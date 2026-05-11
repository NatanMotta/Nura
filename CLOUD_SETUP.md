# EPIC 3 — Cloud Setup (Supabase + Cloudflare R2)

## 1) Variabili ambiente (Flutter)
L'app legge variabili via `--dart-define`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Esempio run:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 2) Schema SQL iniziale (Supabase)

```sql
create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('user','artist','label')),
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.labels (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  city text,
  bio text,
  created_at timestamptz not null default now()
);

create table if not exists public.tracks (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  genre text,
  duration_seconds int,
  storage_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.pitch_requests (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.profiles(id) on delete cascade,
  label_id uuid not null references public.labels(id) on delete cascade,
  track_id uuid not null references public.tracks(id) on delete cascade,
  status text not null check (status in ('sent','viewed','shortlisted','rejected')) default 'sent',
  created_at timestamptz not null default now()
);
```

## 3) RLS base (minimo sicuro)

```sql
alter table public.profiles enable row level security;
alter table public.labels enable row level security;
alter table public.tracks enable row level security;
alter table public.pitch_requests enable row level security;

-- profiles
create policy "profiles_select_self"
on public.profiles for select
using (auth.uid() = id);

create policy "profiles_insert_self"
on public.profiles for insert
with check (auth.uid() = id);

create policy "profiles_update_self"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- labels
create policy "labels_owner_select"
on public.labels for select
using (owner_id = auth.uid());

create policy "labels_owner_insert"
on public.labels for insert
with check (owner_id = auth.uid());

create policy "labels_owner_update"
on public.labels for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

-- tracks
create policy "tracks_artist_select"
on public.tracks for select
using (artist_id = auth.uid());

create policy "tracks_artist_insert"
on public.tracks for insert
with check (artist_id = auth.uid());

create policy "tracks_artist_update"
on public.tracks for update
using (artist_id = auth.uid())
with check (artist_id = auth.uid());

-- pitch_requests
create policy "pitch_artist_or_label_select"
on public.pitch_requests for select
using (
  artist_id = auth.uid() or
  label_id in (select id from public.labels where owner_id = auth.uid())
);

create policy "pitch_artist_insert"
on public.pitch_requests for insert
with check (artist_id = auth.uid());

create policy "pitch_label_update"
on public.pitch_requests for update
using (label_id in (select id from public.labels where owner_id = auth.uid()))
with check (label_id in (select id from public.labels where owner_id = auth.uid()));
```

## 4) Ruoli auth (chiusura completa)

Stato attuale app:
- La UI usa `profiles.role` per instradare `RoleGate`.
- In signup viene salvato anche `requested_role` su `user_metadata` come supporto temporaneo.

Per chiudere il punto in modo corretto/production:
- Impostare `app_metadata.role` via canale trusted server/admin.
- Non usare `user_metadata` per autorizzazione.

Template pronto:
- `supabase/functions/sync-user-role/index.ts`

Deploy esempio:

```bash
supabase functions deploy sync-user-role
supabase secrets set INTERNAL_ADMIN_SECRET=YOUR_SECRET
```

Chiamata esempio (da backend trusted):

```bash
curl -X POST 'https://<project-ref>.functions.supabase.co/sync-user-role' \
  -H 'Authorization: Bearer YOUR_INTERNAL_ADMIN_SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"userId":"<uuid>","role":"artist"}'
```

## 5) R2 integrazione (chiusura completa)

Implementazione consigliata:
1. App chiama Edge Function `r2-sign-upload`.
2. Edge Function genera signed URL R2 e ritorna:
   - `uploadUrl`
   - `storagePath`
   - eventuali `headers`
3. App fa `PUT` bytes su `uploadUrl`.
4. App salva su DB `tracks.storage_path` + metadati (durata/owner).

Template funzione:
- `supabase/functions/r2-sign-upload/index.ts`

Servizio app pronto:
- `lib/core/services/r2_upload_service.dart`

Nota sicurezza:
- Nessuna chiave R2 in client.
- Solo signed URL temporanei.

## 6) Stato codice attuale
- Bootstrap Supabase: `lib/core/services/supabase_bootstrap.dart`
- Auth repository base: `lib/features/auth/data/supabase_auth_repository.dart`
- Auth providers: `lib/features/auth/presentation/auth_providers.dart`
- Auth UI minima: `lib/features/auth/presentation/screens/auth_screen.dart`
- R2 upload client service: `lib/core/services/r2_upload_service.dart`

