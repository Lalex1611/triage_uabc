-- Fotos del incidente en Storage
-- Ruta obligatoria: {incident_id}/{archivo}
-- Las ve quien puede ver el incidente (RLS de incidents); las cambia quien puede editarlo.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'incident_photos',
  'incident_photos',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
on conflict (id) do nothing;

comment on column public.incidents.photo_local_paths is
  'Rutas {incident_id}/{archivo} del bucket incident_photos. Las que empiezan con / son rutas locales antiguas.';

create policy incident_photos_select on storage.objects for select to authenticated
  using (
    bucket_id = 'incident_photos'
    and public.app_current_role() in ('admin', 'paramedico', 'medico')
    and exists (
      select 1 from public.incidents i
      where i.id::text = (storage.foldername(name))[1]
    )
  );

create policy incident_photos_insert on storage.objects for insert to authenticated
  with check (
    bucket_id = 'incident_photos'
    and exists (
      select 1 from public.incidents i
      where i.id::text = (storage.foldername(name))[1]
        and (
          public.app_current_role() = 'admin'
          or (public.app_current_role() = 'paramedico' and i.created_by = auth.uid())
        )
    )
  );

create policy incident_photos_delete on storage.objects for delete to authenticated
  using (
    bucket_id = 'incident_photos'
    and exists (
      select 1 from public.incidents i
      where i.id::text = (storage.foldername(name))[1]
        and (
          public.app_current_role() = 'admin'
          or (public.app_current_role() = 'paramedico' and i.created_by = auth.uid())
        )
    )
  );
