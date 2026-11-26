-- Las escrituras desde la API deben indicar qué foto se quiere cambiar.
create function public.guard_incident_photo_list_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('anon', 'authenticated', 'service_role') then
    raise exception using errcode = '42501',
      message = 'Vuelve a abrir el incidente y modifica las fotos por separado';
  end if;
  return null;
end;
$$;

create trigger guard_incident_photo_list_update
before update of photo_local_paths on public.incidents
for each statement execute function public.guard_incident_photo_list_update();

create or replace function public.paramedico_update_incident_photo_path(
  p_incident_id uuid,
  p_path text,
  p_remove boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_path is null or btrim(p_path) = '' or p_remove is null then
    raise exception using errcode = '22023', message = 'Ruta de foto inválida';
  end if;

  -- Aplica los mismos permisos que las políticas de actualización de incidentes.
  -- El disparador registra el retiro sobre el valor vigente de la fila.
  update public.incidents
    set photo_local_paths = case
      when p_remove then array_remove(photo_local_paths, p_path)
      when p_path = any(photo_local_paths) then photo_local_paths
      else array_append(photo_local_paths, p_path)
    end
    where id = p_incident_id and not is_deleted
      and auth.uid() is not null
      and (
        public.app_current_role() = 'admin'
        or (public.app_current_role() = 'paramedico' and created_by = auth.uid())
      );
  if not found then
    raise exception using errcode = '42501', message = 'Incidente no disponible para esta cuenta';
  end if;
end;
$$;

notify pgrst, 'reload schema';
