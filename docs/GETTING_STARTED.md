
# PowerMesh — Getting started / Primeros pasos

[English](#english) · [Español](#español)

---

# English

## Clone

```bash
git clone https://github.com/tiburonns/PowerMesh.git
cd PowerMesh
open PowerMesh.xcodeproj
```

Targets: `PowerMesh`, `PowerMeshWatch`, `PowerMeshWidgets`. Minimums: iOS/iPadOS 17, macOS 14, watchOS 10.

## Before membership

Use **PowerMesh Local** for iPhone/iPad/Mac and **PowerMeshWatch Local** for Apple Watch. Their `DebugLocal` configurations use separate `.local` bundle identifiers and don't attach CloudKit/App Group entitlement files. Use them for UI, local battery, language, history, and basic behavior tests before paid-team provisioning.

## Signed ecosystem setup

1. Select the same Apple Developer Team for `PowerMesh`, `PowerMeshWatch`, and `PowerMeshWidgets`.
2. Enable CloudKit with `iCloud.com.tiburonns.PowerMesh` on app and Watch.
3. Enable App Groups with `group.com.tiburonns.PowerMesh` on app, Watch, and widget extension.
4. Keep iOS Background Modes: **Background fetch** and **Remote notifications**.
5. Let Xcode refresh provisioning.
6. Install on iPhone/iPad, Mac, and Apple Watch using the same iCloud account.
7. Add a PowerMesh widget and Watch complication after the apps have written their first cache.

## Optional Bluetooth

In Settings enable **Compatible Bluetooth batteries**. PowerMesh scans only for accessories exposing the public standard Battery Service.

## Languages

Settings offers **System**, **English**, **Español**. The preference is mirrored to the shared widget cache.

## Release validation

Follow `docs/TESTING.md`.

---

# Español

## Clonar

```bash
git clone https://github.com/tiburonns/PowerMesh.git
cd PowerMesh
open PowerMesh.xcodeproj
```

Targets: `PowerMesh`, `PowerMeshWatch` y `PowerMeshWidgets`. Mínimos: iOS/iPadOS 17, macOS 14 y watchOS 10.

## Antes de la membresía

Usa **PowerMesh Local** para iPhone/iPad/Mac y **PowerMeshWatch Local** para Apple Watch. Sus configuraciones `DebugLocal` usan bundle identifiers `.local` separados y no conectan entitlements CloudKit/App Group. Sirven para UI, batería local, idioma, historial y comportamiento básico antes del aprovisionamiento de pago.

## Configuración firmada

1. Selecciona el mismo Team Apple Developer en `PowerMesh`, `PowerMeshWatch` y `PowerMeshWidgets`.
2. Habilita CloudKit con `iCloud.com.tiburonns.PowerMesh` en app y Watch.
3. Habilita App Groups con `group.com.tiburonns.PowerMesh` en app, Watch y widgets.
4. Mantén Background Modes de iOS: **Background fetch** y **Remote notifications**.
5. Deja que Xcode regenere el aprovisionamiento.
6. Instala en iPhone/iPad, Mac y Apple Watch con la misma cuenta iCloud.
7. Añade widget y complication después del primer caché.

## Bluetooth opcional

En Configuración activa **Baterías Bluetooth compatibles**. PowerMesh solo busca accesorios que exponen Battery Service estándar público.

## Idiomas

Configuración ofrece **Sistema**, **English**, **Español** y copia la preferencia al caché de widgets.

## Validación

Sigue `docs/TESTING.es.md`.
