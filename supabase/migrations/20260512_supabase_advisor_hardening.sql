-- Address Supabase advisor findings that are safe to remediate without
-- changing the app's access model.

-- Harden functions that run without an explicit search_path. Keeping public in
-- the path preserves the existing unqualified table references in these bodies.
alter function public.add_comment(post_id text, resident_id text, content text)
  set search_path = public, pg_temp;

alter function public.handle_new_user()
  set search_path = public, pg_temp;

alter function public.increment_thread_count(msg_id uuid)
  set search_path = public, pg_temp;

alter function public.prevent_profile_escalation()
  set search_path = public, pg_temp;

alter function public.toggle_reaction(post_id text, emoji text, resident_id text)
  set search_path = public, pg_temp;

-- Add indexes for foreign keys that are hot in core app flows and admin review.
create index if not exists idx_channel_messages_sender_id
  on public.channel_messages(sender_id);

create index if not exists idx_chat_messages_sender_id
  on public.chat_messages(sender_id);

create index if not exists idx_events_created_by
  on public.events(created_by);

create index if not exists idx_invites_created_by
  on public.invites(created_by);

create index if not exists idx_moderation_logs_moderator_id
  on public.moderation_logs(moderator_id);

create index if not exists idx_moderation_logs_target_user_id
  on public.moderation_logs(target_user_id);

create index if not exists idx_posts_author_id
  on public.posts(author_id);

create index if not exists idx_reports_reporter_id
  on public.reports(reporter_id);

create index if not exists idx_world_audit_log_actor_id
  on public.world_audit_log(actor_id);

create index if not exists idx_worlds_sovereign_id
  on public.worlds(sovereign_id);
