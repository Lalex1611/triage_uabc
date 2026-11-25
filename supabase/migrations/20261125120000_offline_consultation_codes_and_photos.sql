-- Verifica la vigencia del código al confirmar un reintento de Médico.
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
    if not exists (
      select 1 from public.patients where id = v_receipt.patient_id
        and hospital_id = v_hospital and created_by = auth.uid() and not is_deleted
    ) then
      raise exception using errcode = 'P0002', message = 'El paciente ya no está disponible';
    end if;
    select trim(c.code) into v_active_code
      from public.consultation_codes c
      where c.patient_id = v_receipt.patient_id and c.revoked_at is null
        and (c.expires_at is null or c.expires_at > now()) and trim(c.code) <> ''
      order by c.created_at desc
      limit 1;
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
create or replace function public.link_medico_walk_in_photo(
  p_account_id uuid,
  p_patient_id uuid,
  p_path text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital uuid;
  v_owner text;
begin
  if auth.uid() is null or p_account_id is distinct from auth.uid() then
    raise exception using errcode = '42501', message = 'Cuenta no autorizada';
  end if;

  select hospital_id into v_hospital from public.profiles
    where id = auth.uid() and is_active and role = 'medico'
    for share;
  if v_hospital is null or not exists (
    select 1 from public.medico_walk_in_capture_receipts
      where patient_id = p_patient_id and account_id = auth.uid() and hospital_id = v_hospital
  ) then
    raise exception using errcode = '42501', message = 'Captura no autorizada';
  end if;

  if p_path is null or split_part(p_path, '/', 1) <> p_patient_id::text
      or p_path !~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|jpeg|png|webp|heic)$' then
    raise exception using errcode = '22023', message = 'Ruta de foto inválida';
  end if;
  select o.owner_id into v_owner
    from storage.objects o
    where o.bucket_id = 'patient_photos' and o.name = p_path
    for share;
  if not found then
    raise exception using errcode = 'P0801', message = 'La foto no existe en Storage';
  end if;
  if v_owner is distinct from auth.uid()::text then
    raise exception using errcode = '42501', message = 'Foto no disponible para esta cuenta';
  end if;

  update public.patients
    set demographics = jsonb_set(demographics, '{photo_storage_paths}',
      case
        when jsonb_typeof(demographics->'photo_storage_paths') is distinct from 'array'
          then jsonb_build_array(p_path)
        when (demographics->'photo_storage_paths') @> jsonb_build_array(p_path)
          then demographics->'photo_storage_paths'
        else (demographics->'photo_storage_paths') || jsonb_build_array(p_path)
      end)
    where id = p_patient_id and hospital_id = v_hospital
      and created_by = auth.uid() and not is_deleted;
  if not found then
    raise exception using errcode = 'P0002', message = 'El paciente ya no está disponible';
  end if;
end;
$$;

-- Agrega o quita una foto sobre el valor actual de la fila, con RLS.
create or replace function public.paramedico_update_incident_photo_path(
  p_incident_id uuid,
  p_path text,
  p_remove boolean
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if p_path is null or btrim(p_path) = '' or p_remove is null then
    raise exception using errcode = '22023', message = 'Ruta de foto inválida';
  end if;

  update public.incidents
    set photo_local_paths = case
      when p_remove then array_remove(photo_local_paths, p_path)
      when p_path = any(photo_local_paths) then photo_local_paths
      else array_append(photo_local_paths, p_path)
    end
    where id = p_incident_id and not is_deleted;
  if not found then
    raise exception using errcode = '42501', message = 'Incidente no disponible para esta cuenta';
  end if;
end;
$$;

revoke all on function public.paramedico_update_incident_photo_path(uuid, text, boolean) from public, anon;
grant execute on function public.paramedico_update_incident_photo_path(uuid, text, boolean) to authenticated;

notify pgrst, 'reload schema';
