# Feature Implementation Spec: Editar nombre y ubicación

## Source Feature

- `id`: `edit-plant`; `area`: `detalle`; `title`: Editar nombre y ubicación.
- `user_visible_behavior`: El usuario modifica el nombre personalizado y la ubicación opcional sin alterar la especie ni otra planta.
- `depends_on`: `plant-detail`, comprobada `accepted` en `feature_list.json` y `PROGRESS.md`.
- `status`: `not_started` al planificar; `source`: `feature_list.json`; no cambia en esta sesión.
- `verification`: Editar nombre y ubicación de una de dos plantas, reabrir la app y verificar cambios locales aislados; gate estándar.
- `notes`: No implica editar la ficha generada por IA.
- Planner ONE-STEP, 2026-10-10: borrador para revisión humana; skills `feature-spec` y guía local `ios-clean-mvvm` aplicadas.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/edit-plant`. Rama/base comunicadas por el encargo: `feature/edit-plant`, main SHA `33703f9cbf0c352bb8598be5154369c52729be98`.
- Raíz corroborada por entorno y rutas absolutas de inspección; no ejecutados `pwd` ni comandos Git para verificar rama/SHA/diff. No implementación, validación de código, builds/tests/init.sh, stage/commit/push/PR/merge ni GitHub. Solo esta spec sin commit; detenerse para revisión humana.

## Goal

Desde el detalle del ejemplar seleccionado, corregir exclusivamente nombre personalizado y ubicación opcional mediante un formulario modal nativo. Guardar confirma una escritura local real por UUID y actualiza coherentemente detalle y colección en la sesión actual y tras relanzar, sin tocar especie, ficha, foto, fecha ni otro ejemplar.

## Non-Goals

- Editar especie, seis cuidados, fotografía/referencia, fecha de alta, UUID, salud o cualquier campo adicional sugerido por Stitch; ni siquiera controles deshabilitados para esas futuras capacidades.
- Acceso directo desde tarjetas: sin menú contextual, swipe, lápiz, pulsación larga ni botón «Editar» en colección.
- Alta, eliminación, historial, riegos, fotos nuevas, IA, permisos, red, geolocalización, cuentas, backend o sincronización.
- Nuevo esquema SwiftData, migración destructiva, catálogo de especies, repositorio duplicado, paquetes o recursos externos.
- Resolver pipeline/memoria de fotos reales: pertenece a `save-plant`; no alterar aceptaciones previas.

## Job Story / Users And Permissions

Cuando consulto una planta guardada, quiero corregir su nombre o dónde la tengo, para reconocer ese ejemplar sin cambiar su identificación ni cuidados.
Único usuario local, sin permisos nuevos; edición disponible sin conectividad y aun cuando falle la carga de la foto.

## Acceptance Scenarios

### 1. Acceso confirmado y formulario mínimo
Given un detalle con metadata cargada,
When se pulsa el botón visible «Editar» en su barra superior,
Then abre una sheet nativa con título «Editar planta», «Cancelar» y «Guardar», y solo «Nombre personalizado» y «Ubicación (opcional)», precargados desde ese UUID.
Then no hay campos de especie, ficha o foto; las tarjetas siguen llevando únicamente al detalle y no tienen acceso de edición.
Given detalle loading/notFound/failed,
Then no se permite abrir una edición con valores inventados; con metadata loaded y foto fallida sí se permite editar.

### 2. Guardar, refrescar y mantener aislamiento
Given A y B de igual especie, UUID/foto/cuidados distintos,
When se cambia nombre y ubicación de A y se pulsa «Guardar»,
Then solo tras commit exitoso se cierra el modal, el detalle muestra los valores confirmados y, al volver, la tarjeta y su etiqueta accesible muestran esos mismos valores sin relanzar.
Then UUID, especie literal, createdAt, seis cuidados, referencia y bytes de ambas fotos permanecen idénticos; B completo no cambia; no se crea una tercera planta ni se altera el orden de colección.
When se vuelve a abrir A y después B,
Then se ven sus valores propios, sin snapshot antiguo ni datos compartidos por especie.

### 3. Ubicación opcional
Given A con ubicación y B sin ella,
When se borra ubicación de A y se guarda, o se añade una a B,
Then ausencia se representa como nil y detalle/tarjeta omiten la fila de A sin placeholder; B muestra su valor nuevo únicamente tras su guardado.
Then se puede cambiar solo uno de los dos campos conservando el otro.

### 4. Cancelar o descartar el borrador
Given cambios escritos pero no guardados,
When se pulsa «Cancelar» o se descarta la sheet por gesto antes de guardar,
Then no se escribe nada ni cambia detalle/colección; volver a editar precarga los últimos valores persistidos, no el borrador descartado.
Given escritura en curso,
Then no se admite doble guardado, edición concurrente de campos, cancelar ni descartar interactivamente el modal hasta conocer el resultado.

### 5. Validación y fallo de escritura
Given nombre vacío o solo espacios/saltos de línea,
When se intenta guardar,
Then «Guardar» está deshabilitado y aparece una explicación textual del nombre obligatorio; Domain/Data rechazan igualmente una invocación inválida sin mutaciones.
Given un error local durante commit,
When se guarda,
Then la sheet permanece abierta, conserva ambos textos, explica el fallo y permite volver a pulsar «Guardar» o cancelar; ningún estado de detalle/colección anuncia éxito y rollback conserva los valores anteriores, incluso tras recrear el repositorio.
Given UUID no existente,
Then la operación informa ausencia explícita y no inserta ni modifica otra planta; cancelar permite salir, sin éxito ficticio.

### 6. Persistencia, offline y accesibilidad
Given A editada y B intacta,
When se termina y relanza el proceso sin desinstalar/resembrar,
Then tarjeta y detalle de A conservan cambios y B todos sus valores originales, incluidas fichas/fotos; no se necesita API/red.
Given iPhone pequeño, texto máximo, teclado visible o VoiceOver,
Then etiquetas, validación, errores y acciones son alcanzables y comprensibles, controles >=44×44 pt; no claves de localización crudas, recorte horizontal ni campos extras.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json`, `ARCHITECTURE.md`, `DESIGN.md`, `CONSTRAINTS.md`, `CONTEXT.md` y ambas skills/template — reglas y dependencia aceptada.
- `docs/{build-brief,domain-model,risks-and-open-questions,testing-local-plant-storage}.md`, `docs/adr/001-local-plant-storage.md`, `docs/specs/plant-detail.md` — límites, storage y pruebas reproducibles. Encabezado ADR antiguo no reemplaza aceptación actual en harness.
- `PlantCareAI/Features/PlantList/Domain/{Plant,PlantRepository,SavePlantUseCase}.swift` — modelo inmutable, validación obligatoria y contrato sin update.
- `PlantCareAI/Features/PlantList/Data/{LocalPlantRepository,PersistedPlant,StorageTestFixture}.swift` — actor, save explícito/rollback, campos existentes y fixtures Debug Simulator.
- `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel,PlantCardViewModel}.swift` — NavigationStack UUID, hasLoaded y snapshot `let plant` en cards.
- `PlantCareAI/Features/PlantDetail/Domain/LoadPlantDetailUseCase.swift`, `Presentation/{PlantDetailView,PlantDetailViewModel}.swift` — detalle por UUID, metadata/foto separadas; load no relee metadata ya loaded.
- `PlantCareAI/PlantCareAIApp.swift`, primeras 90 líneas de `Localizable.xcstrings`, `PlantCareAI.xcodeproj/project.pbxproj`, `init.sh` — composición, español y fuentes registradas manualmente.
- `PlantCareAITests/{LocalPlantRepositoryTests,PlantListViewModelTests}.swift`, primeras 85 líneas de `PlantDetailViewModelTests.swift`, `PlantCareAIUITests/PlantCareAIUITests.swift` completo — XCTest y E2E persistente existentes.
- Directorios raíz/docs/specs/adr y búsqueda `**/*.{png,html}`: no spec previa de edit-plant ni PNG/HTML local encontrado. No adjuntos accesibles; no se inspeccionaron imágenes/Stitch originales. DESIGN.md prevalece sin ampliar alcance.

### Existing Patterns / Current Gaps

- SwiftUI iOS 17+, VMs MainActor/ObservableObject, ownership StateObject, casos de uso inyectados; Domain Foundation/Sendable; adaptador actor único por almacén.
- `savePlant` es alta exclusiva y rechaza UUID duplicado: no reutilizarlo como edición, ni borrar/recrear la planta/foto.
- `PersistedPlant` ya tiene name/location mutables: update no requiere cambiar esquema ni referencia JPEG.
- Listado carga una vez, cards contienen snapshots inmutables y detalle conserva loaded: un simple dismiss/onAppear no refrescará lo necesario.
- Fixture `--storage-verify` exige modelos originales exactos: usarlo tras editar daría un falso error global; nueva verificación editada debe mantener comparación completa y de bytes.

## Technical Approach

### Domain / Data

- Crear `Features/EditPlant/Domain/UpdatePlantUseCase.swift`: caso concreto `UpdatePlant`, repository inyectado, `execute(id:name:location:) async throws -> Plant`; protocolo adicional de caso de uso no necesario, tests usan repository doble.
- Ampliar `Features/PlantList/Domain/PlantRepository.swift` con `updatePlant(id: UUID, name: String, location: String?) async throws -> Plant` y error `.notFound`. Contrato estrecho: no acepta un Plant completo ni campos no editables.
- Validación/normalización propuesta en la sección de revisión: centralizar en Domain y aplicar también en Data al llamar directamente; no depender solo del botón disabled. No límites arbitrarios ni unicidad de nombre.
- `LocalPlantRepository` obtiene registro por UUID, valida antes de mutar, modifica **solo** name/location, invoca seam beforeCommit y context.save; retorna Plant canónico tras éxito. Sin await entre fetch/mutación/commit, sin IO de JPEG, upsert ni fallback vacío.
- En fallo de escritura ejecutar rollback; conservar error notFound/validation distintos de storage. Reapertura debe recuperar valores antiguos tras fallo y nuevos tras éxito. Mantener referencia/ficha/fecha/ID y orden existentes; mismo esquema.
- Reutilizar Plant/CareSheet/PlantRepository de Domain PlantList y el adaptador Data existente; no carpeta Data ficticia en EditPlant ni repositorio nuevo.
- Flujo: `EditPlantView → EditPlantViewModel → UpdatePlant → PlantRepository ← LocalPlantRepository`; wiring en `PlantCareAIApp` sobre la instancia elegida después del override Debug.

### Presentation / composición / refresco

- Crear `Features/EditPlant/Presentation/{EditPlantView,EditPlantViewModel}.swift`. Sheet con NavigationStack propio solo para toolbar modal/Form nativo; el stack push de colección se conserva.
- VM recibe Plant precargado del detalle y UpdatePlant; conserva UUID inmutable y borradores separados del Plant persistido. Estados editing/saving/error/saved; save captura valores, evita duplicados, publica éxito una vez y no simula cancelación de commit.
- `PlantDetailViewModel` recibe UpdatePlant y callback MainActor de actualización local; fábrica de editor sin IO, solo en loaded. Modal posee editor StateObject estable por presentación; nueva presentación descarta VM/borrador anterior.
- Tras éxito, aplicar el Plant devuelto al state loaded del detalle y avisar al listado, después dismiss. No invalidar imagen de detalle ni reload foto por edición; guardas impiden que respuestas metadata antiguas sobrescriban el commit.
- `PlantListViewModel` inyecta UpdatePlant al destino y recibe resultado mediante callback débil para evitar ciclos; reemplaza por UUID el Plant en state loaded y metadata del card existente.
- Cambiar `PlantCardViewModel.plant` a `@Published private(set)` y añadir actualización metadata del mismo UUID, preservando identidad del VM y photoState/cache/tareas. No recrear todos los cards ni rerun StorageFixtureLoad/seed/verify.
- Callback representa resultado de escritura ya confirmada, no optimismo. No event bus, singleton ni dependencia Domain → Presentation; ningún VM de editor conoce listado ni adaptador concreto.
- Toolbar superior trailing con botón textual visible «Editar» solo habilitado para loaded; sin ocultarlo en menú de puntos. IDs: `editPlant-<UUID>`, `editPlantForm-<UUID>`, `editPlantName`, `editPlantLocation`, `cancelEditPlant`, `saveEditPlant`, `editPlantValidation`, `editPlantError`.
- Actualizar todos los doubles conformes a PlantRepository por el nuevo requisito; no default implementation que simule éxito. Mantener tests originales y navegación Atrás por identificador/etiqueta cuando toolbar añade otro botón.

## Visual Design Impact

- UI sí: toolbar de detalle y sheet editing/invalid/saving/error. Fuente: DESIGN.md y decisión confirmada del usuario, no propuesta visual de Stitch no inspeccionada.
- Formulario mínimo nativo de dos campos con etiquetas persistentes (no solo placeholders), título «Editar planta», «Cancelar» leading/«Guardar» trailing. Tokens existentes, tipografía SF/Dynamic Type; sin nueva foto, avatar, vista previa editable o cabecera decorativa.
- Progreso y texto accesible durante guardado; error inline «No se pudieron guardar los cambios en este dispositivo. Inténtalo de nuevo.»; ausencia «No se encontró esta planta en el dispositivo.»; validación «Introduce un nombre para esta planta.».
- Campos y errores desplazables con teclado; focus/submit nativos y accesibilidad de estado/acciones. No alturas fijas ni truncar nombres largos; texto de usuario literal, no LocalizedStringKey.
- Solo claves usadas en Localizable.xcstrings, español/fallback español. Sin artefacto visual externo requerido; comprobar apariencia real en futura sesión autorizada.

## Expected File Changes (futuros; planner no modifica código)

- Crear `PlantCareAI/Features/EditPlant/Domain/UpdatePlantUseCase.swift` y `Presentation/{EditPlantView,EditPlantViewModel}.swift`.
- Modificar `PlantCareAI/Features/PlantList/Domain/PlantRepository.swift` y `Data/LocalPlantRepository.swift` — contrato update/error/commit; PersistedPlant sin cambio de esquema.
- Modificar `PlantCareAI/Features/PlantDetail/Presentation/{PlantDetailView,PlantDetailViewModel}.swift` — acceso/modal/resultado canónico.
- Modificar `PlantCareAI/Features/PlantList/Presentation/{PlantListViewModel,PlantCardViewModel}.swift`, `PlantCareAI/PlantCareAIApp.swift`, `Localizable.xcstrings` — inyección/refresco/copy.
- Crear `PlantCareAITests/{UpdatePlantTests,EditPlantViewModelTests}.swift`; ampliar LocalPlantRepositoryTests, PlantListViewModelTests, PlantDetailViewModelTests, PlantCardViewModelTests y doubles en LoadPlantDetailTests según compilación.
- Ampliar `PlantCareAIUITests/PlantCareAIUITests.swift`, fixture Debug `StorageTestFixture.swift` para verificación editada aislada, y project.pbxproj para fuentes/grupos/app/unit targets explícitos.
- Docs futuras: ARCHITECTURE.md, ADR corto 002, guía de pruebas, PROGRESS.md y feature_list.json. ContentView, assets, init.sh y esquema persistente intactos.

## Durable Documentation Impact

- Ahora: crear **solo** `docs/specs/edit-plant.md`; PROGRESS/feature list intactos y sin evidencia de ejecución nueva.
- `ARCHITECTURE.md`: actualizar mapa EditPlant, contrato de update y callback de refresco; retirar «sin edición», mantener dependencia entre capas.
- `docs/adr/002-local-plant-editing.md`: propuesta corta durante implementación tras aprobación, porque amplía contrato compartido de escritura y coherencia entre features; explicar update estrecho, actor/rollback, resultado canónico y migración no necesaria.
- `CONSTRAINTS.md`, `AGENTS.md`: no necesario, sin cambios de restricciones/workflow.
- `DESIGN.md`, `CONTEXT.md`, `docs/{build-brief,domain-model,risks-and-open-questions}.md`: no necesario, edición ya prevista y sin ampliar modelo/alcance. ADR 001: no necesario cambiar decisión del medio.
- `docs/testing-local-plant-storage.md`: actualizar flujo modal/reapertura editada/cleanup y advertir no usar verify original tras editar.
- `PROGRESS.md` y `feature_list.json`: siguientes roles registran pruebas reales, límites y estados honestos; passing solo autoverificación, accepted solo validación independiente autorizada.

## Implementation Plan / Tasks (después de revisión y autorización)

1. Confirmar raíz/rama/diff y baseline ./init.sh en futura sesión autorizada; preservar cambios ajenos y aceptación previa.
2. Implementar update Domain/Data con tests de validación, aislamiento, ausencia y rollback/reapertura.
3. Implementar editor y estados, componer dependencia y callback, añadir metadata observable de cards y proteger snapshots tardíos.
4. Añadir toolbar/sheet/Form/localización/IDs, registrar fuentes y adaptar doubles/asserts Atrás sin perder cobertura.
5. Extender E2E persistente y verificación editada Debug, ejecutar gate/focalizadas/inspección y documentar evidencia para validator.

- [ ] Contrato estrecho y Data actualizan dos campos por UUID sin tocar fotos ni insertar.
- [ ] Cancelar/descarte sin escritura, validación, save único y error recuperable con borradores conservados.
- [ ] Resultado confirmado actualiza detalle/card/state listado y preserva caché/identidad.
- [ ] Pruebas de dos ejemplares, reapertura, nil ubicación, fallo/rollback y respuestas tardías.
- [ ] UI/formulario accesible sin acceso desde tarjetas ni campos extras; docs y evidencia honestas.

## Verification Plan (futuro; NO ejecutado por planner)

- E2E persistente existente: XCUITest via ./init.sh; añadir tests enfocados, no basta unit coverage.
- UpdatePlantTests: UUID y dos campos correctos; reglas normalización aprobadas, blanco rechazado antes de repo, nil ubicación, sin llamadas savePlant/fotos; error propagado.
- LocalPlantRepositoryTests: dos misma especie, editar A, recrear repo y comparar modelos completos/bytes originales, B intacta; borrar/añadir ubicación; UUID desconocido no inserta; validar llamada Data directa; fallo beforeCommit después de mutación revierte ambos campos en mismo repo y reabierto, permite posterior reintento correcto. Foto ausente no impide update ni se repara.
- EditPlantViewModelTests: precarga/nueva sesión, draft separado, save captura datos/retorna canónico, error conserva draft, doble toque cuenta una operación, cancel/descarte cero escrituras, no éxito prematuro con operación suspendida. Continuations/puertas, sin sleeps artificiales.
- Detail/List/Card tests: resultado UUID actualiza ambos snapshots y labels, mismo objeto card/cache imagen preservados, B intacta y orden igual; respuesta metadata antigua no revierte commit; editor inaccesible en loading/notFound/failed pero disponible con photo.failed.
- UI: abrir A desde tarjeta → Editar → modificar/guardar → detalle nuevo → Atrás → tarjeta nueva → A/B; relanzar sin desinstalar/seed y volver a verificar ambos detalles. Añadir cancelar/gesto, validación, eliminar/añadir ubicación y edición con foto fallida; save failure por dobles unit/integración, sin flags de corrupción de producción.
- Para E2E editada añadir flag Debug Simulator `--storage-verify-edited` con expectativas exactas del escenario (A nombre «Mi monstera», ubicación «Salón», B original), comparar Plant completo reconstruido preservando campos inmutables y bytes de ambas fotos; no debilitar --storage-verify. Relanzar con mismo --storage-test-id y nuevo flag, sin --storage-seed. Otros escenarios nil/cancel se prueban por assertions y tests de repositorio.
- Conservar UI previas vacío/error/foto/dos fichas/fallback español. Sustituir selección de Atrás `.buttons.firstMatch` cuando sea necesario por Atrás explícito; no quitar pruebas por añadir Editar.
- Comandos para futura sesión autorizada, elegir UDID disponible:

```sh
./init.sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAITests' \
  '-only-testing:PlantCareAIUITests/PlantCareAIUITests' test
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/DerivedData/ReleaseCheck" build
plutil -lint PlantCareAI.xcodeproj/project.pbxproj
python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null
git diff --check
```

- init.sh intacto: ejecuta build/unit/UI y termina, no solo guía ni procesos largos. Release sin símbolos/argumentos nuevos de fixtures.
- Manual: claro/oscuro, pantalla pequeña, Dynamic Type máximo, teclado y VoiceOver/orden/errores, Cancelar/gesto y Atrás, offline sin API; restaurar configuración y limpiar solo fixture. Registrar límites reales, no equiparar XCTest con lectura VoiceOver o prueba física de disco.

## Risks / Decisions / Open Questions For Human Review

- **Confirmado:** únicamente nombre personalizado y ubicación opcional; «Editar» visible en barra superior del detalle → formulario modal nativo «Cancelar»/«Guardar»; sin edición desde tarjetas ni extras de Stitch.
- **Propuesta pendiente de revisión del usuario:** nombre obligatorio como validación existente; recortar espacios/saltos de línea exteriores en ambos campos al guardar, ubicación blanca → nil; conservar interiores, acentos/emoji y permitir nombres repetidos, sin límites arbitrarios. Los escenarios técnicos de normalización quedan sujetos a esta aprobación, no se presentan como decisión confirmada.
- **Propuesta de interacción pendiente de revisión:** gesto descarta sin diálogo antes de guardar, igual que Cancelar; durante commit bloqueo temporal de Cancelar/gesto para no aparentar deshacer una escritura ya iniciada. Sin autosave ni aviso de cambios no guardados. Si el usuario prefiere confirmación de descarte, revisar contrato antes de implementar.
- Riesgos principales: snapshots obsoletos por hasLoaded/let plant/detail cache; rollback de SwiftData; fixture verify original rechaza cambios esperados. Mitigación explícita en arquitectura/tests anteriores.
- No bloqueo de dependencia/datos identificado. No imágenes originales inspeccionadas ni cotejo visual fino; no necesita inventar recursos. Lookup O(n), JPEG completo y pipeline de importación conservan límites previos fuera de alcance.
- Siguiente paso único: revisión humana de esta spec y propuestas; no iniciar implementer/validator hasta aprobación/autorización.

## Evidence To Capture / Validator Checklist

- Futuro: logs/xcresult con entorno/UDID, modelos+bytes antes/después/reapertura, tests rollback, capturas modal/validación/error y detalle/colección editados/texto máximo; limitaciones manuales en PROGRESS/feature list, sin logs sensibles.
- [ ] Solo dos campos; acceso visible desde detalle, modal nativo y ninguna edición directa desde tarjetas.
- [ ] Cancel/descarte sin escrituras, validación Domain/Data y save/error honestos; propuestas aprobadas antes de implementación.
- [ ] Commit por UUID modifica solo name/location, sin upsert/fotos/esquema/red; aislamiento completo y rollback comprobados.
- [ ] Detalle y colección coherentes inmediatamente y tras relanzar; VM/imagen de cards conservados, B intacta.
- [ ] Clean + MVVM, inyección desde app, un repositorio elegido tras override Debug; fuentes registradas.
- [ ] E2E actualizado y cobertura previa preservada, fixture editado compara modelos completos y bytes, Release limpio.
- [ ] Accesibilidad/localización/inspección real y límites documentados; estados según evidencia/rol autorizado. Planificación no equivale a passing/accepted.
