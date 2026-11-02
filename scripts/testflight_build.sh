#!/usr/bin/env bash
set -euo pipefail

# Build iOS IPA ready for TestFlight upload.
# Required env vars:
# - SUPABASE_URL
# - SUPABASE_ANON_KEY
#
# Optional env vars:
# - BUILD_NAME (default: 0.1.0)
# - BUILD_NUMBER (optional explicit number; otherwise auto-increment)
# - BUILD_STATE_FILE (default: .nura_build_number)
#
# Usage:
#   ./scripts/testflight_build.sh 3
#   ./scripts/testflight_build.sh --auto

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "ERROR: SUPABASE_URL and SUPABASE_ANON_KEY are required."
  echo "Example:"
  echo '  export SUPABASE_URL="https://<project>.supabase.co"'
  echo '  export SUPABASE_ANON_KEY="<anon-key>"'
  exit 1
fi

BUILD_NAME="${BUILD_NAME:-0.1.0}"
BUILD_STATE_FILE="${BUILD_STATE_FILE:-.nura_build_number}"

arg1="${1:-${BUILD_NUMBER:---auto}}"
if [[ "$arg1" == "--auto" ]]; then
  last=2
  if [[ -f "$BUILD_STATE_FILE" ]]; then
    last="$(cat "$BUILD_STATE_FILE")"
  fi
  if ! [[ "$last" =~ ^[0-9]+$ ]]; then
    echo "ERROR: $BUILD_STATE_FILE must contain a numeric build number."
    exit 1
  fi
  BUILD_NUMBER="$((10#$last + 1))"
elif [[ -n "$arg1" ]]; then
  BUILD_NUMBER="$arg1"
fi

if ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "ERROR: BUILD_NUMBER must be numeric."
  echo "Usage:"
  echo "  ./scripts/testflight_build.sh 3"
  echo "  ./scripts/testflight_build.sh --auto"
  exit 1
fi

echo "==> Flutter clean/get"
flutter clean
# shortcut: Flutter 3.44 non crea questa cartella prima di rsync; rimuovere quando corretto nel SDK.
mkdir -p build/ios/SourcePackages
flutter pub get

echo "==> Flutter analyze"
flutter analyze --no-fatal-infos lib test

echo "==> Building IPA (build-name=${BUILD_NAME}, build-number=${BUILD_NUMBER})"
flutter build ipa \
  --release \
  --build-name="${BUILD_NAME}" \
  --build-number="${BUILD_NUMBER}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

echo "$BUILD_NUMBER" > "$BUILD_STATE_FILE"

echo "==> Done"
echo "Output:"
echo "  build/ios/ipa/*.ipa"
echo "Build number used: ${BUILD_NUMBER}"
echo
echo "Next:"
echo "  Open Xcode Organizer OR Transporter and upload the IPA to TestFlight."
