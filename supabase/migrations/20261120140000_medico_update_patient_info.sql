-- 20 · Editar datos del paciente sin borrar fotos agregadas mientras tanto.
-- El formulario de edición guarda demographics completo a partir de lo que
-- leyó al abrirse; si en ese lapso alguien agregó una foto
-- (medico_append_patient_photo), el guardado la borraba. El formulario no
-- edita fotos, así que esta función guarda lo editado pero conserva
-- photo_local_paths tal como está en la fila al momento del UPDATE.
--
-- security invoker: aplican las mismas reglas que un UPDATE directo del
-- médico (RLS de su hospital y guard_patient_update).

create or replace function public.medico_update_patient_info(
  p_patient_id uuid,
  p_display_name text,
  p_demographics jsonb,
  p_vital_signs jsonb
)
returns void
language plpgsql
volatile
security invoker
set search_path = public
as $$
begin
  update public.patients
  set display_name = btrim(coalesce(p_display_name, '')),
      demographics = case
        when demographics ? 'photo_local_paths' then
          (coalesce(p_demographics, '{}'::jsonb) - 'photo_local_paths')
            || jsonb_build_object('photo_local_paths', demographics -> 'photo_local_paths')
        else coalesce(p_demographics, '{}'::jsonb) - 'photo_local_paths'
      end,
      vital_signs = case
        when p_vital_signs is null or p_vital_signs = '{}'::jsonb then null
        else p_vital_signs
      end
  where id = p_patient_id
    and is_deleted = false;

  if not found then
    raise exception 'Paciente no encontrado';
  end if;
end;
$$;

revoke all on function public.medico_update_patient_info(uuid, text, jsonb, jsonb) from public;
grant execute on function public.medico_update_patient_info(uuid, text, jsonb, jsonb) to authenticated;

notify pgrst, 'reload schema';
