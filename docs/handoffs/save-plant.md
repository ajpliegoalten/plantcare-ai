# Handoff — save-plant / implementer

**Estado final: passing, lista para validator independiente; NO accepted.** 88 focalizadas distintas válidas =68 unit +20 UI, incluye refuerzo largo exacto1000 verde. Release/auditoría/estáticos e inspección básica correctos; gate completo único pendiente del validator. No procesos xcodebuild activos ni cambios ejecutables posteriores al cierre. No init/full gate del implementer.

Worktree exclusivo `save-plant`, rama `feature/save-plant`, base `f4473e33406bf4236c5382c65c2c0f5436ed30a8`, issue #26. Usuario autorizó implementación y flujo posterior al validator; este subagent no lo lanza ni hace stage/commit/publicación. Spec aprobada intacta SHA256 `b1da9160d037fa26aef29aace79398e01b25bb7c1a05b28d435c78fcb31fcd4e`. Cambios iniciales del planner PROGRESS/notas/spec preservados.

## Contrato implementado

Seleccionar propuesta/manual y completar texto → Confirmar especie → cuidados autorizados completos → validar JPEG/snapshot → guardar → callback al listado → dismiss/scroll Mis plantas. Sin resumen, review, formulario, CTA extra o detalle automático. Nombre de especie, ubicación nil, UUID nuevo/fecha estable/retry local sin IA. Cancelación antes de despacho; cierre/gesto/cambios bloqueados al commit; éxito reconocido sin guard de cancelación posterior. DuplicateID solo reconciliado con metadata y bytes exactamente iguales. Mismo repositorio App; Domain sin frameworks de UI/persistencia, ImageIO Data fuera de MainActor. ADR007 supersede review de ADR006 sin modificar historia.

## Archivo → riesgo → selección

| Cambios | Riesgo | Comprobaciones |
| --- | --- | --- |
| SavePlant Domain/Data, JPEG preparado | mapeo erróneo, foto corrupta/metadata, snapshot inválido, duplicado conflictivo | SaveConfirmedPlantTests, PreparedPlantPhotoValidationTests; IdentificationPhotoPreparationTests, GenerateCareSheetTests, LocalPlantRepositoryTests |
| IdentificationPhoto VM | doble confirmación, retry remoto en fallo local, stale/close/commit oculto | SavePlantViewModelTests; GenerateCareSheetViewModelTests, ConfirmSpeciesViewModelTests, ManualSpeciesViewModelTests, IdentificationConsentViewModelTests |
| App/lista/callback/orden y LocalPlantRepository desempate | instancia distinta, lista parcial, metadata atrasada, cache perdido/relaunch | PlantListViewModelTests, LocalPlantRepositoryTests; UI altas/relaunch/aislamiento y callers detalle/edición/foto/consent |
| Estado inline/review retirada/ayuda/catalog/proyecto | pantalla prohibida, controles/cancelación incorrectos, fuentes o traducción ausentes | tres nuevas UI + once UI adaptadas + seis regresiones directas; parse/plutil/JSON/typecheck/diff y inspección básica |

Persistencia/composición/navegación justifican ampliar selección a estos callers, no toda suite ni full baseline. Gate completo previo 146/146 solo antecedente de base, no evidencia de alta nueva.

## Entorno y comandos efectivos

- Xcode 26.2/17C52, macOS26.5.1, iPhone17Pro iOS26.2/23C54 `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, light/texto normal, serial/caffeinate. No tests simultáneos, no retries/iterations. Config privada/xcuserdata no leídos/copied; sandbox público `DerivedData/save-plant-public`, plantilla vacía y `Config/IdentificationDebugInfo.plist` público. Manifest final de entrada 98 archivos `DerivedData/evidence/save-plant/final-repair-hashes.json`, root coincide; posteriores cambios documentales no invalidan fuentes ejecutables.
- CWD de todas las ejecuciones Xcode correctas: `DerivedData/save-plant-public`. Base exacta:

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
 -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
 -derivedDataPath DerivedData -resultBundlePath <nombre>.xcresult \
 -parallel-testing-enabled NO <selectores> test
```

Salida de cada ejecución redirigida `> ../evidence/save-plant/<nombre>.log 2>&1`; salida real preservada en `<nombre>.exit`. El encabezado de cada log conserva comando completo exacto. Bundles en sandbox, exports/summaries/hashes en carpeta de evidencia.

| Nombre | Selectores reales | Resultado |
| --- | --- | --- |
| unit-first | SaveConfirmedPlantTests, PreparedPlantPhotoValidationTests, SavePlantViewModelTests | build FAILED exit65, plist público omitido; cero tests |
| unit-prepared | anteriores + LocalPlantRepositoryTests, PlantListViewModelTests, GenerateCareSheetViewModelTests, GenerateCareSheetTests, ConfirmSpeciesViewModelTests, ManualSpeciesViewModelTests, IdentificationConsentViewModelTests, IdentificationPhotoPreparationTests | build FAILED exit65, helper wait debía ser escaping; cero tests |
| unit-build-repair | mismos once selectores (prefijo `-only-testing:PlantCareAITests/`) | FAILED63/64 exit65, JPEG truncado tolerado por ImageIO; único test de validator fallido |
| photo-repair | SaveConfirmedPlantTests, PreparedPlantPhotoValidationTests | TEST SUCCEEDED5/5 exit0 tras guard SOI/EOI; cero skips |
| ui-new-first | tres nombres nuevos de docs/testing-save-plant.md (prefijo `-only-testing:PlantCareAIUITests/PlantCareAIUITests/`) | FAILED2/3 exit65, dos nuevas pasan; commit fixture3s ya acabó al consultar estado |
| final-unit | SaveConfirmedPlantTests, PreparedPlantPhotoValidationTests, SavePlantViewModelTests, PlantListViewModelTests | interrumpida exit73: nuevo test cache aguardaba doble retenido sin resolver; no aprobación |
| final-unit-cache-repair | mismos cuatro selectores, después de resolver explícitamente doble y simplificar sort de tarjetas | TEST SUCCEEDED14/14 exit0, cero failures/skips/expected failures, 18:25:04–18:25:11 +0200 |
| ui-commit-repair | solo testSavePlantCancellationCommitAndNoReview | FAILED0/1 exit65; bloqueo Cancelar acreditado, pero título colección existe detrás de sheet y test terminó proceso antes del commit15s |
| ui-dismiss-repair | solo testSavePlantCancellationCommitAndNoReview | TEST SUCCEEDED1/1 exit0 cero skips; espera explícita de sheet ausente25s antes de contar/terminar, aserciones intactas; 18:28:07–18:29:47+0200 |
| ui-related | dos UI nuevas restantes + once adaptadas + seis regresiones enumeradas en encabezado del log | TEST SUCCEEDED19/19 exit0, cero failures/skips/expected failures; 18:30:14–18:59:34+0200. Esperada salida original mediante NOTE_EXIT, sin polling/rerun |
| ui-error-visual | solo testSavePlantLocalFailureRetryWithoutNewCareRequest y testCareSheetFailureIncompleteRetryAndConsentCancellation | TEST SUCCEEDED2/2 exit0 cero failures/skips;19:01:24–19:05:04+0200. Únicamente reveal de captura, producto/aserciones intactos; fotos/error/retry realmente inspeccionados |
| final-vm-offline | solo SavePlantViewModelTests | TEST SUCCEEDED3/3 exit0 cero failures/skips;19:05:34–19:05:38+0200. Refuerzo: configuración API cambia a inválida tras fallo local, retry estable sigue guardando sin llamadas nuevas |
| ui-exact-long | solo testCareSheetLongTextAndIdentityInvalidation | TEST SUCCEEDED1/1 exit0 cero failures/skips;19:12:23–19:14:37+0200. Fixture long genera1000 exactos por campo; assertion verifica Abonado íntegro1000 antes/después de relaunch, scroll y segundo ejemplar intactos |

Además la preparación inicial redirigió por error a ruta inexistente desde root: exit1 antes de iniciar xcodebuild, conservada notificación de shell; nunca config privada leída. Tras SIGINT de final-unit, intento TERM encontró proceso ya inexistente; xcodebuild terminó73, app de tests terminada antes de continuar.

**Unitarias válidas distintas: 68 =11 final-unit-cache-repair +3 final-vm-offline +54 anteriores pertinentes reutilizadas**. Final VM sustituye sus3 casos, no añade al total. Resto54 unit-build-repair individualmente verdes, sin cambios relevantes en rutas ejecutadas (esas VMs de generación/conf/manual/consent no inyectan alta y no entran en nueva rama validating). Aggregate63/64 sigue FAILED, no se reinterpreta. Foto reparación5/5 histórica, no sumada otra vez. **UI20 distintas verdes =16 related +2 error-visual +1 dismiss-repair +1 exact-long**; dos errores y caso largo se repitieron por refuerzos concretos, no para convertir fallo funcional en verde ni sumar tests otra vez. Cambio posterior del fixture afecta solo modo long dentro de archivo completamente excluido de Release; otros modos/callers/compilación Release y unitarias relevantes intactos, evidencia reutilizada por impacto.

Estáticos ejecutados: `git diff --check`, `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, `python3 -m json.tool feature_list.json` y catálogo, `xcrun swiftc -typecheck $(find PlantCareAI/Features -path '*/Domain/*.swift' -type f)` Foundation-only, `xcrun swiftc -frontend -parse` de archivos nuevos/modificados de alta/VM/lista/App/tests/UI, hash de spec: correctos, `static.log`. Capturas iniciales exportadas en `ui-new-first-attachments`, realmente inspeccionadas colección dos plantas, fallo local y espera; contraste de retry reparado para la ejecución final. Ninguna inspección ampliada ni API real atribuida al agente.

## Manual/API y pendientes

Guía completa `docs/testing-save-plant.md`: usuario debe configurar privadamente HTTPS/modelo/auth opcional, autorizar fotos propias y aceptar aviso v4 antes del envío. Tests usan dobles, no API real. Cámara física requiere permiso/firma/dispositivo; no pedir micrófono/ubicación. No copiar/publicar Debug con clave. Evidencia real previa de cuidados no acredita esta nueva alta. Matrices ampliadas/VoiceOver/texto aumentado/SE/iCloud/cámara física fuera de verificación habitual; no ejecutadas.

**Pendiente solo gate/aceptación independiente del validator**; no init/full gate del implementer. Release generic Simulator BUILD SUCCEEDED exit0, build separado sin ejecutar simulador (DerivedDataRelease), justificado por nuevo fixture/counter y composición condicional Debug; strings/nm sin tipos/flags/seams nuevos y plist sin claves config, `release.log`/`release-audit.log`. No tests simultáneos. Final98 archivos públicos root=input, `delivery-source-hashes.json` SHA256 `b12e7df3cee072a8d7ee6aa47f0a672636d5d1a6e1d61e61e6792a43512894b9`; nuevo manifest difiere de `ui-dismiss-repair-hashes` solo en dos archivos de tests (reveal capturas y refuerzo API inválida). Producto/Release y otros tests no invalidados por esos cambios focalizados. Digests de summaries y manifest en `evidence-hashes.json` SHA256 `3da0ea26e8035a9d3b8cd0e9a0306caf36b82f9df5f7632575d0340cf7a62c07`. Final diff/plutil/JSON/spec hash correctos; no cambios ejecutables posteriores.

**Hashes definitivos tras refuerzo largo** (los anteriores describen la entrega previa y se conservan): `delivery-source-hashes.json` SHA256 `fe6de5e8f97509825a6c48a5281fc1b91e6d0c263f0bab99788ff8f0c0c0e1d7`,98 inputs públicos coinciden con root; `evidence-hashes.json` SHA256 `823398fd0a6ba0d3c0bc77ccbf7a9bbd555703a275364eaa56bdc212860ee6d0`. Delta adicional únicamente modo long del fixture Debug y su assertion UI, selección1/1 específica recién ejecutada; old snapshot `before-exact-long-source-hashes.json` conserva hash b12e. Parse de los tres archivos tocados recientemente, JSON/plutil/diff/spec hash finales correctos. Captura exacta final `ui-exact-long-attachments/D65AD746-600C-4D94-A5AE-161717540812.png` inspeccionada: cuerpo largo/Abonado y scroll estándar; contenido íntegro1000 también acreditado por assertion tras relaunch. Gate final debe usar este estado, no snapshots anteriores.

Gate sugerido del validator: desde `DerivedData/save-plant-public`, ejecutar **una vez** `caffeinate -dius ./init.sh` sobre inputs finales. El sandbox ya incluye además el script público original `scripts/seed-identification-photos.swift`, necesario solo para ese gate/PhotosPicker real (no usado en las focalizadas aquí). Root/harness intactos; supplemental `validator-gate-support-hashes.json` corrobora init SHA256 `aef891405f810deaeccaae915147367ce3cd3f78bd1285270e5c4d8e6f357b95` y seed SHA256 `ef8295193e3a705e94324b96c96870e92556d037309165a7644c5d9df24e8e79`. Copia y parse de soporte, **no ejecución** de init/seed por implementer. Mantener mismo único simulador estándar booted y plantilla vacía; no copiar configuración privada/xcuserdata. Si el validator prepara sandbox fresco, incluir fuentes/recursos/proyecto/shared scheme/plist Debug público/init/seed y plantilla, comparar manifests antes de probar.

Inspección final real: `ui-error-visual-attachments/AB87DCDA-E9C4-4071-B807-9830D38107A0.png` (foto/error local/ retry blanco sobre verde), `0148909A-BD36-4A3C-8604-CD71B6C4B23A.png` (ficha incompleta/retry remoto), `ui-related-attachments/C28C3895-02DA-4BB1-960E-35C4D7DB2AED.png` (dos tarjetas/fotos distintas/retorno), `94D19955-F1EC-4E70-A51B-05E55CE1BE6B.png` (detalle largo desplazable), además de espera inicial/commit bloqueado y detalle seis campos ya enumerados. Capturas originales de errores desplazadas conservadas, no atribuidas a inspección del texto fuera de pantalla. Contadores superpuestos en colección solo fixture Debug opt-in, no UI de producto. No API real nueva ni matrices ampliadas reclamadas; permisos/manual futura en guía, no fingidos. No lanzar validator desde este subagent. Parent gestiona commit local después de aceptación; no push/PR/merge autorizado.

## Lista exacta de archivos de entrega

- `PlantCareAI/Features/SavePlant/Domain/PreparedPlantPhotoValidating.swift` (nuevo)
- `PlantCareAI/Features/SavePlant/Domain/SaveConfirmedPlantUseCase.swift` (nuevo)
- `PlantCareAI/Features/SavePlant/Data/LocalPreparedPlantPhotoValidator.swift` (nuevo)
- `PlantCareAI/Features/SavePlant/Data/PlantCreationTestFixture.swift` (nuevo, Debug Simulator)
- `PlantCareAI/Features/SavePlant/Presentation/PlantCreationStatusView.swift` (nuevo)
- `PlantCareAI/Features/GenerateCareSheet/Presentation/CareSheetReviewView.swift` (eliminado)
- `PlantCareAI/Features/GenerateCareSheet/Data/CareSheetGenerationTestFixture.swift`
- `PlantCareAI/Features/IdentificationPhoto/Presentation/IdentificationPhotoViewModel.swift`
- `PlantCareAI/Features/IdentificationPhoto/Presentation/IdentificationPhotoView.swift`
- `PlantCareAI/Features/PlantList/Data/LocalPlantRepository.swift` (solo desempate estable de lectura)
- `PlantCareAI/Features/PlantList/Presentation/PlantListViewModel.swift`
- `PlantCareAI/Features/PlantList/Presentation/PlantListView.swift`
- `PlantCareAI/PlantCareAIApp.swift`
- `PlantCareAI/Localizable.xcstrings`
- `PlantCareAI.xcodeproj/project.pbxproj`
- `PlantCareAITests/SaveConfirmedPlantTests.swift` (nuevo)
- `PlantCareAITests/PreparedPlantPhotoValidationTests.swift` (nuevo)
- `PlantCareAITests/SavePlantViewModelTests.swift` (nuevo)
- `PlantCareAITests/PlantListViewModelTests.swift`
- `PlantCareAIUITests/PlantCareAIUITests.swift`
- `ARCHITECTURE.md`, `CONSTRAINTS.md`, `DESIGN.md`
- `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`
- `docs/adr/007-confirmed-plant-creation.md` (nuevo)
- `docs/testing-save-plant.md` (nuevo)
- `docs/handoffs/save-plant.md` (este archivo nuevo)
- `PROGRESS.md`, `feature_list.json` (preservan apuntes iniciales del planner)
- `docs/specs/save-plant.md` (spec inicial del planner, intacta, incluir posteriormente)

Artefactos DerivedData ignorados no se versionan. No cambios en init/shared scheme/config pública/secretos/xcuserdata ni specs/validaciones/handoffs históricos.
