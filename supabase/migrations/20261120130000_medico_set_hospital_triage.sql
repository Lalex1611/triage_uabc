-- 19 · Cambiar el triage hospitalario desde la vista en sala.
-- guard_patient_update no deja que el médico cambie triage_color con un
-- UPDATE directo. Esta RPC es la única vía para el médico: valida rol,
-- hospital y que el paciente esté en sala (recibido), y cambia solo
-- triage_color. El historial (patient_state_history) lo registra el trigger
-- de siempre, con el médico como autor.

create or replace function public.medico_set_hospital_triage(
  p_patient_id uuid,
  p_triage_color text
)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_patient public.patients%rowtype;
begin
  if public.app_current_role() is distinct from 'medico'::public.user_role then
    raise exception 'forbidden';
  end if;
  -- Triage hospitalario: niveles 1 (rojo) a 5 (azul); negro no aplica
  if p_triage_color is null
     or p_triage_color not in ('rojo', 'naranja', 'amarillo', 'verde', 'azul') then
    raise exception 'Elige un nivel de triage válido';
  end if;

  select * into v_patient
  from public.patients
  where id = p_patient_id and is_deleted = false
  for update;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;
  if v_patient.hospital_id is distinct from public.app_current_hospital_id() then
    raise exception 'El paciente no está asignado a su hospital';
  end if;
  if v_patient.status is distinct from 'recibido'::public.patient_lifecycle_status then
    raise exception 'Solo se puede cambiar el triage de un paciente que está en sala';
  end if;
  if v_patient.triage_color = p_triage_color::public.triage_color then
    return;
  end if;

  -- Salta guard_patient_update solo dentro de esta transacción
  perform set_config('app.internal_rpc', 'on', true);
  update public.patients
  set triage_color = p_triage_color::public.triage_color
  where id = p_patient_id;
  perform set_config('app.internal_rpc', 'off', true);
end;
$$;

revoke all on function public.medico_set_hospital_triage(uuid, text) from public;
grant execute on function public.medico_set_hospital_triage(uuid, text) to authenticated;

notify pgrst, 'reload schema';
