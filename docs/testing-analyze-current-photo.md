# Pruebas de analyze-current-photo

Spec aprobada byte-intacta `docs/specs/analyze-current-photo.md`, ADR013. Estado/evidencia de ronda en `docs/handoffs/analyze-current-photo.md` y PROGRESS. Ninguna API real autorizada/ejecutada; dobles y URLProtocol no acreditan calidad/compatibilidad remota.

Delta discard-analysis: spec aprobada `docs/specs/discard-analysis.md` intacta; handoff `docs/handoffs/discard-analysis.md`. AnalyzeCurrentPhotoUITests conserva negativos/consent/selección y sustituye expectativa futura por Descarta activa; inicial largo, pager adicional y ambas entradas timeline cierran por ese botón, insuficiencia relanza sin reseed. Nuevos tests de fallo local abandonado y definitivo inicial preservado al descartar adicional. `--discard-analysis-verify` junto a `--photo-analysis-verify` comprueba cero definitivos propios/ajenos; `--discard-preserve-initial` exige exactamente uno inicial con contenido literal esperado y ninguno adicional/ajeno. No altera lectores/escritores productivos. Integración VM+actor real compara todos los modelos/UUIDs/contenidos/JPEG antes/después/reopen, conserva definitivo de otra planta y bloquea su reanálisis. Keep busy además exige Descarta disabled; retry de Keep permanece como regresión.

## Selección por impacto

- Domain/contexto → pertenencia/aislamiento/corte anterior/presupuestos/errores → BuildPlantAnalysisContextTests, AnalyzePlantPhotoTests.
- Data/scope v5 → foto única/payload mínimo/salida estricta/auth/cancelación/renovación → OpenAICompatiblePlantPhotoAnalysisRepositoryTests; ExternalAIConsentTests, OpenAICompatibleSpeciesIdentificationRepositoryTests, OpenAICompatibleCareSheetGenerationRepositoryTests, IdentificationConsentViewModelTests como regresiones directamente afectadas.
- VM/lifecycle/intenciones → modal único/no provisional retenido/retry/tardíos → PlantPhotoAnalysisViewModelTests, PlantPhotoPagerViewModelTests, PlantTimelineViewModelTests. Factories/navegación compartidas justifican regresiones de caller/sheets/push/back/papelera, no suite total de implementer.
- UI → AnalyzeCurrentPhotoUITests: pager inicial/adicional; timeline inicial/adicional/no care; consent cancel/gesto/accept/recordado; espera cierres ×/Cancelar/gesto; resultado largo/insuficiencia; fallos/retry; Guardar útil y Descarta activa salvo commit; fresh reopen/relaunch y exactitud Plant/CareEvent/PlantPhoto/JPEG/definitivos de ambas plantas por lectura real aislada.

## Fixtures y selectores

Solo Debug Simulator y store/consent UUID válidos: `--storage-test-id UUID --consent-test-id UUID --storage-seed --timeline-fixture mixed --photo-analysis-fixture success|long|busy|failOnce|insufficient`. Proveedor sintético cuenta solicitudes/captura contexto en memoria sin logs, NO almacena análisis. `--photo-analysis-verify` tras relaunch sin reseed verifica todos los cuidados/metadata/JPEG adicionales esperados de mixed. `--storage-verify` compara ambos Plant/JPEG iniciales. Ningún argumento alcanza PlantStore ni preferencias estándar.

IDs: detailAnalyzePhoto-plantUUID, analyzeTimeline-initial-plantUUID, analyzeTimeline-additional-photoUUID; analysisForm/Photo/PhotoDate/Preparing/Busy/Error/Retry/Provisional/Accept/Discard/Cancel/Close. FutureActions retirado en discard-analysis. Contador/identidad synthetic solo Debug: analysisInvocationCount/analysisSelectedIdentity. UI solo observa/gesticula; no activa acciones deshabilitadas ni escribe modelo por atajo.

## Ejecución local

No duplicar tests activos. Config Debug solo copiar ejemplo público vacío SI falta; no leer/sobrescribir secreto existente. Un iPhone17Pro/iOS26.2 estándar, texto normal/una apariencia. Usar:

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -derivedDataPath "$PWD/DerivedData" CODE_SIGNING_ALLOWED=NO build-for-testing
RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 0)
caffeinate -dius xcodebuild -xctestrun "$RUN" \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/BuildPlantAnalysisContextTests \
  -only-testing:PlantCareAITests/AnalyzePlantPhotoTests \
  -only-testing:PlantCareAITests/PlantPhotoAnalysisViewModelTests \
  -only-testing:PlantCareAITests/OpenAICompatiblePlantPhotoAnalysisRepositoryTests \
  -only-testing:PlantCareAIUITests/AnalyzeCurrentPhotoUITests test-without-building
```

Comandos ejecutados exactos/resultados/fallos conservados en handoff/evidencia, este bloque es receta, no claim de ejecución. Capturas1 solo escenarios/pantallas afectados, helper existente; revisar PNG realmente abiertos. Gate único completo `caffeinate -dius ./init.sh` corresponde a validator independiente; confirmar su algoritmo selecciona destino acordado antes. No SE/DynamicType aumentado/VoiceOver/matriz de apariencias habitual. Localización española/fallback y soporte accesible conservados.

Smoke humano sin envío real: lanzar fixture con UUIDs nuevos, abrir tarjeta→Analizar foto→aceptar aviso sintético→leer tres secciones→Descartar análisis→reabrir; pasar a adicional y repetir desde historial. Guardar sigue útil y Descarta también en insuficiencia; ambos bloqueados durante commit. En uso normal sin config aparece indisponible honesto. Usar proveedor real solo con autorización específica, foto/config del usuario y después del aviso v5; no es requisito para que fixtures prueben barrera local ni evidencia remota ya disponible.
