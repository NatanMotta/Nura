# Nura — Roadmap Prodotto (v2)

Ultimo aggiornamento: 2026-05-12
Branch lavoro corrente: `codex/implementazione-profilo-utente`
Owner attività in corso: `Natan`
Nota collaborazione: Francesco lavora in parallelo su stream separati con altra AI.

## Stato attuale sintetico
- Base app Flutter multi-ruolo stabile (`user`, `artist`, `label`).
- Auth Supabase reale attiva + fallback login mock.
- Discovery swipe e audio preview funzionanti.
- Pipeline upload iOS attiva con ASC CLI.
- Profilo in corso: versione `profilo generico` (step ponte verso profili dedicati per ruolo).

---

## Piano per Fasi (implementazione)

### Fase 1 — Stabilizzazione Core (in corso)
Obiettivo: consolidare basi tecniche e UX principale.
Owner fase corrente: `Natan`

Task:
- [x] Routing multi-ruolo + shell dedicate.
- [x] Auth Supabase + ruolo su profilo.
- [x] Discovery swipe + preview audio.
- [x] Pipeline build/upload TestFlight via script + ASC.
- [~] Profilo utente generico (base pronta, in raffinamento UX social).
- [ ] Riduzione peso IPA (ottimizzazione immagini/assets).

Exit criteria:
- Nessun blocker tecnico su login, swipe, audio, profile entrypoint.
- Build iOS ripetibile e upload consistente.

### Fase 2 — Social Foundation (prossima priorità)
Obiettivo: introdurre engagement persistente (like/comment/save/ranking).

Task:
- [x] Progettazione schema Supabase engagement.
- [x] Setup DB remoto MVP (`track_likes`, `track_saves`, `track_comments`) + RLS.
- [x] View ranking/metriche (`track_engagement_stats`, `community_artist_ranking`).
- [ ] Implementazione CRUD lato app per like/save/comment.
- [ ] Aggiornamento ranking community da dati reali.
- [ ] Moderazione base commenti (report/delete owner/admin).

Exit criteria:
- Like/comment/save persistenti e visibili cross-screen.
- Ranking non più mock, calcolato su dati DB.

### Fase 3 — Profili per Settore/Ruolo
Obiettivo: evolvere dal profilo generico ai profili specializzati.

Task:
- [~] Profilo generico (header + metriche + brani) come baseline condivisa.
- [ ] Profilo User (attività social, libreria, follow, cronologia interazioni).
- [ ] Profilo Artist (catalogo, metriche traccia, pitch status, audience signals).
- [ ] Profilo Label (shortlist, scouting board, KPI scouting, workflow review).
- [ ] Regole visibilità per ruolo (pubblico/privato e permessi azioni).

Exit criteria:
- 3 profili distinti e coerenti con use-case ruolo.

### Fase 4 — Workflow Business (Pitch end-to-end)
Obiettivo: completare ciclo artista <-> label con persistenza reale.
Owner fase corrente: `Francesco`

Task:
- [ ] Invio pitch reale con stato lifecycle.
- [ ] Ricezione/review pitch lato label.
- [ ] Azioni persistenti (shortlist/reject/accept) + storico.
- [ ] Notifiche di stato essenziali.

Exit criteria:
- Flusso pitch completo in produzione interna.

### Fase 5 — QA, Release, Hardening
Obiettivo: qualità release e performance su device reali.

Task:
- [ ] QA matrix iOS/Android su dispositivi target.
- [ ] Pass performance finale (swipe/audio/profili/list rendering).
- [ ] Compliance metadata/privacy App Store.
- [ ] Checklist release v1 tester interni.

Exit criteria:
- Build distribuita a tester con bug critici sotto soglia.

---

## Piano per Settori (workstream verticali)

### Settore A — App UX/UI
- Shell ruolo, navigazione, schermate core.
- Profili (generico -> specifici per ruolo).
- Search/discovery secondaria.

### Settore B — Social & Engagement
- Like, Save, Commenti, Ranking community.
- Feed attività e segnali social.

### Settore C — Audio & Media
- Preview engine, resilienza playback.
- Media pipeline (asset locali/cloud, ottimizzazione peso).

### Settore D — Backend Supabase
- Schema DB, RLS, API usage patterns.
- Eventuale edge functions per logica aggregata.

### Settore E — Business Workflow
- Pitch lifecycle artist/label.
- Stato review, shortlist e decision trail.

### Settore F — Release & Operations
- Build, signing, upload ASC.
- QA process, issue triage, release notes.

---

## Audit attuale: Commenti/Like (App + Supabase)

Stato rilevato oggi:
- App: presenti contatori/mock locali (es. swipe like UI, metriche profilo simulate), CRUD non ancora collegato.
- Supabase remoto: tabelle social MVP presenti e migrate (`track_likes`, `track_saves`, `track_comments`) con policy RLS attive.
- Supabase remoto: view aggregate/ranking presenti (`track_engagement_stats`, `community_artist_ranking`).
- Conclusione: backend social MVP **attivo**, integrazione app ancora da completare.

### Preventivo implementazione Social Foundation

Pacchetto 1 — MVP Engagement (consigliato subito)
- Scope:
  - Tabelle: `track_likes`, `track_saves`, `track_comments`.
  - RLS base (owner insert/delete, read pubblico, moderazione minima).
  - API app: toggle like/save, lista commenti, crea commento.
  - UI: binding reale su profilo e feed.
- Stima: 3-5 giorni uomo.

Pacchetto 2 — Ranking & Aggregazioni
- Scope:
  - View/materialized view per score community.
  - Aggiornamento ranking in profilo da dati reali.
- Stima: 1-2 giorni uomo.

Pacchetto 3 — Moderazione base
- Scope:
  - report commento, soft-delete, flag visibilità.
- Stima: 1-2 giorni uomo.

Totale consigliato residuo (integrazione app + ranking UI): 2-4 giorni uomo.

---

## Focus operativo corrente (questa sessione)
Owner corrente: `Natan`
1. Rifinitura profilo generico in stile social (in corso sul branch corrente di Natan).
2. Collegamento app a Supabase per like/save/comment (repository + provider + UI) da parte di Natan.
3. Binding ranking community nel profilo da `community_artist_ranking` da parte di Natan.
4. Poi: specializzazione profili per ruolo partendo dalla baseline generica (stream Natan).
