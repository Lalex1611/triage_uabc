# Sistema Triage

Un sistema de gestión de emergencias médicas diseñado para coordinar la atención de pacientes desde el sitio del incidente hasta su ingreso en el hospital.

## Características Principales

*   **Aplicación Móvil**: Desarrollada en Flutter, con un diseño optimizado para operar en situaciones de emergencia.
*   **Gestión en Tiempo Real**: Sincronización de incidentes y estado de pacientes mediante Supabase Realtime.
*   **Geolocalización**: Mapeo de incidentes y pacientes en el sitio utilizando PostGIS.
*   **Modo Offline**: Capacidad de registro sin conexión a internet y sincronización automática al recuperar la conectividad.
*   **Códigos QR**: Generación de códigos únicos para facilitar la entrega de pacientes en el hospital.

## Arquitectura de la Aplicación (Frontend)

El proyecto intenta implementar Clean Architecture. El directorio `lib/` se estructura de la siguiente manera:

*   **`core/`**: Constantes globales, manejo de sesiones y configuración del enrutador.
*   **`features/`**: Módulos divididos según el rol:
    *   **`paramedico/`**: Creación de incidentes, registro de múltiples víctimas y triage en sitio.
    *   **`medico/`**: Recepción hospitalaria, confirmación de altas y notificaciones de traslados.
    *   **`consulta_externa/`**: Ingreso y clasificación de pacientes por cuenta propia.
    *   **`auth/`**: Autenticación de los usuarips y accesos

En la guía de arquitectura viene más info [Guía de Arquitectura del Frontend](./ARCHITECTURE_GUIDE.md).

## Arquitectura del Backend

El backend se basa en Supabase:

*   **PostgreSQL**: Base de datos principal.
*   **Autenticación**: Gestión de sesiones de usuarios por roles.
*   **Storage**: Almacenamiento de fotografías.
*   **Edge Functions** (Aun no implementadas): Lógica de servidor en Dart para notificaciones.
*   **Seguridad por RLS (Row Level Security)**: Reglas de acceso y edición a nivel de base de datos.

Para mas detalles se puede consultar la [Guía de Arquitectura del Backend](./BACKEND_ARCHITECTURE.md).

## Desarrollo Local

### 1. Requisitos Previos
*   Flutter SDK.
*   Proyecto configurado en Supabase.

### 2. Configuración de Entorno
El proyecto carga las credenciales desde un archivo JSON ubicado en los assets, es necesario modificar el archivo `assets/supabase_runtime.json` con las claves correspondientes de Supabase:
```json
{
  "SUPABASE_URL": "url_de_supabase",
  "SUPABASE_ANON_KEY": "llave_anonima"
}
```

### 3. Ejecución
Instalar dependencias:
```bash
flutter pub get
```

Ejecutar la aplicación:
```bash
flutter run
```

## Pruebas Visuales

En la carpeta test podemos encontrar diseños visuales de las pantallas de la aplicación. Estos fueron creados para ayudar al desarrollo y diseño del frontend.

## Migración de la base de datos (si es necesario)

Si es necesario migrar la base de datos (ahora mismo se encuentra en una Supabase) se incluyen los esquemas de la base de datos en `supabase/migrations/`, estos se encuentran en orden cronólogico y fueron implementadas conforme era necesario realizar ajustes y mejoras a la base de datos. Con esto se puede replicar la base de datos en un nuevo proyecto (Siempre y cuando el proveedor utilice PostgreSQL). Además de esto, muchas de las funciones de backend para comunicarse con supabase están basadas en funciones ya creadas para trabajar con la misma, por lo que sería necesario adaptar estas funciones a la nueva base de datos (no sería mucho retrabajo ya que al trabajar con una clean architecture se separa completamente la lógica de las consultas con la lógica de la interfaz)


