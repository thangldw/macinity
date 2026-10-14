#!/bin/bash
set -euo pipefail

app="${1:?Orven.app path required}"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" = "com.thang.toolbox"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "3.0.0"
architectures="$(lipo -archs "$app/Contents/MacOS/Toolbox")"
grep -qw arm64 <<<"$architectures"
grep -qw x86_64 <<<"$architectures"
test -f "$app/Contents/Resources/en.lproj/Localizable.strings"
test -f "$app/Contents/Resources/vi.lproj/Localizable.strings"
for language in ja zh-Hans; do
  test -f "$app/Contents/Resources/$language.lproj/Localizable.strings"
done
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$app/Contents/Info.plist")" = "Orven"
test -f "$app/Contents/Resources/OrvenLogo.png"
codesign --verify --deep --strict "$app"

echo "PASS: Orven release contract ($architectures)"
