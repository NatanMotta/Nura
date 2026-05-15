create or replace view public.track_engagement_stats as
with likes as (
  select track_id, count(*)::int as likes_count
  from public.track_likes
  group by track_id
),
saves as (
  select track_id, count(*)::int as saves_count
  from public.track_saves
  group by track_id
),
comments as (
  select track_id, count(*)::int as comments_count
  from public.track_comments
  where is_deleted = false
  group by track_id
)
select
  t.id as track_id,
  coalesce(l.likes_count, 0) as likes_count,
  coalesce(s.saves_count, 0) as saves_count,
  coalesce(c.comments_count, 0) as comments_count,
  (
    coalesce(l.likes_count, 0) * 1.0 +
    coalesce(s.saves_count, 0) * 1.5 +
    coalesce(c.comments_count, 0) * 0.5
  )::numeric(12,2) as engagement_score
from public.tracks t
left join likes l on l.track_id = t.id
left join saves s on s.track_id = t.id
left join comments c on c.track_id = t.id;

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
