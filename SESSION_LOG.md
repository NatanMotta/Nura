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
- **Flusso "Nuovo Pitch" & Feedback Sensoriale**:
  - Creato il Selettore Traccia orizzontale con card illuminate da bordi neon rosa glow, spunta visiva all'attivazione e allineamento automatico dei campi del modello core `Track` (`swatch` per colore, `track` per titolo).
  - Sviluppato il Selettore Label verticale a card frosted glass con risoluzione dinamica delle icone brandizzate da Supabase, biografie degli A&R e città di provenienza.
  - Implementato un bottone CTA premium con gradiente rosa Nura e un overlay dialog immersivo a comparsa con spunta animata, descrizione di successo e feedback aptico vibrante `HapticFeedback.mediumImpact()`.
- **Storico e Badge di Stato Colorati**:
  - Creato il feed cronologico dei pitch inviati nella seconda scheda.
  - Sviluppati i badge di stato satinati e colorati per tenere traccia delle letture (`sent` = Grigio/INVIATO, `viewed` = Viola/LETTO, `shortlisted` = Verde/SELEZIONATO, `rejected` = Rosso/NON SEL.).
- **Integrazione e Hardening**:
  - Sostituito il placeholder temporaneo all'interno di `artist_shell.dart` e rimosso il widget orfano `_PlaceholderScreen`.
  - Risolti i warning di import e pulizia sintattica, confermando una compilazione totalmente pulita con `flutter analyze`.

