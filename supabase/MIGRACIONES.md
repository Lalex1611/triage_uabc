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

La migración de Paramédico pasó de `20261117120000` a `20261120150000` para que su versión sea única y se ejecute después de las migraciones de Médico ya incorporadas a `main`. Si el SQL de A08 ya se ejecutó manualmente en un entorno, verifica sus tablas y funciones antes de registrar esa nueva versión en el historial.

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
