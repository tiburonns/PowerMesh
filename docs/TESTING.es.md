# PowerMesh 0.2.0 — Plan de aceptación física del ecosistema

**Español** · [English](TESTING.md)

Este es el primer candidato donde las puertas de aceptación restantes requieren capacidades Apple firmadas y/o hardware físico.

## Registra el entorno

Anota SHA, build, Team Apple Developer, entorno CloudKit, cuenta iCloud, modelo/OS de iPhone/iPad, Mac/macOS, Apple Watch/watchOS y accesorio BLE usado.

## 1. Firma y capacidades

1. Usa el mismo Team para `PowerMesh`, `PowerMeshWatch`, `PowerMeshWidgets` y `PowerMeshWatchWidgets`.
2. Aprovisiona `iCloud.com.tiburonns.PowerMesh`.
3. Aprovisiona App Group `group.com.tiburonns.PowerMesh`.
4. Confirma Background Modes de iOS: Background fetch y Remote notifications.
5. Instala en iPhone/iPad, Mac y Watch.

Pasa si no existe error de aprovisionamiento, entitlement o instalación.

## 2. Fuentes locales

Comprueba porcentaje/estado en iPhone/iPad, Watch y Mac con batería. En Mac de escritorio debe aparecer alimentación externa sin inventar porcentaje.

## 3. Matriz CloudKit

Prueba iPhone ↔ Mac, iPhone ↔ Watch, iPad ↔ Mac y Watch ↔ Mac donde aplique.

1. Publica en A.
2. Actualiza B.
3. Verifica una sola tarjeta estable con nombre/tipo/nivel/estado/fuente/timestamp.
4. Renombra A y publica.
5. Reabre ambas apps.

Pasa si no aparecen IDs duplicados y gana el dato más reciente, salvo la lectura local autoritativa del dispositivo actual.

## 4. Cambios silenciosos de CloudKit

Tras abrir cada app al menos una vez:

1. Deja B en segundo plano/terminada según corresponda.
2. Cambia y publica A.
3. Observa la oportunidad normal de ejecución de B.
4. Abre B y comprueba el caché final.

Pasa si no hay crash y un push entregado provoca un fetch nuevo. No se exige entrega inmediata porque el sistema puede agrupar o retrasar pushes.

## 5. Segundo plano iOS/watchOS

Deja las apps en background durante tiempo realista y vuelve a abrir. En Watch prueba con y sin complication activa.

Pasa si las oportunidades concedidas mejoran la vigencia y PowerMesh nunca presenta como en vivo un dato viejo.

## 6. Widgets y complication

Añade widgets y una complication; cambia datos e idioma.

Pasa si el App Group alimenta ambas extensiones, sus timelines se actualizan eventualmente y el contenido propio de PowerMesh está localizado.

## 7. Historial y tendencia

Genera al menos 30 minutos de muestras de carga/descarga.

Pasa si el historial sobrevive reinicios, evita redundancia excesiva, la tendencia aparece solo con duración suficiente y el signo/ritmo es razonable.

## 8. Alertas de batería baja

Activa alertas, fija umbral, prueba batería baja desconectada, recupera/carga y vuelve a bajar.

Pasa si permiso y textos son correctos, las alertas se deduplican y la recuperación reinicia el estado.

## 9. Accesorio Bluetooth

Usa un periférico conocido con Battery Service `180F` y Battery Level `2A19`.

Pasa si el permiso está localizado, el escaneo es opt-in, aparece un porcentaje coherente, desactivar detiene el escaneo y el accesorio entra al pipeline de caché/historial/sync.

Que AirPods o Apple Pencil no aparezcan no es fallo salvo que ese dispositivo exponga públicamente el servicio estándar.

## 10. Vigencia y recuperación

Ejercita En vivo (<5m), Reciente (<30m), Desactualizado (<2h) y Sin conexión (≥2h), luego recupera red/iCloud.

Pasa si la UI es honesta, los errores no borran caché válido y la recuperación no duplica dispositivos.

## 11. Privacidad/cuentas

Cuando sea posible usa otra cuenta iCloud.

Pasa si los snapshots privados no cruzan cuentas y no aparecen Apple ID, IMEI, serie ni identificadores privados de hardware.

## Puerta de release

PowerMesh 0.2 pasa cuando todas las secciones aplicables aprueban en dispositivos físicos firmados. Todo fallo debe registrarse con plataforma, OS, commit exacto, extracto del error/log de Xcode y pasos de reproducción.
