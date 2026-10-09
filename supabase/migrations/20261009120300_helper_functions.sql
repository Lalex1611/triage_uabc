-- 4/8 · Funciones auxiliares (usadas por triggers y por RLS)

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.patient_status_rank(s public.patient_lifecycle_status)
returns int
language sql
immutable
as $$
  select case s
    when 'en_espera' then 1
    when 'trasladando' then 2
    when 'recibido' then 3
    when 'alta_medica' then 4
  end;
$$;

-- Rol del usuario autenticado. Usuarios desactivados => null => sin acceso.
-- (Se llama app_current_role para no chocar con el built-in current_role de Postgres.)
create or replace function public.app_current_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role
  from public.profiles
  where id = auth.uid() and is_active = true
  limit 1;
$$;

-- Hospital donde trabaja el usuario autenticado (null si no tiene asignado).
create or replace function public.app_current_hospital_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select hospital_id
  from public.profiles
  where id = auth.uid() and is_active = true
  limit 1;
$$;