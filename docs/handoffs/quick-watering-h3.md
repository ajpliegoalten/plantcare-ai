# Quick-watering — H3 bloqueado tras diagnóstico/reparación

**Estado vigente tras continuación autorizada (2026-10-12,10:08+0200): H3 reparado y autoverificado, passing, no accepted.** Ver «Cierre H3 por selección nativa de párrafo» al final. El bloqueo y los resultados FAILED siguientes son históricos preservados; no significan estado actual ni se convierten en verdes.

2026-10-12,03:25+0200. **Estado vigente: blocked, no passing ni accepted.** H3 no resuelto; no ejecutar otro gate para intentar convertir este estado en verde. Parent debe continuar reparación del input UI antes de volver al mismo validator. Producto/riego/schema/spec no modificados por esta ronda.

## Bloqueo concreto

No se ha conseguido una interacción nativa de selección completa fiable para `replace` en el editor estándar. La última autoverificación **focus.xcresult FAILED0/3 exit65**, cero skips: escenario largo y ambos EditPlant UI conservan el nombre entero tras selección solicitada+delete. Todas las assertions originales de vacío/exactitud/precarga/descarte/persistencia siguen intactas. No ocultar con retries, borrado relativo al cursor ni weakening.

Evidencia definitiva `focus.log`: input de espacio temporal recibe el carácter (assert count+1 pasa), comando nativo ⌘A registrado, delete conserva Fixture1/nombre largo. Captura `focus-attachments/FB7431AE…png`, realmente abierta, muestra caret al inicio, **sin selección completa**. Esto descarta que bastase demostrar foco mediante un carácter; no acredita defecto del producto de riego ni persistencia. Advertencia Invalid frame dimension histórica no tiene relación causal probada con esta selección.

## Diagnóstico inicial y experimentos conservados

Brief H3/informe actualizados leídos. Ambos gates del validator permanecen FAILED, Fotos serial ausente; H1 pasó y H2 no reapareció en segundo gate. Cero full gates/init o Release por implementer en esta ronda.

Artefactos `DerivedData/evidence/quick-watering/repair-h3/`:

| Bundle | Resultado | Hipótesis/cambio |
| --- | --- | --- |
| diagnostic | Passed1/1 | Primero solo largo sin cambios sobre build validator/hashes96 contrastados. Cursor exacto no reproducido ni confirmado. |
| editor | FAILED2/3 | Extraer selección menú H1 compartida y reemplazar borrado relativo; largo/editPersist pasan, cancel falla: vídeo failure-48.png demuestra palabra seleccionada+sugerencias de corrección, no menú SelectAll. |
| cancel | FAILED0/1 | Longpress trailing area: vídeo cancel-menu.png demuestra caret sin menú; hipótesis descartada. |
| doubletap | FAILED0/1 | Native doubletap: menú de rango parcial Cortar/Copiar, sin Seleccionar todo; jerarquía confirma. |
| key | FAILED0/1 | Build nativo typeKey compila, pero actividades aún muestran doubletap/selector anterior. **No atribuir este run al comando nuevo**; mismatch de código ejecutado reconocido. |
| key-launch | Passed1/1 | Diagnóstico de posible runner anterior: contrastados hashes installed/build iguales; terminate propio runner informó nada que terminar (causa interna no confirmada). Nueva sesión sí acredita typeKey ⌘A; captura selección completa abierta. No borrar key anterior ni llamarlo Passed. |
| callers-final | FAILED7/9 | Cambia selección a comando teclado compartido; largo/editPersist+5callers pasan, dos ManualUnconfirmed fallan con Potus. Log también registra launch-failed/FBProcessExit64 independiente, aunque summary enumera solo9 escenarios funcionales. No aggregate aprobado. |
| manual-final | Passed7/7 | Restituida interacción menú H1 para manual, teclado solo editor.5Manual+CareSheetDirect+SavePlantAutomatic en serie; cero skips. |
| editor-final | FAILED1/3 | Verificar código final compartido/editor: cancel pasa, largo/editPersist conservan nombre entero tras comando. No reutilizar sus verdes anteriores como aprobación final. |
| focus | FAILED0/3 | Nueva hipótesis foco confirmado por espacio temporal/count+1 antes de comando; tres vacío assertions fallan. Hipótesis no resuelve bloqueo. |

Todas las ejecuciones son únicas por reparación/diagnóstico explícito; sin retries/iteraciones automáticas. Los fallos nunca cuentan como aprobados. No seguir probando permutaciones sin nueva hipótesis sustentada por evidencia.

## Fuente actual y alcance

- Único input ejecutable diferente frente manifiesto H1/H2: `PlantCareAIUITests/PlantCareAIUITests.swift`. Extraído `selectAllAndDelete`: manual usa menú original H1/paginación/selector multitype; editor usa comando nativo de teclado y handshake de espacio temporal con assertion count+1, seguido de delete y assertions originales vacío/final. **Este branch editor es candidato fallido, no listo para entregar.** No mutación directa del estado app ni código producto compensatorio.
- Los7 manual callers verdes se reutilizan tras último cambio solo del branch editor (rama manual inalterada). Producto/Release54 iniciales y auditoría independiente reutilizables por inputs pertinentes intactos, no autorización de H3 ni gate. Catálogo hash original exacto, spec intacta.
- `blocked-source-hashes.json`96 inputs SHA256 **e6a5f4a8af2f2932a92ebcbfcc5519576022ac38b55d8810976b960cf3a507ca**, fuente correspondiente a focus fallido. Spec SHA256 **cc23a2f0d9ab89e4b2dd4e1e7eb7707da5507a56f30f7eb94eb103e1608230e6**. Builds de candidatos build/build-menu/build-doubletap/build-key/build-final/build-focus exit0. Static plist/JSON/diff-check pasa; no false passing.

## Entorno y comandos

Xcode26.2/17C52/macOS26.5.1/iPhone17Pro iOS26.2/23C54, UDID00BBB7EC-8DF7-400C-A08A-9D3C8818D886 normal/claro/caffeinate. Ausencia de procesos competidores contrastada, sesiones secuenciales, sin resets/shutdown ajenos/matrices. Instalación fresca **solo runner UITests propio** en UDID acordado para descartar código residente, no borrado de producto/store. ProMax ajeno intacto. Problema launcher paralelo anotado separadamente, serial no reporta errores infraestructura.

Comandos EXACTOS en cabecera de cada log. Prefijos ejecutados:

```sh
xcrun simctl boot 00BBB7EC-8DF7-400C-A08A-9D3C8818D886
xcrun simctl bootstatus 00BBB7EC-8DF7-400C-A08A-9D3C8818D886 -b
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
 -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
 -derivedDataPath DerivedData/quick-watering build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py DerivedData/quick-watering/Build/Products 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" \
 -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
 -parallel-testing-enabled NO \
 -only-testing:PlantCareAIUITests/QuickWateringUITests/testLongNamesMultilineNoteKeyboardScrollAndHomogeneousEditor \
 -only-testing:PlantCareAIUITests/EditPlantUITests \
 -resultBundlePath DerivedData/evidence/quick-watering/repair-h3/focus.xcresult test-without-building
```

Manual-final: screenshots0,NO; ManualSpeciesUITests+CareSheetDirectAlternativeAndManualSave+SavePlantAutomaticAIAndManualSameSpeciesRelaunch. Callers-final: screenshots0,YES/5workers/maximum5; anteriores+long+EditPersist. Serial final screenshots1 enfocados selección/layout; vídeos exportados de fallo usados para diagnóstico, no nuevas matrices.

## Siguiente paso y límites

Reparar únicamente selección del helper editor con mecanismo nativo verificable sin depender de cursor asumido ni comando ignorado; exigir campo vacío y texto final exacto, recorrer largo+ambos editor, y manual callers solo si su rama cambia. Las capturas y logs finales muestran entrada real pero ausencia de selección completa, útil para diagnóstico de automatización/input. No atribuir foco o warning como raíz definitiva sin prueba. Tras reparación efectiva, passing y nuevo gate del validator justificado por cambios tests, ambas fases incluido Fotos serial. **En este estado no corresponde gate ni accepted.** No procesos propios activos al handoff, sin delegación/staging/commits/publicación/config privada/API real.

## Cierre H3 por selección nativa de párrafo

Autorización actual recibida para continuar reparación/focales; parent mantiene validator independiente y commit local solo tras accept. No otra feature/spec/publicación. Recontrastados96 inputs del blocked-source-hashes inicial y ausencia de xcodebuild/xctest/init competidores antes de continuar.

### Hipótesis sustentadas y resultados nuevos

1. Capturas anteriores separan selección de palabra/correcciones, caret sin selección y ⌘A ignorado. Se intentó abrir menú de inserción con tap en margen inicial+segundo tap, exigiendo SelectAll nativo. Build exit0; `repair-h3-insertion/editor.xcresult` **FAILED1Passed+2Failed exit65**, cero skips. Jerarquías muestran menú de selección Cortar/Copiar sin SelectAll en un caller; largo tampoco ofrece la acción requerida. Se conserva ese fallo; no repetir misma permutación ni interpretar InsertMenu como solución.
2. Investigación documental: Apple iPhone User Guide, [Select, edit, and move text](https://support.apple.com/guide/iphone/select-edit-and-move-text-iph1a9cae52c/ios), documenta **triple-tap para seleccionar párrafo** (distinto de doble-tap palabra). Se usa API pública XCUIElement `tap(withNumberOfTaps: 3, numberOfTouches: 1)`, no seam de producto ni mutación directa de estado. La documentación orienta el gesto; los resultados nuevos demuestran su uso concreto en iOS26.2, no promesa basada solo en versión de la página.
3. Rama editor de `selectAllAndDelete` cambia únicamente a triple-tap nativo, espera acción Copiar/Copy como señal de rango seleccionado, captura opt-in y un delete. **Siguen** assertions exactas de campo vacío/después valor final y todos los checks de caso/cabecera/scroll/cancel/nota/payload7/relaunch. Quitados por completo comando ⌘A y espacio temporal del candidato fallido. No cursor final supuesto, no loops de borrado/fallback/retries. Rama manual menú H1/paginación/selector multitype INTACTA (el parser vuelve a su rama original), solo se reutiliza el helper común existente. Ningún cambio de producto/VM/Domain/Data/schema/localización/harness init.

### Autoverificación final realmente ejecutada

- `DerivedData/evidence/quick-watering/repair-h3-paragraph/build.log`/build.exit: **TEST BUILD SUCCEEDED exit0**.
- `repair-h3-paragraph/editor.xcresult`/editor.log/editor.exit: **TEST EXECUTE SUCCEEDED exit0,3/3**, cero failures/skips/expected failures,10:05:21–10:08:48+0200. Escenarios: QuickWateringUITests/testLongNamesMultilineNoteKeyboardScrollAndHomogeneousEditor; EditPlantUITests/testCancelGestureValidationAndOptionalLocationWithMissingPhoto; EditPlantUITests/testEditPersistsAndRefreshesOnlySelectedPlant. Una ejecución final de esos tres, no iteraciones/retries.
- Selección estándar en serie NO para no introducir runner-parallel diagnóstico en estos tres funcionales; caffeinate, iPhone17Pro iOS26.2/23C54 UDID00BBB7EC-8DF7-400C-A08A-9D3C8818D886, normal/claro, Xcode26.2/17C52/macOS26.5.1. Boot/bootstatus explícitos; instalación fresca solo runnerUITests propio para evitar mismatch de código observado anteriormente, ningún reset/product store/ajeno. Capturas1 solo escenarios afectados.
- Capturas finales realmente abiertas: `attachments/CCE6B0B4…png` muestra TODO el nombre largo envuelto en dos líneas con asas inicio/fin; `1CF00CA4…png` todo Fixture1; `3296EE15…png` toda Ventana. La assertion de vacío después de un solo delete verifica que no fue selección parcial; también pasa blanca→vacía/ubicación nil, texto largo nuevo/final exacto y nota multilinea/riego real/relaunch.
- Limitación honesta del helper de tests: gesto selecciona un párrafo; los valores previos de los fixtures editor son un párrafo, incluso cuando visualmente ocupan múltiples líneas. La assertion de vacío **falla cerrada** si un valor futuro con varios párrafos quedase parcialmente seleccionado. No se cambia ni limita el soporte de nombres/notas arbitrarios del producto. No generalizar el helper a futuros fixtures multipárrafo sin interacción/cobertura apropiada.
- Reuso: manual-final7/7 previo por rama manual byte-equivalente y rutas pertinentes inalteradas (no repetirla por rutina); otras focalizadas54/Release auditoría independiente por inputs producto/resources idénticos. Los anteriores FAILED editor/focus y ambos gates validator siguen FAILED, no reemplazados por aggregate de reuso.

Comandos ejecutados (líneas exactas también en logs):

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
 -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath DerivedData/quick-watering build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py DerivedData/quick-watering/Build/Products 1)
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
 -parallel-testing-enabled NO \
 -only-testing:PlantCareAIUITests/QuickWateringUITests/testLongNamesMultilineNoteKeyboardScrollAndHomogeneousEditor \
 -only-testing:PlantCareAIUITests/EditPlantUITests \
 -resultBundlePath DerivedData/evidence/quick-watering/repair-h3-paragraph/editor.xcresult test-without-building
```

### Fuentes finales y entrega

96 inputs `repair-h3-paragraph/ready-source-hashes.json` SHA256 **f2f9da0a7c01524754048b81c152b670719d442335bdb62f09e6a2e2055a15a5**. Único input ejecutable distinto del estado anterior96: PlantCareAIUITests/PlantCareAIUITests.swift. Spec intacta **cc23a2f0d9ab89e4b2dd4e1e7eb7707da5507a56f30f7eb94eb103e1608230e6**. Static plist/JSON/diff-check y drift check finales pasan; ningún proceso propio de tests activo al cierre. `feature_list.json` passing con evidencia y PROGRESS actualizados.

Sin bloqueos implementer actuales. Parent reanuda **mismo validator independiente**, que decide/ejecuta nuevo gate completo justificado por cambio relevante de UI tests, ambas fases (Fotos serial debe pasar). No init/full gate/Release rutinario por implementer ni pruebas duplicadas de gate; estado passing no accepted. Sin delegación/stage/commit/push/PR/GitHub/merge. El error de launcher paralelo histórico no tiene raíz interna probada ni se garantiza eliminado mediante estos tres seriales; gate completo es precisamente el cierre pendiente.
