#!/usr/bin/env bash
#
# One command from a clean checkout to a file you can upload to Play.
#
# The reason this exists rather than a line in a README: the release
# build takes exactly one flag that nothing enforces and everything
# depends on. Forget --dart-define=API_BASE_URL and the app installs,
# opens, and fails on every screen with "check your connection" —
# because it is trying to reach the machine it was compiled on.
#
# Usage:
#   tool/build_release.sh https://api.vetnow.ba
#   tool/build_release.sh https://api.vetnow.ba apk     # for side-loading
#
set -euo pipefail

API_BASE_URL="${1:-}"
ARTIFACT="${2:-appbundle}"

if [[ -z "$API_BASE_URL" ]]; then
  echo "usage: $0 <https://api.example.com> [appbundle|apk]" >&2
  exit 64
fi

if [[ "$API_BASE_URL" != https://* ]]; then
  echo "error: the API base URL must be https://." >&2
  echo "       The release build blocks cleartext, so an http:// address" >&2
  echo "       fails every request on a real device." >&2
  exit 64
fi

cd "$(dirname "$0")/.."

if [[ ! -f android/key.properties ]]; then
  echo
  echo "  WARNING: android/key.properties is missing."
  echo "  This build will be signed with the shared debug key, and"
  echo "  Google Play will reject it. See android/key.properties.example."
  echo
fi

echo "==> Checks"
flutter analyze
flutter test

echo "==> Building $ARTIFACT against $API_BASE_URL"
flutter build "$ARTIFACT" --release --dart-define="API_BASE_URL=$API_BASE_URL"

echo
echo "Done."
echo
if [[ "$ARTIFACT" == "appbundle" ]]; then
  echo "  Upload:  build/app/outputs/bundle/release/app-release.aab"
else
  echo "  Install: build/app/outputs/flutter-apk/app-release.apk"
fi
echo "  Keep:    build/app/outputs/mapping/release/mapping.txt"
echo
echo "The mapping file is what turns an obfuscated crash report back into"
echo "readable line numbers. Play has a field for it; without it, reports"
echo "from the field are unusable."
