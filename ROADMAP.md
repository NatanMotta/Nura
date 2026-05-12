# Nura App — Session Recap

Ultimo aggiornamento: 2026-05-11

## Stato rapido
- Architettura Flutter (`app/core/features`) impostata e funzionante.
- Esperienze ruolo (`User`, `Artist`, `Label`) presenti con shell dedicate.
- Auth reale Supabase attiva + Login Mock operativo come fallback/test.
- Discovery swipe attiva con dati reali DB + fallback mock.
- Audio engine attivo con lifecycle background/foreground e hardening errori.
- Build/TestFlight pipeline impostata (script + checklist).

## File di tracking
- Stato operativo: `SESSION_RECAP.md` (questo file)
- Log cronologico completo: `SESSION_LOG.md`

---

## Legenda stato
- ✅ completato
- 🟡 parziale
- 🔴 da fare

---

## Roadmap strutturata (numerazione aggiornata)

### EPIC 01 — Setup, Architettura, Ruoli
Obiettivo: base tecnica stabile e routing multi-ruolo.

- ✅ Task 01.01 — Bootstrap progetto e struttura cartelle
- ✅ Task 01.02 — State management (Riverpod) + stato ruolo globale
- ✅ Task 01.03 — Routing base + shell separate per ruolo
- ✅ Task 01.04 — Bottom navigation dinamica per ruolo
- ✅ Task 01.05 — Tema globale base (palette, typography)

Definition of done EPIC 01:
- app avviabile con role-gating
- navigazione coerente per `user|artist|label`
- `flutter analyze` pulito

### EPIC 02 — Mock Data & Assets
Obiettivo: ambiente demo completo senza backend obbligatorio.

- ✅ Task 02.01 — Import media mock (`assets/audio`, `assets/images/artists`, `assets/images/labels`)
- ✅ Task 02.02 — Modelli dominio mock (`Artist`, `NormalUser`, `Label`, `PitchRequest`)
- ✅ Task 02.03 — Servizi/helper mock per discovery, lookup, profilo, pitch
- 🟡 Task 02.04 — Categorie search visuali (rinviata: immagini categories escluse per scelta)

Definition of done EPIC 02:
- app usabile in locale senza cloud
- preview audio e immagini mock collegate

### EPIC 03 — Cloud Foundation (Supabase + Cloudflare R2)
Obiettivo: passare da demo locale a prodotto testabile con dati reali.

- ✅ Task 03.01 — Setup Supabase project + bootstrap env Flutter
- ✅ Task 03.02 — Auth reale (signup/login/logout) + ruolo su profilo
- ✅ Task 03.03 — Schema DB iniziale (`profiles`, `tracks`, `labels`, `pitch_requests`)
- ✅ Task 03.04 — RLS base per isolamento accessi
- ✅ Task 03.05 — Seed dati reali test (artist/label/user + tracks)
- 🟡 Task 03.06 — Integrazione R2 signed upload/download end-to-end
- 🟡 Task 03.07 — Rimozione fallback mock nelle schermate core (swipe/search/profile/pitch)

Definition of done EPIC 03:
- login reale funzionante
- dataset remoto stabile
- policy RLS verificate
- file media gestiti via storage cloud

### EPIC 04 — Accesso & Login Mock
Obiettivo: accelerare QA prodotto senza bloccare l’auth reale.

- ✅ Task 04.01 — Schermata scelta ruolo mock
- ✅ Task 04.02 — RoleGate con priorità auth reale > mock
- ✅ Task 04.03 — Logout mock + logout account reale da impostazioni

Definition of done EPIC 04:
- ingresso rapido ai 3 ruoli disponibile
- nessuna regressione su auth reale

### EPIC 05 — Audio Engine (stabilità + UX)
Obiettivo: riproduzione affidabile, fluida e robusta.

- ✅ Task 05.01 — Integrazione `just_audio`
- ✅ Task 05.02 — Service unico globale (`play/pause/resume/seek/stop`)
- ✅ Task 05.03 — Loop preview + timer reale traccia
- ✅ Task 05.04 — Lifecycle app (`paused/resumed`) con comportamento coerente
- ✅ Task 05.05 — Hardening errori (`timeout`, catch uniforme, fallback UI snackbar)
- 🟡 Task 05.06 — Preload intelligente top/next track per riduzione lag percepito
- 🟡 Task 05.07 — Regole unificate su autoplay/stop cross-screen (swipe <-> profilo)

Definition of done EPIC 05:
- nessun blocco audio in background/foreground
- UX playback coerente in tutte le schermate
- handling errori prevedibile e non distruttivo

### EPIC 06 — Discovery Swipe (Core Experience)
Obiettivo: esperienza principale rapida, chiara e senza jank.

- ✅ Task 06.01 — Card swipe con metadata e CTA
- ✅ Task 06.02 — Autoplay preview card top
- ✅ Task 06.03 — Apertura profilo artista dal feed
- 🟡 Task 06.04 — Ottimizzazioni performance (render, drag, blur, waveform)
- 🟡 Task 06.05 — Regole prodotto finali (like/skip/save/scoring)

Definition of done EPIC 06:
- swipe fluido su device reale
- audio e card sempre sincronizzati

### EPIC 07 — Search & Discovery Secondaria
Obiettivo: ricerca artisti/categorie oltre allo swipe.

- 🟡 Task 07.01 — UI search base esistente
- 🔴 Task 07.02 — Categorie/mood grid completa
- 🔴 Task 07.03 — Ricerca artisti reale su DB
- 🔴 Task 07.04 — Deep link al profilo artista

Definition of done EPIC 07:
- ricerca utilizzabile in produzione
- navigazione profili coerente con feed

### EPIC 08 — Profili differenziati
Obiettivo: vetrine credibili per `artist`, `user`, `label`.

- 🟡 Task 08.01 — Profilo artista pubblico social-style (base presente)
- 🟡 Task 08.02 — Mini-player profilo artista (Spotify-like) con fix UX finali
- 🟡 Task 08.03 — Profilo user con contenuti reali (liked/attività)
- 🔴 Task 08.04 — Profilo label completo (branding + shortlist + monitoraggio)

Definition of done EPIC 08:
- 3 profili distinti, coerenti e completi lato UX + dati

### EPIC 09 — Pitch (Invio/Ricezione)
Obiettivo: abilitare il core business tra artisti ed etichette/curatori.

- 🟡 Task 09.01 — Tab Pitch artista pronta (UI)
- 🔴 Task 09.02 — Invio pitch reale (insert + stato richiesta)
- 🟡 Task 09.03 — Tab Pitch ricevuti etichetta pronta (UI)
- 🔴 Task 09.04 — Azioni etichetta reali (approva/scarta + persistenza)
- 🔴 Task 09.05 — Audit trail/stato visibile a entrambe le parti

Definition of done EPIC 09:
- ciclo pitch completo end-to-end da app

### EPIC 10 — Release, QA, Polishing
Obiettivo: qualità release e distribuzione controllata.

- 🟡 Task 10.01 — Pipeline build iOS/TestFlight (`scripts/testflight_build.sh`)
- 🟡 Task 10.02 — Compliance iOS metadata/privacy (Info.plist, icone, launch)
- 🔴 Task 10.03 — QA test matrix su device reali
- 🔴 Task 10.04 — Performance pass finale (swipe/audio/profili)
- 🔴 Task 10.05 — Release checklist v1.0 interna soci/tester

Definition of done EPIC 10:
- build distribuita ai tester senza blocker
- issue critiche tracciate e priorizzate

---

## Priorità operative (prossimi step consigliati)
1. EPIC 05 — Task 05.06 preload top/next track per ridurre ancora i lag nello swipe.
2. EPIC 03 — Task 03.06 completare R2 signed download e playback cloud end-to-end.
3. EPIC 09 — Task 09.02/09.04 attivare pitch reale con persistenza stato.
4. EPIC 10 — Task 10.03 avviare matrice QA device reale con checklist issue.
