-- Consulta pública por código (anon) + helper paramédico para crear incidente con localización.

create or replace function public.get_patient_status_by_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status public.patient_lifecycle_status;
  v_hospital_id uuid;
  v_name text;
  v_address text;
  v_phone text;
begin
  if p_code is null or length(trim(p_code)) < 1 then
    raise exception 'invalid_code';
  end if;

  select
    p.status,
    p.hospital_id
  into
    v_status,
    v_hospital_id
  from public.consultation_codes cc
  join public.patients p on p.id = cc.patient_id
  where upper(trim(cc.code)) = upper(trim(p_code))
    and cc.revoked_at is null
    and (cc.expires_at is null or cc.expires_at > now())
    and p.is_deleted = false;

  if v_status is null then
    raise exception 'not_found';
  end if;

  if v_hospital_id is not null then
    select h.name, h.address, h.contact_phone
    into v_name, v_address, v_phone
    from public.hospitals h
    where h.id = v_hospital_id
      and h.is_deleted = false;
  end if;

  return jsonb_build_object(
    'patient_status', v_status::text,
    'hospital_name', v_name,
    'hospital_address', v_address,
    'hospital_phone', v_phone
  );
end;
$$;

grant execute on function public.get_patient_status_by_code(text) to anon;
grant execute on function public.get_patient_status_by_code(text) to authenticated;

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
  if public.current_role() is distinct from 'paramedico'::public.user_role then
    raise exception 'forbidden';
  end if;

  insert into public.incidents (
    generated_title,
    emergency_type,
    location,
    created_by
  )
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

grant execute on function public.create_incident_for_paramedic(text, public.emergency_type, double precision, double precision) to authenticated;
