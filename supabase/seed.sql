-- Datos de prueba para desarrollo local. Se ejecuta solo con `supabase db reset` / `supabase start`.
-- NO correr en el proyecto remoto: crea usuarios con contraseña conocida.
--
-- Usuarios (contraseña de todos: Triage123!)
--   admin@triage.test        admin
--   paramedico1@triage.test  paramedico · unidad CRT-101
--   paramedico2@triage.test  paramedico · unidad CRT-102
--   medico1@triage.test      medico · Hospital General de Tijuana
--   medico2@triage.test      medico · Hospital General de Tijuana
--   medico3@triage.test      medico · Hospital Ángeles Tijuana
--
-- Códigos de consulta externa: TRG234 (trasladando), HSP567 (recibido), AXT789 (alta médica)

-- Catálogos -----------------------------------------------------------------
insert into public.ambulancias_unidades (id, numero_economico, unit_type) values
  ('c0000000-0000-0000-0000-000000000001', 'CRT-101', 'Ambulancia Cruz Roja'),
  ('c0000000-0000-0000-0000-000000000002', 'CRT-102', 'Ambulancia Cruz Roja'),
  ('c0000000-0000-0000-0000-000000000003', 'BOM-201', 'Unidad de Bomberos');

insert into public.hospitals (id, name, address, is_public, contact_phone, center_kind, accepted_insurance, location) values
  ('b0000000-0000-0000-0000-000000000001', 'Hospital General de Tijuana',
   'Av. Centenario 10851, Zona Río, Tijuana, B.C.', true, '664 684 0237', 'urgencias',
   array['IMSS-Bienestar', 'Sin seguro'], 'SRID=4326;POINT(-117.0080 32.5260)'),
  ('b0000000-0000-0000-0000-000000000002', 'Hospital Ángeles Tijuana',
   'Av. Paseo de los Héroes 10999, Zona Río, Tijuana, B.C.', false, '664 635 1800', 'urgencias',
   array['GNP', 'AXA', 'MetLife'], 'SRID=4326;POINT(-117.0030 32.5250)'),
  ('b0000000-0000-0000-0000-000000000003', 'IMSS HGR No. 20',
   'Blvd. Agua Caliente s/n, Tijuana, B.C.', true, '664 681 2000', 'consulta_regular',
   array['IMSS'], 'SRID=4326;POINT(-116.9940 32.5110)');

-- Usuarios ------------------------------------------------------------------
-- El trigger on_auth_user_created crea su fila en profiles como consulta_externa.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
select
  '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated', u.email,
  extensions.crypt('Triage123!', extensions.gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', u.full_name),
  now(), now(),
  -- GoTrue falla con "Database error querying schema" si estos tokens son NULL
  '', '', '', ''
from (values
  ('a0000000-0000-0000-0000-000000000001'::uuid, 'admin@triage.test',       'Admin Triage'),
  ('a0000000-0000-0000-0000-000000000002'::uuid, 'paramedico1@triage.test', 'Luis Hernández'),
  ('a0000000-0000-0000-0000-000000000003'::uuid, 'paramedico2@triage.test', 'Ana Castillo'),
  ('a0000000-0000-0000-0000-000000000004'::uuid, 'medico1@triage.test',     'Dra. Sofía Ramírez'),
  ('a0000000-0000-0000-0000-000000000005'::uuid, 'medico2@triage.test',     'Dr. Carlos Medina'),
  ('a0000000-0000-0000-0000-000000000006'::uuid, 'medico3@triage.test',     'Dra. Paola Ortiz')
) as u (id, email, full_name);

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), u.id, u.id::text, 'email',
       jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
       now(), now(), now()
from auth.users u
where u.email like '%@triage.test';

-- Sin auth.uid() el guard de profiles deja cambiar rol/hospital/unidad.
update public.profiles p set role = v.role::public.user_role, hospital_id = v.hospital_id, ambulance_unit_id = v.unit_id
from (values
  ('a0000000-0000-0000-0000-000000000001'::uuid, 'admin',      null::uuid,                              null::uuid),
  ('a0000000-0000-0000-0000-000000000002'::uuid, 'paramedico', null,                                    'c0000000-0000-0000-0000-000000000001'::uuid),
  ('a0000000-0000-0000-0000-000000000003'::uuid, 'paramedico', null,                                    'c0000000-0000-0000-0000-000000000002'::uuid),
  ('a0000000-0000-0000-0000-000000000004'::uuid, 'medico',     'b0000000-0000-0000-0000-000000000001'::uuid, null),
  ('a0000000-0000-0000-0000-000000000005'::uuid, 'medico',     'b0000000-0000-0000-0000-000000000001'::uuid, null),
  ('a0000000-0000-0000-0000-000000000006'::uuid, 'medico',     'b0000000-0000-0000-0000-000000000002'::uuid, null)
) as v (id, role, hospital_id, unit_id)
where p.id = v.id;

-- Incidentes ----------------------------------------------------------------
insert into public.incidents (id, generated_title, description, emergency_type, location, status, created_by, closed_at, created_at) values
  ('d0000000-0000-0000-0000-000000000001', 'Choque múltiple en Vía Rápida Oriente',
   'Colisión de 3 vehículos a la altura del puente Cucapah. Varios lesionados atrapados.',
   'accidente_vehicular', 'SRID=4326;POINT(-116.9900 32.5150)', 'activo',
   'a0000000-0000-0000-0000-000000000002', null, now() - interval '2 hours'),
  ('d0000000-0000-0000-0000-000000000002', 'Derrumbe en colonia Sánchez Taboada',
   'Deslave tras lluvias, una vivienda colapsada parcialmente.',
   'derrumbe', 'SRID=4326;POINT(-117.0350 32.4920)', 'activo',
   'a0000000-0000-0000-0000-000000000002', null, now() - interval '50 minutes'),
  ('d0000000-0000-0000-0000-000000000003', 'Riña en Zona Norte',
   'Reporte de riña con lesionados por arma blanca.',
   'violencia', 'SRID=4326;POINT(-117.0390 32.5390)', 'activo',
   'a0000000-0000-0000-0000-000000000003', null, now() - interval '25 minutes'),
  ('d0000000-0000-0000-0000-000000000004', 'Incendio en nave industrial de Otay',
   'Evacuación de trabajadores por humo. Incidente controlado.',
   'incidente_masivo', 'SRID=4326;POINT(-116.9500 32.5470)', 'cerrado',
   'a0000000-0000-0000-0000-000000000003', now() - interval '1 day', now() - interval '1 day 4 hours');

-- Pacientes -----------------------------------------------------------------
-- Insertar directo salta la máquina de estados (solo valida UPDATE); los triggers
-- de historial y de notificaciones a médicos sí se disparan.
insert into public.patients (
  id, sync_client_id, incident_id, display_name, triage_color, status, location, location_captured_at,
  hospital_id, ambulance_unit_id, regulation_folio, descriptive_notes, vital_signs, is_pediatric,
  demographics, departed_scene_at, estimated_arrival_at, created_by, created_at
) values
  -- Incidente 1: choque múltiple
  ('e0000000-0000-0000-0000-000000000001', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000001',
   'Jorge Salinas', 'rojo', 'trasladando', 'SRID=4326;POINT(-116.9902 32.5151)', now() - interval '100 minutes',
   'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'REG-2026-0101',
   'Conductor atrapado, trauma torácico.',
   '{"ta_sist":"90","ta_diast":"60","fc":"128","respiratory_rate":"32","oxygen_saturation":"88","temperature":"36.1"}', false,
   '{"gender":"masculino","blood_type":"oPositivo","birth_year":1985,"birth_month":4,"birth_day":12,"injury_types":["hemorragia","fractura"],"emergency_contact":"664 123 4567 (esposa)","seguro_medico":"no"}',
   now() - interval '20 minutes', now() + interval '10 minutes', 'a0000000-0000-0000-0000-000000000002', now() - interval '100 minutes'),
  ('e0000000-0000-0000-0000-000000000002', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000001',
   'María López', 'naranja', 'en_espera', 'SRID=4326;POINT(-116.9898 32.5149)', now() - interval '95 minutes',
   null, null, null, 'Copiloto, dolor cervical y laceración en frente.',
   '{"ta_sist":"130","ta_diast":"85","fc":"102","respiratory_rate":"22","oxygen_saturation":"95"}', false,
   '{"gender":"femenino","blood_type":"aPositivo","birth_year":1992,"injury_types":["laceracion"]}',
   null, null, 'a0000000-0000-0000-0000-000000000002', now() - interval '95 minutes'),
  ('e0000000-0000-0000-0000-000000000003', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000001',
   null, 'amarillo', 'en_espera', 'SRID=4326;POINT(-116.9905 32.5153)', now() - interval '90 minutes',
   null, null, null, 'Masculino ~40 años sin identificación, fractura expuesta en pierna.', null, false,
   '{"gender":"masculino","injury_types":["fractura"]}',
   null, null, 'a0000000-0000-0000-0000-000000000002', now() - interval '90 minutes'),
  ('e0000000-0000-0000-0000-000000000004', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000001',
   'Diego Torres', 'verde', 'en_espera', 'SRID=4326;POINT(-116.9897 32.5152)', now() - interval '85 minutes',
   null, null, null, 'Camina, contusiones leves.', null, true,
   '{"gender":"masculino","birth_year":2014,"emergency_contact":"664 765 4321 (madre)"}',
   null, null, 'a0000000-0000-0000-0000-000000000002', now() - interval '85 minutes'),
  ('e0000000-0000-0000-0000-000000000005', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000001',
   null, 'negro', 'en_espera', 'SRID=4326;POINT(-116.9901 32.5148)', now() - interval '110 minutes',
   null, null, null, 'Sin signos vitales a la llegada.', null, false, '{}',
   null, null, 'a0000000-0000-0000-0000-000000000002', now() - interval '110 minutes'),

  -- Incidente 2: derrumbe
  ('e0000000-0000-0000-0000-000000000006', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000002',
   'Rosa Méndez', 'rojo', 'recibido', 'SRID=4326;POINT(-117.0351 32.4921)', now() - interval '45 minutes',
   'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'REG-2026-0102',
   'Aplastamiento de extremidad inferior.',
   '{"ta_sist":"85","ta_diast":"50","fc":"135","respiratory_rate":"30","oxygen_saturation":"90","glucose":"110"}', false,
   '{"gender":"femenino","blood_type":"bNegativo","birth_year":1968,"injury_types":["amputacion","hemorragia"],"allergies":"Penicilina","medical_history":"Diabetes tipo 2","seguro_medico":"si"}',
   now() - interval '35 minutes', now() - interval '15 minutes', 'a0000000-0000-0000-0000-000000000002', now() - interval '45 minutes'),
  ('e0000000-0000-0000-0000-000000000007', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000002',
   'Pedro Méndez', 'amarillo', 'trasladando', 'SRID=4326;POINT(-117.0348 32.4919)', now() - interval '40 minutes',
   'b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000002', 'REG-2026-0103',
   'Traumatismo craneal leve, consciente.',
   '{"ta_sist":"125","ta_diast":"80","fc":"95","respiratory_rate":"18","oxygen_saturation":"97"}', false,
   '{"gender":"masculino","birth_year":1999,"injury_types":["traumatismoCraneal"],"seguro_medico":"si"}',
   now() - interval '10 minutes', now() + interval '15 minutes', 'a0000000-0000-0000-0000-000000000002', now() - interval '40 minutes'),
  ('e0000000-0000-0000-0000-000000000008', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000002',
   'Lucía Méndez', 'azul', 'en_espera', 'SRID=4326;POINT(-117.0352 32.4922)', now() - interval '38 minutes',
   null, null, null, 'Crisis de ansiedad, sin lesiones.', null, true,
   '{"gender":"femenino","birth_year":2017}',
   null, null, 'a0000000-0000-0000-0000-000000000002', now() - interval '38 minutes'),

  -- Incidente 3: riña
  ('e0000000-0000-0000-0000-000000000009', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000003',
   'Raúl Gómez', 'naranja', 'en_espera', 'SRID=4326;POINT(-117.0391 32.5391)', now() - interval '20 minutes',
   null, null, null, 'Herida por arma blanca en abdomen. Traslado rechazado por saturación, buscar otro hospital.',
   '{"ta_sist":"110","ta_diast":"70","fc":"115","respiratory_rate":"24","oxygen_saturation":"94"}', false,
   '{"gender":"masculino","birth_year":1990,"injury_types":["laceracion","hemorragia"]}',
   null, null, 'a0000000-0000-0000-0000-000000000003', now() - interval '20 minutes'),
  ('e0000000-0000-0000-0000-000000000010', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000003',
   null, 'verde', 'en_espera', 'SRID=4326;POINT(-117.0388 32.5389)', now() - interval '18 minutes',
   null, null, null, 'Contusión en brazo.', null, false, '{"gender":"masculino","injury_types":["luxacion"]}',
   null, null, 'a0000000-0000-0000-0000-000000000003', now() - interval '18 minutes'),

  -- Incidente 4 (cerrado): todos con alta
  ('e0000000-0000-0000-0000-000000000011', gen_random_uuid(), 'd0000000-0000-0000-0000-000000000004',
   'Fernanda Ruiz', 'amarillo', 'alta_medica', 'SRID=4326;POINT(-116.9501 32.5471)', now() - interval '1 day 3 hours',
   'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'REG-2026-0095',
   'Inhalación de humo.', '{"oxygen_saturation":"92","fc":"100"}', false,
   '{"gender":"femenino","birth_year":1995,"injury_types":["lesionRespiratoria","quemadura"]}',
   now() - interval '1 day 2 hours', now() - interval '1 day 1 hour', 'a0000000-0000-0000-0000-000000000003', now() - interval '1 day 3 hours'),

  -- Registro rápido sin incidente (paramédico)
  ('e0000000-0000-0000-0000-000000000012', gen_random_uuid(), null,
   'Ernesto Vega', 'amarillo', 'en_espera', 'SRID=4326;POINT(-117.0200 32.5300)', now() - interval '15 minutes',
   null, null, null, 'Caída de su propia altura en vía pública.', null, false,
   '{"gender":"masculino","birth_year":1950,"injury_types":["fractura"],"medications":"Losartán"}',
   null, null, 'a0000000-0000-0000-0000-000000000003', now() - interval '15 minutes'),

  -- Walk-in registrado por médico en el hospital (dispara notificación a medico2)
  ('e0000000-0000-0000-0000-000000000013', gen_random_uuid(), null,
   'Claudia Navarro', 'verde', 'recibido', null, null,
   'b0000000-0000-0000-0000-000000000001', null, null, 'Llega por su cuenta con esguince de tobillo.',
   '{"ta_sist":"120","ta_diast":"78","fc":"80","temperature":"36.6"}', false,
   '{"gender":"femenino","birth_year":1988,"birth_month":9,"birth_day":3,"seguro_medico":"no"}',
   null, null, 'a0000000-0000-0000-0000-000000000004', now() - interval '30 minutes');

-- Traslado cancelado por el hospital (paciente 9 regresó a en_espera) -----------
insert into public.medico_rejected_transfers (hospital_id, patient_id, reason, created_by, created_at) values
  ('b0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000009',
   'Sin quirófano disponible', 'a0000000-0000-0000-0000-000000000006', now() - interval '12 minutes');

insert into public.paramedic_notifications (recipient_id, patient_id, title, body, kind, metadata, created_at) values
  ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000009',
   'Traslado cancelado', 'Hospital Ángeles Tijuana canceló el traslado de Raúl Gómez: Sin quirófano disponible',
   'transfer_cancelled',
   '{"hospital_id":"b0000000-0000-0000-0000-000000000002","reason":"Sin quirófano disponible"}',
   now() - interval '12 minutes');

-- Códigos de consulta (alfabeto de create_consultation_code: sin I, L, O, 0, 1) ---
insert into public.consultation_codes (patient_id, code, expires_at, created_by) values
  ('e0000000-0000-0000-0000-000000000001', 'TRG234', now() + interval '30 days', 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-000000000006', 'HSP567', now() + interval '30 days', 'a0000000-0000-0000-0000-000000000002'),
  ('e0000000-0000-0000-0000-000000000011', 'AXT789', now() + interval '30 days', 'a0000000-0000-0000-0000-000000000003');
