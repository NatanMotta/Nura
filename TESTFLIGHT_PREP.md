# TestFlight Prep — Nura

## 1) Prerequisiti (una volta)
- Apple Developer account attivo.
- App creata in App Store Connect.
- Bundle Identifier iOS uguale tra Xcode e App Store Connect.
- Signing automatico attivo in Xcode per target `Runner`.

## 2) Verifiche progetto correnti
- Build iOS minima: iOS 12.0 (ok per plugin audio).
- Versione Flutter app da `pubspec.yaml`: `0.1.0+1`.
- Runtime config Supabase via `--dart-define` (non hardcoded nel source).

## 3) Bundle ID e Team (controllo obbligatorio)
Nel progetto attuale il bundle id è ancora placeholder:
- `com.example.nuraApp`

Prima del rilascio TestFlight, in Xcode (`Runner` target, Debug/Profile/Release) imposta un bundle id reale, ad esempio:
- `it.nuralabs.nura`

Team attuale rilevato:
- `G2J93V5PK4`

## 4) Build IPA (script pronto)
Usa lo script:

```bash
cd /Users/natan/Programmazione_local/Nura
export SUPABASE_URL="https://<project>.supabase.co"
export SUPABASE_ANON_KEY="<anon-key>"
export BUILD_NAME="0.1.0"
export BUILD_NUMBER="2"
./scripts/testflight_build.sh
```

Output previsto:
- `build/ios/ipa/*.ipa`

## 5) Upload TestFlight
Due opzioni:
1. Xcode Organizer -> Distribute App -> App Store Connect -> Upload
2. App Transporter (drag & drop IPA)

## 6) Dopo upload (App Store Connect)
- Aspetta processing build (5-20 min tipicamente).
- Compila:
  - What to Test
  - Export Compliance (se richiesto)
  - eventuali privacy metadata mancanti
- Aggiungi tester interni e avvia test.

## 7) Regola operativa build successive
- Incrementa sempre `BUILD_NUMBER` a ogni nuovo upload.
- Mantieni `BUILD_NAME` per patch/minor semantiche.
