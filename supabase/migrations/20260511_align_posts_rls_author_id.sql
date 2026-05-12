-- The current Flutter client writes posts.author_id. Older policy files used
-- posts.resident_id, which blocks inserts after the app/client schema update.
do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'posts'
      and column_name = 'author_id'
  ) then
    drop policy if exists posts_insert on public.posts;
    create policy posts_insert on public.posts
      for insert with check (
        author_id = auth.uid()::text
        and is_world_member(world_id)
      );

    drop policy if exists posts_author_delete on public.posts;
    create policy posts_author_delete on public.posts
      for delete using (author_id = auth.uid()::text);
  end if;
end $$;
