# last-watering-hint — handoff implementer

## Estado vigente: PASSING — listo para validator, no accepted

Autoverificación cerrada el2026-10-12. **77 tests distintos, último resultado Passed=49unit+28UI**; registro reconciliado `DerivedData/evidence/last-watering-hint/selected-results.json` y árboles originales. Historial FAILED permanece; no suite completa ni acceptance. No procesos propios activos al cierre, interrupción WebSocket/API no reinició servicio ni duplicó ejecuciones. Handoff histórico «en curso» de abajo se conserva como cronología, no pendientes actuales.

Fuentes finales124 inputs públicos en `ready-source-hashes.json`, SHA256f07f43d91dc47ccb8a9299a0b6ccf5983e90fd509dda63b6fdce3ad373d661d8. Producto/proyecto/catálogo idénticos a primera focalizada, tests modificados solo en PlantDetailViewModelTests (2 casos añadidos) y PlantCareAIUITests (scope/expectativas/targeting). Spec SHA intacta y raíz/rama/base comprobadas. Static plist/JSON claves únicas/diff-check pasan. Issue#34 gestionado exclusivamente por padre, ninguna operación GitHub realizada aquí.

### Resultados finales y reparación de callers

- `scope-visual.xcresult`3/3 UI PASS exit0, cero skips/fallos. Comando ya registrado abajo:3 callers directos del helper negativo, no todo el bundle original repetido.
- `regressions.xcresult` histórico FAILED14/17 exit65, cero skips. PhotoFailure/StoredCollectionSurvives esperaban value foto-only; delta aprobado exige estado foto + resumen loaded. SelectIdentity llegó A→B→A y tap final x=.5/y=.25 se calculó en y100.4, dentro del header y83.7–124.4, fuera del viewport que inicia146; jerarquía DCF105CC...txt y card-select-activities.json corroboran ubicación/error. No defecto de NavigationLink/persistencia atribuido sin prueba.
- Reparación tests: igualdades **exactas** `Foto cargada, Sin riegos registrados`/`No se pudo cargar la foto, Sin riegos registrados` en card (detalle photo-only intacto), sin contains débil. Foto/contenido y A→B→A conservados; limits del tap basados en viewport real, assertions previas al gesto. No cambio de producto/harness init ni assertions descartadas.
- `build-callers.log` BUILD SUCCEEDED exit0; `callers.xcresult` **8/8 UI PASS exit0**, cero skips/failures. Selección3fallidos +5caller adicionales de assertCards. Las14regresiones previas aprobadas no consumen helper cambiado y son reutilizadas; mismos inputs de producto. Comando:

```sh
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 0)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -resultBundlePath DerivedData/evidence/last-watering-hint/callers.xcresult \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testPlantCardsSelectCorrectIdentity \
  -only-testing:PlantCareAIUITests/StoredCollectionUITests/testStoredCollectionSurvivesProcessRelaunch \
  -only-testing:PlantCareAIUITests/ExternalConsentUITests/testExternalConsentUnavailableAndBothPlantsUnchanged \
  -only-testing:PlantCareAIUITests/IdentificationResultUITests/testIdentificationCandidatesReadOnlyResultReplacementAndStorageIsolation \
  -only-testing:PlantCareAIUITests/ManualSpeciesUITests/testManualSpeciesInvalidationCloseAndStorageIsolation \
  -only-testing:PlantCareAIUITests/ConfirmSpeciesUITests/testConfirmSpeciesAlternativeAndDraftInvalidation \
  -only-testing:PlantCareAIUITests/CareSheetUITests/testCareSheetCancellationCloseAndStorageIsolation test-without-building
```

Debug rebuild usa el mismo comando build-for-testing registrado debajo, log build-callers.8 callers elegidos por6 consumidores reales de assertCards +PhotoFailure/Select, no selección arbitraria de IA/red: todos fixtures locales, ninguna solicitud externa.77distintos=49unit+28UI; bundle original50/53, repair4/5 y regressions14/17 **siguen FAILED** aunque reparaciones específicas pasen.

### Release y pendientes del validator

Nuevo guard Debug Simulator/UUID en composición/fixture justifica audit Release por impacto; no gate adicional:

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -configuration Release -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -derivedDataPath DerivedData/LastWateringRelease CODE_SIGNING_ALLOWED=NO build
```

`release.log` BUILD SUCCEEDED exit0. `release-audit.log` compara Release Info.plist (sin PlantCareAIAPIScheme/APIHostPath/Model/APIKey/TimeoutSeconds) y strings del binario (sin --last-watering-fixture/LastWateringReadTestFixture/--care-fixture/CareExpected.json); audit exit0, nunca lectura de config privada.11 PNG únicos abiertos son válidos por producto idéntico; manifests de attachments conservan asociación nombre→PNG; no repetir capturas solo por rol.

Validator siguiente: preflight **fail-closed**, ausencia de competidores, boot/bootstatus explícito del00BBB7EC… acordado (puede estar Shutdown tras XCTest), light/texto normal ya preparados. Revisar diff/contrato/capas/evidencia y ejecutar único `caffeinate -dius ./init.sh` final ambas fases; esperado211tests=158unit+52UIparallel+1Fotosserial, no afirmar gate ejecutado ni aprobado hasta corroborarlo. No repetir focalizadas ya cubiertas sin laguna concreta. Matrices adicionales no solicitadas fuera habitual, no bloqueos. Padre registra accepted/commit LOCAL autorizado únicamente tras accept independiente; sin stage/commit/push/PR/merge por implementer.

Manual smoke sugerido (no relato humano ejecutado): A y B de igual especie; consultar ausencia, cancelar cuidado, registrar abonado, riego hoy y retroactivo; A muestra máximo, B conserva ausencia; volver lista/reabrir proceso sin reseed y revisar foto/identidad/ficha; consejo solo detalle. Persistencia instrumental/77tests/visual básico sí ejecutados. Riesgo residual: fetch completo por tarjeta visible aceptado para prototipo; no batch/escala/multiproceso/daño físico/cronología/alertas prometidos. Sin blocker implementer.

## Contrato y autorización

Worktree exclusivo `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/last-watering-hint`, rama `feature/last-watering-hint`, base comunicada dd87eaac018981d34725ccdbcca69a8d86630050. Usuario aprobó integralmente `docs/specs/last-watering-hint.md`; notas históricas no bloquean. Spec byte-intacta SHA2569966f0477f09c89d4b2ef16b3be9125e6fe0743176432e74c70a74dab929137c. Implementer no acepta ni hace stage/commit/push/PR/merge/GitHub. Padre entrega local solo tras aceptación independiente.

## Impacto → riesgos → selección

- Domain LoadLastWatering/formatter: máximo equivocado/UUID/kinds/fecha inventada → LoadLastWateringTests, LastWateringDateFormatterTests (hoy/anterior/año/zona/reloj/DST).
- VM/lifecycle/contexto/generaciones: error confundido con ausencia/carreras/loops/retención → LastWateringHintViewModelTests; callbacks/composición → PlantListViewModelTests, PlantDetailViewModelTests, PlantCardViewModelTests, RegisterCareViewModelTests. Foto/metadata independientes y cache retenida.
- Lectura real reutilizada sin schema/write → LocalCareEventRepositoryTests, nueva reapertura/orden/Plant/JPEG/payload exactos, anteriores migración/unknown/conflictos/errores.
- Lista/detail/recursos/accesibilidad → LastWateringHintUITests, seis escenarios persistentes con capturas focalizadas. Regresiones directamente relacionadas previstas: StoredCollectionUITests, PlantCardsUITests, EditPlantUITests, LocalizationUITests; no gate completo por implementer.

## Entorno y preparación

Sin competidores xcodebuild/init/test al preflight. Xcode26.2/17C52/macOS26.5.1/25F80; único estándar iPhone17Pro iOS26.2/23C54 UDID00BBB7EC-8DF7-400C-A08A-9D3C8818D886. Boot+bootstatus, light, content_size large (normal); XCTest5 clones aislados, sin matrices. Config inicialmente ausente: solo plantilla pública vacía copiada a ruta ignorada, ningún privado leído/copied/overwrite. Sin API/red ni datos reales.

## Comandos/evidencia en curso

Artefactos ignorados `DerivedData/evidence/last-watering-hint/`.

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -derivedDataPath DerivedData build-for-testing
```

Primera build `build.log` FAILED exit65: dos errores de Swift (defaultValue interpolado no StaticString y comma en expresión lógica de fixture); no tests ejecutados allí. Reparados, `build-repair.log` BUILD SUCCEEDED exit0. No borrar ni contar primer fallo como verde.

```sh
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -resultBundlePath DerivedData/evidence/last-watering-hint/focused.xcresult \
  -only-testing:PlantCareAITests/LoadLastWateringTests \
  -only-testing:PlantCareAITests/LastWateringHintViewModelTests \
  -only-testing:PlantCareAITests/LastWateringDateFormatterTests \
  -only-testing:PlantCareAITests/PlantListViewModelTests \
  -only-testing:PlantCareAITests/PlantDetailViewModelTests \
  -only-testing:PlantCareAITests/PlantCardViewModelTests \
  -only-testing:PlantCareAITests/LocalCareEventRepositoryTests \
  -only-testing:PlantCareAITests/RegisterCareViewModelTests \
  -only-testing:PlantCareAIUITests/LastWateringHintUITests test-without-building
```

Fuente de esta selección: `focused-source-hashes.json` (app/tests/proyecto/catálogo públicos, no config privada); aún no atribuir resultados pendientes a fuentes nuevas. Static plutil, JSON claves únicas, git diff --check y SHA spec ejecutados correctamente. Gate de main es antecedente, no evidencia sobre este delta.

## Siguiente

### Primera focalizada y reparación acotada

`focused.xcresult` FAILED exit65, **50Passed=47unit+3UI,3UIFailed,53total**, cero skipped/expected failures. Tres fallidos: FailedHiddenNoRetryAndLifecycleForegroundRecovery, LoadingCompletelyAbsentThenNormalLoadedWithoutPhotoDependency, PostCommitReadFailureKeepsRealConfirmationAndHiddenSummary. Causa corroborada: assertHidden accedía al value de plantCard aun en detalle; snapshot solo contiene Back/Edit/Register, no card. Targeting movido exclusivamente a rama listado, misma assertion negativa allí; ID/ausencia/textos/CTA/consejo/ficha en detalle preservados. No reparación de producto ni debilitar igualdad/comportamiento. `focused-summary.json`, log y attachments originales conservados.

Rebuild y `ui-repair.xcresult` selección ORIGINAL solo3 UI fallidos +2 tests nuevos DetailVM (lectura antes de foto pendiente/metadata ausente sin consulta; commit confirmado con lectura fallida conserva banner y no recarga foto/metadata, otro kind no consulta). Comando mismo xctestrun/destino/5workers/capturas1, only-testing paths de esos5 exactos en shell/log y selección resumida aquí. `ui-repair-source-hashes.json` vs focused manifiesto demuestra **solo dos ficheros test** cambiados: PlantDetailViewModelTests y PlantCareAIUITests; app/proyecto/catálogo idénticos. Los47unit+3UI aprobados previos son reutilizables para inputs/comportamientos intactos, no green retroactivo del aggregate fallido.

Inspección visual REAL ya abierta de5 PNG originales: last-list-none, last-detail-none, last-detail-today, last-long-list-earlier, last-long-detail-earlier. Foto4:3/identidad/composición preservadas; ausencia/fecha correctas sin urgencia, consejo solo detalle, wrap nombre/especie/ubicación completos. CTA en captura larga al borde del viewport, recorrido persistente verifica alcanzable mediante scroll; no reclamar toda pantalla visible de una vez. Pendiente abrir hidden/final y regresiones, no gate.

### Segunda focalizada y scope de assertions

`build-ui-repair.log` BUILD SUCCEEDED exit0. `ui-repair.xcresult` FAILED exit65 **4/5 Passed=2unit+2UI,1UIFailed**, cero skips/expected failures. Los dos tests nuevos DetailVM y recovery/loading pasaron. PostCommitReadFailure llegó a commit confirmado, summary oculto en detalle/CTA/consejo/ficha/bandera intactos, captura y regreso; falló en assertion global «Sin riegos registrados» del listado. Activities JSON corrobora primero ID card A ausente (correcto), luego texto global encontrado: B no invalidada tiene ausencia real. Se corrige scope por UUID (ID y accessibilityValue de A), conserva negativos globales SOLO en detalle con un UUID; añade igualdad explícita del summary B loaded(nil). No producto ni scripts de gate alterados. Fallos previos intactos, no reintento de fuentes idénticas.

Selección ORIGINAL `scope-visual.xcresult`: único fallido+otros2 callers del helper modificado, capturas1; después `regressions.xcresult`17UI StoredCollection2/PlantCards4/EditPlant2/Localization1/CareEvents8, capturas0. Secuenciales con set-e, no competidores ni duplicación manual. Mismo comando base/destino/5workers/test-without-building, nuevo build-scope.log. `final-source-hashes.json` vuelve a demostrar producto/proyecto/catálogo idénticos a primer bundle; solo los2 archivos test difieren. Pendiente resultado de esta ejecución, no passing todavía.

Inspección REAL ampliada a **11 PNG** únicos: los5 anteriores +last-list-today de focused, y last-detail-failed-hidden/last-list-failed-hidden/last-detail-loading-hidden/last-list-loading-hidden/last-confirmed-read-failed de ui-repair. Manifests en focused-attachments/ui-repair-attachments enlazan nombre→UUID.png; imágenes abiertas, no solo exportadas. Resumen oculto sin hueco/fila/icono/spinner/error/retry, identidad/foto normales y box/CTA/consejo/ficha presentes; confirmación real conservada tras error. Se reutilizan visuales por producto idéntico aunque aggregate bundle FAILED, sin reinterpretar ese fallo ni reclamar escenarios incompletos como Passed. No matrices ampliadas, VoiceOver inspector ni smoke manual humano ejecutados.

Terminar selección original sin duplicados/retries, conservar fallos si aparecen y diagnosticar focalmente; inspección real de capturas afectadas y regresiones caller antes de passing. Luego validator independiente revisa diff/contrato y ejecuta único gate final `caffeinate -dius ./init.sh` ambas fases, sin repetir focales cubiertas. No acceptance implementer. CONSTRAINTS/AGENTS sin delta; dominio/design/arquitectura/ADR010/riesgos/testing actualizados. Coste fetch por tarjeta visible aceptado para prototipo; sin historial/alertas/batch/backfill nuevo. Smoke manual: abrir plantas A/B, cancelar/registrar otros tipos/riego retroactivo y hoy, volver listado/reabrir proceso, comprobar fecha/ausencia y consejo solo detalle. Verificación ampliada no solicitada fuera habitual, no pendiente automático.
