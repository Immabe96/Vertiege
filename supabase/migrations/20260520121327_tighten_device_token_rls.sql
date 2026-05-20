alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_read_own" on public.device_tokens;
drop policy if exists "device_tokens_upsert_own" on public.device_tokens;
drop policy if exists "device_tokens_update_own" on public.device_tokens;
drop policy if exists "device_tokens_delete_own" on public.device_tokens;

create policy "device_tokens_read_own"
  on public.device_tokens
  for select
  using (resident_id = auth.uid()::text);

create policy "device_tokens_upsert_own"
  on public.device_tokens
  for insert
  with check (
    auth.role() = 'authenticated'
    and resident_id = auth.uid()::text
    and token is not null
  );

create policy "device_tokens_update_own"
  on public.device_tokens
  for update
  using (resident_id = auth.uid()::text)
  with check (resident_id = auth.uid()::text);

create policy "device_tokens_delete_own"
  on public.device_tokens
  for delete
  using (resident_id = auth.uid()::text);
