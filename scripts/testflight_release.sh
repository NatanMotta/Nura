#!/usr/bin/env bash
set -euo pipefail

# Build + upload in one command.
# Usage:
#   ./scripts/testflight_release.sh 3
#   ./scripts/testflight_release.sh --auto

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/testflight_build.sh "${1:---auto}"

# Prefer ASC upload flow when available/authenticated (same behavior as nura-upload).
if command -v asc >/dev/null 2>&1; then
  AUTH_STATUS="$(asc auth status --validate 2>/dev/null || true)"
  if [[ "$AUTH_STATUS" == *'"validation":"works"'* ]]; then
    ./scripts/nura-upload-asc.sh
    exit 0
  fi
fi

# Fallback legacy upload flow (altool).
./scripts/testflight_upload.sh
