# Feature Implementation Spec: Reintentar tras fallo de red o IA

## Source Feature

- `id`: `recover-ai-failure`; `area`: `errores-ia`.
- `source`: `feature_list.json:514–522`.
- `depends_on`: `identify-candidates`, `generate-care-sheet`, `analyze-current-photo`, todas `accepted`.
- `status` al planificar: **`not_started`**, evidencia propia vacía; no se modifica.
- Comportamiento: «Un fallo de identificación, cuidados o análisis presenta error recuperable y permite reintentar sin perder datos locales guardados».
- Verificación original: «Simular red/API caída en las tres operaciones; comprobar reintento, sin alta incompleta y colección e historial consultables sin red; gate estándar».
- Nota original: distinguir red/API de persistencia local sin registrar contenido sensible.
- Planner, 2026-10-14; feature-flow **UN SOLO PASO**, pendiente exclusivamente de revisión del usuario.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/recover-ai-failure`.
- Rama/base comunicadas por el padre: `feature/recover-ai-failure`, main `6c259a4fdd9e5d590849c5e7cbb28fc70402e1f3`; no comprobadas mediante Git en este rol.

## Goal y recomendación

### Decisión del usuario — 2026-10-14

El usuario aprueba dar la feature por cubierta con el comportamiento existente y la cobertura offline combinada, sin código ni pruebas adicionales. Esta decisión sucede la propuesta pendiente de revisión descrita abajo; no equivale a una nueva aceptación independiente. Solo queda el cierre documental de evidencia por un revisor independiente, sujeto a autorización posterior. No se inicia implementación ni validación en esta sesión.

Consolidar la trazabilidad de la recuperación ya implementada, antes de crear trabajo redundante.
**Recomendación: cierre por cobertura existente, cero cambios de producto y cero tests nuevos por defecto.**
La lectura de fuentes/tests y de aceptaciones durables cubre cada criterio funcional; no se ha encontrado un defecto que justifique implementar esta feature otra vez.
Esto es una conclusión de planificación, **no aceptación ni validación ejecutable nueva**.
El cierre documental requiere aprobar esta interpretación y una revisión independiente posterior autorizada de evidencia pertinente.

## Non-Goals

- Rediseñar errores, unificar los tres adaptadores/VM, crear una feature transversal `RecoverAIFailure` o nuevos protocolos.
- Retry automático/backoff, monitor de conectividad, cola offline, cache de respuestas, restauración persistente de borradores o fallback de proveedor/auth.
- Permitir altas sin seis cuidados válidos; convertir error en evidencia insuficiente, vacío local o diagnóstico.
- Nueva API real, fotos del usuario, secretos/config privada, cambios de harness, cuentas/backend/sincronización.
- `one-turn-question`: deberá reutilizar las fronteras al implementarse; no queda cubierta anticipadamente por este cierre.
- Modificar specs aceptadas, reinterpretar gates fallidos históricos o publicar Git/GitHub.

## Job Story / Users And Permissions

Cuando falla la IA mientras identifico, genero cuidados o analizo una foto de mi ejemplar,
quiero comprender el fallo y volver a intentarlo expresamente,
para conservar mi foto/intención vigente y seguir consultando lo que ya guardé localmente.

Único usuario local. Cada envío sigue requiriendo el consentimiento del destino/modelo/finalidad vigente.
Cancelar o cerrar invalida la sesión, pero no garantiza retirar bytes/costes ya enviados.
Conservar el borrador ante un fallo no significa restaurarlo después de cerrar/terminar la app.

## Acceptance Scenarios (contrato existente, no ampliación)

1. **Identificación:** Given foto A preparada, When falla red/API, Then error explícito y foto A conservada, sin candidatas/confirmación/alta falsas; When pulsa Identificar, Then una nueva intención autorizada permite recuperar el resultado sin elegir A otra vez.
2. **Cuidados:** Given foto e identidad humana vigentes, When falla red/API o llega ficha incompleta, Then error, identidad/foto conservadas y ninguna alta; When pulsa Reintentar cuidados, Then se obtiene ficha completa y solo entonces puede continuar el alta existente.
3. **Análisis:** Given foto local seleccionada y contexto propio, When falla red/API, Then error sin provisional válido/guardado ni mutación de historial; When pulsa Reintentar, Then una nueva petición conserva identidad y referencia temporal de la intención.
4. **Datos offline:** Given ejemplares/historial previamente guardados y servicio inaccesible, When abandona la operación IA y consulta colección/detalle/historial, Then lee datos locales propios sin necesitar éxito, configuración ni consentimiento de IA; fallo local real no se disfraza de vacío.
5. **Persistencia distinta:** Given éxito remoto seguido de fallo de commit local, When reintenta guardado, Then conserva snapshot y reintenta solo escritura local, sin nueva solicitud IA ni duplicación.
6. **Cancelación/privacidad:** Given operación pendiente, When cancela/cierra o cambia el snapshot, Then no publica respuesta obsoleta ni escribe por error; no hay reintentos automáticos ni logs de foto/contexto/clave/respuesta cruda.

## Repository Research: mapa criterio → código → tests → aceptación durable

Rutas abreviadas en este apartado: `F = PlantCareAI/Features`, `T = PlantCareAITests`.
Todos los E2E nombrados viven en `PlantCareAIUITests/PlantCareAIUITests.swift`.
Las referencias son inspección de código existente, **no tests ejecutados por el planner**.

### C1. Caída de red/API e intención explícita en identificación

- Código: `F/IdentifyCandidates/Data/OpenAICompatibleSpeciesIdentificationRepository.swift:39–99` mapea URLError/timeout/401/403/429/500 y respuesta inválida; POST único, sin bucle de retry.
- `F/IdentificationPhoto/Presentation/IdentificationPhotoViewModel.swift:415–466` publica fallo sin borrar foto; `identifyPhoto()` inicia nueva intención con guards y autorización.
- `IdentificationPhotoView.swift:257–265` separa mensajes; catálogo `identifyCandidates.networkError` explica conservar foto y pulsar Identificar.
- Transporte: `T/OpenAICompatibleSpeciesIdentificationRepositoryTests.swift`, `testStatusesNetworkTimeoutAndInvalidResponsesDoNotRetry` (incluye `.notConnectedToInternet`) y `testUnauthorizedResponseDoesNotRetryWithOrWithoutAuthentication`.
- VM: `T/IdentificationConsentViewModelTests.swift/testServiceFailureIsNotInsufficientAndRetryIsExplicit`, red falla→foto/no resultado/1 llamada→retry humano/2 llamadas.
- E2E: `IdentificationResultUITests/testIdentificationExplicitErrorRetry`, API limitada→sin manual/confirmación→Identificar→resultado, contador1→2 y preview120×80 intacta.
- Evidencia: **E1**, aceptación identifica expresamente error del servicio/retry sin volver a subir la foto. UI prueba rate-limit; la caída de red la cubre el transporte/VM, no se atribuye a ese mismo E2E.

### C2. Caída de red/API en cuidados, sin alta incompleta

- Código: `F/GenerateCareSheet/Data/OpenAICompatibleCareSheetGenerationRepository.swift:35–110` mapea fallos y rechaza truncamiento/refusal/unavailable/JSON/campos incompletos.
- `F/GenerateCareSheet/Domain/GenerateCareSheetUseCase.swift` exige seis textos válidos; VM de identificación `retryCare/startCare:170–228` mantiene identidad/foto, limpia ficha fallida y solo llama `startSave` tras `.completed(sheet)`.
- Transporte: `T/OpenAICompatibleCareSheetGenerationRepositoryTests.swift/testStatusesRefusalTruncationUnavailableMalformedSizeNetworkAndTimeoutNoRetries`, incluye red desconectada/status500.
- VM: `T/GenerateCareSheetViewModelTests.swift/testFailureIncompleteRetryAndEditingRestoresExactSheet`: network→incompleta→válida, sin ficha parcial.
- E2E: `CareSheetUITests/testCareSheetNetworkFailureAndExplicitRetry` y `testCareSheetIncompleteResponseAndExplicitRetry`; `checkCareRetry:1095–1123` exige error, identidad, ningún campo de ficha, contador1→2 y detalle con seis cuidados tras recuperación.
- Aislamiento/cierre: `CareSheetUITests/testCareSheetCancellationCloseAndStorageIsolation`, relaunch sin reseed con `--storage-verify` de dos plantas originales.
- Evidencia: **E2** acredita el contrato remoto original; **E4** incluye los tests actuales adaptados al alta directa. La aceptación antigua de cuidados sin alta no se hace pasar por aceptación de la cadena de alta posterior.

### C3. Caída de red/API en análisis, sin alterar memoria

- Código: `F/AnalyzeCurrentPhoto/Data/OpenAICompatiblePlantPhotoAnalysisRepository.swift:61–127` y `Presentation/PlantPhotoAnalysisViewModel.swift:54–133`: fallo descarta prepared/result, conserva identidad/query/zona y permite retry; no escritura desde ese camino.
- `PlantPhotoAnalysisView.swift:37–40` ofrece error/Reintentar; error de guardado está separado en `:56–62`.
- Transporte: `T/OpenAICompatiblePlantPhotoAnalysisRepositoryTests.swift/testHTTPFailureMappingOneAttemptNoRetry` y `testTotalDeadlineAndNetworkTimeoutMappingAreErrorsWithoutRetry`, incluyen500/red desconectada/timeout/conteo único.
- VM: `T/PlantPhotoAnalysisViewModelTests.swift/testRetryKeepsCapturedQueryAndReferenceZone` y `testConsentRejectZeroAndExplicitRetryAcceptOneDuplicateTapIgnored` (retry de consentimiento, no atribuirle fallo remoto).
- E2E remoto exacto: `AnalyzeCurrentPhotoUITests/testNetworkFailureExplicitRetryNoAutomaticRetryAndDiskExactRelaunch:2527–2533`: fallo/red,1→retry→resultado/2, cierre/relaunch.
- Su helper `launch:2371–2376` usa `--storage-verify --photo-analysis-verify --discard-analysis-verify` sin reseed al reabrir: preserva plantas, cuidados, fotos y definitivos esperados.
- Evidencia: **E3** evalúa explícitamente errores/retry/sin huella; **E4** cubre versión actual posterior a Keep/Discard.

### C4. Colección e historial consultables sin red

- Composición `PlantCareAIApp.swift:77,91–92,151–177,213–225`: lectores locales y proveedores remotos separados; ausencia/fallo/config de IA no sustituye `LocalPlantRepository`.
- Código: `F/PlantList/Domain/LoadPlantsUseCase.swift`, `F/PlantDetail/Domain/LoadPlantDetailUseCase.swift`, `F/PlantTimeline/Domain/LoadPlantTimelineUseCase.swift` leen repositorios locales; timeline fail-closed incluye lector real de definitivos.
- `F/PlantList/Data/LocalPlantRepository.swift:270–274` lee SwiftData, no transporte remoto; foto se lee por UUID local.
- Integración: `T/LoadPlantTimelineTests.swift/testRealViewSessionScrollRetryRefreshContextNeverCommitsOrChangesBytes` y `testRealStoreUnionAllKindsPhotosPreOriginIdentityAndReadOnlyReopen`: disco real/reopen/metadata/JPEG exactos, cero commits adicionales, sin cliente IA.
- `T/LoadPlantDetailTests.swift/testRealReopenedRepositoryReturnsCompleteMetadataWithoutPhoto` acredita ficha completa aun faltando JPEG.
- E2E: aislamiento/relaunch de C2/C3, `StoredCollectionUITests/testStoredCollectionSurvivesProcessRelaunch` y `KeepAnalysisUITests/testSavedTextSurvivesMissingInitialJPEGAndRemainsReadableUnderPlaceholder` (texto local bajo foto fallida).
- Evidencia: **E3/E4/E5**, más aceptación `plant-timeline` en feature_list. Offline se sustenta por separación de dependencias y pruebas locales, **no** por un modo avión/apagado real de red del simulador observado aquí.

### C5. Error remoto distinto de persistencia y logs sensibles

- `F/SavePlant/Presentation/PlantCreationStatusView.swift:20–38,56–67`: «Reintentar guardado» local frente a cuidados y mensajes remotos tipados; VM `retrySave` conserva snapshot sin autorización/IA.
- Análisis separa `state.failed` de `saveState.failed`; `save()` reusa acceptance literal, no llama a analyze.
- Tests: `T/SavePlantViewModelTests.swift/testLocalRetryStableSnapshotNoAIAndEditingCancelNoAutoWrite`; `T/PlantPhotoAnalysisViewModelTests.swift/testLocalSaveRetryKeepsLiteralSnapshotResultNoExtraHTTPAndCallbackOnce`.
- E2E: `SavePlantUITests/testSavePlantLocalFailureRetryWithoutNewCareRequest`; `KeepAnalysisUITests/testLocalFailureRetryNoRemoteRequestAndCloseAbandonsUncommittedResult`.
- Los tres adaptadores inspeccionados no imprimen body/headers/respuestas/secretos; no se propone instrumentación nueva. Evidencia de revisión de seguridad: **E1/E2/E3/E5**, restricciones `CONSTRAINTS.md:40–44`.

### C6. Sin envío automático y cancelación/tardíos

- Guards/generaciones en ambos VM, `AuthorizeExternalAIOperation` en continuaciones de composición y transporte; UI solo envía por intención.
- Tests inspeccionados: identificación `testCancelRequestPreservesPhotoAndIgnoresLateResult`; cuidados `testCancelCloseAndLateResponseNeverPublishOrOverwriteNewIntention`; análisis `testCloseDuringProviderIgnoresLateResultReleasesBytesAndModalGateAllowsReopen`.
- Tests de transporte de las tres operaciones observan cancelación URLSession/deadline; E1/E2/E3 aceptaron límites de privacidad/cancelación, no revocación de bytes ya enviados.

### Índice de evidencia durable de aceptación previa

- **E1:** `docs/validations/identify-candidates.md:1–38`, accept2026-10-10; gate94/94 y focal28/28 corroborados por validator, más relato humano específico de error/retry. Informe conserva bloqueos anteriores como historia.
- **E2:** `docs/validations/generate-care-sheet-V2.md`, accept2026-10-11; gate146/146, seis escenarios humanos de cuidados/fallo/retry corroborados; FAILED145/146 histórico intacto.
- **E3:** `docs/validations/analyze-current-photo.md`, accept2026-10-13; gate337/337, evaluación7/9, `DerivedData/TestResults/20261013-123024-34203/{parallel,gallery}.xcresult` referidos en informe.
- **E4:** `docs/validations/app-launch-branding.md:288–315` (apéndiceV3, no cabeceraBLOCK histórica), accept2026-10-14 registrado en feature_list/PROGRESS; gate390/390=296unit+92UI+2Photos,0fallos/skips, worker1 autorizado/default5 intacto, manifest189inputs `4688d1504b0064a5c80b464ada1a054c4253b8aea4a46ed6b7c2638dab69830f`.
- **E5:** `docs/validations/keep-analysis.md`, accept2026-10-13; local retry/no HTTP/lectores reales/texto durable, gate357/357.
- Estos son registros durables **leídos**, no bundles reabiertos, hashes contrastados con este worktree ni ejecuciones nuevas. `DerivedData` de las sesiones anteriores no acompaña esta raíz; antes de reutilizar un gate como evidencia vigente, el revisor debe acreditar pertinencia de inputs/destino/config pública, no asumir identidad por descendencia de main.

## Lagunas reales vs consolidación documental / decisiones pendientes

- **Producto:** ninguna laguna funcional demostrada dentro del criterio seleccionado.
- **Consolidación:** la entrada `not_started`/evidence[] no enlaza capacidades ya aceptadas; falta el cierre transversal, no otro flujo de retry.
- **Granularidad de pruebas:** no se identificó un único E2E que corte la red del sistema, falle las tres operaciones y abra todo el historial en ese mismo recorrido. Hay transporte simulado desconectado para las tres, retries UI y lectura local real independientes; no equivalen a un smoke humano en modo avión, ni este contrato exige literalmente ese mecanismo.
- **Decisión a aprobar:** aceptar esta cobertura combinada para «simular red/API caída…consultables sin red», evitando añadir un E2E monolítico duplicado. Si el usuario exige expresamente fallo remoto→abrir historial en la misma sesión o modo avión, sería una ampliación de evidencia acotada, no defecto de producto demostrado ni obligación automática actual.
- **Evidencia vigente:** no está corroborada por este planner la igualdad del estado relevante con E4; revisión independiente posterior puede cerrar esa trazabilidad o indicar una laguna concreta. No autoriza ejecutar tests ahora.
- No se piden otra vez API real/credenciales: E1/E2 atribuyen relatos al usuario; E3 no certifica proveedor real y lo deja fuera de aquella aceptación.

## Technical Approach / arquitectura existente

- **Presentation:** IdentificationPhotoView/VM, PlantCreationStatusView y PlantPhotoAnalysisView/VM ya poseen estados, mensajes, retry humano y cancelación; mantenerlos.
- **Domain:** IdentifyCandidates, GenerateCareSheet, AnalyzePlantPhoto y contratos/errores tipados; lectores locales PlantList/Detail/Timeline independientes. Sin dominio nuevo.
- **Data:** tres adaptadores OpenAI-compatible mapean red/API; mismo actor LocalPlantRepository para persistencia/lectura. Sin adapter adicional, schema ni migración.
- **Composición:** `PlantCareAIApp.swift` conecta View→VM→caso de uso→contrato←Data y barrera de consentimiento vigente v5; ContentView sigue entrada fina.
- En el camino recomendado no se toca ninguna capa, proyecto Xcode, recurso, seam o harness. No extraer reutilización por estética arquitectónica.

## Expected File Changes / Visual Design Impact

- **Ahora únicamente:** crear `docs/specs/recover-ai-failure.md`, consolidación y propuesta para revisión.
- **Tras aprobación y autorización posterior, no en este paso:** posible informe independiente `docs/validations/recover-ai-failure.md` y registro de resolución en `PROGRESS.md`/`feature_list.json` por el rol competente. Transiciones solo con evidencia y aceptación independiente según AGENTS; no autoaceptar ni usar `passing` como sello documental sin pruebas pertinentes.
- Producto/tests: **ningún archivo previsto**. No rediseño; conservar errores/acciones/paleta/etiquetas/diseño adaptable de DESIGN.
- Adjuntos visibles: ninguno en el mensaje recibido. Búsqueda local encontró PNG de marca/AppIcon/LaunchScreen, no referencia de errores pertinente; no se abrieron ni se atribuye inspección visual. No HTML/capturas de errores encontrados. No simulador abierto.

## Durable Documentation Impact

- `ARCHITECTURE.md`: no necesario; no cambia dependencia/layer/contrato. Antecedentes históricos no se reescriben.
- `CONSTRAINTS.md`: no necesario; privacidad, consentimiento y no retry automático ya fijados.
- `AGENTS.md`: no necesario; ninguna regla operativa nueva.
- `CONTEXT.md`, `DESIGN.md`, brief/domain/risks: no necesario; comportamiento existente sin delta funcional.
- `docs/testing-ui.md`: no necesario; ya enumera selectores y consolidaciones equivalentes.
- `PROGRESS.md`/`feature_list.json`: eventual cierre documental autorizado; ahora intactos, `not_started`, ninguna evidencia ejecutable añadida.

## Implementation Plan / Tasks

1. Usuario revisa recomendación, mapa y límite de cobertura offline; **detenerse aquí**.
2. Si aprueba cero producto, no convocar implementer para inventar cambios: solicitar por separado revisión independiente documental de cobertura/pertinencia de evidencia.
3. Solo tras esa revisión autorizada, el orquestador documenta cierre/estado conforme a AGENTS; si el revisor demuestra laguna, presentar alcance mínimo y obtener aprobación antes de editar/ejecutar.

- [x] Aprobar interpretación de cobertura combinada (usuario, 2026-10-14).
- [ ] Autorizar posteriormente revisión independiente de cierre documental (no autorizada ahora).
- [ ] Corroborar evidencia pertinente y registrar resolución por rol competente; preservar historia fallida.
- No tareas Swift/tests en el camino recomendado; ninguna tarea marcada ejecutada por esta spec.

## Verification Plan (futuro condicionado, NO ejecutado)

**Ahora:** solo investigación/lectura y redacción. Sin tests/build/init/simuladores/API, validación de código ni Git/escrituras externas. Skills feature-spec y guía local ios-clean-mvvm aplicadas.

**Camino documental:** diff de spec→riesgo de sobreafirmar cobertura/aceptación→revisión de consistencia, selectores, atribución y evidencia previa por reviewer independiente autorizado. Comando documental propuesto `git diff --check`; no ejecutado por planner. No iOS tests ni gate por cambios solo documentales sin impacto ejecutable.

**Solo si una laguna posterior aprobada cambia tests/producto:** implementer hace mapa diff→riesgo→tests afectados y regresiones directas, sin baseline/gate completo rutinarios. Ejemplo disponible (ajustar solo al impacto demostrado, no ejecutar las tres clases por costumbre):

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -only-testing:PlantCareAITests/OpenAICompatiblePlantPhotoAnalysisRepositoryTests \
  -only-testing:PlantCareAIUITests/AnalyzeCurrentPhotoUITests/testNetworkFailureExplicitRetryNoAutomaticRetryAndDiskExactRelaunch test
```

E2E persistente disponible: XCTest UI, selectores C1/C2/C3; no cobertura nueva necesaria en cero producto. Si se exige prueba adicional, actualizar solo escenario pertinente con aserciones de conteo/lectura local, no duplicar la suite ni relajar negativos. Preparar example vacía únicamente si falta config, nunca leer/sobrescribir real; coordinar fuentes y simulador con sesión activa.
Validator sería dueño de **un único `caffeinate -dius ./init.sh` final si hay impacto ejecutable**, o evidencia completa válida corroborada de mismos inputs/entorno; init ejecuta build y ambas fases, no solo guía ni servidor. Fallos se conservan; reparación repite primero escenario fallido/callers, nuevo gate solo si evidencia final quedó invalidada. Sin matrices ampliadas ni envíos reales tácitos.

## Evidence To Capture / Validator Checklist

Capturar posteriormente aprobación, decisión de cero producto, criterio→test→informe, comparación de inputs pertinente si se reutiliza gate, comando/selección/entorno/resultados realmente ejecutados vs históricos y límites. No adjuntar secretos/productos Debug privados ni atribuir screenshots/xcresult no abiertos.

- [ ] Usuario aprobó cero producto y cobertura offline combinada; revisión posterior autorizada explícitamente.
- [ ] C1–C6 tienen trazabilidad; red desconectada de transporte no se etiqueta smoke de sistema.
- [ ] Datos de las dos plantas/historial preservados, ningún alta parcial o guardado remoto implícito.
- [ ] Retry remoto/local distintos, consentimiento vigente, sin retries/logs sensibles nuevos.
- [ ] Evidencia previa independiente pertinente corroborada o laguna concreta documentada; no heredar gates por nombre/antigüedad.
- [ ] Solo documentación: no ejecutar suite iOS; impacto ejecutable posterior: gate completo válido según AGENTS, sin duplicaciones.
- [ ] Estados y registros actualizados únicamente tras autorización/evidencia/aceptación independiente; historia intacta.
- [ ] Sin otra feature, rediseño, cambio de configuración real, publicación ni implementación innecesaria.

**Revisión del usuario completada: cubierta por comportamiento existente, sin implementación adicional. Siguiente paso: autorización de revisión independiente documental para formalizar el cierre; `not_started` se conserva hasta entonces.**
