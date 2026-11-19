-- 14 · Notificaciones del médico (mockup 12).
-- * "Paciente en camino" guarda además incidente, unidad y hora estimada de
--   llegada, para mostrar "llega en N min desde INC-…".
-- * Nueva "Alta registrada": avisa a los demás médicos del hospital.
-- * Nueva "Capacidad al límite": cuando las camas de choque libres bajan a 2
--   o menos (solo al cruzar el umbral, no en cada edición).

-- Paciente en camino (misma lógica; metadata más completa) -----------------
create or replace function public.notify_medicos_incoming_transfer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_body text;
  v_hospital_name text;
  v_unit_code text;
begin
  if new.is_deleted
     or new.status is distinct from 'trasladando'::public.patient_lifecycle_status
     or new.hospital_id is null then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.status is not distinct from 'trasladando'::public.patient_lifecycle_status
     and old.hospital_id is not distinct from new.hospital_id then
    return new;
  end if;

  select h.name into v_hospital_name from public.hospitals h where h.id = new.hospital_id;
  select u.numero_economico into v_unit_code
  from public.ambulancias_unidades u where u.id = new.ambulance_unit_id;

  v_body := coalesce(nullif(trim(new.display_name), ''), 'Paciente en traslado');
  if nullif(trim(new.regulation_folio), '') is not null then
    v_body := v_body || ' · Folio ' || trim(new.regulation_folio);
  end if;
  if nullif(trim(v_hospital_name), '') is not null then
    v_body := v_body || ' → ' || trim(v_hospital_name);
  end if;

  insert into public.medico_notifications (recipient_id, patient_id, title, body, kind, metadata)
  select p.id,
         new.id,
         'Paciente en camino',
         v_body,
         'incoming_transfer',
         jsonb_build_object(
           'patient_display_name', coalesce(nullif(trim(new.display_name), ''), 'Paciente'),
           'hospital_id', new.hospital_id,
           'triage_color', new.triage_color::text,
           'regulation_folio', new.regulation_folio,
           'incident_id', new.incident_id,
           'unit_code', v_unit_code,
           'estimated_arrival_at', new.estimated_arrival_at
         )
  from public.profiles p
  where p.hospital_id = new.hospital_id
    and p.role = 'medico'::public.user_role
    and p.is_active = true;

  return new;
end;
$$;

-- Alta registrada --------------------------------------------------------------
create or replace function public.notify_medicos_patient_discharged()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_deleted
     or new.hospital_id is null
     or new.status is distinct from 'alta_medica'::public.patient_lifecycle_status
     or old.status is not distinct from new.status then
    return new;
  end if;

  insert into public.medico_notifications (recipient_id, patient_id, title, body, kind, metadata)
  select p.id,
         new.id,
         'Alta registrada',
         coalesce(nullif(trim(new.display_name), ''), 'Paciente') || ' salió con alta médica.',
         'patient_discharged',
         jsonb_build_object(
           'patient_display_name', coalesce(nullif(trim(new.display_name), ''), 'Paciente'),
           'triage_color', new.triage_color::text
         )
  from public.profiles p
  where p.hospital_id = new.hospital_id
    and p.role = 'medico'::public.user_role
    and p.is_active = true
    and p.id is distinct from auth.uid();

  return new;
end;
$$;

create trigger patients_notify_medico_discharged
after update of status on public.patients
for each row execute function public.notify_medicos_patient_discharged();

-- Capacidad al límite ----------------------------------------------------------
create or replace function public.notify_medicos_capacity_low()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  c_threshold constant int := 2;
begin
  if new.shock_beds_free is null
     or new.shock_beds_free > c_threshold
     or (old.shock_beds_free is not null and old.shock_beds_free <= c_threshold) then
    return new;
  end if;

  insert into public.medico_notifications (recipient_id, patient_id, title, body, kind, metadata)
  select p.id,
         null,
         'Capacidad al límite',
         case new.shock_beds_free
           when 0 then 'No quedan camas de choque disponibles en urgencias.'
           when 1 then 'Queda 1 cama de choque disponible en urgencias.'
           else 'Quedan ' || new.shock_beds_free || ' camas de choque disponibles en urgencias.'
         end,
         'capacity_low',
         jsonb_build_object(
           'shock_beds_free', new.shock_beds_free,
           'shock_beds_total', new.shock_beds_total
         )
  from public.profiles p
  where p.hospital_id = new.id
    and p.role = 'medico'::public.user_role
    and p.is_active = true
    and p.id is distinct from auth.uid();

  return new;
end;
$$;

create trigger hospitals_notify_medico_capacity_low
after update of shock_beds_free on public.hospitals
for each row execute function public.notify_medicos_capacity_low();
