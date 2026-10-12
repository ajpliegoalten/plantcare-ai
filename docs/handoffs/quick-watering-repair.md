# Quick-watering — reparación H1/H2

Estado posterior vigente: **H3 passing tras reparación3/3**, ver cierre al final de `docs/handoffs/quick-watering-h3.md`. H1/H2 y sus evidencias siguientes son históricos/reutilizados por rutas pertinentes; no accepted ni gate completo aprobado.

2026-10-12. **Passing tras autoverificación de reparación, no accepted**. Parent reanuda el mismo validator independiente. Leído íntegramente `docs/validations/quick-watering.md`, incluido Implementation Repair Brief. Gate original `DerivedData/TestResults/20261012-015906-97979/parallel.xcresult`/validator gate.log exit65 preservado:183Passed (141unit+42UI), assertion H1+error runner H2; Fotos serial no ejecutada. No se llama gate válido ni se sustituye mediante focalizadas.

## H1: diagnóstico y cambio mínimo

- Gate actividades: cinco deletes tras tap x=.95 dejan Potus. Export de attachments del gate no contiene screenshot/hierarchy del assertion H1; solo descripción de runner. No inventar esa evidencia ni afirmar posición exacta del cursor. Export diagnostics/actividades disponibles revisados.
- Primera ejecución obligatoria, **sin tocar tests/producto**, solo ManualSpeciesUITests/testManualUnconfirmedDraftDiscardedAfterErrorRecovery en UDID acordado, reutilizando build del validator contrastada con96 hashes (screenshots1 para diagnóstico): `manual-diagnostic.xcresult` Passed1/1 exit0, cero skips. Hipótesis cursor/foco consistente con fallo anterior pero **no reproducida ni causalidad exacta confirmada**. Captura de teclado tras reemplazo abierta; no defecto determinista demostrado de estado/persistencia del producto.
- Hallazgo acotado: helper borraba relativo a cursor asumido sin selección verificada; postcondición de limpieza incumplida en gate. Solo `typeManual` cambia a **selección nativa de todo el texto + un delete**, eliminando esa dependencia. Conservadas assertion de vacío/placeholder nativo, igualdad final EXACTA, todas las assertions de precarga/cancel/descarte/almacenamiento. No producto ni VM ni feature histórica modificados.
- Primera reparación `manual-repair.xcresult` FAILED0/1 exit65: selector Button no encontraba opción; hierarchy `repair-attachments/A458DFC2…txt` demuestra menu compacto MenuItem + Adelante. Corrección por paginación nativa; `manual-menu.xcresult` FAILED0/1 exit65: menú expandido cambia a Button (`menu-attachments/9F461F90…txt`, Seleccionar todo presente). Selector final admite tipos nativos mediante descendants, navegación acotada3 páginas, sin repetición automática ni fallback a borrar sin selección. Fallos preservados, cada nueva ejecución tiene cambio/hipótesis demostrado por hierarchy.
- `manual-final.xcresult` Passed1/1 exit0, cero skips,02:19:53–02:21:33+0200. Captura `final-attachments/24869BBA…png` realmente abierta: Potus completo seleccionado por asas nativas antes de borrar; vacío/texto final/descarte exactos pasan. `callers.xcresult` Passed6/6 exit0, cero skips,02:21:45–02:29:02+0200: cuatro restantes ManualSpecies +CareSheetDirectAlternativeAndManualSave +SavePlantAutomaticAIAndManualSameSpeciesRelaunch. Fallido ya cubierto excluido para evitar duplicar. Incluye blanco/trim/largo/precarga/cancelación/vuelta AI/almacenamiento/relaunch. **7 callers distintos autoverificados**, no suite completa.

## H2: launcher/destino independiente y límites

- Session logs exportados: Clone3 Edit Plant Recovery `F6019F77-5BD1-45AE-A850-094DAD2DF1A7` reclamado/booted; SpringBoard deniega runner antes de ejecutar tests por FBSOpenApplicationErrorDomain6 Busy/preflight,02:00:38. No demuestra causa H1 ni competidor externo; raíz interna más profunda no determinada por estos logs. Extracto46 líneas `launcher-diagnosis.txt` y objeto original conservados.
- Sin xcodebuild/xctest/init competidores antes de pruebas, sin resets/shutdown ajenos. Boot explícito `00BBB7EC-8DF7-400C-A08A-9D3C8818D886` y simctl bootstatus -b; ProMax ajeno intacto. Todos los nuevos comandos fijan ese destino. Entorno Xcode26.2/17C52/macOS26.5.1/iPhone17Pro iOS26.2/23C54 normal/claro, caffeinate.
- Launcher serial diagnóstico/reparación y **tres runners paralelos** de callers (5workers configurados) arrancaron sin errores de infraestructura. Corroboración focalizada, no garantía de gate5workers ni Fotos serial. Al cerrar rebooteado destino acordado: `devices-final.json` y algoritmo EXACTO de selección de init (sin ejecutar init) confirman que elige **00BBB7EC…**, no B52F… ni ProMax. Validator debe recontrastar boot/selección efectiva inmediatamente antes del gate.

## Comandos, fuentes, reuso y siguiente paso

Artefactos nuevos `DerivedData/evidence/quick-watering/repair-review/`, logs contienen command line exacta. Builds build.log/build-menu.log/build-final.log exit0, build-for-testing en DerivedData/quick-watering. Config privada no leída, clave ejemplo ignorada sin cambios.

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
 -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath DerivedData/quick-watering build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py DerivedData/quick-watering/Build/Products 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
 -parallel-testing-enabled NO \
 -only-testing:PlantCareAIUITests/ManualSpeciesUITests/testManualUnconfirmedDraftDiscardedAfterErrorRecovery \
 -resultBundlePath DerivedData/evidence/quick-watering/repair-review/manual-final.xcresult test-without-building
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py DerivedData/quick-watering/Build/Products 0)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
 -parallel-testing-enabled YES -parallel-testing-worker-count 5 -maximum-concurrent-test-simulator-destinations 5 \
 -only-testing:PlantCareAIUITests/ManualSpeciesUITests \
 -skip-testing:PlantCareAIUITests/ManualSpeciesUITests/testManualUnconfirmedDraftDiscardedAfterErrorRecovery \
 -only-testing:PlantCareAIUITests/CareSheetUITests/testCareSheetDirectAlternativeAndManualSave \
 -only-testing:PlantCareAIUITests/SavePlantUITests/testSavePlantAutomaticAIAndManualSameSpeciesRelaunch \
 -resultBundlePath DerivedData/evidence/quick-watering/repair-review/callers.xcresult test-without-building
```

- **Único input ejecutable final diferente** del ready96 inicial: `PlantCareAIUITests/PlantCareAIUITests.swift`. Xcode reformató automáticamente catálogo durante build; restaurado a SHA previo EXACTO, valores/localizaciones intactos. App/project/resources y Domain/Data/VM idénticos a revisión independiente/Release. No nueva Release ni unitarias de producto sin impacto; reuso auditoría Release corroborada por validator y54 focalizadas iniciales por rutas intactas. No afirmar mismo hash del test bundle inicial.
- Manifiesto nuevo96 `repair-source-hashes.json` SHA256 **e6dd9af7f3d514a9953e8da10b3fd81995a2a9ac61f82d2077ede77032477af7**. Spec permanece **cc23a2f0d9ab89e4b2dd4e1e7eb7707da5507a56f30f7eb94eb103e1608230e6**. Static plist/JSON/diff-check pasan. Capturas enfocadas solamente diagnóstico/selección; no matriz ni screenshots6caller.
- Estado reparación **passing**, no accepted. Tests cambiados invalidan evidencia del gate anterior (ya FAILED); **nuevo gate completo justificado del validator**, no repetición ciega sobre mismas fuentes. Debe ejecutar ambas fases y exigir Fotos serial Passed. Implementer no ejecutó init/gate ni reescribió informe REVISE. Parent reanuda misma sesión independiente. H2 raíz profunda no probada, estabilidad focal sí, límite explícito pendiente de gate. No bloqueos implementer, sin procesos propios activos al handoff, sin stage/commit/publicación/delegación.
