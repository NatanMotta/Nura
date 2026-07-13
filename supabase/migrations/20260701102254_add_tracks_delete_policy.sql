-- Allow artists to delete their own tracks.
-- Without this policy, DELETE calls are silently blocked by RLS.
create policy "tracks_artist_delete"
on public.tracks
for delete
using (artist_id = auth.uid());
