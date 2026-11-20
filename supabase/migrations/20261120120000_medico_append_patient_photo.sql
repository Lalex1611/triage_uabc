-- 18 · Agregar foto al expediente sin pisar otros datos.
-- La app leía demographics, le agregaba la foto y reescribía el JSON
-- completo; si otro médico editaba al paciente mientras se tomaba la foto,
-- sus cambios se perdían. Esta función agrega la ruta al arreglo
-- photo_local_paths en un solo UPDATE sobre la fila actual y no toca el
-- resto de demographics.
--
-- security invoker: aplican las mismas reglas que un UPDATE directo del
-- médico (RLS de su hospital y guard_patient_update).

create or replace function public.medico_append_patient_photo(
  p_patient_id uuid,
  p_path text
)
returns void
language plpgsql
volatile
security invoker
set search_path = public
as $$
declare
  v_path text := nullif(btrim(coalesce(p_path, '')), '');
begin
  if v_path is null then
    raise exception 'La foto no tiene ruta';
  end if;

  update public.patients
  set demographics = jsonb_set(
    coalesce(demographics, '{}'::jsonb),
    '{photo_local_paths}',
    case
      when jsonb_typeof(demographics -> 'photo_local_paths') = 'array'
        then (demographics -> 'photo_local_paths') || to_jsonb(v_path)
      else jsonb_build_array(v_path)
    end,
    true
  )
  where id = p_patient_id
    and is_deleted = false;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;
end;
$$;

revoke all on function public.medico_append_patient_photo(uuid, text) from public;
grant execute on function public.medico_append_patient_photo(uuid, text) to authenticated;

notify pgrst, 'reload schema';
