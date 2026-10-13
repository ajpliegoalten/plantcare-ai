# ADR012 — Eliminación local estrecha de cuidados y fotos adicionales

## Decisión (2026-10-13)

La aprobación integral de `docs/specs/delete-care-event.md` autoriza ambos tipos, protege únicamente la inicial y no ofrece toast/Deshacer. La selección efímera del carrusel no convierte una adicional en portada.

Domain expone `CareEventDeletingRepository` y `PlantPhotoDeletingRepository` junto a los contratos existentes, segregados de lectura/alta: consumidores read-only y sus dobles no adquieren una escritura ficticia/default no-op. `DeleteCareEvent` recibe snapshot CareEvent; `DeletePlantPhoto` exige identidad `.additional` concordante con snapshot PlantPhoto, rechazando `.initial` antes del escritor. El resultado es el snapshot canónico eliminado. Ausente/ajeno/conflict no es éxito idempotente; no revalidar fechas históricas contra el reloj actual.

El mismo actor LocalPlantRepository localiza entidad propia por id Y plantID, valida planta/mapeo/referencia canónica y compara payload literal antes de mutar. SwiftData delete→seam→save es síncrono sin await/autosave; throw durante commit hace rollback. Lectura fallida tiene error diferenciado, no promete payload intacto sin comprobarlo. Ninguna operación toca Plant/CareSheet/otra entidad con UUID coincidente.

En foto, commit metadata precede cleanup best-effort exclusivamente `AdditionalPhotos/<photoID>.jpg`. JPEG ausente/corrupto no bloquea eliminación de metadata propia. Cleanup fallido no revierte commit ni ofrece retry de eliminación; deja huérfano para recuperación existente, que valida TODAS las entidades antes de ambos directorios. No schema/tombstone/transacción distribuida/borrado físico seguro de backups.

Presentation conserva intención discriminada/confirmación/commit/fallo por separado de metadata. Cancelar/× abandonan snapshot y retry; otra intención exige confirmar. Commit único no es optimista, ni cancelable al desaparecer; back/gesto nativos se bloquean solo mientras está activo. Lecturas anteriores se invalidan, foreground se difiere, callback canónico ocurre una vez después de commit, sin toast.

App compone ambos escritores sobre el actor elegido después de overrides Debug. List conserva referencias débiles al Detail REAL visible; callback invalida solo watering propio en detalle/card. Relectura fallida de último riego se oculta conforme ADR010, no transforma commit en fallo. Foto notifica pager incluso suspendido: purga específica, cancela metadata/imagen antiguas, conserva selección superviviente, borrada→inicial y marca reconciliación pendiente al retorno sin IO eager. Loader timeline purga cache/LRU/owners/cola/tokens/geometría por identidad; IO cancelado sigue contando hasta drenar para concurrency2/cache3.

## Consecuencias

El layout de metadata usa VStack ligero y el conector un Shape de fondo. Evita el loop de estimaciones LazyStack medido en iOS26.2 tras alertas/nota larga; los candidatos de conector solo/lista plana no lo resolvieron y sus fallos se conservan en handoff. No cambia diseño/orden/identidades ni mueve IO a onAppear: bytes/decode solo del viewport, concurrency2/cache3. Coste de jerarquía/frames metadata O(n), no garantía de virtualización/escala; verificar scroll8/nota larga/fechas/pie de nuevo sobre estas fuentes, no usar gate histórico como prueba.

Sin segunda persistencia, cambio de orden ni promoción de portada. Una app terminada no restaura intención/banner, pero reentrada relee commit local. Un único escritor por store sigue siendo requisito; no coordinación multiproceso ni garantías frente a daño físico. Fixtures de fallo son exclusivamente Debug Simulator/UUID aislado y no hacen red. Autoverificación focal e independiente gate final se registran por separado.
