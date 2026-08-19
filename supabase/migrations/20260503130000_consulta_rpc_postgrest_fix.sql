-- Repara visibilidad PostgREST / permisos para RPC de consulta

grant usage on schema public to anon, authenticated;

grant execute on function public.get_patient_status_by_code(text) to anon, authenticated, service_role;

do $$
begin
  execute 'alter function public.get_patient_status_by_code(text) owner to postgres';
exception
  when insufficient_privilege then null;
end;
$$;

notify pgrst, 'reload schema';
