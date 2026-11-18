-- 13 · Notas de atención del paciente en sala (mockup 06).
-- Cada nota es una fila: quién la escribió y cuándo. Solo se agregan; no se
-- editan ni se borran (como un expediente clínico).

create table public.patient_attention_notes (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  author_id uuid not null default auth.uid() references public.profiles (id),
  body text not null,
  created_at timestamptz not null default now(),
  constraint patient_attention_notes_body_check
    check (char_length(btrim(body)) between 1 and 2000)
);

comment on table public.patient_attention_notes is
  'Notas de atención que el médico agrega a un paciente en sala. Solo inserción.';

create index patient_attention_notes_patient_idx
  on public.patient_attention_notes (patient_id, created_at desc);

alter table public.patient_attention_notes enable row level security;

-- Las ven el admin y los médicos del hospital del paciente
create policy patient_attention_notes_select on public.patient_attention_notes
  for select to authenticated
  using (
    public.app_current_role() = 'admin'
    or (
      public.app_current_role() = 'medico'
      and exists (
        select 1 from public.patients p
        where p.id = patient_attention_notes.patient_id
          and p.is_deleted = false
          and p.hospital_id = public.app_current_hospital_id()
      )
    )
  );

-- Las agrega un médico del hospital, a su nombre, mientras el paciente está en sala
create policy patient_attention_notes_insert on public.patient_attention_notes
  for insert to authenticated
  with check (
    public.app_current_role() = 'medico'
    and author_id = auth.uid()
    and exists (
      select 1 from public.patients p
      where p.id = patient_attention_notes.patient_id
        and p.is_deleted = false
        and p.status = 'recibido'
        and p.hospital_id = public.app_current_hospital_id()
    )
  );

revoke update, delete on public.patient_attention_notes from anon, authenticated;

notify pgrst, 'reload schema';
