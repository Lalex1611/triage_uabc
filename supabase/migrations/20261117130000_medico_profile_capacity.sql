-- 12 · Perfil del médico (mockup 13): capacidad de urgencias del hospital y
-- resumen de la guardia de hoy.
--
-- * hospitals gana columnas de capacidad (camas de choque / observación,
--   si recibe pacientes rojos y si hay quirófano). Null = sin capturar.
-- * medico_profile_summary(): lee hospital, capacidad y conteos del día.
-- * medico_update_hospital_capacity(): el médico actualiza la capacidad de SU
--   hospital (la política de update de hospitals es solo para admin).

alter table public.hospitals
  add column shock_beds_total int,
  add column shock_beds_free int,
  add column observation_beds_total int,
  add column observation_beds_free int,
  add column accepting_red_patients boolean,
  add column operating_room_available boolean,
  add column capacity_updated_at timestamptz,
  add column capacity_updated_by uuid references public.profiles (id) on delete set null,
  add constraint hospitals_shock_beds_check check (
    (shock_beds_total is null or shock_beds_total between 0 and 999)
    and (shock_beds_free is null or (shock_beds_free >= 0
      and (shock_beds_total is null or shock_beds_free <= shock_beds_total)))
  ),
  add constraint hospitals_observation_beds_check check (
    (observation_beds_total is null or observation_beds_total between 0 and 999)
    and (observation_beds_free is null or (observation_beds_free >= 0
      and (observation_beds_total is null or observation_beds_free <= observation_beds_total)))
  );

comment on column public.hospitals.shock_beds_free is
  'Capacidad de urgencias capturada por los médicos del hospital (perfil, mockup 13).';

-- Resumen del perfil ---------------------------------------------------------------
-- "Hoy" se cuenta desde la medianoche de Tijuana.
create or replace function public.medico_profile_summary()
returns jsonb
language plpgsql
stable
security invoker
set search_path = public
as $$
declare
  v_hospital uuid := public.app_current_hospital_id();
  v_since timestamptz := date_trunc('day', now() at time zone 'America/Tijuana')
                         at time zone 'America/Tijuana';
  v_h public.hospitals%rowtype;
  v_received int;
  v_discharged int;
  v_rejected int;
  v_in_room int;
begin
  if public.app_current_role() is distinct from 'medico'::public.user_role then
    raise exception 'forbidden';
  end if;
  if v_hospital is null then
    raise exception 'Su perfil no tiene hospital asignado';
  end if;

  select * into v_h from public.hospitals where id = v_hospital;

  select
    count(*) filter (where h.new_status = 'recibido'),
    count(*) filter (where h.new_status = 'alta_medica')
  into v_received, v_discharged
  from public.patient_state_history h
  join public.patients p on p.id = h.patient_id
  where p.hospital_id = v_hospital
    and h.created_at >= v_since
    and h.new_status in ('recibido', 'alta_medica')
    and (h.old_status is distinct from h.new_status);

  select count(*) into v_rejected
  from public.medico_rejected_transfers r
  where r.hospital_id = v_hospital and r.created_at >= v_since;

  select count(*) into v_in_room
  from public.patients p
  where p.hospital_id = v_hospital
    and p.status = 'recibido'
    and p.is_deleted = false
    and p.is_archived = false;

  return jsonb_build_object(
    'hospital', jsonb_build_object(
      'id', v_h.id,
      'name', v_h.name,
      'center_kind', v_h.center_kind,
      'shock_beds_total', v_h.shock_beds_total,
      'shock_beds_free', v_h.shock_beds_free,
      'observation_beds_total', v_h.observation_beds_total,
      'observation_beds_free', v_h.observation_beds_free,
      'accepting_red_patients', v_h.accepting_red_patients,
      'operating_room_available', v_h.operating_room_available,
      'capacity_updated_at', v_h.capacity_updated_at
    ),
    'shift', jsonb_build_object(
      'received', v_received,
      'rejected', v_rejected,
      'discharged', v_discharged,
      'in_room', v_in_room
    )
  );
end;
$$;

-- Edición de capacidad -------------------------------------------------------------
create or replace function public.medico_update_hospital_capacity(
  p_shock_beds_free int,
  p_shock_beds_total int,
  p_observation_beds_free int,
  p_observation_beds_total int,
  p_accepting_red_patients boolean,
  p_operating_room_available boolean
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_hospital uuid := public.app_current_hospital_id();
begin
  if public.app_current_role() is distinct from 'medico'::public.user_role then
    raise exception 'forbidden';
  end if;
  if v_hospital is null then
    raise exception 'Su perfil no tiene hospital asignado';
  end if;
  if p_shock_beds_total is not null and p_shock_beds_free is not null
     and p_shock_beds_free > p_shock_beds_total then
    raise exception 'Las camas de choque libres no pueden ser más que el total';
  end if;
  if p_observation_beds_total is not null and p_observation_beds_free is not null
     and p_observation_beds_free > p_observation_beds_total then
    raise exception 'Las camas de observación libres no pueden ser más que el total';
  end if;

  update public.hospitals
  set shock_beds_free = p_shock_beds_free,
      shock_beds_total = p_shock_beds_total,
      observation_beds_free = p_observation_beds_free,
      observation_beds_total = p_observation_beds_total,
      accepting_red_patients = p_accepting_red_patients,
      operating_room_available = p_operating_room_available,
      capacity_updated_at = now(),
      capacity_updated_by = auth.uid()
  where id = v_hospital and is_deleted = false;

  if not found then
    raise exception 'Hospital no encontrado';
  end if;
end;
$$;

revoke all on function public.medico_profile_summary() from public;
revoke all on function public.medico_update_hospital_capacity(int, int, int, int, boolean, boolean) from public;
grant execute on function public.medico_profile_summary() to authenticated;
grant execute on function public.medico_update_hospital_capacity(int, int, int, int, boolean, boolean) to authenticated;

notify pgrst, 'reload schema';
