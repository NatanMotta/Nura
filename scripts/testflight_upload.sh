#!/usr/bin/env bash
set -euo pipefail

# Upload IPA to App Store Connect / TestFlight via altool.
# Preferred auth (App Store Connect API Key):
# - APPLE_API_KEY_ID
# - APPLE_API_ISSUER_ID
# Optional legacy auth:
# - APPLE_ID_EMAIL
# - APPLE_APP_PASSWORD (app-specific password)
# - APPLE_KEYCHAIN_SERVICE (default: NURA_TESTFLIGHT_APP_PASSWORD)
# Optional env vars:
# - APPLE_ASC_PROVIDER (Team short name, only if needed)
# - IPA_PATH (default: latest .ipa in build/ios/ipa)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

use_api_key_auth=false
if [[ -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
  use_api_key_auth=true
fi

if [[ "$use_api_key_auth" != "true" ]]; then
  if [[ -z "${APPLE_ID_EMAIL:-}" ]]; then
    echo "ERROR: missing credentials."
    echo "Use one of:"
    echo '  1) export APPLE_API_KEY_ID="<key-id>" && export APPLE_API_ISSUER_ID="<issuer-id>"'
    echo '  2) export APPLE_ID_EMAIL="you@example.com" (legacy app-specific password flow)'
    exit 1
  fi

  APPLE_KEYCHAIN_SERVICE="${APPLE_KEYCHAIN_SERVICE:-NURA_TESTFLIGHT_APP_PASSWORD}"

  if [[ -z "${APPLE_APP_PASSWORD:-}" ]]; then
    APPLE_APP_PASSWORD="$(security find-generic-password \
      -a "${APPLE_ID_EMAIL}" \
      -s "${APPLE_KEYCHAIN_SERVICE}" \
      -w 2>/dev/null || true)"
  fi

  if [[ -z "${APPLE_APP_PASSWORD:-}" ]]; then
    echo "Inserisci APP-SPECIFIC PASSWORD Apple (non password account)."
    read -r -s -p "APPLE_APP_PASSWORD: " APPLE_APP_PASSWORD
    echo
  fi
fi

if [[ -z "${IPA_PATH:-}" ]]; then
  IPA_PATH="$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${IPA_PATH}" || ! -f "${IPA_PATH}" ]]; then
  echo "ERROR: IPA file not found."
  echo "Build first, or set IPA_PATH explicitly."
  exit 1
fi

echo "==> Uploading IPA: ${IPA_PATH}"
if [[ "$use_api_key_auth" == "true" ]]; then
  xcrun altool --upload-app \
    -f "${IPA_PATH}" \
    -t ios \
    --apiKey "${APPLE_API_KEY_ID}" \
    --apiIssuer "${APPLE_API_ISSUER_ID}" \
    --verbose
else
  if [[ -n "${APPLE_ASC_PROVIDER:-}" ]]; then
    xcrun altool --upload-app \
      -f "${IPA_PATH}" \
      -t ios \
      -u "${APPLE_ID_EMAIL}" \
      -p "${APPLE_APP_PASSWORD}" \
      --asc-provider "${APPLE_ASC_PROVIDER}" \
      --verbose
  else
    xcrun altool --upload-app \
      -f "${IPA_PATH}" \
      -t ios \
      -u "${APPLE_ID_EMAIL}" \
      -p "${APPLE_APP_PASSWORD}" \
      --verbose
  fi
fi

echo "==> Upload request sent."
echo "Note: App Store Connect processing can take 10-30+ minutes before build appears in TestFlight."
