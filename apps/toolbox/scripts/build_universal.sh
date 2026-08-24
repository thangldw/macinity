#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"

swift build -c release --arch arm64
swift build -c release --arch x86_64

ARM_BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"
INTEL_BIN_DIR="$(swift build -c release --arch x86_64 --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/Toolbox.app"
UNIVERSAL_BINARY="$(mktemp -t toolbox-universal)"
trap 'rm -f "$UNIVERSAL_BINARY"' EXIT

lipo -create \
  "$ARM_BIN_DIR/Toolbox" \
  "$INTEL_BIN_DIR/Toolbox" \
  -output "$UNIVERSAL_BINARY"

ARCHITECTURES="$(lipo -archs "$UNIVERSAL_BINARY")"
[[ " $ARCHITECTURES " == *" arm64 "* ]]
[[ " $ARCHITECTURES " == *" x86_64 "* ]]

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$UNIVERSAL_BINARY" "$APP_DIR/Contents/MacOS/Toolbox"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
for localization in "$PROJECT_DIR"/Resources/*.lproj; do
  [[ -d "$localization" ]] && cp -R "$localization" "$APP_DIR/Contents/Resources/"
done
"$PROJECT_DIR/scripts/merge_localizations.swift" \
  "$PROJECT_DIR/Resources/en.lproj" \
  "$APP_DIR/Contents/Resources/en.lproj/Localizable.strings"
chmod +x "$APP_DIR/Contents/MacOS/Toolbox"

if [[ -n "${TOOLBOX_SOURCE_DATE_EPOCH:-}" ]]; then
  [[ "$TOOLBOX_SOURCE_DATE_EPOCH" == <-> ]]
  TIMESTAMP="$(date -r "$TOOLBOX_SOURCE_DATE_EPOCH" +%Y%m%d%H%M.%S)"
  find "$APP_DIR" -exec touch -h -t "$TIMESTAMP" {} +
fi

codesign --force --deep --options runtime --timestamp=none --sign - "$APP_DIR"
echo "Created universal app: $APP_DIR ($ARCHITECTURES)"
