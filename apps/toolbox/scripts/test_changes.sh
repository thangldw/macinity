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
  -I "$BUILD_DIR" \
  -L "$BUILD_DIR" \
  -lToolboxCore \
  "$PROJECT_DIR/Sources/ToolboxChanges/Core/Models.swift" \
  "$PROJECT_DIR/Sources/ToolboxChanges/Features/Snapshots/SnapshotDiffEngine.swift" \
  "$PROJECT_DIR/Sources/ToolboxChanges/Features/Snapshots/SystemSnapshotScanner.swift" \
  "$PROJECT_DIR/Sources/ToolboxChanges/Features/Snapshots/FSEventJournal.swift" \
  "$PROJECT_DIR/Sources/ToolboxChanges/Features/History/SnapshotStore.swift" \
  "$PROJECT_DIR/Sources/ToolboxChanges/Features/Trace/InstallerMetadata.swift" \
  "$PROJECT_DIR/Sources/ToolboxChanges/Features/Trace/InstallTraceCoordinator.swift" \
  "$PROJECT_DIR/Tests/SmokeChanges/main.swift" \
  -o "$BUILD_DIR/toolbox-changes-smoke"

DYLD_LIBRARY_PATH="$BUILD_DIR" "$BUILD_DIR/toolbox-changes-smoke"
