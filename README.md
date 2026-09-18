# PowerMesh

[English](#english) · [Español](#español)

PowerMesh is a multilingual SwiftUI app that aims to show the battery status of a user's Apple ecosystem in one place. / PowerMesh es una app SwiftUI multilingüe cuyo objetivo es mostrar en un solo lugar la batería del ecosistema Apple de un usuario.

---

# English

## Current status

> **Current `main`: 0.1.4 (build 5).** This is an active development build; physical CloudKit validation is still part of the acceptance process.

PowerMesh now ships as a **real clonable Xcode project**.

```bash
git clone https://github.com/tiburonns/PowerMesh.git
cd PowerMesh
open PowerMesh.xcodeproj
```

You do not need to create a project or targets manually.

### Xcode targets

- `PowerMesh`: iPhone, iPad, and native macOS.
- `PowerMeshWatch`: Apple Watch.

### Current MVP features

- iPhone / iPad local battery through `UIDevice`.
- Apple Watch local battery through `WKInterfaceDevice`.
- Mac battery through IOKit / `IOPowerSources`.
- Desktop Macs represented as externally powered devices without an internal battery.
- Private CloudKit snapshot model for cross-device synchronization.
- Stable per-device identity stored in Keychain, with automatic migration from earlier UserDefaults IDs.
- Deterministic reconciliation that keeps the current device authoritative while deduplicating remote CloudKit snapshots.
- Settings cleanup for obsolete remote device snapshots.
- Shared SwiftUI battery dashboard.
- macOS menu-bar view.
- Stale-data indication instead of pretending old snapshots are real-time values.
- App language selector with **System**, **English**, and **Español**.
- Bilingual GitHub documentation in English and Spanish.

## First test

For a fast compile/UI smoke test, open `PowerMesh.xcodeproj`, select the `PowerMesh` scheme, and run it on **My Mac** or an iPhone/iPad simulator.

On macOS you can also run:

```bash
bash script/build_and_run.sh
```

This helper builds without code signing, so CloudKit is not expected to work in that unsigned test.

For complete setup, signing, CloudKit, Watch, and physical-device instructions, read:

**`docs/GETTING_STARTED.md`** y la puerta de release en dispositivos firmados de **`docs/TESTING.es.md`** and the signed-device release gate in **`docs/TESTING.md`**

## Real cross-device synchronization

To make iPhone, iPad, Mac, and Apple Watch publish to the same battery dashboard, configure both targets with the same Apple Developer team and the same private CloudKit container.

The repository includes the entitlement files used by the targets:

- `PowerMesh/PowerMesh.entitlements`
- `PowerMesh/PowerMeshWatch.entitlements`

Configured container:

`iCloud.com.tiburonns.PowerMesh`

The Xcode project wires these entitlements into the main and Watch targets. Unsigned smoke-test builds can still compile with `CODE_SIGNING_ALLOWED=NO`, but CloudKit synchronization requires valid signing/provisioning and the configured iCloud container on physical devices.

## CloudKit record

Record type: `BatterySnapshot`

Fields:

- `deviceID`: String
- `deviceName`: String
- `kind`: String
- `level`: optional Number
- `chargeState`: String
- `updatedAt`: Date/Time
- `source`: String

Each device uses a stable UUID stored in Keychain and publishes a `device-<UUID>` record in the user's private CloudKit database. Existing UserDefaults IDs migrate automatically.

## Language policy

The app must always provide:

1. **System**
2. **English**
3. **Español**

All user-facing strings go through `PowerMesh/Support/AppLanguage.swift`. English is currently the fallback for unsupported system languages.

All project-owned GitHub documentation must be maintained in English and Spanish. See `docs/LOCALIZATION.md`.

## Important accessory limitation

PowerMesh does not use private Apple APIs. AirPods, Apple Pencil, and some other Apple accessories do not expose a general public API that lets third-party apps obtain every value visible in Apple's Batteries widget.

A future CoreBluetooth provider can support BLE accessories that expose public battery characteristics.

## Repository structure

```text
PowerMesh.xcodeproj/
PowerMesh/
├── App/
├── Models/
├── Services/
├── Support/
├── Views/
├── PowerMesh.entitlements
├── PowerMeshWatch.entitlements
└── PrivacyInfo.xcprivacy
script/
└── build_and_run.sh
docs/
├── ARCHITECTURE.md
├── GETTING_STARTED.md
├── LOCALIZATION.md
├── TESTING.md
└── TESTING.es.md
.github/workflows/
└── build.yml
```

## Quality status and roadmap

Automated CI now builds macOS, iOS, and watchOS and runs deterministic core tests for snapshot staleness, CloudKit reconciliation rules, and language behavior. Physical-device CloudKit behavior still requires signed-device validation because unsigned CI cannot exercise a user's private iCloud container.

Next priorities:

1. Complete a signed physical-device test matrix for iPhone/iPad ↔ Mac ↔ Apple Watch CloudKit synchronization.
2. Add CloudKit subscriptions and opportunistic background refresh.
3. Add WidgetKit for iPhone, iPad, and macOS.
4. Add an Apple Watch complication.
5. Add battery history and low-battery alerts.
6. Add public BLE accessory support where technically available.

## Privacy

The design uses the user's private CloudKit database and does not require a custom PowerMesh account or external PowerMesh server. Snapshots contain an installation ID, user-selected device name, device category, battery value, charging state, source, and timestamp.

PowerMesh does not intentionally store Apple IDs, IMEI values, serial numbers, or private hardware identifiers.

---

# Español

## Estado actual

> **`main` actual: 0.1.4 (build 5).** Es una compilación activa de desarrollo; la validación física de CloudKit sigue formando parte del proceso de aceptación.

PowerMesh ahora se entrega como un **proyecto real de Xcode que puedes clonar**.

```bash
git clone https://github.com/tiburonns/PowerMesh.git
cd PowerMesh
open PowerMesh.xcodeproj
```

No necesitas crear manualmente el proyecto ni los targets.

### Targets de Xcode

- `PowerMesh`: iPhone, iPad y macOS nativo.
- `PowerMeshWatch`: Apple Watch.

### Funciones actuales del MVP

- Batería local de iPhone / iPad mediante `UIDevice`.
- Batería local de Apple Watch mediante `WKInterfaceDevice`.
- Batería de Mac mediante IOKit / `IOPowerSources`.
- Macs de escritorio representadas como dispositivos con alimentación externa y sin batería interna.
- Modelo de snapshots en CloudKit privado para sincronización entre dispositivos.
- Identidad estable por dispositivo guardada en Keychain, con migración automática desde IDs anteriores en UserDefaults.
- Reconciliación determinista que mantiene al dispositivo actual como fuente autoritativa y elimina duplicados remotos de CloudKit.
- Limpieza desde Ajustes de snapshots obsoletos de dispositivos remotos.
- Dashboard SwiftUI compartido.
- Vista de barra de menús en macOS.
- Indicador de datos antiguos en lugar de presentar snapshots viejos como información en tiempo real.
- Selector de idioma con **Sistema**, **English** y **Español**.
- Documentación de GitHub bilingüe en inglés y español.

## Primera prueba

Para una prueba rápida de compilación/interfaz, abre `PowerMesh.xcodeproj`, selecciona el esquema `PowerMesh` y ejecútalo en **My Mac** o en un simulador de iPhone/iPad.

En macOS también puedes ejecutar:

```bash
bash script/build_and_run.sh
```

El script compila sin firma, por lo que CloudKit no debe esperarse que funcione durante esa prueba sin firma.

Para la configuración completa de firma, CloudKit, Watch y dispositivos físicos consulta:

**`docs/GETTING_STARTED.md`**

## Sincronización real entre dispositivos

Para que iPhone, iPad, Mac y Apple Watch publiquen en el mismo dashboard de batería, configura ambos targets con el mismo equipo de Apple Developer y el mismo contenedor privado de CloudKit.

El repositorio incluye los archivos de entitlements utilizados por los targets:

- `PowerMesh/PowerMesh.entitlements`
- `PowerMesh/PowerMeshWatch.entitlements`

Contenedor configurado:

`iCloud.com.tiburonns.PowerMesh`

El proyecto Xcode conecta estos entitlements a los targets principal y de Watch. Las pruebas de compilación sin firma pueden seguir usando `CODE_SIGNING_ALLOWED=NO`, pero la sincronización de CloudKit requiere firma/provisioning válidos y el contenedor de iCloud configurado en dispositivos físicos.

## Registro de CloudKit

Record type: `BatterySnapshot`

Campos:

- `deviceID`: String
- `deviceName`: String
- `kind`: String
- `level`: Number opcional
- `chargeState`: String
- `updatedAt`: Date/Time
- `source`: String

Cada dispositivo usa un UUID estable guardado en Keychain y publica un registro `device-<UUID>` en la base privada de CloudKit del usuario. Los IDs existentes de UserDefaults se migran automáticamente.

## Política de idiomas

La app siempre debe ofrecer:

1. **Sistema**
2. **English**
3. **Español**

Todos los textos visibles pasan por `PowerMesh/Support/AppLanguage.swift`. Actualmente inglés funciona como idioma alternativo para idiomas del sistema todavía no soportados.

Toda la documentación propia del proyecto en GitHub debe mantenerse en inglés y español. Consulta `docs/LOCALIZATION.md`.

## Limitación importante con accesorios

PowerMesh no utiliza APIs privadas de Apple. AirPods, Apple Pencil y algunos otros accesorios Apple no exponen una API pública general que permita a aplicaciones de terceros obtener todos los valores que aparecen en el widget Baterías de Apple.

Más adelante podremos agregar un proveedor CoreBluetooth para accesorios BLE que expongan públicamente características de batería.

## Estructura del repositorio

```text
PowerMesh.xcodeproj/
PowerMesh/
├── App/
├── Models/
├── Services/
├── Support/
├── Views/
├── PowerMesh.entitlements
└── PowerMeshWatch.entitlements
script/
└── build_and_run.sh
docs/
├── ARCHITECTURE.md
├── GETTING_STARTED.md
├── LOCALIZATION.md
├── TESTING.md
└── TESTING.es.md
.github/workflows/
└── build.yml
```

## Estado de calidad y próximos pasos

El CI automatizado ya compila macOS, iOS y watchOS y ejecuta pruebas deterministas de antigüedad de snapshots, reglas de reconciliación de CloudKit e idioma. El comportamiento real de CloudKit todavía requiere validación firmada en dispositivos físicos porque el CI sin firma no puede ejercer el contenedor privado de iCloud de un usuario.

Prioridades siguientes:

1. Completar una matriz de pruebas firmadas en dispositivos físicos para la sincronización iPhone/iPad ↔ Mac ↔ Apple Watch.
2. Agregar suscripciones de CloudKit y actualización oportunista en segundo plano.
3. Agregar WidgetKit para iPhone, iPad y macOS.
4. Agregar complication para Apple Watch.
5. Agregar historial de batería y alertas de batería baja.
6. Agregar soporte para accesorios BLE mediante APIs públicas cuando sea técnicamente posible.

## Privacidad

El diseño utiliza la base privada de CloudKit del usuario y no requiere una cuenta propia de PowerMesh ni un servidor externo de PowerMesh. Los snapshots contienen un ID de instalación, nombre elegido por el usuario, categoría del dispositivo, valor de batería, estado de carga, fuente y timestamp.

PowerMesh no almacena intencionalmente Apple IDs, IMEI, números de serie ni identificadores privados del hardware.
