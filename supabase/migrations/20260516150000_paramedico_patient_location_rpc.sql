-- Guarda la ubicación del paciente desde la app paramédica sin exponer la
-- columna PostGIS a actualizaciones directas del cliente.
create or replace function public.paramedico_update_patient_location(
  p_patient_id uuid,
  p_lat double precision,
  p_lng double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_patient public.patients%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Sesión inválida';
  end if;

  if public.current_role() is distinct from 'paramedico'::public.user_role then
    raise exception 'Solo paramédicos pueden actualizar la ubicación del paciente';
  end if;

  if p_lat is null or p_lng is null or p_lat < -90 or p_lat > 90 or p_lng < -180 or p_lng > 180 then
    raise exception 'Coordenadas inválidas';
  end if;

  select *
  into v_patient
  from public.patients
  where id = p_patient_id
    and is_deleted = false;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;

  update public.patients
  set
    location = st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography,
    location_captured_at = now(),
    demographics = coalesce(demographics, '{}'::jsonb) || jsonb_build_object(
      'registration_lat', p_lat,
      'registration_lng', p_lng
    )
  where id = p_patient_id;
end;
$$;

revoke all on function public.paramedico_update_patient_location(uuid, double precision, double precision)
from public;

grant execute on function public.paramedico_update_patient_location(uuid, double precision, double precision)
to authenticated;

-- La pantalla de detalle permite editar datos clínicos/demográficos en cualquier
-- estado visible para paramédico. La política anterior dejaba fuera `recibido`,
-- lo que bloqueaba updates sin cambio de estado con "new row violates RLS".
drop policy if exists patients_update_paramedico on public.patients;

create policy patients_update_paramedico on public.patients for update
  to authenticated using (
    is_deleted = false
    and public.current_role() = 'paramedico'
  )
with check (
  public.current_role() = 'paramedico'
  and status in (
    'registrado',
    'en_espera',
    'trasladando',
    'recibido',
    'alta_medica'
  )
);
