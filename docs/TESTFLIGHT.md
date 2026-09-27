# PowerMesh TestFlight preflight / Preflight de TestFlight

## English

PowerMesh 0.2.0 (build 14) must pass its static contract, strict-concurrency/warning-free Debug matrix, and Release iOS/macOS/watchOS/widget matrix before a signed build is treated as a release candidate.

### Apple capability setup

Before Archive, configure the paid Developer Team so the production profiles contain:

- `iCloud.com.tiburonns.PowerMesh` with CloudKit;
- `group.com.tiburonns.PowerMesh`;
- production APNs for the iOS and Watch targets;
- the matching widget/App Group entitlements.

Do not use the Local schemes as proof of production provisioning: those schemes intentionally remove paid capabilities.

### Physical ecosystem acceptance

- iPhone/iPad local battery and freshness timestamps.
- iPhone ↔ Mac ↔ Watch private CloudKit synchronization.
- Silent CloudKit push/change refresh.
- App Group cache from the installed iOS/macOS widget.
- Watch complication/WidgetKit data.
- Background refresh behavior over several hours.
- Low-battery local notifications and deduplication.
- A real BLE accessory that publicly exposes Battery Service 180F / Battery Level 2A19.
- Signed-out/unavailable iCloud and revoked Bluetooth permission paths.
- English, Spanish, and System language behavior.

### Archive / TestFlight

1. Merge only after all required checks are green.
2. Open `PowerMesh.xcodeproj`.
3. Select your paid Team and confirm production capabilities.
4. Archive the `PowerMesh` iOS destination.
5. Organizer > Validate App.
6. Upload to App Store Connect and start Internal Testing.
7. Install the Watch app/widget through the TestFlight build and repeat the ecosystem acceptance matrix.

The source does not claim access to proprietary AirPods/Apple Pencil battery APIs; only public BLE Battery Service accessories are in scope.

---

## Español

PowerMesh 0.2.0 (build 14) debe pasar contrato estático, matriz Debug con strict concurrency/warnings-as-errors y la matriz Release de iOS/macOS/watchOS/widgets antes de tratarlo como candidato firmado.

### Capabilities

Antes del Archive configura el Team de pago con:

- `iCloud.com.tiburonns.PowerMesh` + CloudKit;
- `group.com.tiburonns.PowerMesh`;
- APNs de producción para iOS/Watch;
- entitlements correspondientes de widgets/App Group.

Los schemes Local eliminan estas capabilities intencionalmente y no validan provisioning de producción.

### Aceptación física

- Batería local y timestamps en iPhone/iPad.
- Sincronización privada iPhone ↔ Mac ↔ Watch mediante CloudKit.
- Push/cambios silenciosos.
- Caché App Group desde widgets instalados.
- Complication/WidgetKit en Watch.
- Refresh en segundo plano durante varias horas.
- Notificaciones de batería baja.
- Accesorio BLE real con Battery Service 180F / 2A19.
- Rutas sin iCloud y permiso Bluetooth revocado.
- Sistema, English y Español.

### Archive / TestFlight

1. Merge sólo con checks verdes.
2. Abre `PowerMesh.xcodeproj`.
3. Selecciona el Team de pago y confirma capabilities.
4. Archive del destino iOS `PowerMesh`.
5. Organizer > Validate App.
6. Sube a App Store Connect e inicia Internal Testing.
7. Instala Watch/widget desde la build de TestFlight y repite la matriz.

PowerMesh no afirma acceso a APIs privadas de batería de AirPods/Apple Pencil.
