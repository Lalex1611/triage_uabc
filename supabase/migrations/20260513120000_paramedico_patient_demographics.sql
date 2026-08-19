-- Campos adicionales para el flujo paramédico (registro / detalle en app)
-- demographics: JSON libre (lesiones, texto, fechas nacimiento, paths de fotos, respuestas START, etc.)

alter table public.patients
  add column if not exists display_name text;

alter table public.patients
  add column if not exists demographics jsonb not null default '{}'::jsonb;

comment on column public.patients.display_name is 'Nombre corto o alias mostrado en tarjetas y cabeceras.';
comment on column public.patients.demographics is 'Datos START/registro no normalizados (JSON).';

-- Bucket para fotos clínicas; paths sugeridos: {auth.uid()}/{patient_id}/{filename}
insert into storage.buckets (id, name, public)
values ('patient_photos', 'patient_photos', false)
on conflict (id) do nothing;

drop policy if exists patient_photos_select on storage.objects;
drop policy if exists patient_photos_insert on storage.objects;
drop policy if exists patient_photos_update on storage.objects;
drop policy if exists patient_photos_delete on storage.objects;

create policy patient_photos_select on storage.objects for
select
  to authenticated using (bucket_id = 'patient_photos');

create policy patient_photos_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'patient_photos'
  and name like (auth.uid ()::text || '/%')
);

create policy patient_photos_update on storage.objects for
update
  to authenticated using (bucket_id = 'patient_photos' and name like (auth.uid ()::text || '/%'))
with check (
  bucket_id = 'patient_photos'
  and name like (auth.uid ()::text || '/%')
);

create policy patient_photos_delete on storage.objects for delete to authenticated using (
  bucket_id = 'patient_photos'
  and name like (auth.uid ()::text || '/%')
);
