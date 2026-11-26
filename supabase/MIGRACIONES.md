# Migraciones de Supabase

Las migraciones se aplican **en la base de datos a la que apunta la app**
(`SUPABASE_URL` en `assets/supabase_runtime.json`), no en el repositorio: los
archivos `.sql` ya están en `supabase/migrations/`.

- **Supabase local (Docker, `http://127.0.0.1:54321`)**: cada integrante tiene su
  propia base de datos en su computadora, así que **cada quien debe aplicar las
  migraciones nuevas** después de hacer `git pull` (ver Opción A).
- **Proyecto de Supabase en la nube compartido**: se aplican **una sola vez** y
  todos los que usan esa URL ya las tienen (ver Opción B).

Cada migración se aplica una sola vez por base de datos y siempre en orden.

## Orden

Los archivos están en `supabase/migrations/` y se aplican por fecha (el prefijo
del nombre). Nunca cambiar el orden ni editar una migración ya aplicada: para
corregir algo se crea una nueva.

| # | Archivo | Qué hace |
|---|---------|----------|
| 1 | `20261009120000_extentions_and_types.sql` | Extensiones y tipos (enums) |
| 2 | `20261009120100_core_tables.sql` | Tablas principales |
| 3 | `20261009120200_notifications_and_audit_tables.sql` | Notificaciones y auditoría |
| 4 | `20261009120300_helper_functions.sql` | Funciones auxiliares |
| 5 | `20261009120400_triggers.sql` | Triggers |
| 6 | `20261009120500_rls_policies.sql` | Políticas RLS |
| 7 | `20261009120600_rpc_functions.sql` | Funciones RPC |
| 8 | `20261009120700_storage_and_realtime.sql` | Storage y Realtime |
| 9 | `20261019120000_consulta_status_changed_at.sql` | Fecha del último cambio de estado (consulta externa) |
| 10 | `20261024120000_consulta_rate_limit_atomic.sql` | Límite de consulta externa por cliente |
| 11 | `20261109120000_incident_photos_storage.sql` | Storage de fotos de incidentes |
| 12 | `20261117120000_medico_register_walk_in.sql` | Médico: registro de pacientes que llegan por su cuenta |
| 13 | `20261117130000_medico_profile_capacity.sql` | Médico: capacidad del hospital en el perfil |
| 14 | `20261117140000_patient_attention_notes.sql` | Notas de atención del paciente |
| 15 | `20261117150000_medico_notifications_kinds.sql` | Tipos de notificación del médico |
| 16 | `20261117160000_patient_discharges.sql` | Altas médicas |
| 17 | `20261117170000_paramedic_transfer_notifications.sql` | Notificaciones de traslado al paramédico |
| 18 | `20261119120000_require_discharge_for_alta.sql` | Alta médica solo con registro de alta |
| 19 | `20261120120000_medico_append_patient_photo.sql` | Agregar foto sin pisar otros datos |
| 20 | `20261120130000_medico_set_hospital_triage.sql` | Cambiar el triage hospitalario desde sala |
| 21 | `20261120140000_medico_update_patient_info.sql` | Editar datos sin borrar fotos |
| 22 | `20261120150000_paramedic_offline_captures.sql` | Sincronización de incidentes, pacientes y fotos capturados sin conexión por Paramédico |
| 23 | `20261120160000_medico_offline_walk_ins.sql` | Sincronización de admisiones y fotos capturadas sin conexión por Médico |
| 24 | `20261124120000_a08_recover_capture_photos.sql` | Recuperación de fotos de capturas y preservación de adjuntos al editar pacientes |
| 25 | `20261125120000_offline_consultation_codes_and_photos.sql` | Vigencia de códigos en reintentos y actualizaciones seguras de fotos |
| 26 | `20261125130000_paramedic_capture_photo_integrity.sql` | Vigencia de códigos de Paramédico y protección del vínculo y retiro de fotos |
| 27 | `20261125140000_offline_retry_and_photo_access.sql` | Validación de fotos por paciente y aviso de adjuntos retirados durante un reintento |
| 28 | `20261125150000_offline_incident_photo_and_account_guards.sql` | Impide restaurar fotos retiradas con una carga tardía o una lista anterior y verifica el perfil al reanudar la captura |

Antes de aplicar #26 en una instalación con capturas pendientes, comprueba si
hay reintentos de fotos de incidentes. Si alguna ruta ya se retiró, concilia el
retiro confirmado y su archivo de Storage antes de reanudar esos reintentos.
La #26 registra los retiros a partir de su aplicación. Distribuye la app
compatible con #27 para que limpie del bucket los adjuntos que se vuelvan a
subir por un reintento.

### Si el historial ya contiene la versión `20261117120000`

La versión se usó para el registro de Médico (#12) y en una versión anterior del
modo sin conexión de Paramédico, que pasó a `20261120150000` (#22). La CLI
compara las versiones por fecha. En el SQL Editor revisa el nombre y las
sentencias registradas, si existe la tabla de historial, y los objetos instalados.

```sql
select version, name, statements
from supabase_migrations.schema_migrations
where version in ('20261117120000', '20261120150000');

select
  to_regprocedure(
    'public.medico_register_walk_in_patient(text,public.triage_color,jsonb,jsonb,text)'
  ) as registro_medico,
  to_regclass('public.paramedic_capture_receipts') as comprobantes_paramedico,
  to_regprocedure('public.sync_paramedic_capture(uuid,text,uuid,jsonb)') as captura_paramedico,
  to_regprocedure('public.link_paramedic_capture_photo(uuid,text,uuid,text)') as fotos_paramedico;
```

- Si la entrada corresponde al SQL de Médico, conserva `20261117120000`.
  Si Paramédico se instaló aparte, verifica sus objetos y permisos antes de
  registrar #22 como aplicada.
- Si la entrada corresponde únicamente al SQL anterior de Paramédico, aplica
  el archivo #12 en el SQL Editor si el registro de Médico sigue ausente.
  Verifica que exista `medico_register_walk_in_patient`, que
  `authenticated` pueda ejecutarla y que su definición corresponda a #12.
  Comprueba también la tabla, RLS, RPC y permisos de Paramédico según #22.
  Cuando ambos conjuntos estén instalados, registra #22 como aplicada y
  sustituye la entrada antigua de #12 por la canónica. Omite el primer
  comando si #22 ya figura como aplicada. Estos comandos reparan el historial
  sin volver a ejecutar la creación de tablas.

  Usa el mismo destino para consultar el historial, ejecutar el SQL y
  repararlo. En local, usa el Studio de `supabase status` y estos comandos.

  ```bash
  npx supabase migration repair 20261120150000 --status applied --local
  npx supabase migration repair 20261117120000 --status reverted --local
  npx supabase migration repair 20261117120000 --status applied --local
  npx supabase migration list --local
  ```

  En la nube, confirma que `supabase link` apunta al mismo proyecto que
  abriste en el SQL Editor y usa estos comandos.

  ```bash
  npx supabase migration repair 20261120150000 --status applied --linked
  npx supabase migration repair 20261117120000 --status reverted --linked
  npx supabase migration repair 20261117120000 --status applied --linked
  npx supabase migration list --linked
  ```

Si falta el historial o la entrada carece de sentencias, confirma el origen
con el SQL aplicado, las definiciones instaladas y el registro del despliegue
antes de reparar. [Referencia de Supabase CLI](https://supabase.com/docs/reference/cli/supabase-migration-repair)

## Opción A: Supabase local (Docker)

Requisitos: Docker corriendo. No hace falta `supabase login`.

```bash
# 1. Levantar Supabase local (si no está corriendo)
npx supabase start

# 2. Ver qué migraciones están aplicadas (columna Remote) y cuáles faltan
npx supabase migration list

# 3. Aplicar solo las que faltan, en orden (no borra datos)
npx supabase migration up
```

Para empezar de cero (**borra todos los datos locales**, corre todas las
migraciones y `seed.sql`):

```bash
npx supabase db reset
```

## Opción B: proyecto en la nube

La CLI guarda en el proyecto qué migraciones ya se aplicaron, así nadie las
repite por error.

```bash
# 1. Iniciar sesión (abre el navegador)
npx supabase login

# 2. Vincular la carpeta con el proyecto (pide la contraseña de la base de datos)
npx supabase link --project-ref <project-ref>

# 3. Ver qué migraciones tiene el proyecto (columna Remote) y cuáles faltan
npx supabase migration list --linked

# 4. Aplicar las que faltan, en orden
npx supabase db push
```

El `<project-ref>` es el subdominio de la URL (`https://<project-ref>.supabase.co`).

Si `migration list` muestra la columna Remote vacía pero la base ya tiene
tablas (porque antes se aplicaron a mano en el SQL Editor), `db push` intentaría
correr todo desde la #1 y fallaría. Antes, marcar como aplicadas las que ya
existen (la versión es el número del inicio del nombre del archivo):

```bash
npx supabase migration repair --status applied <versión> [<versión> ...]
```

Sin CLI: en el dashboard → **SQL Editor**, pegar cada archivo pendiente y dar
**Run**, uno por uno y en orden (este método no deja registro).

## Historial de aplicación

| Fecha | Migraciones | Quién |
|-------|-------------|-------|
| 2026-11-21 | 18 a 21 (`20261119120000` a `20261120140000`) | Supabase local de Munin0 (`migration up`) |
