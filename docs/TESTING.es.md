# PowerMesh 0.1.4 — Plan de aceptación física del ecosistema

**Español** · [English](TESTING.md)

El CI de PowerMesh valida la lógica determinista y compila macOS, iOS y watchOS. Una release todavía requiere pruebas firmadas en dispositivos físicos porque CloudKit privado, publicación desde watchOS, oportunidades de segundo plano y fuentes reales de batería no pueden demostrarse con CI sin firma.

## Puerta de release

Usa el commit exacto que se pretende publicar. Registra modelo/OS de iPhone o iPad, Mac/macOS, Apple Watch/watchOS, equipo Apple Developer, cuenta iCloud, entorno CloudKit, SHA del commit y build.

## Firma y CloudKit

1. Configura los targets `PowerMesh` y `PowerMeshWatch` con el mismo equipo Apple Developer.
2. Confirma que ambos usen `iCloud.com.tiburonns.PowerMesh` con CloudKit.
3. Instala en al menos un iPhone o iPad, un Mac y un Apple Watch con la misma cuenta iCloud.
4. Abre cada app una vez con conectividad disponible.

Resultado esperado: sin crash de CloudKit, sin error de entitlement y cada plataforma publica sin reemplazar el ID de otro dispositivo.

## Fuentes locales de batería

Comprueba en hardware real:

- iPhone/iPad: porcentaje y estado de carga coinciden con el sistema dentro de una ventana razonable.
- Apple Watch: la app del reloj publica su porcentaje y estado.
- Mac con batería: IOPowerSources se representa correctamente.
- Mac de escritorio sin batería interna: aparece con alimentación externa sin inventar un porcentaje.

## Matriz de sincronización

Prueba donde aplique: iPhone ↔ Mac, iPhone ↔ Watch, iPad ↔ Mac y Watch ↔ Mac.

1. Abre PowerMesh en A y publica/actualiza.
2. Abre PowerMesh en B con la misma cuenta iCloud.
3. Confirma que A aparezca en B con la misma identidad estable, nombre, tipo, nivel/estado, fuente y timestamp razonable.
4. Cambia un nombre editable, vuelve a publicar y confirma que el snapshot nuevo sustituya al anterior en vez de crear un duplicado.
5. Repite después de cerrar y volver a abrir ambas apps.

Resultado esperado: una tarjeta lógica por ID de instalación; el dato remoto más reciente gana salvo cuando el dispositivo actual publica su propio snapshot local autoritativo.

## Datos antiguos y modo sin conexión

1. Publica un dispositivo y deja de actualizarlo más tiempo que el umbral de antigüedad.
2. Abre otro cliente.
3. Confirma que el valor se marque como antiguo y no como tiempo real.
4. Desactiva temporalmente red/iCloud e intenta actualizar.
5. Recupera la conectividad y vuelve a actualizar.

Resultado esperado: los datos antiguos se distinguen, un error de sync no borra estado local válido y la recuperación no crea duplicados.

## Olvidar dispositivo

1. Desde Ajustes, olvida un dispositivo remoto obsoleto.
2. Confirma que desaparezca.
3. Reabre PowerMesh en otro cliente y revisa el resultado.
4. Reabre el dispositivo físico olvidado y publica de nuevo.

Resultado esperado: un dispositivo activo puede reaparecer con un snapshot nuevo y olvidar uno no daña los demás registros.

## Migración de identidad

Actualiza encima de una compilación que guardaba el ID estable en UserDefaults sin borrar datos.

Resultado esperado: el ID migra al Llavero, el dispositivo no aparece dos veces y los siguientes inicios conservan la misma identidad.

## Idioma e interfaz

Prueba **Sistema**, **English** y **Español** en iPhone/iPad, Mac y Watch donde esté disponible el selector. Revisa tarjetas, Ajustes, barra de menús, estados vacíos/error, carga y datos antiguos. La selección debe persistir al reabrir.

## Privacidad y separación de cuentas

Cuando sea posible usa dos cuentas iCloud distintas en dispositivos de prueba. La segunda no debe ver snapshots privados de la primera. Confirma que PowerMesh no requiera una cuenta propia y no exponga Apple ID, número de serie, IMEI ni identificadores privados de hardware.

## Resultado

El candidato pasa cuando las fuentes locales son correctas, CloudKit firmado sincroniza los dispositivos previstos, no se crean identidades duplicadas, el comportamiento antiguo/sin conexión es honesto, olvidar/migrar mantiene la integridad y la interfaz bilingüe es consistente.