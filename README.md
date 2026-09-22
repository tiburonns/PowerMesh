
# PowerMesh

[English](#english) · [Español](#español)

PowerMesh is a multilingual SwiftUI battery dashboard for the Apple ecosystem. / PowerMesh es un dashboard SwiftUI multilingüe de batería para el ecosistema Apple.

---

# English

## Status

> **Current `main`: 0.2.0 (build 8).** Feature-complete for the first signed ecosystem acceptance pass. The remaining release gate is physical-device validation of Apple-provisioned capabilities and real hardware behavior.

### Xcode targets

- `PowerMesh` — iPhone, iPad, and native macOS.
- `PowerMeshWatch` — Apple Watch.
- `PowerMeshWidgets` — iPhone/iPad/macOS widgets.
- `PowerMeshWatchWidgets` — dedicated watchOS WidgetKit extension for modern Apple Watch complications.
- `PowerMesh Local` — CloudKit/App Group-free iPhone/iPad/Mac smoke testing before paid-team provisioning.
- `PowerMeshWatch Local` — matching CloudKit/App Group-free Watch smoke testing.

## Implemented in 0.2

- Local battery reading through `UIDevice`, `WKInterfaceDevice`, and IOKit / `IOPowerSources`.
- Stable per-installation Keychain identity.
- Private CloudKit `BatterySnapshot` synchronization and `CKQuerySubscription` change notifications.
- iOS `BGAppRefreshTask` and watchOS app-refresh paths.
- Persistent App Group cache: `group.com.tiburonns.PowerMesh`.
- Separate WidgetKit targets for iPhone/iPad/macOS and Apple Watch complications, sharing the same rendering code.
- Live / Recent / Stale / Offline freshness states.
- Seven-day history and percent/hour trend estimation.
- Configurable low-battery notifications.
- macOS menu-bar dashboard.
- Optional public CoreBluetooth Battery Service (`180F` / `2A19`) support.
- **System / English / Español** language modes, including widget and Bluetooth-permission localization.
- Privacy manifest and release-contract validation.

## Data flow

```text
local battery / compatible BLE
            ↓
    BatteryDashboardStore
      ↙             ↘
App Group cache     private CloudKit
     ↓                    ↓
widgets/Watch       other PowerMesh installs
complication
```

PowerMesh doesn't claim continuous execution. Background opportunities are system-scheduled, so every reading exposes a timestamp and freshness state.

## Accessory scope

PowerMesh uses public APIs only. The BLE provider supports devices that publicly expose the standard Battery Service. This does **not guarantee** AirPods, Apple Pencil, or proprietary Apple accessory battery access because third-party apps don't receive a general public equivalent of Apple's Batteries widget.

## What now requires a real test

1. Provision `iCloud.com.tiburonns.PowerMesh` and `group.com.tiburonns.PowerMesh`.
2. Signed iPhone/iPad ↔ Mac ↔ Apple Watch synchronization.
3. Silent CloudKit push delivery and background refresh timing.
4. Installed widget/App Group and Watch complication data sharing.
5. Low-battery notification delivery.
6. Bluetooth permission and a real compatible Battery-Service accessory.
7. Long-run history/trend and freshness transitions.

See `docs/TESTING.md`.

## Privacy

No custom PowerMesh account or external PowerMesh server is required. Synced records contain a random installation ID, visible device name, category, battery value/state, source, and timestamp. PowerMesh doesn't intentionally store Apple IDs, IMEI values, serial numbers, or private hardware identifiers.

---

# Español

## Estado

> **`main` actual: 0.2.0 (build 8).** Funcionalmente completo para la primera aceptación firmada del ecosistema. La puerta restante es validar en hardware real las capacidades aprovisionadas por Apple.

### Targets de Xcode

- `PowerMesh` — iPhone, iPad y macOS nativo.
- `PowerMeshWatch` — Apple Watch.
- `PowerMeshWidgets` — widgets de iPhone/iPad/macOS.
- `PowerMeshWatchWidgets` — extensión WidgetKit dedicada de watchOS para complications modernas de Apple Watch.
- `PowerMesh Local` — pruebas iPhone/iPad/Mac sin CloudKit/App Group antes del aprovisionamiento con equipo de pago.
- `PowerMeshWatch Local` — ruta equivalente para Apple Watch sin capabilities de pago.

## Implementado en 0.2

- Batería local mediante `UIDevice`, `WKInterfaceDevice` e IOKit / `IOPowerSources`.
- Identidad estable por instalación en Keychain.
- Sincronización privada `BatterySnapshot` con CloudKit y cambios mediante `CKQuerySubscription`.
- `BGAppRefreshTask` en iOS y app-refresh propio de watchOS.
- Caché App Group persistente: `group.com.tiburonns.PowerMesh`.
- Targets WidgetKit separados para iPhone/iPad/macOS y complications de Apple Watch, compartiendo el mismo código de presentación.
- Estados En vivo / Reciente / Desactualizado / Sin conexión.
- Historial de siete días y tendencia en porcentaje/hora.
- Alertas configurables por batería baja.
- Dashboard de barra de menús en macOS.
- Soporte opcional para Battery Service público de CoreBluetooth (`180F` / `2A19`).
- Modos **Sistema / English / Español**, incluida la localización de widgets y permiso Bluetooth.
- Privacy Manifest y validación del contrato de release.

## Flujo

```text
batería local / BLE compatible
            ↓
    BatteryDashboardStore
      ↙             ↘
caché App Group     CloudKit privado
     ↓                    ↓
widgets/Watch       otras instalaciones
complication
```

PowerMesh no promete ejecución continua. El sistema concede las oportunidades de segundo plano; por eso cada lectura muestra timestamp y vigencia.

## Alcance de accesorios

PowerMesh usa solo APIs públicas. El proveedor BLE funciona con dispositivos que exponen públicamente Battery Service. Esto **no garantiza** acceso a AirPods, Apple Pencil ni accesorios propietarios, porque no existe para terceros un equivalente público general del widget Baterías de Apple.

## Lo que ya exige una prueba real

1. Aprovisionar `iCloud.com.tiburonns.PowerMesh` y `group.com.tiburonns.PowerMesh`.
2. Sincronización firmada iPhone/iPad ↔ Mac ↔ Apple Watch.
3. Pushes silenciosos de CloudKit y ritmo real de segundo plano.
4. App Group desde widgets instalados y complication de Watch.
5. Entrega de alertas de batería baja.
6. Permiso Bluetooth y un accesorio real compatible.
7. Historial/tendencia prolongados y transiciones de vigencia.

Consulta `docs/TESTING.es.md`.

## Privacidad

No requiere cuenta PowerMesh ni servidor externo propio. Los registros contienen ID aleatorio de instalación, nombre visible, categoría, nivel/estado de batería, fuente y timestamp. PowerMesh no almacena intencionalmente Apple ID, IMEI, números de serie ni identificadores privados de hardware.
