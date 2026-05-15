-- Rebalance preview tracks across all active artist tester profiles
-- (artist01..artist10 + asd + gianni) for richer swipe diversity.

with target_profiles as (
  select u.id, u.email, p.display_name
  from auth.users u
  join public.profiles p on p.id = u.id
  where p.role = 'artist'
    and (
      u.email like 'artist%@nura.test'
      or u.email in ('asd@gmail.com', 'giannigiove02@gmail.com')
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
profile_count as (
  select count(*)::int as c from ordered_profiles
),
mapping as (
  select ta.id as track_id,
         op.id as profile_id
  from tracks_to_assign ta
  cross join profile_count pc
  join ordered_profiles op
    on op.rn = ((ta.rn - 1) % pc.c) + 1
)
update public.tracks t
set artist_id = m.profile_id
from mapping m
where t.id = m.track_id;
