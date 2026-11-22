-- Ejecutar en una base aislada con las migraciones de Médico y A08.
begin;

insert into public.hospitals (id, name) values
  ('a8400000-0000-0000-0000-000000000001', 'Hospital ficticio 1'),
  ('a8400000-0000-0000-0000-000000000002', 'Hospital ficticio 2');
insert into auth.users (id, email, raw_user_meta_data) values
  ('a8410000-0000-0000-0000-000000000001', 'medico-a08-a@example.test', '{}'),
  ('a8410000-0000-0000-0000-000000000002', 'medico-a08-b@example.test', '{}'),
  ('a8410000-0000-0000-0000-000000000003', 'medico-a08-c@example.test', '{}');
update public.profiles set role = 'medico', hospital_id = 'a8400000-0000-0000-0000-000000000001'
  where id in ('a8410000-0000-0000-0000-000000000001', 'a8410000-0000-0000-0000-000000000002');
update public.profiles set role = 'medico', hospital_id = 'a8400000-0000-0000-0000-000000000002'
  where id = 'a8410000-0000-0000-0000-000000000003';

set local role authenticated;

do $$
declare
  actor uuid := 'a8410000-0000-0000-0000-000000000001';
  colleague uuid := 'a8410000-0000-0000-0000-000000000002';
  other_hospital uuid := 'a8410000-0000-0000-0000-000000000003';
  hospital uuid := 'a8400000-0000-0000-0000-000000000001';
  capture_id uuid := 'a8420000-0000-0000-0000-000000000001';
  request jsonb := jsonb_build_object(
    'hospital_id', hospital, 'display_name', 'Paciente ficticio A08 Médico',
    'triage_color', 'verde', 'demographics', '{"blood_type":"oPositivo"}'::jsonb,
    'vital_signs', '{"heart_rate":72}'::jsonb, 'descriptive_notes', 'Motivo ficticio'
  );
  confirmed jsonb;
  patient uuid;
  photo text;
begin
  perform set_config('request.jwt.claim.sub', actor::text, true);
  confirmed := public.sync_medico_walk_in_capture(actor, capture_id, request);
  patient := (confirmed->>'id')::uuid;
  assert patient is not null and length(confirmed->>'code') = 6, 'Faltó confirmación o código';
  assert confirmed = public.sync_medico_walk_in_capture(actor, capture_id, request), 'Reintento distinto';
  assert (select count(*) = 1 from public.patients where created_by = actor), 'Paciente duplicado';
  assert (select count(*) = 1 from public.consultation_codes where patient_id = patient), 'Código duplicado';
  assert (select hospital_id = hospital and status = 'recibido' and incident_id is null
      and vital_signs = '{"heart_rate":72}'::jsonb and descriptive_notes = 'Motivo ficticio'
      from public.patients where id = patient), 'El alta no conserva los campos del formulario';

  begin
    perform public.sync_medico_walk_in_capture(actor, capture_id, request || '{"triage_color":"azul"}');
    raise exception 'Se esperaba conflicto de captura';
  exception when unique_violation then null;
  end;
  begin
    perform 1 from public.medico_walk_in_capture_receipts;
    raise exception 'Se esperaba que los comprobantes fueran privados';
  exception when insufficient_privilege then null;
  end;

  photo := patient::text || '/a8430000-0000-0000-0000-000000000001.jpg';
  begin
    perform public.link_medico_walk_in_photo(actor, patient, photo);
    raise exception 'No se esperaba confirmar una foto sin subir';
  exception when insufficient_privilege then null;
  end;
  insert into storage.objects (bucket_id, name, owner_id) values ('patient_photos', photo, actor::text);
  perform public.link_medico_walk_in_photo(actor, patient, photo);
  perform public.link_medico_walk_in_photo(actor, patient, photo);

  perform set_config('request.jwt.claim.sub', colleague::text, true);
  begin
    perform public.sync_medico_walk_in_capture(colleague, capture_id, request);
    raise exception 'Otra cuenta reutilizó un comprobante';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.link_medico_walk_in_photo(colleague, patient, photo);
    raise exception 'Otra cuenta confirmó un adjunto ajeno';
  exception when insufficient_privilege then null;
  end;

  perform public.medico_update_patient_info(patient, 'Paciente ficticio editado',
    '{"blood_type":"aPositivo","photo_storage_paths":["ruta antigua"]}', '{"heart_rate":75}');
  assert (select demographics->'photo_storage_paths' = jsonb_build_array(photo)
    and demographics->>'blood_type' = 'aPositivo' from public.patients where id = patient),
    'La edición reemplazó las fotos remotas';

  perform set_config('request.jwt.claim.sub', other_hospital::text, true);
  assert not exists (select 1 from public.patients where id = patient), 'Paciente visible en otro hospital';
  begin
    perform public.sync_medico_walk_in_capture(other_hospital, capture_id, request);
    raise exception 'Otro hospital recibió una captura ajena';
  exception when insufficient_privilege then null;
  end;
end;
$$;

rollback;
