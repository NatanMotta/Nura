-- Rebalance all preview tracks across real tester profiles so swipe shows multiple real artists.

with target_profiles as (
  select u.id, u.email
  from auth.users u
  where u.email in (
    'asd@gmail.com',
    'giannigiove02@gmail.com',
    'fraanzescoo@icloud.com',
    'magaldifilippo@gmail.com',
    'natamottadelli@gmail.com',
    'sala88sala@icloud.com'
  )
),
ordered_profiles as (
  select id, row_number() over (order by email) as rn
  from target_profiles
),
tracks_to_assign as (
  select t.id,
         row_number() over (order by t.created_at desc, t.id) as rn
  from public.tracks t
  where t.storage_path is not null
    and t.storage_path like 'previews/%'
),
counts as (
  select count(*)::int as c from ordered_profiles
),
mapping as (
  select ta.id as track_id,
         op.id as profile_id
  from tracks_to_assign ta
  cross join counts c
  join ordered_profiles op
    on op.rn = ((ta.rn - 1) % c.c) + 1
)
update public.tracks t
set artist_id = m.profile_id
from mapping m
where t.id = m.track_id;
