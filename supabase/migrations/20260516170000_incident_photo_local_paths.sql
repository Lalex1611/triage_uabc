-- Rutas locales de fotografías generales del incidente capturadas en la app.
-- Mantiene el mismo enfoque actual de pacientes (`photo_local_paths`) hasta
-- que se conecte Storage real para archivos binarios.
alter table public.incidents
  add column if not exists photo_local_paths text[] not null default '{}';

comment on column public.incidents.photo_local_paths is
  'Rutas locales de fotos generales del incidente capturadas desde la app paramédica.';
