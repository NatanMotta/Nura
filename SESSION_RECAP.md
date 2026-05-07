# Nura App — Session Recap

Ultimo aggiornamento: 2026-05-07

## Stato rapido
- Architettura base `app/core/features`: presente
- Shell per ruolo: presenti (`User`, `Artist`, `Label`)
- RoleGate: collegato a stato globale ruolo (Riverpod)
- Bottom navigation dinamica per ruolo: presente
- Struttura assets Task 2.1: creata e registrata
- `flutter analyze`: OK (no issues)

---

## Roadmap aggiornata (stato)

Legenda:
- ✅ completato
- 🟡 parziale
- 🔴 da fare

### EPIC 1 — Setup, Architettura & Gestione Ruoli
- ✅ Task 1.1 Configurazione progetto/struttura
- ✅ Task 1.2 State management (Riverpod + stato ruolo globale)
- ✅ Task 1.3 Routing + BottomNav dinamica per ruolo
- ✅ Task 1.4 Tema globale

### EPIC 2 — Dati Mockati & Assets
- 🟡 Task 2.1 Media assets: cartelle + `pubspec.yaml` completati, file reali ancora da inserire
- 🟡 Task 2.2 Modelli dati (alcuni presenti, mancano `Artist`, `NormalUser`, `Label`, `PitchRequest`)
- 🟡 Task 2.3 Servizio mock completo (base presente in `mock_nura_data.dart`, da estendere)

### EPIC 3 — Login Mock
- 🔴 Task 3.1 Schermata scelta ruolo + redirect shell

### EPIC 4 — Audio Engine
- 🔴 Task 4.1 Setup libreria audio
- 🔴 Task 4.2 Audio service globale

### EPIC 5 — Home Swipe Discovery
- 🟡 Task 5.1 UI card base presente, feedback swipe da rifinire
- 🔴 Task 5.2 Meccanica swipe + audio preview 15s

### EPIC 6 — Cerca
- 🟡 Task 6.1 Base presente, grid categorie/mood da completare

### EPIC 7 — Profili Differenziati
- 🔴 Task 7.1 Profilo Artista
- 🟡 Task 7.2 Profilo Utente (base presente, contenuti da finalizzare)
- 🔴 Task 7.3 Profilo Etichetta

### EPIC 8 — Pitch (Invio/Ricezione)
- 🟡 Task 8.1 Pitch Artista (tab pronta, feature da implementare)
- 🟡 Task 8.2 Pitch Etichetta (tab pronta, inbox/azioni da implementare)

### EPIC 9 — Polishing & Build
- 🔴 Task 9.1 Polishing UI/UX
- 🔴 Task 9.2 Gestione errori base
- 🔴 Task 9.3 Build APK/IPA test device

---

## Modifiche implementate finora

### Nuovi file
- `lib/features/user/shell/user_shell.dart`
- `lib/features/artist/shell/artist_shell.dart`
- `lib/features/label/shell/label_shell.dart`
- `lib/features/shared/presentation/screens/role_gate.dart`
- `lib/features/shared/domain/user_role.dart`
- `lib/features/shared/presentation/providers/user_role_provider.dart`
- `assets/ASSETS_TODO.md`

### File modificati
- `lib/core/widgets/bottom_nav.dart`
- `lib/app/nura_app.dart`
- `lib/main.dart`
- `pubspec.yaml`

### Cartelle create (Task 2.1)
- `assets/audio/`
- `assets/images/artists/`
- `assets/images/labels/`
- `assets/images/categories/`

---

## Prossimi step consigliati (ordine)
1. Inserire file media reali nelle cartelle assets (seguendo `assets/ASSETS_TODO.md`).
2. EPIC 3 / Task 3.1: schermata login mock con 3 bottoni ruolo.
3. EPIC 2 / Task 2.2: modelli dati mancanti (`Artist`, `NormalUser`, `Label`, `PitchRequest`).
4. EPIC 2 / Task 2.3: estensione `mock_nura_data.dart`.

---

## Log sessioni

### Sessione 2026-05-07 (A)
- Creato scheletro ruoli con shell dedicate (User/Artist/Label).
- Aggiunto `RoleGate` mock come entry-point esperienza.
- Estesa `BottomNav` per tab dinamiche.
- Verifica statica completata: `flutter analyze` senza errori.

### Sessione 2026-05-07 (B)
- Integrato `flutter_riverpod`.
- Creato stato globale ruolo (`userRoleProvider`).
- Aggiornato `RoleGate` da ruolo hardcoded a ruolo da provider.
- Aggiornato bootstrap app con `ProviderScope`.
- Verifica statica completata: `flutter analyze` senza errori.

### Sessione 2026-05-07 (C)
- Creata struttura assets per Task 2.1.
- Registrati i path assets in `pubspec.yaml`.
- Aggiunta checklist operativa `assets/ASSETS_TODO.md`.
- Verifica statica completata: `flutter analyze` senza errori.

(appendere qui le sessioni successive)
