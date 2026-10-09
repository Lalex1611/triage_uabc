-- 3/8 · Notificaciones, traslados rechazados, auditoría y antiabuso

create table public.paramedic_notifications (
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

create index paramedic_notifications_recipient_idx
  on public.paramedic_notifications (recipient_id, created_at desc);

create table public.medico_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  patient_id uuid references public.patients (id) on delete set null,
  title text not null,
  body text not null,
  kind text not null default 'generic',
  metadata jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index medico_notifications_recipient_idx
  on public.medico_notifications (recipient_id, created_at desc);

-- Fuente de verdad del motivo de cancelación (ya no se guarda en patients.demographics).
create table public.medico_rejected_transfers (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals (id),
  patient_id uuid not null references public.patients (id) on delete cascade,
  reason text not null,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create index medico_rejected_transfers_hospital_idx
  on public.medico_rejected_transfers (hospital_id, created_at desc);
create index medico_rejected_transfers_patient_idx
  on public.medico_rejected_transfers (patient_id, created_at desc);

-- Auditoría append-only de cambios de status / triage_color (la llena un trigger).
create table public.patient_state_history (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  incident_id uuid references public.incidents (id) on delete set null,
  actor_id uuid references public.profiles (id) on delete set null,
  actor_role public.user_role,
  changed_fields text[] not null,
  old_status public.patient_lifecycle_status,
  new_status public.patient_lifecycle_status not null,
  old_triage_color public.triage_color,
  new_triage_color public.triage_color not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint patient_state_history_has_changed_fields
    check (coalesce(array_length(changed_fields, 1), 0) > 0)
);

create index patient_state_history_patient_created_idx
  on public.patient_state_history (patient_id, created_at desc);
create index patient_state_history_incident_created_idx
  on public.patient_state_history (incident_id, created_at desc);

-- Intentos de consulta pública por código (rate limit).
create table public.consultation_lookup_attempts (
  id bigint generated always as identity primary key,
  client_key text not null,
  created_at timestamptz not null default now()
);

create index consultation_lookup_attempts_key_idx
  on public.consultation_lookup_attempts (client_key, created_at desc);