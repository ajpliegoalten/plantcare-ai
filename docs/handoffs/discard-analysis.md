# discard-analysis — handoff implementer

## Contrato y fuentes

- Usuario aprobó integralmente la spec actual; texto histórico de borrador no invalida esa autorización. `docs/specs/discard-analysis.md` preservada byte-intacta, SHA256 `b2770e7ae77191aa9a856fe7f01ff1f84131e6e92f5e0e64812465d908c49362`.
- Rama `feature/discard-analysis`, base `079a0f735f56e4a2b44dc8ce39ace05a405a8c9e`; única feature. Sin stage/commit/push/PR/merge.
- Presentation: `canDiscard`/`discard()` guardan resultado presente, sesión abierta, estados útil/insuficiente y no saving/saved; delegan en limpieza única `close()`. Vista conserva cápsula neutral52 y dismiss autorizado, sin alerta/toast/ayuda futura. Error local conserva disponibilidad; commit reconocido por Keep, jamás delete compensatorio.
- Domain, Data productiva, schema, transporte, consentimiento, caches/callers y composición productiva intactos. Ruta Descarta termina en Presentation; no use case/adapter ficticio. Composición solo conecta dos expectativas opt-in del verifier Debug sobre actor real.
- Recursos: retirada exclusiva `keepAnalysis.discardFuture`; todas las restantes traducciones exactas a HEAD, sin extracción automática Xcode.

## Cambios → riesgos → selección

| Archivos/callers | Riesgo | Comprobación seleccionada |
|---|---|---|
| Analysis View/VM | persistencia por descarte, callback, retry abandonado, doble/obsoleto, busy/saved | PlantPhotoAnalysisViewModelTests completa; 3 tests nuevos, guards extendidos y regresiones cierre/consent/tardíos/commit |
| Spy de proveedor compartido | cambiar respuesta default de otros callers | AnalyzePlantPhotoTests completa; default conserva contenido previo |
| VM + actor/disco real | borrar origen/definitivo propio o ajeno, nuevo JPEG/cuidado/texto | LocalPlantPhotoAnalysisRepositoryTests completa; nueva integración compara snapshots semánticos Plant/ficha/cuidados/fotos/definitivos/JPEG antes/después/reopen inicial+adicional, protege definitivo ajeno/lector |
| UI/result helper/Debug verifier | botón inactivo, caller/selección, scroll largo, relaunch falso, insuficiencia, error local | AnalyzeCurrentPhotoUITests completa (8); Keep local-retry y busy (2) como regresiones directas |
| Composición/seam Debug | expectativa de disco no real o inclusión Release | build Debug; auditoría Release de nuevos flags/verifier/puente |

No baseline completo ni gate `init.sh` del implementer. Gates accepted anteriores son históricos, no evidencia de estas fuentes. Config solo copia de example vacío si ausente y check-ignore; nunca leer valores/overwrite/API real. Único destino iPhone17Pro iOS26.2/23C54 `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, Xcode26.2/17C52 macOS26.5.1/25F80; UI/unit seriales sin procesos de test competidores. Ningún otro simulador modificado; tamaños ampliados/SE/VoiceOver/matrices fuera habitual, no ejecutados ni bloqueantes.

## Comandos realmente ejecutados

Desde raíz del worktree, artefactos ignorados `DerivedData/evidence/discard-analysis/`:

```sh
printf 'SWIFT_EMIT_LOC_STRINGS = NO\n' > DerivedData/evidence/discard-analysis/NoLocalizationExtraction.xcconfig
XCODE_XCCONFIG_FILE="$PWD/DerivedData/evidence/discard-analysis/NoLocalizationExtraction.xcconfig" caffeinate -dius xcodebuild \
  -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -derivedDataPath "$PWD/DerivedData" CODE_SIGNING_ALLOWED=NO build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' -parallel-testing-enabled NO \
  -resultBundlePath DerivedData/evidence/discard-analysis/unit.xcresult \
  -only-testing:PlantCareAITests/PlantPhotoAnalysisViewModelTests \
  -only-testing:PlantCareAITests/LocalPlantPhotoAnalysisRepositoryTests \
  -only-testing:PlantCareAITests/AnalyzePlantPhotoTests test-without-building
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' -parallel-testing-enabled NO \
  -resultBundlePath DerivedData/evidence/discard-analysis/ui.xcresult \
  -only-testing:PlantCareAIUITests/AnalyzeCurrentPhotoUITests \
  -only-testing:PlantCareAIUITests/KeepAnalysisUITests/testLocalFailureRetryNoRemoteRequestAndCloseAbandonsUncommittedResult \
  -only-testing:PlantCareAIUITests/KeepAnalysisUITests/testBusyBlocksDoubleSaveCancelCloseAndGestureUntilDurableCommit test-without-building
XCODE_XCCONFIG_FILE="$PWD/DerivedData/evidence/discard-analysis/NoLocalizationExtraction.xcconfig" caffeinate -dius xcodebuild \
  -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/DerivedData" CODE_SIGNING_ALLOWED=NO build
```

Stdout/stderr y exit en `build.{log,exit}`, `unit.{log,exit}`, `ui.{log,exit}`; ruta exacta de productos en `xctestrun-path.txt`. Static `git diff --check`, `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON catálogo y comparación de traducciones previas: pasan. Inputs públicos finales capturados (sin config privada): `inputs-final.json`, 161 archivos, SHA256 `2de9b6a073fe7f5cff23066222834d2c7449a79b9258af3cfb88835813bc8d83` (manifiesto final, no baseline inventada).

## Resultados y siguiente paso

- Build Debug exit0, TEST BUILD SUCCEEDED.
- Unit/integración exit0: **32/32 Passed**, cero failures/skips/expectedFailures (`unit-summary.json`, `unit.xcresult`). Todas pruebas nuevas en esta sesión, ninguna aceptación histórica reutilizada.
- Release exit0, BUILD SUCCEEDED (`release.{log,exit}`); audit `nm` + `strings` excluye `--discard-analysis-verify`, `--discard-preserve-initial`, `PlantPhotoAnalysisFixtureVerify`, y `plistlib` verifica ausencia de keys API/IDENTIFICATION en Info. Solo build simultáneo con UI, nunca otro proceso de tests/simulador.
- Static final confirma los 161 inputs relevantes exactos tras builds/UI y todas las entradas ajenas de feature_list exactas. Contraste sRGB de Descarta TextSecondary/SurfaceMuted: **8,473:1**, tokens reales auditados y control activo corroborado visualmente.
- **La misma ejecución UI original terminó exit0, 10/10 Passed**, cero failures/skips/expectedFailures (`ui-summary.json`, `ui.xcresult`). Se esperó al wrapper original con evento Darwin kqueue NOTE_EXIT, sin nuevo xcodebuild ni rerun/retries. Notificación de shell `sh_135ab41e00019SIOxWsfbqYcGN` corroborada; no tests pendientes/competidores al cierre. Apariencia light consultada tras terminar, texto normal sin matrices/settings cambiados.
- **42 IDs finales distintos Passed =32 unit/integración +10 UI**, 6 tests nuevos (3 VM, 1 integración, 2 UI) y 36 existentes/actualizados. Corroboración IDporID `selected-final-results.json`, comandos/exit/log/bundle `commands.json`. Ningún fallo ni reparación ejecutable en esta ronda; no sumar repeticiones, no usar aceptación anterior como baseline nueva.
- Se exportaron46PNG y se abrieron realmente5 en `attachments/`: `159D4175-4E21-4C6B-BA31-D58FE0FCEC2A.png` útil/CTA activa; `6768B31B-3669-4B0F-9E45-D2AAC094DCFA.png` insuficiente/Descarta activa; `4AEC1635-A2F5-479C-B2FB-481F7A0D7705.png` busy/Descarta disabled; `28F62F3A-470D-4BED-B80B-4713D85EF908.png` error local/retry (Descarta parcialmente recortada en esa captura; cierre funcional probado, no claim de control completo visible); `C40A02F6-D15A-4592-8160-F062A185B20B.png` definitivo inicial bajo su foto preservado. Modal/acciones/tipografía existentes sin rediseño, ayuda futura ausente; control neutral activo legible y disabled atenuado. No inspección afirmada de las otras41PNG.
- Estado **passing focal**, listo para validator; NO accepted ni suite completa. Spec/161inputs públicos intactos al cierre; solo docs/harness actualizados después de tests, sin invalidar producto/test/config relevante.
- Validator independiente debe revisar diff/spec/evidencia y ejecutar único gate final completo `caffeinate -dius ./init.sh` ambas fases sobre fuentes finales (puede usar override SWIFT_EMIT_LOC_STRINGS=NO). No repetir focales cubiertas por gate ni atribuir gate de Keep a Descarta. Implementer no declara accepted.
- «Sin huella» no revoca envío/consentimiento externo ni significa borrado seguro. Calidad IA real no acreditada por fixtures. No hay función adyacente implementada ni bloqueo nuevo que añadir a CONSTRAINTS.
