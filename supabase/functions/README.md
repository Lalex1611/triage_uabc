# Edge Functions (Dart) — reservado

Este directorio sigue la estructura descrita en [`BACKEND_ARCHITECTURE.md`](../../BACKEND_ARCHITECTURE.md) para funciones posteriores (`create_incident`, `notify_reinforcements`, `process_discharge`, etc.).

**Estado actual:** la app usa **PostgreSQL** (RLS, triggers) y **RPC `SECURITY DEFINER`** en migraciones para casos que no deben ir al cliente; no hay funciones Edge desplegadas aquí todavía. Los contratos JSON expuestos al cliente deben documentarse junto con el frontend.
