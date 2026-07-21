#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

swiftc \
  "$PROJECT_DIR/Sources/Changeora/App/AppMetadata.swift" \
  "$PROJECT_DIR/Sources/Changeora/Core/Models.swift" \
  "$PROJECT_DIR/Sources/Changeora/Features/Snapshots/SnapshotDiffEngine.swift" \
  "$PROJECT_DIR/Sources/Changeora/Features/Snapshots/SystemSnapshotScanner.swift" \
  "$PROJECT_DIR/Sources/Changeora/Features/History/SnapshotStore.swift" \
  "$PROJECT_DIR/Tests/Smoke/main.swift" \
  -o "$TEMP_DIR/changeora-smoke"

"$TEMP_DIR/changeora-smoke"
