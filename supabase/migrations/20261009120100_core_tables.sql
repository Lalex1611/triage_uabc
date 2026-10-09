-- 2/8 · Tablas principales

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

create table public.hospitals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  is_public boolean,
  contact_phone text,
  center_kind public.hospital_reception_kind,
  accepted_insurance text[],
  location geography (point, 4326),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

comment on column public.hospitals.location is
  'Coordenadas del hospital para mostrar destino y exportar ruta.';

create index hospitals_location_gix on public.hospitals using gist (location)
  where is_deleted = false and location is not null;

-- role, hospital_id, ambulance_unit_id e is_active solo los cambia un admin (ver trigger guard).
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role public.user_role not null default 'consulta_externa',
  ambulance_unit_id uuid references public.ambulancias_unidades (id),
  hospital_id uuid references public.hospitals (id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.incidents (
  id uuid primary key default gen_random_uuid(),
  sync_client_id uuid unique,
  generated_title text not null,
  description text,
  emergency_type public.emergency_type not null,
  location geography (point, 4326) not null,
  status public.incident_status not null default 'activo',
  photo_local_paths text[] not null default '{}',
  created_by uuid not null references public.profiles (id),
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

comment on column public.incidents.photo_local_paths is
  'TEMPORAL: rutas locales del dispositivo. Migrar a Storage cuando se conecte.';

create index incidents_status_idx on public.incidents (status) where is_deleted = false;
create index incidents_location_gix on public.incidents using gist (location) where is_deleted = false;

-- hospital_id = hospital DESTINO (lo fija el paramédico al pasar a 'trasladando',
-- o el médico en un walk-in). No confundir con profiles.hospital_id (donde trabaja el médico).
create table public.patients (
  id uuid primary key default gen_random_uuid(),
  sync_client_id uuid not null unique,
  incident_id uuid references public.incidents (id) on delete restrict,
  display_name text,
  triage_color public.triage_color not null,
  status public.patient_lifecycle_status not null default 'en_espera',
  location geography (point, 4326),
  location_captured_at timestamptz,
  hospital_id uuid references public.hospitals (id),
  ambulance_unit_id uuid references public.ambulancias_unidades (id),
  regulation_folio text,
  descriptive_notes text,
  vital_signs jsonb,
  is_pediatric boolean,
  demographics jsonb not null default '{}'::jsonb,
  is_archived boolean not null default false,
  departed_scene_at timestamptz,
  estimated_arrival_at timestamptz,
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  -- un paciente en traslado o recibido siempre tiene hospital
  constraint patients_hospital_required_check
    check (status not in ('trasladando', 'recibido') or hospital_id is not null)
);

comment on column public.patients.demographics is
  'Datos START/registro no normalizados (JSON). No guardar aquí datos con reglas (cancelaciones, coordenadas).';

create index patients_incident_idx on public.patients (incident_id) where is_deleted = false;
create index patients_status_idx on public.patients (status) where is_deleted = false;
create index patients_hospital_idx on public.patients (hospital_id) where is_deleted = false;
create index patients_location_gix on public.patients using gist (location) where is_deleted = false;

-- Bitácora general de acciones (para eventos que no son cambio de estado).
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

-- Códigos que se entregan al familiar. Se generan SOLO con la RPC create_consultation_code.
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

create index consultation_codes_patient_idx on public.consultation_codes (patient_id);