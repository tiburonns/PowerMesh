
# PowerMesh architecture / Arquitectura de PowerMesh

[English](#english) · [Español](#español)

---

# English

## Architecture

```text
UIDevice / WKInterfaceDevice / IOPowerSources / public BLE
                         ↓
                 BatterySnapshot
                         ↓
              BatteryDashboardStore
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
  local history     App Group cache    private CloudKit
        ↓                ↓                ↓
 detail + trends    widgets/Watch     other installs
                    complication
```

Each installation owns a stable random Keychain ID. CloudKit records use `device-<UUID>`. Remote duplicates reconcile by ID and newest timestamp; the running device remains authoritative for its fresh local reading.

### Freshness

- Live: under 5 minutes.
- Recent: under 30 minutes.
- Stale: under 2 hours.
- Offline: 2 hours or more.

These are freshness labels, not direct connectivity probes.

### CloudKit and background delivery

`CloudBatteryStore` uses the private database, verifies account availability, and installs a `CKQuerySubscription` for `BatterySnapshot` changes. A push is only a change signal; PowerMesh performs a new query before updating its cache.

iOS uses `BGAppRefreshTask` (`com.tiburonns.PowerMesh.refresh`). watchOS uses its native app-refresh path. macOS receives CloudKit remote notifications and also refreshes normally in foreground.

### Shared cache and WidgetKit

Validated snapshots are written to `group.com.tiburonns.PowerMesh`. WidgetKit reads only this cache and never contacts CloudKit directly. Writes request timeline reloads. The widget extension supplies iPhone/iPad/macOS widgets and modern Watch complications.

### History, trends, alerts

PowerMesh retains up to seven days of compact samples, suppresses redundant close samples, and computes percent/hour only with enough elapsed time. Low-battery alerts are local, configurable, and deduplicated.

### Bluetooth

BLE scanning is opt-in and limited to the standard Battery Service `180F` and Battery Level `2A19`. Compatible accessory snapshots flow through the same cache/history/CloudKit pipeline. No private Apple accessory API is used.

### Local configuration

`DebugLocal` / `PowerMesh Local` removes CloudKit and App Group entitlement requirements for pre-membership testing.

---

# Español

## Arquitectura

```text
UIDevice / WKInterfaceDevice / IOPowerSources / BLE público
                         ↓
                 BatterySnapshot
                         ↓
              BatteryDashboardStore
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
 historial local    caché App Group    CloudKit privado
        ↓                ↓                ↓
 detalle+tendencia  widgets/Watch     otras instalaciones
                    complication
```

Cada instalación tiene un ID aleatorio estable en Keychain. CloudKit usa registros `device-<UUID>`. Los duplicados se reconcilian por ID y timestamp; el dispositivo actual conserva su lectura local reciente como autoritativa.

### Vigencia

- En vivo: menos de 5 minutos.
- Reciente: menos de 30 minutos.
- Desactualizado: menos de 2 horas.
- Sin conexión: 2 horas o más.

Son etiquetas de vigencia, no pruebas directas de conectividad.

### CloudKit y segundo plano

`CloudBatteryStore` usa la base privada, comprueba la cuenta e instala una `CKQuerySubscription` para cambios de `BatterySnapshot`. El push solo indica que hubo cambios; PowerMesh vuelve a consultar antes de actualizar el caché.

iOS usa `BGAppRefreshTask` (`com.tiburonns.PowerMesh.refresh`), watchOS su ruta app-refresh nativa y macOS callbacks de CloudKit más actualización normal en foreground.

### Caché compartida y WidgetKit

Los snapshots validados se guardan en `group.com.tiburonns.PowerMesh`. WidgetKit lee únicamente ese caché; no consulta CloudKit directamente. Las escrituras solicitan recargar timelines. La extensión sirve widgets de iPhone/iPad/macOS y complications modernas de Watch.

### Historial, tendencias y alertas

Se conservan hasta siete días de muestras compactas, se eliminan muestras cercanas redundantes y la tendencia porcentaje/hora solo se calcula con duración suficiente. Las alertas por batería baja son locales, configurables y deduplicadas.

### Bluetooth

El escaneo BLE es opcional y limitado a Battery Service `180F` y Battery Level `2A19`. Los accesorios compatibles usan el mismo pipeline de caché/historial/CloudKit. No se usan APIs privadas de Apple.

### Configuración local

`DebugLocal` / `PowerMesh Local` elimina requisitos de entitlement CloudKit/App Group para pruebas antes de la membresía.
