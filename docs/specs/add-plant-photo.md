# Feature Implementation Spec: Añadir foto fechada a una planta

## Source Feature

- `id`: `add-plant-photo`; `area`: `fotografias`; fuente: `feature_list.json`.
- Dependencia `save-plant`: `accepted`, comprobada antes de crear el worktree.
- Estado `not_started`, `evidence: []`. Planner ONE STEP, 2026-10-12, modelo `openai/gpt-6.1-sol`; pendiente revisión humana integral.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/add-plant-photo`.
- Rama `feature/add-plant-photo`; base fija `main`/`origin/main`: `12c5184c6f34b2ae2faa5e15b95b54a8991a735e`.
- Conducta fuente: añadir expresamente una foto local con fecha a un ejemplar guardado; comprobar imagen, fecha y pertenencia tras reiniciar.
- El planner entregó el contenido tras rechazo de permisos de edición; el orquestador lo persiste. No implementación ni validación de código.

## Goal / Job Story

Cuando quiero conservar una fotografía de un ejemplar existente, quiero elegirla o capturarla, ajustar su fecha y guardarla localmente, sin identificar otra vez ni cambiar su portada.

Una operación guarda una fotografía adicional independiente. Varias aperturas sucesivas permiten varias fotos, incluso con fecha o bytes iguales, con UUID nuevo por intención humana. Tras guardar se cierra el modal y el paginador superior del detalle muestra la nueva foto; incluye inicial y adicionales, fecha visible, gesto horizontal y botones ‹ ›. Paginar nunca cambia la portada de Mis plantas.

## Non-Goals

- Cronología/timeline, pantalla de galería separada, último registro fotográfico como nueva proyección, ampliación, sustitución de portada o borrado. El paginador persistente del detalle sí pertenece a esta feature.
- Multiselección, lotes, arrays de borradores, contratos batch o scaffolding especulativo: no hay feature de selección múltiple prevista en la lista.
- IA, análisis, ficha nueva, consentimiento externo, configuración API, fecha EXIF, nota/caption, hora o selector de zona.
- Backfill/duplicación de fotos iniciales, segunda copia del historial, cuentas, backend, sincronización, alertas o chat.
- Refactor transversal del VM de identificación para reutilizar el modal entero.

## Users And Permissions

- Un usuario local; pertenencia por UUID, nunca nombre/especie/posición.
- PhotosPicker de una imagen sin permiso global de Fotos. Cámara por intención explícita, reutilizando CheckCameraAccess/SystemCameraAccess y CameraPickerView; sin micrófono ni guardar captura en Fotos.
- Denegación/restricción/indisponibilidad comprensibles; Ajustes solo por tap explícito, permiso reconsultado al intentar cámara nuevamente.
- Guardado local sin consentimiento IA ni construcción de transporte/configuración remota.
- Fotos puede descargar assets iCloud por cuenta del sistema: no prometer importación siempre offline.

## Acceptance Scenarios — Given / When / Then

1. **Guardar hoy:** Given dos plantas A/B, When abro Añadir foto desde A, elijo imagen y pulso Guardar foto, Then tras commit cierra el modal y el paginador del detalle A selecciona la nueva foto con su fecha visible; JPEG/fecha/origen propios, portadas/modelos A/B intactos y cero IA. Selecciona su identidad también si es una foto antigua situada en medio/final del orden.
2. **Fecha humana:** Given foto preparada, When elijo un día pasado incluso anterior al alta, Then se guarda su inicio de día gregoriano; hoy es default, no EXIF. Futuros bloqueados en UI y rechazados en Domain/Data; zona inválida, día omitido o fechas no finitas tampoco guardan.
3. **Sustituir selección:** Given preview A lista, When cancelo picker/cámara o falla transferencia/preparación B, Then A y fecha siguen intactas. When B se prepara correctamente, Then sustituye A, conserva fecha y elimina retry/error anterior; mismo asset reseleccionable.
4. **Cancelar:** Given modal vacío, con preview o preparando, When Cancelar/gesto lo cierra, Then cero escrituras y respuestas tardías no restauran borrador. Reabrir en el mismo proceso o relanzar abre vacío/hoy, sin banner restaurado.
5. **Error/retry:** Given fallo antes de commit, When guardo, Then conserva foto/fecha y muestra error local, sin confirmación. Retry conserva UUID, siete campos y bytes, sin IA ni segunda foto. Editar fecha/publicar otra foto invalida snapshot y crea nueva intención al guardar.
6. **Commit bloqueado:** Given escritura despachada, When doble tap, cambio, cierre o gesto, Then no segunda escritura ni cambios/cierre; éxito confirmado reconocido pese a cancelación técnica tardía. Prevalidación cancelable no escribe si sesión deja de ser vigente.
7. **Reapertura/aislamiento:** Given dos fotos sucesivas en A y una en B, When termina el proceso y reabre sin seed/reinstalar, Then cada detalle empieza en su inicial y permite paginar las fotos/fechas propias persistidas; no restaura selección/borrador/banner anterior. Portadas, Plant/CareEvent y último riego exactos; duplicado exacto reconcilia, conflicto no overwrite.
8. **Fallos de almacenamiento:** Given metadata corrupta o apertura/migración fallida, When se accede, Then error, no vacío/reset ni limpieza destructiva. Foto referenciada ausente/corrupta produce error al cargar, no pérdida de planta ni sustitución por otra foto.
9. **Detalle sin portada:** Given metadata loaded y portada loading/failed, When abro Añadir foto, Then funciona con preview vacía. Metadata loading/failed/notFound no habilita acceso.
10. **Paginar:** Given inicial y adicionales ordenadas, When deslizo horizontalmente o pulso ‹ ›, Then cambia solo selección/fecha/imagen propia, sin writes ni carga de todos los JPEG. En extremos se deshabilita el botón correspondiente, sin wrap; con una foto no hay controles de paginación activos. Fecha visible también si falla su imagen.
11. **Carga/retry por foto:** Given foto X cargando/fallida, When selecciono Y y llega respuesta tardía de X, Then Y conserva identidad/fecha/imagen correctas. Reintentar X solo relee X; error de metadata adicional no aparenta ausencia ni listado completo. Cuidados y Añadir foto siguen disponibles.

## Repository Research

### Files Inspected

- AGENTS, PROGRESS, feature_list, ARCHITECTURE, CONSTRAINTS, CONTEXT, DESIGN; skills feature-spec/template e ios-clean-mvvm.
- Brief, dominio, riesgos; ADR001/008; testing-ui/testing-identification-photo e init.sh.
- `PlantCareAI/Features/PlantList/Data/{LocalPlantRepository,PersistedPlant}.swift` y Presentation/PlantListViewModel.
- PlantDetail/Presentation/{PlantDetailView,PlantDetailViewModel}.
- IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel,CameraPickerView}; View completa y estado/dependencias iniciales del VM.
- IdentificationPhoto/Domain/{IdentificationPhoto,PrepareIdentificationPhotoUseCase,CameraAccess}; Data/LocalIdentificationPhotoPreparer.
- SavePlant/Domain/PreparedPlantPhotoValidating y Data/LocalPreparedPlantPhotoValidator.
- CareEvents/Domain/RegisterCareEventUseCase y Presentation/RegisterCareViewModel.
- PlantCareAIApp, inicio de project.pbxproj, LocalCareEventRepositoryTests y sección SystemGalleryUITests/búsquedas verify en PlantCareAIUITests.swift.
- Sin spec previa, adjuntos disponibles ni archivos visuales en repositorio. Referencia confirmada por usuario: modal actual. Sin simulador ni inspección de imágenes.
- Continuación del mismo planner: releídos spec/PROGRESS/entrada feature actuales persistidos por orquestador; delta de paginador explícitamente autorizado por usuario, sin investigación ejecutable ni pruebas nuevas.

### Findings / Gaps

- LocalPlantRepository: único actor escritor PlantRepository + CareEventRepository; container/context perezosos, autosave false, `Plants.store` y `Photos/<plantID>.jpg`.
- V1/V2 son nombres documentales de schemas **no versionados**: PersistedPlant / PersistedPlant+PersistedCareEvent. Sin VersionedSchema/MigrationPlan reales.
- Apertura valida Plant/CareEvent antes de limpiar `.pending`/JPEG huérfanos; recuperación solo conoce portadas. Añadir archivos allí sin cambiar recuperación los borraría.
- No entidad/contrato actual de fotos adicionales; iniciales permanecen en PersistedPlant.
- Pipeline reutilizable: entrada ≤30 MiB/80 MP, primer frame, orientación en pixels, lado ≤2048 sin ampliar, alfa blanco, JPEG .85 ≤5 MiB sin EXIF/GPS. Validador de alta verifica integridad/dimensiones sin recomprimir fuera de MainActor.
- Detail VM/fábrica de listado/App permiten sheet por sesión; CareEvents aporta precedente de fecha/origen/retry/bloqueo/banner real sin cronología.
- Gate separa clase SystemGalleryUITests completa en fase serial sembrada; nuevas pruebas PhotosPicker real deben pertenecer a ella.

## Technical Approach

### Layers And Composition

- `Features/PlantPhotos/Presentation`: AddPlantPhotoView/VM propios y PlantPhotoPagerView/VM. VM de alta controla borrador/snapshot; VM de paginador controla descriptores/identidad seleccionada, metadata, imágenes acotadas/cache/generaciones. SwiftUI/PhotosUI/UIImage solo Presentation; sin tareas de IO por cada página montada.
- `Features/PlantPhotos/Domain`: PlantPhoto, PlantPhotoRepository, AddPlantPhotoUseCase y LoadPlantPhotosUseCase para metadata; Foundation, sin rutas/SwiftData/UIKit/IA. Inicial se proyecta desde Plant y no es entidad nueva: identidad discriminada `.initial(plantID)`/`.additional(photoID)` evita colisión de UUID y de índices. Consulta de bytes inicial reutiliza LoadInitialPlantPhoto; adicional usa contrato PlantPhotoRepository detrás de caso de uso LoadPlantPhotoUseCase.
- `Features/PlantPhotos/Data`: PersistedPlantPhoto y fixture Debug Simulator aislado.
- Adaptador real: mismo LocalPlantRepository también PlantPhotoRepository; no segundo actor/container sobre el mismo store.
- Dirección: View → VM → AddPlantPhoto → PlantPhotoRepository ← LocalPlantRepository.
- Lectura: PagerView → PagerVM → casos de uso metadata/bytes → contratos Domain ← mismo actor. Detail VM posee paginador por UUID y recibe callback canónico de alta; no crea adaptadores. Preservar snapshot de foto inicial para EditPlant/CareEvents, no sustituirlo por la página adicional seleccionada.
- Preparación/validación/cámara mediante contratos existentes inyectados, no IdentificationPhotoViewModel ni consentimiento/alta.
- App compone sobre actor definitivo después de overrides Debug; fábrica/dependencias pasan por PlantListViewModel a Detail VM. Init/fábricas sin IO; ContentView intacto.
- Reutilizar DTO IdentificationPhoto como JPEG efímero, no evidencia IA; documentar uso compartido sin renombrado transversal.

### Data Contract / Time

- PlantPhoto: siete campos `id`, `plantID`, `occurredAt`, `createdAt`, `timeZoneIdentifier`, `width`, `height`; Sendable/Equatable. JPEG fuera del modelo Domain.
- PersistedPlantPhoto: siete campos + `photoReference` canónico `<photoID>.jpg`; UUID único. Validar estructura/dimensiones/referencia/pertenencia a planta existente. Sin kind/source/analysisID especulativos.
- Plant/CareSheet/PersistedPlant/PersistedCareEvent intactos.
- Contrato mínimo: `savePhoto(_ photo: PlantPhoto, jpeg: Data) async throws -> PlantPhoto`, `loadPhotos(for plantID: UUID) async throws -> [PlantPhoto]`, `loadPhoto(id: UUID, for plantID: UUID) async throws -> Data`.
- AddPlantPhoto usa save; paginador y tests/fixture usan metadata/bytes. Metadata sin lectura JPEG; bytes por UUID + plantID validados, sin acceso cruzado.
- Orden metadata determinista occurredAt desc, createdAt desc, UUID asc; sin timeline UI.
- Propuesta de orden del paginador: unión de inicial proyectada UNA vez (fecha disponible = Plant.createdAt, etiquetada como fecha de alta, sin EXIF/zona origen ficticia) y adicionales; clave temporal absoluta desc (`createdAt` inicial / `occurredAt` adicional), createdAt desc como desempate, clave discriminada estable asc al final. No agrupar/deduplicar por bytes/día. El orden no depende del formato/zona de presentación; inicial puede no ocupar índice 0. Apertura selecciona siempre `.initial(plantID)`, no el primer índice ni la más reciente. Esta política temporal es propuesta técnica revisable.
- PlantPhotoError: validation/plantNotFound/notFound/conflict/photoMissing/photoCorrupt/storage. Error nunca lista vacía; VM distingue preparación/cámara/persistencia.
- Hoy al abrir; inicio de día gregoriano en origen IANA, sin hora observada. createdAt primer intento de guardar esa intención.
- Como CareEvents: pasadas/prealta permitidas, inserciones no futuras con reloj fresco en origen; cubrir DST/día omitido/no finito/zona inválida. Helper temporal puro pequeño solo si evita duplicación real, con regresiones de ambos dominios.
- UI presenta en zona ACTUAL: día puede cambiar al viajar sin reescribir instante/origen. Nueva elección humana captura origen nuevo. Retry conserva origen/fecha aunque cambien zona/medianoche; lectura no compara contra reloj actual.

### Migration / Publication / Recovery

- Propuesta: upgrade automático aditivo SwiftData al schema documental V3 **no versionado**, añadiendo PersistedPlantPhoto al container actual y misma ruta Plants.store. No inventar historial VersionedSchema.
- **Migración propuesta, no acreditada:** demostrar disco V2 real con ambas entidades/cinco kinds/modelos/JPEG exactos, liberar container/context, abrir V3, guardar/reabrir. Conservar prueba V1→V3. Si falla, detener y revisar estrategia/ADR; sin reset/reseed/fallback destructivo.
- Nuevo `PlantStore/AdditionalPhotos/<photoID>.jpg`, separando nombres/limpieza de portadas. No mover/copiar JPEG iniciales ni backfill. Extensibilidad por identidad real, no batches; futura timeline proyectará inicial desde Plant más fotos adicionales sin duplicarlas ahora.
- Apertura fetch/valida TODOS Plant/CareEvent/PlantPhoto incluidas referencias/pertenencia **antes de borrar en ambos directorios**. Después limpia `.pending` y `.jpg` no referenciados con conjuntos propios. Fallo fetch/validación aborta limpieza; formatos desconocidos/rutas ajenas intactos.
- Validar JPEG también en Data para callers directos usando LocalPreparedPlantPhotoValidator y dimensiones del registro. Puede suspender antes de obtener contexto/transacción; luego ningún await entre fetch/duplicado/publicación/save. IO/decode fuera de MainActor.
- Dentro del actor comprobar planta, duplicado exacto (siete campos/origen literal/bytes), después inserción con now fresco. Duplicado confirmado exacto devuelve canónico sin save antes del reloj; diferencias son conflict, nunca overwrite. Bytes confirmados ausentes/corruptos: error, no reparación silenciosa.
- Inserción: validar JPEG → temporal `.pending` único → escribir/verificar bytes exactos → move sin overwrite → insert metadata → seam síncrona de fallo → context.save. Sin segunda compresión.
- Rollback/eliminar SOLO archivos nuevos/temporal propios, jamás destino preexistente. Cancelación antes de publicación; desde despacho de commit no abandonar éxito por cancelación técnica.
- Seams antes/después de publicación y antes de save. Interrupción move/save deja huérfano recuperable; después de save conservar registro/foto. No transacción distribuida ni garantía contra daño físico/multiproceso; un escritor/store, tests liberan container antes de otro.
- Referencia rota no borra metadata ni invalida todo store por archivo ausente; loadPhoto devuelve error.

### Presentation / Save And Persistent Pager

- Entrada secundaria «Añadir foto» en detalle loaded bajo identidad, separada de Registrar cuidado; sin toolbar sobrecargada ni barra fija inferior. Disponible aunque portada falle.
- Modal «Añadir foto» con Cancelar/grabber/scroll nativos. Referencia **modal de identificación actual**, solo preview/placeholder 4:3 radio22, álbum, cámara y «Guardar foto» en lugar de Identificar.
- Cápsulas de igual ancho/altura ≥44, espaciado/paleta DESIGN; sin candidatas/manual/privacidad IA/Volver a identificar. Nombre persistido de apertura multilínea identifica pertenencia; portada no se carga como nueva foto.
- Preview vacía; fecha compacta editable entre preview y acciones, hoy/rango sin futuros. Sin chips Ayer/Hoy obligatorios ni nota.
- Guardar deshabilitado sin foto lista/fecha válida o durante transferencia/cámara/validación/commit. A permanece al fallar B; reset PhotosPickerItem permite reselección. Generaciones + closed protegen respuestas tardías, incluido puente cámara.
- Snapshot inmutable siete campos/JPEG; prevalidación cancelable y revalidación de token/sesión/foto/fecha antes de despacho. Saving bloquea campos/fuentes/Cancelar/gesto antes de await; doble tap no duplica.
- Error «No pudimos guardar la foto»/«Reintentar guardado». Fecha/nueva selección publicada elimina retry/error; reemplazo fallido/cancelado conserva snapshot A.
- Callback canónico una vez por sesión/plantID antes de dismiss: integra metadata confirmada por identidad, selecciona `.additional(confirmed.id)` aunque sea retroactiva y muestra esa foto/fecha en paginador superior. No cambia portada/Plant ni invalida último riego/listado. Banner «Foto guardada» por sesión es complemento propuesto, nunca sustituto del paginador ni requisito para probar persistencia.
- Propuesta de integración de commit: upsert canónico en descriptores conocidos y preparar thumbnail del JPEG ya validado fuera de MainActor (≤1600 px), sin recomprimir/escribir otra copia ni retener JPEG en cache. Releer metadata adicional para reconciliar; generación/token impide que un fetch previo al commit suprima la foto nueva o cambie selección. Fallo de esta lectura no convierte commit en guardado fallido: conservar nueva foto confirmada/selección y error de actualización con retry; conjunto previo/incompleto no se presenta como completo.
- Paginador reemplaza bloque fotográfico superior actual conservando 4:3/radio22/paleta. Swipe horizontal nativo y botones ‹ › de ≥44 pt con etiquetas «Foto anterior»/«Foto siguiente», fecha visible de página seleccionada (inicial «Foto inicial · [fecha de alta]», adicional fecha humana en zona actual). Sin navegación circular; extremos deshabilitados, con una sola foto ocultar controles redundantes, fecha permanece. Indicador `n de N` opcional técnico solo cuando metadata completa, nunca contador parcial como total real.
- Plant loaded permite mostrar descriptor inicial mientras metadata adicional idle/loading/failed tiene estado independiente y explícito junto al paginador; no atribuir cero adicionales a error. Inicial puede cargar con Plant metadata disponible; cada adicional solo carga bytes tras su descriptor validado. Metadata completa antes de habilitar paginación de todo el conjunto; retry de metadata no relee portada ni cuidados.
- Selección por identidad estable, índice derivado de la colección reconciliada; no guardar índice como identidad. Swipe/botones usan la misma intención. Refresh preserva identidad existente; si desaparece tras lectura correcta, fallback inicial. Durante carga de metadata adicional sin error/resultado solo inicial navegable; callback de commit puede añadir registro confirmado sin afirmar colección completa.
- Imagen seleccionada: idle/loading/loaded/failed por clave discriminada; placeholder/spinner/error/retry dentro del área, fecha/controles/cuidados disponibles. Retry relee solo bytes de esa clave; nunca sustituir foto fallida por inicial/otra imagen. Respuestas del UUID/planta/selección/generación anterior no publican en la página actual.
- Propuesta de memoria: thumbnails ImageIO ≤1600 px fuera de MainActor; cache local máxima TRES imágenes decodificadas (inicial + seleccionada + última adicional LRU), sin JPEG retenidos ni precarga de toda colección/cache global/disco. Cargar solo selección; descartar tareas de selección anterior y cache al destruir detalle. Cancelación/generaciones también cubren decode y retry; metadatos sí pueden permanecer completos en memoria. No afirmar memoria constante de originales.
- Apertura normal/reentrada con nuevo detalle y relaunch comienzan en inicial; onDisappear cancela lecturas/decode, invalida callbacks tardíos y restablece selección inicial al reaparecer, sin restaurar borrador. Guardado que termina con detalle aún activo conserva selección nueva tras dismiss del modal; cierre de sheet no se trata como abandono de destino. Paginación/fecha de presentación/refresh son SOLO lecturas, cero writes.
- IDs: `detailAddPhoto-<plantID>`, `addPlantPhotoForm`, `additionalPhotoPreview/Placeholder`, `additionalPhotoGallery/Camera/Date/Loading/Error/Saving`, `saveAdditionalPhoto`, `retryAdditionalPhoto`, `cancelAdditionalPhoto`, `additionalPhotoConfirmation-<plantID>`.
- Paginador: `plantPhotoPager-<plantID>`, `plantPhotoPrevious/Next-<plantID>`, `plantPhotoDate-<plantID>`, `plantPhotoMetadataError/Retry-<plantID>`, y foto/error/retry por clave discriminada. Conservar IDs/contrato accesible inicial anteriores donde equivalentes; adaptar callers explícitamente sin debilitar assertions de foto/navegación.
- Español/fallback sin claves crudas; texto adaptable, etiquetas accesibles y objetivos ≥44 pt.

## Expected File Changes — Future Implementer

- Crear `PlantCareAI/Features/PlantPhotos/Domain/{PlantPhoto,PlantPhotoRepository,AddPlantPhotoUseCase,LoadPlantPhotosUseCase,LoadPlantPhotoUseCase}.swift`; descriptor/identidad discriminada en fichero Domain existente o propio si simplifica, no entidad persistida adicional.
- Crear `PlantCareAI/Features/PlantPhotos/Presentation/{AddPlantPhotoView,AddPlantPhotoViewModel,PlantPhotoPagerView,PlantPhotoPagerViewModel}.swift` y Data/{PersistedPlantPhoto,PlantPhotoTestFixture}.swift.
- Modificar PlantList/Data/LocalPlantRepository; PlantDetail/Presentation/{PlantDetailView,PlantDetailViewModel}; PlantList/Presentation/PlantListViewModel y PlantCareAIApp.
- Modificar Localizable.xcstrings/project.pbxproj: recursos y registro explícito Swift app/test.
- Crear `PlantCareAITests/{AddPlantPhotoTests,AddPlantPhotoViewModelTests,LocalPlantPhotoRepositoryTests,PlantPhotoPagerViewModelTests,LoadPlantPhotosTests}.swift`; extender Detail/List VM tests afectados.
- Extender PlantCareAIUITests.swift con AddPlantPhotoUITests y pruebas dentro de SystemGalleryUITests; preservar assertions existentes.
- init.sh intacto: selecciona clase Fotos serial completa. Helper temporal compartido solo para callers reales.

## Durable Documentation Impact

- Futuro ARCHITECTURE: dominio/callers/actor/rutas/recuperación/schema aditivo/DTO compartido y lectura paginada/cache/generaciones sin mutar portada.
- Futuro `docs/adr/011-local-additional-plant-photos.md`, tras aprobación: alternativas/consecuencias/migración/limitaciones.
- Futuro dominio/DESIGN/riesgos: fecha humana/portada intacta/paginador persistente inicial+adicionales/orden propuesto/estados de error/riesgos; no cronología.
- Futuro testing-ui/testing-local-plant-storage y nueva testing-add-plant-photo: contratos/selectores/fixture/comandos.
- CONTEXT/brief/CONSTRAINTS/AGENTS sin cambio necesario. No reescribir specs aceptadas/evidencias históricas.
- Planner solo spec/PROGRESS/planner_notes; not_started/evidence vacía conservados.

## Implementation Plan / Tasks

1. [ ] Revisión humana integral de delta paginador y propuestas de orden/cache/reconciliación; ADR y decisión de helper temporal. Acceso bajo identidad/paginador/fechas ya confirmados, sin nueva entrevista salvo bloqueo.
2. [ ] Metadata/errores/use case/tiempo y tests puros/snapshot/precommit.
3. [ ] Entidad/actor/schema/recuperación; upgrade real V2/V1, no store nuevo como migración.
4. [ ] VM/modal/pipeline/cámara/callback y paginador metadata→bytes/identidades/cache/lifecycle/composición; Swift/resources sin cambios ajenos.
5. [ ] Fixture real Debug Simulator aislada y E2E con expectativas independientes, sin historial ficticio.
6. [ ] Diff→riesgos→selección; autoverificación por impacto, docs/evidencia/handoff independiente.

## Verification Plan — Proposed, Not Executed

### Implementer: Impact-Selected

- Schema/cleanup/actor: LocalPlantPhotoRepositoryTests + LocalPlantRepositoryTests + LocalCareEventRepositoryTests completos. Upgrade V2/V1 real/reopen; bytes/modelos/eventos exactos, fotos sucesivas, conflictos plantID/zona/dims/bytes, rollback/temporales/orphans, validación antes de cleanup, referencias rotas y metadata sin IO JPEG.
- Domain/tiempo: AddPlantPhotoTests hoy/pasado/prealta/futuro, DST/día omitido/zonas/reloj atrasado/duplicado antes de reloj/límites/JPEG corrupto/sin EXIF. Si helper temporal compartido, RegisterCareEventTests/RegisterCareViewModelTests.
- VM/fábricas: AddPlantPhotoViewModelTests + PlantDetailViewModelTests + PlantListViewModelTests. A/error/B/mismo asset/cierre/tardías/cámara/fecha/prevalidación cancelada/retry zona-medianoche/edición invalidante/bloqueos/doble tap/commit tardío/callback único dirigido/cache/último riego intactos.
- Paginador: LoadPlantPhotosTests + PlantPhotoPagerViewModelTests para unión/orden/desempates/inicial no duplicada/UUID colisionables, inicial no índice0, single-photo/extremos/gesto y botones equivalentes, selección nueva retroactiva, metadata antes de bytes, cache máximo3/eviction/sin JPEG retenidos, cancel/decode/retry tardíos, fallo metadata vs ausencia, refresh preserva clave y no pierde commit, error postcommit separado, lifecycle/reopen inicial y cero writes al paginar. Snapshot de editor/cuidado sigue inicial y cards no cambian.
- Pipeline/cámara: IdentificationPhotoPreparationTests, PreparedPlantPhotoValidationTests, CameraAccessTests; IdentificationPhotoViewModelTests si código compartido cambia.
- E2E AddPlantPhotoUITests: hoy/pasado/relaunch sin reseed, dos plantas/varias sucesivas, Cancelar/gesto/reapertura/error/retry/busy/portada fallida/largos/scroll/calendario/futuro/fallback. Fixture compara campos/bytes independientes; sidecar no sustituye persistencia real.
- E2E paginador dentro de AddPlantPhotoUITests: guardar retroactiva selecciona identidad/imagen/fecha correcta, anterior/siguiente y swipe reales, extremos/single-photo, A→B→A aislado, fallo de imagen+retry propios, relaunch inicia inicial y permite volver a adicionales reales. Verificar ambos Plant/JPEG iniciales/CareEvents exactos y metadata/JPEG adicionales tras navegación sin reseed; seam observa cero writes por paginar y ningún envío IA. Fixtures con imágenes distintas/fechas empatadas/retroactivas y expectativas independientes, no foto precargada que sustituya prueba de lectura real.
- PhotosPicker real dentro de **SystemGalleryUITests**: acceso detalle/seleccionar/cancelar/reemplazar/reseleccionar/guardar/relaunch/verificar disco; conservar identificación original. Clase completa serial con media sembrada.
- Regresiones: StoredCollectionUITests, PlantCardsUITests, EditPlantUITests, CareEventsUITests, SavePlantUITests, LocalizationUITests; LastWateringHintUITests si callers/callback/posición afectados. Acotar métodos según diff y registrar motivo; persistencia/composición justifican ampliar, no suite completa automática.

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 CODE_SIGNING_ALLOWED=NO \
  -only-testing:PlantCareAITests/AddPlantPhotoTests \
  -only-testing:PlantCareAITests/AddPlantPhotoViewModelTests \
  -only-testing:PlantCareAITests/LocalPlantPhotoRepositoryTests \
  -only-testing:PlantCareAITests/PlantPhotoPagerViewModelTests \
  -only-testing:PlantCareAITests/LoadPlantPhotosTests \
  -only-testing:PlantCareAIUITests/AddPlantPhotoUITests test
```

- Añadir regresiones elegidas por diff. Fotos: `xcrun swift scripts/seed-identification-photos.swift "$PWD/DerivedData/IdentificationPhotoMedia"`, después `xcrun simctl addmedia "$UDID" "$PWD/DerivedData/IdentificationPhotoMedia/picker-A.png" "$PWD/DerivedData/IdentificationPhotoMedia/picker-B.png"`; clase SystemGalleryUITests con `-parallel-testing-enabled NO`, sin borrar media ajena.
- Visual focalizado vacío/preview/error/saving y paginador inicial/nueva-retroactiva/fecha/controles/error, iPhone estándar/texto normal/una apariencia. Capturas vía build-for-testing y configure-ui-test-environment.py/xctestrun según testing-ui, reutilizando productos válidos; no repetir aprobadas solo por capturas.
- Coordinar sesión/simulador, sin competidores. Antes de build copiar plantilla pública vacía solo si config Debug ausente; nunca leer/sobrescribir real existente. Flujo local sin API.
- Release build/audit por nuevos seams, excluyendo secretos/fixture/flags. Estáticos futuros: plutil proyecto, JSON/catalog sin duplicados, git diff --check, Domain Foundation-only.
- Baseline reutilizable solo con fuentes/config/destino relevantes idénticos; si falta evidencia diagnosticar focalmente, no gate baseline rutinario. Reparación primero fallo/callers, conservar fallo, sin retries/iterations para verde.
- Cámara física/iCloud/memoria constante no acreditadas por dobles. SE/texto aumentado/VoiceOver/matrices fuera habitual, no bloqueos automáticos.

### Validator: Final Gate

- Único `caffeinate -dius ./init.sh` final con ambas fases válidas, o evidencia completa corroborada de mismas fuentes/entorno; no duplicar focalizadas cubiertas sin laguna concreta.
- Cambios ejecutables posteriores invalidan gate: reparación focal y nuevo gate justificado. Gate fallido nunca aceptación parcial.
- Planner documental: lectura/coherencia, sin build/tests/gate/simulador ni validación de código.

## Evidence To Capture / Validator Checklist

- [ ] Comandos/selección/motivo/exit/log/xcresult/fuentes/config/destino, nuevos vs reutilizados, gate pendiente.
- [ ] Upgrade V2/V1 real/reopen, bytes/modelos/eventos/plantID/fechas exactos; portadas intactas, validación global antes de cleanup.
- [ ] Escenarios 1–11, paginador persistente/fecha/gesto/botones/extremos/single-photo/errores, Fotos real serial, visual realmente inspeccionado; límites hardware/iCloud explícitos.
- [ ] Domain limpio, único actor/composición, cero IA/aviso externo, una foto por intención, sin timeline/batches.
- [ ] Nueva foto seleccionada por identidad tras commit incluso retroactiva; retry/error/cancelación/callback aislados, metadata antes de bytes/cache acotada, apertura inicial y cero writes al paginar.
- [ ] Docs/ADR/estado/evidencia reales; passing = focalizadas, accepted = independiente/gate válido.

## Decisions And Reviewable Questions

- Confirmado por usuario: modal actual solo foto/cámara/álbum/Guardar foto, fecha editable hoy sin EXIF, pasadas/prealta permitidas/futuras bloqueadas, portada intacta, acceso bajo identidad separado de cuidado. Una foto/operación y varias sucesivas; cerrar al guardar y mostrar nueva foto en paginador superior con inicial+adicionales, swipe/botones ‹ ›/fecha; apertura normal inicial, Mis plantas no cambia, mismos registros para futura timeline sin implementarla.
- Propuestas técnicas revisables: origen IANA/presentación actual como CareEvents, orden temporal absoluto con inicial proyectada sin duplicación, cache máximo3, selección por identidad/reconciliación tras commit y banner complementario. No implican entrevista nueva ni aprobación integral; revisar antes de implementar.
- Riesgos: migración automática V2→V3 aún no demostrada; recuperación debe validar todo antes de limpiar; Photos/UIKit pueden materializar originales, sin memoria constante.
- Un writer y compensación no equivalen a transacción distribuida; sin downgrade ni recuperación garantizada frente a daño físico.
- Paginador añade riesgos de decode/cache/cancelación y callers accesibles del detalle; pruebas propuestas amplían impacto dentro de esta misma feature, sin timeline ni segunda entidad. Historia previa de feedback limitado queda solo en PROGRESS; contrato vigente es este delta autorizado.
- Próximo paso exclusivo: revisión humana integral. Planner detenido; ninguna autorización de implementación inferida.
