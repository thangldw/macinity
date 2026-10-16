#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
BUILD_DIR="$(mktemp -d)"
trap 'rm -r "$BUILD_DIR"' EXIT

swiftc \
  -emit-library \
  -emit-module \
  -module-name MacinityCore \
  -emit-module-path "$BUILD_DIR/MacinityCore.swiftmodule" \
  "$PROJECT_DIR"/Sources/MacinityCore/*.swift \
  -o "$BUILD_DIR/libMacinityCore.dylib"

swiftc \
  -parse-as-library \
  -I "$BUILD_DIR" \
  -L "$BUILD_DIR" \
  -lMacinityCore \
  "$PROJECT_DIR/Sources/Macinity/ReleaseUpdateChecker.swift" \
  "$PROJECT_DIR/Tests/SmokeApp/main.swift" \
  -o "$BUILD_DIR/macinity-app-smoke"

DYLD_LIBRARY_PATH="$BUILD_DIR" "$BUILD_DIR/macinity-app-smoke"
