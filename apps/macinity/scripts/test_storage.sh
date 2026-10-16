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
  "$PROJECT_DIR/Sources/MacinityStorage/Core/Models.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Cleaning/CleanerService.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Cleaning/ScheduledScan.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Applications/ApplicationManager.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/History/HistoryStore.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/History/UnifiedRecoveryAdapter.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Storage/StorageModels.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Storage/StorageAnalyzer.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Duplicates/DuplicateScanner.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Photos/SimilarPhotoScanner.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Projects/ProjectModels.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Projects/ProjectScanner.swift" \
  "$PROJECT_DIR/Sources/MacinityStorage/Features/Projects/ProjectCleanupService.swift" \
  "$PROJECT_DIR/Tests/SmokeStorage/main.swift" \
  -o "$BUILD_DIR/macinity-storage-smoke"

DYLD_LIBRARY_PATH="$BUILD_DIR" \
  MAC_CLEANER_TEST_IMAGE="$PROJECT_DIR/Resources/AppIcon-1024.png" \
  "$BUILD_DIR/macinity-storage-smoke"
