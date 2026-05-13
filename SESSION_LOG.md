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

### Francesco — Sessione 2026-05-13 (A)
- Obiettivo sessione: Risoluzione errori di compilazione Android (AGP e Kotlin) per compatibilità con Flutter 3.24+.
- Modifiche principali:
  - Aggiornato Android Gradle Plugin (AGP) da 7.3.0 a 8.9.1 per supportare moduli AndroidX.
  - Aggiornato Gradle alla versione 8.11.1.
  - Aggiornato Kotlin alla versione 2.1.0 e aggiunto plugin `org.jetbrains.kotlin.android` in settings.gradle.
  - Eseguito `flutter pub upgrade` per rimozione v1 embedding legacy.
- File coinvolti:
  - `android/settings.gradle`
  - `android/gradle/wrapper/gradle-wrapper.properties`
  - `android/build.gradle`
- Verifiche:
  - `flutter analyze`: non verificato per questa sessione
  - build/test: `flutter build apk --debug` e `assembleDebug` completati con successo senza errori.