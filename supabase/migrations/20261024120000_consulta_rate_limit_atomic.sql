-- 10 · Serializa el límite de consulta externa por clave de cliente.
-- Conserva la RPC, sus permisos, su respuesta y los 10 intentos en 5 minutos.

create or replace function public.get_patient_status_by_code(p_code text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_key text;
  v_status public.patient_lifecycle_status;
  v_status_changed_at timestamptz;
  v_hospital_id uuid;
  v_name text;
  v_address text;
  v_phone text;
begin
  v_key := coalesce(
    nullif(trim(split_part(
      coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for', ''),
      ',', 1)), ''),
    'unknown'
  );

  delete from public.consultation_lookup_attempts where created_at < now() - interval '1 day';

  -- Mismo cliente: contar y registrar en orden, incluso entre sesiones.
  -- El bloqueo se libera automáticamente al terminar la transacción.
  -- VOLATILE conserva una instantánea nueva para el conteo tras la espera.
  perform pg_advisory_xact_lock(
    hashtextextended('consulta_externa:get_patient_status_by_code:' || v_key, 0)
  );

  if (select count(*) from public.consultation_lookup_attempts
      where client_key = v_key and created_at > now() - interval '5 minutes') >= 10 then
    return jsonb_build_object('found', false, 'error', 'rate_limited');
  end if;

  insert into public.consultation_lookup_attempts (client_key) values (v_key);

  if p_code is null or length(trim(p_code)) < 1 then
    return jsonb_build_object('found', false, 'error', 'invalid_code');
  end if;

  select p.status, p.hospital_id,
         coalesce((
           select max(h.created_at)
           from public.patient_state_history h
           where h.patient_id = p.id
             and h.old_status is distinct from h.new_status
         ), p.created_at)
  into v_status, v_hospital_id, v_status_changed_at
  from public.consultation_codes cc
  join public.patients p on p.id = cc.patient_id
  where upper(trim(cc.code)) = upper(trim(p_code))
    and cc.revoked_at is null
    and (cc.expires_at is null or cc.expires_at > now())
    and p.is_deleted = false;

  if v_status is null then
    return jsonb_build_object('found', false, 'error', 'not_found');
  end if;

  if v_hospital_id is not null then
    select h.name, h.address, h.contact_phone
    into v_name, v_address, v_phone
    from public.hospitals h
    where h.id = v_hospital_id and h.is_deleted = false;
  end if;

  return jsonb_build_object(
    'found', true,
    'patient_status', v_status::text,
    'status_changed_at', v_status_changed_at,
    'hospital_name', v_name,
    'hospital_address', v_address,
    'hospital_phone', v_phone
  );
end;
$$;

notify pgrst, 'reload schema';
