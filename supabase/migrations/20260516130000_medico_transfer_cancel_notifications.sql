-- Cancelación de traslado por médico + notificaciones al paramédico registrador.

create table if not exists public.paramedic_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  patient_id uuid references public.patients (id) on delete set null,
  title text not null,
  body text not null,
  kind text not null default 'transfer_cancelled',
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists paramedic_notifications_recipient_idx
  on public.paramedic_notifications (recipient_id, created_at desc);

alter table public.paramedic_notifications enable row level security;

create policy paramedic_notifications_select_own
  on public.paramedic_notifications for select to authenticated
  using (recipient_id = auth.uid());

create policy paramedic_notifications_update_own
  on public.paramedic_notifications for update to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- Permite volver a registrado cuando el hospital cancela el traslado (motivo en demographics).
create or replace function public.enforce_patient_status_transition()
returns trigger
language plpgsql
as $$
declare
  r_old int;
  r_new int;
begin
  if tg_op = 'UPDATE' and old.status is not distinct from new.status then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.status in ('trasladando'::public.patient_lifecycle_status, 'en_espera'::public.patient_lifecycle_status)
     and new.status = 'registrado'::public.patient_lifecycle_status
     and coalesce(new.demographics, '{}'::jsonb) ? 'transfer_cancellation_reason'
  then
    return new;
  end if;

  r_old := public.patient_status_rank(old.status);
  r_new := public.patient_status_rank(new.status);
  if r_new < r_old then
    raise exception 'no se permiten retrocesos de estado del paciente';
  end if;
  if new.status = 'alta_medica'::public.patient_lifecycle_status then
    return new;
  end if;
  if r_new > r_old + 1 then
    raise exception 'transición de estado inválida (salto)';
  end if;
  return new;
end;
$$;

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
  v_role public.user_role;
  v_patient public.patients%rowtype;
  v_demo jsonb;
  v_reason text := nullif(trim(p_reason), '');
  v_medico_hospital uuid;
begin
  if public.current_role() is distinct from 'medico'::public.user_role then
    raise exception 'Solo personal hospitalario puede cancelar traslados';
  end if;
  if v_reason is null then
    raise exception 'Indique el motivo de la cancelación';
  end if;

  select hospital_id into v_medico_hospital
  from public.profiles
  where id = auth.uid();

  select * into v_patient
  from public.patients
  where id = p_patient_id
    and is_deleted = false;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;

  if v_patient.status is distinct from 'trasladando'::public.patient_lifecycle_status then
    raise exception 'El paciente no está en traslado';
  end if;

  if v_medico_hospital is not null
     and v_patient.hospital_id is distinct from v_medico_hospital then
    raise exception 'El paciente no está asignado a su hospital';
  end if;

  v_demo := coalesce(v_patient.demographics, '{}'::jsonb);
  v_demo := v_demo
    || jsonb_build_object(
      'transfer_cancelled_at', now(),
      'transfer_cancellation_reason', v_reason,
      'transfer_cancelled_by', auth.uid()
    );

  update public.patients
  set
    status = 'registrado'::public.patient_lifecycle_status,
    hospital_id = null,
    regulation_folio = null,
    estimated_arrival_at = null,
    demographics = v_demo,
    updated_at = now()
  where id = p_patient_id;

  insert into public.paramedic_notifications (
    recipient_id,
    patient_id,
    title,
    body,
    kind,
    metadata
  )
  values (
    v_patient.created_by,
    p_patient_id,
    'Traslado cancelado',
    v_reason,
    'transfer_cancelled',
    jsonb_build_object(
      'patient_display_name', coalesce(v_patient.display_name, 'Paciente'),
      'cancelled_by_hospital_id', v_medico_hospital
    )
  );

  insert into public.incident_logs (
    incident_id,
    patient_id,
    actor_id,
    action,
    metadata
  )
  values (
    v_patient.incident_id,
    p_patient_id,
    auth.uid(),
    'transfer_cancelled',
    jsonb_build_object('reason', v_reason)
  );
end;
$$;

grant execute on function public.medico_cancel_patient_transfer(uuid, text) to authenticated;
