#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PROJECT_DIR/Resources/Info.plist")"
RELEASE_DIR="$PROJECT_DIR/release"
APP_DIR="$PROJECT_DIR/dist/Diskora.app"
UNIVERSAL="${DISKORA_UNIVERSAL:-auto}"
if [[ "$UNIVERSAL" == "auto" ]]; then
    [[ "$(xcode-select -p)" == *CommandLineTools* ]] && UNIVERSAL=0 || UNIVERSAL=1
fi
if [[ "$UNIVERSAL" == "1" && "$(xcode-select -p)" == *CommandLineTools* ]]; then
    echo "Full Xcode chưa được cài; chuyển sang build native $(uname -m)."
    UNIVERSAL=0
fi

ARCH_LABEL="$(uname -m)"
[[ "$UNIVERSAL" == "1" ]] && ARCH_LABEL="universal"
ARCHIVE="$RELEASE_DIR/Diskora-$VERSION-macos-$ARCH_LABEL-unsigned.zip"

mkdir -p "$RELEASE_DIR"
DISKORA_UNIVERSAL="$UNIVERSAL" "$PROJECT_DIR/scripts/build_app.sh"
codesign --verify --deep --strict "$APP_DIR"

ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE"
cd "$RELEASE_DIR"
shasum -a 256 "${ARCHIVE:t}" > "${ARCHIVE:t}.sha256"

echo "Release artifacts:"
echo "  $ARCHIVE"
echo "  $ARCHIVE.sha256"
