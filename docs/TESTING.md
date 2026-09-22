# PowerMesh 0.2.0 — Physical Ecosystem Acceptance Plan

[Español](TESTING.es.md) · **English**

This is the first release candidate where the remaining acceptance gates require signed Apple capabilities and/or physical hardware.

## Record the test environment

Record commit SHA, build number, Apple Developer Team, CloudKit environment, iCloud account, iPhone/iPad model + OS, Mac model + macOS, Apple Watch + watchOS, and any BLE accessory used.

## 1. Signing and capabilities

1. Use the same Team for `PowerMesh`, `PowerMeshWatch`, and `PowerMeshWidgets`.
2. Provision `iCloud.com.tiburonns.PowerMesh`.
3. Provision App Group `group.com.tiburonns.PowerMesh`.
4. Confirm iOS Background Modes include Background fetch and Remote notifications.
5. Install on iPhone/iPad, Mac, and Watch.

Pass: no provisioning/entitlement/install error.

## 2. Local battery sources

Verify:
- iPhone/iPad percentage and charging state.
- Watch percentage and charging state.
- battery-powered Mac percentage/state.
- desktop Mac reports external power without inventing a percentage.

Pass: readings plausibly match the OS.

## 3. CloudKit cross-device matrix

Test iPhone ↔ Mac, iPhone ↔ Watch, iPad ↔ Mac, and Watch ↔ Mac where available.

1. Publish on A.
2. Refresh B.
3. Verify one stable card with correct name/kind/level/state/source/timestamp.
4. Rename A and republish.
5. Relaunch both apps.

Pass: no duplicate installation IDs and newest data wins except the current device's authoritative local reading.

## 4. Silent CloudKit changes

After every device has launched once:

1. Background/terminate B as appropriate.
2. Change and publish A.
3. Observe whether B receives the change through the normal system background opportunity.
4. Open B and verify the resulting cache matches CloudKit.

Pass: no crash; a delivered push causes a fresh fetch. Timing itself is not required to be immediate because the OS can coalesce or delay background delivery.

## 5. iOS/watchOS background refresh

1. Put the apps in background.
2. Allow realistic system time.
3. Reopen and compare timestamps/history.
4. On Watch, test both with and without the complication on the active face.

Pass: opportunistic refresh improves freshness when the system grants runtime; PowerMesh never presents an old sample as live.

## 6. Widgets and Watch complication

1. Add small/medium/large widget where supported.
2. Add a Watch complication.
3. Change battery data and language in PowerMesh.
4. Confirm the App Group cache reaches the extension and timeline reloads eventually.

Pass: extension renders cached values without opening CloudKit directly and uses localized PowerMesh-owned copy.

## 7. History and trend

Generate charging and discharging samples over at least 30 minutes.

Pass:
- history survives app relaunch,
- redundant samples don't grow excessively,
- trend appears only after enough elapsed time,
- trend sign/direction is plausible,
- seven-day retention behaves as designed.

## 8. Low-battery alerts

1. Enable alerts.
2. Choose a threshold.
3. Test a device below threshold while unplugged.
4. Charge/recover and drop again.

Pass: permission flow is correct, alerts are localized, repeated notifications are deduplicated, and charging/recovery resets the alert state.

## 9. Bluetooth accessory

Use a known peripheral that exposes Battery Service `180F` and Battery Level `2A19`.

Pass:
- permission copy is localized,
- scan is opt-in,
- compatible accessory appears with a sane percentage,
- disabling the toggle stops scanning,
- accessory can enter the normal cache/history/sync pipeline.

Failure to detect AirPods/Apple Pencil is not a failure unless that device publicly exposes the standard service.

## 10. Freshness/offline recovery

Exercise Live (<5m), Recent (<30m), Stale (<2h), and Offline (≥2h), then restore network/iCloud.

Pass: the UI remains honest, valid cached state survives sync errors, and recovery does not duplicate devices.

## 11. Account/privacy boundary

Where practical, use a second iCloud account.

Pass: private snapshots do not cross accounts; no custom PowerMesh account, Apple ID, IMEI, serial number, or private hardware ID appears in records/logs.

## Release gate

PowerMesh 0.2 passes when all applicable sections above pass on signed physical devices. Any failure should be captured with platform, OS, exact commit, Xcode error/log excerpt, and reproduction steps.
