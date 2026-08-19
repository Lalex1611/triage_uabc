-- Incluye la tabla en la publicación Realtime para que los clientes reciban INSERT/UPDATE

alter publication supabase_realtime add table public.medico_notifications;
