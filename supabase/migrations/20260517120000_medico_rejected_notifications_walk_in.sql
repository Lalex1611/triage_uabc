-- Traslados rechazados visibles por hospital, notificaciones in-app para médicos,
-- disparador tras registro walk-in, política de INSERT para médicos (recibido),
-- y registro del rechazo dentro de medico_cancel_patient_transfer.

create table if not exists public.medico_rejected_transfers (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals (id),
  patient_id uuid not null references public.patients (id) on delete cascade,
  reason text not null,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create index if not exists medico_rejected_transfers_hospital_idx
  on public.medico_rejected_transfers (hospital_id, created_at desc);

alter table public.medico_rejected_transfers enable row level security;

create policy medico_rejected_transfers_select_hospital
  on public.medico_rejected_transfers for select to authenticated
  using (
    hospital_id = (select hospital_id from public.profiles where id = auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'medico'::public.user_role
    )
  );

create table if not exists public.medico_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  patient_id uuid references public.patients (id) on delete set null,
  title text not null,
  body text not null,
  kind text not null default 'generic',
  read_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists medico_notifications_recipient_idx
  on public.medico_notifications (recipient_id, created_at desc);

alter table public.medico_notifications enable row level security;

create policy medico_notifications_select_own
  on public.medico_notifications for select to authenticated
  using (recipient_id = auth.uid());

create policy medico_notifications_update_own
  on public.medico_notifications for update to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- Permite al médico crear pacientes «walk-in» (recibido en su hospital).
create policy patients_insert_medico_walk_in on public.patients for insert to authenticated
with check (
  public.current_role () = 'medico'::public.user_role
  and created_by = auth.uid ()
  and hospital_id is not null
  and status = 'recibido'::public.patient_lifecycle_status
);

create or replace function public.notify_medicos_walk_in_patient()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  creator_role public.user_role;
begin
  if new.is_deleted then
    return new;
  end if;

  select role into creator_role from public.profiles where id = new.created_by;

  if creator_role is distinct from 'medico'::public.user_role then
    return new;
  end if;

  if new.status is distinct from 'recibido'::public.patient_lifecycle_status then
    return new;
  end if;

  if new.hospital_id is null then
    return new;
  end if;

  insert into public.medico_notifications (recipient_id, patient_id, title, body, kind)
  select p.id,
         new.id,
         'Nuevo registro en hospital',
         coalesce(nullif(trim(new.display_name), ''), 'Paciente registrado'),
         'walk_in_registered'
  from public.profiles p
  where p.hospital_id = new.hospital_id
    and p.role = 'medico'::public.user_role;

  return new;
end;
$$;

drop trigger if exists patients_notify_medico_walk_in on public.patients;

create trigger patients_notify_medico_walk_in
after insert on public.patients
for each row
execute function public.notify_medicos_walk_in_patient();

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

  if v_patient.hospital_id is not null then
    insert into public.medico_rejected_transfers (
      hospital_id,
      patient_id,
      reason,
      created_by
    ) values (
      v_patient.hospital_id,
      p_patient_id,
      v_reason,
      auth.uid()
    );
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
