# PowerMesh 0.1.5 — Physical Ecosystem Acceptance Plan

[Español](TESTING.es.md) · **English**

PowerMesh CI validates deterministic model behavior and compiles macOS, iOS, and watchOS. A release still requires signed physical-device testing because private CloudKit behavior, watchOS publishing, background opportunities, and real battery sources cannot be proven by unsigned CI.

## Release gate

Use the exact commit intended for release. Record iPhone/iPad model and OS, Mac model and macOS, Apple Watch model and watchOS, Apple Developer team, iCloud account, CloudKit environment, commit SHA, and build version.

## Signing and CloudKit setup

1. Configure the `PowerMesh` and `PowerMeshWatch` targets with the same Apple Developer team.
2. Confirm both targets use `iCloud.com.tiburonns.PowerMesh` with CloudKit enabled.
3. Install on at least one iPhone or iPad, one Mac, and one Apple Watch signed into the same iCloud account.
4. Launch each app once and keep network connectivity available.

Expected: no CloudKit startup crash, no entitlement error, and each platform can publish without replacing another device ID.

## Local battery sources

Verify on each applicable device:

- iPhone/iPad: battery percentage and charging state reflect the system within a reasonable refresh window.
- Apple Watch: local percentage and charging state are published from the Watch app.
- Battery-powered Mac: IOPowerSources percentage/state are represented correctly.
- Desktop Mac without internal battery: it is shown as externally powered without inventing a battery percentage.

## Cross-device synchronization matrix

Perform these paths in both directions where applicable: iPhone ↔ Mac, iPhone ↔ Watch, iPad ↔ Mac, and Watch ↔ Mac.

1. Open PowerMesh on device A and refresh/publish.
2. Open PowerMesh on device B using the same iCloud account.
3. Confirm A appears on B with the same stable device identity, name, kind, level/state, source, and a plausible timestamp.
4. Change a user-editable device name, publish again, and confirm the newest snapshot replaces the older one rather than creating a duplicate.
5. Repeat after terminating and reopening both apps.

Expected: one logical card per installation ID and newest remote data wins unless the current device is publishing its own authoritative local snapshot.

## Stale and offline behavior

1. Publish a device, then prevent it from updating for longer than the stale threshold.
2. Open another PowerMesh client.
3. Confirm the old value is visibly marked stale rather than presented as real-time.
4. Disable network/iCloud temporarily and refresh.
5. Re-enable connectivity and refresh again.

Expected: old data remains distinguishable from current data, sync errors do not erase valid local state, and recovery does not duplicate devices.

## Forget device

1. From Settings, forget an obsolete remote device.
2. Confirm its snapshot disappears.
3. Relaunch PowerMesh on another client and confirm the deletion/absence is reflected as designed.
4. Relaunch the forgotten physical device and publish again.

Expected: an actively used device can reappear by publishing a fresh snapshot; forgetting does not corrupt other records.

## Identity migration

Upgrade a device from a build that stored its stable ID in UserDefaults. Do not delete app data.

Expected: the old identity migrates into Keychain, the device does not appear twice in CloudKit, and subsequent launches keep the same ID.

## Language and platform UI

Test **System**, **English**, and **Español** on iPhone/iPad, Mac, and Watch where the selector is exposed. Confirm battery cards, settings, menu-bar UI, empty/error states, charge states, and stale-data labels use the effective language and survive relaunch.

## Privacy and account boundary

Use two different iCloud accounts on separate test devices when practical. The second account must not see the first account private CloudKit snapshots. Confirm PowerMesh requires no custom PowerMesh account and does not expose Apple ID, serial number, IMEI, or private hardware identifiers in visible records/logs.

## Acceptance result

A PowerMesh release candidate passes when local battery sources are correct on real hardware, signed CloudKit sync works across the intended Apple devices, duplicate identities are not created, stale/offline behavior is honest, forget/migration flows preserve data integrity, and the bilingual UI behaves consistently.