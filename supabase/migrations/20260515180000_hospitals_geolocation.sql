-- añadimos las coordenadas para los hospitales, asi tenemos un punto para mostrar en el mapa y exportar ruta.
alter table public.hospitals
  add column if not exists location geography (point, 4326);

comment on column public.hospitals.location is 'coordenadas del hospital para mostrar destino y exportar ruta.';

create index if not exists hospitals_location_gix
  on public.hospitals using gist (location)
  where
    is_deleted = false
    and location is not null;
