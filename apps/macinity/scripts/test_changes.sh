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
  -I "$BUILD_DIR" \
  -L "$BUILD_DIR" \
  -lMacinityCore \
  "$PROJECT_DIR/Sources/MacinityChanges/Core/Models.swift" \
  "$PROJECT_DIR/Sources/MacinityChanges/Features/Snapshots/SnapshotDiffEngine.swift" \
  "$PROJECT_DIR/Sources/MacinityChanges/Features/Snapshots/SystemSnapshotScanner.swift" \
  "$PROJECT_DIR/Sources/MacinityChanges/Features/Snapshots/FSEventJournal.swift" \
  "$PROJECT_DIR/Sources/MacinityChanges/Features/History/SnapshotStore.swift" \
  "$PROJECT_DIR/Sources/MacinityChanges/Features/Trace/InstallerMetadata.swift" \
  "$PROJECT_DIR/Sources/MacinityChanges/Features/Trace/InstallTraceCoordinator.swift" \
  "$PROJECT_DIR/Tests/SmokeChanges/main.swift" \
  -o "$BUILD_DIR/macinity-changes-smoke"

DYLD_LIBRARY_PATH="$BUILD_DIR" "$BUILD_DIR/macinity-changes-smoke"
