-- Fix: recreate views with security_invoker=true so RLS of the querying
-- user is enforced instead of the view creator's permissions.
-- Safe because all underlying tables (tracks, track_likes, track_saves,
-- track_comments) already have SELECT policies with `using (true)`.

drop view if exists public.community_artist_ranking;
drop view if exists public.track_engagement_stats;
create view public.track_engagement_stats
with (security_invoker = true)
as
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
create view public.community_artist_ranking
with (security_invoker = true)
as
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
