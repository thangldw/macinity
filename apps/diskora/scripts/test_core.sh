#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
TEST_BINARY="$(mktemp -d)/diskora-smoke"

swiftc \
    "$PROJECT_DIR/Sources/Diskora/Core/Models.swift" \
    "$PROJECT_DIR/Sources/Diskora/App/AppMetadata.swift" \
    "$PROJECT_DIR/Sources/Diskora/Features/Cleaning/CleanerService.swift" \
    "$PROJECT_DIR/Sources/Diskora/Features/Storage/StorageModels.swift" \
    "$PROJECT_DIR/Sources/Diskora/Features/Storage/StorageAnalyzer.swift" \
    "$PROJECT_DIR/Sources/Diskora/Features/Duplicates/DuplicateScanner.swift" \
    "$PROJECT_DIR/Sources/Diskora/Features/Photos/SimilarPhotoScanner.swift" \
    "$PROJECT_DIR/Tests/Smoke/main.swift" \
    -o "$TEST_BINARY"

MAC_CLEANER_TEST_IMAGE="$PROJECT_DIR/Resources/AppIcon-1024.png" "$TEST_BINARY"
