drop policy if exists incidents_update on public.incidents;

create policy incidents_update on public.incidents for
update
  to authenticated using (
    is_deleted = false
    and public.current_role () = 'paramedico'
    and created_by = auth.uid ()
  )
with check (
  is_deleted = false
  and public.current_role () = 'paramedico'
  and created_by = auth.uid ()
);
