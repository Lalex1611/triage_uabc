-- 6/8 · Row Level Security
-- Matriz resumida:
--   admin             : catálogos (hospitales, ambulancias), perfiles, lectura/edición de todo
--   paramedico        : incidentes y pacientes (cualquier ambulancia puede editar cualquier paciente)
--   medico            : SOLO pacientes de su hospital (sin hospital asignado = no ve nada)
--   consulta_externa  : sin acceso a tablas; consulta por código vía RPC

alter table public.ambulancias_unidades enable row level security;
alter table public.hospitals enable row level security;
alter table public.profiles enable row level security;
alter table public.incidents enable row level security;
alter table public.patients enable row level security;
alter table public.incident_logs enable row level security;
alter table public.consultation_codes enable row level security;
alter table public.paramedic_notifications enable row level security;
alter table public.medico_notifications enable row level security;
alter table public.medico_rejected_transfers enable row level security;
alter table public.patient_state_history enable row level security;
alter table public.consultation_lookup_attempts enable row level security; -- sin políticas: solo RPC

-- Catálogos ------------------------------------------------------------------
create policy ambulancias_unidades_select on public.ambulancias_unidades for select to authenticated
  using (is_deleted = false and public.app_current_role() is not null);

create policy ambulancias_unidades_admin_insert on public.ambulancias_unidades for insert to authenticated
  with check (public.app_current_role() = 'admin');

create policy ambulancias_unidades_admin_update on public.ambulancias_unidades for update to authenticated
  using (public.app_current_role() = 'admin')
  with check (public.app_current_role() = 'admin');

create policy hospitals_select on public.hospitals for select to authenticated
  using (is_deleted = false and public.app_current_role() is not null);

create policy hospitals_admin_insert on public.hospitals for insert to authenticated
  with check (public.app_current_role() = 'admin');

create policy hospitals_admin_update on public.hospitals for update to authenticated
  using (public.app_current_role() = 'admin')
  with check (public.app_current_role() = 'admin');

-- Perfiles (el trigger guard impide que un no-admin cambie rol/hospital/unidad) ----
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.app_current_role() = 'admin');

create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid() or public.app_current_role() = 'admin')
  with check (id = auth.uid() or public.app_current_role() = 'admin');

-- Incidentes -------------------------------------------------------------------
create policy incidents_select on public.incidents for select to authenticated
  using (
    is_deleted = false
    and (
      public.app_current_role() in ('admin', 'paramedico')
      or (
        public.app_current_role() = 'medico'
        and exists (
          select 1 from public.patients p
          where p.incident_id = incidents.id
            and p.is_deleted = false
            and p.hospital_id = public.app_current_hospital_id()
        )
      )
    )
  );

create policy incidents_insert on public.incidents for insert to authenticated
  with check (public.app_current_role() = 'paramedico' and created_by = auth.uid());

-- Solo quien creó el incidente (o un admin) lo modifica/cierra.
create policy incidents_update on public.incidents for update to authenticated
  using (
    is_deleted = false
    and (
      public.app_current_role() = 'admin'
      or (public.app_current_role() = 'paramedico' and created_by = auth.uid())
    )
  )
  with check (
    public.app_current_role() = 'admin'
    or (public.app_current_role() = 'paramedico' and created_by = auth.uid())
  );

-- Pacientes ----------------------------------------------------------------------
create policy patients_select on public.patients for select to authenticated
  using (
    is_deleted = false
    and (
      public.app_current_role() in ('admin', 'paramedico')
      or (
        public.app_current_role() = 'medico'
        and hospital_id is not null
        and hospital_id = public.app_current_hospital_id()
      )
    )
  );

create policy patients_insert_paramedico on public.patients for insert to authenticated
  with check (
    public.app_current_role() = 'paramedico'
    and created_by = auth.uid()
    and status in ('en_espera', 'trasladando')
  );

-- Walk-in: el médico registra un paciente ya recibido en SU hospital.
create policy patients_insert_medico_walk_in on public.patients for insert to authenticated
  with check (
    public.app_current_role() = 'medico'
    and created_by = auth.uid()
    and status = 'recibido'
    and hospital_id is not null
    and hospital_id = public.app_current_hospital_id()
  );

create policy patients_update_paramedico on public.patients for update to authenticated
  using (is_deleted = false and public.app_current_role() = 'paramedico')
  with check (public.app_current_role() = 'paramedico');

create policy patients_update_medico on public.patients for update to authenticated
  using (
    is_deleted = false
    and public.app_current_role() = 'medico'
    and hospital_id is not null
    and hospital_id = public.app_current_hospital_id()
  )
  with check (
    public.app_current_role() = 'medico'
    and hospital_id = public.app_current_hospital_id()
  );

create policy patients_update_admin on public.patients for update to authenticated
  using (public.app_current_role() = 'admin')
  with check (public.app_current_role() = 'admin');

-- Bitácora -----------------------------------------------------------------------
create policy incident_logs_select on public.incident_logs for select to authenticated
  using (public.app_current_role() in ('admin', 'paramedico') or actor_id = auth.uid());

create policy incident_logs_insert on public.incident_logs for insert to authenticated
  with check (
    actor_id = auth.uid()
    and public.app_current_role() in ('admin', 'paramedico', 'medico')
  );

-- Historial de estado (solo lectura para el cliente) -------------------------------
create policy patient_state_history_select on public.patient_state_history for select to authenticated
  using (
    public.app_current_role() in ('admin', 'paramedico')
    or (
      public.app_current_role() = 'medico'
      and exists (
        select 1 from public.patients p
        where p.id = patient_state_history.patient_id
          and p.hospital_id = public.app_current_hospital_id()
      )
    )
  );

revoke insert, update, delete on public.patient_state_history from anon, authenticated;

-- Códigos de consulta: se CREAN solo con la RPC create_consultation_code ------------
create policy consultation_codes_select on public.consultation_codes for select to authenticated
  using (
    public.app_current_role() in ('admin', 'paramedico')
    or (
      public.app_current_role() = 'medico'
      and exists (
        select 1 from public.patients p
        where p.id = consultation_codes.patient_id
          and p.hospital_id = public.app_current_hospital_id()
          and p.is_deleted = false
      )
    )
  );

create policy consultation_codes_revoke on public.consultation_codes for update to authenticated
  using (public.app_current_role() in ('admin', 'paramedico'))
  with check (public.app_current_role() in ('admin', 'paramedico'));

-- El cliente solo puede revocar (no cambiar código ni paciente).
revoke update on public.consultation_codes from anon, authenticated;
grant update (revoked_at) on public.consultation_codes to authenticated;

-- Notificaciones (las crean triggers/RPC; el usuario solo lee y marca como leída) ----
create policy paramedic_notifications_select_own on public.paramedic_notifications for select to authenticated
  using (recipient_id = auth.uid());
create policy paramedic_notifications_update_own on public.paramedic_notifications for update to authenticated
  using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

create policy medico_notifications_select_own on public.medico_notifications for select to authenticated
  using (recipient_id = auth.uid());
create policy medico_notifications_update_own on public.medico_notifications for update to authenticated
  using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

revoke update on public.paramedic_notifications from anon, authenticated;
revoke update on public.medico_notifications from anon, authenticated;
grant update (read_at) on public.paramedic_notifications to authenticated;
grant update (read_at) on public.medico_notifications to authenticated;

-- Traslados rechazados: el hospital que rechazó, y paramédicos/admin para ver el motivo ----
create policy medico_rejected_transfers_select on public.medico_rejected_transfers for select to authenticated
  using (
    public.app_current_role() in ('admin', 'paramedico')
    or (
      public.app_current_role() = 'medico'
      and hospital_id = public.app_current_hospital_id()
    )
  );

create policy profiles_select_staff on public.profiles for select to authenticated
  using (public.app_current_role() in ('paramedico', 'medico'));