# Handoff — manual-species-inline

## Reparación V1 — estado actual, passing (2026-10-11)

Validator devolvió **revise**, informe `docs/validations/manual-species-inline.md`.
Gate fallido **122/124 = 96 unit + 26 UI, exit 65** sigue intacto/FAILED; aceptación
histórica no acepta esta ronda. Solo producto modificado desde ese gate: retirar
`en: Cancel editing` de `manualSpecies.cancelEdit`, conservando español «Cancelar
edición». **Swift, reglas, tests y assertions intactos**. No traducción global.

Riesgo/hypótesis: locale inglés parcial de una clave impide fallback completo a es.
Public sandbox existente sincroniza solo catálogo; build público en **DerivedDataRepair
fresco**, sin borrar builds/directorios amplios ni leer/copiar config real. Config
sintética sandbox contrastada con plantilla pública vacía. Mismo iPhone normal/light,
serial, sin procesos activos al inicio/fin; espera del comando foreground original,
sin timeout/polling/sleeps/duplicados/retries. No full gate por implementer.

Comando exacto desde `DerivedData/manual-inline-sandbox`:

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination 'platform=iOS Simulator,id=B52F5194-6A81-4FAA-B094-B0D248084877' \
  -derivedDataPath "$PWD/DerivedDataRepair" \
  -resultBundlePath '../evidence/manual-inline-v1-repair/focused.xcresult' \
  -parallel-testing-enabled NO \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests/testExternalConsentUnavailableAndBothPlantsUnchanged \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesWithoutAIAndCancelEdit test \
  > ../evidence/manual-inline-v1-repair/focused.log 2>&1
```

**TEST SUCCEEDED exit 0, 3/3 UI, 0 fallos/omitidas**. Fresh compile dentro del test.
Evidencia actual en `DerivedData/evidence/manual-inline-v1-repair/`:
- focused.log/.exit/.xcresult, focused-summary.json, attachments/manifest.json.
- scope-check.json: única diferencia producto = catálogo/solo en retirado, fresh path.
- source-manifest-before.json/after.json y delivery-source-manifest.json:
  **86 hashes iguales raíz/sandbox antes/después**; manifiestos previos conservados,
  ya no son los hashes del catálogo reparado. Usar manifiesto V1 para fuentes actuales.
- bundle-localization.json: bundle público fresco **solo es.lproj**, 108 claves,
  CFBundleDevelopmentRegion es y Cancelar edición exacto; sin en.lproj parcial/residual.
- Capturas inspeccionadas de fallback/detalle (AF721BD4...), indisponibilidad
  (B3E79CFC...) y manual/cancelar (B86DF889...): español sin keys y control inline.
  Interacción XCUITest; aislamiento/cancelación verificados con assertions intactas.

Gate final nuevo queda al validator: usar producto público limpio (nuevo derivedData
o DerivedDataRepair) y una única ejecución final de init; no reutilizar gate fallido
ni el directorio antiguo con en.lproj como prueba de reparación. Init público no cambia.
No accepted/commit/GitHub/otra feature. Secciones siguientes son evidencia anterior
de esta misma ronda, preservada; V1/manifiesto actual prevalecen para el catálogo.

## Contrato / estado
Implementer, ronda explícitamente autorizada sobre accepted `3cdbc15` en el único
worktree `manual-species`, rama `feature/manual-species`. **passing**, autoverificación
por impacto cerrada; sin aceptación independiente nueva. Spec histórica y
todos los informes/evidencia anteriores intactos; delta en
`docs/specs/manual-species-inline.md`.

Manual es opción humana siempre disponible con foto en «Otras posibilidades», mismo
check/badge/borde que IA. Selección exclusiva en VM, campo inline sin sheet nueva,
único Confirmar especie al resumen ya existente. EditPlant intacto. Editar/seleccionar
no borra identidad anterior; Cancelar edición explícito sustituye cancelación del
editor modal y restaura estado anterior, también tras pasar a candidata. Volver
expresamente a IA desde resumen sigue borrando confirmación/exigiendo reconfirmar.
Domain/source/caso puro/trim, Data, App, transporte/config/init no cambian.

## Fuentes y seguridad
- Presentation: IdentificationPhotoViewModel/View, IdentificationResultView,
  ManualSpeciesView; catálogo, ManualSpeciesViewModelTests y UI tests adaptadas.
- Sin IO/alta/cuidados/consentimiento/consulta nueva. Nombre humano no certifica
  botánica ni infiere común/científico; sin límite/autocomplete.
- Config real existente no leído/copied/modificado. Build/tests en
  `DerivedData/manual-inline-sandbox` con copia de fuentes públicas/proyecto/shared
  scheme y plantilla pública vacía como config. Manifiestos en
  `DerivedData/evidence/manual-inline/`; no publicar productos/xcresults.
- No stage/commit/push/PR/merge/GitHub. No otra feature ni edición de informes viejos.

## Impacto / evidencia
VM/guards y callers → seis clases unitarias relacionadas; selector/campo/CTA y
composición compartida → cuatro UI manuales y dos regresiones directas IA. Nueva
unit verifica común CTA/exclusión/largos/cancelación tras pasar a candidata.
Selección y comandos exactos registrados en PROGRESS; logs/xcresults/summaries y
manifiestos bajo `DerivedData/evidence/manual-inline`.

- Unit inicial `unit.log/.xcresult/-summary.json`: 33/33, cero fallos/omitidas.
- `ui-first.log/.xcresult/-summary.json`: exit 65, 6/7 pasan (nueva unit + 5 UI).
  Error/insuficiencia falla en dos expectativas antiguas de ausencia de CTA.
  Reparación: presencia + disabled + manual disponible, conserva no confirmación
  y añade confirmación/vuelta manual sin alternativas.
- `ui-repair.log/.xcresult/-summary.json`: exit 0, 3/3 (caso fallido, espera, máximo).
  Inspección posterior detecta aviso IA tras manual/incluso sin propuestas: producto
  agrupa incertidumbre/aviso antes de opciones humanas y omite aviso en insuficiencia.
  Assertions de orden y ausencia del aviso añadidas.
- `ui-visual-final.log/.xcresult/-summary.json`: exit 65, 4/5. Dos manuales con
  resultados, alternativa/foto/aislamiento y error/insuficiencia/sin alternativas/
  largos pasan con layout final. Máximo falla por arrastre helper 95% que activa
  manual: screenshot `3F0B41CC-8AA0-4F9C-A1C5-CBB0BC37102B.png` conserva diagnóstico.
  Solo assertRetryLayout cambia scroll a gutter 99% (default del helper intacto para
  otros callers) y añade manual no seleccionado antes/después; assertions originales
  enabled/igualdad/separación/selección intactas.
- `ui-layout-repair.log/.xcresult/-summary.json`: exit 0, **1/1** máximo final.
  Sin retries automáticos/gate completo. Fallos anteriores íntegros.
- **42 escenarios distintos pasan: 34 unit + 8 UI**, cero omitidas. Reutilización
  de esta ronda: unit inicial 33 + nueva unit 1; dos manuales sin resultado de
  ui-first y espera de ui-repair por caminos relevantes intactos; cuatro escenarios
  de ui-visual-final y máximo final reparado. Los bundles fallidos completos no se
  declaran aprobados, ni el 123/123 histórico como gate final de esta ronda.
- Estáticos `static.log`: parse Swift, plutil proyecto, JSON catálogo/lista,
  diff y SHA256 spec intacto. Preparación inicial falló antes de ejecutar por workdir
   inexistente; corregida sin ejecutar tests duplicados ni ocultar fallo de producto.
- Inspección visual real de PNG exportados: vacío/rellenado/largo/teclado/resumen
  manual de ui-first (caminos sin resultado intactos); insuficiencia sin aviso IA,
  exclusión manual↔IA y teclado/resultados en ui-visual-final; acciones iguales/
  separadas y summary IA de ui-layout-repair. También vuelta y no-alternativas.
  Interacción XCUITest, no recorrido manual interactivo adicional.
- `final-source-manifest.json` (fuentes al último test) y `delivery-source-manifest.json`
  (incluye init público para validator) contrastados con raíz/sandbox. Catálogo tuvo
  orden/extractionState automáticos, sin cambio de textos; catalog-semantic-check
  acredita equivalencia. `final-manifest-check.json`: **86 hashes iguales** raíz/
  sandbox (85 fuentes/recursos/config pública + init público), cero cambios desde
  el último test en las 85 fuentes testeadas. Ninguna fuente ejecutable cambia después.
  `static-final.log`: parse Swift, proyecto/plutil, JSON catálogo/lista, bash init,
  diff/hash e ignore de config correctos. Otras features y arrays históricos de
  evidence/validator_evidence contrastados contra HEAD: intactos.

### Comandos exactos

Todos desde `DerivedData/manual-inline-sandbox`, serial. Los logs incluyen la
invocación expandida. Comando común con sustituciones literales abajo:

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination 'platform=iOS Simulator,id=B52F5194-6A81-4FAA-B094-B0D248084877' \
  -derivedDataPath "$PWD/DerivedData" \
  -resultBundlePath '../evidence/manual-inline/<nombre>.xcresult' \
  -parallel-testing-enabled NO <selección> test > ../evidence/manual-inline/<nombre>.log 2>&1
```

- `unit`: `-only-testing:PlantCareAITests/ConfirmManualSpeciesTests -only-testing:PlantCareAITests/ManualSpeciesViewModelTests -only-testing:PlantCareAITests/ConfirmSpeciesTests -only-testing:PlantCareAITests/ConfirmSpeciesViewModelTests -only-testing:PlantCareAITests/IdentificationPhotoViewModelTests -only-testing:PlantCareAITests/IdentificationConsentViewModelTests`
- `ui-first`: `-only-testing:PlantCareAITests/ManualSpeciesViewModelTests/testInlineExclusiveSelectionCancelAfterSwitchAndCommonConfirmation -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesWithoutAIAndCancelEdit -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesFromProposalsAndReturn -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesInvalidationCloseAndStorageIsolation -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesAfterInsufficientAndErrorAndUnconfirmedClose -only-testing:PlantCareAIUITests/PlantCareAIUITests/testConfirmSpeciesAlternativeAndDraftInvalidation -only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry`
- `ui-repair`: `-only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry -only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationWaitingCancellationCloseAndRelaunchWithoutDraft -only-testing:PlantCareAIUITests/PlantCareAIUITests/testMaximumAlternativesLastSelectionAndSeparatedEqualActions`
- `ui-visual-final`: `-only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesAfterInsufficientAndErrorAndUnconfirmedClose -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesFromProposalsAndReturn -only-testing:PlantCareAIUITests/PlantCareAIUITests/testConfirmSpeciesAlternativeAndDraftInvalidation -only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry -only-testing:PlantCareAIUITests/PlantCareAIUITests/testMaximumAlternativesLastSelectionAndSeparatedEqualActions`
- `ui-layout-repair`: `-only-testing:PlantCareAIUITests/PlantCareAIUITests/testMaximumAlternativesLastSelectionAndSeparatedEqualActions`

Exportes por bundle desde raíz: `xcrun xcresulttool get test-results summary --path DerivedData/evidence/manual-inline/<nombre>.xcresult --format json > DerivedData/evidence/manual-inline/<nombre>-summary.json` y `xcrun xcresulttool export attachments --path DerivedData/evidence/manual-inline/<nombre>.xcresult --output-path DerivedData/evidence/manual-inline/<nombre>-attachments`.

## Validator
Ejecutar un único gate final `caffeinate -dius ./init.sh` sobre fuentes finales,
en sandbox seguro público/plantilla vacía si se mantiene config real sin lectura.
Reutilizar evidencia focalizada corroborada, no repetirla por rutina. Comprobar
manifiesto contra fuentes, delta autorizado, IA↔manual sin confirmar, campo vacío/
blancos/largo/teclado, resumen/cancelar/precarga/vuelta IA, error/insuficiencia/sin
alternativas, guards y cierre/aislamiento. Inspección implementer cerrada; revisar
capturas/pantallas afectadas como validator. Procesos finalizados al handoff.

Un único iPhone 17 Pro iOS 26.2 B52F5194-6A81-4FAA-B094-B0D248084877,
texto normal/light, serial; verificar procesos antes de usarlo. API/cámara física/
dispositivo físico/Release recertificación y matrices ampliadas no ejecutados ni
exigidos por impacto; no test de red real ni botánica. Cuidados/alta siguen siendo
features futuras, no iniciadas. Riesgo nuevo: scroll/teclado inline en el selector;
E2E e inspección cubren accesibilidad funcional con texto normal, no VoiceOver real.
