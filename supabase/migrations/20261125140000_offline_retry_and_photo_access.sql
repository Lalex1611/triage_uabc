-- Quita referencias cruzadas en los registros sin tocar los archivos de Storage.
update public.patients p
  set demographics = jsonb_set(p.demographics, '{photo_storage_paths}', (
    select coalesce(jsonb_agg(photo.path order by photo.position)
      filter (where jsonb_typeof(photo.path) = 'string'
        and starts_with(photo.path #>> '{}', p.id::text || '/')), '[]'::jsonb)
    from jsonb_array_elements(
      case when jsonb_typeof(p.demographics->'photo_storage_paths') = 'array'
        then p.demographics->'photo_storage_paths' else '[]'::jsonb end
    ) with ordinality as photo(path, position)
  ))
  where p.demographics ? 'photo_storage_paths' and (
    jsonb_typeof(p.demographics->'photo_storage_paths') is distinct from 'array'
    or exists (
      select 1 from jsonb_array_elements(
        case when jsonb_typeof(p.demographics->'photo_storage_paths') = 'array'
          then p.demographics->'photo_storage_paths' else '[]'::jsonb end
      ) as photo(path)
      where jsonb_typeof(photo.path) <> 'string'
        or not starts_with(photo.path #>> '{}', p.id::text || '/')
    )
  );

-- Autoriza al paciente y consulta el código activo en la misma lectura.
create or replace function public.sync_medico_walk_in_capture(
  p_account_id uuid,
  p_sync_client_id uuid,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital uuid;
  v_hash bytea;
  v_receipt public.medico_walk_in_capture_receipts%rowtype;
  v_result jsonb;
  v_active_code text;
begin
  if auth.uid() is null or p_account_id is distinct from auth.uid() then
    raise exception using errcode = '42501', message = 'Cuenta no autorizada';
  end if;

  select hospital_id into v_hospital from public.profiles
    where id = auth.uid() and is_active and role = 'medico'
    for share;
  if v_hospital is null or v_hospital is distinct from (p_payload->>'hospital_id')::uuid then
    raise exception using errcode = '42501', message = 'El registro pertenece a otro hospital';
  end if;

  if p_sync_client_id is null or jsonb_typeof(p_payload) is distinct from 'object'
      or jsonb_typeof(p_payload->'demographics') is distinct from 'object' then
    raise exception using errcode = '22023', message = 'Captura de Médico inválida';
  end if;

  v_hash := sha256(convert_to(p_payload::text, 'UTF8'));
  perform pg_advisory_xact_lock(hashtextextended('medico_walk_in:' || p_sync_client_id::text, 0));

  select * into v_receipt from public.medico_walk_in_capture_receipts
    where sync_client_id = p_sync_client_id;
  if found then
    if v_receipt.account_id is distinct from auth.uid()
        or v_receipt.hospital_id is distinct from v_hospital then
      raise exception using errcode = '42501', message = 'Captura no autorizada';
    end if;
    if v_receipt.request_hash is distinct from v_hash then
      raise exception using errcode = '23505', message = 'La captura ya existe con otros datos';
    end if;
    select active.code into v_active_code
      from public.patients p
      left join lateral (
        select trim(c.code) as code from public.consultation_codes c
        where c.patient_id = p.id and c.revoked_at is null
          and (c.expires_at is null or c.expires_at > now()) and trim(c.code) <> ''
        order by c.created_at desc
        limit 1
      ) active on true
      where p.id = v_receipt.patient_id and p.hospital_id = v_hospital
        and p.created_by = auth.uid() and not p.is_deleted
      for share of p;
    if not found then
      raise exception using errcode = 'P0002', message = 'El paciente ya no está disponible';
    end if;
    return jsonb_build_object('id', v_receipt.patient_id, 'code', v_active_code);
  end if;

  v_result := public.medico_register_walk_in_patient(
    p_payload->>'display_name',
    (p_payload->>'triage_color')::public.triage_color,
    (p_payload->'demographics') - 'photo_local_paths' - 'photo_storage_paths',
    p_payload->'vital_signs',
    p_payload->>'descriptive_notes'
  );

  insert into public.medico_walk_in_capture_receipts (
    sync_client_id, account_id, hospital_id, patient_id, request_hash, consultation_code
  ) values (
    p_sync_client_id, auth.uid(), v_hospital, (v_result->>'patient_id')::uuid,
    v_hash, v_result->>'consultation_code'
  );

  return jsonb_build_object('id', v_result->>'patient_id', 'code', v_result->>'consultation_code');
end;
$$;

-- Conserva el objeto de Storage hasta confirmar el vínculo clínico.

-- Avisa al cliente si tiene que retirar del bucket un adjunto reintentado.
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
      raise exception using errcode='P0802',message='El adjunto se retiró del incidente';
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
      case
        when jsonb_typeof(demographics->'photo_storage_paths') is distinct from 'array'
          then jsonb_build_array(p_path)
        when (demographics->'photo_storage_paths') @> jsonb_build_array(p_path)
          then demographics->'photo_storage_paths'
        else (demographics->'photo_storage_paths') || jsonb_build_array(p_path)
      end)
    where id=p_record_id and created_by=auth.uid() and not is_deleted;
  end if;
  if not found then raise exception using errcode='42501',message='Registro no disponible'; end if;
end;
$$;

notify pgrst, 'reload schema';
