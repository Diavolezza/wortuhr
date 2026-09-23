#!/bin/bash
# Baut Wortuhr.saver (arm64 + x86_64), signiert ad hoc und installiert nach ~/Library/Screen Savers.
# Aufruf:  ./build.sh            bauen und installieren
#          ./build.sh --no-install   nur bauen
#          ./build.sh --system       für alle Benutzer nach /Library/Screen Savers (Administrator-Passwort)
set -euo pipefail
cd "$(dirname "$0")"
# Ausgabe zusätzlich in build.log (damit Claude Fehler mitlesen kann)
exec > >(tee build.log) 2>&1

NAME=Wortuhr
MIN_OS=13.0
ARCHS=(arm64 x86_64)
BUILD=build
BUNDLE="$BUILD/$NAME.saver"
SDK=$(xcrun --sdk macosx --show-sdk-path)
TOOLCHAIN_LIB="$(dirname "$(xcrun --find swiftc)")/../lib/swift/macosx"

rm -rf "$BUILD"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

BINS=()
for ARCH in "${ARCHS[@]}"; do
  echo "▸ Kompiliere $ARCH"
  xcrun swiftc -parse-as-library -wmo -O \
    -module-name "$NAME" \
    -target "$ARCH-apple-macos$MIN_OS" -sdk "$SDK" \
    -c Sources/*.swift -o "$BUILD/$NAME-$ARCH.o"
  echo "▸ Linke $ARCH"
  xcrun clang -bundle -target "$ARCH-apple-macos$MIN_OS" -isysroot "$SDK" \
    "$BUILD/$NAME-$ARCH.o" -o "$BUILD/$NAME-$ARCH" \
    -L"$SDK/usr/lib/swift" -L"$TOOLCHAIN_LIB" \
    -Xlinker -rpath -Xlinker /usr/lib/swift \
    -framework ScreenSaver -framework AppKit -framework QuartzCore -framework CoreText
  BINS+=("$BUILD/$NAME-$ARCH")
done

lipo -create "${BINS[@]}" -output "$BUNDLE/Contents/MacOS/$NAME"
cp Info.plist "$BUNDLE/Contents/Info.plist"
# Neue Build-Nummer bei jedem Bau, damit macOS zwischengespeicherte Vorschaubilder verwirft.
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%Y%m%d%H%M%S)" "$BUNDLE/Contents/Info.plist"
echo "▸ Vorschaubild (11:55)"
xcrun swiftc -O -module-name WortuhrThumb -sdk "$SDK" \
  Sources/*.swift Tools/main.swift -o "$BUILD/makethumb" -framework ScreenSaver
"$BUILD/makethumb" "$BUNDLE/Contents/Resources"
tiffutil -cathidpicheck "$BUNDLE/Contents/Resources/thumbnail.png" "$BUNDLE/Contents/Resources/thumbnail@2x.png" -out "$BUNDLE/Contents/Resources/thumbnail.tiff" >/dev/null
# Wie bei Xcode-Projekten nur die kombinierte TIFF-Datei ausliefern, keine PNGs.
rm -f "$BUNDLE/Contents/Resources/thumbnail.png" "$BUNDLE/Contents/Resources/thumbnail@2x.png"
# Alles für alle lesbar machen – sonst kann macOS das Paket aus /Library nicht laden.
chmod -R u+rwX,go+rX-w "$BUNDLE"
codesign --force --sign - "$BUNDLE"
echo "✓ Gebaut: $BUNDLE"

MODE="${1:-}"
if [ "$MODE" != "--no-install" ]; then
  if [ "$MODE" = "--system" ]; then
    # Für alle Benutzer nach /Library (fragt nach dem Administrator-Passwort)
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
      echo "  Hinweis: Es liegt noch eine Kopie in /Library/Screen Savers (mit --system gebaut)."
    fi
  fi
  # Alte Instanzen beenden, sonst lädt macOS weiter den vorigen Build.
  pkill -f legacyScreenSaver 2>/dev/null || true
  # Systemeinstellungen und Hintergrund-Agent neu starten, damit Liste und Vorschaubild neu geladen werden.
  osascript -e 'quit app "System Settings"' 2>/dev/null || true
  killall WallpaperAgent 2>/dev/null || true
  echo "✓ Installiert: $DEST/$NAME.saver"
  echo "  Systemeinstellungen → Bildschirmschoner → Wortuhr"
fi
