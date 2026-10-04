#!/bin/bash
# Builds Wortuhr.saver (arm64 + x86_64), signs it ad hoc and installs it to ~/Library/Screen Savers.
# Usage:  ./build.sh                build and install
#         ./build.sh --no-install   build only
#         ./build.sh --system       install for all users to /Library/Screen Savers (admin password)
#         --arm-only                Apple Silicon only (faster; combinable, e.g. ./build.sh --system --arm-only)
#         --docs                    also render the README images in docs/ (combinable)
set -euo pipefail
cd "$(dirname "$0")"
# Also write the output to build.log (so Claude can read errors)
exec > >(tee build.log) 2>&1

NAME=Wortuhr
MIN_OS=13.0
ARCHS=(arm64 x86_64)
MODE=""
DOCS=0
for arg in "$@"; do
  case "$arg" in
    --arm-only) ARCHS=(arm64) ;;
    --docs) DOCS=1 ;;
    --no-install|--system) MODE="$arg" ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done
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
    -c Sources/*.swift -o "$BUILD/$NAME-$ARCH.o"
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
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%Y%m%d%H%M%S)" "$BUNDLE/Contents/Info.plist"
echo "▸ Thumbnail (11:55)"
xcrun swiftc -O -module-name WortuhrThumb -sdk "$SDK" \
  Sources/*.swift Tools/main.swift -o "$BUILD/makethumb" -framework ScreenSaver
"$BUILD/makethumb" "$BUNDLE/Contents/Resources"
tiffutil -cathidpicheck "$BUNDLE/Contents/Resources/thumbnail.png" "$BUNDLE/Contents/Resources/thumbnail@2x.png" -out "$BUNDLE/Contents/Resources/thumbnail.tiff" >/dev/null
# Like Xcode projects, ship only the combined TIFF file, no PNGs.
rm -f "$BUNDLE/Contents/Resources/thumbnail.png" "$BUNDLE/Contents/Resources/thumbnail@2x.png"
if [ "$DOCS" = 1 ]; then
  echo "▸ README images (docs/)"
  xcrun swiftc -O -module-name WortuhrDocs -sdk "$SDK" \
    Sources/*.swift Tools/Docs/main.swift -o "$BUILD/makedocs" -framework ScreenSaver
  "$BUILD/makedocs" docs
fi
# Make everything world-readable – otherwise macOS cannot load the bundle from /Library.
chmod -R u+rwX,go+rX-w "$BUNDLE"
codesign --force --sign - "$BUNDLE"
echo "✓ Built: $BUNDLE"

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
