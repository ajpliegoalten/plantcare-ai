# Seguimiento final independiente H3 — accept

**2026-10-11 · Verdict: accept · ui-test-performance**, spec `docs/specs/ui-test-performance.md` con delta5workers/evidencia estándar. Usuario autorizó reparar H3 y nuevo gate final; validator no publica ni cambia el estado a accepted.

- Nueva ejecución única: `caffeinate -dius ./init.sh` en `DerivedData/ui-test-performance-H3-final-public`, defaults5workers/capturas0, sin overrides/BASH_ENV/trace/retries/baseline/focalizadas adicionales. **TEST BUILD SUCCEEDED +ambas fases TEST EXECUTE SUCCEEDED, exit0**.
- **163/163 PASS:125 unitarias +37UI paralelas y1UI PhotosPicker real serial**. Cero failed/skipped/expected failures. Árboles/summaries independientes confirman162 identificadores únicos paralelos y1 serial; conjuntos completos/disjuntos, sin omisiones/inesperados/duplicación entre selecciones. Seed Fotos real y fase serial ejecutados, no sustituidos por fixture.
- Bundles originales: `DerivedData/ui-test-performance-H3-final-public/DerivedData/TestResults/20261011-222203-64007/{parallel,gallery}.xcresult`. Evidencia estándar `DerivedData/evidence/ui-test-performance-H3-final/`: command.txt, gate.log, gate.exit, summaries/tests de ambas fases, selection-and-source-check.json, harness-check.json, source-before/after.json. No extractores/timings/CSV/cronologías regenerados; todos los hashes de CSV históricos permanecen iguales.
- Entorno: Xcode26.2/17C52 macOS26.5.1/25F80, único iPhone17Pro iOS26.2/23C54 base00BBB7EC-8DF7-400C-A08A-9D3C8818D886 normal/large/light;5workers configurados y Clone1..5 observados, serial sin paralelismo. Coordinación previa sin procesos competidores, wrapper original esperado por NOTE_EXIT, ningún proceso de test duplicado. Capturas0 reales en ambos targets del xctestrun.
- **101 inputs públicos raíz=antes=después=sandbox byte-a-byte**; config únicamente copia del example vacío (igualdad comprobada). No lectura/copia de config privada/xcuserdata/secretos, API real ni matrices ampliadas. Productos compilados desde las fuentes finales, incluyendo comentario afinado; la focalizada H3 previa no se presentó como identidad byte-a-byte de esas fuentes.
- **H3 cerrado**: delta ejecutable únicamente caller Cancelar `gutterX:0.85` dentrocontenido; shared helper intacto,8gestos/isHittable/geometría y todas assertions busy/cancel/error/count/identity/retry/close/reopen/relaunch/storageverify conservadas. Escenario completo PASS en gate final. Diagnóstico anterior acreditaba movimiento transitorio/rebote en borde, no receptorUIKitexacto ni defecto producto/carga5workers. Focalizada anterior1/1 corroborada sin repetirla; captura `care-waiting` A9ED9F0C… inspeccionada independientemente muestra Cancelar libre deoverlay, loading/foto y controles bloqueados.
- **H1/H2 siguen cerrados**: manual estrictamente vacío/placeholder exacto y exact-input;5Manual+otroscallers verdes. Script stdlib/configuración xctestrun0 real y evidenciaoptin anterior reutilizada, sin repetir capturas/Release. Cobertura estática independiente35métodos previos y sustitutos permanece aplicable (CSV histórico conservado); ahora38UI ejecutadas completas respaldan equivalencia funcional. No producto/unitarias/Domain/fixtures/harness adicionales cambiados por H3.
- Checklist scoped seguridad/arquitectura/docs: sin nuevos findings bloqueantes. UUIDlimpieza DebugSimulator limitada a namespaces de tests, dependencia Clean/MVVM/adaptadores/consentimiento/IOreal intactos; nuevo caller no introduce rutas/red/secretos. Harness falla ante error y compilauna vez, dosfases explícitas/disjuntas. Spec/docs concuerdan con delta5workers/capturasoptin; las referencias a gate pendiente describen historia de implementer y se resuelven con esta evidencia, no se reescriben. Sin garantías cuantitativas de ahorro/performance ni ampliaciones no solicitadas.

**Required follow-up:** ninguno para aceptación funcional. Orquestador puede persistir accepted y realizar la publicación Git autorizada por usuario tras este verdict; validator no branch/stage/commit/push/PR. Los dos gates fallidos, hallazgos y bloqueoprocedimental previos permanecen íntegros debajo, sin reinterpretarlos como aprobados.

---

# Antecedentes íntegros

# Seguimiento independiente — fuentes reparadas, gate autorizado de nuevo

**2026-10-11 · Verdict: revise.** Nueva autorización: «Lanza el gate completo de nuevo». Spec con delta posterior aplicada:5 workers y evidencia estándar, sin nuevos informes de rendimiento. Estado permanece passing focalizado; el validator no persiste accepted.

## Ejecución única sobre fuentes finales

- Comando: `caffeinate -dius ./init.sh`, CWD `DerivedData/ui-test-performance-final-public`; defaults5 workers/capturas0, sin overrides/BASH_ENV/trace. Shell guarda stdout/stderr en `DerivedData/evidence/ui-test-performance-final/gate.log` y exit real en `gate.exit`. Proceso original esperado por NOTE_EXIT, sin polling ni relanzamiento.
- **TEST BUILD SUCCEEDED; fase paralela TEST EXECUTE FAILED, exit65**.125 unitarias pasan;37 UI paralelas:36 pasan y1 falla. Total **161/162 pasan**, cero skipped/expected failures. Descubrimiento/conjunto paralelo exactamente125+37,162 identificadores únicos, sin identificadores inesperados.
- Por set-e, **seed Fotos y fase serial no ejecutados; gallery.xcresult no existe**. No se acredita gate163/163 ni se sustituye Fotos por fixture.
- Bundle original: `DerivedData/ui-test-performance-final-public/DerivedData/TestResults/20261011-215147-57159/parallel.xcresult`. Summaries/tree/conjunto normal: `parallel-summary.json`, `parallel-tests.json`, `selection-check.json` en evidencia nueva. Sin extract-results/parse-runner, tablas/cronologías/mediciones detalladas regeneradas. Todos los CSV históricos conservan sus hashes.
- Xcode26.2/17C52, macOS26.5.1/25F80, iPhone17Pro iOS26.2/23C54 base00BBB7EC-8DF7-400C-A08A-9D3C8818D886, normal/large y light. Logs confirman runners de Clone1..5 del mismo modelo/runtime; una sola sesión, sin competidores previos. No matrices ampliadas, API real, configuración privada ni xcuserdata leídos/copied.
- Sandbox público nuevo, **101 inputs root=antes=después=sandbox**, config solo del example vacío. Manifests `source-before.json`, `source-after.json`; delta vs gate anterior: solo helper UI/scheme/init y nuevo script Python. Producto y unitarias intactos respecto aquella revisión. No repairs/versionado/publicación por validator.

## H1/H2 cerrados; evidencia reutilizada sin repetir focalizadas

- H1: `typeManual` acepta tras borrar únicamente cadena vacía o placeholder exacto de TextField nativo con placeholder no nil. TextView/residual/nil no se aceptan; igualdad exact-input y assertions de escenarios intactas. Los5 métodos ManualSpecies pasan también en este gate, incluidas las3 failures anteriores.
- H2: scheme TestActionNO/default literal0; script stdlib configura0/1 en xctestrun, y init utiliza explícitamente ese fichero. `.xctestrun` real del nuevo gate contiene valor0 en ambos targets (`runner-capture-default.json`). Sin cambios al entorno de LaunchAction ni a config de app.
- Focalizadas existentes corroboradas: `DerivedData/ui-test-performance-repair-public/focused.xcresult`7/7 y `capture-check.xcresult`1/1 de un escenario ya incluido, con configuración distinta justificada; **7 escenarios distintos, no8**. Activities originales contienen attachments manual-keyboard/manual-filled/manual-summary con sus sufijos exportados. Export normal de summaries/tree/activities y corroboración en `reused-*`/`focused-corroboration.json`. No repetición focalizada ni capturas nuevas/Release por rutina. Un frame del nuevo fallo se extrajo de su recording original solo para diagnóstico, no se lanzó una nueva captura/test.
- Auditoría completa anterior de35 métodos/cobertura permanece aplicable: producto/unitarias y demás assertions/UI no cambiaron, salvo reparación estricta del vacío. No gap estático nuevo detectado. El fallo siguiente y la omisión Fotos impiden aceptación ejecutada completa.

## H3 — Reveal de Cancelar solicitud falla antes de cancelar cuidados

- **Severidad: High**, impide verificar cancelación/cierre y conservación de almacenamiento.
- Evidencia: `CareSheetUITests/testCareSheetCancellationCloseAndStorageIsolation()` es la única failure; console original sitúa `XCTAssertTrue failed` en **PlantCareAIUITests.swift:58**, `revealInPhoto` (isHittable después de8 gestos), invocado para `cancelCareSheetRequest`. No es la assertion de vacío H1.
- `failed-test-console.txt` y `failed-test-activities.json` muestran ocho gestos descendentes globales y fallo antes del tap/cancelación. El recording original y `care-cancel-failure-frame.png`, abierto independientemente, muestran la sheet aún en «Generando cuidados…», con Cancelar solicitud junto al área translúcida de cabecera y controles deshabilitados debajo. No se demuestra cierre espontáneo, crash, alta inesperada ni defecto del producto; la causa exacta de que ese recorrido no desplace el target debe resolverse, no atribuirse automáticamente a tiempo de API o carga de5 workers.
- Artefactos: `failed-test-details.json`, `failed-test-console.txt`, `failed-test-activities.json`, `failed-test-attachments/` (incluye recording `58A6F49F-4BC7-445C-B443-9215C41A7CF2.mp4`) y `diagnostics/` en evidencia nueva. Helper falla correctamente sin seguir operando sobre contexto incierto.
- Cambio requerido: conseguir que el helper/test llegue al Cancelar real en contenido no ocluido mediante el viewport/gutter apropiados, preservando bounded gestures, isHittable y geometría; luego ejecutar cancelación/retry/close/verify originales. No quitar assertions, aumentar ciegamente loops/timeouts, bajar workers para ocultar fallo ni cambiar producto para acomodar el test.

### Implementation Repair Brief (no ejecutado)

1. Diagnosticar H3 con los eventos/snapshots/recording ya preservados: identificar el ScrollView correcto, geometría de Cancelar y gesto efectivamente recibido; comparar el recorrido con helpers relacionados. Mantener5 workers y estándar normal/light.
2. Reparar solo el escenario/helper necesario, con movimiento guardado en contenido y parada por target accesible sin oclusión. Conservar todas las assertions de cancelación/busy/identity/counters/retry/close/relaunch y exact-model/JPEG verification; no repair de producto salvo defecto demostrado y autorización nueva.
3. Ejecutar primero únicamente el escenario fallido sobre reparación; si cambia helper compartido, añadir callers realmente afectados por diff. Preservar este gateFAILED; no retry idéntico para verde. No volver a probar H1/H2 por rutina si sus fuentes/entorno relevantes siguen iguales.
4. Después pedir validator para nuevo gate final único de fuentes reparadas (evidencia actual fallida nunca vale como pass), exigiendo125+37 paralelos y1 Fotos serial, ambos bundles verdes/conjuntos completos y disjuntos. No autorización inferida para relanzarlo ahora.
5. Registrar evidencia estándar y pendientes, sin regenerar CSV/tablas de rendimiento ni iniciar otra feature/flow/Git publicación.

Checklist de seguridad/arquitectura scoped sin nuevos findings bloqueantes: Python stdlib modifica solo variable explícita de runner generado, valores0/1 validados y fallo sin variable impide continuar; capas/IO/consentimiento/transportes/config privada no modificados. Docs y delta concordantes con5 workers/default0 y xctestrun; fallo histórico y todos sus informes/CSV se preservan abajo. **No cambios de estado, reparaciones, stage/commit/push ni segunda ejecución en esta ronda.**

---

# Antecedente íntegro — primera validación y bloqueo previo

# ui-test-performance — validación independiente final

**Verdict: revise.** Fecha: 2026-10-11; validator openai/gpt-6.1-sol, skills feature-validator e ios-clean-mvvm. No se confirma todavía conservación completa en ejecución: tres escenarios abortan y Fotos no llegó a ejecutarse. No reparación realizada, ni passing/accepted artificial, stage/commit/push/publicación.

Spec vigente `docs/specs/ui-test-performance.md`, SHA256 `e6d287d00b57da3ab2348e8f65c37576450eb8c8189276144b49104ecbf8b209`. La revisión de `in_progress` fue solicitada explícitamente por usuario. El bloqueo inicial por falta de spec se resolvió documentalmente y se conserva íntegro al final como antecedente; no hubo gate antes de resolverlo.

## Único gate final nuevo y entorno

```sh
# Sandbox público: DerivedData/ui-test-performance-public
caffeinate -dius ./init.sh
```

Wrapper `DerivedData/evidence/ui-test-performance/run-gate.py`, log original `gate.log`, timestamps de recepción `gate-lines.jsonl`, exit `gate.exit`, resumen `gate-wallclock.json` y fases `phases.json` en el mismo directorio. `BASH_ENV=.../trace-env.sh` aporta traza con timestamp, sin modificar init ni selección de tests; TEST_WORKERS/UI_TEST_SCREENSHOTS ausentes del entorno exterior para usar defaults2/0. Xcode invocó **una sola compilación build-for-testing** y **una sola fase paralela test-without-building**. No baseline, focalizadas, retry, iterations ni segundo gate. El wrapper original48797 se esperó por NOTE_EXIT, no se reiniciaron pruebas.

- Xcode26.2/17C52, macOS26.5.1/25F80; iPhone17Pro iOS26.2/23C54, base UDID `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, light/texto normal (`large`). Modelo/runtime únicos; clones aislados XCTest permitidos.
- Coordinación: sesión padre autorizó esta ejecución única; inspección ps previa sin procesos competidores (excluida la propia inspección). Sin API real ni config privada/xcuserdata leídos/copied/modificados. Sandbox nuevo con100 inputs públicos y config exclusivamente de `.example` vacío.
- HEAD/base real `12a363b3f44ef0b5abbeb196d402435e33c320ee`, merge save-plant #27. Manifest SHA256 `33d19eaa13d109aa5df08937f14edc6fe5bb87e3c3309608a444cff8a7f48525`. **Los100 hashes root=antes=después=sandbox**, config sandbox idéntica a example. Evidencia `source-manifest-before.json`, `source-manifest-after.json`, `source-comparison.json`; sin deltas ejecutables durante el gate.

| Fase | Inicio–fin UTC | Wallclock | Resultado |
| --- | --- | --- | --- |
| Gate | 19:00:31.299–19:16:39.122 | **967.783s =16m07.783s** | **exit65 / FAILED** |
| build-for-testing | 19:00:32.508–19:00:46.796 | 14.288s | TEST BUILD SUCCEEDED, exit0 |
| Paralela test-without-building | 19:00:46.796–19:16:39.122 | 952.326s | 159 pasan /3 fallan, exit65 |
| Seed Fotos | N/D | N/D | No ejecutado: set-e aborta |
| Serial PhotosPicker | N/D | N/D | No ejecutada: set-e aborta |

Fases medidas por recepción de trazas de inicio/ transición y exit real del wrapper; incluyen pequeño overhead de transición y cierre, no son suma de tests. Sesión interna xcresult:19:00:47.336–19:16:38.670 UTC,951.334s. No se inventa duración de fases no ejecutadas.

Bundle **original**, no rotado: `DerivedData/ui-test-performance-public/DerivedData/TestResults/20261011-210032-48814/parallel.xcresult`. **gallery.xcresult no existe**; no se presenta el único bundle como gate completo. Summary/tree/details/legacy metadata y diagnósticos originales exportados en `DerivedData/evidence/ui-test-performance/`.

## Recuentos, descubrimiento y duplicados

- **125/125 unitarias pasan**, sin cambios de sus fuentes.
- **37 UI paralelas ejecutadas:34 pasan,3 fallan**;13 clases con métodos, un archivo UI único. Cero skipped/expected failures en el bundle.
- Total observado **162 invocaciones /162 identificadores distintos:159 pasan,3 fallan**. Esperado completo163=125+38.
- Única omisión del gate: `PlantCareAIUITests/SystemGalleryUITests/testRealGalleryPickerSelectReplaceCancelAndReselect`, por abortar antes de serial. No hay omisiones inesperadas en la selección paralela125+37.
- **Cero tests duplicados entre las invocaciones realmente ejecutadas.** Corroborado por162 eventos runner `testCaseWillStart` y162 `testCaseDidFinish`,162 summaries de consola únicos,162 metadatos legacy y162 `testDescription` con1 run. No se cuentan assertions/activities ni mensajes repetidos. No se puede acreditar ambos bundles completos porque el segundo no se ejecutó.
- Scheduling contiene dispatch vacío de `SystemGalleryUITests` (skip explícito) y de base `PlantCareAIUITestCase` (sin métodos): **no son ejecuciones de tests ni duplicados**. Runners49538/49873 son dos procesos sucesivos en Clone1, no dos ejecuciones del mismo método.

`invocation-audit.json` y `runner-invocations.json` contienen la comprobación independiente. La primera vista preliminar del extractor era incorrecta y fue descartada: Test Case Run en el árbol moderno codifica mensajes de fallo, no invocaciones en esta versión. Se conserva en `invalid-extraction-preview.json`, sin usarla para el verdict. `extraction-notes.md` registra también intento de abrir bundle incompleto y export console no disponible; ninguno ejecutó tests ni alteró el gate.

## H1 — Helper manual confunde el placeholder con texto no borrado

- **Severidad: High**, regresión del harness que impide completar escenarios aceptados.
- Evidencia: `PlantCareAIUITests/PlantCareAIUITests.swift:497`, `typeManual`; las tres failures de `parallel-summary.json` dicen `XCTAssertEqual failed: Optional("Ficus lyrata, Potus, Costilla de Adán") != Optional("")`.

| Método ManualSpeciesUITests | Duración (s) |
| --- | --- |
| testManualSpeciesAfterZeroCandidatesAndCancelEdit | 52.127 |
| testManualUnconfirmedDraftDiscardedAfterErrorRecovery | 44.474 |
| testManualUnconfirmedDraftDiscardedAfterInsufficientEvidence | 43.634 |


- Causa acreditada: tras borrar todo el valor precargado, el TextField nativo expone el **placeholder** en `value`. El helper ya distingue placeholder antes de borrar (línea493), pero la nueva assertion tras borrar exige exclusivamente cadena vacía. El log de la primera failure muestra12 deletes para `Ficus lyrata`, inmediatamente seguido de placeholder y aborto; no texto residual demostrado.
- Inspección visual independiente del recording original: `manual-preloaded-before-delete.png` (frame real45.153s: Ficus lyrata) y `manual-empty-after-delete.png` (frame real46.292s: campo vacío/caret/placeholder gris). Recording `manual-failure-media/D26E1D20-0268-4C16-96BD-0D41C63A8343.mp4`. Mismo normal/light; sin nueva prueba para capturas. No defecto del producto inferido.
- Por qué importa: fail-fast aborta antes de cancelación/reconfirmación/descartes posteriores; esos escenarios no quedan verificados aunque el mapa estático sea equivalente.
- Cambio requerido: assertion de vacío compatible con **ambas representaciones nativas** (valor vacío o exactamente placeholder), no eliminar la comprobación ni aceptar texto arbitrario; conservar exactitud del valor después de typeText y todas las assertions de escenario.
- Implementación sugerida: identificar TextField/TextView y normalizar únicamente su representación de vacío en el helper; conservar borrado por longitud/caret y exact-input check. No producto/Domain/fixtures ni revertir a triple-tap frágil.
- Verificación tras reparación: primero3 fallidas y restantes callers afectados (5 métodos ManualSpeciesUITests +CareSheet direct +SavePlant automatic,7 UI distintas); después validator nuevo gate único de fuentes reparadas, con ambas fases. **No ejecutados aquí**.

## H2 — El flag opt-in no se incorpora al runner generado

- **Severidad: Medium**, configuración/documentación de inspección visual incompleta.
- Evidencia: scheme `TestAction` conserva `shouldUseLaunchSchemeArgsEnv="YES"` pero declara `UI_TEST_SCREENSHOTS=$(UI_TEST_SCREENSHOTS)` únicamente dentro de TestAction. El gate pasa build setting0; el `.xctestrun` real carece de `UI_TEST_SCREENSHOTS` en todos los entornos de ambos targets (export público `xctestrun-public.json`). `capture` línea20 consulta ese environment del runner.
- Impacto: la guía que promete capturas con build setting1 no queda sustentada; con herencia de LaunchAction el EnvironmentVariables de TestAction no llega al runner. Default sin capturas funciona, pero la vía opt-in declarada no está correctamente conectada. No se ejecutó modo1 y no se le atribuye éxito.
- Cambio requerido: propagar efectivamente la variable al entorno del runner usando configuración de scheme coherente (por ejemplo TestAction sin heredar env de LaunchAction, o declarar la variable en el entorno realmente heredado). No habilitar capturas de toda la suite por rutina.
- Verificación tras reparación: inspeccionar `.xctestrun` con valor1 y aprovechar **uno de los escenarios manuales focalizados ya necesarios por H1**, comprobando attachment nombrado por `capture`; valor0 debe mantener ausencia de attachments explícitos de éxito. Los diagnósticos automáticos de fallo permanecen: aquí sí se recuperaron recording y48 snapshots/events, aunque `--only-failures` no los selecciona por metadata `isAssociatedWithFailure=false`.

## Auditoría de cobertura, arquitectura, seguridad y docs

Mapa completo **independiente de35 métodos previos** en `docs/validations/ui-test-performance-coverage.csv` (assertions/casos y equivalentes concretos, no solo nombres/count). Fuente previa preservada en `ui-before.swift`, diff en `ui.diff`, inventarios en `ui-inventory.json`.

-35 métodos anteriores:3 redundantes fusionados y bucles4+2+3 separados en9 métodos →38 actuales. No detectado gap estático de assertions/casos: los removed full-detail recorridos conservan presentación canónica de ambos UUIDs en StoredCollection, long/error/fallback; en los puntos de aislamiento se mantiene `--storage-verify`/`--storage-verify-edited` con igualdad de **Plant completo y ambos JPEG exactos**, no solo número de tarjetas. Cada sustitución está descrita en CSV.
- Vacío: todos los textos/enabled/negativos de clean launch integrados; viewport scroll+header fijo, centro y ambas acciones Add permanecen. Tap exitoso+apertura sustituye isHittable redundante del primer Add.
- Selección IA/manual: se conservan no preselección/toggle/exclusividad/identity/cancelación,0 alternativas/max3, long160 y zero-candidate vs error. Manual→IA/reconfirmación repetida en no-alternatives trasladada a casos genéricos de manual/confirm, sin retirar comprobación de ausencia de alternativa ficticia. H1 invalida por ahora3 ejecuciones, no este mapa.
- Cuidados/alta: error/incompleta/renewal separados1:1, identidad/counters/retry sin JPEG extra, no review/partial/save; cancelación remota del caso commit consolidada en cancelación con verify exacto de2 originales/no tercero y nueva assertNoCreationReview. Commit15s observable/no cierre sigue. Long1000 exacto, scroll y relaunch conservados; segunda alta/manual/replacement tienen casos propios. El antiguo nombre UI “late response” no esperaba callback tardío antes tampoco; unitarias VM deterministas siguen cubriéndolo.
- Fotos: photo fixture conserva cámara indisponible/progreso2s explícito/A-error-B/cancelación durante transferencia/gesto con A/reopen/terminate; identificación lenta30s, cuidados waiting20s y commit15s intactos. Cancelar PhotosPicker se trasladó a integración real con exactA retenida, pero **esa nueva ejecución falta**.
- Helpers: fail-fast y8 gestos con geometría conservada; preparación guardada15 intacta. UUID por caso/clones, teardown batch seguro; captura éxito opt-in tiene H2.
- Clean/MVVM: Domain/real Data/ViewModels/ContentView/persistencia/consentimiento/transporte sin cambios. Seams Presentation/Data y cleanup en composición existentes, **DEBUG&&simulator**. Cleanup canonicaliza UUID y limita borrado a StorageTests/UUID y ExternalAIConsentTests.UUID, nunca PlantStore/ruta arbitraria/preferencias standard. Errores de limpieza ignorados pueden dejar fixtures, como antes; no se afirma cleanup transaccional.
- Checklist seguridad scoped: sin findings relevantes bloqueantes. No secretos/nuevas dependencias/auth/ATS/redirect/retry/red/payload/log privado añadidos. Config real no leída/copiada; fotos solo sintéticas. Riesgos históricos Debug extraíble/memoria original/servicios/botánica no recertificados. No Release build nuevo; seams excluidos por inspección, cambios reales de producto ninguno.
- Catálogo JSON frente HEAD: **cero traducciones existentes cambiadas**, solo metadata/reformat/EOF y nuevo empty Debug key Care invocations. Estáticos pasados: diff-check, bash syntax, plutil proyecto, XML scheme, JSON feature_list/catalog, swift frontend parse de4 inputs cambiados. Selector docs actualizado y specs/historia intactos. `docs/testing-ui.md` “no ejecutado” corresponde a fase implementer, no evidencia de esta validación.

## Coste por archivo (orden descendente)

**Suma** = duración medida de tests de ese grupo, incluidos los3 fallidos. **Ventana wallclock** = primer inicio→último fin real del grupo, incluye huecos y solapamientos. No sumar ventanas de clases/ficheros para obtener el tiempo del gate. Los timestamps de logs tienen resolución1ms; duración xcresult más fina, así que en tests muy breves puede sumarse algo más que una ventana redondeada.

| Archivo (prefijo de target implícito) | Invocaciones | Suma tests (s) | Ventana wallclock (s) |
| --- | --- | --- | --- |
| PlantCareAIUITests.swift | 37 | 1699.528 | 860.323 |
| OpenAICompatibleSpeciesIdentificationRepositoryTests.swift | 12 | 10.099 | 10.102 |
| OpenAICompatibleCareSheetGenerationRepositoryTests.swift | 5 | 10.063 | 10.064 |
| ManualSpeciesViewModelTests.swift | 14 | 0.326 | 0.330 |
| LocalPlantRepositoryTests.swift | 8 | 0.301 | 0.303 |
| GenerateCareSheetViewModelTests.swift | 7 | 0.299 | 0.301 |
| ConfirmSpeciesViewModelTests.swift | 8 | 0.234 | 0.236 |
| IdentificationConsentViewModelTests.swift | 9 | 0.234 | 0.237 |
| IdentificationPhotoPreparationTests.swift | 6 | 0.169 | 0.170 |
| SavePlantViewModelTests.swift | 3 | 0.119 | 0.120 |
| SaveConfirmedPlantTests.swift | 4 | 0.055 | 0.055 |
| PlantCardViewModelTests.swift | 6 | 0.046 | 0.047 |
| PlantDetailViewModelTests.swift | 9 | 0.046 | 0.047 |
| IdentificationPhotoViewModelTests.swift | 3 | 0.033 | 0.033 |
| LoadPlantDetailTests.swift | 3 | 0.029 | 0.029 |
| PreparedPlantPhotoValidationTests.swift | 2 | 0.016 | 0.017 |
| PlantListViewModelTests.swift | 5 | 0.006319 | 0.007000 |
| UserDefaultsExternalAIConsentRepositoryTests.swift | 1 | 0.005882 | 0.006000 |
| ConfirmSpeciesTests.swift | 2 | 0.003874 | 0.005000 |
| EditPlantViewModelTests.swift | 3 | 0.002221 | 0.003000 |
| CameraAccessTests.swift | 3 | 0.002154 | 0.003000 |
| IdentifyCandidatesTests.swift | 3 | 0.002002 | 0.002000 |
| ExternalAIConsentTests.swift | 4 | 0.001892 | 0.002000 |
| GenerateCareSheetTests.swift | 2 | 0.001381 | 0.001000 |
| ConfirmManualSpeciesTests.swift | 2 | 0.000707 | 0.001000 |
| UpdatePlantTests.swift | 1 | 0.000497 | 0.001000 |


Total unitario: **22.096s suma**,22.172s ventana (125 tests). UI único archivo: **1699.528s suma =28m19.528s**,**860.323s ventana =14m20.323s** (37 tests), frente952.326s de fase por bootstrapping/finalización/overhead. Todas las duraciones individuales reales en CSV; no datos de galería, por ausencia de fase.

## Coste de clases UI (orden descendente)

| Clase UI | Tests | Suma (s) | Ventana (s) | Resultado |
| --- | --- | --- | --- | --- |
| CareSheetUITests | 6 | 315.854 | 315.858 | Todos pasan |
| ManualSpeciesUITests | 5 | 307.917 | 307.919 | 2 pasan /3 fallan |
| IdentificationResultUITests | 6 | 183.035 | 183.038 | Todos pasan |
| SavePlantUITests | 3 | 166.110 | 166.111 | Todos pasan |
| ExternalConsentUITests | 3 | 151.327 | 151.329 | Todos pasan |
| EditPlantUITests | 2 | 122.018 | 122.019 | Todos pasan |
| PlantCardsUITests | 4 | 108.343 | 108.345 | Todos pasan |
| IdentificationLayoutUITests | 2 | 106.394 | 106.394 | Todos pasan |
| ConfirmSpeciesUITests | 1 | 87.239 | 87.240 | Todos pasan |
| IdentificationPhotoUITests | 1 | 51.756 | 51.756 | Todos pasan |
| StoredCollectionUITests | 1 | 45.128 | 45.129 | Todos pasan |
| CollectionLayoutUITests | 2 | 28.439 | 28.439 | Todos pasan |
| LocalizationUITests | 1 | 25.969 | 25.969 | Todos pasan |
| SystemGalleryUITests | 0 | N/D | N/D | No ejecutada |


## Orden real de lanzamiento y solapamiento

Chronología completa por test: `docs/validations/ui-test-performance-timings.csv`,162 filas ordenadas por evento runner de inicio, con target/clase/método/fichero/fase/worker/cloneUDID/destino base/inicio/fin/duración/solapamientos y líneas exactas del log. Secuencia de dispatch de clases incluyendo las2 vacías: `docs/validations/ui-test-performance-launch-order.csv` (40 filas). Dispatch es planning, no prueba de invocación; usar CSV timings para orden efectivo.

- Unitarias primero, todas en Clone1/PID49538,19:01:33.673–19:01:55.845 UTC (25 clases); cada método y su orden tienen timestamps obtenidos del Session log porque API moderna omite startTime unitario.
- UI después en **dos workers concurrentes**: Clone1 `B972FABB-1A20-488E-87F8-E4F934755E98`/PID49873 (19 UI), Clone2 `3CE9B43F-ED3D-45B0-8289-66B584B3DAB1`/PID49846 (18 UI). Todos corresponden al mismo iPhone17Pro/runtime26.2.
- **Pico observado2 tests simultáneos**,36 inicios tienen otro test en curso. Ejemplo: ManualSpecies AfterZero comienza19:02:00.205 y termina19:02:52.333; CareSheet Cancellation comienza19:02:03.176 y termina19:02:55.087. No hay orden serial único; la lista ordenada por inicio no implica dependencia/ejecución secuencial.

Primeros inicios efectivos por clase UI (no el orden de texto buffered del gate):

| Inicio UTC | Clase UI | Worker |
| --- | --- | --- |
| 19:02:00.205000 | ManualSpeciesUITests | Clone 2 |
| 19:02:03.176000 | CareSheetUITests | Clone 1 |
| 19:07:08.130000 | IdentificationLayoutUITests | Clone 2 |
| 19:07:19.043000 | SavePlantUITests | Clone 1 |
| 19:08:54.533000 | IdentificationPhotoUITests | Clone 2 |
| 19:09:46.294000 | IdentificationResultUITests | Clone 2 |
| 19:10:05.159000 | ConfirmSpeciesUITests | Clone 1 |
| 19:11:32.404000 | CollectionLayoutUITests | Clone 1 |
| 19:12:00.846000 | PlantCardsUITests | Clone 1 |
| 19:12:49.340000 | StoredCollectionUITests | Clone 2 |
| 19:13:34.473000 | LocalizationUITests | Clone 2 |
| 19:13:49.199000 | ExternalConsentUITests | Clone 1 |
| 19:14:00.448000 | EditPlantUITests | Clone 2 |


Fuente de tiempos: Session originales `testCaseWillStart/testCaseDidFinish` con fecha conocida2026-10-11/offset+0200, normalizadosUTC; precisión1ms. Duración original `durationInSeconds` de cada xcresult detail. Worker/clone/PID de scheduling y resumen de consola, no inferencia del destino base. ModernUI startTime corroborado; `.xctestrun` y summaries preservados. Ningún test añadido/repetido para obtener timings.

## Comparabilidad y límites

Gate histórico save-plant **43m47s** no es un baseline comparable de rendimiento: suite serial/35 métodos con bucles, capturas y trayectos distintos, anterior harness y estado de cachés/simuladores. Este gate16m07.783s **falló y no incluyó Fotos**, además3 escenarios abortaron antes de terminar. No se calcula ahorro porcentual/garantía de tiempo ni se llama mejora aprobada. Costes/clases indican dónde se consume trabajo en esta ejecución fallida, no duración definitiva de gate reparado.

Inspección visual focalizada: solo2 frames realmente abiertos del recording fallido para diagnosticar campo manual vacío vs precargado; no matrices, prueba extra, API o launch manual. No se certifica aquí apariencia de todas las pantallas a partir de capturas no inspeccionadas. Layout de producto no cambió; E2E de geometría/long/scroll unaffected pasa. SE/DynamicType aumentado/VoiceOver/appearance matrix/cámara física/iCloud fuera de habitual, no ejecutados/no bloqueos por defecto.

## Implementation Repair Brief (handoff, no ejecutado)

1. Corregir solo `typeManual` para distinguir campo vacío de placeholder nativo tras borrado; conservar exact-input/escenarios/assertions y3 tests fallidos. No modificar producto/Domain/fixtures ni reducir checks para verde.
2. Corregir la conexión de `UI_TEST_SCREENSHOTS` al runner del scheme; inspeccionar xctestrun generado con1 y obtener attachment explícito en uno de los7 callers focalizados de H1, sin suite entera de capturas.
3. Implementer verifica por impacto los7 UI callers:5 ManualSpeciesUITests, CareSheetUITests/testCareSheetDirectAlternativeAndManualSave y SavePlantUITests/testSavePlantAutomaticAIAndManualSameSpeciesRelaunch. Mantener source manifests/public example y fallos actuales.
4. Posteriormente validator ejecuta **un nuevo gate final** sobre fuentes reparadas, necesario porque helper/scheme cambiados invalidan evidencia y el gate actualFAILED nunca cuenta como aprobado. Exigir125+37 paralelos y1 Fotos serial, ambos bundles,0 omisiones/duplicados. No baseline ni retries; no autorización inferida para ejecutarlo ahora.
5. Actualizar docs/evidencia y medir nueva ejecución; no marcar accepted hasta aceptación independiente. Orquestador decide estado; esta revisión lo deja in_progress.

No separar archivos, cambios de producto, refactor adyacente, config privada, commits/stage/push. Informe/CSV y nueva entrada PROGRESS son los únicos cambios versionables realizados por validator; artefactos locales ignorados aparte.

---

# Antecedente conservado — primera revisión bloqueada (resuelta antes de ejecutar)

# ui-test-performance — validación independiente bloqueada antes del gate

Fecha: 2026-10-11. Verdict: **block** (procedimiento/contrato, no fallo de comportamiento demostrado).

## Alcance y estado

Se cargaron `feature-validator` e `ios-clean-mvvm`; se consultaron PROGRESS, feature_list, ARCHITECTURE, rúbrica/checklist y estado/stat del diff. Feature `ui-test-performance` permanece `in_progress`; la autorización actual permite ejecutar el gate y sustituye la prohibición anterior. No se exige fingir `passing`.

## B1 — Falta de spec requerida por la skill

- Severidad: Medium, bloqueo procedimental.
- Evidencia: `test -f docs/specs/ui-test-performance.md` devuelve ausencia. La skill `feature-validator`, paso 1, exige: «If there is no spec, stop: validation needs a contract.»
- El usuario aportó un contrato de mantenimiento (petición + `docs/testing-ui.md` + diff + instrucciones históricas). Es sustantivo, pero no permite a este wrapper omitir la instrucción explícita de parada de su skill. No demuestra pérdida de cobertura ni defecto del refactor.
- Cambio requerido: proporcionar/confirmar una spec de mantenimiento bajo `docs/specs/ui-test-performance.md` que formalice ese contrato existente, sin replanificar producto, alterar specs históricas ni reparar código/tests/harness; alternativamente, resolver la exigencia de spec desde las instrucciones que gobiernan el wrapper.
- Siguiente verificación: retomar auditoría completa de assertions/casos y ejecutar una sola vez el gate final autorizado, en sandbox público con example vacío, con ambos xcresult y extracción de timings/cronología/invocaciones. No ejecutar baseline ni retries.

## Evidencia ejecutada y pendiente

Comandos ejecutados: `pwd`, `git status --short`, `git diff --stat`, listado de specs, comprobación de existencia de spec y lectura de documentación/skills. No tests, build, `./init.sh`, app, simuladores, API, config privada ni xcuserdata leídos/ejecutados. No stage/commit/push ni reparaciones.

Recuentos **esperados, no observados**: 125 unitarias +38 UI (37 paralelas y1 SystemGallery serial). No bundles nuevos. Duraciones de gate/fases/tests/clases/ficheros, orden real y duplicados: **no disponibles**, porque no se inició el gate. No CSV de timings ficticios. Auditoría exhaustiva de cobertura, seguridad y harness: no completada; no se emite conformidad. Aceptación histórica de save-plant intacta y no atribuida a estas fuentes.

## Handoff

Solo resolver B1 y devolver al validator, sin iniciar planner/implementer/flow completo. Conservar cambios actuales e historia; no marcar accepted. No reparación de producto/tests/harness indicada en esta revisión preliminar.
