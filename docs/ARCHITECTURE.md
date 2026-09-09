# PowerMesh architecture / Arquitectura de PowerMesh

[English](#english) · [Español](#español)

---

# English

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

The private CloudKit database is the shared source of truth for cross-device snapshots. Each installation owns exactly one stable `device-<UUID>` record.

The local UI merges its freshly read snapshot before the network round trip so the current device does not appear stale while CloudKit is being updated.

## Freshness model

A snapshot is considered stale after 30 minutes. This is intentionally explicit because iOS, iPadOS, and watchOS do not allow arbitrary continuous background execution.

## Localization architecture

The user's language preference is stored with `@AppStorage` under the `appLanguage` key.

Supported choices are:

- `system`
- `english`
- `spanish`

`PowerMeshApp` injects both the selected `AppLanguage` and its corresponding SwiftUI `Locale` into the environment. Views obtain all user-facing copy from `AppLanguage.text(_:)`, while model display labels such as charge state are resolved using the same language context.

When `system` is selected, PowerMesh currently resolves Spanish system locales to Spanish and uses English as the fallback for other locales. This keeps behavior deterministic until additional translations are added.

This centralized layer also prevents CloudKit/service errors from being permanently stored as already-localized UI strings: the store retains the technical error detail and the view adds the localized explanation at render time.

See `LOCALIZATION.md` for the full contribution policy.

## Privacy model

No custom account system and no external server are required for the MVP. Data remains in the user's private CloudKit database.

## Planned modules

- Complete Xcode project and target configuration
- Background refresh coordinator
- CloudKit subscriptions
- Widget shared cache / App Group
- WidgetKit targets
- watchOS complication
- Battery history
- Threshold alerts
- BLE accessory provider
- Additional localizations

---

# Español

## Objetivo

Ofrecer un único dashboard de batería para los dispositivos Apple del usuario sin depender de un backend propio.

## Flujo de datos

```text
API local de batería
      ↓
LocalBatteryReader
      ↓
BatterySnapshot
      ↓
BatteryDashboardStore
      ↓
CloudBatteryStore
      ↓
Base privada de CloudKit
      ↓
Otras instalaciones de PowerMesh
```

## Fuente de verdad

La base privada de CloudKit es la fuente de verdad compartida para los snapshots entre dispositivos. Cada instalación posee exactamente un registro estable `device-<UUID>`.

La interfaz local combina primero su snapshot recién leído, antes del viaje de red, para que el dispositivo actual no parezca desactualizado mientras CloudKit termina de sincronizarse.

## Modelo de vigencia

Un snapshot se considera antiguo después de 30 minutos. Esto se muestra de forma explícita porque iOS, iPadOS y watchOS no permiten una ejecución continua arbitraria en segundo plano.

## Arquitectura de localización

La preferencia de idioma del usuario se guarda con `@AppStorage` usando la clave `appLanguage`.

Las opciones admitidas son:

- `system`
- `english`
- `spanish`

`PowerMeshApp` inyecta al entorno tanto el `AppLanguage` seleccionado como su `Locale` de SwiftUI correspondiente. Las vistas obtienen todo el texto visible mediante `AppLanguage.text(_:)`, mientras que etiquetas de modelo como el estado de carga se resuelven usando el mismo contexto de idioma.

Cuando se selecciona `system`, PowerMesh actualmente resuelve los sistemas en español a español y utiliza inglés como alternativa para los demás idiomas. Esto mantiene un comportamiento determinista hasta que se añadan más traducciones.

La capa centralizada también evita almacenar errores de CloudKit/servicios como cadenas ya traducidas: el store conserva el detalle técnico y la vista añade la explicación localizada al momento de renderizar.

Consulta `LOCALIZATION.md` para la política completa de contribución.

## Modelo de privacidad

El MVP no requiere sistema de cuentas propio ni servidor externo. Los datos permanecen en la base privada de CloudKit del usuario.

## Módulos planeados

- Proyecto Xcode completo y configuración de targets
- Coordinador de actualización en segundo plano
- Suscripciones de CloudKit
- Cache compartida / App Group para widgets
- Targets de WidgetKit
- Complication de watchOS
- Historial de batería
- Alertas por umbral
- Proveedor BLE para accesorios
- Localizaciones adicionales
