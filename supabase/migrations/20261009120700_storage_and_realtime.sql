-- 8/8 · Storage (fotos clínicas) y Realtime

-- Ruta obligatoria: {patient_id}/{archivo}
-- Solo admin/paramédico/médico, y solo de pacientes que ese usuario ya puede ver (RLS de patients).
insert into storage.buckets (id, name, public)
values ('patient_photos', 'patient_photos', false)
on conflict (id) do nothing;

create policy patient_photos_select on storage.objects for select to authenticated
  using (
    bucket_id = 'patient_photos'
    and public.app_current_role() in ('admin', 'paramedico', 'medico')
    and exists (
      select 1 from public.patients p
      where p.id::text = (storage.foldername(name))[1]
    )
  );

create policy patient_photos_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'patient_photos'
    and public.app_current_role() in ('admin', 'paramedico', 'medico')
    and exists (
      select 1 from public.patients p
      where p.id::text = (storage.foldername(name))[1]
    )
  );

create policy patient_photos_update on storage.objects for update to authenticated
  using (
    bucket_id = 'patient_photos'
    and public.app_current_role() in ('admin', 'paramedico', 'medico')
    and exists (select 1 from public.patients p where p.id::text = (storage.foldername(name))[1])
  )
  with check (
    bucket_id = 'patient_photos'
    and exists (select 1 from public.patients p where p.id::text = (storage.foldername(name))[1])
  );

create policy patient_photos_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'patient_photos'
    and public.app_current_role() in ('admin', 'paramedico', 'medico')
    and exists (select 1 from public.patients p where p.id::text = (storage.foldername(name))[1])
  );

-- Realtime
alter publication supabase_realtime add table public.incidents;
alter publication supabase_realtime add table public.patients;
alter publication supabase_realtime add table public.medico_notifications;
alter publication supabase_realtime add table public.paramedic_notifications;

alter table public.incidents replica identity full;
alter table public.patients replica identity full;