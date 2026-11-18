-- 11 · Registro de paciente que llega por su cuenta (médico, mockups 07-08).
-- Antes la app insertaba el paciente y luego pedía el código de consulta en otra
-- llamada: si la segunda fallaba quedaba un paciente sin código. Esta RPC hace
-- las dos cosas en una sola transacción y toma el hospital del perfil del médico.
--
-- Corre como el usuario (security invoker): la política
-- patients_insert_medico_walk_in sigue aplicando al insert.

create or replace function public.medico_register_walk_in_patient(
  p_display_name text,
  p_triage_color public.triage_color,
  p_demographics jsonb default '{}'::jsonb,
  p_vital_signs jsonb default null,
  p_descriptive_notes text default null
)
returns jsonb
language plpgsql
volatile
security invoker
set search_path = public
as $$
declare
  v_hospital uuid := public.app_current_hospital_id();
  v_name text := nullif(trim(coalesce(p_display_name, '')), '');
  v_notes text := nullif(trim(coalesce(p_descriptive_notes, '')), '');
  v_patient uuid;
  v_code text;
begin
  if public.app_current_role() is distinct from 'medico'::public.user_role then
    raise exception 'forbidden';
  end if;
  if v_hospital is null then
    raise exception 'Su perfil no tiene hospital asignado';
  end if;
  if v_name is null then
    raise exception 'Escribe el nombre del paciente o "desconocido"';
  end if;
  -- Triage hospitalario: niveles 1 (rojo) a 5 (azul); negro no aplica.
  if p_triage_color is null or p_triage_color = 'negro'::public.triage_color then
    raise exception 'Selecciona un nivel de triage';
  end if;
  if p_demographics is not null and jsonb_typeof(p_demographics) <> 'object' then
    raise exception 'Datos del paciente inválidos';
  end if;
  if p_vital_signs is not null and jsonb_typeof(p_vital_signs) <> 'object' then
    raise exception 'Signos vitales inválidos';
  end if;

  insert into public.patients (
    sync_client_id,
    hospital_id,
    triage_color,
    status,
    display_name,
    demographics,
    vital_signs,
    descriptive_notes,
    created_by
  )
  values (
    gen_random_uuid(),
    v_hospital,
    p_triage_color,
    'recibido',
    v_name,
    coalesce(p_demographics, '{}'::jsonb),
    nullif(p_vital_signs, '{}'::jsonb),
    v_notes,
    auth.uid()
  )
  returning id into v_patient;

  v_code := public.create_consultation_code(v_patient);

  return jsonb_build_object(
    'patient_id', v_patient,
    'consultation_code', v_code
  );
end;
$$;

revoke all on function public.medico_register_walk_in_patient(text, public.triage_color, jsonb, jsonb, text) from public;
grant execute on function public.medico_register_walk_in_patient(text, public.triage_color, jsonb, jsonb, text) to authenticated;

notify pgrst, 'reload schema';
