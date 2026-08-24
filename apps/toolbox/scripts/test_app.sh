#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
BUILD_DIR="$(mktemp -d)"
trap 'rm -r "$BUILD_DIR"' EXIT

swiftc \
  -emit-library \
  -emit-module \
  -module-name ToolboxCore \
  -emit-module-path "$BUILD_DIR/ToolboxCore.swiftmodule" \
  "$PROJECT_DIR"/Sources/ToolboxCore/*.swift \
  -o "$BUILD_DIR/libToolboxCore.dylib"

swiftc \
  -parse-as-library \
  -I "$BUILD_DIR" \
  -L "$BUILD_DIR" \
  -lToolboxCore \
  "$PROJECT_DIR/Sources/Toolbox/ReleaseUpdateChecker.swift" \
  "$PROJECT_DIR/Tests/SmokeApp/main.swift" \
  -o "$BUILD_DIR/toolbox-app-smoke"

DYLD_LIBRARY_PATH="$BUILD_DIR" "$BUILD_DIR/toolbox-app-smoke"
