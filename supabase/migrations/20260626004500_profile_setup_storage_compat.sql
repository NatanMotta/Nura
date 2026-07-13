alter table public.profiles
add column if not exists avatar_url text;
update public.profiles
set avatar_url = image_asset
where avatar_url is null
  and image_asset is not null;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'public read avatars'
  ) then
    create policy "public read avatars"
    on storage.objects
    for select
    using (bucket_id = 'avatars');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'authenticated insert avatars'
  ) then
    create policy "authenticated insert avatars"
    on storage.objects
    for insert
    to authenticated
    with check (bucket_id = 'avatars');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'authenticated update avatars'
  ) then
    create policy "authenticated update avatars"
    on storage.objects
    for update
    to authenticated
    using (bucket_id = 'avatars')
    with check (bucket_id = 'avatars');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'authenticated delete avatars'
  ) then
    create policy "authenticated delete avatars"
    on storage.objects
    for delete
    to authenticated
    using (bucket_id = 'avatars');
  end if;
end $$;
