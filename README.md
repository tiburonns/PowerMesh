# PowerMesh

[English](#english) · [Español](#español)

PowerMesh is a multilingual SwiftUI app for a unified battery view across the Apple ecosystem. / PowerMesh es una app SwiftUI multilingüe para visualizar de forma unificada la batería del ecosistema Apple.

---

# English

## Goal

PowerMesh aims to show the battery status of a user's Apple devices in one place, without requiring a custom account system or external backend.

## Current MVP

- iPhone / iPad: local battery through `UIDevice`.
- Apple Watch: local battery through `WKInterfaceDevice`.
- Mac laptops: internal battery through IOKit (`IOPowerSources`).
- Desktop Macs: identified as externally powered devices without an internal battery.
- Sync: every installation publishes its battery snapshot to the user's private CloudKit database.
- Shared dashboard: devices signed in to the same iCloud account can read the same snapshots.
- macOS: basic `MenuBarExtra` for checking batteries without opening the main window.
- Freshness: every card exposes the age of its data so an old snapshot is never presented as real-time information.
- Languages: English, Spanish, and a System option that follows the device language.

## Language policy

PowerMesh is multilingual by design.

The app must provide these language choices:

1. **System** — follows the device language.
2. **English**.
3. **Español**.

English is currently the fallback when the system language is not supported.

All user-facing strings must go through the centralized localization layer in `PowerMesh/Support/AppLanguage.swift`. New UI must not introduce hard-coded English or Spanish strings outside that layer unless the text is a product name or another intentionally non-localized value.

All GitHub documentation must be maintained in **English and Spanish**. See `docs/LOCALIZATION.md` for the project policy.

## Important limitation

PowerMesh does not use private APIs to replicate Apple's Batteries widget. AirPods, Apple Pencil, and some Apple accessories do not expose a general public API that allows third-party apps to query every battery percentage.

A future CoreBluetooth provider can support BLE accessories that expose a standard Battery Service or another publicly accessible characteristic.

## Recommended requirements

- Recent Xcode / Swift 6.
- iOS / iPadOS 17 or later.
- macOS 14 or later.
- watchOS 10 or later.
- Apple Developer account for reliable CloudKit testing across physical devices.

## Xcode setup

1. Create a **Multiplatform > App** project using SwiftUI and Swift.
2. Add a watchOS App target if Xcode does not create one automatically.
3. Add the files under `PowerMesh/` to the appropriate targets.
4. In every target, open **Signing & Capabilities** and add **iCloud**.
5. Enable **CloudKit** and select the same container for iPhone/iPad, Mac, and Watch.
6. Run every app while signed in to the same iCloud account. In Development, CloudKit can create the `BatterySnapshot` record type.
7. Before release, deploy the schema to Production from CloudKit Console.

## CloudKit schema

Record Type: `BatterySnapshot`

Fields:

- `deviceID`: String
- `deviceName`: String
- `kind`: String
- `level`: optional Number
- `chargeState`: String
- `updatedAt`: Date/Time
- `source`: String

Each installation uses a stable `CKRecord.ID` in the form `device-<UUID>` and updates its own record.

## Synchronization flow

When the app opens:

1. Read the local battery.
2. Publish the local snapshot to private CloudKit.
3. Fetch snapshots for all known PowerMesh installations.
4. Render the dashboard.

While the app remains active, it checks the local battery once per minute and uploads only when the percentage, charge state, or device name changes, or when 15 minutes have passed since the previous heartbeat.

## Roadmap

1. Complete Xcode project with multiplatform targets and entitlements.
2. `BGAppRefreshTask` for opportunistic iPhone/iPad background snapshots.
3. watchOS background update strategy.
4. WidgetKit for iPhone, iPad, and macOS.
5. Apple Watch complication.
6. `CKSubscription` for reacting to remote changes.
7. Shared App Group cache for widgets.
8. Configurable low-battery alerts.
9. Battery history and charging/discharging trends.
10. CoreBluetooth provider for compatible accessories.
11. Additional app languages through the centralized localization catalog.

## Repository structure

```text
PowerMesh/
├── App/
│   └── PowerMeshApp.swift
├── Models/
│   └── BatterySnapshot.swift
├── Services/
│   ├── BatteryDashboardStore.swift
│   ├── CloudBatteryStore.swift
│   ├── DeviceIdentity.swift
│   └── LocalBatteryReader.swift
├── Support/
│   └── AppLanguage.swift
└── Views/
    ├── BatteryCard.swift
    ├── CompactMenuView.swift
    ├── DashboardView.swift
    └── SettingsView.swift
```

## Privacy

The current implementation uses `CKContainer.privateCloudDatabase`. Snapshots contain only a random installation ID, the user-selected device name, device type, battery percentage, charging state, source, and timestamp.

PowerMesh does not store serial numbers, Apple IDs, IMEI values, or private hardware identifiers.

---

# Español

## Objetivo

PowerMesh busca mostrar en un solo lugar el estado de batería de los dispositivos Apple de un usuario, sin requerir un sistema de cuentas propio ni un servidor externo.

## MVP actual

- iPhone / iPad: batería local mediante `UIDevice`.
- Apple Watch: batería local mediante `WKInterfaceDevice`.
- Mac portátil: batería interna mediante IOKit (`IOPowerSources`).
- Mac de escritorio: se identifica como dispositivo con alimentación externa y sin batería interna.
- Sincronización: cada instalación publica su snapshot en la base privada de CloudKit del usuario.
- Dashboard compartido: los dispositivos con la misma cuenta de iCloud consultan los mismos snapshots.
- macOS: `MenuBarExtra` básico para consultar baterías sin abrir la ventana principal.
- Vigencia del dato: cada tarjeta muestra la antigüedad de la información para no presentar un snapshot viejo como si fuera tiempo real.
- Idiomas: inglés, español y una opción Sistema que sigue el idioma del dispositivo.

## Política de idiomas

PowerMesh es multilingüe por diseño.

La aplicación debe ofrecer estas opciones:

1. **Sistema** — sigue el idioma del dispositivo.
2. **English**.
3. **Español**.

Actualmente se usa inglés como idioma alternativo cuando el idioma del sistema todavía no está soportado.

Todos los textos visibles para el usuario deben pasar por la capa de localización centralizada en `PowerMesh/Support/AppLanguage.swift`. Las nuevas interfaces no deben introducir textos fijos en inglés o español fuera de esa capa, salvo nombres de producto u otros valores que intencionalmente no se traduzcan.

Toda la documentación de GitHub debe mantenerse en **inglés y español**. Consulta `docs/LOCALIZATION.md` para la política del proyecto.

## Limitación importante

PowerMesh no usa APIs privadas para replicar el widget Baterías de Apple. AirPods, Apple Pencil y algunos accesorios Apple no exponen una API pública general que permita a una app de terceros consultar todos sus porcentajes de batería.

Más adelante se puede añadir un proveedor CoreBluetooth para accesorios BLE que publiquen un Battery Service estándar u otra característica accesible públicamente.

## Requisitos recomendados

- Xcode reciente / Swift 6.
- iOS / iPadOS 17 o posterior.
- macOS 14 o posterior.
- watchOS 10 o posterior.
- Cuenta de Apple Developer para probar CloudKit correctamente entre dispositivos físicos.

## Configuración en Xcode

1. Crea un proyecto **Multiplatform > App** con SwiftUI y Swift.
2. Añade un target de watchOS App si Xcode no lo crea automáticamente.
3. Añade los archivos de `PowerMesh/` a los targets correspondientes.
4. En cada target abre **Signing & Capabilities** y añade **iCloud**.
5. Activa **CloudKit** y selecciona el mismo container para iPhone/iPad, Mac y Watch.
6. Ejecuta cada app con la misma cuenta de iCloud. En Development, CloudKit podrá crear el tipo `BatterySnapshot`.
7. Antes de publicar, despliega el schema a Production desde CloudKit Console.

## Schema de CloudKit

Record Type: `BatterySnapshot`

Campos:

- `deviceID`: String
- `deviceName`: String
- `kind`: String
- `level`: Number opcional
- `chargeState`: String
- `updatedAt`: Date/Time
- `source`: String

Cada instalación utiliza un `CKRecord.ID` estable con formato `device-<UUID>` y actualiza su propio registro.

## Flujo de sincronización

Al abrir la app:

1. Lee la batería local.
2. Publica el snapshot local en CloudKit privado.
3. Consulta los snapshots de todas las instalaciones conocidas de PowerMesh.
4. Renderiza el dashboard.

Mientras la app permanece activa, revisa la batería local una vez por minuto y publica solo si cambia el porcentaje, estado de carga o nombre del dispositivo, o si han pasado 15 minutos desde el último heartbeat.

## Próximas iteraciones

1. Proyecto Xcode completo con targets multiplataforma y entitlements.
2. `BGAppRefreshTask` para snapshots oportunistas en segundo plano en iPhone/iPad.
3. Estrategia de actualización en segundo plano para watchOS.
4. WidgetKit para iPhone, iPad y macOS.
5. Complication para Apple Watch.
6. `CKSubscription` para reaccionar a cambios remotos.
7. Cache compartida con App Group para widgets.
8. Alertas configurables por batería baja.
9. Historial y tendencias de carga/descarga.
10. Proveedor CoreBluetooth para accesorios compatibles.
11. Idiomas adicionales mediante el catálogo centralizado de localización.

## Estructura del repositorio

```text
PowerMesh/
├── App/
│   └── PowerMeshApp.swift
├── Models/
│   └── BatterySnapshot.swift
├── Services/
│   ├── BatteryDashboardStore.swift
│   ├── CloudBatteryStore.swift
│   ├── DeviceIdentity.swift
│   └── LocalBatteryReader.swift
├── Support/
│   └── AppLanguage.swift
└── Views/
    ├── BatteryCard.swift
    ├── CompactMenuView.swift
    ├── DashboardView.swift
    └── SettingsView.swift
```

## Privacidad

La implementación actual usa `CKContainer.privateCloudDatabase`. Los snapshots contienen únicamente un ID aleatorio de instalación, nombre del dispositivo elegido por el usuario, tipo, porcentaje, estado de carga, fuente y timestamp.

PowerMesh no almacena números de serie, Apple ID, IMEI ni identificadores privados del hardware.
