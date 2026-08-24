#!/bin/bash
set -euo pipefail

app="${1:?Toolbox.app path required}"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" = "com.thang.toolbox"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "2.0.0"
architectures="$(lipo -archs "$app/Contents/MacOS/Toolbox")"
grep -qw arm64 <<<"$architectures"
grep -qw x86_64 <<<"$architectures"
test -f "$app/Contents/Resources/en.lproj/Localizable.strings"
test -f "$app/Contents/Resources/vi.lproj/Localizable.strings"
codesign --verify --deep --strict "$app"

echo "PASS: Toolbox release contract ($architectures)"
