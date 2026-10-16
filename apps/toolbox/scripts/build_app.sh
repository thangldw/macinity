#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"

if [[ "${TOOLBOX_UNIVERSAL:-0}" == "1" ]]; then
  exec "$PROJECT_DIR/scripts/build_universal.sh"
fi

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP_DIR="$PROJECT_DIR/dist/Macinity.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/Toolbox" "$APP_DIR/Contents/MacOS/Toolbox"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$PROJECT_DIR/Resources/MacinityLogo.png" "$APP_DIR/Contents/Resources/MacinityLogo.png"
cp "$PROJECT_DIR/Resources/"MacinityMenuTemplate*.png "$APP_DIR/Contents/Resources/"
for localization in "$PROJECT_DIR"/Resources/*.lproj; do
  [[ -d "$localization" ]] && cp -R "$localization" "$APP_DIR/Contents/Resources/"
done
for language in en ja zh-Hans; do
  "$PROJECT_DIR/scripts/merge_localizations.swift" \
    "$PROJECT_DIR/Resources/$language.lproj" \
    "$APP_DIR/Contents/Resources/$language.lproj/Localizable.strings"
done
chmod +x "$APP_DIR/Contents/MacOS/Toolbox"

codesign --force --deep --options runtime --timestamp=none --sign - "$APP_DIR"
echo "Created: $APP_DIR"
