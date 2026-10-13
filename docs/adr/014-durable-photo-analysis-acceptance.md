# ADR014 — Aceptación durable sobre una fotografía existente

## Decisión (keep-analysis, 2026-10-13)

Guardar análisis es una intención local explícita, independiente del éxito remoto de ADR013. `KeepPlantPhotoAnalysis` valida un snapshot inmutable: UUID de aceptación, planta, identidad discriminada, descriptor origen, fecha de foto, consulta, revisión, aceptación y contenido estructurado literal. Evidencia insuficiente no es guardable.

El mismo actor `LocalPlantRepository` incorpora `PersistedPlantPhotoAnalysis` al schema documental V4 aditivo, con autosave desactivado. Valida registros, vínculos y unicidad antes de limpiar JPEG. Lookup, revalidación del descriptor, insert y save no suspenden. Un UUID y payload completos idénticos devuelve el registro canónico; otra aceptación de la misma foto o payload diferente produce conflicto, sin overwrite. Fallo precommit revierte contexto. Guardar no lee ni copia JPEG, no altera planta/ficha/cuidados/fecha/portada.

`SavedPlantPhotoAnalysisReading` alimenta UI; adaptación explícita `AcceptedPlantPhotoAnalysisReading` aporta solo texto y fecha de origen al constructor contextual existente. La composición real, incluyendo proveedor Debug, conecta ambos lectores al mismo actor. Errores no representan ausencia. `PlantTimelineSnapshot` asocia textos por identidad a hitos existentes, sin entidad ni fila nueva. El protocolo de timeline conserva su lectura de entradas y añade snapshot; el default mantiene compatibilidad de dobles antiguos sin capacidad de análisis, no sustituye al lector real de producción.

Modal: snapshot una vez, retry solo local con el mismo UUID/fechas; resultado retenido ante fallo. Busy bloquea cierres/gesto/doble despacho. Resultado canónico notifica consumidores retenidos antes de dismiss; un refresh fallido no revierte ni transforma el commit en fallo de guardado. Error de origen/conflicto/lectura requiere nueva intención, no retry ciego. No toast.

Una adicional eliminada retira su análisis en el mismo save de metadata; rollback conjunto. Cleanup JPEG posterior sigue best-effort de ADR012; no reinserta metadata. Inicial continúa protegida. Alerta advierte la cascada solo cuando hay texto guardado asociado.

## Consecuencias y límites

- Un definitivo por planta/identidad; sin reanálisis, reemplazo ni delete independiente de análisis.
- Texto íntegro bajo foto/placeholder o miniatura inicial: orientación, no diagnóstico ni cuidado realizado.
- Fechas de origen/consulta/aceptación distintas; contexto usa origen y conserva presupuestos ADR013.
- Upgrade aditivo automático; evidencia de disco no garantiza downgrade/daño físico/multiproceso.
- Snapshot compuesto por lecturas secuenciales; un actor por almacén, sin escritores externos simultáneos.
- Metadata/frames O(n), JPEG viewport/cache3/concurrencia2 intactos, sin garantía de escala/memoria constante.
- Cierre sin guardar libera provisional; Descarta permanece inactivo y pendiente.
