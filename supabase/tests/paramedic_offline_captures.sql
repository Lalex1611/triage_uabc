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
    'demographics',jsonb_build_object('description','Datos ficticios'),'lat',32.5,'lng',-117.0,
    'captured_at','2026-11-16T12:00:00Z');
  first_result := public.sync_paramedic_capture(a,'patient',p,patient);
  again := public.sync_paramedic_capture(a,'patient',p,patient);
  assert first_result=again, 'patient/code replay changed result';
  assert (select count(*)=1 from public.patients where sync_client_id=p), 'duplicate patient';
  assert (select count(*)=1 from public.consultation_codes where patient_id=p), 'duplicate consultation code';
  assert (select location is not null and incident_id=i from public.patients where id=p), 'location or parent missing';
  assert (select location_captured_at='2026-11-16T12:00:00Z'::timestamptz from public.patients where id=p), 'capture date missing';
  begin
    perform 1 from public.paramedic_capture_receipts;
    raise exception 'Expected private receipt rejection';
  exception when insufficient_privilege then null; end;
  assert (public.get_patient_status_by_code(first_result->>'code')->>'found')::boolean, 'consultation contract broken';
  begin
    perform public.sync_paramedic_capture(a,'patient','a0820000-0000-0000-0000-000000000002',patient||'{"lat":100}');
    raise exception 'Expected invalid coordinates';
  exception when invalid_parameter_value then null; end;
  assert not exists(select 1 from public.patients where id='a0820000-0000-0000-0000-000000000002'), 'partial patient';
  photo := p::text||'/a0830000-0000-0000-0000-000000000001.jpg';
  begin
    perform public.link_paramedic_capture_photo(a,'patient',p,photo);
    raise exception 'Expected missing upload';
  exception when invalid_parameter_value then null; end;
  insert into storage.objects(bucket_id,name,owner_id) values('patient_photos',photo,a::text);
  perform public.link_paramedic_capture_photo(a,'patient',p,photo);
  perform public.link_paramedic_capture_photo(a,'patient',p,photo);
  assert (select jsonb_array_length(demographics->'photo_storage_paths')=1 from public.patients where id=p), 'duplicate photo link';
  photo := i::text||'/a0830000-0000-0000-0000-000000000002.jpg';
  insert into storage.objects(bucket_id,name,owner_id) values('incident_photos',photo,a::text);
  perform public.link_paramedic_capture_photo(a,'incident',i,photo);
  perform public.link_paramedic_capture_photo(a,'incident',i,photo);
  assert (select cardinality(photo_local_paths)=1 from public.incidents where id=i), 'duplicate incident photo';
  perform set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000002',true);
  begin
    perform public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000002','incident',i,request);
    raise exception 'Expected owner rejection';
  exception when insufficient_privilege then null; end;
  begin
    perform public.link_paramedic_capture_photo('a0800000-0000-0000-0000-000000000002','incident',i,photo);
    raise exception 'Expected photo owner rejection';
  exception when insufficient_privilege then null; end;
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
begin raise exception 'simulated code failure'; end; $$;
create trigger a08_code_failure before insert on public.consultation_codes for each row execute function public.a08_fail_code();
set local role authenticated;
select set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000001',true);
do $$
begin
  begin
    perform public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000001','patient',
      'a0820000-0000-0000-0000-000000000003','{"incident_id":"a0810000-0000-0000-0000-000000000001","triage_color":"verde","demographics":{},"lat":32.5,"lng":-117}');
    raise exception using errcode='22023',message='Expected code failure';
  exception when raise_exception then null; end;
  assert not exists(select 1 from public.patients where id='a0820000-0000-0000-0000-000000000003'), 'partial patient after code failure';
end;
$$;
rollback;
