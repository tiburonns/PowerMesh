# PowerMesh — batería unificada para el ecosistema Apple

PowerMesh es una app SwiftUI multiplataforma cuyo objetivo es mostrar en una sola vista el estado de batería de los dispositivos Apple de un mismo usuario.

## MVP actual

- iPhone / iPad: batería local mediante `UIDevice`.
- Apple Watch: batería local mediante `WKInterfaceDevice`.
- Mac portátil: batería interna mediante IOKit (`IOPowerSources`).
- Mac de escritorio: se identifica como dispositivo con alimentación externa y sin batería interna.
- Sincronización: cada instalación publica su snapshot en la base privada de CloudKit.
- Dashboard compartido: cualquier dispositivo con la misma cuenta de iCloud consulta los mismos registros.
- macOS: `MenuBarExtra` básico para consultar baterías sin abrir la ventana principal.
- Cada tarjeta muestra la antigüedad del dato para no confundir un snapshot viejo con información en tiempo real.

## Limitación importante

PowerMesh no usa APIs privadas para intentar replicar el widget Baterías de Apple. AirPods, Apple Pencil y algunos accesorios Apple no exponen una API pública general que permita a una app de terceros consultar todos sus porcentajes de batería.

Más adelante se puede añadir un módulo CoreBluetooth para accesorios BLE que publiquen un Battery Service estándar u otra característica accesible públicamente.

## Requisitos recomendados

- Xcode reciente / Swift 6.
- iOS / iPadOS 17 o posterior.
- macOS 14 o posterior.
- watchOS 10 o posterior.
- Cuenta de Apple Developer para probar CloudKit correctamente entre dispositivos físicos.

## Cómo montar el proyecto en Xcode

1. Crea un proyecto **Multiplatform > App** con SwiftUI y Swift.
2. Añade un target de watchOS App si Xcode no lo crea automáticamente.
3. Añade los archivos de `PowerMesh/` a los targets correspondientes.
4. En cada target abre **Signing & Capabilities** y añade **iCloud**.
5. Activa **CloudKit** y selecciona el mismo container para iPhone/iPad, Mac y Watch.
6. Ejecuta cada app con la misma cuenta de iCloud. En Development, CloudKit podrá crear el tipo `BatterySnapshot`.
7. Antes de publicar, despliega el schema a Production desde CloudKit Console.

## Schema CloudKit

Record Type: `BatterySnapshot`

Campos:

- `deviceID`: String
- `deviceName`: String
- `kind`: String
- `level`: Number opcional
- `chargeState`: String
- `updatedAt`: Date/Time
- `source`: String

Cada dispositivo utiliza un `CKRecord.ID` estable con formato `device-<UUID>` y actualiza su propio registro.

## Sincronización

Al abrir la app:

1. Lee la batería local.
2. Publica el snapshot en CloudKit privado.
3. Consulta los snapshots de todos los dispositivos.
4. Renderiza el dashboard.

Mientras la app permanece ejecutándose, revisa la batería local una vez por minuto y publica solo si cambia el porcentaje, estado o nombre, o si han pasado 15 minutos desde el último heartbeat.

## Próximas iteraciones

1. `BGAppRefreshTask` para snapshots oportunistas en segundo plano en iPhone/iPad.
2. Actualización de watchOS adaptada a sus ventanas de ejecución.
3. WidgetKit para iPhone, iPad y macOS.
4. Complication para Apple Watch.
5. `CKSubscription` para reaccionar a cambios remotos.
6. Cache compartida con App Group para widgets.
7. Alertas configurables por umbral de batería.
8. Historial y tendencias de descarga/carga.
9. Módulo CoreBluetooth para accesorios compatibles.

## Estructura

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
└── Views/
    ├── BatteryCard.swift
    ├── CompactMenuView.swift
    ├── DashboardView.swift
    └── SettingsView.swift
```

## Privacidad

La implementación usa `CKContainer.privateCloudDatabase`. Los snapshots contienen únicamente un ID aleatorio de instalación, nombre del dispositivo elegido por el usuario, tipo, porcentaje, estado de carga, fuente y timestamp.

No se almacenan seriales, Apple ID, IMEI ni identificadores privados del hardware.
