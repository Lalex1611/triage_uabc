-- Ejecutar solo en una base de pruebas aislada con todas las migraciones.
-- Los datos de prueba se revierten al final.
begin;
insert into auth.users(id,email,raw_user_meta_data) values
 ('a0800000-0000-0000-0000-000000000001','a08-paramedic-a@example.test','{}'),
 ('a0800000-0000-0000-0000-000000000002','a08-paramedic-b@example.test','{}'),
 ('a0800000-0000-0000-0000-000000000003','a08-reader@example.test','{}'),
 ('a0800000-0000-0000-0000-000000000004','a08-doctor@example.test','{}');
update public.profiles set role='paramedico' where id in
 ('a0800000-0000-0000-0000-000000000001','a0800000-0000-0000-0000-000000000002');
update public.profiles set role='medico' where id='a0800000-0000-0000-0000-000000000004';
set local role authenticated;
select set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000001',true);
do $$
declare
  a uuid := 'a0800000-0000-0000-0000-000000000001';
  i uuid := 'a0810000-0000-0000-0000-000000000001';
  p uuid := 'a0820000-0000-0000-0000-000000000001';
  request jsonb := '{"title":"Incidente ficticio A08","emergency_type":"otro","lat":32.5,"lng":-117.0,"description":"Prueba"}';
  patient jsonb;
  first_result jsonb;
  again jsonb;
  photo text;
  other_photo text;
begin
  first_result := public.sync_paramedic_capture(a,'incident',i,request);
  again := public.sync_paramedic_capture(a,'incident',i,request);
  assert first_result=again, 'incident replay changed result';
  assert (select count(*)=1 from public.incidents where sync_client_id=i), 'duplicate incident';
  begin
    perform public.sync_paramedic_capture(a,'incident',i,request||'{"title":"Incompatible"}');
    raise exception 'Expected conflict';
  exception when unique_violation then null; end;
  patient := jsonb_build_object('incident_id',i,'triage_color','verde','display_name','Paciente ficticio A08',
    'demographics','{"description":"Datos ficticios","photo_local_paths":["local.jpg"],"photo_storage_paths":["sin-verificar.jpg"]}'::jsonb,
    'lat',32.5,'lng',-117.0,
    'captured_at','2026-11-16T12:00:00Z');
  first_result := public.sync_paramedic_capture(a,'patient',p,patient);
  again := public.sync_paramedic_capture(a,'patient',p,patient);
  assert first_result=again, 'patient/code replay changed result';
  assert (select count(*)=1 from public.patients where sync_client_id=p), 'duplicate patient';
  assert (select count(*)=1 from public.consultation_codes where patient_id=p), 'duplicate consultation code';
  assert (select location is not null and incident_id=i from public.patients where id=p), 'location or parent missing';
  assert (select location_captured_at='2026-11-16T12:00:00Z'::timestamptz from public.patients where id=p), 'capture date missing';
  assert (select demographics = '{"description":"Datos ficticios"}'::jsonb
    from public.patients where id=p), 'Se aceptaron referencias a fotos sin verificar';
  begin
    perform 1 from public.paramedic_capture_receipts;
    raise exception 'Expected private receipt rejection';
  exception when insufficient_privilege then null; end;
  assert (public.get_patient_status_by_code(first_result->>'code')->>'found')::boolean, 'consultation contract broken';
  reset role;
  update public.consultation_codes set expires_at = now() - interval '1 day'
    where patient_id = p;
  set local role authenticated;
  again := public.sync_paramedic_capture(a,'patient',p,patient);
  assert again = jsonb_build_object('id',p,'code',null), 'El reintento devolvió un código vencido';
  reset role;
  update public.consultation_codes set expires_at = now() + interval '1 day', revoked_at = now()
    where patient_id = p;
  set local role authenticated;
  again := public.sync_paramedic_capture(a,'patient',p,patient);
  assert again = jsonb_build_object('id',p,'code',null), 'El reintento devolvió un código revocado';
  assert (select count(*)=1 from public.patients where sync_client_id=p), 'Se duplicó el paciente';
  assert (select count(*)=1 from public.consultation_codes where patient_id=p), 'Se generó otro código';
  begin
    perform public.sync_paramedic_capture(a,'patient','a0820000-0000-0000-0000-000000000002',patient||'{"lat":100}');
    raise exception 'Expected invalid coordinates';
  exception when invalid_parameter_value then null; end;
  assert not exists(select 1 from public.patients where id='a0820000-0000-0000-0000-000000000002'), 'partial patient';
  photo := p::text||'/a0830000-0000-0000-0000-000000000001.jpg';
  begin
    perform public.link_paramedic_capture_photo(a,'patient',p,photo);
    raise exception 'Expected missing upload';
  exception when sqlstate 'P0801' then null; end;
  other_photo := p::text||'/a0830000-0000-0000-0000-000000000003.jpg';
  insert into storage.objects(bucket_id,name,owner_id)
    values('patient_photos',other_photo,'a0800000-0000-0000-0000-000000000002');
  begin
    perform public.link_paramedic_capture_photo(a,'patient',p,other_photo);
    raise exception 'Se esperaba rechazar el archivo de otra cuenta';
  exception when insufficient_privilege then null; end;
  insert into storage.objects(bucket_id,name,owner_id) values('patient_photos',photo,a::text);
  reset role;
  update public.patients set demographics = demographics || '{"photo_storage_paths":{"legacy":true}}'
    where id = p;
  set local role authenticated;
  perform public.link_paramedic_capture_photo(a,'patient',p,photo);
  perform public.link_paramedic_capture_photo(a,'patient',p,photo);
  assert (select jsonb_array_length(demographics->'photo_storage_paths')=1 from public.patients where id=p), 'duplicate photo link';
  perform public.paramedico_update_patient_record(
    p,
    '{"description":"Descripción editada","photo_local_paths":["foto-local.jpg"],"photo_storage_paths":["ruta antigua"]}',
    p_display_name => 'Paciente ficticio editado',
    p_triage_color => 'amarillo'
  );
  assert (select display_name = 'Paciente ficticio editado' and triage_color = 'amarillo'
      and demographics->>'description' = 'Descripción editada'
      and demographics->'photo_local_paths' = '["foto-local.jpg"]'::jsonb
      and demographics->'photo_storage_paths' = jsonb_build_array(photo)
    from public.patients where id = p), 'La edición reemplazó fotos verificadas o perdió datos del formulario';
  perform public.paramedico_update_patient_record(p, '{"description":"Otra edición","photo_local_paths":[]}');
  assert (select demographics->'photo_local_paths' = '[]'::jsonb
      and demographics->'photo_storage_paths' = jsonb_build_array(photo)
    from public.patients where id = p), 'Se perdieron fotos remotas al quitar las fotos locales';
  photo := i::text||'/a0830000-0000-0000-0000-000000000002.jpg';
  insert into storage.objects(bucket_id,name,owner_id) values('incident_photos',photo,a::text);
  perform public.link_paramedic_capture_photo(a,'incident',i,photo);
  perform public.link_paramedic_capture_photo(a,'incident',i,photo);
  assert (select cardinality(photo_local_paths)=1 from public.incidents where id=i), 'duplicate incident photo';
  other_photo := i::text||'/a0830000-0000-0000-0000-000000000003.jpg';
  perform public.paramedico_update_incident_photo_path(i, other_photo, false);
  perform public.paramedico_update_incident_photo_path(i, other_photo, false);
  assert (select photo_local_paths = array[photo, other_photo]
    from public.incidents where id = i), 'La foto manual duplicó o reemplazó un adjunto';
  perform public.paramedico_update_incident_photo_path(i, other_photo, true);
  assert (select photo_local_paths = array[photo]
    from public.incidents where id = i), 'Se quitó una foto distinta de la seleccionada';

  perform set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000002',true);
  begin
    perform public.paramedico_update_incident_photo_path(i, photo, true);
    raise exception 'Se esperaba rechazar la edición de un incidente ajeno';
  exception when insufficient_privilege then null; end;
  begin
    perform public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000002','incident',i,request);
    raise exception 'Expected owner rejection';
  exception when insufficient_privilege then null; end;
  begin
    perform public.link_paramedic_capture_photo('a0800000-0000-0000-0000-000000000002','incident',i,photo);
    raise exception 'Expected photo owner rejection';
  exception when insufficient_privilege then null; end;
  perform set_config('request.jwt.claim.sub',a::text,true);
  other_photo := i::text||'/a0830000-0000-0000-0000-000000000004.jpg';
  perform public.paramedico_update_incident_photo_path(i,other_photo,false);
  perform public.paramedico_update_incident_photo_path(i,photo,true);
  begin
    perform public.link_paramedic_capture_photo(a,'incident',i,photo);
    raise exception 'Se esperaba informar que la foto se retiró';
  exception when sqlstate 'P0802' then null; end;
  delete from storage.objects where bucket_id = 'incident_photos' and name = photo;
  assert not exists (select 1 from storage.objects where bucket_id = 'incident_photos' and name = photo),
    'La prueba no borró la foto de Storage';
  begin
    perform public.link_paramedic_capture_photo(a,'incident',i,photo);
    raise exception 'Se esperaba informar el retiro aunque el archivo no exista';
  exception when sqlstate 'P0802' then null; end;
  assert (select photo_local_paths = array[other_photo] from public.incidents where id=i),
    'Un reintento restauró una foto retirada';
  update public.incidents set photo_local_paths = array[photo, other_photo, '/local/foto.jpg']
    where id = i;
  assert (select photo_local_paths = array[other_photo, '/local/foto.jpg'] from public.incidents where id=i),
    'Una lista anterior restauró una foto retirada o alteró las demás rutas';
  -- Simula la publicación final por el servicio de Storage tras el retiro.
  reset role;
  begin
    insert into storage.objects(bucket_id,name,owner_id) values('incident_photos',photo,a::text);
    raise exception 'Se esperaba rechazar la publicación tardía de la foto retirada';
  exception when sqlstate 'P0802' then null; end;
  insert into storage.objects(bucket_id,name,owner_id) values('incident_photos',other_photo,a::text);
  begin
    update storage.objects set name = photo where bucket_id = 'incident_photos' and name = other_photo;
    raise exception 'Se esperaba rechazar el cambio de nombre a una ruta retirada';
  exception when sqlstate 'P0802' then null; end;
  assert not exists (select 1 from storage.objects where bucket_id='incident_photos' and name=photo),
    'La carga tardía dejó la ruta retirada en el bucket';
  assert exists (select 1 from storage.objects where bucket_id='incident_photos' and name=other_photo),
    'La protección de la ruta retirada afectó a otra foto';
  set local role authenticated;
  begin
    perform public.link_paramedic_capture_photo(a,'incident',i,
      i::text||'/a0830000-0000-0000-0000-000000000009.jpg');
    raise exception 'Se esperaba reponer un archivo ausente que sigue pendiente';
  exception when sqlstate 'P0801' then null; end;
  perform set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000003',true);
  assert (select count(*)=0 from public.patients), 'consulta externa read leaked';
  assert (select count(*)=0 from public.incidents), 'consulta externa incidents leaked';
  begin
    perform public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000003','incident',gen_random_uuid(),request);
    raise exception 'Expected role rejection';
  exception when insufficient_privilege then null; end;
  perform set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000004',true);
  assert (select count(*)=0 from public.patients), 'doctor without hospital read leaked';
end;
$$;
reset role;
-- Provoca un fallo al generar el código después de insertar al paciente para
-- comprobar que se revierta toda la transacción de la RPC.
create function public.a08_fail_code() returns trigger language plpgsql as $$
begin
  raise exception using errcode='P0899', message='Fallo simulado al generar el código';
end;
$$;
create trigger a08_code_failure before insert on public.consultation_codes for each row execute function public.a08_fail_code();
set local role authenticated;
select set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000001',true);
do $$
begin
  begin
    perform public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000001','patient',
      'a0820000-0000-0000-0000-000000000003','{"incident_id":"a0810000-0000-0000-0000-000000000001","triage_color":"verde","demographics":{},"lat":32.5,"lng":-117}');
    raise exception using errcode='22023',message='Expected code failure';
  exception when sqlstate 'P0899' then null; end;
  assert not exists(select 1 from public.patients where id='a0820000-0000-0000-0000-000000000003'), 'partial patient after code failure';
end;
$$;
rollback;
