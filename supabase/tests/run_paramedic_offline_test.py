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
import time

CONTAINER = 'triage-a08-test'
ROOT = Path(__file__).resolve().parents[1]
DATABASE = 'a08_tests_' + str(time.time_ns())

def sql(text, database=DATABASE):
    result = subprocess.run(['docker','exec','-i',CONTAINER,'psql','-U','postgres',
        '-d',database,'-v','ON_ERROR_STOP=1','-q'],input=text,encoding='utf-8',capture_output=True)
    if result.returncode:
        raise RuntimeError(result.stderr)

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
    sql(migration.read_text(encoding='utf-8'))
    print('Applied',migration.name)
sql((ROOT/'tests'/'paramedic_offline_captures.sql').read_text(encoding='utf-8'))
print('PASS: idempotency, conflicts, ownership, locations, codes, attachments, atomic rollback and RLS')
sql("""
insert into auth.users(id,email) values('a0800000-0000-0000-0000-000000000010','concurrency@example.test');
update public.profiles set role='paramedico' where id='a0800000-0000-0000-0000-000000000010';
""")
request = """
set role authenticated;
select set_config('request.jwt.claim.sub','a0800000-0000-0000-0000-000000000010',false);
select public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000010','incident',
'a0810000-0000-0000-0000-000000000010','{"title":"Concurrent test","emergency_type":"otro","lat":32.5,"lng":-117}');
select public.sync_paramedic_capture('a0800000-0000-0000-0000-000000000010','patient',
'a0820000-0000-0000-0000-000000000010','{"incident_id":"a0810000-0000-0000-0000-000000000010","triage_color":"verde","demographics":{},"lat":32.5,"lng":-117}');
"""
with ThreadPoolExecutor(max_workers=6) as pool:
    list(pool.map(sql,[request]*6))
sql("""do $$ begin
assert (select count(*)=1 from public.incidents where sync_client_id='a0810000-0000-0000-0000-000000000010');
assert (select count(*)=1 from public.patients where sync_client_id='a0820000-0000-0000-0000-000000000010');
assert (select count(*)=1 from public.consultation_codes where patient_id='a0820000-0000-0000-0000-000000000010');
end; $$;""")
print('PASS: six concurrent retries create one incident, one patient and one code')
