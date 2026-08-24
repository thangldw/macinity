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
  "$PROJECT_DIR/Sources/ToolboxStorage/Core/Models.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Cleaning/CleanerService.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Applications/ApplicationManager.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/History/HistoryStore.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Storage/StorageModels.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Storage/StorageAnalyzer.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Duplicates/DuplicateScanner.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Photos/SimilarPhotoScanner.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Projects/ProjectModels.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Projects/ProjectScanner.swift" \
  "$PROJECT_DIR/Sources/ToolboxStorage/Features/Projects/ProjectCleanupService.swift" \
  "$PROJECT_DIR/Tests/SmokeStorage/main.swift" \
  -o "$BUILD_DIR/toolbox-storage-smoke"

DYLD_LIBRARY_PATH="$BUILD_DIR" \
  MAC_CLEANER_TEST_IMAGE="$PROJECT_DIR/Resources/AppIcon-1024.png" \
  "$BUILD_DIR/toolbox-storage-smoke"
