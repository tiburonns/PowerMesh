#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
temp_dir="$(mktemp -d /tmp/powermesh-tests.XXXXXX)"
test_binary="$temp_dir/powermesh-core-tests"
trap 'rm -rf "$temp_dir"' EXIT

xcrun swiftc -parse-as-library \
  "$repo_root/PowerMesh/Support/AppLanguage.swift" \
  "$repo_root/PowerMesh/Support/AppLifecycle.swift" \
  "$repo_root/PowerMesh/Models/BatteryHistory.swift" \
  "$repo_root/PowerMesh/Models/BatterySnapshot.swift" \
  "$repo_root/PowerMesh/Services/PowerMeshStorage.swift" \
  "$repo_root/PowerMesh/Services/BatteryNotificationService.swift" \
  "$repo_root/PowerMesh/Services/BatteryDashboardStore.swift" \
  "$repo_root/PowerMesh/Services/CloudBatteryStore.swift" \
  "$repo_root/PowerMesh/Services/DeviceIdentity.swift" \
  "$repo_root/PowerMesh/Services/LocalBatteryReader.swift" \
  "$repo_root/Tests/CoreIntegration.swift" \
  -o "$test_binary"

"$test_binary"
