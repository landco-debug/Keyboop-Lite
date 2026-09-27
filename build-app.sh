#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="Keyboop Lite.app"
OUT="$APP/Contents"
RES="$OUT/Resources"
SRC="Sources/KeyboopLite"
UPSTREAM="https://raw.githubusercontent.com/iffuno/keyboop/fb9bdde4eb8f13a486974cf102a8bec9d607e5d2/Sources/Keyboop/Resources"

rm -rf "$APP" "Keyboop-Lite-arm64.zip" .build-resources
mkdir -p "$OUT/MacOS" "$RES" .build-resources

echo "▸ fetching pinned language resources"
for f in words_ru.json words_en.json trigrams_ru.json trigrams_en.json typo_rules.json; do
  curl --fail --silent --show-error --location "$UPSTREAM/$f" -o ".build-resources/$f"
done

python3 - <<'PY'
import json, pathlib, struct

p = pathlib.Path(".build-resources")

for name in ("words_ru", "words_en"):
    words = json.loads((p / f"{name}.json").read_text(encoding="utf-8"))
    words = sorted({str(w).lower() for w in words if w})
    (p / f"{name}.txt").write_text("\n".join(words) + "\n", encoding="utf-8")

for name in ("trigrams_ru", "trigrams_en"):
    table = json.loads((p / f"{name}.json").read_text(encoding="utf-8"))
    records = []
    for key, value in table.items():
        cps = [ord(ch) for ch in key]
        if len(cps) != 3:
            raise SystemExit(f"{name}: non-3-scalar trigram {key!r}")
        records.append((cps[0], cps[1], cps[2], float(value)))
    records.sort(key=lambda r: r[:3])
    with (p / f"{name}.bin").open("wb") as f:
        for record in records:
            f.write(struct.pack("<IIIf", *record))
PY

cp .build-resources/words_ru.txt .build-resources/words_en.txt "$RES/"
cp .build-resources/trigrams_ru.bin .build-resources/trigrams_en.bin "$RES/"
cp .build-resources/typo_rules.json "$RES/"

echo "▸ compiling arm64 release"
swiftc -Osize "$SRC"/*.swift   -o "$OUT/MacOS/Keyboop Lite"   -target arm64-apple-macos14.0   -framework AppKit   -framework ApplicationServices   -framework Carbon   -framework ServiceManagement

cat > "$OUT/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key><string>Keyboop Lite</string>
  <key>CFBundleExecutable</key><string>Keyboop Lite</string>
  <key>CFBundleIdentifier</key><string>io.github.landco-debug.KeyboopLite</string>
  <key>CFBundleName</key><string>Keyboop Lite</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"

echo "▸ running deterministic self-test"
"$OUT/MacOS/Keyboop Lite" --self-test

ditto -c -k --sequesterRsrc --keepParent "$APP" "Keyboop-Lite-arm64.zip"

echo "✓ $APP"
echo "✓ Keyboop-Lite-arm64.zip"
