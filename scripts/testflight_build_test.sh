#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export TEST_PROJECT_DIR="$TEST_DIR/project"
mkdir -p "$TEST_PROJECT_DIR/scripts"
cp "$ROOT_DIR/scripts/testflight_build.sh" "$TEST_PROJECT_DIR/scripts/"
export PATH="$TEST_DIR:$PATH"
export BUILD_STATE_FILE="$TEST_DIR/build_number"
export FLUTTER_TEST_LOG="$TEST_DIR/flutter.log"
export SUPABASE_URL="https://example.invalid"
export SUPABASE_ANON_KEY="test-key"
unset BUILD_NUMBER

cat > "$TEST_DIR/flutter" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FLUTTER_TEST_LOG"
if [[ "$1" == "clean" ]]; then
  rm -rf "$TEST_PROJECT_DIR/build"
fi
if [[ "$1 $2" == "pub get" && ! -d "$TEST_PROJECT_DIR/build/ios/SourcePackages" ]]; then
  echo 'ERROR: missing SourcePackages directory after clean' >&2
  exit 1
fi
if [[ "$1" == "build" && "${FLUTTER_FAIL_BUILD:-0}" == "1" ]]; then
  exit 1
fi
if [[ "$1" == "build" ]]; then
  [[ "$(command -v rsync)" == "/usr/bin/rsync" ]] || exit 1
  if [[ "${FLUTTER_NO_IPA:-0}" != "1" ]]; then
    mkdir -p build/ios/ipa
    printf 'test IPA' > build/ios/ipa/NURA.ipa
  fi
fi
MOCK
chmod +x "$TEST_DIR/flutter"

echo 15 > "$BUILD_STATE_FILE"
bash "$TEST_PROJECT_DIR/scripts/testflight_build.sh" > /dev/null
[[ "$(cat "$BUILD_STATE_FILE")" == "16" ]]
grep -q -- '--build-number=16' "$FLUTTER_TEST_LOG"
grep -q -- 'analyze --no-fatal-infos lib test' "$FLUTTER_TEST_LOG"

bash "$TEST_PROJECT_DIR/scripts/testflight_build.sh" --auto > /dev/null
[[ "$(cat "$BUILD_STATE_FILE")" == "17" ]]
bash "$TEST_PROJECT_DIR/scripts/testflight_build.sh" 42 > /dev/null
[[ "$(cat "$BUILD_STATE_FILE")" == "42" ]]

if FLUTTER_FAIL_BUILD=1 bash "$TEST_PROJECT_DIR/scripts/testflight_build.sh" > /dev/null; then
  echo 'ERROR: failed build should fail the script'; exit 1
fi
[[ "$(cat "$BUILD_STATE_FILE")" == "42" ]]

if FLUTTER_NO_IPA=1 bash "$TEST_PROJECT_DIR/scripts/testflight_build.sh" > /dev/null; then
  echo 'ERROR: missing IPA should fail even if Flutter exits successfully'; exit 1
fi
[[ "$(cat "$BUILD_STATE_FILE")" == "42" ]]

echo invalid > "$BUILD_STATE_FILE"
if bash "$TEST_PROJECT_DIR/scripts/testflight_build.sh" > /dev/null; then
  echo 'ERROR: invalid counter should be rejected'; exit 1
fi
[[ "$(cat "$BUILD_STATE_FILE")" == "invalid" ]]
echo 'Build numbering checks passed (no IPA built or uploaded).'
