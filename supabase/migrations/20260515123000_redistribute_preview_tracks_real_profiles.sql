-- Redistribute preview demo tracks across real Supabase profiles
-- so swipe cards always point to real artist profiles.

with profile_map as (
  select u.id as profile_id, u.email
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
target_assignments as (
  select 'preview_audio_1.mp3'::text as file_name, 'asd@gmail.com'::text as email union all
  select 'preview_audio_2.mp3', 'giannigiove02@gmail.com' union all
  select 'preview_audio_3.mp3', 'fraanzescoo@icloud.com' union all
  select 'preview_audio_4.mp3', 'magaldifilippo@gmail.com' union all
  select 'preview_audio_5.mp3', 'natamottadelli@gmail.com' union all
  select 'preview_audio_6.mp3', 'sala88sala@icloud.com' union all
  select 'preview_audio_7.mp3', 'asd@gmail.com' union all
  select 'preview_audio_8.mp3', 'giannigiove02@gmail.com' union all
  select 'preview_audio_9.mp3', 'fraanzescoo@icloud.com' union all
  select 'preview_audio_10.mp3', 'magaldifilippo@gmail.com' union all
  select 'preview_audio_11.mp3', 'natamottadelli@gmail.com'
)
update public.tracks t
set artist_id = pm.profile_id
from target_assignments ta
join profile_map pm on pm.email = ta.email
where split_part(t.storage_path, '/', 2) = ta.file_name;

