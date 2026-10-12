# Pruebas de plant-timeline

## Selección por impacto

- Domain/proyección y persistencia: LoadPlantTimelineTests (cinco kinds, prealta, identidades cruzadas, aislamiento, todos los errores de fuente, modelos/JPEG/reopen reales y contador de commit).
- Contexto/orden: PlantTimelineDateFormatterTests y PlantTimelineViewModelTests (día visible, inversión occurredAt-createdAt, clave discriminada, zona une/separa/invierte, DST/Ayer, reloj retrocedido, pie derivado, loading/failed/notFound/reentry/pending/tardíos).
- Imágenes: PlantTimelinePhotoViewModelTests (demanda/dedup, dos in-flight incluso IO cancelado drenando, cache≤3/evicción sin hot-loop, error/retry propio, foreign UUID, decode real≤1600/corrupto, owners de reparenting mantienen una sola lectura al cambiar grupo). Delta scroll: viewport geométrico por identidad, expulsión de ocultas antes de visibles, retorno de filas montadas sin onAppear, máximo3demandas/dos in-flight y cancelación drenando al invertir dirección. Publicaciones coalescidas fuera de layout/snapshot y demanda idempotente con conjunto visible igual: test cuenta objectWillChange para impedir republicaciones loading y comprueba cancelación de reconciliación al salir.
- Callers: PlantPhotoPagerViewModelTests, PlantDetailViewModelTests y PlantListViewModelTests por suspensión/abandono/composición del path. UI persistente PlantTimelineUITests y métodos directamente afectados de AddPlantPhoto/CareEvents/StoredCollection/PlantCards/EditPlant/Localization.
- Fotos reales/harness intactos: no picker focal nuevo; validator conserva su fase serial en único init.sh final. No migración redundante porque Data/schema intactos.

## Fixtures y selectores

`--storage-test-id UUID --storage-seed --timeline-fixture mixed|photosOnly` envuelve StorageFixtureLoad y siembra con APIs del mismo actor real. Solo Debug Simulator/UUID aislado; sin sidecar, red ni reseed al consultar historial. Primera planta: cinco cuidados (nota larga en poda), adicional y cuidado prealta; segunda sentinel SOLO PLANTA B. `--timeline-read-error` falla una vez tras lectura real para distinguir error de vacío; `--additional-photo-read-fixture imageErrorOnce` existente falla solo imagen adicional. Relanzar sin --storage-seed conserva datos.

IDs: detailHistory-UUID, plantTimeline-UUID, timelineDay-yyyy-MM-dd; timelineEntry-/timelinePhoto-/timelinePhotoError-/retryTimelinePhoto-<care|additional|initial>-UUID; timelineError/retryTimeline/timelineNoRecords/timelineOriginFooter. Solo cabeceras contienen fechas de elementos; notas libres del usuario no se restringen.

`--timeline-fixture scrollPhotos` siembra ocho adicionales con JPEG reales alternos y UUID distintos, sin cuidados; primera planta solamente. `testEightPhotosScrollBothDirectionsReloadsActualImagesWithoutLeavingHistory` recorre8fotos y la inicial, vuelve por las8, invierte scroll y comprueba aislamiento. Cada foto exige valor accesible «Foto cargada», no mera existencia del contenedor/placeholder; dos capturas focalizadas de extremo inferior/regreso superior. Evidencia reparación en docs/handoffs/plant-timeline-scroll-fix.md; no confundir gate254/254 histórico con aceptación de fuentes corregidas.

`testMetadataRefreshReloadsLastViewportWithoutNewGeometryAndRealExitClearsIt` exige nuevas lecturas de fotos visibles tras refresh aunque no haya callback de geometría/appearance, sin cache vieja, sin UUID ajeno y sin retener visibilidad al abandonar realmente. TimelineVM/Load seam y UI globalRetry/commit-reentry cubren sus callers; no repetir todo el gate en implementer.

## Comandos

Usar destino estándar acordado `00BBB7EC-8DF7-400C-A08A-9D3C8818D886` iPhone17Pro/iOS26.2 normal/light si disponible, coordinar sin tests competidores y preparar example público vacío solo si config ausente. Build-for-testing seguido de helper capturas1 focalizado y test-without-building con cinco workers, según docs/testing-ui.md; no init completo implementer.

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
  -destination "platform=iOS Simulator,id=$UDID" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/LoadPlantTimelineTests \
  -only-testing:PlantCareAITests/PlantTimelineDateFormatterTests \
  -only-testing:PlantCareAITests/PlantTimelineViewModelTests \
  -only-testing:PlantCareAITests/PlantTimelinePhotoViewModelTests \
  -only-testing:PlantCareAIUITests/PlantTimelineUITests test-without-building
```

Comandos/resultados reales, fallos y fuentes están en docs/handoffs/plant-timeline.md/PROGRESS; este ejemplo no afirma ejecución. Capturas básicas focalizadas box/mixto/nota/alta-prealta/error; no SE/texto aumentado/VoiceOver/matrices extra salvo petición. Gate estándar independiente pertenece al validator.
