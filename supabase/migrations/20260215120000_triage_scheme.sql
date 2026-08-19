/*
  Sistema Triage — esquema inicial (para la supabase)
*/


create extension if not exists "uuid-ossp";
create extension if not exists postgis;

-- los roles que hay en el sistema
create type public.user_role as enum (
  'paramedico',
  'medico',
  'consulta_externa'
);

-- los estados que tiene el incidente en el sistema puede o estar acctivo o cerrado 
create type public.incident_status as enum ('activo', 'cerrado');

-- Tipos de emergencia (aun falta agregar algunas mas que estan por especificar pero por el momento estas)
create type public.emergency_type as enum (
  'accidente_vehicular',
  'derrumbe',
  'incidente_masivo',
  'otro'
);

-- colores del triage prehospitalario
create type public.triage_color as enum (
  'rojo',
  'naranja',
  'amarillo',
  'verde',
  'azul',
  'negro'
);

-- estos son los estaados que tiene el paciente en el sistema
create type public.patient_lifecycle_status as enum (
  'registrado',
  'en_espera',
  'trasladando',
  'recibido',
  'alta_medica'
);

-- tipo de recepcion del paciente ya haya sido en urgencias o una consulta
create type public.hospital_reception_kind as enum ('urgencias', 'consulta_regular');

-- las ambulancias que hay en el sistema y que pueden ser asignadas 
create table public.ambulancias_unidades (
  id uuid primary key default gen_random_uuid(),
  numero_economico text not null,
  unit_type text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  constraint ambulancias_unidades_numero_economico_unique unique (numero_economico)
);

-- Hospitales receptores que se encuentran en la lista
create table public.hospitals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  is_public boolean,
  contact_phone text,
  center_kind public.hospital_reception_kind,
  accepted_insurance text[],
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);


-- los perfiles que hay en el sistema y que pueden ser asignados a un usuario
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role public.user_role not null default 'consulta_externa',
  -- Unidad en la que opera el paramédico (opcional)
  ambulance_unit_id uuid references public.ambulancias_unidades (id),
  -- Hospital en el que opera el médico (opcional)
  hospital_id uuid references public.hospitals (id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- tenemos los incidentes que se registran en el sistema
create table public.incidents (
  id uuid primary key default gen_random_uuid(),
  sync_client_id uuid unique,
  generated_title text not null,
  description text,
  emergency_type public.emergency_type not null,
  location geography (point, 4326) not null,
  status public.incident_status not null default 'activo',
  created_by uuid not null references public.profiles (id),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create index incidents_status_idx on public.incidents (status)
where
  is_deleted = false;

create index incidents_location_gix on public.incidents using gist (location)
where
  is_deleted = false;


-- Pacientes/vitimas 
-- hospital_id es el destino y ambulance_unit_id es la unidad asignada a este traslado
create table public.patients (
  id uuid primary key default gen_random_uuid(),
  sync_client_id uuid not null unique,
  incident_id uuid references public.incidents (id) on delete restrict,
  triage_color public.triage_color not null,
  status public.patient_lifecycle_status not null default 'registrado',
  location geography (point, 4326),
  location_captured_at timestamptz,
  hospital_id uuid references public.hospitals (id),
  ambulance_unit_id uuid references public.ambulancias_unidades (id),
  regulation_folio text,
  descriptive_notes text,
  vital_signs jsonb,
  is_pediatric boolean,
  is_archived boolean not null default false,
  departed_scene_at timestamptz,
  estimated_arrival_at timestamptz,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create index patients_incident_idx on public.patients (incident_id)
where
  is_deleted = false;

create index patients_status_idx on public.patients (status)
where
  is_deleted = false;

create index patients_location_gix on public.patients using gist (location)
where
  is_deleted = false;


--por si siempre si se requiere de un log de lo que se ha realizado en el sistema
create table public.incident_logs (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid references public.incidents (id) on delete set null,
  patient_id uuid references public.patients (id) on delete set null,
  actor_id uuid not null references public.profiles (id),
  action text not null,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index incident_logs_incident_idx on public.incident_logs (incident_id);

create index incident_logs_patient_idx on public.incident_logs (patient_id);

create index incident_logs_created_idx on public.incident_logs (created_at);

-- Aqui se almacenan los codigos de consulta familiar que se generan para consultar el estado del paciente
-- aun pensando en su implementaciónn por el momento 
create table public.consultation_codes (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete restrict,
  code text not null,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  constraint consultation_codes_code_unique unique (code)
);

--algunas utiliadades para la actualizacion de las tablas
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger ambulancias_unidades_updated_at
before update on public.ambulancias_unidades
for each row
execute function public.set_updated_at();

create trigger hospitals_updated_at
before update on public.hospitals
for each row
execute function public.set_updated_at();

create trigger profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger incidents_updated_at
before update on public.incidents
for each row
execute function public.set_updated_at();

create trigger patients_updated_at
before update on public.patients
for each row
execute function public.set_updated_at();

create or replace function public.patient_status_rank(s public.patient_lifecycle_status)
returns int
language sql
immutable
as $$
  select case s
    when 'registrado' then 1
    when 'en_espera' then 2
    when 'trasladando' then 3
    when 'recibido' then 4
    when 'alta_medica' then 5
  end;
$$;

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

create trigger patients_status_transition
before update on public.patients
for each row
execute function public.enforce_patient_status_transition();

--registrar perfiles al crear un usuario
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  r text;
begin
  r := coalesce(new.raw_user_meta_data->>'role', 'consulta_externa');
  if r not in ('paramedico', 'medico', 'consulta_externa') then
    r := 'consulta_externa';
  end if;
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    nullif(trim(coalesce(new.raw_user_meta_data->>'full_name', '')), ''),
    r::public.user_role
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

-- aqui ban las buenas practicas en postgreSQL para evitar accesos indeseados a la base de datos
create or replace function public.current_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid()
  limit 1;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table public.ambulancias_unidades enable row level security;

alter table public.hospitals enable row level security;

alter table public.profiles enable row level security;

alter table public.incidents enable row level security;

alter table public.patients enable row level security;

alter table public.incident_logs enable row level security;

alter table public.consultation_codes enable row level security;

-- politicas sobre quein puede ver las unidades de ambulancia
create policy ambulancias_unidades_select on public.ambulancias_unidades for
select
  to authenticated using (is_deleted = false);

create policy ambulancias_unidades_insert on public.ambulancias_unidades for insert to authenticated
with check (
  public.current_role () = 'paramedico'
);

create policy ambulancias_unidades_update on public.ambulancias_unidades for
update
  to authenticated using (
    is_deleted = false
    and public.current_role () = 'paramedico'
  )
with check (
  public.current_role () = 'paramedico'
);

create policy hospitals_select on public.hospitals for
select
  to authenticated using (is_deleted = false);

create policy hospitals_insert on public.hospitals for insert to authenticated
with check (
  public.current_role () = 'paramedico'
);

create policy hospitals_update on public.hospitals for
update
  to authenticated using (
    is_deleted = false
    and public.current_role () = 'paramedico'
  )
with check (
  public.current_role () = 'paramedico'
);

-- politicas pa los perfiles propios
create policy profiles_select_own on public.profiles for
select
  to authenticated using (id = auth.uid());

create policy profiles_update_own on public.profiles for
update
  to authenticated using (id = auth.uid())
with check (id = auth.uid());

--  politicas para que los apramedicos puedan crear incidentes
create policy incidents_insert on public.incidents for insert to authenticated
with check (
  public.current_role () = 'paramedico'
  and created_by = auth.uid()
);

create policy incidents_select on public.incidents for
select
  to authenticated using (
    is_deleted = false
    and public.current_role () in ('paramedico', 'medico', 'consulta_externa')
  );

create policy incidents_update on public.incidents for
update
  to authenticated using (
    is_deleted = false
    and public.current_role () = 'paramedico'
  )
with check (
  public.current_role () = 'paramedico'
);

create policy patients_insert on public.patients for insert to authenticated
with check (
  public.current_role () = 'paramedico'
  and created_by = auth.uid ()
);

create policy patients_select on public.patients for
select
  to authenticated using (
    is_deleted = false
    and public.current_role () in ('paramedico', 'medico', 'consulta_externa')
  );

-- los estados que pueden ser actualizados por los paramedicos
create policy patients_update_paramedico on public.patients for
update
  to authenticated using (
    is_deleted = false
    and public.current_role () = 'paramedico'
  )
with check (
  public.current_role () = 'paramedico'
  and status in (
    'registrado',
    'en_espera',
    'trasladando',
    'alta_medica'
  )
);

create policy patients_update_medico on public.patients for
update
  to authenticated using (
    is_deleted = false
    and public.current_role () = 'medico'
  )
with check (
  public.current_role () = 'medico'
  and status in ('recibido', 'alta_medica')
);

-- los posibles logs que se podrian incluir para adespues 
create policy incident_logs_select on public.incident_logs for
select
  to authenticated using (
    public.current_role () in ('paramedico', 'medico')
  );

create policy incident_logs_insert on public.incident_logs for insert to authenticated
with check (
  actor_id = auth.uid ()
  and public.current_role () in ('paramedico', 'medico')
);

-- Códigos de consulta  que pueden proveer los paramédicos y revisar los familiares
create policy consultation_codes_select on public.consultation_codes for
select
  to authenticated using (public.current_role () in ('paramedico', 'consulta_externa'));

create policy consultation_codes_insert on public.consultation_codes for insert to authenticated
with check (
  public.current_role () = 'paramedico'
  and created_by = auth.uid ()
);

create policy consultation_codes_update on public.consultation_codes for
update
  to authenticated using (public.current_role () = 'paramedico')
with check (
  public.current_role () = 'paramedico'
);

--publicar cambios en incidentes y pacientes
alter publication supabase_realtime add table public.incidents;

alter publication supabase_realtime add table public.patients;

alter table public.incidents replica identity full;

alter table public.patients replica identity full;
