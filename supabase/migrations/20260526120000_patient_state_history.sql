-- Historial automatico de cambios de estado del paciente.
-- Registra tanto el estado operativo (registrado, en_espera, trasladando, recibido, alta_medica)
-- como el color de TRIAGE cada vez que cambia en public.patients.

create table if not exists public.patient_state_history (
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

comment on table public.patient_state_history is
  'Auditoria append-only de cambios de status y triage_color de pacientes.';
comment on column public.patient_state_history.changed_fields is
  'Campos que detonaron el registro: created, status, triage_color.';
comment on column public.patient_state_history.actor_id is
  'Usuario autenticado que provoco el cambio, cuando existe en profiles.';

create index if not exists patient_state_history_patient_created_idx
  on public.patient_state_history (patient_id, created_at desc);

create index if not exists patient_state_history_incident_created_idx
  on public.patient_state_history (incident_id, created_at desc);

create index if not exists patient_state_history_actor_created_idx
  on public.patient_state_history (actor_id, created_at desc);

alter table public.patient_state_history enable row level security;

drop policy if exists patient_state_history_select on public.patient_state_history;

create policy patient_state_history_select
  on public.patient_state_history for select to authenticated
  using (public.current_role () in ('paramedico', 'medico'));

revoke insert, update, delete on public.patient_state_history from anon, authenticated;
grant select on public.patient_state_history to authenticated;

insert into public.patient_state_history (
  patient_id,
  incident_id,
  actor_id,
  actor_role,
  changed_fields,
  old_status,
  new_status,
  old_triage_color,
  new_triage_color,
  metadata,
  created_at
)
select
  p.id,
  p.incident_id,
  p.created_by,
  pr.role,
  array['created', 'status', 'triage_color'],
  null,
  p.status,
  null,
  p.triage_color,
  jsonb_build_object(
    'operation', 'BACKFILL',
    'display_name', p.display_name,
    'hospital_id', p.hospital_id,
    'ambulance_unit_id', p.ambulance_unit_id,
    'regulation_folio', p.regulation_folio
  ),
  coalesce(p.created_at, now())
from public.patients p
left join public.profiles pr on pr.id = p.created_by
where not exists (
  select 1
  from public.patient_state_history h
  where h.patient_id = p.id
);

create or replace function public.record_patient_state_history()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid := auth.uid();
  v_actor_role public.user_role;
  v_changed_fields text[] := array[]::text[];
begin
  if v_actor_id is not null then
    select role into v_actor_role
    from public.profiles
    where id = v_actor_id;

    if not found then
      v_actor_id := null;
      v_actor_role := null;
    end if;
  end if;

  if tg_op = 'INSERT' then
    v_changed_fields := array['created', 'status', 'triage_color'];
  else
    if old.status is distinct from new.status then
      v_changed_fields := array_append(v_changed_fields, 'status');
    end if;

    if old.triage_color is distinct from new.triage_color then
      v_changed_fields := array_append(v_changed_fields, 'triage_color');
    end if;
  end if;

  if coalesce(array_length(v_changed_fields, 1), 0) = 0 then
    return new;
  end if;

  insert into public.patient_state_history (
    patient_id,
    incident_id,
    actor_id,
    actor_role,
    changed_fields,
    old_status,
    new_status,
    old_triage_color,
    new_triage_color,
    metadata
  )
  values (
    new.id,
    new.incident_id,
    v_actor_id,
    v_actor_role,
    v_changed_fields,
    case when tg_op = 'INSERT' then null else old.status end,
    new.status,
    case when tg_op = 'INSERT' then null else old.triage_color end,
    new.triage_color,
    jsonb_build_object(
      'operation', tg_op,
      'display_name', new.display_name,
      'hospital_id', new.hospital_id,
      'ambulance_unit_id', new.ambulance_unit_id,
      'regulation_folio', new.regulation_folio
    )
  );

  return new;
end;
$$;

drop trigger if exists patients_record_state_history on public.patients;

create trigger patients_record_state_history
after insert or update of status, triage_color on public.patients
for each row
execute function public.record_patient_state_history();
