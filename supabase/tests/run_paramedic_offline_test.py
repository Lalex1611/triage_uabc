"""Pruebas del contrato SQL en un contenedor temporal de PostGIS.

docker run --rm --name triage-a08-test --network none -e POSTGRES_HOST_AUTH_METHOD=trust -d postgis/postgis:17-3.5
python supabase/tests/run_paramedic_offline_test.py
docker stop triage-a08-test

La autenticación y el almacenamiento se simulan con datos de prueba en SQL.
Las migraciones, los disparadores, las RPC y las políticas RLS del proyecto
se ejecutan tal como están.
"""
from pathlib import Path
import subprocess
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
import time

CONTAINER = 'triage-a08-test'
ROOT = Path(__file__).resolve().parents[1]
DATABASE = 'a08_tests_' + str(time.time_ns())

def wait_for_postgres(timeout=30):
    deadline = time.monotonic() + timeout
    while (remaining := deadline - time.monotonic()) > 0:
        try:
            # El servidor temporal de inicialización solo escucha por socket Unix.
            result = subprocess.run(
                ['docker', 'exec', CONTAINER, 'psql', '-h', '127.0.0.1',
                 '-U', 'postgres', '-d', 'postgres', '-w', '-Atqc', 'select 1'],
                capture_output=True,
                encoding='utf-8',
                timeout=min(2, remaining),
            )
            if result.returncode == 0 and result.stdout.strip() == '1':
                return
        except subprocess.TimeoutExpired:
            pass
        time.sleep(min(0.25, max(0, deadline - time.monotonic())))
    raise RuntimeError(f'PostgreSQL en {CONTAINER} no aceptó conexiones TCP en {timeout} s.')

def psql(database):
    return ['docker', 'exec', '-i', CONTAINER, 'psql', '-U', 'postgres',
            '-d', database, '-v', 'ON_ERROR_STOP=1', '-qAt']

def sql(text, database=DATABASE):
    result = subprocess.run(psql(database), input=text, encoding='utf-8',
                            capture_output=True, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout.strip()

def wait_for_condition(query, failure, timeout=10):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if sql(query) == 't':
            return
        time.sleep(0.1)
    raise RuntimeError(failure)

@contextmanager
def holding_transaction(statement):
    with subprocess.Popen(psql(DATABASE), stdin=subprocess.PIPE,
                          stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                          encoding='utf-8') as first:
        first.stdin.write("set application_name = 'offline-first';\nbegin;\n" + statement
                          + "\nselect 1 /* lista */;\n")
        first.stdin.flush()
        try:
            wait_for_condition("""
                select exists (select 1 from pg_stat_activity
                  where application_name = 'offline-first' and state = 'idle in transaction'
                  and query = 'select 1 /* lista */;');
            """, 'La primera transacción no llegó al punto de espera.')
            yield
            first.stdin.write("commit;\n")
        finally:
            # Cerrar la entrada sin COMMIT revierte la transacción si falla la prueba.
            _, error = first.communicate(timeout=10)
            if first.returncode:
                raise RuntimeError(error)

def run_contended(first, second, *, advisory=True, callers=1, while_blocked=None):
    with ThreadPoolExecutor(max_workers=callers) as pool:
        with holding_transaction(first):
            calls = [pool.submit(sql, "set application_name = 'offline-second';\n" + second)
                     for _ in range(callers)]
            lock_filter = "and waiter.wait_event = 'advisory'" if advisory else ""
            wait_for_condition(f"""
                select exists (select 1 from pg_stat_activity waiter
                  join pg_stat_activity holder on holder.pid = any(pg_blocking_pids(waiter.pid))
                  where waiter.application_name = 'offline-second'
                    and holder.application_name = 'offline-first'
                    and waiter.wait_event_type = 'Lock' {lock_filter});
            """, 'La segunda transacción no llegó al bloqueo esperado.')
            if while_blocked:
                sql(while_blocked)
        for call in calls:
            call.result()

wait_for_postgres()
sql('create database ' + DATABASE + ';', 'postgres')
sql("""
do $$ begin create role anon nologin; exception when duplicate_object then null; end; $$;
do $$ begin create role authenticated nologin; exception when duplicate_object then null; end; $$;
create schema auth;
create schema storage;
create schema extensions;
create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb default '{}');
create function auth.uid() returns uuid language sql stable as
$$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
grant usage on schema auth,storage,extensions to anon,authenticated;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid primary key default gen_random_uuid(),bucket_id text references storage.buckets(id),name text,owner_id text,unique(bucket_id,name));
alter table storage.objects enable row level security;
create function storage.foldername(text) returns text[] language sql immutable as
$$ select (string_to_array($1,'/'))[1:array_length(string_to_array($1,'/'),1)-1] $$;
grant select,insert,update,delete on storage.objects to authenticated;
alter default privileges in schema public grant select,insert,update,delete on tables to authenticated;
create publication supabase_realtime;
""")
for migration in sorted((ROOT/'migrations').glob('*.sql')):
    migration_sql = migration.read_text(encoding='utf-8')
    if migration.name == '20261125140000_offline_retry_and_photo_access.sql':
        fixture = (ROOT/'tests'/'offline_patient_photo_cleanup.sql').read_text(encoding='utf-8')
        sql('begin;\n' + fixture + '\n' + migration_sql
            + '\nselect pg_temp.verificar_limpieza();\nrollback;')
        print('PASS Limpieza: referencias del paciente, orden y objetos de Storage')
    sql(migration_sql)
    print('Applied',migration.name)
sql((ROOT/'tests'/'paramedic_offline_captures.sql').read_text(encoding='utf-8'))
print('PASS Paramédico: idempotencia, adjuntos, reversión y RLS')
sql((ROOT/'tests'/'medico_offline_walk_ins.sql').read_text(encoding='utf-8'))
print('PASS Médico: idempotencia, vigencia del código, fotos y RLS')
sql("""
insert into auth.users(id,email) values('a0800000-0000-0000-0000-000000000010','concurrency@example.test');
update public.profiles set role='paramedico' where id='a0800000-0000-0000-0000-000000000010';
""")
session = """
set role authenticated;
select set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000010',false);
"""
incident = """
select public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000010','incident',
'a0810000-0000-0000-0000-000000000010','{"title":"Concurrent test","emergency_type":"otro","lat":32.5,"lng":-117}');
"""
for combined, patient_id in [(True, 'a0820000-0000-0000-0000-000000000010'),
                             (False, 'a0820000-0000-0000-0000-000000000011')]:
    patient = f"""
        select public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000010','patient',
          '{patient_id}','{{"incident_id":"a0810000-0000-0000-0000-000000000010","triage_color":"verde","demographics":{{}},"lat":32.5,"lng":-117}}');
    """
    request = session + (incident if combined else '') + patient
    run_contended(request, request, callers=5)
    sql(f"""do $$ begin
      assert (select count(*)=1 from public.incidents where sync_client_id='a0810000-0000-0000-0000-000000000010');
      assert (select count(*)=1 from public.patients where sync_client_id='{patient_id}');
      assert (select count(*)=1 from public.consultation_codes where patient_id='{patient_id}');
    end; $$;""")
    print('PASS Reintentos concurrentes:', 'incidente y paciente' if combined else 'solo paciente')

photo = 'a0810000-0000-0000-0000-000000000010/aaaaaaaa-0000-0000-0000-000000000010.jpg'
sql(session + f"""select public.paramedico_update_incident_photo_path(
  'a0810000-0000-0000-0000-000000000010', '{photo}', false);""")
run_contended(
    session + f"""select public.paramedico_update_incident_photo_path(
      'a0810000-0000-0000-0000-000000000010', '{photo}', true);""",
    f"""do $$ begin
      insert into storage.objects(bucket_id,name,owner_id)
        values ('incident_photos','{photo}','a0800000-0000-0000-0000-000000000010');
      raise exception 'Se publicó una foto retirada';
    exception when sqlstate 'P0802' then null; end; $$;""",
    advisory=False)
sql(f"""do $$ begin assert not exists(select 1 from storage.objects
  where bucket_id='incident_photos' and name='{photo}'); end; $$;""")
print('PASS Una subida en curso respeta el retiro confirmado')

capture_id = 'a0810000-0000-0000-0000-000000000012'
run_contended(
    f"select pg_advisory_xact_lock(hashtextextended('{capture_id}',0));",
    session + f"""do $$ begin
      perform public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000010','incident',
        '{capture_id}','{{"title":"Espera","emergency_type":"otro","lat":32.5,"lng":-117}}');
      raise exception 'Una cuenta desactivada pudo sincronizar';
    exception when insufficient_privilege then null; end; $$;""",
    while_blocked="""update public.profiles set is_active=false
      where id='a0800000-0000-0000-0000-000000000010';""")
sql(f"""do $$ begin
  assert not exists(select 1 from public.incidents where id='{capture_id}');
  assert not exists(select 1 from public.paramedic_capture_receipts where sync_client_id='{capture_id}');
end; $$;""")
print('PASS Una cuenta desactivada durante la espera no deja incidente ni comprobante')
