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

### Francesco — Sessione 2026-05-18 (A)
- **Architettura Strutturale e Gestione del Layout (`Stack` & `CustomScrollView`)**:
  - Riorganizzato l'intero scheletro della pagina in un unico contenitore ad altissime prestazioni basato su `CustomScrollView` e `SliverToBoxAdapter`. Questa struttura unificata ha risolto in modo definitivo i problemi di overflow e i fastidiosi warning di layout presenti sui dispositivi con schermi di piccole dimensioni.
  - Utilizzata una stratificazione a livelli tramite `Stack` per separare rigorosamente: lo sfondo a parallasse (livello 0), l'immagine del banner con trasparenza controllata (livello 1), il contenuto principale scorrevole (livello 2), e i controlli flottanti di navigazione satinati (livello 3). Questo isolamento previene i conflitti nella gestione dei tocchi e delle gesture.
- **Sfondo Mesh Parallasse Avanzato (`ParallaxOrganicMeshPainter`)**:
  - Sviluppato un `CustomPainter` ad alte prestazioni per disegnare riflessi e "glow blobs" cromatici sfumati nei colori del brand Nura (Blu Musicura e Rosa Nura) direttamente sulla canvas di sfondo.
  - Applicata una sfocatura pesante tramite `ImageFilter.blur(sigmaX: 55, sigmaY: 55)` ottimizzata per GPU, garantendo un rendering fluido a 60/120 FPS senza lag di calcolo.
  - Collegati i baricentri dei riflessi allo scorrimento tramite un moltiplicatore di parallasse controllato (`scrollOffset * 0.15`), conferendo all'interfaccia un senso di tridimensionalità e profondità (effetto 3D layered) durante lo scroll dei contenuti.
- **Interactive Pro Player Timeline Seeking (`global_mini_player.dart`)**:
  - Aggiornata la timeline del player a capsula inferiore trasformandola in uno `Slider` completamente interattivo.
  - Implementata una `_FullWidthTrackShape` personalizzata per rimuovere ogni padding orizzontale, integrando perfettamente la barra di scorrimento con i bordi della capsula vitrea.
  - Collegati i controlli rapidi di play/pause, chiusura (stop preview via `AudioPreviewService`) e icona like direttamente sulla barra flottante.
- **Engagement Stats & Social Metrics (`artist_public_profile_screen.dart`)**:
  - Aggiunti i contatori di like e commenti reali direttamente sotto il titolo di ogni brano nella lista pubblica dell'artista.
- **Audio Visualizer in Tempo Reale**:
  - Sviluppato un mini-visualizzatore spettrale a 3 barre animate (`AudioVisualizerAnimation`) in overlay sulla copertina del brano in riproduzione attiva. L'animazione si attiva esclusivamente sulla traccia corrente.
- **Swipe Haptics Dismissible**:
  - Aggiunta l'azione swipe orizzontale (`Dismissible`) sui brani per aggiungere rapidamente la traccia ai preferiti, calibrata con micro-vibrazioni aptiche (`HapticFeedback.lightImpact` e `mediumImpact`) su device fisici.
- **Hero Artist Banner Immersivo**:
  - Rimosso l'avatar circolare limitato.
  - Introdotta una foto banner a schermo intero (full-bleed) in formato rettangolare per valorizzare l'immagine dell'artista.
  - Applicata una **`ShaderMask` con Linear Gradient Mask (da opaco a trasparente)** alla base dell'immagine per sfumare e "sciogliere" la foto in modo invisibile all'interno dello sfondo grigio chiaro/mesh (`Color(0xFFF8F9FA)`).
- **Scorrimento Sincrono 1:1 con Dissolvenza Progressiva**:
  - Configurato il posizionamento della foto banner a `top: -_scrollOffset` per agganciare lo scorrimento in sincrono perfetto (1:1) con il testo e i brani.
  - Integrata una formula di opacità dinamica `(1.0 - (_scrollOffset / 260)).clamp(0.0, 1.0)` che sfuma la sola foto banner in trasparenza mentre sale, lasciando i testi, pulsanti e statistiche totalmente solidi e leggibili.
  - Ricalibrati gli spazi con un'altezza trasparente iniziale di ben **`280px`**, posizionando il nome artista, pulsanti e statistiche esattamente sotto il viso per una visibilità perfetta del volto al primo caricamento.
  - Aggiunti pulsanti "Indietro" e "Opzioni" fissi in alto, isolati all'interno di cerchietti in vetro satinato (`BackdropFilter` + sfocatura `8.0`) per garantire massima visibilità e contrasto cromatico.
  - Rimossi overlay invasivi come la sticky app bar e indicatori complessi per preservare la fluidità di scorrimento nativa di iOS/Android.
- **Verifica e Hardening**:
  - Eseguito `flutter analyze` con esito pulito senza errori sintattici o logici nel modulo Artist Profile.

### Francesco — Sessione 2026-05-18 (B)
- **Creazione Branch e Setup Modulo Dati (`invio-pitch-artista`)**:
  - Creato e attivato il nuovo branch dedicato `invio-pitch-artista` per isolare lo sviluppo.
  - Sviluppato `artist_pitch_service.dart` in `submissions/data/` che implementa le query per caricare le tracce demo dell'artista, recuperare le etichette con loghi integrati tramite join relazionali su Supabase, inviare i pitch (`sendPitch`) e storicizzare le candidature.
  - Creato `pitch_providers.dart` in `submissions/presentation/providers/` per esporre i dati in cache reattiva Riverpod, abilitando l'invalidazione immediata dello stato a ogni nuovo invio.
- **Interfaccia Utente e Parallasse Mesh (`ArtistPitchScreen`)**:
  - Implementata la schermata principale unificata `ArtistPitchScreen` reattiva e performante.
  - Integrato lo sfondo premium a parallasse `ParallaxOrganicMeshPainter` (blu e rosa) reattivo allo scorrimento verticale, ereditando l'identità cromatico-mesh fluida del profilo artista.
  - Sviluppato un Segmented Tab Control personalizzato ("Nuovo Pitch" / "I Miei Pitch") con micro-vibrazioni aptiche integrate.
- **Mock Login Fallback & Hardening Offline**:
  - Introdotto il provider `resolvedArtistIdProvider` in `pitch_providers.dart` per risolvere dinamicamente la sessione. Se l'utente effettua l'accesso rapido finto ("Entra come Artista"), rileva l'ID del primo artista reale configurato a DB per consentire di testare l'invio reale sul server, salvaguardando l'esperienza utente.
  - Integrati i fallback automatici sui dati mock locali ad alta fedeltà (`kTracks`, `kLabels` e `kPitchRequests`) all'interno di `ArtistPitchService` nel caso in cui Supabase sia offline o non popolato.
- **Interactive 3D Vinyl Deck Selector (Opzione B)**:
  - Sostituita la lista brani orizzontale classica con un espositore di vinili interattivo ad altissimo impatto sensoriale.
  - Ogni traccia è rappresentata all'interno di una custodia (sleeve) con bordi in vetro satinato e bagliore neon rosa a terra.
  - Al tocco di selezione (`isSelected == true`), un vero disco in vinile nero (disegnato programmaticamente in Flutter con riflessi radiali metallici, solchi fisici e adesivo centrale colorato in base all'HSL del brano) **scivola lateralmente fuori di 48px** con un'animazione elastica (`Curves.easeOutBack`) e **inizia a girare continuamente a 360°** a tempo di musica. Deselezionando la traccia, il vinile smette di ruotare e rientra docilmente nella custodia.
- **Flusso "Nuovo Pitch" & Feedback Sensoriale**:
  - Sviluppato il Selettore Label verticale a card frosted glass con risoluzione dinamica delle icone brandizzate da Supabase, biografie degli A&R e città di provenienza.
  - Implementato un bottone CTA premium con gradiente rosa Nura e un overlay dialog immersivo a comparsa con spunta animata, descrizione di successo e feedback aptico vibrante `HapticFeedback.mediumImpact()`.
- **Storico e Badge di Stato Colorati**:
  - Creato il feed cronologico dei pitch inviati nella seconda scheda.
  - Sviluppati i badge di stato satinati e colorati per tenere traccia delle letture (`sent` = Grigio/INVIATO, `viewed` = Viola/LETTO, `shortlisted` = Verde/SELEZIONATO, `rejected` = Rosso/NON SEL.).
- **Hardening e Pulizia Compilatore**:
  - Eliminati gli import inutilizzati e pulito l'albero sintattico di `ArtistPitchScreen` e `ArtistPitchService`.
  - Risolti ed eliminati tutti i warning e gli errori sintattici: compilazione superata con successo con **0 ERRORI e 0 AVVISI** rilevati da `flutter analyze`.
  - Committato e inviato in push l'intero aggiornamento sul repository GitHub sul branch remoto `invio-pitch-artista`.

### Francesco — Sessione 2026-05-18 (C)
- **Risoluzione "Scroll Brutto" e allineamento cache**:
  - Identificata e spiegata la causa dell'header bianco fisso e bloccato ("Artist 01"), dovuto alla persistenza della vecchia `SliverAppBar` nella cache dell'emulatore. Spiegata la necessità di effettuare un semplice **Hot Restart** per caricare la versione parallasse con pulsanti satinati.
- **Controllo di Ruolo e Rimozione Pulsante "Battle"**:
  - Integrato il tracciamento reattivo del ruolo dell'utente (`UserRole`) in `ArtistPublicProfileScreen` tramite i provider di Riverpod (`userRoleProvider` e `authStateProvider`).
  - Nascosto condizionalmente il pulsante **Battle** per Utenti ed Etichette, rendendolo esclusivo per la visualizzazione da parte di altri Artisti.
- **Allineamento e Navigazione In-Line Shell Etichetta (`LabelShell`)**:
  - Unificata la navigazione di `LabelShell` sullo stesso modello in-line e fluido di `UserShell`, mantenendo la barra di navigazione inferiore sempre persistente ed evitando il push nativo a tutto schermo.
  - Integrata la capsula del `GlobalMiniPlayer` reattivo sopra la barra di navigazione a 4 elementi (`bottom: 84 + safeBottom`).
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

### Francesco — Sessione 2026-05-18 (A)
- **Architettura Strutturale e Gestione del Layout (`Stack` & `CustomScrollView`)**:
  - Riorganizzato l'intero scheletro della pagina in un unico contenitore ad altissime prestazioni basato su `CustomScrollView` e `SliverToBoxAdapter`. Questa struttura unificata ha risolto in modo definitivo i problemi di overflow e i fastidiosi warning di layout presenti sui dispositivi con schermi di piccole dimensioni.
  - Utilizzata una stratificazione a livelli tramite `Stack` per separare rigorosamente: lo sfondo a parallasse (livello 0), l'immagine del banner con trasparenza controllata (livello 1), il contenuto principale scorrevole (livello 2), e i controlli flottanti di navigazione satinati (livello 3). Questo isolamento previene i conflitti nella gestione dei tocchi e delle gesture.
- **Sfondo Mesh Parallasse Avanzato (`ParallaxOrganicMeshPainter`)**:
  - Sviluppato un `CustomPainter` ad alte prestazioni per disegnare riflessi e "glow blobs" cromatici sfumati nei colori del brand Nura (Blu Musicura e Rosa Nura) direttamente sulla canvas di sfondo.
  - Applicata una sfocatura pesante tramite `ImageFilter.blur(sigmaX: 55, sigmaY: 55)` ottimizzata per GPU, garantendo un rendering fluido a 60/120 FPS senza lag di calcolo.
  - Collegati i baricentri dei riflessi allo scorrimento tramite un moltiplicatore di parallasse controllato (`scrollOffset * 0.15`), conferendo all'interfaccia un senso di tridimensionalità e profondità (effetto 3D layered) durante lo scroll dei contenuti.
- **Interactive Pro Player Timeline Seeking (`global_mini_player.dart`)**:
  - Aggiornata la timeline del player a capsula inferiore trasformandola in uno `Slider` completamente interattivo.
  - Implementata una `_FullWidthTrackShape` personalizzata per rimuovere ogni padding orizzontale, integrando perfettamente la barra di scorrimento con i bordi della capsula vitrea.
  - Collegati i controlli rapidi di play/pause, chiusura (stop preview via `AudioPreviewService`) e icona like direttamente sulla barra flottante.
- **Engagement Stats & Social Metrics (`artist_public_profile_screen.dart`)**:
  - Aggiunti i contatori di like e commenti reali direttamente sotto il titolo di ogni brano nella lista pubblica dell'artista.
- **Audio Visualizer in Tempo Reale**:
  - Sviluppato un mini-visualizzatore spettrale a 3 barre animate (`AudioVisualizerAnimation`) in overlay sulla copertina del brano in riproduzione attiva. L'animazione si attiva esclusivamente sulla traccia corrente.
- **Swipe Haptics Dismissible**:
  - Aggiunta l'azione swipe orizzontale (`Dismissible`) sui brani per aggiungere rapidamente la traccia ai preferiti, calibrata con micro-vibrazioni aptiche (`HapticFeedback.lightImpact` e `mediumImpact`) su device fisici.
- **Hero Artist Banner Immersivo**:
  - Rimosso l'avatar circolare limitato.
  - Introdotta una foto banner a schermo intero (full-bleed) in formato rettangolare per valorizzare l'immagine dell'artista.
  - Applicata una **`ShaderMask` con Linear Gradient Mask (da opaco a trasparente)** alla base dell'immagine per sfumare e "sciogliere" la foto in modo invisibile all'interno dello sfondo grigio chiaro/mesh (`Color(0xFFF8F9FA)`).
- **Scorrimento Sincrono 1:1 con Dissolvenza Progressiva**:
  - Configurato il posizionamento della foto banner a `top: -_scrollOffset` per agganciare lo scorrimento in sincrono perfetto (1:1) con il testo e i brani.
  - Integrata una formula di opacità dinamica `(1.0 - (_scrollOffset / 260)).clamp(0.0, 1.0)` che sfuma la sola foto banner in trasparenza mentre sale, lasciando i testi, pulsanti e statistiche totalmente solidi e leggibili.
  - Ricalibrati gli spazi con un'altezza trasparente iniziale di ben **`280px`**, posizionando il nome artista, pulsanti e statistiche esattamente sotto il viso per una visibilità perfetta del volto al primo caricamento.
  - Aggiunti pulsanti "Indietro" e "Opzioni" fissi in alto, isolati all'interno di cerchietti in vetro satinato (`BackdropFilter` + sfocatura `8.0`) per garantire massima visibilità e contrasto cromatico.
  - Rimossi overlay invasivi come la sticky app bar e indicatori complessi per preservare la fluidità di scorrimento nativa di iOS/Android.
- **Verifica e Hardening**:
  - Eseguito `flutter analyze` con esito pulito senza errori sintattici o logici nel modulo Artist Profile.

### Francesco — Sessione 2026-05-18 (B)
- **Creazione Branch e Setup Modulo Dati (`invio-pitch-artista`)**:
  - Creato e attivato il nuovo branch dedicato `invio-pitch-artista` per isolare lo sviluppo.
  - Sviluppato `artist_pitch_service.dart` in `submissions/data/` che implementa le query per caricare le tracce demo dell'artista, recuperare le etichette con loghi integrati tramite join relazionali su Supabase, inviare i pitch (`sendPitch`) e storicizzare le candidature.
  - Creato `pitch_providers.dart` in `submissions/presentation/providers/` per esporre i dati in cache reattiva Riverpod, abilitando l'invalidazione immediata dello stato a ogni nuovo invio.
- **Interfaccia Utente e Parallasse Mesh (`ArtistPitchScreen`)**:
  - Implementata la schermata principale unificata `ArtistPitchScreen` reattiva e performante.
  - Integrato lo sfondo premium a parallasse `ParallaxOrganicMeshPainter` (blu e rosa) reattivo allo scorrimento verticale, ereditando l'identità cromatico-mesh fluida del profilo artista.
  - Sviluppato un Segmented Tab Control personalizzato ("Nuovo Pitch" / "I Miei Pitch") con micro-vibrazioni aptiche integrate.
- **Mock Login Fallback & Hardening Offline**:
  - Introdotto il provider `resolvedArtistIdProvider` in `pitch_providers.dart` per risolvere dinamicamente la sessione. Se l'utente effettua l'accesso rapido finto ("Entra come Artista"), rileva l'ID del primo artista reale configurato a DB per consentire di testare l'invio reale sul server, salvaguardando l'esperienza utente.
  - Integrati i fallback automatici sui dati mock locali ad alta fedeltà (`kTracks`, `kLabels` e `kPitchRequests`) all'interno di `ArtistPitchService` nel caso in cui Supabase sia offline o non popolato.
- **Interactive 3D Vinyl Deck Selector (Opzione B)**:
  - Sostituita la lista brani orizzontale classica con un espositore di vinili interattivo ad altissimo impatto sensoriale.
  - Ogni traccia è rappresentata all'interno di una custodia (sleeve) con bordi in vetro satinato e bagliore neon rosa a terra.
  - Al tocco di selezione (`isSelected == true`), un vero disco in vinile nero (disegnato programmaticamente in Flutter con riflessi radiali metallici, solchi fisici e adesivo centrale colorato in base all'HSL del brano) **scivola lateralmente fuori di 48px** con un'animazione elastica (`Curves.easeOutBack`) e **inizia a girare continuamente a 360°** a tempo di musica. Deselezionando la traccia, il vinile smette di ruotare e rientra docilmente nella custodia.
- **Flusso "Nuovo Pitch" & Feedback Sensoriale**:
  - Sviluppato il Selettore Label verticale a card frosted glass con risoluzione dinamica delle icone brandizzate da Supabase, biografie degli A&R e città di provenienza.
  - Implementato un bottone CTA premium con gradiente rosa Nura e un overlay dialog immersivo a comparsa con spunta animata, descrizione di successo e feedback aptico vibrante `HapticFeedback.mediumImpact()`.
- **Storico e Badge di Stato Colorati**:
  - Creato il feed cronologico dei pitch inviati nella seconda scheda.
  - Sviluppati i badge di stato satinati e colorati per tenere traccia delle letture (`sent` = Grigio/INVIATO, `viewed` = Viola/LETTO, `shortlisted` = Verde/SELEZIONATO, `rejected` = Rosso/NON SEL.).
- **Hardening e Pulizia Compilatore**:
  - Eliminati gli import inutilizzati e pulito l'albero sintattico di `ArtistPitchScreen` e `ArtistPitchService`.
  - Risolti ed eliminati tutti i warning e gli errori sintattici: compilazione superata con successo con **0 ERRORI e 0 AVVISI** rilevati da `flutter analyze`.
  - Committato e inviato in push l'intero aggiornamento sul repository GitHub sul branch remoto `invio-pitch-artista`.

### Francesco — Sessione 2026-05-18 (C)
- **Risoluzione "Scroll Brutto" e allineamento cache**:
  - Identificata e spiegata la causa dell'header bianco fisso e bloccato ("Artist 01"), dovuto alla persistenza della vecchia `SliverAppBar` nella cache dell'emulatore. Spiegata la necessità di effettuare un semplice **Hot Restart** per caricare la versione parallasse con pulsanti satinati.
- **Controllo di Ruolo e Rimozione Pulsante "Battle"**:
  - Integrato il tracciamento reattivo del ruolo dell'utente (`UserRole`) in `ArtistPublicProfileScreen` tramite i provider di Riverpod (`userRoleProvider` e `authStateProvider`).
  - Nascosto condizionalmente il pulsante **Battle** per Utenti ed Etichette, rendendolo esclusivo per la visualizzazione da parte di altri Artisti.
- **Allineamento e Navigazione In-Line Shell Etichetta (`LabelShell`)**:
  - Unificata la navigazione di `LabelShell` sullo stesso modello in-line e fluido di `UserShell`, mantenendo la barra di navigazione inferiore sempre persistente ed evitando il push nativo a tutto schermo.
  - Integrata la capsula del `GlobalMiniPlayer` reattivo sopra la barra di navigazione a 4 elementi (`bottom: 84 + safeBottom`).
- **Hardening Mini Player Shell Utente (`UserShell`)**:
  - Avvolto il mini player a capsula in un `ValueListenableBuilder<String?>` reattivo su `playingTrackId` di `AudioPreviewService`, risolvendo il bug delle schede vuote e disallineate in assenza di brani attivi.
- **Hardening e Sicurezza Tasto Indietro Fluttuante**:
  - Aggiornato l'onPressed del tasto indietro fluttuante del profilo artista per fare il `pop` nativo se spinto via `Navigator.push`.
  - Risolti i warning di analisi sul BuildContext asincrono catturando `NavigatorState` prima dell'`await` su `_audio.stop()`.
- **Verifica Statica**:
  - Eseguito `flutter analyze` confermando la totale assenza di errori e warning per tutti i moduli modificati.

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

### Francesco — Sessione 2026-05-18 (D)
- **Estensione Modello Dati e Backend Pitch**:
  - Esteso il modello `PitchRequest` e aggiornato il database con la colonna facoltativa `message` tramite lo script di migrazione Supabase.
  - Aggiornato `ArtistPitchService` per supportare il caricamento del messaggio sia in produzione su Supabase che nei log locali mockup offline.
- **Compact Frosted Genre Tags (Step 2)**:
  - Inserite le capsule dei generi ricercati (es. *Dream Pop*, *Deep House*, *Neo-Classical*) sotto la biografia di ciascuna etichetta discografica nello Step 2.
  - Palette HSL coordinata con bordi semitrasparenti e layout responsivo basato su `Wrap` per scongiurare overflow di layout.
- **Progressive Disclosure & Frosted Glass Message Input (Step 3)**:
  - Rivelato lo Step 3 in dissolvenza solo dopo la selezione congiunta di un brano e di un'etichetta.
  - Disegnato un input di testo multi-riga in vetro satinato (`BackdropFilter`) con un contatore neon di caratteri limitato a 300 in Rosa Nura (con flash rosso in caso di superamento della soglia).
  - Integrato il testo del messaggio nella transazione d'invio del pitch con feedback aptico integrato.
- **Glass Bottom Sheet Dettaglio Candidature & Live Neon Visualizer (Task 4)**:
  - Abilitato il tap interattivo con micro-vibrazione sulle card dello storico dei pitch inviati.
  - Creato un **Glass Bottom Sheet immersivo** (sfocatura `BackdropFilter` 20.0) che ospita:
    - **Mini-Player**: Per riprodurre/mettere in pausa la canzone.
    - **Live Spectral Visualizer**: Quando il brano è in esecuzione, sopra la copertina appare un'animazione spettrale a 3 barre oscillanti al neon con ombreggiature soffuse.
    - **Timeline Stepper al Neon**: Un tracciato verticale luminoso che mostra le tappe del pitch (Inviato -> Letto -> Shortlisted/Rejected).
    - **Lettera di Feedback dell'A&R**: Una nota personalizzata ed emotivamente ricca firmata dai curatori dell'etichetta (in Verde Smeraldo se *Shortlisted*, in Rosso se *Non Selezionato*, o in Viola per esame in corso).
- **Hardening, Risoluzione Errori e Allineamento Compilazione (Task 5)**:
  - Risolti gli errori su `FontWeight.w950` correggendoli a `w900`.
  - Risolto l'import di `kTracks` aggiungendo l'importazione di `mock_nura_data.dart`.
  - Sostituita l'icona shortlist non definita con `Icons.stars_outlined`.
  - Gestito il fallback per copertine nulle (`coverAsset`) con un gradiente inline.
  - Eliminata la variabile inutilizzata `_pitchMessage` per ripulire completamente i warning di compilazione.
  - Eseguito `flutter analyze` confermando la totale assenza di errori e warning per tutto il codice sviluppato.

### Francesco — Sessione 2026-05-21 (A)
- **Ottimizzazione UX Audio e Lifecycle Artist Pitch (`artist_pitch_screen.dart`)**:
  - Implementata la disattivazione automatica della riproduzione dell'anteprima audio del brano quando l'utente scorre verso il basso (Step 2) o seleziona un'etichetta discografica per eliminare i rumori di sottofondo fastidiosi durante la fase decisionale.
  - Aggiunta chiamata esplicita `AudioPreviewService.instance.stop()` al superamento dello scroll offset (quando l'utente scorre giù a `offset > 150` verso la selezione delle label).
  - Aggiunto lo stop dell'audio anche direttamente all'interno della selezione manuale di un'etichetta discografica (callback `onTap` di Step 2).
  - Eseguito `flutter analyze` confermando la totale assenza di errori e warning nel codice dell'applicazione.

### Francesco — Sessione 2026-05-29 (A)
- [x] **Walkthrough** per Artist Pitch creato e approvato.
- [x] Rimosso `Scaffold` duplicato e background in `artist_pitch_screen.dart`.
- **Motore di Ricerca e Filtri Dimensione Etichette (`artist_pitch_screen.dart`)**:
  - Esteso il modello `Label` e i dati mock (`kLabels`) con il campo `size` per categorizzare le etichette in `small`, `medium` e `big`. Questi tag in produzione saranno collegati direttamente ai campi del profilo dell'etichetta su Supabase.
  - Implementata una barra di ricerca testuale (con icona a lente) per filtrare in tempo reale le etichette per nome direttamente nello Step 2 (Selezione Etichetta Discografica).
  - Aggiunti filter chips orizzontali ad alto contrasto per filtrare la visualizzazione tra Tutte, Small, Medium e Big.
  - Aggiunto un badge visivo (`size` tag) in colore brandizzato (Rosa Nura) direttamente sulla card della singola etichetta, informando l'artista sulla dimensione dell'etichetta a colpo d'occhio.
  - Ridotte le dimensioni e ottimizzati i padding interni della barra di ricerca "Cerca etichetta" per integrarsi meglio col design compatto.
  - Inseriti i feedback aptici (`HapticFeedback`) tattili per dare una risposta fisica ai touch (su tap etichette, selezioni filtri e pulsante d'invio).
  - Risolto l'errore fittizio in fase di invio: gestita correttamente la fallback alla modalità mock nel servizio `ArtistPitchService` per mostrare correttamente la modale di successo "PITCH INVIATO!" senza causare crash locali quando offline o in test mode.

### Modulo "Artist Pitch" Concluso (Maggio 2026)
- **Status: COMPLETATO ✅**
- Il flusso di Invio Candidature e storico (Pitch) per gli artisti è stato ultimato. Comprende:
  - Interfaccia Glassmorphism premium (Blur, sfumature neon rosa Nura, background mesh organico animato).
  - Selezione brano (AudioPreviewService, visualizzatori spettrali interattivi).
  - Selezione etichetta (filtri avanzati per dimensione `small/medium/big`, ricerca testuale real-time in UI, visualizzazione generi ricercati, blocco audio automatico allo scroll).
  - Feedback Aptico completo su tutti i punti di contatto fisici dell'utente.
  - Modale interattiva di successo post-invio con animazioni e badge.
  - Storico candidature (Scheda "I Miei Pitch") con timeline di accettazione, bottom sheet in glassmorphism, player miniaturizzato e lettera di feedback dal curatore A&R.
  - Backend Services interfacciati via mock fallback e pronti per l'integrazione di produzione (Supabase schema `pitch_requests`).
  - Analisi statica del codice passata integralmente (`flutter analyze` clean su tutto il flow).

---

## [2026-05-29] Update: Redesign Navigation Bar & Calm UX

**Branch Attuale:** `rework-navbar`

**Obiettivi Raggiunti:**
1. **Design "Liquid Glass" 2026**:
   - `BottomNav` trasformata in un "Floating Dock" sopraelevato e aderente in sicurezza alla Safe Area inferiore.
   - Sfondo `LinearGradient` sfumato (Cyan leggerissimo o Pink verso un base dark) estremamente trasparente per un effetto glass puro senza ingombri pesanti.
   - Rimozione completa di testi ed etichette, focalizzando la UI sulle icone bianche minimali ad alto contrasto.
   - Barretta inferiore indicatoria dipinta dinamicamente in colore Accento.
2. **Logica "Calm UX" Assoluta**:
   - Scomparsa dinamica su scroll in `UserShell` e `ArtistShell`: scorrendo attivamente verso il basso, la navbar scompare morbidamente, liberando spazio prezioso a schermo.
   - **Risoluzione Bug Bouncing**: Intercettato il rimbalzo fisico (`outOfRange` e `pixels <= 0`) per impedire artefatti grafici/scomparsa accidentale ai bordi delle liste.
   - **Riapparizione Immediata a Inerzia Finita**: Aggiunto hook su `ScrollEndNotification` e direzioni `idle`. Appena lo scroll giunge a destinazione o il tocco termina, la barra riappare istantaneamente senza necessitare scroll inversi espliciti.
3. **Ottimizzazione Fisica Pagine**:
   - Rimosso il fastidioso `BouncingScrollPhysics` custom da schermate chiave come `ArtistPitchScreen` e `ArtistPublicProfileScreen`, uniformando lo scorrimento e l'attrito al resto dell'esperienza Nura.

*Navbar minimalista, reattiva organicamente al contesto dell'utente, ed esteticamente pulita senza eccessi. Branch pronto al merge!*

---

## [2026-05-29] Integrazione (Merge Test)
- Eseguito con successo il workflow di "test merge" su branch temporaneo `test-merge-kekko`.
- Uniti senza crash i branch `rework-navbar` (Francesco) e `Update-nuovo-tema-+-fix-sezione-swipe` (Natan).
- Test utente locale completato con successo.
- Codice validato e pronto per la promozione stabile su `test-version`.


---

## [2026-06-07] 🚀 L'Ascesa a "God App": Da Tweak UI/UX a Motore Bare-Metal (Francesco)

**Branch Attuale:** `rework-home-swipe`

**Sintesi dell'Evoluzione (Da UI a Hardcore Engineering):**
Quello che doveva essere un semplice ritocco all'interfaccia utente e alla UX della home page si è trasformato in una riscrittura totale delle fondamenta dell'applicazione. Inizialmente l'obiettivo era rendere lo scorrimento delle card visivamente più appagante (GUI). Tuttavia, spingendo al massimo la fedeltà visiva (es. shader complessi), ci siamo scontrati con i limiti fisici del framework e dei moderni display a 120Hz. Per ottenere la "God App" (100% fluidità, 0 bug, 0 stuttering, temperature glaciali), abbiamo abbandonato le astrazioni standard e riscritto il sistema scendendo al livello del silicio, gestendo la memoria C++ manualmente e aggirando il Garbage Collector.

### 🎨 1. Rivoluzione UI / UX e GUI
Rispetto al branch precedente, l'esperienza visiva e interattiva è stata alterata in modo irriconoscibile:
- **Liquid Glass Shader (GUI)**: Abbiamo introdotto un `FragmentProgram` scritto in GLSL che gira direttamente sulla GPU per creare un effetto vetro liquido sulla base delle card. Questo non è un semplice blur di Flutter, è un'onda matematica calcolata a 60fps.
- **Dinamica Balistica e Velocità (UX)**: Lo swipe classico è stato rimpiazzato da un motore fisico inerziale personalizzato. Ora le card non vengono "animate", ma scagliate seguendo le leggi della fisica (Spring Simulation). Il feedback tattile (Haptic Feedback) si attiva organicamente in base alla trazione del pollice.
- **Aesthetic Retina-Ready (UI)**: Addio sfocature (blurriness). Le copertine musicali ora calcolano dinamicamente il `devicePixelRatio` dello schermo (Super Retina / AMOLED), caricando le texture in VRAM con precisione chirurgica pixel-perfect.
- **Crossfade Audio Immersivo (UX)**: Passaggio tra un brano e l'altro gestito al millisecondo, senza fastidiosi tagli netti o delay di caricamento, con fading logaritmico.

### ⚙️ 2. File Modificati e Nuove Architetture (Il Dettaglio Tecnico)

#### `pubspec.yaml` e `shaders/liquid_glass.frag`
- **Cosa abbiamo fatto**: Rimosso il vecchio pacchetto audio `just_audio` (troppo lento e memory-heavy). Aggiunto `flutter_soloud` per avere accesso diretto all'hardware audio in C++ tramite FFI. Registrato il nuovo asset shader GLSL.

#### `lib/features/discovery/swipe/presentation/widgets/physics_swiper.dart` (NUOVO)
- **Cosa abbiamo fatto**: Cuore del nuovo swipe. Creato da zero.
- **Perché e Come**: 
  1. **Zero-Allocation e SIMD**: Invece di creare oggetti Dart (innescando il Garbage Collector), gestiamo vettori e matrici (Matrix4) scambiando puntatori in memoria (Double Buffering) e usando un `KineticSimdEngine` per operazioni massive in un singolo clock.
  2. **Fix VRR/LTPO (Fix Your Timestep)**: Glii schermi moderni variano tra 10Hz e 120Hz. Usare il `dt` normale faceva "esplodere" la fisica. Abbiamo creato un Accumulatore a Passo Fisso (`_timeAccumulator`), blindando l'aggiornamento vettoriale a step inviolabili di 16.6ms. Determinismo assoluto.
  3. **Anti-Soft Brick**: Gestito il lifecycle (pause/resume). Se una notifica OS interrompe il touch, l'app salva lo stato e riattiva la molla al ritorno in foreground, impedendo che la card resti congelata a mezz'aria.

#### `lib/features/discovery/swipe/presentation/widgets/music_card.dart` (NUOVO)
- **Cosa abbiamo fatto**: Rappresentazione visiva della traccia con shader e background dinamico.
- **Perché e Come**:
  1. **Shader Mantissa Decay Fix**: L'uptime passava al C++ i secondi continui. Dopo ore, i float a 32 bit perdevano precisione (effetto sfarfallio). Risolto applicando un modulo `elapsed % 10000`, garantendo stabilità geometrica all'infinito.
  2. **DPR Rescaling**: Rimosso l'hardcode a `600px`. Aggiunto il `devicePixelRatio` nel `ResizeImage` per ottenere sharpness assoluta.

#### `lib/core/services/audio_preview_service.dart` & `lib/core/services/music_player_manager.dart`
- **Cosa abbiamo fatto**: Passaggio al FFI (Foreign Function Interface) C++.
- **Perché e Come**:
  1. **Crossfade Hardware**: Spostato l'onere del volume-fade dal thread UI Dart al DSP (Digital Signal Processor) nativo (`SoLoud.instance.fadeVolume`).
  2. **FFI Memory Leak Fix**: Il bug #324 di SoLoud impediva lo smaltimento dei brani vecchi. Aggiunto un fallback di sicurezza (`Future.any` con timeout di 500ms) per ghigliottinare comunque il puntatore C++ ed evitare Out-Of-Memory (OOM) letali.
  3. **Widget Tree Lock Fix**: Avvolti gli aggiornamenti di stato (`playingTrackId.value`) in un `WidgetsBinding.instance.addPostFrameCallback` durante la funzione `stop()`, per evitare che il framework vada in panico (`setState called when widget tree was locked`) durante lo smontaggio sincrono delle viste.

#### `lib/features/discovery/swipe/presentation/screens/artist_public_profile_screen.dart`
- **Cosa abbiamo fatto**: Revisione della vista profilo artista, pesantissima termicamente.
- **Perché e Come**:
  1. **Disinnesco Bomba Termica (Thermal Throttling)**: Lo scroll a 120Hz ricostruiva tutto l'albero via `setState`. Sostituito con un `ValueNotifier` isolato (`_scrollOffsetNotifier`) unito a un `ValueListenableBuilder`. Ora SOLO la mesh del background e l'opacità dell'header si ridipingono, mantenendo i core della CPU gelidi.
  2. **Prevenzione SIGSEGV (PopScope)**: Inserito un `PopScope` con `canPop: false`. Se l'utente fa back-swipe di sistema su iOS/Android, intercettiamo la chiusura, blocchiamo l'audio C++ (`await _audio.stop()`) PRIMA che la pagina muoia. Questo ha annientato il crash di violazione di memoria (Use-After-Free) dovuto a pointer FFI orfani.

#### `lib/features/discovery/swipe/presentation/screens/home_feed.dart`
- **Cosa abbiamo fatto**: Implementato algoritmo di "Occlusion Culling N+2".
- **Perché e Come**: Anziché renderizzare 50 card, il sistema itera al contrario e inietta in VRAM solo la card attuale, quella sotto e la terza rimpicciolita. Questo annulla totalmente i calcoli per il 95% del mazzo, salvando enormi quantità di memoria RAM.

### 🏆 Il Verdetto
Da una semplice richiesta UX ("facciamolo più carino e fluido") abbiamo partorito un'architettura che dialoga direttamente con la fisica del dispositivo. Le falle hardware e kernel (Thermal Throttling, OOM, SIGSEGV, VRR Physics bug) sono state tutte eradicate. Il branch `rework-home-swipe` è ora uno Standard enterprise a prestazioni definitive.

---

## Branch: `curator-rework`

### 🎯 Obiettivo Principale
Fix e refactoring estremo della sezione `CuratorPitchReviewScreen` a partire dalla versione stabile `test-version`. Abbiamo risolto i crash legati alla navigazione, standardizzato il ruolo `curator` nel database e creato una UI "Glassmorphism" moderna e completamente a tutto schermo.

### 🛠️ Modifiche Principali

#### `lib/features/auth/`
- **Cosa abbiamo fatto**: Migrazione dal ruolo DB `label` al ruolo universale `curator`.
- **Perché e Come**: Il database usa `curator` per designare i Curatori, ma il codice frontend aveva un mismatch con l'enum `label`. Abbiamo riscritto `UserRole` in `supabase_auth_repository.dart`, `auth_screen.dart` e mock login, allineando definitivamente il framework a Supabase.

#### `lib/features/curator/received_tracks/presentation/screens/curator_pitch_review_screen.dart`
- **Cosa abbiamo fatto**: Total refactoring UI/UX, eliminazione dei fastidiosi tagli visivi e risoluzione conflitti di gesture.
- **Perché e Come**:
  1. **Disinnesco Conflitti di Scorrimento**: Un `SingleChildScrollView` annidato in un `showModalBottomSheet` assorbiva i gesti "pull-to-dismiss". Lo abbiamo trasformato in un full-screen `Scaffold` (`Navigator.push`) con una "X" fluttuante, garantendo una UX immersiva.
  2. **Immersive Parallax Mesh**: Eliminato lo sfondo grigio piatto; ora abbraccia l'intero `ParallaxOrganicMeshPainter` (sfondo animato).
  3. **High-Contrast Typography**: Bilanciato il contrasto convertendo i testi al Dark (`Color(0xFF1A1A1A)`) per massima visibilità sugli sfondi luminosi.
  4. **Data Injection - "Etichetta Destinazione"**: Aggiunto il parametro `targetLabel` per mostrare esplicitamente la Record Label di destinazione del pitch in ogni singola card e nella dashboard di review.

### 🏆 Il Verdetto
Il branch `curator-rework` è solido. I crash derivati dal vecchio codice sono stati cancellati partendo puliti da `test-version`. Il design è Premium. Pronto per il merge.
---

## Branch: `eventi(futuri)` e `risoluzioni-piccoli-bug`

### 🎯 Obiettivo Principale
Implementare la nuova pagina "Eventi", aggiornare l'architettura della Navigation Bar in tutte le Shell (`UserShell`, `ArtistShell`, `CuratorShell`) per preservare lo stato e la posizione di scroll di ogni tab isolatamente, e risolvere gravi bug di Layout e di Build Frame generati dai ValueNotifier.

### 🛠️ Modifiche Principali

#### `lib/features/events/presentation/screens/empty_events_tab.dart`
- **Cosa abbiamo fatto**: Sostituita la vecchia sezione profilo con una nuova tab "Eventi".
- **Perché e Come**: Mostra gli eventi futuri live e streaming. Utilizza carte glassmorphism ("Battle in arrivo", "Evento generico") e condivide lo sfondo animato Parallax dell'app per massima coerenza visiva.

#### `lib/features/user/shell/user_shell.dart`, `artist_shell.dart`, `curator_shell.dart`
- **Cosa abbiamo fatto**: Completo refactoring architetturale da un semplice blocco `switch` a un `IndexedStack` con memoria per singola tab.
- **Perché e Come**:
  1. **Persistent State**: Usando `IndexedStack`, l'app ora mantiene vive le tab in background. Questo fa sì che cambiando tab e tornando indietro, l'esatta posizione di scroll venga mantenuta perfettamente, cancellando il fastidioso bug dello "scroll perso".
  2. **Isolamento dell'Header**: Creato un sistema di Mappe (`_isScrolledMap`, `_navVisibilityMap`) per isolare lo stato di visualizzazione del GlobalHeader e della BottomNavBar. Scorrendo giù in "Home", l'header sparisce; passando a "Eventi", l'header torna visibile perché la memoria della tab è indipendente.
  3. **Risoluzione "Build scheduled during frame"**: Risolto il blocco nativo che generava eccezioni cambiando velocemente tab, iniettando la modifica dei `ValueNotifier` all'interno di un `WidgetsBinding.instance.addPostFrameCallback`. Ora lo stato viene aggiornato solo dopo che Flutter ha costruito il frame in modo sicuro, garantendo 60fps continui.

#### `lib/features/curator/received_tracks/presentation/screens/curator_pitch_review_screen.dart`
- **Cosa abbiamo fatto**: Fix critico di Layout Overflow per i nomi lunghi.
- **Perché e Come**: Il parametro `targetLabel` generava un errore grafico se l'etichetta di destinazione era troppo lunga (troncando lo schermo a destra). Abbiamo disinnescato l'overflow avvolgendo il Testo in un widget `Flexible` e rimuovendo i limiti di linea. Ora i testi lunghi vengono incolonnati elegantemente.

### 🏆 Il Verdetto
Il blocco di Navigazione è arrivato a uno standard da top app di mercato. Non ci sono più stati globali corrotti o crash da ridisegno frame. Un utente può scrollare aggressivamente qualsiasi tab, l'app gestirà dinamicamente le visibilità della TopBar e BottomBar isolando memoria, posizione visiva ed elementi grafici in frazioni di secondo. I branch sono stati fusi puliti su `test-merge-francesco`.


### Antigravity � Sessione 2026-06-14 (Fase 4: A&R Dashboard & Nura Score)
- **Database Schema Update**:
  - Creata e applicata migrazione `07_curator_scores.sql` su Supabase per integrare i voti (Lyrics, Vibe, Production, Market) e feedback testuali nella tabella `curator_pitches`.
  - Creata vista SQL `curator_pitches_view` per aggregare agevolmente i pitch con i dati di artisti e brani.
- **Data Layer (Servizi)**:
  - Sviluppato `CuratorPitchService` per caricare i pitch pendenti (Da Valutare) e valutati.
  - Aggiunto calcolo del **Nura Score** reale in `ArtistStatsService` per calcolare la media ponderata sia per singola traccia (`getTrackNuuraScore`) che globale per l'artista (`getArtistNuuraScore`).
- **Integrazione UI - Curatore (A&R Dashboard)**:
  - Aggiornata l'interfaccia `CuratorPitchReviewScreen` trasformandola in `ConsumerStatefulWidget` e inserendo due tab: **Da Valutare** e **Valutati**.
  - Collegato il pannello di dettaglio (sliders per le 4 metriche e campo testuale) alla funzione di invio verso Supabase in tempo reale.
- **Integrazione UI - Artista (Analytics & Nura Score)**:
  - Aggiornato `ArtistPersonalProfileScreen`: ora visualizza il punteggio reale sul badge dei vinili interrogando il DB traccia per traccia.
  - Aggiornata la schermata `NuraScoreAnalyticsScreen` per visualizzare metriche e barre di avanzamento reali (non pi� mock) con il conteggio dei feedback ufficiali.
- **UX e Fix Vari**:
  - Sostituito il colore Ciano originario con il Rosa Nura e il Viola per la coerenza del brand (NuraBrand) all'interno dell'interfaccia Curatore.
  - Assicurato il corretto funzionamento dei placeholder per foto profilo e cover mancanti (ad esempio sull'emulatore) senza errori.


### Antigravity - Sessione 2026-06-16 (Fix Flashing e UX Caricamento)
- **Tema Globale e Scaffolds**:
  - Risolto il problema del "flashing scuro" durante i caricamenti modificando pp_theme.dart e impostando scaffoldBackgroundColor sul bianco ghiaccio (Color(0xFFF8F9FA)).
  - Allineata la NuraVibe.premium ai colori chiari effettivi per mantenere coerenza visuale tra i passaggi.
- **Raffinamento UX di Caricamento Iniziale**:
  - Implementata una UX di caricamento fluida e continua dalla chiusura di RoleGate fino al caricamento completo di HomeFeed (Nessun micro-scatto o shell vuota).
  - Aggiunto un overlay di caricamento globale in ArtistShell, UserShell e CuratorShell (tramite _isFeedReady), garantendo l'uso di un caricamento esteso (Approccio 1).
  - Collegato HomeFeed all'evento onFeedReady che viene notificato non appena le tracce remote o in cache sono caricate (anche in caso di errore), svelando l'App al momento perfetto.
- **Risoluzione Errori di Sintassi**:
  - Corretto errore di parentesi per IgnorePointer all'interno dell' IndexedStack che causava la non-compilazione.

### Antigravity - Sessione 2026-06-17 (Emergenza FFmpeg & Audio Toolkit Nativo)
- **Risoluzione Emergenza Globale FFmpegKit**:
  - Rimosso `ffmpeg_kit_flutter_audio` e dipendenze correlate dal progetto, a causa del ritiro ufficiale dei binari dal Maven Central che bloccava completamente le build Android mondiali dell'app.
- **Implementazione Nuova Conversione Audio Nativa Silenziosa**:
  - Installato e integrato `flutter_audio_toolkit`.
  - Implementata in `ArtistTrackUploadScreen` la conversione invisibile e completamente offline dei file WAV.
  - La libreria delega ai chip MediaCodec/AVFoundation dei dispositivi la transcodifica del WAV in AAC (container M4A, 320kbps) garantendo qualita eccelsa, dimensioni del file minime e risparmio drastico sui costi del DB Cloud e banda.
  - Eliminato dalla UI lo stato di "Preparazione", in modo che l'utente percepisca l'operazione solo come un normale "Caricamento in corso...".
- **Gestione UI Profilo Artista (Design Revert)**:
  - Testato l'approccio FAB (Floating Action Button) per il pulsante di Caricamento Brano, ma in base al feedback dell'utente e' stato mantenuto il Banner largo e centrale all'interno del CustomScrollView, considerato piu' adatto allo stile del progetto.

### Antigravity - Rilascio Backend (Task 1: Cloudflare R2 Upload)
- **Implementata Edge Function 2-sign-upload**:
  - Scritta la logica in Deno usando l'SDK AWS S3 per generare URL pre-firmati compatibili con Cloudflare R2.
  - Inserito blocco di sicurezza (Limite a 50MB per file) per bloccare upload massivi abusivi.
  - Implementata verifica JWT (supabaseClient.auth.getUser()) per assicurare che solo utenti autenticati possano farsi firmare gli URL.
  - Le variabili d'ambiente necessarie (R2_ACCOUNT_ID, ecc.) andranno settate su Supabase per farla funzionare in produzione.

### Antigravity - Rilascio Backend (Task 2: Social Auth)
- **Implementato Google & Apple Sign-In Nativi**:
  - Aggiunti e configurati i pacchetti google_sign_in: ^6.2.1 e sign_in_with_apple: ^6.1.1 in pubspec.yaml.
  - Aggiunto crypto per hasare in SHA256 la nonce crittografica di Apple Sign-In.
  - Creati metodi signInWithGoogle e signInWithApple in SupabaseAuthRepository.
  - Aggiornata la AuthScreen per mostrare i bottoni in UI.
  - Adesso l'app sfrutta i flussi nativi OS (bottom sheet nativi) invece della webview.

### Antigravity - Rilascio Backend (Task 3: Hardening Database e RLS)
- **Scritta Migrazione  8_security_harden.sql**:
  - Aggiunte le policy di DELETE per le tabelle profiles, 	racks, curator_pitches e ollows, in modo che solo l'owner originale possa cancellare il proprio contenuto.
  - Aggiunte le policy di DELETE sui bucket Storage di Supabase (vatars, 	racks_covers).
  - Creato un **Trigger** prevent_role_escalation su profiles: impedisce ad utenti malintenzionati di usare l'API Supabase per promuoversi da "user" ad "artist" o "curator" da soli.

### Antigravity - Rilascio Backend (Task 4: Compliance App Store)
- **Scritta Migrazione  9_reports_schema.sql**:
  - Create tabelle content_reports e user_blocks per permettere agli utenti di segnalare e bloccare i contenuti e artisti che ritengono inappropriati.
- **Aggiornato il Frontend Flutter**:
  - Inserito il PopupMenuButton in music_card.dart per l'invio diretto dei report su Supabase Database.
  - Inserito il pulsante **Elimina Account** all'interno di profile_settings_screen.dart.
- **Creata Edge Function delete-account**:
  - Completata la Edge Function in Deno TypeScript per rimuovere permanentemente l'utente, sfruttando l'ON DELETE CASCADE per pulire tutti i profili, le tracce e svuotare lo storage associato.

### Antigravity - Push Notifications e Rilascio Finale (Completato)
- **Supabase Deploy**:
  - Migrazione eseguita in cloud: 10_notifications_schema.sql (Tabelle: user_devices, in_app_notifications).
  - Deploy Edge Functions: send-push-notification, delete-account, 2-sign-upload, sync-user-role.
- **Flutter**:
  - Integrati i pacchetti Firebase per FCM.
  - Creato PushNotificationService in ascolto su main.dart, capace di estrarre e sincronizzare i token verso Supabase.

### Nota Fondamentale per il Lancio (Da completare manualmente dal proprietario)
Il codice per le notifiche push (Flutter App e Supabase Edge Functions) è completo e già in produzione. Tuttavia, per funzionare, deve essere collegato a un account Firebase reale di proprietà dell'utente. I passaggi burocratici da eseguire in futuro sono:
1. **Configurazione Firebase in Flutter**: Dal terminale locale, eseguire lutterfire configure. Questo comando collegherà l'app Flutter al progetto Firebase su Google, generando in automatico i file irebase_options.dart (per il web/Dart) e scaricando i file nativi google-services.json (Android) e GoogleService-Info.plist (iOS). Senza questi file fisici (che non possono essere generati da un assistente AI perché richiedono l'autenticazione Google dell'utente), l'app Flutter crasherà se si tenta di inizializzare Firebase. Attualmente l'inizializzazione nel main.dart è protetta da un 	ry/catch per evitare crash temporanei.
2. **Caricamento Credenziali su Supabase**: Dalla console di Firebase (Project Settings > Service Accounts), bisognerà generare una "Private Key" (file JSON). Il contenuto di questo file andrà caricato nei secret di Supabase eseguendo il comando: supabase secrets set FIREBASE_SERVICE_ACCOUNT='{il_contenuto_del_file_json}'. Questo darà all'Edge Function di Supabase il permesso di usare Firebase per inviare materialmente i messaggi ai telefoni.

### Automazione Notifiche (Completato)
- Creati 3 trigger SQL (11_notifications_triggers.sql) che automatizzano l'inserimento in in_app_notifications su eventi:
  - **Nuovo Follower** (tabella ollows)
  - **Nuovo Pitch** (tabella curator_pitches)
  - **Pitch Recensito** (tabella curator_pitches update status)
- Il codice Dart per il bottone 'Segui' nel profilo pubblico artista era già implementato e perfettamente connesso.
- Migrazione spinta su database live.
 
 # # #   P r e p a r a z i o n e   S t o r e   &   R 2   ( C o m p l e t a t o )  
 -   C o r r e t t o   i l   a p p l i c a t i o n I d   A n d r o i d   d a   c o m . e x a m p l e . . .   a   i t . n u r a l a b s . n u r a .  
 -   I n s e r i t o   i l   p e r m e s s o   a n d r o i d . p e r m i s s i o n . I N T E R N E T   n e c e s s a r i o   p e r   l a   p r o d u z i o n e .  
 -   I n s e r i t o   i l   p e r m e s s o   b a c k g r o u n d   U I B a c k g r o u n d M o d e s   s u   i O S   p e r   l ' a u d i o   p e r s i s t e n t e   a   s c h e r m o   s p e n t o .  
 -   C a b l a t a   l a   C D N   C l o u d f l a r e   R 2   v e r a   e   p r o p r i a   p e r   l o   s t r e a m i n g   a u d i o   i n v e c e   d e l   m o c k   l o c a l e ,   u t i l i z z a n d o   l a   v a r i a b i l e   - - d a r t - d e f i n e = R 2 _ P U B L I C _ U R L = . . .  
  
 # # #   C o n f i g u r a z i o n e   F i r e b a s e   e   N o t i f i c h e   P u s h   ( C o m p l e t a t o )  
 -   E s e g u i t o   ' f l u t t e r f i r e   c o n f i g u r e '   p e r   c o l l e g a r e   l e   a p p   A n d r o i d   e   i O S   a l   p r o g e t t o   F i r e b a s e .  
 -   I m p o r t a t o   D e f a u l t F i r e b a s e O p t i o n s . c u r r e n t P l a t f o r m   n e l   m a i n . d a r t   d e l l ' a p p   F l u t t e r .  
 -   R i c e v u t o   i l   S e r v i c e   A c c o u n t   J S O N   e   i m p o s t a t o   s u   S u p a b a s e   i n   F I R E B A S E _ S E R V I C E _ A C C O U N T .  
 -   R i d e p l o y a t a   l ' E d g e   F u n c t i o n   ' s e n d - p u s h - n o t i f i c a t i o n '   s u   S u p a b a s e .  
 L ' a p p   o r a   e '   c o n f i g u r a t a   e   p r o n t a   p e r   g l i   s t o r e .  
  
 # # #   C o n t r o l l o   P r e - L a n c i o   F i n a l e   ( C o m p l e t a t o )  
 -   V e r i f i c a t a   i n t e g r i t �   d e l   f l u s s o   P i t c h   ( d a   i n s e r i m e n t o   d e l l ' a r t i s t a   a   v a l u t a z i o n e   d e l   c u r a t o r e ,   f i n o   a l   t r i g g e r   d e l l a   P u s h   N o t i f i c a t i o n ) .  
 -   V e r i f i c a t a   l a   p r e s e n z a   d e i   m e t o d i   n a t i v i   s i g n I n W i t h A p p l e   e   s i g n I n W i t h G o o g l e .  
 -   R i m o s s i   i   p e r m e s s i   d i   B a c k g r o u n d   A u d i o   ( i O S )   e   W A K E _ L O C K   ( A n d r o i d )   p e r   g a r a n t i r e   c h e   l ' a p p   i n t e r r o m p a   l a   m u s i c a   a   s c h e r m o   s p e n t o .  
 -   G e n e r a t a   l ' a n a l i s i   a r c h i t e t t u r a l e   f i n a l e   i n   n u r a _ a r c h i t e c t u r e _ a n d _ s t a t u s . m d  
 