# ADR 001 — Metadatos SwiftData y fotografías en archivos

Fecha: 2026-10-09. Estado: implementada según `local-plant-storage`, pendiente de validación independiente.

## Contexto y decisión

iOS 17+, datos privados por ejemplar, sin catálogo ni sincronización. Usamos SwiftData para identidad y ficha propia (seis campos), y archivos JPEG independientes para fotos iniciales. Solo la referencia UUID.jpg vive en SwiftData; Domain no conoce rutas ni SwiftData. Un actor por directorio serializa escritura, lectura y comprobación de UUID. La app no usa fallback vacío/en memoria ante errores.

Alternativas descartadas: bytes dentro de SwiftData (coste y precarga potencial), JSON por ejemplar o SQLite directo (no son la decisión de la spec), almacén temporal (no demuestra reapertura).

## Consistencia y consecuencias

Imagen validada → temporal `.pending` → movimiento sin sobrescribir → commit de metadatos. Ante error, rollback y compensación de archivos nuevos. Tras cierre abrupto entre publicación y commit, se eliminan fotos huérfanas/temporales en la próxima apertura **solo después** de leer y validar el almacén. No se elimina una referencia rota: cargar esa foto informa ausencia/corrupción. Listar solo carga metadatos. No hay transacción atómica entre disco y SwiftData ni garantía de recuperación frente a pérdida del dispositivo o daño físico.

Una instancia escritora por almacén; no soporta coordinación multiproceso ni varias instancias escritoras concurrentes. El futuro borrado deberá eliminar referencia y archivos asociados sin afectar a otras plantas. Los futuros eventos/fotos usarán pertenencia por UUID. Guardar fotos reales requiere primero pipeline documentado de orientación, reescalado, límites de dimensiones/bytes, codificación y memoria en `save-plant` y `add-plant-photo`; estos fixtures son JPEG pequeños.

## Evolución

No hay datos previos que migrar. Si cambia el modelo persistente, añadir esquema/migración SwiftData antes de publicar; si cambia el medio, importar UUID, fechas y copias de ficha y mover fotos conservando pertenencia, verificando bytes y referencias antes de retirar el almacén original. No usar una reinstalación destructiva como migración.
