#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"

if [[ "${TOOLBOX_UNIVERSAL:-0}" == "1" ]]; then
  exec "$PROJECT_DIR/scripts/build_universal.sh"
fi

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/Toolbox.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/Toolbox" "$APP_DIR/Contents/MacOS/Toolbox"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
for localization in "$PROJECT_DIR"/Resources/*.lproj; do
  [[ -d "$localization" ]] && cp -R "$localization" "$APP_DIR/Contents/Resources/"
done
"$PROJECT_DIR/scripts/merge_localizations.swift" \
  "$PROJECT_DIR/Resources/en.lproj" \
  "$APP_DIR/Contents/Resources/en.lproj/Localizable.strings"
chmod +x "$APP_DIR/Contents/MacOS/Toolbox"

codesign --force --deep --options runtime --timestamp=none --sign - "$APP_DIR"
echo "Created: $APP_DIR"
