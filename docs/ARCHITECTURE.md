# PowerMesh architecture

## Goal

Provide one battery dashboard across the user's Apple devices without a custom backend.

## Data flow

```text
Local battery API
      ↓
LocalBatteryReader
      ↓
BatterySnapshot
      ↓
BatteryDashboardStore
      ↓
CloudBatteryStore
      ↓
Private CloudKit database
      ↓
Other PowerMesh installations
```

## Source of truth

CloudKit private database is the shared source of truth for cross-device snapshots. Each installation owns exactly one stable `device-<UUID>` record.

The local UI merges its freshly read snapshot before the network round trip so the current device does not appear stale while CloudKit is being updated.

## Freshness model

A snapshot is considered stale after 30 minutes. This is intentionally explicit because iOS, iPadOS and watchOS do not allow arbitrary continuous background execution.

## Privacy model

No custom account system and no external server are required for the MVP. Data remains in the user's private CloudKit database.

## Planned modules

- Background refresh coordinator
- CloudKit subscriptions
- Widget shared cache / App Group
- WidgetKit targets
- watchOS complication
- Battery history
- Threshold alerts
- BLE accessory provider
