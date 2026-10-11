# ADR 007 — Alta directa desde identidad confirmada

Fecha: 2026-10-11. Decisión de producto autorizada en `docs/specs/save-plant.md` y conversación posterior. Implementación pendiente de validación independiente.

## Contexto

El usuario rechaza la revisión intermedia, un formulario previo y una segunda confirmación de alta. Confirmar especie debe expresar la intención humana de incorporar ese ejemplar si se obtienen seis cuidados válidos. Esta decisión sustituye la revisión efímera de ADR 006; el ADR y las specs históricas permanecen intactos.

## Decisión

`IdentificationPhotoView → IdentificationPhotoViewModel → SaveConfirmedPlantUseCase → PreparedPlantPhotoValidating + SavePlant → PlantRepository ← LocalPlantRepository`. App compone el mismo repositorio local para lista, detalle, edición y alta, después de cualquier override Debug. No hay nueva entidad ni migración. Domain reutiliza identidad confirmada, fotografía preparada y CareSheet; no importa ImageIO/SwiftUI/SwiftData.

La intención existente Confirmar especie genera cuidados mediante la barrera v4 y pasa directamente a prevalidación/commit, sin publicar una vista de cuidados o resumen. La ayuda junto al botón explica el alta. Selección sola nunca invoca ni guarda; manual conserva su disponibilidad exclusivamente tras identificación exitosa vigente.

El snapshot inmutable contiene UUID nuevo distinto de foto, fecha local finita, foto, identidad y seis cuidados completos. IA usa nombre común o científico como fallback; especie plana `común (científico)` cuando ambos difieren. Manual conserva texto humano tras trim. Ubicación nil; personalización posterior mediante EditPlant. La procedencia no se finge persistida en el modelo plano existente.

Se adoptan los mismos bytes JPEG de LocalIdentificationPhotoPreparer: primer frame, orientación aplicada, sin ampliar, lado ≤2048, alfa blanco, calidad .85, ≤5 MiB, sin EXIF/GPS/orientación original. LocalPreparedPlantPhotoValidator valida tipo, límites, dimensiones reales, marcadores/estado completo, decode y metadata fuera de MainActor antes de IO. No hay segunda compresión, recorte ni reimportación. Originals picker/UIImage pueden materializarse completos; no se garantiza memoria constante, cámara física ni descarga iCloud.

Presentation permite cancelar generación/prevalidación. `willCommit` valida token/foto/identidad/cancelación en MainActor y bloquea cierre/gesto/cambios antes de despachar SavePlant. Una escritura despachada se reconoce al resolver, sin guard de cancelación posterior que oculte éxito. LocalPlantRepository conserva su tramo actor sin suspensión, rollback y limpieza de huérfanos; no es atomicidad física ni exact-once multiproceso.

Error de cuidados ofrece retry remoto explícito. Error local conserva snapshot/UUID/fecha/bytes y ofrece Reintentar guardado sin IA/config/consentimiento nuevos. Editar oculta elegibilidad; cancelar edición restaura el fallo sin escribir. Reconfirmar o publicar foto B invalida snapshot; fallo de reemplazo conserva A. DuplicateID se reconcilia únicamente si metadata completa y foto coinciden exactamente; conflicto nunca sobrescribe ni cambia UUID para fingir éxito.

Callback MainActor exactamente una vez, antes de dismiss: listado aplica por UUID y mantiene tarjetas/imágenes previas, orden createdAt y UUID para empate; invalida lecturas antiguas. Si lista no estaba completa, refresca toda metadata sin fotos y no declara una lista parcial completa. Error de lectura requiere retry de lectura, no de alta. Colección vuelve desplazada a tarjeta nueva, sin abrir detalle automáticamente.

## Consecuencias

No revisión botánica antes de alta: seis textos completos son validación estructural, no garantía de verdad. Los cuidados orientativos se consultan en detalle por navegación voluntaria. No historial nuevo, formularios, geolocalización, cuentas, sincronización ni otra feature. Terminar después de commit conserva alta al reabrir; borrador fallido no se restaura entre procesos. Fixtures opt-in Debug Simulator no acreditan API real ni cámara.
