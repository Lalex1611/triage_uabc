-- 1/8 · Extensiones y tipos enumerados

create extension if not exists postgis;
create extension if not exists pgcrypto with schema extensions;

-- admin: gestiona hospitales, ambulancias y asigna roles/hospitales a usuarios.
-- consulta_externa: ciudadano con cuenta (la consulta por código funciona sin cuenta, vía RPC anon).
create type public.user_role as enum (
  'admin',
  'paramedico',
  'medico',
  'consulta_externa'
);

create type public.incident_status as enum ('activo', 'cerrado');

create type public.emergency_type as enum (
  'accidente_vehicular',
  'derrumbe',
  'incidente_masivo',
  'violencia',
  'otro'
);

create type public.triage_color as enum (
  'rojo',
  'naranja',
  'amarillo',
  'verde',
  'azul',
  'negro'
);

-- Flujo: en_espera -> trasladando -> recibido -> alta_medica
-- Único retroceso permitido: trasladando -> en_espera (el hospital cancela el traslado).
create type public.patient_lifecycle_status as enum (
  'en_espera',
  'trasladando',
  'recibido',
  'alta_medica'
);

create type public.hospital_reception_kind as enum ('urgencias', 'consulta_regular');