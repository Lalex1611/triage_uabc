-- Serializa el retiro de una foto con las cargas del mismo incidente, incluso
-- cuando la solicitud HTTP sigue en curso después del tiempo de espera de la app.
create or replace function public.record_paramedic_incident_photo_removals()
returns trigger language plpgsql security definer
set search_path = ''
as $$
declare
  v_removed text[];
begin
  if new.photo_local_paths is null then return new; end if;
  v_removed := array(
    select path from unnest(old.photo_local_paths) removed(path)
    where path ~ ('^'||old.id::text||'/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|heic)$')
      and not exists (select 1 from unnest(new.photo_local_paths) kept(path) where kept.path = removed.path)
  );
  if cardinality(v_removed) > 0 then
    perform pg_advisory_xact_lock(hashtextextended('incident_photos:' || old.id::text, 0));
    insert into public.paramedic_removed_incident_photos (incident_id, path)
      select old.id, path from unnest(v_removed) removed(path)
      on conflict do nothing;
  end if;

  -- Una lista editada antes del retiro puede incluir una referencia ya retirada.
  new.photo_local_paths := array(
    select item.path from unnest(new.photo_local_paths) with ordinality item(path, n)
    where not exists (select 1 from public.paramedic_removed_incident_photos r
      where r.incident_id = old.id and r.path = item.path)
    order by item.n
  );
  return new;
end;
$$;

drop trigger record_paramedic_incident_photo_removals on public.incidents;
create trigger record_paramedic_incident_photo_removals
before update of photo_local_paths on public.incidents
for each row when (old.photo_local_paths is distinct from new.photo_local_paths)
execute function public.record_paramedic_incident_photo_removals();

-- Reconcilia referencias restauradas antes de instalar la protección.
update public.incidents i set photo_local_paths = array(
  select item.path from unnest(i.photo_local_paths) with ordinality item(path, n)
  where not exists (select 1 from public.paramedic_removed_incident_photos r
    where r.incident_id = i.id and r.path = item.path)
  order by item.n
)
where exists (select 1 from public.paramedic_removed_incident_photos r
  where r.incident_id = i.id and r.path = any(i.photo_local_paths));

create function public.reject_removed_incident_photo_upload()
returns trigger language plpgsql security definer
set search_path = ''
as $$
declare
  v_incident uuid := split_part(new.name, '/', 1)::uuid;
begin
  -- Storage puede archivar una versión o crear una marca de borrado al retirar
  -- un objeto. Ambas escrituras deben poder terminar.
  if (to_jsonb(new)->>'is_delete_marker')::boolean is true
     or to_jsonb(new)->>'archived_at' is not null then
    return null;
  end if;
  perform pg_advisory_xact_lock_shared(hashtextextended('incident_photos:' || v_incident::text, 0));
  if exists (select 1 from public.paramedic_removed_incident_photos
    where incident_id = v_incident and path = new.name) then
    raise exception using errcode = 'P0802', message = 'El adjunto se retiró del incidente';
  end if;
  return null;
end;
$$;
revoke all on function public.reject_removed_incident_photo_upload() from public, anon, authenticated;

-- Valida la escritura final de Storage, incluso si aprobó la carga antes del
-- retiro. La API de Storage sigue siendo responsable de los archivos físicos.
create trigger reject_removed_incident_photo_upload
after insert or update on storage.objects
for each row when (new.bucket_id = 'incident_photos' and
  new.name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|heic)$')
execute function public.reject_removed_incident_photo_upload();

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
  -- El perfil pudo cambiar mientras otro reintento tenía el bloqueo.
  perform 1 from public.profiles
    where id = auth.uid() and is_active and role = 'paramedico'
    for share;
  if not found then
    raise exception using errcode = '42501', message = 'Cuenta o rol no autorizado';
  end if;
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

notify pgrst, 'reload schema';
