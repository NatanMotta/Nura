#!/usr/bin/env bash
set -euo pipefail

# Build iOS IPA ready for TestFlight upload.
# Required env vars:
# - SUPABASE_URL
# - SUPABASE_ANON_KEY
#
# Optional env vars:
# - BUILD_NAME (default: 0.1.0)
# - BUILD_NUMBER (default: 1)

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
BUILD_NUMBER="${BUILD_NUMBER:-1}"

echo "==> Flutter clean/get"
flutter clean
flutter pub get

echo "==> CocoaPods install"
cd ios
pod install
cd ..

echo "==> Flutter analyze"
flutter analyze

echo "==> Building IPA (build-name=${BUILD_NAME}, build-number=${BUILD_NUMBER})"
flutter build ipa \
  --release \
  --build-name="${BUILD_NAME}" \
  --build-number="${BUILD_NUMBER}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

echo "==> Done"
echo "Output:"
echo "  build/ios/ipa/*.ipa"
echo
echo "Next:"
echo "  Open Xcode Organizer OR Transporter and upload the IPA to TestFlight."
