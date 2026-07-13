-- MVP: WAV uploads are marked ready immediately using the raw path.
-- Replace this trigger with a real transcoding pipeline when available.
create or replace function public.auto_finalise_wav_upload()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.transcoding_status = 'processing'
     and new.raw_storage_path is not null
     and new.storage_path is null
  then
    new.storage_path     := new.raw_storage_path;
    new.transcoding_status := 'ready';
  end if;
  return new;
end;
$$;
drop trigger if exists trg_auto_finalise_wav on public.tracks;
create trigger trg_auto_finalise_wav
  before insert on public.tracks
  for each row
  execute function public.auto_finalise_wav_upload();
