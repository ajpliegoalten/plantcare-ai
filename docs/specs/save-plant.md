# Feature Implementation Spec: Añadir ejemplar confirmado a Mis plantas

## Source Feature / estado de revisión

- `id`: `save-plant`; `area`: `alta`; fuente: `feature_list.json`.
- `depends_on`: `generate-care-sheet`, `local-plant-storage`, `plant-cards`: comprobadas `accepted`.
- Estado: `not_started`. Planificación 2026-10-11; **las tres decisiones funcionales fueron confirmadas por el usuario; no autoriza implementación**.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/save-plant`; rama/base: `feature/save-plant` / `f4473e33406bf4236c5382c65c2c0f5436ed30a8` (`main` local).
- Metadata de origen: «Tras revisar la ficha, el usuario guarda un ejemplar con foto, nombre propio, especie, cuidados y ubicación opcional».
- Verificación de origen conservada: alta de dos ejemplares de la misma especie, reinicio e identidades/fichas/fotos independientes.

## Goal / delta explícitamente solicitada

El usuario indica: «No quiero que esa vista se muestre, se deben pedir los datos y si son correctos, es decir los necesarios para completar la ficha se debe proceder a guardar la planta sin mostrar ninguna pantalla de resumen».

Tras la intención humana existente **Confirmar especie**, obtener cuidados autorizados, validar integridad estructural y persistir automáticamente el ejemplar con su JPEG preparado. No mostrar `CareSheetReviewView`, resumen de identidad, seis cuidados previos al alta, formulario de nombre/ubicación ni un CTA adicional Guardar/Generar. La ficha seguirá consultable en el detalle existente **después** de guardar, por navegación voluntaria.

**Decisión confirmada por el usuario:** seleccionar una especie propuesta o seleccionar la opción manual y completar su texto; al pulsar **Confirmar especie**, solicitar su ficha de cuidados y, si está completa y válida, guardar directamente. Seleccionar por sí solo no envía ni guarda. No mostrar ninguna pantalla de resumen ni de confirmación adicional entre ese botón y el retorno a Mis plantas. Se conserva el aviso de privacidad vigente cuando corresponda antes del envío externo; no es una confirmación de alta nueva.

Este delta reemplaza revisión de cuidados y segunda intención de alta descritas en brief, dominio, DESIGN, CONSTRAINTS y metadata de origen. La confirmación común pasa a expresar intención de incorporar el ejemplar si la ficha es válida. Añadir junto al botón ayuda breve: «Al confirmar, generaremos los cuidados y añadiremos tu planta si la ficha está completa». No añadir aceptación modal ni botón nuevo. No reescribir specs/evidencias históricas aceptadas ni estados de otras features.

## Non-Goals

- Verificar verdad botánica, diagnosticar, RAG, fuentes certificadas, editar/regenerar cuidados válidos.
- Formulario previo, nombre personalizado obligatorio introducido por usuario, ubicación obligatoria, resumen o navegación automática al detalle.
- Nueva entidad de especie, catálogo, migración de esquema, historial/eventos/fotos adicionales; la foto inicial sigue el contrato existente, sin crear una cronología en esta feature.
- Cuentas/backend/sync/notificaciones, cambios de proveedor/credenciales/alcance de datos externos o de disponibilidad manual.
- Rediseñar colección/detalle, adjuntos inexistentes, mockups nuevos, matrices ampliadas o refactor general del VM/transporte.

## Job Story / Users And Permissions

Cuando confirmo la identidad de mi foto, quiero que la app complete y guarde mi ejemplar directamente para encontrarlo en Mis plantas sin una revisión adicional. Único usuario local; propuestas IA nunca se confirman solas. Cada envío conserva `AuthorizeExternalAIOperation` y aviso v4; persistencia local no requiere otro consentimiento externo.

## Acceptance Scenarios (Given / When / Then)

### 1. Seleccionar no es confirmar; alta directa IA
Given foto actual identificada con principal y alternativa, sin preselección,
When selecciono/deselecciono y luego elijo alternativa y pulso Confirmar especie,
Then selección sola hace cero llamadas/escrituras; confirmar genera una sola ficha para esa alternativa y, si válida, guarda un ejemplar, cierra el borrador y muestra su tarjeta en Mis plantas. No se ve resumen, revisión, formulario ni CTA Guardar, ni siquiera un frame tras éxito.

### 2. Vía manual y datos iniciales
Given identificación exitosa actual con cero o más candidatas y nombre manual válido,
When confirmo por el botón común,
Then sigue exactamente la misma cadena; persiste nombre humano normalizado sin inventar taxonomía, nombre inicial automático y ubicación nil. Blanco no confirma; exceso de 2000 caracteres falla antes de red sin truncar. Manual continúa oculto antes de identificar y ante error.

### 3. Integridad sin certificación botánica
Given identidad confirmada, foto vigente y una respuesta de cuidados,
When falta/vacía/excede límite cualquiera de los seis textos, hay JSON inválido/rechazo/truncamiento o vínculo obsoleto,
Then cero altas y ninguna ficha parcial; error de cuidados conserva foto/identidad y permite reintento/cambio de especie. Seis textos válidos son orientación, no prueba de que la especie o consejos sean verdaderos.

### 4. Consentimiento/red y retry remoto
Given alcance no aceptado/antiguo, configuración inválida o petición fallida,
When rechazo/cancelo aviso o aparece error de autorización/red/API,
Then no se guarda y no se envía sin barrera vigente; permanece la foto/identidad. Reintentar cuidados es explícito, una nueva llamada por intención, sin reidentificar ni reenviar JPEG; éxito dispara alta sin revisión. Sin retry automático.

### 5. Fallo local y retry sin IA
Given seis cuidados válidos y snapshot de alta validado,
When falla almacenamiento antes de commit,
Then se muestra «No pudimos guardar tu planta» y «Reintentar guardado», conserva ficha/foto/identidad/UUID/fecha y no añade tarjeta ni archivos nuevos referenciados. Retry usa ese snapshot, cero llamadas adicionales de identificación/cuidados; funciona aunque la API esté indisponible. Cambiar especie/foto invalida snapshot; cancelar edición restaura snapshot fallido y exige retry local, no autoescritura.

### 6. Cancelación y frontera de commit
Given aviso o generación/prevalidación en curso,
When cancelo/cierro antes de despachar la escritura,
Then se descartan continuaciones tardías y cero escrituras; cancelar solicitud permite retry, cerrar descarta el borrador.
Given escritura ya despachada al repositorio,
When intento cerrar/gesto/cancelar/cambiar foto/especie o llega cancelación técnica,
Then controles/gesto están bloqueados hasta resolver commit; éxito se reconoce como guardado, nunca «cancelado» con planta creada ocultamente. Terminar proceso después de commit conserva alta al reabrir; antes de commit aplica rollback/recuperación de huérfanos existente, sin prometer atomicidad ante daño físico.

### 7. Duplicados y aislamiento
Given una intención de alta en marcha o completada,
When llegan doble tap, reaparición de vista, retry repetido o respuesta tardía,
Then como máximo un UUID/commit/callback para esa intención. Dos aperturas/intenciones nuevas de la misma especie y foto crean dos UUID distintos; no deduplicar por nombre/especie/bytes. Conflicto UUID con datos distintos nunca sobrescribe ni se declara éxito.

### 8. Colección, relaunch y textos largos
Given dos altas de la misma especie con cuidados/fotos distintos y ejemplares previos,
When termino cada alta y cierro/reabro la app sin reseed,
Then tarjetas y detalles muestran copias propias, fechas y JPEG correctos; las plantas previas permanecen intactas. Alta refresca colección inmediatamente sin recrear VMs/fotos de tarjetas previas. Nombre largo y cuidados de 1000 caracteres son consultables por scroll en detalle, sin resumen previo. Nombre/ubicación se personalizan después con EditPlant existente.

## Repository Research

### Files Inspected

- `AGENTS.md`, skill `feature-spec` cargada mediante herramienta y `.agents/skills/ios-clean-mvvm/SKILL.md`, `.agents/skills/feature-spec/references/spec-template.md`; `PROGRESS.md`, `feature_list.json`: rol, dependencias y política de verificación.
- `CONTEXT.md`, `ARCHITECTURE.md`, `DESIGN.md`, `CONSTRAINTS.md`, `docs/{build-brief,domain-model,risks-and-open-questions}.md`: alcance y deltas a actualizar tras aprobación.
- `docs/specs/generate-care-sheet.md` (entrada/escenarios), `docs/adr/{001-local-plant-storage,005-confirmed-draft-identity,006-care-sheet-generation}.md`: contratos históricos, sin editarlos.
- `PlantCareAI/PlantCareAIApp.swift`: repositorio único elegido tras override Debug, fábrica por borrador, snapshot de configuración, fixtures y contadores.
- `PlantCareAI/Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift`: selección, confirmación, cierre y publicación de cuidados (lectura focalizada del VM); `Data/LocalIdentificationPhotoPreparer.swift`: pipeline existente.
- `PlantCareAI/Features/ConfirmSpecies/Domain/ConfirmedDraftIdentity.swift`, `PlantCareAI/Features/GenerateCareSheet/{Domain/GenerateCareSheetUseCase,Presentation/CareSheetReviewView}.swift`: identidad y seis campos validados/revisión actual.
- `PlantCareAI/Features/PlantList/Domain/{Plant,PlantRepository,SavePlantUseCase}.swift`, `Data/LocalPlantRepository.swift`, `Presentation/{PlantListView,PlantListViewModel}.swift`: modelo plano, commit, listado one-shot y sheet.
- `PlantCareAITests/{GenerateCareSheetViewModelTests,LocalPlantRepositoryTests,PlantListViewModelTests,IdentificationPhotoPreparationTests}.swift` (lecturas completas o focalizadas), `PlantCareAIUITests/PlantCareAIUITests.swift` (escenarios de cuidados/firmas), `PlantCareAI.xcodeproj/project.pbxproj` (referencias relevantes), `init.sh`.

### Patterns / gaps

- `SavePlant` ya valida textos obligatorios/fecha finita y foto no vacía; Data valida JPEG completo, rechaza UUID duplicado y compensa archivos ante fallo. Actor sin suspensión entre comprobación y commit; una instancia escritora por almacén.
- `Plant` guarda solo `confirmedSpecies: String`, no nombres separados/procedencia; adoptar mapeo explícito sin migrar ni aparentar una procedencia persistida.
- `PlantListViewModel.load()` es one-shot: otro `.task` no refresca alta. Hace falta callback de commit y reconciliación metadata con generaciones.
- Éxito actual publica ficha para review. Se debe cambiar ese punto, no una tarea de vista ni un botón de alta. Tests aceptados que esperan review/no alta requieren adaptación por este delta, no eliminación de cobertura.
- Pipeline efímero real ya normaliza imagen; falta formalizar reutilización persistente y verificar límites al cruzar alta. No hay spec save-plant previa ni adjuntos visibles; DESIGN indica que referencia Stitch no está incorporada.

## Technical Approach

### Datos obligatorios y mapeo (Domain)

- Nuevo caso de uso `SaveConfirmedPlantUseCase` / implementación `SaveConfirmedPlant` en `Features/SavePlant/Domain/SaveConfirmedPlantUseCase.swift`, inyectable en VM. Recibe snapshot inmutable: UUID de alta, fecha, `IdentificationPhoto`, identidad y `CareSheet`; devuelve `Plant` solo tras commit confirmado.
- UUID de alta nuevo, distinto del UUID de selección de foto; generar una vez por intención confirmada. Fecha local finita al primer intento de escritura, estable en retries. La nueva apertura no restaura borradores/UUID pendientes tras relaunch.
- Exigir `identity.photoID == photo.id`, intención vigente en Presentation, al menos un nombre no blanco con límites vigentes ≤2000 por nombre. Reutilizar validaciones Domain de generación, no aceptar propuesta sin confirmar.
- Exigir los seis campos `light`, `watering`, `humidity`, `temperature`, `substrate`, `fertilizer`: texto no vacío después de trim y cada uno ≤1000 caracteres; conservar contenido interior/Unicode. Ningún campo extra opcional bloquea alta; no añadir poda/trasplante ni sustitutos «desconocido».
- IA: `Plant.name` inicial = común si existe, si no científico. `confirmedSpecies` = `común (científico)` si ambos distintos; si uno o iguales, un solo nombre. Conservar nombres exactos válidos, sin traducir/truncar ni inferir. Manual: name y confirmedSpecies = nombre humano confirmado tras trim. Dos altas pueden compartir nombre; editables después.
- `location = nil` siempre en este recorrido; no pedirla ni geolocalizar. Foto JPEG preparada es obligatoria, dimensiones positivas y consistentes con bytes. `SavePlant` sigue siendo el límite de almacenamiento común; no endurecer históricas fichas persistidas con límites nuevos al leerlas.

### Fotografía real (Data; reutilización, no nueva importación)

- Adoptar explícitamente para foto inicial la salida actual de `LocalIdentificationPhotoPreparer`: primer frame, orientación aplicada a pixels, sin ampliar, lado máximo 2048 px, alfa blanco, JPEG calidad 0.85, ≤5 MiB, sin EXIF/GPS/orientación de origen. Entrada JPEG/PNG/HEIC, ≤30 MiB/80 MP antes de thumbnail; no releer galería/cámara ni guardar original/base64.
- Persistir **los mismos bytes preparados**, sin segunda compresión/decode-encode ni recorte a 4:3. Añadir `PreparedPlantPhotoValidating` Domain + `LocalPreparedPlantPhotoValidator` en `Features/SavePlant/Data/`: valida JPEG completo, dimensiones reales positivas/≤2048 y coincidencia con snapshot, ≤5 MiB y ausencia de metadata excluida antes de IO persistente. Inyectarlo desde App; no importar ImageIO en Domain/VM.
- Validación ImageIO fuera de MainActor, cancelable antes de escritura; repositorio conserva su defensa JPEG/rollback. Pipeline/validador reutilizables por futura add-plant-photo, sin implementarla ahora. Documentar memoria: originales PhotosPicker/UIImage pueden materializarse completos; buffers JPEG y decode/copias son acotados por salida, no memoria constante ni garantía para captura física/iCloud.

### Presentation / concurrencia / errores

- Mantener el único `IdentificationPhotoViewModel`; `CareState.loaded` puede existir internamente pero no se representa como ficha. Tras `.completed(sheet)` y guards actuales, congelar snapshot y pasar directamente a estado de alta `validating → saving → saved` o `failed`.
- `isBusy` incluye validación y guardado; ningún double tap/`.task`/`onAppear` inicia alta. Tokens por intención/foto/identidad, además de igualdad de nombres, excluyen respuestas antiguas iguales. Nunca guardar desde snapshot oculto durante edición.
- Separar errores de cuidados (retry con IA) y persistencia (retry local). Ficha válida se retiene únicamente en memoria durante fallo local. Retry local no depende de configuración/consentimiento actuales; estos se comprobaron al obtener ficha, no hay envío nuevo. Cambio explícito de identidad o publicación de foto B invalida snapshot/UUID; fallo de reemplazo conserva A.
- Durante generación/prevalidación permitir cancelar; inmediatamente antes de despachar `SavePlant`, comprobar token/cancelación y bloquear Cancelar/dismiss interactivo. `close()` debe rechazar cierre durante escritura, no solo deshabilitar UI. El tramo actor de escritura no se cancela a mitad; no poner un guard `Task.isCancelled` después de commit que oculte éxito.
- Retry conserva UUID/fecha/bytes/modelo. Caso `.duplicateID`: reconciliar solo ese UUID por lectura metadata y foto, declarar éxito únicamente si ambos coinciden exactamente con snapshot; de lo contrario error local, cero sobreescrituras/UUID alternativo. No convertir cualquier error en éxito ni deduplicar especies.
- Callback MainActor de éxito exactamente una vez y previo al dismiss. Composición captura débilmente listado. No ciclos de retención ni Data construida por vistas. Un cierre de proceso después de commit no se compensa borrando una planta válida.

### Composición / colección / navegación confirmada

- Flujo: vista → VM → `SaveConfirmedPlant` → validación foto + `SavePlant` → `PlantRepository` ← `LocalPlantRepository`. App inyecta la **misma instancia** escogida tras fixture override que para listado/detalle/edición. Domain puede reutilizar contratos de PlantList/ConfirmSpecies/IdentificationPhoto/GenerateCareSheet; no depende de Presentation/Data.
- Éxito: aplicar `Plant` confirmado al listado por UUID, crear solo nueva tarjeta, ordenar igual que repositorio (createdAt ascendente; desempate estable), invalidar cargas metadata antiguas, mantener VMs/imagenes previos y cerrar sheet. Volver a **Mis plantas con el listado actualizado**, según confirmación del usuario. Colección desplazada hasta nueva tarjeta; sin abrir detalle automáticamente. Cualquier feedback accesible «Planta añadida» será no bloqueante dentro de la colección, nunca una pantalla/modal de confirmación ni requerirá otra acción.
- Si listado estaba loading/failed, hacer refresh metadata postcommit sobre el mismo repositorio, sin reseed ni fotos; error se muestra como error de colección con reintento de **lectura**, nunca retry de alta. No presentar una lista parcial como completa. Dismiss no depende de esa lectura: alta ya fue confirmada; relaunch recupera datos.

## Expected File Changes (futuros, no realizados por planner)

- Crear `PlantCareAI/Features/SavePlant/Domain/{SaveConfirmedPlantUseCase,PreparedPlantPhotoValidating}.swift` y `Data/LocalPreparedPlantPhotoValidator.swift`.
- Modificar `IdentificationPhoto/Presentation/{IdentificationPhotoViewModel,IdentificationPhotoView}.swift`; crear `SavePlant/Presentation/PlantCreationStatusView.swift` para estado inline mínimo, no pantalla/ruta nueva. Retirar `GenerateCareSheet/Presentation/CareSheetReviewView.swift` y sus referencias de target si queda sin callers; no retirar generación Domain/Data.
- Modificar `PlantList/Presentation/{PlantListViewModel,PlantListView}.swift` y `PlantCareAIApp.swift`: callback, refresh/scroll/dismiss, composición. `ContentView` sin pantallas/lógica nuevas.
- `PlantList/Domain/SavePlantUseCase.swift`/`Data/LocalPlantRepository.swift`: solo si necesario para guard de cancelación previo a escritura; mantener contrato de commit y lecturas históricas, justificar cualquier diff.
- Crear `PlantCareAITests/{SaveConfirmedPlantTests,PreparedPlantPhotoValidationTests,SavePlantViewModelTests}.swift`; extender tests de lista/repositorio/pipeline; adaptar regresiones de confirmación/manual/cuidados afectadas.
- `PlantCareAIUITests/PlantCareAIUITests.swift`, fixtures Debug necesarios, `PlantCareAI/Localizable.xcstrings` (es-only), `PlantCareAI.xcodeproj/project.pbxproj` (una SourcesBuildPhase, registrar nuevos archivos/quitar review). No secretos/xcuserdata ni cambios de harness por defecto.

## Visual Design Impact

- UI sí: remover review y representar espera/error dentro de sheet actual con foto visible, «Generando cuidados…»/«Guardando planta…», cancelación según etapa, retry correspondiente y Cambiar especie ante error. No renderizar bloques de cuidados o tarjeta-resumen de identidad postconfirmación; error puede identificar brevemente especie/foto para contexto, sin resumen nuevo.
- DESIGN sigue tokens, controles nativos/44 pt, contraste, etiquetas y soporte adaptable. Su apartado review/alta recibe delta tras aprobación. Colección y detalle no se rediseñan; aviso «Cuidados orientativos generados por IA» permanece en detalle.
- **No pantalla nueva ni mockup obligatorio**: el usuario rechaza esa pantalla; no se requieren adjuntos inaccesibles ni una revisión Stitch. Inspección básica futura de estados afectados y ausencia de review, en simulador estándar.
- Recursos efectivamente consultados: dirección escrita `DESIGN.md` y código de vistas actuales, particularmente `CareSheetReviewView`, `IdentificationPhotoView` y `PlantListView`. No se consultaron screenshots, imágenes, PDFs, HTML de Stitch ni adjuntos de la conversación; no se atribuye inspección visual de una app ejecutada.

## Durable Documentation Impact

- `ARCHITECTURE.md`: update al implementar; cadena de alta, commit/cancelación, callback, fotografía adoptada y fin de review efímera. `AGENTS.md`: not needed, reglas de rol intactas.
- `CONSTRAINTS.md`: update tras aprobación: «alta explícita» es la intención de Confirmar especie con ayuda informativa, no segundo CTA; conservar barrera y seis campos. No rebajar confirmación humana de especie.
- `docs/{build-brief,domain-model,risks-and-open-questions}.md` y `DESIGN.md`: update de delta de producto, nombres/ubicación/mapeo y límites reales de pipeline; no crear historial ficticio. `CONTEXT.md`: not needed, significado de planta/confirmación no cambia.
- Crear `docs/adr/007-confirmed-plant-creation.md` tras aprobación: nuevo caller entre features, mapeo plano sin migración, reutilización de fotografía, intención y frontera commit; supersede review de ADR006 sin modificarlo.
- Crear `docs/testing-save-plant.md` y handoff de implementación; `PROGRESS.md`/entrada save-plant: registro real por rol. Planner solo spec y apuntes mínimos de planificación, status not_started/evidence vacía. No editar specs aprobadas ni evidencias históricas.

## Implementation Plan / Tasks (solo después de revisión)

1. [ ] Tras autorización de implementación, documentar delta/ADR y las decisiones funcionales ya confirmadas, sin alterar antecedentes.
2. [ ] Implementar caso de uso, validación/mapeo/snapshot y defensa foto con tests unitarios y persistencia real aislada.
3. [ ] Integrar éxito de generación → alta automática en VM; tokens/busy, cancelación precommit, reconocimiento postcommit y retries separados, con dobles retenidos/fallidos.
4. [ ] Sustituir review por estados mínimos existentes; conservar selector/confirmación/consentimiento y ayuda de intención; añadir callback/colección/scroll/dismiss desde composición.
5. [ ] Actualizar UI funcionales afectadas para nuevo contrato sin eliminar escenarios/assertions de aislamiento, consentimiento, cancelación, textos largos o selección; mover comprobación de seis cuidados al detalle posterior al commit.
6. [ ] Registrar fuentes en proyecto, docs y evidencia focalizada; entregar a validator independiente, sin avanzar otra feature.

## Verification Plan (comandos futuros; no ejecutados en planificación)

### Implementer — por impacto

- Domain/mapeo/foto → blancos/límites/ambas vías/metadata: nuevas SaveConfirmedPlantTests + PreparedPlantPhotoValidationTests + IdentificationPhotoPreparationTests + GenerateCareSheetTests.
- VM/transición/commit → race/duplicado/retry/no nueva IA: SavePlantViewModelTests + GenerateCareSheetViewModelTests + ConfirmSpeciesViewModelTests + ManualSpeciesViewModelTests + IdentificationConsentViewModelTests, adaptadas al contrato vigente.
- Repositorio/lista/composición → rollback/relaunch/callback tardío/aislamiento/cache: LocalPlantRepositoryTests + PlantListViewModelTests y regresiones UI de detalle/edición/consentimiento/foto directamente afectadas por callers/helpers. Ampliar selección solo explicando diff → riesgo.
- Ejemplo ejecutable una vez añadido test: `caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID estándar coordinado>' -derivedDataPath DerivedData -resultBundlePath DerivedData/save-plant-unit.xcresult -parallel-testing-enabled NO -only-testing:PlantCareAITests/SaveConfirmedPlantTests -only-testing:PlantCareAITests/PreparedPlantPhotoValidationTests -only-testing:PlantCareAITests/SavePlantViewModelTests -only-testing:PlantCareAITests/LocalPlantRepositoryTests -only-testing:PlantCareAITests/PlantListViewModelTests test`; añadir selectors de regresión según impacto final.
- E2E persistente disponible = XCUITest: añadir `testSavePlantAutomaticAIAndManualSameSpeciesRelaunch`, `testSavePlantLocalFailureRetryWithoutNewCareRequest`, `testSavePlantCancellationCommitAndNoReview`. Comando misma plantilla con `-only-testing:PlantCareAIUITests/PlantCareAIUITests/<nombre>` por escenario; fixtures aislados no seed tras relaunch, contadores IA y modelos/bytes verificados. Simular fallo local real mediante beforeCommit, no éxito fingido.
- Inspección visual básica real de espera/error/local retry/colección y detalle largo, una apariencia/texto normal. Soporte AX intacto; SE/AX aumentado/VoiceOver/matrices fuera de habitual, no ejecutadas salvo petición.
- Coordinar con sesión activa, no simultanear simulador. Reutilizar evidencia válida de mismas fuentes/config/destino; gate accepted146/146 es antecedente, no prueba de alta nueva. Sin full baseline/final rutinarios del implementer. Fallos preservados; reparar/ejecutar primero escenario fallido y afectados.
- Antes de futura ejecución: sandbox público/example con clave vacía sin leer/copiar configuración privada; jamás sobrescribir fichero real. Estáticos futuros: `git diff --check`, `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, `python3 -m json.tool feature_list.json` y catálogo. No cambiar init ni reducir cobertura para verde.

### Validator — gate final

- Tras implementación final autorizada: un `caffeinate -dius ./init.sh` o corroborar gate completo válido de exactamente mismas fuentes/entorno, sin duplicarlo por rol. init ejecuta build + todas unit/UI, prepara imágenes sintéticas, termina; no servicio largo ni modo nuevo.
- No repetir focalizadas cubiertas por gate sin laguna/diagnóstico concreto. Reparación de producto/tests/config/recursos que invalida gate justifica gate nuevo después de checks afectados. Revisar seguridad, capas, ausencia de review y evidencia visual básica.
- **Este paso documental** solo requiere coherencia/lectura del diff; no iOS tests/build/init ni aceptación de producto. API real futura solo bajo autorización del usuario; evidencia aceptada de cuidados no es prueba del guardado real.

## Evidence To Capture / Validator Checklist

- [ ] Ocho escenarios cubiertos, sin review/segundo CTA; selección sola cero red/escritura y confirmación humana conservada.
- [ ] Dos UUID de misma especie, metadata/seis cuidados/JPEG propios tras relaunch sin reseed; plantas previas intactas y edición posterior funcional.
- [ ] Fallo local/rollback, retry con mismo snapshot/cero IA, duplicados conflictivos, cierre precommit y éxito postcommit no oculto; contadores separados y continuaciones tardías.
- [ ] Registro de comando/selección-motivo/fuente/config pública/destino/resultado/xcresult/fallos y capturas realmente inspeccionadas; distinguir nuevo/reutilizado/pendiente validator, no secretos ni payloads.
- [ ] Fronteras Presentation → Domain ← Data/composición y fuentes Xcode correctas; memoria/límites/procedencia plana documentados honestamente, sin migración ni historial añadido.
- [ ] Documentación durable refleja delta y conserva historia; passing solo autoverificación, accepted solo aceptación independiente con gate válido.

## Decisiones confirmadas por el usuario / riesgos residuales

- Confirmadas 2026-10-11: seleccionar propuesta o manual con texto completo → pulsar Confirmar especie → obtener y validar cuidados → guardar automáticamente, sin pantallas de resumen ni confirmación adicionales.
- En esta primera versión, el nombre guardado será el nombre de la especie (común si existe, científico como fallback; texto confirmado en manual) y la ubicación quedará vacía (`nil`). No solicitar nombre personalizado ni ubicación al confirmar; un futuro flujo para introducirlos queda fuera de esta feature. La edición posterior existente no se modifica.
- Tras guardar, volver a Mis plantas con el listado actualizado; no abrir el detalle automáticamente. Las tres dudas funcionales planteadas quedan resueltas; no se infiere aprobación técnica independiente ni permiso de implementación.
- Riesgos: calidad botánica no certificada, servicios intermitentes, memoria original de picker/cámara, daños de disco y terminación entre JPEG/commit. Guard/retry no prometen exact-once multiproceso ni recuperación de borrador; cámaras físicas/iCloud siguen sin acreditarse por fixtures.
- Tamaño: una cadena de alta y el modelo Plant existente; no requiere dividir la feature.
- Siguiente paso exclusivo: **spec actualizada con las decisiones del usuario; detenerse aquí**. No implementar, validar código ni delegar roles hasta autorización posterior.
