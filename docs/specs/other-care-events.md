# Feature Implementation Spec: Registrar otros cuidados fechados

## Source Feature / estado de planificación

- `id`: `other-care-events`; `area`: `cuidados`; fuente: `feature_list.json`.
- Título: Registrar otros cuidados fechados. Comportamiento: guardar abonado, poda, trasplante u otro con fecha y nota opcional en su planta.
- `depends_on`: `quick-watering`, comprobada `accepted` en feature_list/PROGRESS; evidencia independiente en `docs/validations/quick-watering.md` referenciada por esos documentos, no reejecutada aquí.
- `status`: `not_started`; `evidence`: `[]`. No cambiar estados ni evidencias históricas en este paso.
- Verificación de origen: guardar cada tipo, reiniciar y comprobar aislamiento por planta; gate estándar.
- Planner ONE STEP, 2026-10-12; skills `feature-spec` e `ios-clean-mvvm` aplicadas.
- Worktree exclusivo `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/other-care-events`; rama `feature/other-care-events`, base main/origin/main `a2fe57f751bf9324f85814ce1fc9d0b175e3b7b1`: contexto aportado por el orquestador, no nueva comprobación Git del planner.
- **Borrador implementación-ready pendiente de revisión humana integral. No autoriza implementar, validar ni publicar.**

## Goal / Job Story / Usuarios

Cuando consulto un ejemplar que he cuidado, quiero elegir el tipo, fecha y nota opcional en un único formulario, para conservar mi registro humano local solo en ese UUID.

Contrato confirmado por usuario: **un único popup Registrar cuidado con Riego, Abonado, Poda, Trasplante y Otro**, sustituyendo el popup de riego. Renombrar el acceso del detalle a Registrar cuidado. Abrir sin tipo seleccionado; Guardar cuidado deshabilitado hasta elegirlo. Mantener reglas aceptadas de fecha, nota y persistencia.

Único usuario local, sin permisos nuevos, cuentas, perfil, red ni consentimiento IA. Metadata loaded permite registrar aunque la foto esté cargando o falle. Caso rápido de riego: abrir → elegir Riego → Guardar cuidado, **tres taps desde detalle loaded**, delta autorizada sobre los dos taps históricos, no regresión encubierta.

## Non-Goals

- Segundo popup, ruta paralela de riego, tipo preseleccionado, guardado al abrir/seleccionar/cancelar o autosave.
- Historial/cronología visible, última-fecha/sugerencias calculadas, recomendaciones, análisis/IA, fotos nuevas, eliminar/Deshacer, acceso desde tarjetas.
- Cantidad/unidad, fertilizante estructurado, nombre de tipo libre para Otro, salud/humedad observadas, selector de hora/zona o procedencia persistida nueva.
- Cambiar nombre/ubicación, ficha orientativa o JPEG de Plant; rediseñar editor, colección o seis tarjetas de cuidados.
- Avatar/cuentas del HTML, datos/fechas/fotos de muestra, fuentes/CDN/CSS/Tailwind/Material Symbols o dependencias externas.
- Footer prohibido por quick-watering («Registro manual del usuario…» o paráfrasis sustitutiva); no recuperarlo.
- Garantías de downgrade, escritores multiproceso, recuperación de borradores o daño físico.

## Acceptance Scenarios — Given / When / Then

### 1. Apertura vacía y selección reversible
Given detalle A loaded y B de igual especie pero UUID propio, When pulso Registrar cuidado,
Then aparece una sola sheet con ese título, nombre/foto propios de A o placeholder, mensaje de pertenencia, cinco tipos sin selección, Hoy seleccionado y nota vacía; CTA Guardar cuidado deshabilitada; cero writes/éxito.
Given metadata loading/notFound/failed, Then no puede abrirse; foto fallida con metadata loaded sí permite abrir y guardar.
When elijo Abonado, Then solo Abonado muestra borde/check y trait selected, CTA habilitada.
When elijo Poda, Then sustituye exclusivamente Abonado, sin borrar fecha/nota ni escribir.
When pulso otra vez Poda, Then queda sin tipo y CTA deshabilitada, conservando fecha/nota.
When invoco save sin tipo incluso fuera de la vista, Then cero despachos/callbacks; nunca asumir watering.

### 2. Cada tipo y commit real
Given una sesión nueva para A, When elijo cada tipo y guardo fecha válida/nota opcional,
Then se confirma exactamente un evento del tipo elegido y siete campos completos; solo tras commit cierra y muestra «Cuidado registrado» en detalle.
Then B y todos los campos/fotos/ficha de A permanecen exactos; no aparece última-fecha, Deshacer ni recomendaciones nuevas.
Given dos intenciones explícitas iguales el mismo día, Then UUID distintos y ambos registros legítimos.
Given una reapertura, Then tipo nil, fecha actual y nota vacía, sin restaurar selección/banner/borrador anteriores.

### 3. Fecha, nota y zona aceptadas
Given sesión con tipo elegido, When uso DatePicker/Ayer/Hoy o fecha prealta y nota multilínea,
Then fecha/chips coherentes; persiste inicio del día gregoriano en origen IANA y nota trim extremos/blanca→nil, interiores/saltos/Unicode/longitud intactos.
Given fecha futura/no finita/día civil omitido/zona inválida, When intento registrar, Then error de validación y cero nuevas inserciones; no truncar ni desplazar silenciosamente el día.
Given cambio de zona actual, Then solo se convierte representación del instante, pudiendo cambiar el día; origen/payload no se reescriben. Siguiente elección humana de fecha captura nueva zona.
Given retry sin editar tras cambio de zona/medianoche, Then conserva los siete campos; no recaptura Hoy ni createdAt.

### 4. Cancelación, busy y error local
Given sesión antes de despacho, When Cancelar/gesto/cierre de proceso, Then cero writes/confirmaciones y reapertura limpia.
Given escritura despachada, Then tipos/fecha/chips/nota/CTA/Cancelar/gesto bloqueados, spinner «Guardando cuidado…»; doble tap no duplica; éxito no se descarta por cancelación técnica tardía.
Given fallo de commit, Then rollback comprobable en disco, sheet conserva tipo/fecha/nota, error «No se pudo guardar el cuidado en este dispositivo. Inténtalo de nuevo.» y «Reintentar guardado», sin pedir conexión.
When reintento sin editar, Then mismo UUID/payload completo, una inserción final/callback, sin retry automático.
When cambio tipo, lo deselecciono o edito fecha/nota tras fallo, Then invalida snapshot/error; siguiente guardado válido es intención nueva, nunca reutiliza UUID con payload cambiado.

### 5. Persistencia, compatibilidad y conflictos
Given store V2 de quick-watering con watering confirmado, When abro nueva versión y agrego otros tipos/reinicio sin reseed/desinstalar,
Then recupero eventos antiguos y nuevos completos solo por su plantID, ambos Plant/JPEG exactos y orden occurredAt desc/createdAt desc/UUID asc conservado.
Given UUID confirmado idéntico, Then éxito canónico sin save, incluso si retrocede reloj; mismo UUID con kind u otro campo distinto da conflict, nunca overwrite.
Given planta ausente/store ilegible/raw kind desconocido, Then error explícito, nunca éxito ni lista vacía como fallback ni limpieza destructiva.

### 6. Presentación funcional y regresiones
Given vacío, Abonado seleccionado, error/busy, foto fallida y textos largos, Then layout/controles/teclado/CTA alcanzables por scroll en iPhone estándar; no claves crudas ni truncamiento horizontal.
Then editor de nombre/ubicación mantiene apariencia/conducta/IDs aprobados y no crea eventos ni IO fotográfico nuevo. Detalle mantiene identidad/seis cuidados completos y navegación UUID.

## Repository Research

### Inspeccionado realmente
- `AGENTS.md`, `PROGRESS.md` reciente, `feature_list.json`, `CONTEXT.md`, `CONSTRAINTS.md`, `ARCHITECTURE.md`, `DESIGN.md`; ambas skills y template feature-spec.
- `docs/{build-brief,domain-model,risks-and-open-questions,testing-ui}.md`, `docs/specs/quick-watering.md`, `docs/adr/008-local-care-events.md`. Spec other-care-events no existía; docs/product-brief y otros discovery del template no figuran en docs, se usa build-brief vigente.
- `PlantCareAI/Features/QuickWatering/Domain/{CareEvent,CareEventRepository,RegisterWateringUseCase}.swift`, `Presentation/{QuickWateringView,QuickWateringViewModel}.swift`, `Data/{PersistedCareEvent,WateringTestFixture}.swift`.
- `Features/PlantList/Data/LocalPlantRepository.swift`, tramos relevantes de `PlantListViewModel`, `PlantDetailView/ViewModel`, `PlantCareAIApp.swift`, `Shared/Presentation/PlantFormHeader.swift`.
- `PlantCareAITests/{RegisterWateringTests,QuickWateringViewModelTests,LocalCareEventRepositoryTests}.swift`; clase QuickWateringUITests y edición adyacente en `PlantCareAIUITests/PlantCareAIUITests.swift`; referencias pertinentes de `project.pbxproj`; `init.sh` completo.
- Referencias visuales: descripción y decisiones de dos HTML (vacío/Abonado) transmitidas en prompt padre. Los HTML completos/archivos/capturas no estaban disponibles en este contexto; no se afirma inspección directa ni equivalencia pixel-perfect.

### Hallazgos y gaps
- CareEvent tiene siete campos; Kind solo `.watering`; raw persistido String y mapping con rechazo de desconocidos. Igualdad nota por UTF8, no solo equivalencia Unicode de String.
- RegisterWatering ya contiene reglas genéricas temporales/nota; VM fija watering al crear snapshot, no tiene selección. Vista usa TextField vertical 3...8, no TextEditor.
- LocalPlantRepository es único actor/escritor: mismo Plants.store/container/contexto, fetch planta/duplicado→validate→insert→save sin await, rollback; store valida eventos antes de cleanup. No nueva entidad ni migración necesaria por ampliar valores del String.
- Detalle tiene una sheet riego y otra distinta para editar identidad; fábrica solo loaded, snapshot UIImage, callback session/plantID y banner efímero. No IO de foto desde formularios.
- PlantFormHeader usa foto48; fixture watering captura payload7 pero verify solo A y asume nota uniforme: debe ampliar expectativas independientes por tipo/UUID, no limitar casos nuevos a ese supuesto.
- Project registra fuentes explícitamente. E2E persistente disponible mediante XCUITest/./init.sh; no harness web ni API necesario para esta feature.

## Technical Approach

### Refactor único por capacidad, sin duplicación
Generalizar y mover el módulo `Features/QuickWatering` a `Features/CareEvents`, preservando capas. Renombrar RegisterWatering→RegisterCareEvent, QuickWateringView/VM→RegisterCareView/VM. No conservar segundo formulario ni wrapper/implementación de reglas duplicadas. Actualizar todos los callers y pruebas, manteniendo cobertura histórica con delta explícita de tres taps/sin preselección. No reescribir specs aceptadas.

Domain: `CareEvent.Kind` raw estable `watering`, `fertilizing`, `pruning`, `repotting`, `other`, orden UI Riego/Abonado/Poda/Trasplante/Otro; Codable no necesario para entidad. Presentación/localización/iconos fuera de Domain. Mantener modelo7/campos/equatable UTF8 y CareEventRepository save/load sin ampliación de PlantRepository. RegisterCareEvent conserva execute/normalización/validación para todos los tipos, sin introducir rutas/SwiftUI/SwiftData ni protocolo innecesario.

Fecha/nota: conservar literalmente reglas y tests de ADR008/implementación aceptada: Gregorian startOfDay/origen IANA admisible, Ayer día calendario, DST/día omitido, finitud/futuras bloqueadas/prealta permitida. occurredAt absoluto; createdAt primer despacho; presentación zona ACTUAL. DatePicker mantiene `latestSelectableDate = max(now, occurredAt)` para no expulsar selección retenida al viajar/retroceder reloj; Domain/Data rechazan nueva inserción futura. Retry origen/siete campos inmutables; lectura no valida contra hoy. Nota sin límite/truncamiento; trim no normaliza Unicode interior.

Data: reubicar archivo PersistedCareEvent sin renombrar clase `@Model`, entidad, propiedades ni ruta/schema V2. Mapping admite exactamente cinco raws; unknown sigue error. Adaptador existente referencia RegisterCareEvent para reglas; conservar actor/atomicidad/rollback/dedup previo al reloj/no-upsert/orden/no IO JPEG nuevo. No schema V3, backfill ni reset: compatibilidad V2 con watering debe probarse en disco; mantener prueba V1→V2 existente. En versión vieja otros raws pueden fallar al leer: no prometer downgrade.

Presentation: `selectedKind: CareEvent.Kind? = nil`, estado editing/saving/error/saved y `canSave` exige selección/ausencia busy/saved (fecha inválida sigue error de dominio). `selectKind` exclusiva con toggle nil, conserva fecha/nota, invalida snapshot/error al cambiar y está bloqueada busy/saved. Guard save exige kind incluso si se invoca programáticamente. Snapshot7 canónico en primer despacho; retry sin editar reutiliza exactamente ese snapshot, callback solo confirmado==snapshot y una vez.

Composición: `RegisterCareView → RegisterCareViewModel → RegisterCareEvent → CareEventRepository ← LocalPlantRepository`. App compone después de overrides Debug y pasa a PlantListVM/fábrica de detalle. Detalle renombra sesión/fábrica/confirmation a care, mantiene guard UUID/session/débil y limpia banner al abrir; solo un `.sheet` para cuidado (editor de identidad distinto permanece). No recarga ficha/lista/foto por evento. Cancel/gesto antes del despacho no invoca use case; después bloqueados.

## Visual Design Impact

- Referencias HTML como dirección + DESIGN/tokens actuales; sheet blanca/grabber nativo/esquinas24/toolbar Cancelar izquierda/título centrado; sin avatar ni barra web.
- Cabecera contexto foto propia snapshot56/radio12/nombre multilínea/mensaje «El registro se guardará exclusivamente para este ejemplar». Parametrizar tamaño de PlantFormHeader con default48 para editor intacto; cuidado usa56. Loading/failed→placeholder leaf.fill, sin decode/IO nuevo.
- Formulario inset SurfaceMuted/radio16/margen20/spacing16, inputs Surface/radio12, grupo de tipos con encabezado «Tipo de cuidado».
- Grid dos columnas iguales: filas Riego–Abonado, Poda–Trasplante, Otro en columna izquierda con celda derecha sin control ni tipo ficticio. Todas las opciones mismo ancho; soporte adaptable sin recorte. Decisión deliberada para cinco tipos, no importar grid4 de muestra.
- SF Symbols iOS17: drop.fill, leaf.fill, scissors, arrow.triangle.2.circlepath, ellipsis.circle; confirmar render real. Selección borde PrimaryAction/checkmark.circle.fill y fondo CareMint/acento/icono; texto y `.isSelected`, no solo color. Targets min44.
- DatePicker nativo compacto solo fecha con píldora/locale español, calendario/zona explícitos; Ayer/Hoy min44/check, Hoy activo al abrir aunque ningún tipo lo esté. Sin fecha hardcoded ni hora.
- TextEditor nativo opcional, vacío, altura inicial aproximada tres filas/min90, accesible/multilínea, sin ejemplo default; Done solo quita foco. Texto largo desplazable sin límite de dominio; fondo Surface controlado.
- CTA cápsula52 ancho completo «Guardar cuidado», aspecto deshabilitado real/neutro al faltar tipo, verde PrimaryAction tras elección; spinner/error/retry local. CTA alcanzable por scroll/teclado, no footer fijo nuevo.
- IDs propuestos: `detailRegisterCare-<UUID>`, `careForm`, `careKind-<raw>`, `careDate`, `careToday`, `careYesterday`, `careNote`, `saveCare`, `cancelCare`, `dismissCareKeyboard`, `careError`, `careSaving`, `careConfirmation`; actualizar selectores y assertions antiguos, conservar los de editor/header.
- Confirmación genérica «Cuidado registrado», no nombres gramaticales por tipo ni banner antes del commit. Mantener bloque de consejo estático de sustrato existente sin convertirlo en recomendación derivada del tipo; no ampliar su contenido.

## Expected File Changes — futuros, solo tras autorización

- Mover seis fuentes app de QuickWatering a CareEvents, renombrando use case/view/VM y `WateringTestFixture`→`CareEventTestFixture` (son siete contando fixture); conservar nombre/modelo PersistedCareEvent y protocolos. Sin nuevo repositorio.
- `Features/PlantList/Data/LocalPlantRepository.swift`: referencias a reglas renombradas; invariantes/schema intactos.
- `PlantDetailView.swift`, `PlantDetailViewModel.swift`, `PlantListViewModel.swift`, `PlantCareAIApp.swift`: inyección, sheet única, nombres/IDs/feedback genéricos.
- `Shared/Presentation/PlantFormHeader.swift`: parámetro foto con default48. EditPlantView/VM/Domain sin cambios previstos.
- `PlantCareAI/Localizable.xcstrings`: claves care/tipos/textos nuevos y detalle; retirar únicamente watering UI realmente sin callers, no tocar traducciones ajenas.
- `PlantCareAI.xcodeproj/project.pbxproj`: paths/grupos/fuentes y tests explícitos, sin reescribir scheme/harness ni configuración privada.
- Renombrar/ampliar `RegisterWateringTests`→`RegisterCareEventTests`, `QuickWateringViewModelTests`→`RegisterCareViewModelTests`; ampliar `LocalCareEventRepositoryTests`, callers Detail/List y fixture verify de `StorageTestFixture.swift` según referencias.
- `PlantCareAIUITests/PlantCareAIUITests.swift`: QuickWateringUITests→CareEventsUITests; adaptar cinco casos sin quitar cobertura, añadir escenarios tipos/selección/relaunch/errores; ajustar caso StoredCollection/fallback y callers de IDs.
- Sin cambios previstos en ContentView, PersistedPlant, Plant/PlantRepository, assets, init.sh, scripts, secretos ni historial.

## Durable Documentation Impact — implementación posterior

- `ARCHITECTURE.md`: update módulo/capacidad general/callers/cinco tipos; misma dirección de dependencias y actor.
- `DESIGN.md`: update único Registrar cuidado/sin tipo/tres taps/grid/TextEditor; editor mantiene contrato. No borrar decisiones históricas sin indicar delta.
- `docs/domain-model.md`: update capacidad actual cinco tipos y selección obligatoria; mantener campos/tiempo/nota/retry.
- Nuevo `docs/adr/009-unified-care-registration.md`: generalización cross-feature, un formulario, cinco raws sin cambio schema y transición de callers; referenciar ADR008 sin reescribir su evidencia histórica.
- `docs/testing-{ui,local-plant-storage}.md`: update selectores/cobertura/fixture7/tipos/compatibilidad. `docs/risks-and-open-questions.md`: update pendiente otros tipos/downgrade solo si nuevo comportamiento lo exige.
- `PROGRESS.md`/`feature_list.json`: futuros roles registran resultados reales; passing solo con focalizadas válidas, accepted solo independiente. Planner modifica exclusivamente esta spec.
- `CONSTRAINTS.md`, `AGENTS.md`, `CONTEXT.md`, `docs/build-brief.md`: not needed, reglas/vocabulario/2–3 interacciones/alcance ya compatibles. Specs aceptadas, ADR008 y CSV/evidencia histórica intactos.

## Implementation Plan / Tasks

1. Tras revisión humana/autorización, confirmar raíz/rama/diff y coordinar sesión activa; preservar cambios ajenos/historia y mapear todas las referencias del refactor.
2. Generalizar Domain/renombres/Kind, conservar tests temporales/UTF8; probar cinco tipos y conflictos kind.
3. Mantener Data/schema/compatibilidad V2 y V1; adaptar fixture para expectativas por UUID/kind/nota, no solo payload capturado por el producto.
4. VM selección/toggle/canSave/snapshot/errores/busy/callback; inyección/fábrica única/detalle/banner.
5. UI/localización/header56/IDs/TextEditor/grid y target; conservar edición/6cuidados/navegación.
6. E2E por impacto/visual focal/static, docs/evidencia y handoff independiente; no adelantar siguiente feature.
- [ ] Cinco tipos raw estables/roundtrip/old watering exacto; ninguna nueva entidad o migración artificial.
- [ ] Sin preselección; toggle exclusivo; guard save; tres taps default riego; Cancelar cero writes.
- [ ] Retry7/busy/rollback/conflicto kind/tiempo/nota/UUID comprobados, no IA.
- [ ] Un popup, UI accesible/scroll/placeholder/fallback; cobertura histórica mantenida con delta explícita.
- [ ] Docs/target/evidencia seleccionada lista para validator, sin accepted anticipado.

## Verification Plan — futuro, NO ejecutado por planner

### Implementer — impacto → riesgos → selección
- Domain rename/cinco kinds → reglas/consumidores → RegisterCareEventTests: conservar DST/día omitido/futuro/prealta/zonas/nota5k/UTF8 y parametrizar invariantes por cinco tipos.
- VM/UI → selección/canSave/toggle/busy/edit-error → RegisterCareViewModelTests con continuaciones deterministas: nil/save0, selección única, toggle conserva nota/fecha, cambio kind invalida retry, bloqueo de tipo, payload7 estable al viajar, callback una vez/new session.
- Data/mappeo/shared writer → pérdida/conflicto/cleanup → LocalCareEventRepositoryTests completo: cada kind nil/nota, mixed order/filter, same UUID distinto kind conflict, unknown raw error, rollback/retry/duplicado con reloj atrás y Plant/JPEG exactos.
- Compatibilidad: crear store real con watering raw y mismo schema V2, liberar container/contexto antes de reapertura, comparar siete campos antiguos y modelos/JPEG antes/después de agregar cuatro raws y reabrir. No fixture «viejo» sin watering ni reset. Mantener test real V1→V2 existente.
- Fixture verifica valores esperados INDEPENDIENTES de la selección requerida (kind raw, nota exacta, fecha), además de payload7 capturado/UUID/aislamiento tras relaunch; capturar dispatch solamente no detecta que UI haya guardado kind incorrecto.
- CareEventsUITests E2E: conservar cinco recorridos quick-watering adaptados a tres taps/TextEditor; añadir vacío→Abonado→Poda→nil→Otro/fecha-nota preservadas y cada tipo guardado/relaunch, nota blanca, cambiar tipo tras error. A/B UUID propios; nuevas expectativas por evento permiten notas distintas. UI selector calendario fecha anterior/futuras bloqueadas; validación manipulada en unit/integración.
- Callers → PlantDetailViewModelTests/PlantListViewModelTests y regresiones LocalPlantRepositoryTests/EditPlantViewModelTests; UI EditPlantUITests, StoredCollectionUITests, PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation, LocalizationUITests y SavePlantUITests por actor/composición. Si diff final reduce/amplía selección, justificar callers/riesgo, no retirar assertions.
- Evidencia accepted185/185 de dependencia es histórica: reutilizar solo rutas/config/destino relevantes iguales, nunca atribuirla a refactor nuevo. Sin baseline/final full gate automáticos del implementer; si falta evidencia, build/diagnóstico focal. Tras fallo, escenario fallido/afectados primero con hipótesis y fallos preservados; no retries para verde.

Comandos futuros (UDID estándar acordado, DD dedicado, host despierto/tapa abierta, sin competidores; config pública vacía según AGENTS solo cuando se autorice verificar, jamás leer/copiar privada):
```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DD" build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$DD/Build/Products" 0)
xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -maximum-concurrent-test-simulator-destinations 5 \
  -only-testing:PlantCareAITests/RegisterCareEventTests \
  -only-testing:PlantCareAITests/RegisterCareViewModelTests \
  -only-testing:PlantCareAITests/LocalCareEventRepositoryTests \
  -only-testing:PlantCareAITests/LocalPlantRepositoryTests \
  -only-testing:PlantCareAITests/PlantDetailViewModelTests \
  -only-testing:PlantCareAITests/PlantListViewModelTests \
  -only-testing:PlantCareAITests/EditPlantViewModelTests \
  -only-testing:PlantCareAIUITests/CareEventsUITests \
  -only-testing:PlantCareAIUITests/EditPlantUITests \
  -only-testing:PlantCareAIUITests/StoredCollectionUITests \
  -only-testing:PlantCareAIUITests/LocalizationUITests \
  -only-testing:PlantCareAIUITests/SavePlantUITests \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation \
  -resultBundlePath "$DD/focused.xcresult" test-without-building
plutil -lint PlantCareAI.xcodeproj/project.pbxproj
python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null
git diff --check
```
Planificar helper valor1 solo para casos visuales de vacío/Abonado/error/busy/placeholder/teclado afectados al ejecutar esos casos, sin repetir toda selección para capturas; inspeccionar capturas realmente abiertas. Un iPhone estándar/texto normal/una apariencia; ampliadas fuera de rutina/no ejecutadas salvo petición expresa. Release/audit del seam Debug renombrado justificado: build Release generic iOS Simulator y comprobar ausencia de fixture/flags nuevos, sin API real ni config privada; registrar comando final exacto.

### Validator — final gate
Revisar diff/arquitectura/compatibilidad/escenarios y ejecutar **una vez** `caffeinate -dius ./init.sh` sobre fuentes finales, o corroborar gate válido del mismo estado/entorno. init intacto: ejecuta build-for-testing una vez, unit/UI5workers y PhotosPicker real serial con test-without-building/xcresult separados; termina, no inicia servicios. Ambas fases verdes y descubrimiento real, no prometer185 tras tests nuevos. No repetir focalizadas cubiertas salvo gap concreto. Reparación de fuentes/tests/recursos/config relevantes invalida gate y justifica nueva ejecución tras reparación focal; failed nunca aprobado. Esta planificación documental solo exige coherencia, no suite iOS.

## Decisions / dudas por revisar / Evidence / Validator Checklist

- Decisión revisable propuesta: toggle exclusivo a nil al tocar opción activa (HTMLs inconsistentes). Coherente con entrada sin preselección y selección reversible existente; no considerada confirmación explícita del usuario aún.
- Otras decisiones propuestas: grid5 con Otro a izquierda, raws ingleses estables, banner genérico, módulo CareEvents y cabecera56 solo cuidado. No hay dudas bloqueantes identificadas; revisión humana integral pendiente antes de ejecución.
- Riesgos principales: referencias/callers renombrados, compatibilidad raw watering, fixture con expectativas independientes, tipo mutable vs retry7, TextEditor/teclado/scroll/contraste y preservar editor48. Ninguna promesa de implementación comprobada.
- Capturar en futuros roles: diff→riesgos→selección/comandos/log/exit/xcresult, fuentes/destino/config pública/entorno, evidencia nueva vs reutilizada, kind/UUID/payload7 independientes tras relaunch/compatibilidad, capturas abiertas y full gate pendiente/verificado. No registrar notas humanas/fotos/secretos en logs de producto.
- [ ] Cinco tipos reales aislados por UUID, old watering intacto y errores no vacíos; Plant/JPEG exactos.
- [ ] Único popup sin tipo inicial, toggle y tres taps riego; CTA/guard/busy/cancel/retry/conflict correctos.
- [ ] Reglas aceptadas fecha/nota/zona/UTF8/actor/composición/target conservadas; no IO foto nuevo.
- [ ] Vacío/selección/error/busy/placeholder/largos/fallback visuales; editor/6cuidados sin regresiones.
- [ ] No historial/recomendaciones/cuentas/footer/última-fecha/Deshacer ni dependencias externas.
- [ ] E2E/regresiones/documentación/evidencia honesta/gate independiente y estados correctos.

## Planner Handoff

Único archivo documental previsto/modificado: esta spec. Revisión documental de coherencia con entrada other-care-events, reglas/código aceptado inspeccionado y checklist de skill; no comandos shell/pwd/Git disponibles en este runtime, por lo que no se reclama git diff --check ni estado Git comprobado. Raíz localizada por rutas absolutas retornadas en lecturas/búsquedas. Sin implementación, validación de código, build/tests/init/simulador, acceso a secretos, stage/commit/push/PR/merge/GitHub ni delegación. **Siguiente paso exclusivo: revisión humana; detener planner.**
