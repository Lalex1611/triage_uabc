-- Médicos: consultar y crear códigos de consulta para pacientes de su hospital.

create policy consultation_codes_select_medico
  on public.consultation_codes for select to authenticated
  using (
    public.current_role () = 'medico'::public.user_role
    and exists (
      select 1
      from public.patients p
      join public.profiles pr on pr.id = auth.uid ()
      where p.id = consultation_codes.patient_id
        and p.hospital_id = pr.hospital_id
        and p.is_deleted = false
    )
  );

create policy consultation_codes_insert_medico
  on public.consultation_codes for insert to authenticated
  with check (
    public.current_role () = 'medico'::public.user_role
    and created_by = auth.uid ()
    and exists (
      select 1
      from public.patients p
      join public.profiles pr on pr.id = auth.uid ()
      where p.id = patient_id
        and p.hospital_id = pr.hospital_id
        and p.is_deleted = false
    )
  );
