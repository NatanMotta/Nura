# Nura App (Flutter)

App mobile Flutter per discovery musicale e profili social (utente/artista/label), con backend Supabase e pipeline di rilascio iOS su TestFlight.

## Panoramica

Nura è organizzata a feature, con UI social-first:

- feed swipe discovery
- profili utente/artista in stile social
- engagement reale su brani (`like`, `save`, `commenti`)
- viste dedicate per ruoli diversi (`user`, `artist`, `label`)

Stack principale:

- Flutter (Dart)
- Riverpod (`flutter_riverpod`)
- Supabase (`supabase_flutter`)
- Audio preview (`just_audio`)

## Struttura del progetto

```text
lib/
  app/
    nura_app.dart                # root app, shell principale
    router/                      # routing schermate principali
    theme/                       # tema, palette, vibe

  core/
    constants/
    models/
    services/                    # bootstrap Supabase, audio service, ecc.
    utils/
    widgets/                     # componenti UI condivisi

  features/
    auth/                        # autenticazione + provider auth
    onboarding/
    discovery/swipe/             # feed swipe + profili artista da swipe
    social/data/                 # servizio engagement (like/save/commenti)

    user/
      home/
      search/
      rankings/
      profile/                   # profilo personale + dettaglio traccia
      shell/

    artist/
      dashboard/
      profile/
      submissions/
      upload_track/
      battles/
      shell/

    label/
      dashboard/
      artist_monitoring/
      received_tracks/
      shortlist/
      shell/

    shared/                      # layer condiviso tra ruoli

assets/
  audio/
  branding/
  images/

supabase/
  migrations/                    # schema DB, social tables/views
  functions/                     # edge functions

scripts/
  testflight_build.sh
  testflight_upload.sh
  testflight_release.sh
  nura-upload-asc.sh
```

## Flussi applicativi principali

1. Login/registrazione utente (Supabase Auth).
2. Caricamento profilo + ruolo (`user`, `artist`, `label`).
3. Navigazione feed discovery con swipe e preview audio.
4. Interazioni social su tracce:
   - like (`track_likes`)
   - salvataggi (`track_saves`)
   - commenti (`track_comments`)
5. Visualizzazione profili con metriche reali aggregate da view SQL.

## Backend Supabase

### Migrazioni rilevanti

- `20260512184500_social_engagement_mvp.sql`
  - tabelle social: `track_likes`, `track_saves`, `track_comments`
  - policy RLS
  - view aggregate (`track_engagement_stats`, `community_artist_ranking`)
- `20260513192500_tracks_add_cover_image_asset.sql`
  - aggiunta `tracks.cover_image_asset`
- `20260513201500_fix_engagement_views_counts.sql`
  - fix conteggi engagement nella view

### Edge Functions

- `sync-user-role`: sincronizzazione ruolo utente
- `r2-sign-upload`: endpoint per firma/upload (stato dipendente dall'implementazione corrente)

## Requisiti locali

- Flutter SDK (compatibile con `sdk: '>=3.2.3 <4.0.0'`)
- Xcode + CocoaPods (per iOS)
- Supabase CLI (per migrazioni e debug DB)
- `asc` CLI (per upload build iOS su App Store Connect)

## Configurazione ambiente

Impostare le variabili usate a runtime/build:

```bash
export SUPABASE_URL="https://<project>.supabase.co"
export SUPABASE_ANON_KEY="<anon-key>"
```

## Avvio app in locale

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

## Build iOS + TestFlight

### Build automatica numero versione

```bash
./scripts/testflight_build.sh --auto
```

Oppure build number esplicito:

```bash
./scripts/testflight_build.sh 42
```

### Upload con ASC

```bash
./scripts/nura-upload-asc.sh
```

Variabili utili:

- `ASC_APP_ID` (default script: `6768263432`)
- `ASC_WAIT=1` per attendere il processing completo upload

### Build + Upload in un comando

```bash
./scripts/testflight_release.sh --auto
```

## Convenzioni operative

- Architettura feature-first.
- Layer consigliati per feature: `data / domain / presentation`.
- UI con componenti condivisi in `core/widgets`.
- Stato e dipendenze via Riverpod.
- Ogni modifica backend deve passare da migrazione SQL versionata.

## Documentazione interna correlata

- `ROADMAP.md`: stato task e pianificazione
- `SESSION_LOG.md`: log operativo sessioni
- `CLOUD_SETUP.md`: setup servizi cloud
- `TESTFLIGHT_PREP.md`: checklist rilascio iOS

