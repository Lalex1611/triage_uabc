# Guía de Backend - SISTEMA TRIAGE

Este documento establece las bases de la estructuración de datos y la lógica del lado del servidor. El objetivo es apoyarse al máximo en Supabase para las tareas estándar y utilizar Dart únicamente cuando se requiera lógica compleja.

---

## 1. Backend: Supabase + Dart

El proyecto no utiliza un backend construido desde cero, sino que se apoya en **Supabase**:
*   **PostgreSQL**: Base de datos principal para el almacenamiento de información.
*   **Auth**: Módulo para la gestión de usuarios (paramédicos, médicos, etc.).
*   **Realtime**: Componente fundamental para que los incidentes y estados se actualicen en vivo en las pantallas de los usuarios sin necesidad de refrescar.

Para los casos que requieren lógica compleja (por ejemplo, el envío de notificaciones o el cierre de incidentes), se planeaba usar Edge Functions (Pendiente por implementar). Esto permite mantener todo el stack de funciones en el mismo lenguaje de programación (Para nuestro caso sería Dart).

---

## 2. Tablas Principales

El esquema `public` se compone de cuatro tablas principales:
*   `profiles`: Almacena los detalles extendidos de los usuarios (rol, unidad operativa).
*   `incidents`: Registra las emergencias activas e históricas.
*   `patients`: Contiene a las víctimas de la emergencia, vinculadas a su incidente correspondiente.
*   `incident_logs`: Actúa como una bitácora de auditoría para registrar las acciones de los usuarios y las fechas de los eventos.

---

## 3. Seguridad (RLS)

**Regla principal:** No se debe confiar ciegamente en la validación enviada desde la aplicación móvil. 
La seguridad de los datos se gestiona directamente en la base de datos mediante Row Level Security (RLS).
*   El personal paramédico tiene permisos para editar la información de los pacientes únicamente hasta el momento en que son entregados al hospital.
*   El personal médico tiene la autoridad exclusiva para determinar cuándo un paciente recibe el alta médica.
*   Se implementan Triggers en la base de datos para evitar que los registros salten estados lógicos (por ejemplo, pasar un paciente de "Registrado" directamente a "Alta" sin antes haber sido recibido en el hospital).

---

## 4. Modo Offline

Para mantener la operatividad en situaciones de emergencia sin cobertura de red:
*   La aplicación guarda temporalmente los cambios en una base de datos local del dispositivo.
*   Al recuperar la conexión, los datos acumulados se sincronizan automáticamente con Supabase.
*   **En cuanto a Deletes**: Es imperativo no utilizar el comando `DELETE` físico sobre los registros (NO SE DEBE HACER). En su lugar, se debe usar una bandera `is_deleted = true` o trasladar el registro al histora. La eliminación física puede corromper la sincronización local en otros dispositivos.

---

## 5. Nombrando Cosas

Convenciones de nomenclatura:
*   **Base de datos**: Todas las tablas y columnas deben nombrarse en minúsculas utilizando `snake_case` (ej. `created_at`).
*   **Archivos Dart**: Se aplican las mismas reglas que en el frontend: `snake_case` para el nombre de los archivos y `PascalCase` para el nombre de las clases.

---

## 6. Procedimiento para Nuevas Funcionalidades

1. **Definición de Base de Datos**: Se debe evaluar si la funcionalidad requiere nuevas tablas y estructurar la migración SQL correspondiente.
2. **Políticas de Seguridad (RLS)**: Se deben establecer los permisos de lectura y escritura para los nuevos datos.
3. **Pruebas Locales**: Es obligatorio ejecutar `supabase start` para probar cualquier cambio localmente antes de ya subirlo.
