# ADR 008: eventos locales de cuidado y upgrade aditivo

Fecha: 2026-10-11. Ámbito: quick-watering; autoverificación no equivale a aceptación independiente.

## Decisión

CareEvent persiste exactamente id/plantID/kind/occurredAt/note/createdAt/timeZoneIdentifier. Kind actual: `watering`. PlantRepository no se amplía; CareEventRepository es una frontera propia, implementada por el mismo actor LocalPlantRepository, contexto, container y Plants.store. No relaciones/cascadas ni cambios de identidad/campos de PersistedPlant. No IO fotográfico nuevo al insertar eventos.

V1 es el schema no versionado con solo PersistedPlant. V2 añade PersistedCareEvent mediante migración ligera automática SwiftData. `LocalCareEventRepositoryTests.testRealDiskV1UpgradeThenSevenFieldRoundtripIsolationAndSecondIntention` genera V1 real en disco, libera container/context, abre V2, verifica dos Plant completos/JPEG exactos/cero eventos, registra dos intenciones y reabre los siete campos. La primera ejecución focalizada pasó en Xcode26.2/iOS26.2; la evidencia final se registra en el handoff. No reset, fallback en memoria ni cambio de ruta. Un fallo de apertura/validación propaga error antes de limpiar huérfanos. No se promete downgrade.

## Atomicidad e identidad

Fetch planta/duplicado → validar → insert → seams síncronas → context.save sin await. Rollback en error; save es la frontera de commit. Duplicado canónico compara los siete campos antes de validar contra reloj fresco: éxito sin save si coinciden; conflicto si difieren, incluso solo zona con offset equivalente. No upsert ni deduplicación por día. Una nueva intención humana obtiene UUID nuevo. Un escritor por store, no exact-once multiproceso.

Nota canónica se compara literalmente por UTF8: `String ==` acepta secuencias Unicode canónicamente equivalentes pero distintas; no debe ocultar un payload diferente con el mismo UUID. Trim no normaliza interiores ni Unicode. Fixture también compara esos bytes, no solo equivalencia visual.

La VM bloquea antes de await y conserva snapshot inmutable tras fallo. Retry no recaptura UUID/fecha/zona/nota; editar crea intención nueva. Callback una vez tras éxito real; cancelación técnica tardía no convierte commit en error. No compensar eliminando un evento confirmado. Borrador, retry y banner no se restauran entre procesos.

## Tiempo y nota

occurredAt es instante absoluto de inicio del día gregoriano en zona IANA capturada al abrir/elegir; createdAt es primer despacho real. Ayer usa resta de día de calendario, no86400. Días civiles omitidos se rechazan por componentes; DST usa startOfDay. Validación estructural en Domain y Data; nueva inserción no futura con reloj fresco en origen. Duplicado confirmado puede reconciliarse aunque retroceda el reloj. Lectura no compara contra hoy.

Visualización en zona ACTUAL explícita: puede cambiar el día al viajar, sin reescribir instante/origen ni crear intención. Siguiente elección humana captura zona nueva; retry conserva la original. Se rechazan abreviaturas, offsets e identificadores desconocidos. Nota trim de extremos/blanca→nil; interior, Unicode y longitud intactos. No recomendaciones, IA, última fecha ni historial nuevo.

## Consecuencias

La tabla aditiva conserva upgrade de V1 demostrado para el runtime probado, no garantía universal frente a daño físico. Futuros tipos/historial/eliminación son features separadas; no interpretar CareSheet.watering (texto orientativo) como evento. Fixture WateringTestFixture solo Debug Simulator, UUID aislado, captura payload despachado y compara siete campos tras relaunch; no UI de historial ficticia.
