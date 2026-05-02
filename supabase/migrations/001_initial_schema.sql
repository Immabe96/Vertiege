-- Vertiege: Complete Supabase Schema
-- Run this in your Supabase SQL Editor (https://app.supabase.com)

-- ⚠️ WARNING: This drops ALL old Expo app data and recreates everything

-- ── Clean up old schema (cascade drops remove policies too) ─
drop table if exists public.moderation_logs cascade;
drop table if exists public.reports cascade;
drop table if exists public.events cascade;
drop table if exists public.channel_messages cascade;
drop table if exists public.chat_messages cascade;
drop table if exists public.dm_rooms cascade;
drop table if exists public.invites cascade;
drop table if exists public.posts cascade;
drop table if exists public.channels cascade;
drop table if exists public.world_members cascade;
drop table if exists public.worlds cascade;
drop table if exists public.notifications cascade;
drop table if exists public.profiles cascade;

-- ── Extension ──────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── Profiles ───────────────────────────────────────────────
create table public.profiles (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  bio         text default '',
  tier        int default 1,
  avatar_url  text default '',
  profession  text,
  verified_roles    text[] default '{}',
  decorations       text[] default '{}',
  wealth_worlds_unlocked text[] default '{}',
  badges            text[] default '{}',
  cosmetics         jsonb default '{"badges":[]}',
  last_check_in     text,
  streak_count      int default 0,
  following         text[] default '{}',
  joined_world_ids  text[] default '{}',
  world_standings   jsonb default '{}',
  banned_world_ids  text[] default '{}',
  muted_until       jsonb default '{}',
  last_seen_at      bigint default 0,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

create policy "Anyone can read profiles"
  on public.profiles for select using (true);

create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

-- ── Worlds ─────────────────────────────────────────────────
create table public.worlds (
  id              text primary key,
  name            text not null,
  type            text not null default 'wealth', -- wealth, profession, dominion
  description     text default '',
  sovereign_id    uuid not null references public.profiles(id),
  sovereign_name  text not null,
  prestige        int default 1,
  member_count    int default 0,
  icon            text default 'earth',
  required_tier   int,
  required_profession text,
  created_at      timestamptz default now()
);

alter table public.worlds enable row level security;

create policy "Anyone can read worlds"
  on public.worlds for select using (true);

create policy "Sovereign can update world"
  on public.worlds for update using (auth.uid() = sovereign_id);

create policy "Users can create worlds"
  on public.worlds for insert with check (auth.uid() = sovereign_id);

-- ── World Members (standing per resident per world) ────────
create table public.world_members (
  id            uuid primary key default uuid_generate_v4(),
  world_id      text not null references public.worlds(id) on delete cascade,
  resident_id   uuid not null references public.profiles(id) on delete cascade,
  resident_name text not null,
  rep           int default 0,
  joined_at     timestamptz default now(),
  unique(world_id, resident_id)
);

alter table public.world_members enable row level security;

create policy "Anyone can read members"
  on public.world_members for select using (true);

create policy "Residents can join worlds"
  on public.world_members for insert with check (auth.uid() = resident_id);

-- ── Channels ───────────────────────────────────────────────
create table public.channels (
  id            text primary key,
  world_id      text not null references public.worlds(id) on delete cascade,
  name          text not null,
  description   text,
  channel_type  text default 'text', -- text, announcement, feed
  position      int default 0,
  is_default    boolean default false,
  created_at    timestamptz default now()
);

alter table public.channels enable row level security;

create policy "Anyone can read channels"
  on public.channels for select using (true);

create policy "World members can create channels"
  on public.channels for insert with check (
    exists (select 1 from public.world_members where world_id = channels.world_id and resident_id = auth.uid())
  );

-- ── Posts ──────────────────────────────────────────────────
create table public.posts (
  id              text primary key,
  world_id        text not null references public.worlds(id) on delete cascade,
  resident_id     uuid not null references public.profiles(id) on delete cascade,
  resident_name   text not null,
  resident_avatar text default '',
  content         text not null,
  image_url       text,
  tier_at_posting int default 1,
  is_announcement boolean default false,
  is_pinned       boolean default false,
  is_edited       boolean default false,
  reactions       jsonb default '{}',
  comments        jsonb default '[]',
  created_at      timestamptz default now()
);

alter table public.posts enable row level security;

create policy "Anyone can read posts"
  on public.posts for select using (true);

create policy "World members can create posts"
  on public.posts for insert with check (
    exists (select 1 from public.world_members where world_id = posts.world_id and resident_id = auth.uid())
  );

create policy "Authors can update own posts"
  on public.posts for update using (auth.uid() = resident_id);

create policy "Authors or moderators can delete posts"
  on public.posts for delete using (auth.uid() = resident_id);

-- ── Events ─────────────────────────────────────────────────
create table public.events (
  id              text primary key,
  world_id        text not null references public.worlds(id) on delete cascade,
  title           text not null,
  description     text default '',
  created_by      uuid not null references public.profiles(id),
  created_by_name text not null,
  starts_at       bigint not null,
  ends_at         bigint,
  rsvp_ids        text[] default '{}',
  created_at      timestamptz default now()
);

alter table public.events enable row level security;

create policy "Anyone can read events"
  on public.events for select using (true);

-- ── Reports ────────────────────────────────────────────────
create table public.reports (
  id            text primary key,
  world_id      text not null references public.worlds(id) on delete cascade,
  post_id       text not null references public.posts(id) on delete cascade,
  reporter_id   uuid not null,
  reason        text not null, -- spam, harassment, hateSpeech, nsfw, misinformation, other
  details       text,
  status        text default 'pending', -- pending, resolved, dismissed
  created_at    timestamptz default now()
);

alter table public.reports enable row level security;

create policy "World moderators can read reports"
  on public.reports for select using (true);

create policy "Anyone can create reports"
  on public.reports for insert with check (true);

-- ── Invites ────────────────────────────────────────────────
create table public.invites (
  id            text primary key,
  world_id      text not null references public.worlds(id) on delete cascade,
  code          text not null unique,
  created_by    uuid not null references public.profiles(id),
  uses          int default 0,
  max_uses      int default 10,
  expires_at    bigint,
  created_at    timestamptz default now()
);

alter table public.invites enable row level security;

create policy "Anyone can read invites"
  on public.invites for select using (true);

create policy "World members can create invites"
  on public.invites for insert with check (
    exists (select 1 from public.world_members where world_id = invites.world_id and resident_id = auth.uid())
  );

-- ── DM Rooms ───────────────────────────────────────────────
create table public.dm_rooms (
  id            text primary key,
  resident_ids  text[] not null,
  names         jsonb default '{}',
  last_message  text,
  last_message_at timestamptz,
  created_at    timestamptz default now()
);

alter table public.dm_rooms enable row level security;

create policy "Users can read own DM rooms"
  on public.dm_rooms for select using (auth.uid() = any(resident_ids));

-- ── Chat Messages ──────────────────────────────────────────
create table public.chat_messages (
  id            text primary key,
  room_id       text not null references public.dm_rooms(id) on delete cascade,
  sender_id     uuid not null references public.profiles(id) on delete cascade,
  content       text not null,
  created_at    timestamptz default now()
);

alter table public.chat_messages enable row level security;

create policy "Room members can read messages"
  on public.chat_messages for select using (
    exists (select 1 from public.dm_rooms where id = chat_messages.room_id and auth.uid() = any(resident_ids))
  );

create policy "Room members can send messages"
  on public.chat_messages for insert with check (
    exists (select 1 from public.dm_rooms where id = chat_messages.room_id and auth.uid() = any(resident_ids))
  );

-- ── Channel Messages ───────────────────────────────────────
create table public.channel_messages (
  id            text primary key,
  channel_id    text not null references public.channels(id) on delete cascade,
  world_id      text not null references public.worlds(id) on delete cascade,
  sender_id     uuid not null references public.profiles(id) on delete cascade,
  sender_name   text not null,
  content       text not null,
  created_at    timestamptz default now()
);

alter table public.channel_messages enable row level security;

create policy "World members can read channel messages"
  on public.channel_messages for select using (
    exists (select 1 from public.world_members where world_id = channel_messages.world_id and resident_id = auth.uid())
  );

create policy "World members can send channel messages"
  on public.channel_messages for insert with check (
    exists (select 1 from public.world_members where world_id = channel_messages.world_id and resident_id = auth.uid())
  );

-- ── Notifications ──────────────────────────────────────────
create table public.notifications (
  id            text primary key,
  recipient_id  uuid not null references public.profiles(id),
  type          text not null, -- like, comment, worldUnlocked, tierUpgrade, welcome, modAction
  message       text not null,
  world_id      text,
  post_id       text,
  read          boolean default false,
  created_at    timestamptz default now()
);

alter table public.notifications enable row level security;

create policy "Users can read own notifications"
  on public.notifications for select using (auth.uid() = recipient_id);

-- ── Moderation Logs ────────────────────────────────────────
create table public.moderation_logs (
  id              text primary key,
  world_id        text not null references public.worlds(id) on delete cascade,
  moderator_id    uuid not null references public.profiles(id),
  target_user_id  uuid not null references public.profiles(id),
  action          text not null, -- mute, unmute, ban, unban, warn
  reason          text,
  duration_hours  int,
  created_at      timestamptz default now()
);

alter table public.moderation_logs enable row level security;

create policy "World moderators can read logs"
  on public.moderation_logs for select using (
    exists (select 1 from public.world_members where world_id = moderation_logs.world_id and resident_id = auth.uid())
  );

-- ── Functions ──────────────────────────────────────────────

-- Toggle reaction on a post
create or replace function public.toggle_reaction(
  post_id   text,
  emoji     text,
  resident_id text
) returns void as $$
begin
  update public.posts
  set reactions = jsonb_set(
    reactions,
    array[emoji],
    coalesce((reactions->>emoji)::int::text, '0')::int + 1
  )::jsonb
  where id = post_id;
end;
$$ language plpgsql;

-- Add comment to a post
create or replace function public.add_comment(
  post_id   text,
  resident_id text,
  content   text
) returns void as $$
begin
  update public.posts
  set comments = comments || jsonb_build_object(
    'id', uuid_generate_v4(),
    'residentId', resident_id,
    'content', content,
    'timestamp', extract(epoch from now()) * 1000
  )::jsonb
  where id = post_id;
end;
$$ language plpgsql;

-- ── Indexes ────────────────────────────────────────────────
create index if not exists idx_posts_world_id on public.posts(world_id);
create index if not exists idx_posts_created_at on public.posts(created_at desc);
create index if not exists idx_world_members_world on public.world_members(world_id);
create index if not exists idx_channel_messages_channel on public.channel_messages(channel_id);
create index if not exists idx_channel_messages_created on public.channel_messages(created_at desc);
create index if not exists idx_chat_messages_room on public.chat_messages(room_id);
create index if not exists idx_chat_messages_created on public.chat_messages(created_at desc);
create index if not exists idx_notifications_recipient on public.notifications(recipient_id);
create index if not exists idx_events_world on public.events(world_id);

-- ── Realtime ───────────────────────────────────────────────
alter publication supabase_realtime add table public.channel_messages;
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.notifications;
