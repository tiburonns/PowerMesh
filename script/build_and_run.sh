#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/PowerMesh.xcodeproj"
SCHEME="PowerMesh"
DERIVED_DATA="$ROOT/.build/DerivedData"
APP="$DERIVED_DATA/Build/Products/Debug/PowerMesh.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "PowerMesh must be built with Xcode on macOS."
  exit 1
fi

pkill -x PowerMesh 2>/dev/null || true

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

if [[ ! -d "$APP" ]]; then
  echo "Build succeeded but $APP was not found."
  exit 1
fi

open -n "$APP"
