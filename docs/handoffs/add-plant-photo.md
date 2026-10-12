# add-plant-photo — implementación y autoverificación

2026-10-12, implementer `openai/gpt-6.1-sol`, feature-implementer + ios-clean-mvvm. **passing, NO accepted**, revisión independiente/gate final pendientes. Mismo worktree/rama `feature/add-plant-photo`, base `12c5184c6f34b2ae2faa5e15b95b54a8991a735e`; sin otro checkout, delegación, stage/commit/push/GitHub/PR/merge. Issue36 pertenece al orquestador.

Spec aprobada íntegramente por usuario, bytes conservados SHA256 `2923282365edeaa511672dc14dc79bc85d1cc8dd49f59c0aa104d87c55db37b0`. Sus notas de planner pendiente son históricas, no una prohibición vigente de implementación; no se reescriben ni marcan sus checkboxes.

## Cambios → riesgos → selección

| Cambios | Riesgo | Comprobación seleccionada |
| --- | --- | --- |
| PlantPhotos Domain, siete campos/tiempo/identidades/orden | Futuro, DST/día omitido/origen, colisión initial/additional, pertenencia | AddPlantPhotoTests, LoadPlantPhotosTests; CareEvents temporal no refactorizado |
| PersistedPlantPhoto + actor/container/cleanup V3 | Upgrade real, destrucción accidental, huérfanos, rollback/conflicto/bytes | LocalPlantPhotoRepositoryTests completos, LocalPlantRepositoryTests + LocalCareEventRepositoryTests completos |
| VM/modal/pipeline/cámara | A/B/cancel/tardíos/prevalidación/retry/clock/commit/doble tap | AddPlantPhotoViewModelTests completos, pipeline/validador/cámara existentes; AddPlantPhotoUITests |
| PagerVM/cache/generaciones/readers | Metadata incompleta, selección retroactiva, imagen equivocada/retry, memoria/late result/cero writes | PlantPhotoPagerViewModelTests completos; unión Domain y E2E fechas/dimensiones/swipe/botones/relaunch |
| App→List→Detail fábricas/navegación/snapshot inicial | Card/portada/edición/cuidado/último riego/alta/fallback | VM List/Detail existentes+nuevo factory test;13 UI regresiones directas |
| Debug fixtures/resources/proyecto | Fakes productivos, claves crudas, flags en Release | PhotosPicker real2 seriales, JSON únicas/traducciones anteriores/PBX único/plutil/Domain typecheck, Release build+nm/strings |

### Archivos/límites

Nuevos11 Swift en Features/PlantPhotos/{Domain,Presentation,Data};4 ficheros unitarios (LoadPlantPhotosTests comparte AddPlantPhotoTests.swift). Actor real, App, List/Detail VM/View, StorageTestFixture Debug, proyecto/catalog15 claves, test Detail y UI afectados. Arquitectura/ADR011/dominio/DESIGN/riesgos/testing actualizados. ContentView, init.sh, Plant/CareSheet/PersistedPlant/PersistedCareEvent/transporte/consentimiento/helpers heredados intactos. No nueva constraint operativa fuera de lo ya fijado en spec/ADR/ARCHITECTURE.

Una foto por operación, persistencia local real; ninguna IA al añadir/paginar. Modal vacío/hoy, JPEG preparado/preview4:3, fecha humana editable, cámara/álbum, Guardar. Reemplazo fallido/cancelado conserva A/fecha/snapshot retry; nueva selección/fecha invalida intención. Prevalidación cancelable y sesión comprobada antes de despacho, commit bloqueado, éxito reconocido tras cancelación técnica. Callback canónico único dirigido a UUID antes de cerrar la sheet desde su propietario.

V3 aditivo no versionado sobre mismo Plants.store, archivos AdditionalPhotos separados; todos los metadatos/pertenencias válidos antes de **ambas** limpiezas. Tests crean V2/V1 reales y liberan containers antes de upgrade/reopen, no store nuevo presentado como migración. Portadas/dos Plant/cinco kinds exactos. Duplicado literal antes del reloj, conflicto sin overwrite; validar JPEG antes de contexto, no await entre duplicate/publicación/save; rollback solo de archivos propios. Referencia rota no borra registro ni planta.

Inicial proyectada una vez; orden absoluto desc/createdAt desc/clave discriminada asc; apertura inicial aunque no índice0. Commit selecciona nueva identidad incluso retroactiva, thumbnail/cache+reconciliación generacional, error de actualización separado de éxito. Metadata antes de bytes adicionales, carga solo selección, fecha visible ante error, retry propio, controles extremos sin wrap. Cache≤3 thumbnails1600 sin JPEG, inicial retenida para editor/cuidados; cancelación/late decode/metadata/bytes/lifecycle cubiertos. Seam real beforeCommit en integración comprueba5 escrituras de setup y **cero** al paginar/refrescar/reaparecer, además del doble Domain que cuenta0 escrituras.

## Entorno/fuentes/evidencia

`DerivedData/evidence/add-plant-photo/` contiene logs completos, `.exit`, xcresults originales, summaries/árboles, attachments/manifests y `commands.json` con invocaciones exactas extraídas de las cabeceras. No resultados antiguos de base reutilizados. No ./init.sh, gate completo ni baseline completo por implementer.

- Xcode26.2/17C52, macOS26.5.1, iPhone17Pro iOS26.2/23C54 `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, texto normal/claro. Una sola plataforma/modelo/runtime;5 clones XCTest aislados solo para fase focalizada UI. Otros comandos seriales/caffeinate, ninguno simultáneo. Preflight pgrep/bootstatus/appearance; ningún xcodebuild/xctest activo al cierre.
- Config Debug preparada exclusivamente con `if [ ! -e Config/IdentificationSecrets.xcconfig ]; then cp Config/IdentificationSecrets.xcconfig.example Config/IdentificationSecrets.xcconfig; fi`. No lectura/copia/overwrite de fichero real existente, API real ni configuración privada/xcuserdata inspeccionadas. El fichero local y DerivedData permanecen ignorados.
- Manifest final **139 inputs públicos** `ready-public-inputs.json` SHA256 `56df7ee72bc9cf9884afa61763d349cc04c8583e8f44448f54f537e3d0258999`. Incluye Swift/tests/proyecto/shared scheme/recursos/config pública/scripts/init; excluye secretos/xcuserdata. Manifests anteriores seleccionados de123 inputs conservados, no atribuidos a fuentes posteriores. Early builds/diagnósticos no tenían manifest completo: logs conservan comandos/ficheros compilados, no inventar hashes antiguos.
- `selected-results.json`: **83 escenarios distintos válidos =62unit+21UI**, último resultado seleccionado Passed, cero skips/expected failures en evidencia final seleccionada. No suma de repeticiones ni aprobación de aggregates fallidos. UI21=6nuevos+13regresiones+2Fotos; unit62=15nuevos (incluye Detail factory)+47regresiones.

### Ejecuciones/reutilización válida

| Bundle | Resultado original | Uso final |
| --- | --- | --- |
| unit-first | exit0,54unit/54 | Domain/preparador/validador/cámara/List/Detail y otros callers sin cambios pertinentes; Data y VM/pager luego sustituidos focalmente |
| target-repair | aggregate FAILED exit65,23unit Passed+2UI Passed+1UI Failed |18regresiones Data válidas sobre cleanup/pertenencias final; no aprobación del aggregate |
| final-unit-strengthening | exit0,6unit/6 |4LocalPhoto+Detail factory; pager real sustituido por seam reforzada posterior |
| cancellation-final | exit0,8unit+1UI |5VM+3pager, cancel/decode/snapshot/late; pager real luego sustituido por seam |
| zero-write-seam | exit0,1unit/1 |Assert real beforeCommit (5setup→5tras navegación), reemplaza el mismo escenario, no añade uno |
| final-ui | FAILED exit65,18Passed/19 |16UI sin cambios pertinentes después; error propio y cancel preparación sustituidos según abajo, fallo original conservado |
| retry-target-repair | exit0,2UI/2 |Regresión PhotoFailure reparada +error/retry metadata/adicional sobre label44 final |
| gallery | exit0,2UI/2 |Clase Fotos completa serial: identificación preservada y nuevo adicional real con JPEG independiente exacto/relaunch sin reseed |

Reuso por impacto, no fuentes globalmente idénticas: después de final-ui cambiaron únicamente labels de retry≥44 (ambos callers reejecutados), guardas de lectura adicional para metadata JPEG excluida (LocalPhoto y pager real reejecutados; los JPEG válidos E2E ya comprobados byte/dimensiones no cambian), puente de cancelación/checks de thumbnail (VM/pager y UI preparación cancelada reejecutados). Fixture gallery solo comentarios después de su ejecución; prueba zero-write solo refuerza test, producto/Release intactos. Último product build-for-testing cancellation-final y Release-final correctos; zero-write recompiló el test modificado. Validator debe verificar las fuentes finales, no reutilizar aggregates fallidos como gate.

### Comandos principales ejecutados

Las invocaciones exactas de cada selección se preservan en `commands.json` y primeras líneas de su `.log` (incluidos logs de fallos). Patrón base real:

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData/PhotoBuild" \
  CODE_SIGNING_ALLOWED=NO build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/PhotoBuild/Build/Products" 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
  -destination "platform=iOS Simulator,id=$UDID" -parallel-testing-enabled YES \
  -parallel-testing-worker-count 5 -only-testing:PlantCareAIUITests/AddPlantPhotoUITests \
  -only-testing:PlantCareAIUITests/StoredCollectionUITests \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testPlantCardsSelectCorrectIdentity \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testLongCardTextRemainsReachable \
  -only-testing:PlantCareAIUITests/EditPlantUITests \
  -only-testing:PlantCareAIUITests/CareEventsUITests/testThreeTapWateringRealCommitRelaunchAndNewIntentionSameDay \
  -only-testing:PlantCareAIUITests/CareEventsUITests/testBusyBlocksFieldsCancelAndGestureWithMissingPhoto \
  -only-testing:PlantCareAIUITests/SavePlantUITests/testSavePlantAutomaticAIAndManualSameSpeciesRelaunch \
  -only-testing:PlantCareAIUITests/LocalizationUITests \
  -only-testing:PlantCareAIUITests/LastWateringHintUITests/testAbsenceTodayRetroactiveOtherCancelIsolationAndPersistence \
  -only-testing:PlantCareAIUITests/LastWateringHintUITests/testLoadingCompletelyAbsentThenNormalLoadedWithoutPhotoDependency \
  -resultBundlePath "$PWD/DerivedData/evidence/add-plant-photo/final-ui.xcresult" test-without-building
```

Ese comando original falló18/19 y **no se repitió**: repair solo2callers pertinentes. Posterior preparación cancel/decode solo8unit+1UI. Fotos ejecutadas con `configure-ui-test-environment.py ... 0`, `-parallel-testing-enabled NO -only-testing:PlantCareAIUITests/SystemGalleryUITests`, `gallery.xcresult`; antes `xcrun swift scripts/seed-identification-photos.swift "$PWD/DerivedData/IdentificationPhotoMedia"` y `simctl addmedia "$UDID" ...picker-A.png ...picker-B.png` tras bootstatus. Sin borrar media ajena.

Release-final: `caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/DerivedData/PhotoRelease" CODE_SIGNING_ALLOWED=NO build`, exit0. `nm`+`strings` del binario: PlantPhotoTestFixture/PlantPhotoReadTestFixture y nuevos flags ausentes. Release previo válido para su estado, sustituido al añadir cancelación productiva. Domain completo Foundation-only: `xcrun swiftc -typecheck $(find PlantCareAI/Features -path '*/Domain/*.swift' | sort)`, exit0. `plutil -lint ...project.pbxproj`, JSON únicas/traducciones anteriores/PBX IDs únicos, diff-check y SHA spec pasan. No nuevos bridge keys API ni sidecar fotográfico.

## Fallos conservados / diagnóstico

- migration-first: build FAILED65/0tests, IDs PBX nuevos DD colisionaban con PlantCards. Cambiados solo IDs nuevos a DB, no tocar entradas heredadas.
- migration-project-repair: FAILED65,0/3tests y6errores. JPEG histórico raw de StorageTestFixture no cumple contrato preparado sin metadata. Entradas adicionales pasan por preparador real; portadas siguen raw/exactas. migration-fixture-repair3/3 Passed pero conserva warnings SQLite por unlink con container vivo en loop; test libera reopened antes de eliminar raíz y final-unit-strengthening4/4 sin esos warnings.
- ui-first FAILED1Passed+3Failed; ui-repair FAILED1Passed+2Failed; ui-dismiss-repair FAILED3Passed+1Failed. ID contenedor del pager sobrescribía descendants (AX conservado): agregado `.contain`. Busy ProgressView se expone como otro elemento, búsqueda por ID sin reducir bloqueo. Commit rápido/retry exigió cerrar desde el propietario de la sheet por callback canónico; cierre/gesture/busy ahora pasan.
- target-repair, preview-hit-repair, native-date-repair, date-ax-diagnostic, image-frame-repair: mismo caso calendar FAILED, resto de unitarias/casos individuales válidos cuando corresponden. Hipótesis helper scroll y clipping/hit-testing/wrapper no resolvieron el fallo; **no se declaran causas probadas**. AX diagnóstico: botón enabled=true, frame completo visible; vídeo28s inspeccionado. Tap al centro nativo con existencia/enabled/geometry y calendario/futuro/fecha exactos pasó en date-center-repair1/1; posterior final-ui refuerza dimensiones reales A/B, swipe/extremos y aislamiento, pasa ese mismo escenario sin sumar repeats. No borrar assertions ni editar fecha por fixture.
- final-ui FAILED18/19 por retry inicial height20.33<44. Reparación label≥44, misma assertion heredada; retry-target-repair2/2 Passed.
- gallery-seed exit133 LaunchdSimError antes de tests: root acordado observado Shutdown tras fase paralela. Bootstatus del mismo UDID +light, nueva addmedia exit0, gallery2/2 Passed. No reset/media ajena ni ocultar fallo de preparación.

Todos logs/bundles originales FAILED permanecen. Sin test-iterations/retries automáticos ni repetir unchanged para verde. No fallos pendientes de escenarios seleccionados.

## Visual y límites

Realmente abiertos8PNG finales: empty1444…, preview441C…, retroactiveCBE8…, busyB63A…, long1903… y error024F… en final-ui-attachments; retry adicional9CF1… y retry inicial1052… en retry-target-attachments. Foto4:3, nombre largo multilínea, fechas/controles/errores/acciones y contraste correctos en destino normal/claro. Además dos imágenes diagnósticas anteriores (error y frame28 del vídeo) inspeccionadas, no evidencia final. Capturas automáticas de helpers heredados en selección focalizada incluyen filas incidentales; no inspección visual de toda la suite ni nuevas matrices. Futuras regresiones deben usar capturas0 para evitar esos adjuntos por fila; no se repiten ahora por fotografías.

Persistencia/relaunch y navegación fueron E2E, no smoke humano separado. Cámara física/iCloud, memoria constante de originales, downgrade/daño físico/multiproceso no acreditados. SE/texto aumentado/VoiceOver/otras apariencias fuera de comprobación habitual, no ejecutados/no bloqueos automáticos.

## Handoff siguiente

Sin bloqueo implementer, no procesos activos. Validator independiente revisa diff/spec/ADR/83 focalizadas y ejecuta **único** gate final `caffeinate -dius ./init.sh` con ambas fases, preflight del UDID acordado. Predicción descubrimiento233=173unit+58UIparallel+2Fotos serial, no resultado ejecutado. No duplicar focales cubiertas por ese gate sin laguna concreta. Orquestador maneja accepted/commit/autorizaciones Git después del verdict; implementer no declara aceptación.
