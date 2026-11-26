-- Datos previos a la migración de limpieza. El ejecutor revierte esta prueba.
do $$
declare
  owner_id uuid := 'a0800000-0000-0000-0000-000000000027';
  patient_id uuid := 'a0820000-0000-0000-0000-000000000027';
  other_id uuid := 'a0820000-0000-0000-0000-000000000028';
  first_path text := patient_id || '/z.jpg';
  second_path text := patient_id || '/a.jpg';
  foreign_path text := other_id || '/foto.jpg';
begin
  insert into auth.users(id,email) values (owner_id,'limpieza@example.test');
  insert into public.patients(id,sync_client_id,triage_color,created_by,demographics)
  values
    (patient_id,patient_id,'verde',owner_id,jsonb_build_object('nota','conservar',
      'photo_storage_paths',jsonb_build_array(first_path,foreign_path,null,second_path))),
    (other_id,other_id,'verde',owner_id,'{"photo_storage_paths":null}');
  insert into storage.objects(bucket_id,name,owner_id) values
    ('patient_photos',first_path,owner_id::text),
    ('patient_photos',second_path,owner_id::text),
    ('patient_photos',foreign_path,owner_id::text);
end;
$$;
create temporary table objetos_antes as table storage.objects;

create function pg_temp.verificar_limpieza() returns void language plpgsql as $$
declare
  patient_id uuid := 'a0820000-0000-0000-0000-000000000027';
begin
  assert (select demographics = jsonb_build_object('nota','conservar',
    'photo_storage_paths',jsonb_build_array(patient_id || '/z.jpg',patient_id || '/a.jpg'))
    from public.patients where id=patient_id), 'Se alteraron las rutas válidas o su orden';
  assert (select demographics = '{"photo_storage_paths":[]}'::jsonb from public.patients
    where id='a0820000-0000-0000-0000-000000000028'), 'No se normalizó la lista nula';
  assert not exists ((table objetos_antes except all table storage.objects)
    union all (table storage.objects except all table objetos_antes)), 'Se modificó Storage';
end;
$$;
