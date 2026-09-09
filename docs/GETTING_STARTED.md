# PowerMesh — Getting started / Primeros pasos

[English](#english) · [Español](#español)

---

# English

## Clone and open

```bash
git clone https://github.com/tiburonns/PowerMesh.git
cd PowerMesh
open PowerMesh.xcodeproj
```

The repository includes a real Xcode project. You do not need to create targets manually.

## Targets

- `PowerMesh`: iPhone, iPad, and native macOS.
- `PowerMeshWatch`: Apple Watch.

Minimum versions for the first MVP are iOS/iPadOS 17, macOS 14, and watchOS 10.

## First test without CloudKit

For the fastest smoke test, select the `PowerMesh` scheme and run it on **My Mac** or an iPhone/iPad simulator. The app can read/display the current device battery where the simulator/platform exposes it. CloudKit synchronization may show an error until signing and the iCloud capability are configured.

On macOS you can also run:

```bash
bash script/build_and_run.sh
```

That helper intentionally builds without code signing so a clone can be compile-tested before configuring an Apple Developer team. CloudKit is not expected to work in that unsigned run.

## Enable real cross-device CloudKit sync

To test iPhone + iPad + Mac + Apple Watch together:

1. Open `PowerMesh.xcodeproj`.
2. Select the `PowerMesh` target → **Signing & Capabilities**.
3. Select your Apple Developer team.
4. Add the **iCloud** capability.
5. Enable **CloudKit**.
6. Use the container `iCloud.com.tiburonns.PowerMesh` (or replace it consistently if your account requires another identifier).
7. Repeat the same capability/container setup for `PowerMeshWatch`.
8. Run every installation while signed into the same iCloud account.

The repository includes `PowerMesh/PowerMesh.entitlements` and `PowerMesh/PowerMeshWatch.entitlements` as the canonical entitlement templates. Once your developer account/container is ready, set each target's `Code Signing Entitlements` build setting to the corresponding file if Xcode did not do that automatically.

> iCloud/CloudKit capability availability depends on the Apple Developer account used for signing. A build can be tested locally without it, but cross-device synchronization requires a valid signed configuration.

## Language test

Open Settings in PowerMesh and test all three choices:

- System
- English
- Español

The selection persists between launches.

## Recommended first physical-device test

1. Mac: run PowerMesh and rename it `Test Mac`.
2. iPhone: run the same project with the same iCloud account.
3. Tap refresh on both devices.
4. Confirm both devices appear in the battery dashboard.
5. Change the app language on one device and confirm it does not change the language preference on the other device.

---

# Español

## Clonar y abrir

```bash
git clone https://github.com/tiburonns/PowerMesh.git
cd PowerMesh
open PowerMesh.xcodeproj
```

El repositorio ya incluye un proyecto real de Xcode. No tienes que crear los targets manualmente.

## Targets

- `PowerMesh`: iPhone, iPad y macOS nativo.
- `PowerMeshWatch`: Apple Watch.

Las versiones mínimas del primer MVP son iOS/iPadOS 17, macOS 14 y watchOS 10.

## Primera prueba sin CloudKit

Para la prueba más rápida, selecciona el esquema `PowerMesh` y ejecútalo en **My Mac** o en un simulador de iPhone/iPad. La app puede leer/mostrar la batería del dispositivo actual cuando la plataforma o el simulador la exponga. La sincronización de CloudKit puede mostrar un error hasta que configures la firma y la capacidad de iCloud.

En macOS también puedes ejecutar:

```bash
bash script/build_and_run.sh
```

Ese script compila intencionalmente sin firma para que un clon pueda verificarse antes de configurar un equipo de Apple Developer. CloudKit no debe esperarse que funcione en esa ejecución sin firma.

## Activar la sincronización real con CloudKit

Para probar iPhone + iPad + Mac + Apple Watch juntos:

1. Abre `PowerMesh.xcodeproj`.
2. Selecciona el target `PowerMesh` → **Signing & Capabilities**.
3. Selecciona tu equipo de Apple Developer.
4. Agrega la capacidad **iCloud**.
5. Activa **CloudKit**.
6. Usa el contenedor `iCloud.com.tiburonns.PowerMesh` (o reemplázalo de forma consistente si tu cuenta requiere otro identificador).
7. Repite la misma configuración de capacidad/contenedor para `PowerMeshWatch`.
8. Ejecuta todas las instalaciones usando la misma cuenta de iCloud.

El repositorio incluye `PowerMesh/PowerMesh.entitlements` y `PowerMesh/PowerMeshWatch.entitlements` como plantillas canónicas. Cuando tu cuenta/contenedor estén listos, configura `Code Signing Entitlements` de cada target con su archivo correspondiente si Xcode no lo hace automáticamente.

> La disponibilidad de iCloud/CloudKit depende de la cuenta de Apple Developer usada para firmar. Puedes probar la compilación local sin ella, pero la sincronización entre dispositivos requiere una configuración firmada válida.

## Prueba de idiomas

Abre Configuración en PowerMesh y prueba las tres opciones:

- Sistema
- English
- Español

La selección se conserva entre aperturas.

## Primera prueba recomendada con dispositivos físicos

1. Mac: ejecuta PowerMesh y renómbrala `Mac de prueba`.
2. iPhone: ejecuta el mismo proyecto usando la misma cuenta de iCloud.
3. Pulsa actualizar en ambos dispositivos.
4. Confirma que ambos aparezcan en el dashboard de baterías.
5. Cambia el idioma de la app en un dispositivo y confirma que no cambia la preferencia de idioma del otro.
