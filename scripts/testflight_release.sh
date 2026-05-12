#!/usr/bin/env bash
set -euo pipefail

# Build + upload in one command.
# Usage:
#   ./scripts/testflight_release.sh 3
#   ./scripts/testflight_release.sh --auto

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

./scripts/testflight_build.sh "${1:---auto}"
./scripts/testflight_upload.sh
