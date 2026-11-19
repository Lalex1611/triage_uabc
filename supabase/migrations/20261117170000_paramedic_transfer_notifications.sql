-- 16 · Avisos al paramédico cuando el hospital acepta o rechaza un traslado.
--
-- Solo se generan los datos en public.paramedic_notifications; mostrarlos es
-- responsabilidad de la app del paramédico. Formato (contrato):
--
--   kind = 'transfer_accepted'   title = 'Traslado aceptado'
--     body: '<Hospital> recibió a <Paciente>.'
--   kind = 'transfer_cancelled'  title = 'Traslado rechazado'
--     body: '<Hospital> rechazó el traslado de <Paciente>: <motivo>'
--
--   metadata (ambos):
--     patient_display_name, triage_color, regulation_folio, unit_code,
--     hospital_id, hospital_name, medico_name
--   metadata (solo transfer_cancelled):
--     reason, cancelled_by_hospital_id (se conserva por compatibilidad)
--
-- Destinatarios: el paramédico que registró al paciente y los paramédicos
-- activos de la unidad que lo traslada (sin repetir).

comment on column public.paramedic_notifications.kind is
  'transfer_accepted | transfer_cancelled. Ver migración 20261117170000 para el formato de body y metadata.';

-- A quién avisar ------------------------------------------------------------------
create or replace function public.paramedic_recipients_for_patient(
  p_created_by uuid,
  p_ambulance_unit_id uuid
)
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.id
  from public.profiles p
  where p.role = 'paramedico'::public.user_role
    and p.is_active = true
    and (
      p.id = p_created_by
      or (p_ambulance_unit_id is not null and p.ambulance_unit_id = p_ambulance_unit_id)
    );
$$;

revoke all on function public.paramedic_recipients_for_patient(uuid, uuid) from public, anon, authenticated;

-- Traslado aceptado (trasladando → recibido) ---------------------------------------
create or replace function public.notify_paramedics_transfer_accepted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := coalesce(nullif(trim(new.display_name), ''), 'Paciente');
  v_hospital_name text;
  v_unit_code text;
  v_medico_name text;
begin
  if new.is_deleted
     or old.status is distinct from 'trasladando'::public.patient_lifecycle_status
     or new.status is distinct from 'recibido'::public.patient_lifecycle_status then
    return new;
  end if;

  select h.name into v_hospital_name from public.hospitals h where h.id = new.hospital_id;
  select u.numero_economico into v_unit_code
  from public.ambulancias_unidades u where u.id = new.ambulance_unit_id;
  select pr.full_name into v_medico_name from public.profiles pr where pr.id = auth.uid();

  insert into public.paramedic_notifications (recipient_id, patient_id, title, body, kind, metadata)
  select r.id,
         new.id,
         'Traslado aceptado',
         coalesce(nullif(trim(v_hospital_name), ''), 'El hospital') || ' recibió a ' || v_name || '.',
         'transfer_accepted',
         jsonb_build_object(
           'patient_display_name', v_name,
           'triage_color', new.triage_color::text,
           'regulation_folio', new.regulation_folio,
           'unit_code', v_unit_code,
           'hospital_id', new.hospital_id,
           'hospital_name', v_hospital_name,
           'medico_name', v_medico_name
         )
  from public.paramedic_recipients_for_patient(new.created_by, new.ambulance_unit_id) as r(id);

  return new;
end;
$$;

create trigger patients_notify_paramedic_transfer_accepted
after update of status on public.patients
for each row execute function public.notify_paramedics_transfer_accepted();

-- Traslado rechazado: misma lógica que antes, con aviso más completo ----------------
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
  v_hospital_name text;
  v_unit_code text;
  v_medico_name text;
  v_name text;
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

  v_name := coalesce(nullif(trim(v_patient.display_name), ''), 'Paciente');
  select h.name into v_hospital_name from public.hospitals h where h.id = v_hospital;
  select u.numero_economico into v_unit_code
  from public.ambulancias_unidades u where u.id = v_patient.ambulance_unit_id;
  select pr.full_name into v_medico_name from public.profiles pr where pr.id = auth.uid();

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

  -- Se usan los datos de antes del update (unidad y quién lo registró)
  insert into public.paramedic_notifications (recipient_id, patient_id, title, body, kind, metadata)
  select r.id,
         p_patient_id,
         'Traslado rechazado',
         coalesce(nullif(trim(v_hospital_name), ''), 'El hospital')
           || ' rechazó el traslado de ' || v_name || ': ' || v_reason,
         'transfer_cancelled',
         jsonb_build_object(
           'patient_display_name', v_name,
           'triage_color', v_patient.triage_color::text,
           'regulation_folio', v_patient.regulation_folio,
           'unit_code', v_unit_code,
           'hospital_id', v_hospital,
           'hospital_name', v_hospital_name,
           'medico_name', v_medico_name,
           'reason', v_reason,
           'cancelled_by_hospital_id', v_hospital
         )
  from public.paramedic_recipients_for_patient(v_patient.created_by, v_patient.ambulance_unit_id) as r(id);

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

notify pgrst, 'reload schema';
