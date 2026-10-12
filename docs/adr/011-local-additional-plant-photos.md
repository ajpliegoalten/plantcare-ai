# ADR 011 — Fotografías adicionales locales y paginador del detalle

Fecha: 2026-10-12. Decisión original autorizada por aprobación integral de `docs/specs/add-plant-photo.md`, aceptada independientemente233/233 en `docs/validations/add-plant-photo.md`. Refinamiento posterior solicitado por usuario descrito abajo; su evidencia nueva no reutiliza ese gate como aceptación de fuentes modificadas.

## Decisión

`PlantPhotos` separa Presentation (modal/borrador/paginador), Domain (siete campos, identidad discriminada, contratos/tiempo/casos de uso) y Data (entidad/fixtures). La composición de App inyecta fábricas por PlantList a PlantDetail sobre el **mismo** LocalPlantRepository, después de overrides Debug. No se construye transporte IA ni configuración remota al añadir/paginar. IdentificationPhoto es el DTO JPEG efímero compartido, no identidad botánica ni entidad persistida.

Una intención humana guarda una foto: UUID, plantID, occurredAt, createdAt, timeZoneIdentifier IANA, width, height. Fecha gregoriana al inicio del día de origen; hoy por defecto, pasadas/prealta permitidas, futuras rechazadas. Presentación en zona actual; retry conserva origen/instantes/UUID/bytes, incluso tras viaje/medianoche. Se mantienen validadores temporales pequeños propios, sin refactor del dominio CareEvents aceptado; ambas rutas conservan su cobertura existente.

Schema documental V3 **no versionado**, aditivo sobre V2/V1, mismo `Plants.store`; PersistedPlant/PersistedCareEvent intactos. Nueva PersistedPlantPhoto añade referencia canónica `<photoID>.jpg`; archivos en `AdditionalPhotos`, portadas siguen en `Photos/<plantID>.jpg`. No backfill ni copia de iniciales. Pruebas de disco crean realmente schemas V2 y V1, liberan sus containers, abren V3, guardan y reabren conservando dos modelos/JPEG y los cinco tipos de cuidado exactos.

Un actor escritor valida todas las entidades/pertenencias antes de limpiar cualquiera de los dos directorios. Metadata no lee JPEG. Lecturas por photoID **y** plantID comprueban referencia, integridad, dimensiones y contrato preparado. Archivos ausentes/corruptos no borran metadata. Apertura/validación fallida aborta limpieza, no devuelve vacío/reset.

JPEG preparado existente ≤2048 px/5 MiB, sin metadata excluida; validador fuera de MainActor, sin recomprimir. Antes de contexto puede suspender; desde duplicate-check hasta publicación/save no hay await. Duplicado literal de siete campos/bytes reconcilia antes del reloj; conflicto no overwrite. `.pending` propio → comprobar bytes → move sin overwrite → metadata → save. Rollback elimina solo archivos nuevos propios; seams síncronas antes/después de publicación y antes de save. Huérfanos sin metadata son recuperables al abrir; un commit real no se compensa tras éxito.

El paginador proyecta la inicial una vez desde Plant.createdAt, sin zona EXIF inventada. Orden absoluto descendente por fecha, createdAt descendente y clave discriminada estable ascendente. Apertura normal selecciona siempre `.initial(plantID)`, no índice0. Commit selecciona `.additional(photoID)` también retroactiva; upsert canónico con thumbnail preparado y relectura generacional. Error de reconciliación no deshace guardado ni presenta un conjunto parcial como completo.

Una superficie fotográfica SwiftUI recibe swipe horizontal nativo/‹ › sobre la misma selección por identidad; no monta tareas de IO por página. Metadata y bytes tienen errores/retries separados. Solo lee/decodifica selección, thumbnails ImageIO ≤1600 px, máximo tres imágenes decodificadas LRU (inicial retenida mientras vive el destino), sin cache de JPEG/disco/global ni precarga. Generaciones/cancelación cubren transferencia, permiso, metadata, bytes y decode. Editor/cuidado usan snapshot **inicial**, nunca la adicional seleccionada. Abandonar detalle limpia cache y vuelve a inicial; cerrar el modal tras commit no abandona el destino.

## Alternativas y consecuencias

### Refinamiento posterior autorizado

Usuario solicita ordenar el carrusel por incorporación: **createdAt ascendente**, antigua primero, reciente última, empate por clave discriminada. La fecha humana se conserva/visualiza pero no ordena. Sustituye el orden descendente original descrito arriba; no migra ni escribe registros. TabView page nativo aporta desplazamiento interactivo entre páginas, usando selección estable/cache existente sin IO por cada página. Presentar una sheet/cámara no cancela la sesión de detalle; al cerrar tras commit permanece la nueva foto. Salir realmente del detalle sí restablece inicial. Cabecera/placeholder/acciones reutilizan componentes Presentation sin cambiar contratos Data/alta. Spec original y aceptación previa permanecen históricas; esta ronda requiere evidencia propia.

No segundo actor/container, imágenes embebidas en SwiftData, galería separada, batch, sustitución de portada, timeline ni modelos especulativos de análisis. La futura cronología consultará estos mismos registros más la inicial proyectada.

No se inventa VersionedSchema/MigrationPlan retrospectivo. Upgrade automático aditivo demostrado en Xcode26.2/iOS26.2; no downgrade ni promesa para todos los runtimes. Un writer y compensación de archivos no equivalen a transacción distribuida: daño físico/multiproceso/desinstalación pueden perder datos. Photos/cámara pueden materializar originales; la cache acotada no garantiza memoria constante de esos originales. iCloud y cámara física no acreditados por simulador/dobles.

Evidencia, reparaciones y límites: `docs/handoffs/add-plant-photo.md`.
