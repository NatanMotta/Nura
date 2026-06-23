-- Social engagement MVP: likes, saves, comments + ranking view

create table if not exists public.track_likes (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (track_id, user_id)
);

create table if not exists public.track_saves (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (track_id, user_id)
);

create table if not exists public.track_comments (
  id uuid primary key default gen_random_uuid(),
  track_id uuid not null references public.tracks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint track_comments_body_len check (char_length(trim(body)) between 1 and 500)
);

create index if not exists idx_track_likes_track_id on public.track_likes(track_id);
create index if not exists idx_track_likes_user_id on public.track_likes(user_id);
create index if not exists idx_track_saves_track_id on public.track_saves(track_id);
create index if not exists idx_track_saves_user_id on public.track_saves(user_id);
create index if not exists idx_track_comments_track_id_created_at on public.track_comments(track_id, created_at desc);
create index if not exists idx_track_comments_user_id on public.track_comments(user_id);

create or replace function public.set_track_comments_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_track_comments_updated_at on public.track_comments;
create trigger trg_track_comments_updated_at
before update on public.track_comments
for each row
execute function public.set_track_comments_updated_at();

alter table public.track_likes enable row level security;
alter table public.track_saves enable row level security;
alter table public.track_comments enable row level security;

-- Likes policies
create policy track_likes_select_public
on public.track_likes
for select
using (true);

create policy track_likes_insert_self
on public.track_likes
for insert
with check (auth.uid() = user_id);

create policy track_likes_delete_self
on public.track_likes
for delete
using (auth.uid() = user_id);

-- Saves policies
create policy track_saves_select_public
on public.track_saves
for select
using (true);

create policy track_saves_insert_self
on public.track_saves
for insert
with check (auth.uid() = user_id);

create policy track_saves_delete_self
on public.track_saves
for delete
using (auth.uid() = user_id);

-- Comments policies
create policy track_comments_select_public
on public.track_comments
for select
using (true);

create policy track_comments_insert_self
on public.track_comments
for insert
with check (auth.uid() = user_id);

create policy track_comments_update_self
on public.track_comments
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy track_comments_delete_self
on public.track_comments
for delete
using (auth.uid() = user_id);

create or replace view public.track_engagement_stats as
select
  t.id as track_id,
  count(distinct tl.user_id)::int as likes_count,
  count(distinct ts.user_id)::int as saves_count,
  count(tc.id) filter (where tc.is_deleted = false)::int as comments_count,
  (
    count(distinct tl.user_id) * 1.0 +
    count(distinct ts.user_id) * 1.5 +
    count(tc.id) filter (where tc.is_deleted = false) * 0.5
  )::numeric(12,2) as engagement_score
from public.tracks t
left join public.track_likes tl on tl.track_id = t.id
left join public.track_saves ts on ts.track_id = t.id
left join public.track_comments tc on tc.track_id = t.id
group by t.id;

create or replace view public.community_artist_ranking as
with per_track as (
  select
    t.artist_id,
    es.likes_count,
    es.saves_count,
    es.comments_count,
    es.engagement_score
  from public.track_engagement_stats es
  join public.tracks t on t.id = es.track_id
)
select
  artist_id,
  coalesce(sum(likes_count), 0)::int as total_likes,
  coalesce(sum(saves_count), 0)::int as total_saves,
  coalesce(sum(comments_count), 0)::int as total_comments,
  coalesce(sum(engagement_score), 0)::numeric(12,2) as total_score,
  dense_rank() over (order by coalesce(sum(engagement_score), 0) desc) as rank_position
from per_track
group by artist_id;
