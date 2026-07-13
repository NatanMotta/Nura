alter table public.tracks
add column if not exists raw_storage_path text,
add column if not exists source_content_type text,
add column if not exists transcoding_status text not null default 'ready'
  check (transcoding_status in ('ready', 'processing', 'failed')),
add column if not exists transcoding_error text;
update public.tracks
set transcoding_status = 'ready'
where storage_path is not null
  and transcoding_status is distinct from 'ready';
create index if not exists idx_tracks_artist_status_created_at
on public.tracks (artist_id, transcoding_status, created_at desc);
