-- 5/8 · Triggers (reglas de negocio automáticas)
-- Convención: RLS decide QUIÉN y sobre QUÉ filas; los triggers guard deciden QUÉ puede cambiar.
-- Las RPC internas activan 'app.internal_rpc' (solo dentro de su transacción) para saltar los guards.

-- updated_at ---------------------------------------------------------------
create trigger ambulancias_unidades_updated_at before update on public.ambulancias_unidades
  for each row execute function public.set_updated_at();
create trigger hospitals_updated_at before update on public.hospitals
  for each row execute function public.set_updated_at();
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger incidents_updated_at before update on public.incidents
  for each row execute function public.set_updated_at();
create trigger patients_updated_at before update on public.patients
  for each row execute function public.set_updated_at();

-- Alta de usuario: SIEMPRE consulta_externa (el metadata del cliente no es confiable).
-- Un admin promueve después a paramedico / medico.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    nullif(trim(coalesce(new.raw_user_meta_data->>'full_name', '')), ''),
    'consulta_externa'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- Perfiles: solo un admin cambia rol, hospital, unidad o is_active ---------
create or replace function public.guard_profile_update()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is null
     or current_setting('app.internal_rpc', true) = 'on'
     or public.app_current_role() = 'admin' then
    return new;
  end if;

  if new.id is distinct from old.id
     or new.role is distinct from old.role
     or new.hospital_id is distinct from old.hospital_id
     or new.ambulance_unit_id is distinct from old.ambulance_unit_id
     or new.is_active is distinct from old.is_active then
    raise exception 'Solo un administrador puede modificar rol, hospital, unidad o estado del usuario';
  end if;
  return new;
end;
$$;

create trigger profiles_guard_update
before update on public.profiles
for each row execute function public.guard_profile_update();

-- Pacientes: qué puede cambiar cada rol ------------------------------------
create or replace function public.guard_patient_update()
returns trigger
language plpgsql
as $$
declare
  v_role public.user_role;
begin
  -- service role / SQL directo / RPC internas
  if auth.uid() is null or current_setting('app.internal_rpc', true) = 'on' then
    return new;
  end if;

  v_role := public.app_current_role();

  if new.id is distinct from old.id
     or new.sync_client_id is distinct from old.sync_client_id
     or new.created_by is distinct from old.created_by then
    raise exception 'id, sync_client_id y created_by no se pueden modificar';
  end if;

  if v_role = 'admin' then
    return new;

  elsif v_role = 'paramedico' then
    -- 'recibido' lo marca el hospital; el regreso a en_espera solo ocurre vía cancelación del hospital.
    if new.status is distinct from old.status
       and new.status not in ('trasladando', 'alta_medica') then
      raise exception 'Un paramédico solo puede pasar un paciente a trasladando o alta_medica';
    end if;

  elsif v_role = 'medico' then
    if new.status is distinct from old.status
       and new.status not in ('recibido', 'alta_medica') then
      raise exception 'El personal hospitalario solo puede pasar un paciente a recibido o alta_medica';
    end if;
    if new.triage_color is distinct from old.triage_color
       or new.hospital_id is distinct from old.hospital_id
       or new.ambulance_unit_id is distinct from old.ambulance_unit_id
       or new.regulation_folio is distinct from old.regulation_folio
       or new.incident_id is distinct from old.incident_id
       or new.location is distinct from old.location then
      raise exception 'El personal hospitalario solo puede modificar estado y datos clínicos';
    end if;

  else
    raise exception 'Rol sin permiso para modificar pacientes';
  end if;

  return new;
end;
$$;

create trigger patients_guard_update
before update on public.patients
for each row execute function public.guard_patient_update();

-- Pacientes: máquina de estados --------------------------------------------
create or replace function public.enforce_patient_status_transition()
returns trigger
language plpgsql
as $$
declare
  r_old int;
  r_new int;
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  -- Único retroceso: el hospital cancela el traslado (solo desde la RPC).
  if old.status = 'trasladando' and new.status = 'en_espera' then
    if current_setting('app.internal_rpc', true) = 'on' then
      return new;
    end if;
    raise exception 'Solo el hospital puede cancelar un traslado';
  end if;

  r_old := public.patient_status_rank(old.status);
  r_new := public.patient_status_rank(new.status);

  if r_new < r_old then
    raise exception 'no se permiten retrocesos de estado del paciente';
  end if;
  if new.status = 'alta_medica' then
    return new;
  end if;
  if r_new > r_old + 1 then
    raise exception 'transición de estado inválida (salto)';
  end if;
  return new;
end;
$$;

create trigger patients_status_transition
before update on public.patients
for each row execute function public.enforce_patient_status_transition();

-- Historial de estado / triage ----------------------------------------------
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
    select role into v_actor_role from public.profiles where id = v_actor_id;
    if not found then
      v_actor_id := null;
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
    patient_id, incident_id, actor_id, actor_role, changed_fields,
    old_status, new_status, old_triage_color, new_triage_color, metadata
  )
  values (
    new.id, new.incident_id, v_actor_id, v_actor_role, v_changed_fields,
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

create trigger patients_record_state_history
after insert or update of status, triage_color on public.patients
for each row execute function public.record_patient_state_history();

-- Notificación: médico registra un paciente walk-in (avisa a los DEMÁS médicos del hospital)
create or replace function public.notify_medicos_walk_in_patient()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_deleted
     or new.status is distinct from 'recibido'::public.patient_lifecycle_status
     or new.hospital_id is null
     or not exists (
       select 1 from public.profiles c
       where c.id = new.created_by and c.role = 'medico'::public.user_role
     ) then
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
    and p.role = 'medico'::public.user_role
    and p.is_active = true
    and p.id <> new.created_by;

  return new;
end;
$$;

create trigger patients_notify_medico_walk_in
after insert on public.patients
for each row execute function public.notify_medicos_walk_in_patient();

-- Notificación: paciente en camino al hospital --------------------------------
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
           'regulation_folio', new.regulation_folio
         )
  from public.profiles p
  where p.hospital_id = new.hospital_id
    and p.role = 'medico'::public.user_role
    and p.is_active = true;

  return new;
end;
$$;

create trigger patients_notify_medico_incoming_transfer
after insert or update of status, hospital_id, display_name, regulation_folio on public.patients
for each row execute function public.notify_medicos_incoming_transfer();