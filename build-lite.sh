#!/bin/bash
# Build Keyboop Lite only. No Homebrew/vendor/Whisper/FluidAudio/Sparkle.
set -euo pipefail
cd "$(dirname "$0")"

bash scripts/restore-words-ru.sh

APP="${KEYBOOP_LITE_APP:-build/Keyboop Lite.app}"
BIN="$APP/Contents/MacOS/Keyboop Lite"
RES="$APP/Contents/Resources"
SOURCE_LIST="scripts/lite-sources.txt"

rm -rf "$APP"
mkdir -p "$(dirname "$BIN")" "$RES"

SOURCES=()
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  SOURCES+=("$line")
done < "$SOURCE_LIST"

for src in "${SOURCES[@]}"; do
  [[ -f "$src" ]] || { echo "✗ missing retained source: $src"; exit 2; }
done

echo "▸ Keyboop Lite: compiling ${#SOURCES[@]} retained Swift sources"
xcrun swiftc -O -whole-module-optimization \
  "${SOURCES[@]}" \
  -o "$BIN" \
  -swift-version 5 \
  -D KEYBOOP_LITE \
  -target arm64-apple-macos15.0 \
  -framework AppKit \
  -framework Carbon \
  -framework ServiceManagement \
  -framework ApplicationServices \
  -framework IOKit \
  -framework QuartzCore \
  -framework Security

cp Sources/Keyboop/Resources/trigrams_*.json "$RES/"
cp Sources/Keyboop/Resources/typo_rules.json "$RES/"
cp Sources/Keyboop/Resources/words_*.json "$RES/"
cp Sources/Keyboop/Resources/menubar-mark.png "$RES/" 2>/dev/null || true
cp Resources/AppIcon.icns "$RES/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Keyboop Lite</string>
  <key>CFBundleIdentifier</key><string>ru.keyboop.lite</string>
  <key>CFBundleName</key><string>Keyboop Lite</string>
  <key>CFBundleDisplayName</key><string>Keyboop Lite</string>
  <key>CFBundleShortVersionString</key><string>0.4.10-lite</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>15.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHumanReadableCopyright</key><string>Keyboop upstream authors; Keyboop Lite surgical build</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "▸ linkage"
otool -L "$BIN"

echo "✓ $APP"
