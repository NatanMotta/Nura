#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_ID="${ASC_APP_ID:-6768263432}"
IPA_PATH="${IPA_PATH:-$(ls -t "$ROOT_DIR"/build/ios/ipa/*.ipa 2>/dev/null | head -n 1 || true)}"

if ! command -v asc >/dev/null 2>&1; then
  echo "ERROR: asc CLI not found. Install with: brew install asc"
  exit 1
fi

if [[ -z "$IPA_PATH" || ! -f "$IPA_PATH" ]]; then
  echo "ERROR: IPA non trovata. Esegui prima nura-ipa-auto"
  exit 1
fi

AUTH_STATUS="$(asc auth status --validate 2>/dev/null || true)"
if [[ "$AUTH_STATUS" != *'"validation":"works"'* ]]; then
  echo "ERROR: ASC auth non valida. Esegui prima:"
  echo "  asc auth login --name \"Nura\" --key-id \"<KEY_ID>\" --issuer-id \"<ISSUER_ID>\" --private-key \"/path/AuthKey_<KEY_ID>.p8\""
  exit 1
fi

echo "==> Upload ASC"
echo "    app: $APP_ID"
echo "    ipa: $IPA_PATH"

# Default: no wait (piu rapido). Usa ASC_WAIT=1 nura-upload per attendere processing completo.
if [[ "${ASC_WAIT:-0}" == "1" ]]; then
  asc builds upload --app "$APP_ID" --ipa "$IPA_PATH" --wait --output json --pretty
else
  asc builds upload --app "$APP_ID" --ipa "$IPA_PATH" --output json --pretty
fi
