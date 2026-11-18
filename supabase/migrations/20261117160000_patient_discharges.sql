-- 15 · Alta médica (mockup 10): a dónde sale el paciente y nota de alta.
-- * patient_discharges: una fila por paciente dado de alta.
-- * medico_discharge_patient(): registra el alta y pasa al paciente a
--   alta_medica en una sola transacción.
-- * La notificación "Alta registrada" ahora dice a dónde salió.

create table public.patient_discharges (
  patient_id uuid primary key references public.patients (id) on delete cascade,
  destination text not null,
  note text,
  discharged_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  constraint patient_discharges_destination_check
    check (destination in ('domicilio', 'hospitalizacion', 'traslado', 'defuncion')),
  constraint patient_discharges_note_check
    check (note is null or char_length(note) <= 2000)
);

comment on table public.patient_discharges is
  'Alta médica del paciente: destino y nota. Se escribe solo con medico_discharge_patient().';

alter table public.patient_discharges enable row level security;

create policy patient_discharges_select on public.patient_discharges
  for select to authenticated
  using (
    public.app_current_role() = 'admin'
    or (
      public.app_current_role() = 'medico'
      and exists (
        select 1 from public.patients p
        where p.id = patient_discharges.patient_id
          and p.is_deleted = false
          and p.hospital_id = public.app_current_hospital_id()
      )
    )
  );

revoke insert, update, delete on public.patient_discharges from anon, authenticated;

-- Registrar alta -----------------------------------------------------------------
create or replace function public.medico_discharge_patient(
  p_patient_id uuid,
  p_destination text,
  p_note text default null
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_patient public.patients%rowtype;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if public.app_current_role() is distinct from 'medico'::public.user_role then
    raise exception 'forbidden';
  end if;
  if p_destination is null
     or p_destination not in ('domicilio', 'hospitalizacion', 'traslado', 'defuncion') then
    raise exception 'Elige a dónde sale el paciente';
  end if;

  select * into v_patient
  from public.patients
  where id = p_patient_id and is_deleted = false
  for update;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;
  if v_patient.hospital_id is distinct from public.app_current_hospital_id() then
    raise exception 'El paciente no está asignado a su hospital';
  end if;
  if v_patient.status is distinct from 'recibido'::public.patient_lifecycle_status then
    raise exception 'Solo se puede dar de alta a un paciente que está en sala';
  end if;

  -- Primero el alta, para que la notificación pueda decir a dónde salió
  insert into public.patient_discharges (patient_id, destination, note, discharged_by)
  values (p_patient_id, p_destination, v_note, auth.uid())
  on conflict (patient_id) do update
    set destination = excluded.destination,
        note = excluded.note,
        discharged_by = excluded.discharged_by,
        created_at = now();

  update public.patients
  set status = 'alta_medica'::public.patient_lifecycle_status
  where id = p_patient_id;
end;
$$;

revoke all on function public.medico_discharge_patient(uuid, text, text) from public;
grant execute on function public.medico_discharge_patient(uuid, text, text) to authenticated;

-- "Alta registrada" con destino ------------------------------------------------
create or replace function public.notify_medicos_patient_discharged()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text := coalesce(nullif(trim(new.display_name), ''), 'Paciente');
  v_destination text;
  v_body text;
begin
  if new.is_deleted
     or new.hospital_id is null
     or new.status is distinct from 'alta_medica'::public.patient_lifecycle_status
     or old.status is not distinct from new.status then
    return new;
  end if;

  select d.destination into v_destination
  from public.patient_discharges d where d.patient_id = new.id;

  v_body := case v_destination
    when 'domicilio' then v_name || ' salió con alta a domicilio.'
    when 'hospitalizacion' then v_name || ' pasó a hospitalización.'
    when 'traslado' then v_name || ' fue trasladado a otra unidad.'
    when 'defuncion' then 'Se registró la defunción de ' || v_name || '.'
    else v_name || ' salió con alta médica.'
  end;

  insert into public.medico_notifications (recipient_id, patient_id, title, body, kind, metadata)
  select p.id,
         new.id,
         'Alta registrada',
         v_body,
         'patient_discharged',
         jsonb_build_object(
           'patient_display_name', v_name,
           'triage_color', new.triage_color::text,
           'destination', v_destination
         )
  from public.profiles p
  where p.hospital_id = new.hospital_id
    and p.role = 'medico'::public.user_role
    and p.is_active = true
    and p.id is distinct from auth.uid();

  return new;
end;
$$;

notify pgrst, 'reload schema';
