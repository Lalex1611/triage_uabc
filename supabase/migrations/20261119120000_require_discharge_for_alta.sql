-- 17 · Alta médica solo con registro de alta.
-- Un médico no puede pasar a un paciente a alta_medica con un UPDATE directo:
-- debe existir su fila en patient_discharges (destino y nota), lo que solo
-- ocurre con medico_discharge_patient(). Esa RPC inserta el alta antes de
-- cambiar el estado, así que sigue funcionando igual.

create or replace function public.guard_patient_update()
returns trigger
language plpgsql
as $$
declare
  v_role public.user_role;
begin
  -- service role / SQL directo / RPC internas
  if auth.uid() is null or current_setting('app.internal_rpc', true) = 'on' then
    return new;
  end if;

  v_role := public.app_current_role();

  if new.id is distinct from old.id
     or new.sync_client_id is distinct from old.sync_client_id
     or new.created_by is distinct from old.created_by then
    raise exception 'id, sync_client_id y created_by no se pueden modificar';
  end if;

  if v_role = 'admin' then
    return new;

  elsif v_role = 'paramedico' then
    -- 'recibido' lo marca el hospital; el regreso a en_espera solo ocurre vía cancelación del hospital.
    if new.status is distinct from old.status
       and new.status not in ('trasladando', 'alta_medica') then
      raise exception 'Un paramédico solo puede pasar un paciente a trasladando o alta_medica';
    end if;

  elsif v_role = 'medico' then
    if new.status is distinct from old.status
       and new.status not in ('recibido', 'alta_medica') then
      raise exception 'El personal hospitalario solo puede pasar un paciente a recibido o alta_medica';
    end if;
    -- El alta médica requiere su registro (destino y nota)
    if new.status = 'alta_medica'
       and old.status is distinct from new.status
       and not exists (
         select 1 from public.patient_discharges d where d.patient_id = new.id
       ) then
      raise exception 'Registre el alta del paciente (a dónde sale) para darlo de alta';
    end if;
    if new.triage_color is distinct from old.triage_color
       or new.hospital_id is distinct from old.hospital_id
       or new.ambulance_unit_id is distinct from old.ambulance_unit_id
       or new.regulation_folio is distinct from old.regulation_folio
       or new.incident_id is distinct from old.incident_id
       or new.location is distinct from old.location then
      raise exception 'El personal hospitalario solo puede modificar estado y datos clínicos';
    end if;

  else
    raise exception 'Rol sin permiso para modificar pacientes';
  end if;

  return new;
end;
$$;

notify pgrst, 'reload schema';
