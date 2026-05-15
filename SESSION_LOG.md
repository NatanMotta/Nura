# Nura App — Session Log

Ultimo aggiornamento: 2026-05-11

Questo file contiene il diario cronologico completo delle sessioni di lavoro.

## Log sessioni

### Natan — Sessione 2026-05-07 (A)
- Creato scheletro ruoli con shell dedicate (User/Artist/Label).
- Aggiunto `RoleGate` mock come entry-point esperienza.
- Estesa `BottomNav` per tab dinamiche.
- Verifica statica completata: `flutter analyze` senza errori.

### Natan — Sessione 2026-05-07 (B)
- Integrato `flutter_riverpod`.
- Creato stato globale ruolo (`userRoleProvider`).
- Aggiornato `RoleGate` da ruolo hardcoded a ruolo da provider.
- Aggiornato bootstrap app con `ProviderScope`.
- Verifica statica completata: `flutter analyze` senza errori.

### Natan — Sessione 2026-05-07 (C)
- Creata struttura assets per Task 2.1.
- Registrati i path assets in `pubspec.yaml`.
- Aggiunta checklist operativa `assets/ASSETS_TODO.md`.
- Verifica statica completata: `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (D)
- Completato Task 2.2 con nuovi modelli: `Artist`, `NormalUser`, `Label`, `PitchRequest`.
- Esteso `mock_nura_data.dart` con dataset realistici e riferimenti asset (audio/immagini).
- Esteso `Track` con campi opzionali `audioAsset` e `coverAsset`.
- Wiring minimo su `HomeProfile`: utente e liked tracks ora da mock data.
- Verifica statica completata: `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (E)
- Completato wiring mock su Discovery: le card usano `coverAsset` reale quando presente.
- Rifinito `mock_nura_data.dart` con helper (`getTrackById`, `getArtistById`, `getLabelById`, filtri pitch).
- Task 2.1 chiuso nel perimetro concordato (senza immagini categories).
- Task 2.3 portato a completo per le schermate attive.
- Verifica statica completata: `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (F)
- Collegate le preview audio ai brani salvati in profilo (`HomeProfile`).
- Aggiunto servizio audio globale minimale `AudioPreviewService` con play/pause toggle per track.
- Aggiunta dipendenza `just_audio` in `pubspec.yaml`.
- Verifica statica completata: `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (G)
- Spostato il collegamento preview audio nella sezione Swipe Discovery (non nel profilo).
- `HomeFeed` ora riproduce preview del brano top e passa automaticamente al successivo dopo swipe.
- Pulsante play/pause sulla card swipe collegato a `audioAsset`.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (H)
- Fix iOS per audio plugin: alzato deployment target a iOS 12.0 (`Podfile`, `AppFrameworkInfo.plist`, `project.pbxproj`).
- Eseguito `pod install` con installazione corretta di `audio_session` e `just_audio`.
- Aggiunto `ios/Flutter/Profile.xcconfig` con include Pods profile + Generated.
- Warning residui su UUID RunnerTests presenti ma non bloccanti per plugin audio.

### Natan — Sessione 2026-05-10 (I)
- Fix sincronizzazione autoplay/pulsante play nello swipe.
- `playingTrackId` ora viene aggiornato prima del play per allineare subito UI e stato player.
- Protezione anti-race su callback `completed` per evitare reset del track attivo sbagliato.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (J)
- Abilitato loop continuo preview nello swipe (`LoopMode.one`).
- Aggiunto timer reale da player nella card attiva (`mm:ss / mm:ss`).
- Minutaggio statico sostituito dinamicamente sul top card; fallback invariato sulle card sotto.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (K)
- Decisione di passare alla fase cloud per test realistici multi-account/upload.
- Pianificato stack: Supabase (Auth, Postgres, RLS) + Cloudflare R2 (storage audio/media).
- Definita priorita: setup cloud prima di estendere nuove feature mock.

### Natan — Sessione 2026-05-10 (M)
- Implementata schermata Auth minima (email/password) con Login + Sign up.
- `RoleGate` ora usa stato auth Supabase: non autenticato -> `AuthScreen`, autenticato -> shell ruolo.
- Repository auth esteso con lookup ruolo da tabella `profiles` + creazione profilo default `user` al primo accesso.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-10 (N)
- Sign up reso completo con selezione ruolo (`user|artist|label`) e display name.
- Salvataggio ruolo in `profiles.role` in fase di registrazione.
- Auth screen unificata login/signup con switch mode.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-11 (A)
- Completamento EPIC 3 step 4-5 con artefatti operativi.
- Aggiunte Edge Function template: `sync-user-role` (app_metadata.role) e `r2-sign-upload` (signed URL).
- Aggiunto servizio client `R2UploadService` per flusso signed upload (invoke function + PUT bytes).
- Aggiornato `CLOUD_SETUP.md` con procedure complete e deploy examples.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-11 (B)
- Wiring finale swipe: `HomeFeed` ora tenta lettura tracce reali da Supabase (`public.tracks`) con fallback mock.
- Aggiunto `RemoteTracksService` con mapping DB -> modello `Track`.
- Protezione autoplay: se la traccia cloud non ha URL audio pronta, il player si ferma senza errori.
- `flutter analyze` senza errori.

### Natan — Sessione 2026-05-11 (C)
- Fix audio UX swipe: tasto play/pause ora fa resume sullo stesso brano invece di restart da zero.
- Tracciamento `_loadedTrackId` nel servizio audio per distinguere resume vs reload asset.
- `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (D)
- Seed database remoto completato con profili test reali da `auth.users`:
  - 10 artist (`artist01..10@nura.test`)
  - 5 label (`label1..5@nura.test`)
  - 5 user (`user1..5@nura.test`)
- Popolato/aggiornato `public.profiles` con `role`, `display_name`, `image_asset` (path locali in `assets/images/...`).
- Creati record `public.labels` per i 5 profili label (owner_id collegato al profilo).
- Redistribuite le 11 preview in `public.tracks` sui 10 artist test (round-robin su `artist_id`).
- Verifica post-seed:
  - `profiles`: artist=10, label=5, user=6 (include l'utente storico `Nat_test`)
  - `labels`: 5 record
  - `tracks`: 11 record assegnati a profili artist test.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (E)
- Distribuite tracce demo aggiuntive nel DB remoto:
  - inserite 20 nuove tracce (`Demo Artist XX A/B`) su 10 artist test
  - totale tracce in `public.tracks`: 31
- Swipe Home: aggiunto tap sul nome artista per apertura profilo artista pubblico.
- Nuova schermata: profilo artista pubblico con:
  - immagine profilo (`profiles.image_asset`)
  - lista tracce dell'artista da Supabase
  - play/pause preview locale per ogni traccia.
- Esteso modello `Track` con `artistId` per navigazione profilo da card swipe.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (F)
- Swipe card cloud: aggiunto mapping `storage_path -> coverAsset` per mostrare artwork nella foto grande della card.
- Artwork swipe ora separata dalla foto profilo artista (che resta usata solo nel profilo artista).
- Fix apertura profilo artista da swipe:
  - tap sul nome artista sempre attivo sulla card
  - fallback lookup su `profiles` per recuperare `artist_id` se non presente nel modello.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (G)
- Risolto errore “Profilo artista non disponibile” con fix strutturale RLS su Supabase:
  - nuova policy `profiles_select_artist_public` (read-only profili artist)
  - nuova policy `tracks_select_public` (read-only tracce per discovery/profili)
- Estesa tabella `public.profiles` con colonna `bio`.
- Popolate bio mock per i 10 artist test nel DB.
- Aggiornata schermata profilo artista pubblico:
  - legge `display_name`, `image_asset`, `bio` da Supabase
  - mostra bio e lista tracce reali artista.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (H)
- Redesign completo del profilo artista pubblico in stile social.
- Nuova struttura UI:
  - hero header con cover immersiva
  - stats pills (tracce/battle/vibe)
  - CTA `Segui` e `Invita Battle`
  - bio artista evidenziata
  - chip sezione (`Latest`, `Top Plays`, `Battle Cuts`)
  - feed tracce a card con play/pause.
- Dati reali da Supabase mantenuti (`display_name`, `image_asset`, `bio`, tracce).
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (I)
- Profilo artista: aggiunta banda player inferiore stile Spotify, espandibile/collassabile.
- Funzioni implementate:
  - tap traccia nel profilo -> selezione/riproduzione nel player
  - play/pause reale (senza restart)
  - seek sulla barra di avanzamento
  - prev/next tra brani dell'artista
  - stato tempo corrente/durata sincronizzato in realtime.
- Esteso `AudioPreviewService` con controlli espliciti:
  - `playTrack`, `pause`, `resume`, `seek`
  - notifier `isPlaying`
  - getter `loadedTrackId`.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (J)
- Preparazione TestFlight completata lato processo/build.
- Aggiunto script eseguibile `scripts/testflight_build.sh` per build IPA release con `--dart-define` Supabase.
- Aggiunta guida operativa `TESTFLIGHT_PREP.md` con checklist completa:
  - prerequisiti Apple
  - check bundle id/team
  - build command
  - upload su TestFlight
  - regole versione/build number.
- Nota evidenziata: bundle id iOS attuale è placeholder (`com.example.nuraApp`) e va impostato reale prima dell'upload.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (K)
- Risolto blocco archive iOS/TestFlight causato da Xcode script sandbox:
  - `ENABLE_USER_SCRIPT_SANDBOXING` impostato a `NO` in `project.pbxproj` (Runner configs).
- Pulita cache build locale Xcode (`DerivedData/Runner-*`).
- Podfile già aggiornato per forzare deployment target iOS 12.0 su tutti i Pod (riduzione warning).
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (L)
- Aggiunto logo app: file trovato e spostato in `assets/branding/logo_nura_app.jpeg`.
- Configurato `flutter_launcher_icons` in `pubspec.yaml`.
- Generate icone launcher iOS + Android automaticamente dal logo.
- Consiglio operativo per il futuro: inserire sempre i loghi app in `assets/branding/`.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (M)
- Risolto warning App Store "Launch image is set to the default placeholder icon".
- Sostituiti i file placeholder `LaunchImage` (1x/2x/3x) in `ios/Runner/Assets.xcassets/LaunchImage.imageset/` con il logo reale.
- Le immagini launch erano 1x1 px placeholder; ora sono reali (200/400/600 px).
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (N)
- Implementato EPIC 4 Login Mock con schermata dedicata:
  - nuovo file `lib/features/shared/presentation/screens/mock_role_login_screen.dart`
  - 3 ingressi rapidi: Artista / Utente / Etichetta.
- Aggiornato provider ruolo mock:
  - `userRoleProvider` ora nullable (`UserRole?`) con stato iniziale `null`
  - aggiunto metodo `clear()`.
- Aggiornato `RoleGate`:
  - priorità ruolo: `authUser.role` (reale) -> `mockRole` (mock)
  - se nessun ruolo disponibile mostra `Login Mock`.
- In `Login Mock`, se Supabase è pronto, aggiunto accesso al login reale email/password.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (O)
- Ottimizzazione swipe performance su device reale (riduzione jank durante drag/avvio).
- Aggiornato `home_feed.dart`:
  - rimosso `BackdropFilter` dai bottoni azione circolari (`_RoundBtn`)
  - rimosso blur dal pannello info in basso della card swipe
  - ridotto costo `Waveform` (`count` da 36 a 24)
  - waveform animata solo quando la top card è ferma (`drag == Offset.zero`) e non in exit animation
  - aggiunto throttle su `onPanUpdate` (~60fps) per ridurre `setState` eccessivi durante swipe
  - cover image con `filterQuality: FilterQuality.low`.
- Risultato atteso: meno lag percepito, swipe più fluido e meno “scatti” su hardware reale.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (P)
- EPIC 4 aggiornato a completato (Login Mock).
- Stabilizzazione lifecycle audio implementata in `AudioPreviewService`:
  - aggiunto `WidgetsBindingObserver` globale sul service singleton
  - in `inactive/hidden/paused`: pausa automatica se il player era in play
  - in `resumed`: resume automatico solo se prima del background era in play
  - mantenuto stato `_wasPlayingBeforeBackground` per evitare resume indesiderati.
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (Q)
- EPIC 5 hardening errori audio completato (timeout + fallback UI).
- `AudioPreviewService` aggiornato con:
  - `lastError` (`ValueNotifier<String?>`) per error reporting centralizzato
  - timeout operazioni audio (`setAsset/play/pause/seek/stop`) con soglia 4s
  - wrapper `_runGuarded` con catch uniforme (`MissingPluginException`, `TimeoutException`, errori runtime)
  - messaggi fallback utente quando preview/player non disponibili.
- Fallback UI aggiunto (SnackBar errori audio) in:
  - `home_feed.dart`
  - `artist_public_profile_screen.dart`
  - `home_profile.dart`
- Verifica statica: `flutter analyze` senza errori.

(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-11 (R)
- Separazione documentazione di tracking:
  - creazione `ROADMAP.md` come documento principale roadmap
  - mantenuto `SESSION_LOG.md` come diario cronologico
  - rimosso `SESSION_RECAP.md` su richiesta.
- Build/TestFlight tooling migliorato:
  - aggiornato `scripts/testflight_build.sh` con supporto build number da parametro (`./scripts/testflight_build.sh 3`)
  - aggiunta modalità auto-increment (`--auto`) con stato locale su `.nura_build_number`
  - aggiunti alias shell:
    - `nura-ipa <build_number>`
    - `nura-ipa-auto`.
- Git housekeeping:
  - eliminato branch locale `codex/ottimizzazione-generale`
  - eliminato branch remoto `origin/codex/ott-gen-epic-new`
  - confermati branch attivi: `main`, `codex/ottimizzazione-next`.
- Supporto operativo:
  - spiegati flussi merge/fork/branch
  - generato albero git aggiornato per stato repository.


(appendere qui le sessioni successive)

### Natan — Sessione 2026-05-12 (A)
- Merge completato del ramo `codex/ottimizzazione-next` in `main` dopo test utente positivi.
- Setup pipeline ASC CLI (`asc`) per upload TestFlight:
  - raccolte credenziali API key (`Key ID`, `Issuer ID`, file `.p8`)
  - fix permessi file private key (`chmod 600`)
  - login riuscito con profilo keychain `Nura` (`asc auth status --validate` OK)
  - identificata app target `Nura App` con App ID `6768263432`.
- Automazione terminale upload:
  - creato script `scripts/nura-upload-asc.sh`
  - aggiornato alias `nura-upload` per usare ASC upload (con `ASC_WAIT=1` opzionale)
  - mantenuto flusso operativo semplice: `nura-ipa-auto` -> `nura-upload`.
- Profilo utente (tab destra footer) rifatto in versione minimal:
  - semplificata `home_profile.dart`
  - card profilo essenziale con nome/handle/email/ruolo reali da auth+`profiles` (fallback puliti)
  - lista azioni minima (`Dettagli account`, `Notifiche`, `Impostazioni`).
- Branch dedicato per la nuova fase profilo:
  - creato `codex/implementazione-profilo-utente`
  - commit effettuato: `f2ddea8` (`feat(profile): implementa sezione profilo utente minimal nel tab footer`).
- Nota performance upload:
  - IPA attuale ~83 MB; evidenziati asset immagini come principale fattore di lentezza upload/processing.
- Aggiornamento sessione (A) — audit live Supabase via CLI completato:
  - verificato progetto linkato `vsfaemlbnufprlcxmzwi`
  - stato pre-migrazione confermato: presenti solo `profiles`, `tracks`, `labels`, `pitch_requests`.
- Implementazione immediata backend social MVP su remoto:
  - creata migrazione `supabase/migrations/20260512184500_social_engagement_mvp.sql`
  - eseguito `supabase db push` con successo.
- Oggetti DB attivi in produzione Supabase:
  - tabelle: `track_likes`, `track_saves`, `track_comments`
  - view: `track_engagement_stats`, `community_artist_ranking`
  - RLS/policy: select public + insert/delete owner (like/save), select/insert/update/delete owner (commenti).
- Allineata roadmap:
  - `ROADMAP.md` aggiornato con fase Social Foundation marcata parzialmente completata lato backend.
  - prossimo focus: integrazione CRUD app -> Supabase + binding ranking reale in profilo.
- Aggiornamento sessione (A) — integrazione app con backend social MVP completata:
  - creato `lib/features/social/data/social_engagement_service.dart` (Supabase):
    - fetch metriche engagement per track
    - fetch like/save utente
    - toggle like/save
    - fetch/create commenti.
  - `home_feed.dart` aggiornato:
    - like swipe persistente su `track_likes` quando l'utente è autenticato
    - bookmark salvati persistenti su `track_saves`
    - contatori live per brano top (`like/saves/commenti`) da `track_engagement_stats`
    - bottom sheet commenti con lettura/scrittura su `track_comments`.
  - `home_profile.dart` aggiornato:
    - metriche canzoni proprie alimentate da DB (`track_engagement_stats`) con fallback visivo solo se dati mancanti.
- Verifica statica post-integrazione:
  - `flutter analyze` su file modificati: nessun errore.
- Aggiornamento sessione (A) — refactor profilo richiesto (meno gamer, più social/editoriale):
  - `home_profile.dart` riscritto con layout sobrio (header account + metriche compatte + lista tracce).
  - sezione `Le tue canzoni` ora alimentata da dati reali DB (`tracks` con `storage_path` R2), priorità a tracce dell'utente artista; fallback a ultime tracce reali caricate.
  - tracce cliccabili: tap sulla riga avvia play/pause preview (mapping `storage_path` -> asset locale preview attuale).
  - metriche per traccia (`likes/saves/comments`) lette da `track_engagement_stats` (niente conteggi mock).
  - azioni social per ogni traccia (like/save/comment) mantenute reali su Supabase.
- Verifica statica: `flutter analyze` su `home_profile.dart` senza errori.
- Aggiornamento sessione (A) — audit live utenti/tracce Supabase per test end-to-end:
  - confermato account utente reale `asd@gmail.com` presente su `auth.users` e `profiles`.
  - confermati utenti fake (`user*.nura.test`, `artist*.nura.test`, `label*.nura.test`).
  - confermate tracce reali con path `storage_path` `previews/...` (31 tracce).
- Seed dati test social su tracce reali:
  - distribuiti like/save/commenti su un set di 16 tracce recenti.
  - coinvolti utenti fake + account `asd@gmail.com`.
  - commenti seed marcati con prefisso `[seed]` per tracciabilità.
- Fix critico metriche engagement:
  - corretta view `track_engagement_stats` (prima sovracontava per join multiplicative).
  - nuova migrazione: `20260513201500_fix_engagement_views_counts.sql` applicata su remoto.
- Stato dati dopo seed/fix:
  - `track_likes`: 139
  - `track_saves`: 52
  - `track_comments` attivi: 41
  - `asd@gmail.com` incluso nel seed commenti/like.
- Aggiornamento sessione (A) — fix profilo `asd@gmail.com` senza tracce:
  - root cause 1: profilo `asd@gmail.com` era `role=user`, quindi nessuna traccia propria collegata.
  - root cause 2: `home_profile.dart` interrogava `profiles.username` (colonna non presente), causando errore in load profilo.
- Correzioni applicate:
  - aggiornato `profiles.role` di `asd@gmail.com` a `artist`.
  - assegnate 6 tracce reali (`storage_path` `previews/...`) a `asd@gmail.com` come owner artist.
  - redistribuite le altre tracce reali sui fake artist per mantenere copertura test multi-profilo.
  - patch codice `home_profile.dart` per leggere solo `display_name` da `profiles` e derivare handle da email (niente dipendenza da `username`).
- Verifica post-fix:
  - `asd@gmail.com` risulta `artist` su `profiles`.
  - tracce collegate a `asd@gmail.com`: 6.
  - metriche reali disponibili su quelle tracce (like/save/commenti) via `track_engagement_stats`.

### Natan — Sessione 2026-05-15 (A)
- Refactor profilo utente in stile SoundCloud minimale:
  - `home_profile.dart` alleggerito con layout piu pulito e orientato a lista tracce.
  - mantenuta UX player (play/pause per traccia + mini-player dockato sopra bottom nav).
  - migliorata espansione mini-player: ora toggle anche con tap sull'intera barra, non solo freccia.
  - eliminata ridondanza controlli in stato espanso (niente doppio play visivo nel contesto profilo utente).
- Social nel profilo utente temporaneamente in mock:
  - disattivate chiamate reali like/commenti dal profilo utente.
  - contatori mock per test UI e snackbar informativa `coming soon`.
- Alias terminale release sistemati:
  - fix `~/.zshrc` per `nura-release` e `nura-release-auto` con `SUPABASE_URL` + `SUPABASE_ANON_KEY` inline.
  - risolto problema di quoting alias corrotto e verificata corretta espansione.
- Miglioramento identita mock in app (cross-feature shared):
  - introdotta identita mock (`displayName`, `username`) in `user_role_provider`.
  - `mock_role_login_screen` aggiornato con profili test realistici per ruolo:
    - Artista: `Luca Neon` (`@luca.neon`)
    - Utente: `Giulia Wave` (`@giulia.wave`)
    - Etichetta: `Marta A&R` (`@marta.label`)
  - `home_profile.dart` usa identita mock quando non c'e auth reale (no piu `Utente/@guest`).
  - `profile_settings_screen.dart` aggiornata per pulire anche identita mock su `Esci dal ruolo mock` e logout.
- Aggiornamento dati mock su Supabase:
  - migrazione applicata `20260515101500_refresh_mock_profiles_display_names.sql`
  - aggiornata anagrafica profili test (`display_name` + `bio`) inclusa `asd@gmail.com` (`Natan Test`).
  - fix migrazione: rimosso campo `updated_at` non presente in `profiles`.
- Sezione swipe aggiornata per profili reali Supabase (cross-feature discovery):
  - `remote_tracks_service.dart`: filtro tracce remote per includere solo artisti reali validi (`artist_id`/`display_name` non nulli, no `Unknown Artist`).
  - `home_feed.dart`: snackbar esplicita se non vengono trovate tracce remote valide.
  - nuova migrazione applicata `20260515123000_redistribute_preview_tracks_real_profiles.sql`:
    - ridistribuite tracce demo `preview_audio_1..11.mp3` su profili reali Supabase (incluso mock privato e altri profili test).
- Ribilanciamento ulteriore richiesto per evitare concentrazione su pochi profili:
  - query remota verificata: distribuzione iniziale sbilanciata su `Natan Test` e `Gianni Giove`.
  - applicata nuova migrazione `20260515134500_rebalance_preview_tracks_across_artist_testers.sql`.
  - risultato verificato con query `supabase db query --linked`:
    - tracce preview distribuite su `Artist 01..10` + `Gianni Giove` + `Natan Test` (2-3 tracce ciascuno).
- Fix falsi positivi timeout audio (cross-feature core):
  - file modificato `lib/core/services/audio_preview_service.dart`.
  - comportamento aggiornato:
    - se scatta timeout ma il player risulta comunque operativo (`playing` o `ProcessingState.ready/buffering`), errore utente soppresso.
    - mantenuto log tecnico con `debugPrint`.
  - obiettivo: evitare snackbar `Operazione audio in timeout` quando l'audio funziona regolarmente.