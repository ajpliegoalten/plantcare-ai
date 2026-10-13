# ADR015 — Eliminación local de un ejemplar

Fecha: 2026-10-13. Decisión aprobada en `docs/specs/delete-plant.md`.

`PlantDetailView → PlantDetailViewModel → DeletePlantUseCase → PlantDeletingRepository ← LocalPlantRepository`.
Domain Foundation añade escritor estrecho; sin no-ops en lectores ni schema nuevo. App conecta el mismo actor tras overrides.
Snapshot Plant completo vigente; Data revalida los cuatro conjuntos, pertenencias/referencias/análisis, incluso con contexto cacheado.
Ausencia/conflicto/lectura fallida no son éxito. La intención autoriza todos los hijos vigentes al commit, no inventario UI antiguo.

Delete/save síncrono sin suspensión elimina planta/ficha embebida, cuidados, adicionales y definitivos iniciales/adicionales.
Fallo pre-save hace rollback y conserva JPEG. Solo este flujo elimina inicial/definitivo; ADR012 sigue protegiéndolos en historial.
Post-save intenta cada ruta JPEG propia validada independientemente; cleanup no revierte commit ni ofrece retry destructivo.
Apertura recupera huérfanos después de validar TODAS las entidades, antes de tocar ambos directorios.
Sin borrado de carpetas/Fotos/config/consentimiento/backups/remotos, borrado seguro ni transacción distribuida.
Un actor escritor, sin multiproceso; validación global O(n) apta para prototipo.

Pie rojizo después de leyenda, alerta iOS Cancelar/Eliminar. Snapshot/binding separados. Commit retiene owner, reconoce éxito
una vez aunque desaparezca, bloquea acciones/back/gesto y no navega optimistamente. Storage conserva intención para retry literal;
×/Cancelar abandonan. Lectura/conflicto/ausencia requieren Releer y nueva confirmación, sin prometer JPEG sano.
Terminal invalida generaciones/sesiones/fotos/resumen. Callback retira solo UUID propio de lista/cards, conserva otros consumidores,
publica evento UUID al dueño del NavigationPath para raíz sin toast. Lista no loaded relee completa fail-closed,
reconciliando por UUID para conservar consumidores/imagen/resumen de B aun si ya había tarjetas retenidas antes de la relectura.
No compensación de commit exitoso por cierre. E2E Debug Simulator opt-in UUID verifica entidades/bytes y ausencia al relanzar.
Implementer verifica por impacto; validator posee gate final. Evidencia en handoff, no en esta decisión.
