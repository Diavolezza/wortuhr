#!/bin/bash
# Builds Wortuhr.saver (arm64 + x86_64), signs it and installs it to ~/Library/Screen Savers.
# Usage:  ./build.sh                build and install (signed ad hoc)
#         ./build.sh --no-install   build only
#         ./build.sh --system       install for all users to /Library/Screen Savers (admin password)
#         --arm-only                Apple Silicon only (faster; combinable, e.g. ./build.sh --system --arm-only)
#         --docs                    also render the README images in docs/ (combinable)
#         --notarize                sign with the Developer ID, notarise with Apple and staple the ticket
#         --version X.Y             set the version (CFBundleShortVersionString) before signing
# Notarisation credentials: locally the keychain profile "wortuhr-notary"
#   (xcrun notarytool store-credentials wortuhr-notary --key … --key-id … --issuer …);
#   in CI the variables NOTARY_KEY_PATH, NOTARY_KEY_ID and NOTARY_ISSUER_ID.
# SIGN_ID selects the signing identity; by default the Developer ID Application certificate
#   in the keychain (with TEAM_ID set: the one of that team) is used for --notarize.
set -euo pipefail
cd "$(dirname "$0")"
# Also write the output to build.log (so Claude can read errors)
exec > >(tee build.log) 2>&1

NAME=Wortuhr
MIN_OS=13.0
ARCHS=(arm64 x86_64)
MODE=""
DOCS=0
NOTARIZE=0
VERSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --arm-only) ARCHS=(arm64) ;;
    --docs) DOCS=1 ;;
    --notarize) NOTARIZE=1 ;;
    --version) VERSION="${2:?--version needs a value}"; shift ;;
    --no-install|--system) MODE="$1" ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done
if [ "$NOTARIZE" = 1 ] && [ -z "${SIGN_ID:-}" ]; then
  SIGN_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" \
    | grep -- "$(printf %s "${TEAM_ID:-}" | tr -d '[:space:]')" | head -1 | awk '{print $2}' || true)
  if [ -z "$SIGN_ID" ]; then
    echo "No 'Developer ID Application' certificate found in the keychain." >&2; exit 1
  fi
fi
SIGN_ID="${SIGN_ID:--}"
BUILD=build
BUNDLE="$BUILD/$NAME.saver"
SDK=$(xcrun --sdk macosx --show-sdk-path)
TOOLCHAIN_LIB="$(dirname "$(xcrun --find swiftc)")/../lib/swift/macosx"

rm -rf "$BUILD"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

BINS=()
for ARCH in "${ARCHS[@]}"; do
  echo "▸ Compiling $ARCH"
  xcrun swiftc -parse-as-library -wmo -O \
    -module-name "$NAME" \
    -target "$ARCH-apple-macos$MIN_OS" -sdk "$SDK" \
    -c Sources/*.swift Shared/*.swift -o "$BUILD/$NAME-$ARCH.o"
  echo "▸ Linking $ARCH"
  xcrun clang -bundle -target "$ARCH-apple-macos$MIN_OS" -isysroot "$SDK" \
    "$BUILD/$NAME-$ARCH.o" -o "$BUILD/$NAME-$ARCH" \
    -L"$SDK/usr/lib/swift" -L"$TOOLCHAIN_LIB" \
    -Xlinker -rpath -Xlinker /usr/lib/swift \
    -framework ScreenSaver -framework AppKit -framework QuartzCore -framework CoreText
  BINS+=("$BUILD/$NAME-$ARCH")
done

lipo -create "${BINS[@]}" -output "$BUNDLE/Contents/MacOS/$NAME"
cp Info.plist "$BUNDLE/Contents/Info.plist"
# New build number on every build so macOS discards cached thumbnails.
# Seconds since 1970: always increasing and small enough for macOS's version comparison.
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%s)" "$BUNDLE/Contents/Info.plist"
if [ -n "$VERSION" ]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$BUNDLE/Contents/Info.plist"
fi
echo "▸ Thumbnail (11:55)"
xcrun swiftc -O -module-name WortuhrThumb -sdk "$SDK" \
  Sources/*.swift Shared/*.swift Tools/main.swift -o "$BUILD/makethumb" -framework ScreenSaver
"$BUILD/makethumb" "$BUNDLE/Contents/Resources"
tiffutil -cathidpicheck "$BUNDLE/Contents/Resources/thumbnail.png" "$BUNDLE/Contents/Resources/thumbnail@2x.png" -out "$BUNDLE/Contents/Resources/thumbnail.tiff" >/dev/null
# Like Xcode projects, ship only the combined TIFF file, no PNGs.
rm -f "$BUNDLE/Contents/Resources/thumbnail.png" "$BUNDLE/Contents/Resources/thumbnail@2x.png"
if [ "$DOCS" = 1 ]; then
  echo "▸ README images (docs/)"
  xcrun swiftc -O -module-name WortuhrDocs -sdk "$SDK" \
    Sources/*.swift Shared/*.swift Tools/Docs/main.swift -o "$BUILD/makedocs" -framework ScreenSaver
  "$BUILD/makedocs" docs
fi
# Make everything world-readable – otherwise macOS cannot load the bundle from /Library.
chmod -R u+rwX,go+rX-w "$BUNDLE"
if [ "$SIGN_ID" = "-" ]; then
  codesign --force --sign - "$BUNDLE"
else
  echo "▸ Signing with Developer ID"
  codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$BUNDLE"
  codesign --verify --strict --verbose=1 "$BUNDLE"
fi
echo "✓ Built: $BUNDLE"

if [ "$NOTARIZE" = 1 ]; then
  echo "▸ Notarising (takes a few minutes)"
  ZIP="$BUILD/$NAME-notarize.zip"
  ditto -c -k --keepParent "$BUNDLE" "$ZIP"
  if [ -n "${NOTARY_KEY_PATH:-}" ]; then
    # Strip stray whitespace/line breaks that easily slip into pasted secrets.
    KEY_ID=$(printf %s "${NOTARY_KEY_ID:-}" | tr -d '[:space:]')
    ISSUER=$(printf %s "${NOTARY_ISSUER_ID:-}" | tr -d '[:space:]')
    AUTH=(--key "$NOTARY_KEY_PATH" --key-id "$KEY_ID" --issuer "$ISSUER")
  else
    AUTH=(--keychain-profile wortuhr-notary)
  fi
  xcrun notarytool submit "$ZIP" "${AUTH[@]}" --wait --timeout 30m --output-format json \
    | tee "$BUILD/notarize.json" || true
  if ! grep -q '"status" *: *"Accepted"' "$BUILD/notarize.json"; then
    ID=$(sed -n 's/.*"id" *: *"\([^"]*\)".*/\1/p' "$BUILD/notarize.json" | head -1)
    [ -n "$ID" ] && xcrun notarytool log "$ID" "${AUTH[@]}" || true
    echo "Notarisation failed." >&2; exit 1
  fi
  rm -f "$ZIP"
  xcrun stapler staple "$BUNDLE"
  xcrun stapler validate "$BUNDLE"
  echo "✓ Notarised and stapled"
fi

if [ "$MODE" != "--no-install" ]; then
  if [ "$MODE" = "--system" ]; then
    # For all users into /Library (asks for the admin password)
    DEST="/Library/Screen Savers"
    rm -rf "$HOME/Library/Screen Savers/$NAME.saver"
    sudo rm -rf "$DEST/$NAME.saver"
    sudo cp -R "$BUNDLE" "$DEST/"
    sudo chown -R root:wheel "$DEST/$NAME.saver"
    sudo chmod -R u+rwX,go+rX-w "$DEST/$NAME.saver"
  else
    DEST="$HOME/Library/Screen Savers"
    mkdir -p "$DEST"
    rm -rf "$DEST/$NAME.saver"
    cp -R "$BUNDLE" "$DEST/"
    if [ -d "/Library/Screen Savers/$NAME.saver" ]; then
      echo "  Note: there is still a copy in /Library/Screen Savers (built with --system)."
    fi
  fi
  # Quit old instances, otherwise macOS keeps loading the previous build.
  pkill -f legacyScreenSaver 2>/dev/null || true
  # Restart System Settings and the wallpaper agent so the list and thumbnail are reloaded.
  osascript -e 'quit app "System Settings"' 2>/dev/null || true
  killall WallpaperAgent 2>/dev/null || true
  echo "✓ Installed: $DEST/$NAME.saver"
  echo "  System Settings → Screen Saver → Wortuhr"
fi
