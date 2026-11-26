-- Conserva los retiros de adjuntos para detener vínculos anteriores al retiro.
create table public.paramedic_removed_incident_photos (
  incident_id uuid not null references public.incidents(id) on delete cascade,
  path text not null,
  primary key (incident_id, path)
);

alter table public.paramedic_removed_incident_photos enable row level security;
revoke all on public.paramedic_removed_incident_photos from public, anon, authenticated;

create function public.record_paramedic_incident_photo_removals()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.paramedic_removed_incident_photos (incident_id, path)
  select old.id, path from unnest(old.photo_local_paths) removed(path)
  where path ~ ('^'||old.id::text||'/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|heic)$')
    and not exists (select 1 from unnest(new.photo_local_paths) kept(path) where kept.path = removed.path)
  on conflict do nothing;
  return new;
end;
$$;

revoke all on function public.record_paramedic_incident_photo_removals() from public, anon, authenticated;

create trigger record_paramedic_incident_photo_removals
after update of photo_local_paths on public.incidents
for each row when (old.photo_local_paths is distinct from new.photo_local_paths)
execute function public.record_paramedic_incident_photo_removals();

-- Confirma el registro idempotente aunque su código haya vencido.
create or replace function public.sync_paramedic_capture(
  p_account_id uuid, p_kind text, p_sync_client_id uuid, p_payload jsonb
) returns jsonb language plpgsql security definer
set search_path = public, extensions
as $$
declare
  v_receipt public.paramedic_capture_receipts%rowtype;
  v_id uuid;
  v_parent uuid;
  v_code text;
  v_result jsonb;
  v_lat double precision;
  v_lng double precision;
begin
  if auth.uid() is null or p_account_id is distinct from auth.uid()
     or public.app_current_role() is distinct from 'paramedico'::public.user_role then
    raise exception using errcode = '42501', message = 'Cuenta o rol no autorizado';
  end if;
  if p_sync_client_id is null or p_kind is null or p_kind not in ('incident','patient')
     or p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception using errcode = '22023', message = 'Solicitud inválida';
  end if;
  -- Procesa una solicitud a la vez por identificador, desde el primer registro.
  perform pg_advisory_xact_lock(hashtextextended(p_sync_client_id::text, 0));
  if p_kind = 'patient' then
    v_parent := (p_payload->>'incident_id')::uuid;
    -- Mantiene el incidente visible hasta que termine la captura.
    perform 1 from public.incidents where id = v_parent and not is_deleted for share;
    if not found then
      raise exception using errcode = '42501', message = 'Incidente no disponible';
    end if;
  end if;
  select * into v_receipt from public.paramedic_capture_receipts where sync_client_id=p_sync_client_id;
  if found then
    if v_receipt.account_id <> auth.uid() then
      raise exception using errcode = '42501', message = 'Identificador de otra cuenta';
    end if;
    if v_receipt.kind <> p_kind or v_receipt.request <> p_payload then
      raise exception using errcode = '23505', message = 'Solicitud incompatible con la captura original';
    end if;
    if (p_kind='incident' and not exists(select 1 from public.incidents where id=(v_receipt.response->>'id')::uuid and not is_deleted))
      or (p_kind='patient' and not exists(select 1 from public.patients where id=(v_receipt.response->>'id')::uuid and not is_deleted)) then
      raise exception using errcode = '42501', message = 'Registro no disponible';
    end if;
    if p_kind = 'patient' then
      select trim(c.code) into v_code
        from public.consultation_codes c
        where c.patient_id = (v_receipt.response->>'id')::uuid and c.revoked_at is null
          and (c.expires_at is null or c.expires_at > now()) and trim(c.code) <> ''
        order by c.created_at desc
        limit 1;
      return jsonb_build_object('id', v_receipt.response->>'id', 'code', v_code);
    end if;
    return v_receipt.response;
  end if;
  if exists(select 1 from public.incidents where sync_client_id=p_sync_client_id)
     or exists(select 1 from public.patients where sync_client_id=p_sync_client_id) then
    raise exception using errcode = '23505', message = 'Identificador ya utilizado';
  end if;
  v_lat := (p_payload->>'lat')::double precision;
  v_lng := (p_payload->>'lng')::double precision;
  if v_lat is null or v_lng is null or not(v_lat between -90 and 90) or not(v_lng between -180 and 180) then
    raise exception using errcode = '22023', message = 'Coordenadas inválidas';
  end if;
  if p_kind='incident' then
    if nullif(trim(p_payload->>'title'),'') is null then
      raise exception using errcode='22023', message='Falta el título';
    end if;
    insert into public.incidents(id,sync_client_id,generated_title,description,emergency_type,location,created_by)
    values(p_sync_client_id,p_sync_client_id,p_payload->>'title',p_payload->>'description',
      (p_payload->>'emergency_type')::public.emergency_type,
      st_setsrid(st_makepoint(v_lng,v_lat),4326)::geography,auth.uid()) returning id into v_id;
    v_result := jsonb_build_object('id',v_id);
  else
    if jsonb_typeof(p_payload->'demographics') is distinct from 'object' then
      raise exception using errcode='22023', message='Datos de paciente inválidos';
    end if;
    insert into public.patients(id,sync_client_id,incident_id,triage_color,status,created_by,
      display_name,demographics,location,location_captured_at)
    values(p_sync_client_id,p_sync_client_id,v_parent,(p_payload->>'triage_color')::public.triage_color,
      'en_espera',auth.uid(),coalesce(nullif(trim(p_payload->>'display_name'),''),'Paciente '||upper(left(p_sync_client_id::text,8))),
      (p_payload->'demographics') - 'photo_local_paths' - 'photo_storage_paths',
      st_setsrid(st_makepoint(v_lng,v_lat),4326)::geography,
      coalesce((p_payload->>'captured_at')::timestamptz,now())) returning id into v_id;
    v_code := public.create_consultation_code(v_id);
    v_result := jsonb_build_object('id',v_id,'code',v_code);
  end if;
  insert into public.paramedic_capture_receipts(sync_client_id,account_id,kind,request,response)
  values(p_sync_client_id,auth.uid(),p_kind,p_payload,v_result);
  return v_result;
end;
$$;

-- Protege la fila de Storage durante el vínculo de ambos tipos de foto.
create or replace function public.link_paramedic_capture_photo(
  p_account_id uuid,p_kind text,p_record_id uuid,p_path text
) returns void language plpgsql security definer
set search_path = public, extensions
as $$
declare
  v_bucket text;
  v_owner text;
begin
  if auth.uid() is null or p_account_id is distinct from auth.uid()
     or public.app_current_role() is distinct from 'paramedico'::public.user_role then
    raise exception using errcode='42501',message='Cuenta o rol no autorizado';
  end if;
  if p_kind is null or p_kind not in ('incident','patient') or p_path is null or
     p_path !~ ('^'||p_record_id::text||'/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|heic)$') then
    raise exception using errcode='22023',message='Ruta de foto inválida';
  end if;
  v_bucket := case when p_kind='incident' then 'incident_photos' else 'patient_photos' end;
  if not exists(select 1 from public.paramedic_capture_receipts
      where sync_client_id=p_record_id and account_id=auth.uid() and kind=p_kind) then
    raise exception using errcode='42501',message='Captura de otra cuenta';
  end if;
  if p_kind = 'incident' then
    -- Serializa el vínculo con el UPDATE que registra el retiro.
    perform 1 from public.incidents
      where id = p_record_id and created_by = auth.uid() and not is_deleted
      for no key update;
    if not found then
      raise exception using errcode='42501',message='Registro no disponible';
    end if;
    if exists (select 1 from public.paramedic_removed_incident_photos
        where incident_id = p_record_id and path = p_path) then
      return;
    end if;
  end if;
  select o.owner_id into v_owner
    from storage.objects o where o.bucket_id=v_bucket and o.name=p_path
    for share;
  if not found then
    raise exception using errcode='P0801',message='La foto no existe en Storage';
  end if;
  if v_owner is distinct from auth.uid()::text then
    raise exception using errcode='42501',message='La foto pertenece a otra cuenta';
  end if;
  if p_kind='incident' then
    update public.incidents set photo_local_paths = case when p_path=any(photo_local_paths)
      then photo_local_paths else array_append(photo_local_paths,p_path) end
    where id=p_record_id and created_by=auth.uid() and not is_deleted;
  else
    update public.patients set demographics=jsonb_set(demographics,'{photo_storage_paths}',
      case when coalesce(demographics->'photo_storage_paths','[]'::jsonb) @> jsonb_build_array(p_path)
        then demographics->'photo_storage_paths'
        else coalesce(demographics->'photo_storage_paths','[]'::jsonb)||jsonb_build_array(p_path) end)
    where id=p_record_id and created_by=auth.uid() and not is_deleted;
  end if;
  if not found then raise exception using errcode='42501',message='Registro no disponible'; end if;
end;
$$;

notify pgrst, 'reload schema';
