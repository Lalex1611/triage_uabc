-- Notifica a los médicos del hospital cuando un paramédico envía un paciente en traslado.

create or replace function public.notify_medicos_incoming_transfer()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_body text;
  v_hospital_name text;
begin
  if new.is_deleted then
    return new;
  end if;

  if new.status is distinct from 'trasladando'::public.patient_lifecycle_status then
    return new;
  end if;

  if new.hospital_id is null then
    return new;
  end if;

  if tg_op = 'UPDATE'
     and old.status is not distinct from 'trasladando'::public.patient_lifecycle_status
     and old.hospital_id is not distinct from new.hospital_id then
    return new;
  end if;

  select h.name into v_hospital_name
  from public.hospitals h
  where h.id = new.hospital_id;

  v_body := coalesce(nullif(trim(new.display_name), ''), 'Paciente en traslado');
  if new.regulation_folio is not null and trim(new.regulation_folio) <> '' then
    v_body := v_body || ' · Folio ' || trim(new.regulation_folio);
  end if;
  if v_hospital_name is not null and trim(v_hospital_name) <> '' then
    v_body := v_body || ' → ' || trim(v_hospital_name);
  end if;

  insert into public.medico_notifications (
    recipient_id,
    patient_id,
    title,
    body,
    kind,
    metadata
  )
  select
    p.id,
    new.id,
    'Paciente en camino',
    v_body,
    'incoming_transfer',
    jsonb_build_object(
      'patient_display_name', coalesce(nullif(trim(new.display_name), ''), 'Paciente'),
      'hospital_id', new.hospital_id,
      'triage_color', new.triage_color::text,
      'regulation_folio', new.regulation_folio
    )
  from public.profiles p
  where p.hospital_id = new.hospital_id
    and p.role = 'medico'::public.user_role
    and p.is_active = true;

  return new;
end;
$$;

drop trigger if exists patients_notify_medico_incoming_transfer on public.patients;

create trigger patients_notify_medico_incoming_transfer
after insert or update of status, hospital_id, display_name, regulation_folio on public.patients
for each row
execute function public.notify_medicos_incoming_transfer();
