-- Run in Supabase SQL Editor. This is a self-contained schema for Fasl.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  display_name text not null default '',
  avatar text not null default '🙂',
  role text not null default 'student' check (role in ('student','teacher')),
  created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  sender_name text not null,
  room text not null default 'general' check (room in ('general','class-call')),
  body text not null default '',
  image_url text,
  created_at timestamptz not null default now(),
  constraint messages_need_content check (length(trim(body)) > 0 or image_url is not null)
);
create table if not exists public.timetable (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  day_name text not null,
  starts_at time not null,
  ends_at time not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint valid_time_range check (ends_at > starts_at)
);
create table if not exists public.class_sessions (
  id uuid primary key default gen_random_uuid(),
  room_name text not null default 'fasl-3eme-info',
  active boolean not null default true,
  started_by uuid references auth.users(id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

alter table public.profiles enable row level security;
alter table public.messages enable row level security;
alter table public.timetable enable row level security;
alter table public.class_sessions enable row level security;

-- Authenticated users can read profiles and messages. Users may only edit their own profile.
drop policy if exists "profiles read authenticated" on public.profiles;
create policy "profiles read authenticated" on public.profiles for select to authenticated using (true);
drop policy if exists "profile insert self" on public.profiles;
create policy "profile insert self" on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists "profile update self" on public.profiles;
create policy "profile update self" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "messages read authenticated" on public.messages;
create policy "messages read authenticated" on public.messages for select to authenticated using (true);
drop policy if exists "messages insert self" on public.messages;
create policy "messages insert self" on public.messages for insert to authenticated with check (sender_id = auth.uid());
-- Teacher-only delete is enforced by a protected role claim/server policy in production. Do not trust a role value supplied by a browser.
-- For a secure teacher delete policy, use a server-managed app_metadata claim and a helper function; see README.

drop policy if exists "timetable read authenticated" on public.timetable;
create policy "timetable read authenticated" on public.timetable for select to authenticated using (true);
drop policy if exists "timetable teacher insert" on public.timetable;
create policy "timetable teacher insert" on public.timetable for insert to authenticated with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher'));
drop policy if exists "timetable teacher delete" on public.timetable;
create policy "timetable teacher delete" on public.timetable for delete to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher'));

drop policy if exists "sessions read authenticated" on public.class_sessions;
create policy "sessions read authenticated" on public.class_sessions for select to authenticated using (true);
drop policy if exists "sessions teacher insert" on public.class_sessions;
create policy "sessions teacher insert" on public.class_sessions for insert to authenticated with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher'));
drop policy if exists "sessions teacher update" on public.class_sessions;
create policy "sessions teacher update" on public.class_sessions for update to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher'));

-- Realtime support for messages and sessions.
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; when others then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.class_sessions;
exception when duplicate_object then null; when others then null; end $$;
