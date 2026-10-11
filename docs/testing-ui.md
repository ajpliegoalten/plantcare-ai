# Suite UI: cobertura y coste

Refactor solicitado el 2026-10-11. En su fase inicial **no se ejecutaron builds, tests, simuladores ni mediciones**, por petición del usuario. La posterior validación y sus fallos están registrados en `docs/validations/ui-test-performance.md`; resultados de reparación en PROGRESS. No confundir esa historia con aceptación de las fuentes actuales.

## Ejecución

- `./init.sh`: una compilación `build-for-testing`, unitarias y UI de fixtures en paralelo, PhotosPicker real en una segunda fase serial. Ambas reutilizan productos con `test-without-building`. Un fallo en cualquier fase hace fallar el gate; no hay retries.
- Cinco workers por defecto, por petición posterior del usuario; `TEST_WORKERS=1..5` permite ajustar al equipo. XCTest gestiona clones aislados del mismo modelo/runtime, no varias sesiones competidoras. El PhotosPicker real queda fuera de los clones porque `simctl addmedia` siembra un simulador concreto. No se presupone que Fotos se replique a los workers.
- Resultados separados en `DerivedData/TestResults/<fecha-pid>/parallel.xcresult` y `gallery.xcresult`: comprobar ambos, no atribuir aprobación completa a uno solo.
- Los tests UI están divididos en **14 clases** dentro de `PlantCareAIUITests/PlantCareAIUITests.swift`, con helpers en una base sin tests. Trece clases participan en la fase paralela; `SystemGalleryUITests` en la fase serial. No se necesita cambiar el registro de fuentes del proyecto.
- Cada escenario usa UUID propios para almacén y consentimiento, sin estado compartido entre workers. El teardown termina la app y hace una sola apertura de limpieza para todos los UUID del escenario. El flag Debug Simulator `--test-cleanup-ids` acepta únicamente UUID y elimina solo `StorageTests/<UUID>` y `ExternalAIConsentTests.<UUID>`, nunca PlantStore ni preferencias estándar. Si un runner muere antes del teardown, pueden quedar fixtures aislados.
- Sin capturas explícitas de éxito por defecto. TestAction usa su propio entorno con valor literal0 (no hereda LaunchAction). `init.sh` aplica `UI_TEST_SCREENSHOTS=0/1` al `.xctestrun` generado mediante `scripts/configure-ui-test-environment.py`; ambas fases consumen ese mismo fichero. Una variable custom en el scheme no se expande desde un build setting arbitrario de xcodebuild. Para revisión visual **focalizada**, usar el mismo helper/configuración con selección `-only-testing`, como abajo. Los diagnósticos automáticos de XCTest ante fallos permanecen. No repetir toda la suite para obtener capturas.
- Un test se detiene ante su primera assertion fallida (`continueAfterFailure = false`), no encadena gestos y esperas sobre una pantalla desaparecida. Los helpers de reveal tienen un máximo de ocho gestos y conservan sus assertions de visibilidad/geometría. No se reducen los timeouts de existencia a ciegas.
- La selección de foto del fixture no espera artificialmente 2 s salvo `--photo-fixture-delay`, usado por el escenario que observa progreso/cancelación. Identificación normal tampoco espera 1 s artificial. Los modos de espera explícita de identificación/cuidados/commit conservan sus demoras para observar controles/cancelación.

## Selección focalizada (comandos para uso futuro, no ejecutados)

Elegir clases/tests por diff y callers, no toda la suite UI por cada feature. `test` compila lo necesario; `test-without-building` solo es válido con productos ya compilados para esas mismas fuentes/configuración/destino. No reutilizar productos anteriores tras cambiar código.

```sh
# Ejemplo: alta local y sus callers, no toda la suite.
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/SaveConfirmedPlantTests \
  -only-testing:PlantCareAITests/SavePlantViewModelTests \
  -only-testing:PlantCareAIUITests/SavePlantUITests test
```

Para inspección de una pantalla, compilar una vez con `build-for-testing` y usar la configuración explícita con una selección focalizada (comandos para uso futuro):

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 1)
xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAIUITests/ManualSpeciesUITests/testManualSpeciesAfterZeroCandidatesAndCancelEdit test-without-building
```

No volver a compilar si ya hay productos válidos del mismo estado/destino; el helper cambia solo el entorno de capturas del runner, no recompila. Para ejecución habitual sin capturas usar valor0; `init.sh` lo aplica por defecto. Para Fotos usar `docs/testing-identification-photo.md`: sembrar los recursos en `$UDID` y seleccionar `SystemGalleryUITests` con paralelismo deshabilitado. Ejecutar todos los tests desde Xcode sin esa preparación no equivale al gate.

Los antiguos selectores `PlantCareAIUITests/PlantCareAIUITests/...` ya no existen. Consultar la clase actual abajo; specs, handoffs y evidencias históricas mantienen los comandos realmente usados en su momento.

## Consolidaciones y cobertura sustituta

| Eliminado o recortado | Cobertura que conserva el contrato |
| --- | --- |
| `testCleanLaunchShowsEmptyCollectionAndAvailableAdd` | Sus textos, acciones disponibles y negativos se integran en `CollectionLayoutUITests.testEmptyCollectionCenteredBelowFixedHeaderAndAddWorks`. |
| `testEmptyCollectionCanScrollToAvailableAction` | El mismo test de colección desplaza el viewport, comprueba encabezado estable y abre desde ambas acciones Añadir. |
| `testIdentificationPhotoLeavesBothPersistedPlantsUnchanged` | `IdentificationResultUITests.testIdentificationCandidatesReadOnlyResultReplacementAndStorageIsolation` prepara/reemplaza/cancela y relanza con `--storage-verify`: compara ambos modelos completos y los JPEG exactos. |
| Recorrer dos detalles completos después de consentimiento/identificación/manual/cancelación | Se mantiene `--storage-verify` + ambas tarjetas cargadas. `StorageFixtureLoad` rechaza cualquier cambio de UUID/fecha/nombre/especie/ubicación/seis cuidados/JPEG antes de mostrar tarjetas. La presentación completa tiene su escenario propio. |
| Recorrer cuidados en cada selección A→B→A y varias veces tras editar | Navegación conserva UUID/nombre correcto, fotos/contenido de tarjeta y retorno. Edición conserva refresh/reopen y `--storage-verify-edited` para modelos y bytes; detalles completos en `StoredCollectionUITests`. |
| Manual→IA→confirmación repetida dentro del caso sin alternativas | Se verifica la UI específica de una sola propuesta; alternancia/cancelación/reconfirmación se conserva en `ManualSpeciesUITests` y `ConfirmSpeciesUITests`. |
| Reemplazo de foto y segunda alta manual dentro del test de texto de 1000 caracteres | Foto/invalidación tienen tests propios. El caso largo conserva 1000 caracteres exactos, desplazamiento y contenido tras relanzar; dos altas IA/manual tienen `SavePlantUITests`. |
| Cancelación remota repetida antes de probar bloqueo de commit | `CareSheetUITests.testCareSheetCancellationCloseAndStorageIsolation` conserva cancelación/cierre/sin alta y verificación de plantas originales; `SavePlantUITests` se dedica al commit bloqueado y persistido. |
| Cancelación del PhotosPicker en fixture de foto | Se traslada al único test del PhotosPicker real, que ahora sí prueba cancelar conservando la primera foto, además de reemplazar/reseleccionar. |

Tres métodos redundantes eliminados; tres métodos con bucles se separan en nueve casos independientes. **35 métodos anteriores → 38 actuales**, pero con menos recorridos/esperas/capturas. El número de métodos no representa el trabajo realizado: antes varios escondían hasta cuatro escenarios y dificultaban selección y diagnóstico. Las **125 unitarias** no se modifican: la refactorización se centra en el coste de UI, sin retirar cobertura de Domain, ViewModel, transporte o persistencia.

## Definición útil de cada escenario actual

Los nombres de métodos siguientes llevan el prefijo `test` en el código.

| Clase | Método | Contrato observado / decisión |
| --- | --- | --- |
| ExternalConsentUITests | ExternalConsentCancelGestureAcceptRememberAndRelaunch | Cancelar por botón/gesto no envía; pendiente no persiste; aceptación se recuerda entre intenciones/procesos, no en otra instalación aislada. |
| ExternalConsentUITests | ExternalConsentUnavailableAndBothPlantsUnchanged | Config inválida falla localmente, sin manual/envío/foto perdida; almacenamiento intacto sin repetir fichas. |
| ExternalConsentUITests | ExternalConsentReadErrorPreservesPhotoAndAllowsRetry | Fallo de lectura no autoriza; foto y acción de retry siguen disponibles, contador cero. |
| IdentificationResultUITests | IdentificationCandidatesReadOnlyResultReplacementAndStorageIsolation | Destinatario antes de enviar, propuestas no seleccionadas, reemplazo fallido conserva A, B limpia resultado, no altera plantas guardadas. |
| IdentificationResultUITests | IdentificationInsufficientEvidence | Insuficiencia distinta de error, sin propuesta, manual disponible y confirmación no habilitada automáticamente. |
| IdentificationResultUITests | IdentificationWithoutAlternatives | Propuesta única y manual presentes sin alternativa ficticia; confirmar usa la principal y cambiar conserva selección. |
| IdentificationResultUITests | IdentificationExplicitErrorRetry | Error explícito sin opciones manual/confirmación; retry humano produce resultado y una nueva invocación. |
| IdentificationResultUITests | IdentificationLongNameRemainsReachable | Nombre largo íntegro y acciones alcanzables, análisis libre oculto; confirmar conserva identidad. |
| IdentificationResultUITests | IdentificationWaitingCancellationCloseAndRelaunchWithoutDraft | Espera bloquea acciones; cancelar conserva foto, cerrar/relanzar descarta borrador y contador. |
| ManualSpeciesUITests | ManualSpeciesAfterZeroCandidatesAndCancelEdit | Blanco no confirma; toggle descarta texto/libera acciones; trim, precarga y cancelación de edición preservan identidad. |
| ManualSpeciesUITests | ManualSpeciesFromProposalsAndReturn | Selección IA/manual exclusiva, toggle IA, cancelar restaura, volver a IA exige reconfirmar sin reidentificar. |
| ManualSpeciesUITests | ManualSpeciesInvalidationCloseAndStorageIsolation | Texto largo/teclado, fallo de reemplazo conserva identidad, B/reidentificar/cerrar la invalidan; disco original intacto. |
| ManualSpeciesUITests | ManualUnconfirmedDraftDiscardedAfterInsufficientEvidence | Borrador manual tras cero candidatas no se restaura al terminar el proceso; separado del siguiente caso. |
| ManualSpeciesUITests | ManualUnconfirmedDraftDiscardedAfterErrorRecovery | No manual durante error; tras retry sí; borrador pendiente tampoco sobrevive al proceso. |
| ConfirmSpeciesUITests | ConfirmSpeciesAlternativeAndDraftInvalidation | Sin preselección, principal/alternativa exclusivas, identidad exacta, cambios/reidentificación/foto/close invalidan sin alta ante error retenido. |
| CollectionLayoutUITests | CollectionFixedHeaderWithPlantsAndDetailAfterScroll | Scroll mueve tarjetas pero no encabezado; detalle correcto y Añadir siguen accesibles. |
| CollectionLayoutUITests | EmptyCollectionCenteredBelowFixedHeaderAndAddWorks | Vacío centrado/textos correctos/acciones habilitadas; encabezado estable y ambas entradas abren foto. Fusiona dos duplicados. |
| IdentificationLayoutUITests | MaximumAlternativesLastSelectionAndSeparatedEqualActions | Tres alternativas exactas, última alcanzable/exclusiva/confirmable; geometría de acciones y separación, sin cambiar selección por scroll. |
| IdentificationLayoutUITests | GenericDestinationConsentShowsSnapshotAndRenewsAfterDestinationModelChange | Endpoint/modelo/operador desconocido visibles; cambiar destino/modelo vuelve a pedir aceptación, recordada después. |
| CareSheetUITests | CareSheetDirectAlternativeAndManualSave | Ambas vías crean y muestran sus seis campos propios; seleccionar no solicita cuidados. Se conserva por diferencia de procedencia/payload frente a altas de igual especie. |
| CareSheetUITests | CareSheetNetworkFailureAndExplicitRetry | Error remoto conserva identidad; retry humano y contador exacto; ficha completa posterior. |
| CareSheetUITests | CareSheetIncompleteResponseAndExplicitRetry | Respuesta incompleta no es éxito parcial; retry explícito completa ficha. |
| CareSheetUITests | CareSheetRenewedConsentCancellationAndRetry | Aviso de texto no reenvía foto; cancelación hace cero llamadas de cuidados; retry pide aceptación antes de enviar. |
| CareSheetUITests | CareSheetCancellationCloseAndStorageIsolation | Estado busy/cancelación, retry y cierre; reabrir vacío, plantas anteriores completas intactas. No se atribuye prueba UI de respuesta tardía: la cubren ViewModels deterministas. |
| CareSheetUITests | CareSheetThousandCharacterTextScrollsAndPersists | Campo de 1000 caracteres completo, desplazable y conservado tras relanzar; sin segunda alta/foto duplicadas. |
| SavePlantUITests | SavePlantAutomaticAIAndManualSameSpeciesRelaunch | Dos altas misma especie/fotos diferentes/UUID distintos, ubicación nil, seis cuidados por UUID después de relanzar. |
| SavePlantUITests | SavePlantLocalFailureRetryWithoutNewCareRequest | Error real de commit, editar/cancelar restaura error, retry local no solicita IA y persiste una sola alta. |
| SavePlantUITests | SavePlantCommitLocksDismissalAndHasNoReview | Commit observable impide cerrar; sin review/formulario; termina en colección y sigue allí al relanzar. |
| StoredCollectionUITests | StoredCollectionSurvivesProcessRelaunch | Disco verifica dos modelos/JPEG exactos; único recorrido canónico de ambos detalles completos tras relanzar. |
| EditPlantUITests | EditPersistsAndRefreshesOnlySelectedPlant | Editar nombre/ubicación refresca tarjeta/detalle/precarga solo propios; disco completo y segundo UUID intactos tras relanzar. |
| EditPlantUITests | CancelGestureValidationAndOptionalLocationWithMissingPhoto | Botón/gesto descartan; blanco no guarda; quitar/añadir ubicación funciona incluso con foto ausente. |
| PlantCardsUITests | PlantCardsSelectCorrectIdentity | A→B→A por regiones de foto/contenido y Atrás conserva navegación UUID; no vuelve a comprobar seis campos en cada salto. |
| PlantCardsUITests | PhotoFailureKeepsCardsAndNavigation | Retry de tarjeta no navega; detalle con foto fallida mantiene cuidados/retry; segunda foto carga normalmente. |
| PlantCardsUITests | LongCardTextRemainsReachable | Nombres/especies/ubicación largos y cuidados largos de ambas plantas íntegros/desplazables sin desbordamiento horizontal. |
| PlantCardsUITests | StorageFailureDoesNotShowEmptyCollection | Almacén corrupto muestra error, no vacío; Añadir/cerrar no oculta el fallo. |
| IdentificationPhotoUITests | IdentificationPhotoReplacementFailureCancellationAndEphemeralDraft | Cámara no disponible; progreso demorado opt-in, A/error/B, cancelación en carga, gesto con foto y descarte en mismo proceso/relaunch. |
| SystemGalleryUITests | RealGalleryPickerSelectReplaceCancelAndReselect | Única integración PhotosPicker real: elegir A, cancelar conserva A, elegir B y reseleccionar mismo asset reactiva Identificar. Serial/sembrado. |
| LocalizationUITests | EnglishPreferenceFallsBackToSpanishInsteadOfKeys | Preferencia en inglés resuelve vacío y detalle completo en español sin claves crudas. No duplica el caso español: detecta fallback de bundle. |

## Riesgos y siguiente comprobación (no ejecutada)

La validación anterior comprobó selectores/clones/limpieza/fixtures/gestos, pero falló en la representación del campo manual vacío y señaló la falta de propagación de capturas. La reparación acepta únicamente cadena vacía o el placeholder exacto de un TextField nativo, nunca texto residual ni nil; conserva la igualdad exacta después de escribir. TestAction deja de heredar el entorno de LaunchAction; el helper configura el valor literal de capturas en xctestrun. Comprobación focalizada de reparación registrada en PROGRESS; gate independiente con cinco workers pendiente. No tocar adaptadores de producción ni límites de Domain para reducir latencia.

Antes de aceptar: ejecutar **un** gate final sobre fuentes reparadas, comprobar descubrimiento de 125 unitarias + 37 UI en la fase paralela y 1 UI en la fase Fotos. Usar solo simulador estándar/texto normal/una apariencia. No hay presupuesto de tiempo garantizado. La prohibición original de ejecución fue levantada para la validación posterior; el gate fallido y sus hallazgos se conservan en `docs/validations/ui-test-performance.md`.

Los CSV e informes detallados de tiempos/orden/duplicados fueron solicitados **una sola vez**, como referencia orientativa. Se conservan sin regenerar en ejecuciones futuras. El gate no llama a los extractores de esa auditoría; solo produce resultados estándar xcresult y estado de salida. La reparación sigue registrando comando, selección, resultado y pendientes en PROGRESS, sin nuevas tablas/cronologías.
