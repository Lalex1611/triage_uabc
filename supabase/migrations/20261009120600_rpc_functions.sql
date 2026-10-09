-- 7/8 · RPC (funciones que llama la app)

-- Paramédico crea incidente con localización --------------------------------
create or replace function public.create_incident_for_paramedic(
  p_title text,
  p_emergency_type public.emergency_type,
  p_lng double precision,
  p_lat double precision
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if public.app_current_role() is distinct from 'paramedico'::public.user_role then
    raise exception 'forbidden';
  end if;

  insert into public.incidents (generated_title, emergency_type, location, created_by)
  values (
    p_title,
    p_emergency_type,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
    auth.uid()
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- Paramédico guarda la ubicación del paciente (sin exponer PostGIS al cliente) ----
-- La fuente de verdad es patients.location; ya no se duplica en demographics.
create or replace function public.paramedico_update_patient_location(
  p_patient_id uuid,
  p_lat double precision,
  p_lng double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.app_current_role() is distinct from 'paramedico'::public.user_role then
    raise exception 'Solo paramédicos pueden actualizar la ubicación del paciente';
  end if;

  if p_lat is null or p_lng is null
     or p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180 then
    raise exception 'Coordenadas inválidas';
  end if;

  update public.patients
  set location = st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
      location_captured_at = now()
  where id = p_patient_id and is_deleted = false;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;
end;
$$;

-- Médico rechaza/cancela un traslado: el paciente vuelve a en_espera ---------------
create or replace function public.medico_cancel_patient_transfer(
  p_patient_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_patient public.patients%rowtype;
  v_reason text := nullif(trim(p_reason), '');
  v_hospital uuid;
begin
  if public.app_current_role() is distinct from 'medico'::public.user_role then
    raise exception 'Solo personal hospitalario puede cancelar traslados';
  end if;
  if v_reason is null then
    raise exception 'Indique el motivo de la cancelación';
  end if;

  v_hospital := public.app_current_hospital_id();
  if v_hospital is null then
    raise exception 'Su usuario no tiene un hospital asignado';
  end if;

  select * into v_patient
  from public.patients
  where id = p_patient_id and is_deleted = false
  for update;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;
  if v_patient.status is distinct from 'trasladando'::public.patient_lifecycle_status then
    raise exception 'El paciente no está en traslado';
  end if;
  if v_patient.hospital_id is distinct from v_hospital then
    raise exception 'El paciente no está asignado a su hospital';
  end if;

  insert into public.medico_rejected_transfers (hospital_id, patient_id, reason, created_by)
  values (v_hospital, p_patient_id, v_reason, auth.uid());

  -- Habilita el único retroceso permitido, solo dentro de esta transacción.
  perform set_config('app.internal_rpc', 'on', true);

  update public.patients
  set status = 'en_espera'::public.patient_lifecycle_status,
      hospital_id = null,
      regulation_folio = null,
      estimated_arrival_at = null
  where id = p_patient_id;

  perform set_config('app.internal_rpc', 'off', true);

  insert into public.paramedic_notifications (recipient_id, patient_id, title, body, kind, metadata)
  values (
    v_patient.created_by,
    p_patient_id,
    'Traslado cancelado',
    v_reason,
    'transfer_cancelled',
    jsonb_build_object(
      'patient_display_name', coalesce(v_patient.display_name, 'Paciente'),
      'cancelled_by_hospital_id', v_hospital
    )
  );

  insert into public.incident_logs (incident_id, patient_id, actor_id, action, metadata)
  values (
    v_patient.incident_id,
    p_patient_id,
    auth.uid(),
    'transfer_cancelled',
    jsonb_build_object('reason', v_reason)
  );
end;
$$;

-- Genera un código de consulta aleatorio (6 caracteres sin ambiguos: sin I, L, O, 0, 1) ----
create or replace function public.create_consultation_code(
  p_patient_id uuid,
  p_ttl_hours int default 72
)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  c_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; -- 31 caracteres
  v_role public.user_role := public.app_current_role();
  v_patient public.patients%rowtype;
  v_code text;
  v_byte int;
  v_attempt int := 0;
begin
  if v_role is null or v_role not in ('admin', 'paramedico', 'medico') then
    raise exception 'forbidden';
  end if;

  select * into v_patient from public.patients where id = p_patient_id and is_deleted = false;
  if not found then
    raise exception 'Paciente no encontrado';
  end if;

  if v_role = 'medico'
     and v_patient.hospital_id is distinct from public.app_current_hospital_id() then
    raise exception 'El paciente no está asignado a su hospital';
  end if;

  loop
    v_code := '';
    while length(v_code) < 6 loop
      v_byte := get_byte(gen_random_bytes(1), 0);
      continue when v_byte >= 248; -- descarta sesgo (248 = 31 * 8)
      v_code := v_code || substr(c_alphabet, 1 + (v_byte % 31), 1);
    end loop;

    begin
      insert into public.consultation_codes (patient_id, code, expires_at, created_by)
      values (p_patient_id, v_code, now() + make_interval(hours => greatest(p_ttl_hours, 1)), auth.uid());
      return v_code;
    exception when unique_violation then
      v_attempt := v_attempt + 1;
      if v_attempt >= 5 then
        raise exception 'No se pudo generar un código único';
      end if;
    end;
  end loop;
end;
$$;

-- Consulta pública por código (anon). Respuesta mínima + rate limit por IP. -----------
-- Devuelve {found:false} en vez de lanzar excepción para que el intento quede registrado.
create or replace function public.get_patient_status_by_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key text;
  v_status public.patient_lifecycle_status;
  v_hospital_id uuid;
  v_name text;
  v_address text;
  v_phone text;
begin
  v_key := coalesce(
    nullif(trim(split_part(
      coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for', ''),
      ',', 1)), ''),
    'unknown'
  );

  delete from public.consultation_lookup_attempts where created_at < now() - interval '1 day';

  if (select count(*) from public.consultation_lookup_attempts
      where client_key = v_key and created_at > now() - interval '5 minutes') >= 10 then
    return jsonb_build_object('found', false, 'error', 'rate_limited');
  end if;

  insert into public.consultation_lookup_attempts (client_key) values (v_key);

  if p_code is null or length(trim(p_code)) < 1 then
    return jsonb_build_object('found', false, 'error', 'invalid_code');
  end if;

  select p.status, p.hospital_id
  into v_status, v_hospital_id
  from public.consultation_codes cc
  join public.patients p on p.id = cc.patient_id
  where upper(trim(cc.code)) = upper(trim(p_code))
    and cc.revoked_at is null
    and (cc.expires_at is null or cc.expires_at > now())
    and p.is_deleted = false;

  if v_status is null then
    return jsonb_build_object('found', false, 'error', 'not_found');
  end if;

  if v_hospital_id is not null then
    select h.name, h.address, h.contact_phone
    into v_name, v_address, v_phone
    from public.hospitals h
    where h.id = v_hospital_id and h.is_deleted = false;
  end if;

  return jsonb_build_object(
    'found', true,
    'patient_status', v_status::text,
    'hospital_name', v_name,
    'hospital_address', v_address,
    'hospital_phone', v_phone
  );
end;
$$;

-- Permisos de ejecución -----------------------------------------------------------
grant usage on schema public to anon, authenticated;

revoke all on function public.create_incident_for_paramedic(text, public.emergency_type, double precision, double precision) from public;
revoke all on function public.paramedico_update_patient_location(uuid, double precision, double precision) from public;
revoke all on function public.medico_cancel_patient_transfer(uuid, text) from public;
revoke all on function public.create_consultation_code(uuid, int) from public;
revoke all on function public.get_patient_status_by_code(text) from public;

grant execute on function public.create_incident_for_paramedic(text, public.emergency_type, double precision, double precision) to authenticated;
grant execute on function public.paramedico_update_patient_location(uuid, double precision, double precision) to authenticated;
grant execute on function public.medico_cancel_patient_transfer(uuid, text) to authenticated;
grant execute on function public.create_consultation_code(uuid, int) to authenticated;
grant execute on function public.get_patient_status_by_code(text) to anon, authenticated;

notify pgrst, 'reload schema';