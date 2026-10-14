#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
check_dir=$(mktemp -d /tmp/handcraft-check.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library -swift-version 5 -default-isolation MainActor \
  -module-cache-path "$check_dir/modules" \
  Florgugrel/GameModel.swift Florgugrel/ProgressStore.swift \
  Florgugrel/BeastCatalog.swift Florgugrel/Theme.swift Tests/EngineChecks.swift \
  -o "$check_dir/engine-checks"
"$check_dir/engine-checks"
