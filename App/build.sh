#!/bin/bash
# Generates the Xcode project and builds app and widget for macOS and the iOS Simulator
# (compile check without signing). Full output in App/build.log.
#   --snapshots   also render test images of the clock face to App/build/snapshots
set -uo pipefail
cd "$(dirname "$0")"
SNAPSHOTS=0
[ "${1:-}" = "--snapshots" ] && SNAPSHOTS=1
LOG=build.log
: > "$LOG"

# Team ID from the Developer ID certificate in the keychain (for signing in Xcode)
if [ -z "${TEAM_ID:-}" ]; then
  TEAM_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep -m1 -oE '\([A-Z0-9]{10}\)"' | tr -d '()"' || true)
fi
export TEAM_ID
echo "Team: ${TEAM_ID:-none}" | tee -a "$LOG"

xcodegen generate 2>&1 | tee -a "$LOG"
[ "${PIPESTATUS[0]}" -eq 0 ] || exit 1

status=0
for dest in "generic/platform=macOS" "generic/platform=iOS Simulator"; do
  echo "== $dest" | tee -a "$LOG"
  xcodebuild -project Wortuhr.xcodeproj -scheme Wortuhr -configuration Debug \
    -destination "$dest" -derivedDataPath build CODE_SIGNING_ALLOWED=NO build >> "$LOG" 2>&1
  if [ $? -eq 0 ]; then echo "   ok"; else echo "   FAILED"; status=1; fi
  grep -E "(error|warning): " "$LOG" | grep -vE "^ld: warning|appintentsmetadataprocessor" | sort -u | tail -n 30
done

if [ $status -eq 0 ] && [ $SNAPSHOTS -eq 1 ]; then
  echo "== Snapshots"
  rm -rf build/snapshots
  build/Build/Products/Debug/Wortuhr.app/Contents/MacOS/Wortuhr -snapshot "$PWD/build/snapshots"
fi
exit $status
