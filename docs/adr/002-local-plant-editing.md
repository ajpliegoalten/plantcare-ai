# ADR 002 — Edición local estrecha y coherencia de snapshots

Fecha: 2026-10-10. Implementada según spec aprobada; pendiente validación independiente.

## Contexto

Nombre y ubicación ya existen en SwiftData; savePlant crea y rechaza duplicados. Detalle y colección retienen snapshots por UUID e imágenes preparadas que no deben perderse por una edición.

## Decisión

Añadir `updatePlant(id:name:location:) -> Plant`, sin Plant completo ni upsert. `UpdatePlant` centraliza recorte exterior, nombre obligatorio y ubicación blanca a nil; Data también valida invocaciones directas. El actor modifica solo dos campos y confirma explícitamente sin suspensiones, usando el seam beforeCommit y rollback. UUID desconocido es notFound, no alta. No escribe/lee/repara fotografías.

El resultado canónico confirmado se aplica al detalle y mediante callback MainActor débil al listado; card metadata observable conserva VM, imagen y tarea. Generaciones impiden que metadata anterior revierta el resultado. Borradores de sheet independientes, guardar único, sin autosave; cancelar/gesto descartan antes del commit y están temporalmente bloqueados durante él.

## Consecuencias y migración

No cambia esquema ni necesita migración. Se amplía contrato compartido y todos los doubles deben implementarlo explícitamente. No se incorpora event bus ni dependencia Domain → Presentation. Conserva actor único por almacén y límites de disco/JPEG del ADR 001. Las pruebas cubren rollback, reapertura y modelos/bytes completos; no equivalen a fallo físico de disco.
