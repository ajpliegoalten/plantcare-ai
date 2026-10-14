# Validación independiente: app-launch-branding

## Veredicto: BLOCK

2026-10-13. Rama `feature/app-launch-branding`, HEAD/base
`3033dbc930497f619fb552cbdc29b37b8695eb59`.
Contrato: `docs/specs/app-launch-branding.md`, con autorizaciones posteriores
registradas en PROGRESS/handoff (icono512→1024, Portrait/Light, grupos físicos,
firma ad hoc exclusivamente app SDK simulator Debug/Release). El pendiente de
aprobación de la spec y rechazo de firma originales son históricos, no decisiones
vigentes. `feature_list.json` permanece `passing`; no se persiste accepted.

La implementación supera revisión estática, recursos, firma y visual disponible.
**No puede aceptarse: el único gate final falla por preparación del clon XCTest;
no completa UI ni ejecuta la fase Fotos.** No se ha identificado un defecto de
producto responsable ni una causa profunda del fallo ambiental.

## Gate NUEVO: único intento autorizado

```sh
# Fichero externo público: SOLO SWIFT_EMIT_LOC_STRINGS=NO
XCODE_XCCONFIG_FILE="$PWD/DerivedData/evidence/app-launch-branding/validator/NoLocalizationExtraction.xcconfig" caffeinate -dius ./init.sh
```

- Exit real **65**, capturado en `gate_rc`; `TEST BUILD SUCCEEDED`,
  `TEST EXECUTE FAILED` en paralela. Default5workers/capturas0; init/scheme intactos.
- Bundle original: `DerivedData/TestResults/20261013-215643-44970/parallel.xcresult`.
  Paralela 21:56:46.668–21:58:51.965 +0200. `gallery.xcresult` **no existe**:
  `set -e` detiene el gate antes de PhotosPicker.
- Summary y árbol cotejados: **299 hojas =296 Passed unitarias +3 Failed**;
  cero skipped/expectedFailures. Los dos LaunchBrandingResourcesTests pasan.
  No UI aprobadas en este gate. No presentar 296/299 como gate completo.
- Dos entradas de infraestructura: app/unit host y UI runner no preparan
  `Clone 1 of iPhone 17 Pro`: CoreSimulator SimError404,
  `No matching device (0A5D5C42-11B0-4440-BB73-60CCC48DB39C)` en XCTestDevices.
  `LocalizationUITests/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys()`
  termina con signal term, duración0s en consola; no fallo de assertion localizado.
- Evidencia: `DerivedData/evidence/app-launch-branding/validator/`:
  gate.log/gate-exit.txt, parallel-summary.json/parallel-tests.json,
  inputs-before.json/inputs-after.json, static-review.py/txt, devices.json,
  reused-focused-summary.json, snapshots staged/unstaged before/after.
- **189 inputs públicos byte-exactos antes/después**, iguales al manifest final
  implementer `simulator-signing-inputs.json`. Manifest validator SHA256
  `4688d1504b0064a5c80b464ada1a054c4253b8aea4a46ed6b7c2638dab69830f`.
  Catálogo y proyecto no cambiaron durante gate. Override externo separado.
- Preflight pgrep sin competidores; selección efectiva de init y xcresult:
  `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, iPhone17Pro iOS26.2/23C54,
  Xcode26.2/17C52, macOS26.5.1. Root ya Booted; ProMax ajeno no tocado.
  Texto normal del handoff, no medición AX nueva; app fuerza Light desde plist.
  Consulta simctl appearance devolvió `unknown`, no se afirma medición light
  del sistema ni se cambió preferencia. Sin matrices ampliadas.
- Se esperó el comando original mediante notificación y evento vnode/kqueue del
  fichero de exit, sin polling, retries, iteraciones, otro gate ni focales nuevas.
  Al cierre pgrep no encuentra xcodebuild/XCTRunner/init activos.

## Revisión independiente y evidencia REUTILIZADA

Skills feature-validator y guía local ios-clean-mvvm aplicadas; MCP XcodeBuildMCP
no disponible en catálogo, shell fallback, sin llamadas MCP.

1. **Icono**: AppIcon1024×1024 opaco confirmado con sips. Fuente aprobada JPEG512,
   ampliación sin pretensión de detalle adicional; catálogo universal y máscara
   aplicada por iOS. Contact sheet real muestra brote instalado en SpringBoard.
2. **Arranque frío real**: abiertos por este validator
   `simulator-signing-launch-contact-sheet.png` y `simulator-signing-frame-11.png`.
   Marca, crema, halos, PlantCare/AI y subtítulo exacto legibles en frame11 durante
   animación nativa de iOS; secuencia transiciona a Mis plantas. No se atribuye
   preview UIKit ni vídeo de copia diagnóstica a captura del bundle habitual.
3. **Transición/datos**: focal original final `simulator-signing-focused.xcresult`
   corroborada summary **4/4 Passed**,0failed/skipped/expectedFailures:
   recursos2 +emptyCollection1 +storedRelaunch1. Reutilizada por189inputs exactos,
   no repetida ni sumada al gate. Inicial6/6 y Portrait4/4 son históricos, no
   evidencia de configuración final de firma. Gate actual UI sigue incompleto.
4. **Bundle offline Debug/Release**: inspección directa de plists/artifactos
   confirma LaunchScreen.storyboardc, AppIcon, Portrait-only/Light, ausencia de
   UILaunchScreen generado y sello CodeResources; Release sin cinco keys puente
   Debug. No se imprimen valores de configuración privada. Logs finales existentes
   Debug TEST BUILD SUCCEEDED / Release BUILD SUCCEEDED reutilizados, no Release
   rebuild nuevo. `codesign --verify --strict --verbose=2` ejecutado aquí válido
   ambos, Signature=adhoc/TeamIdentifier not set/SealedResourcesv2 (43/7files).

## Arquitectura, alcance y seguridad

- Presentation de arranque es storyboard nativo estático, sin customClass,
  timers, splash SwiftUI, navegación, red, permisos ni IO nuevos. Domain/Data y
  composición sin cambios; no capas/casos de uso artificiales.
- Script macOS offline revisado: entrada local aprobada→CGContext→cuatro PNGs
  en rutas fijas; no descarga ni ejecución desde build/target. No regenerado.
- Auditoría PBX independiente (`static-review.py`): **69 grupos físicos/161 refs
  únicas existentes sin symlinks**, DeletePlant Domain/Data bajo Features y test
  bajo PlantCareAITests. PBXBuildFile/membership/fases previos conservados, solo
  test/storyboard nuevos registrados. Dos errores del script validator (tratar
  xcassets como fichero y suponer nombre DeletePlantViewModelTests) corregidos
  únicamente en evidencia ignorada; no errores del producto ni tests rerun.
- Todas build configurations comparadas contra HEAD: delta autorizado exacto.
  Únicamente app Debug/Release agrega cuatro settings SDK signing YES/identity-;
  generalNO/tests/dispositivo conservados. Manual/team/profile vacíos externos
  preservados. Sin certificados, profiles, entitlements, cuenta Apple ni firma
  física; preparación futura no verificada ni requisito de esta feature.
- JSON/plutil/diff-check pasan. **258 claves de localización y sus localizations
  anteriores exactas**, cambios externos de serialización/extractionState
  preservados. Workspace `self:` generado por usuario/Xcode conservado.
  Snapshots staged/unstaged before/after iguales antes de crear este informe;
  no Git stage/reset/commit/push/PR/merge ejecutado.
- Checklist seguridad por diff: sin hallazgos relevantes de secretos, nueva
  exposición, bypass, envíos o dependencias. Config real solo existencia e ignore;
  no leído/hash/copied/overwrite; no API real. Firma ad hoc de simulador no
  acredita identidad de distribución ni añade custodia apta para publicación.

## Documentación y observaciones no bloqueantes

Spec original preservada; addenda PROGRESS/handoff trazan autorizaciones y
negativos históricos correctamente. ARCHITECTURE/CONSTRAINTS/DESIGN/testing-ui
explican firmaSDK, recursos nativos y provisioning futuro. Brief/dominio sin
cambios necesarios. Estado passing representa focal, no aceptación completa.

Nota Low: bullet heredado de ARCHITECTURE «ocho colores… sin imágenes» sigue
literalmente obsoleto; la nueva sección inicial define explícitamente AppIcon y
artwork y resuelve la dirección vigente. Conviene aclarar ese bullet histórico
en una limpieza documental posterior, sin reinterpretar pruebas históricas.
No defecto ejecutable ni motivo de este BLOCK.

## B1 — gate incompleto por preparación del clon

- **Severity High (bloqueo ambiental de verificación)**.
- Evidencia: exit65 y tres fallos originales arriba; Photos no ejecutada.
- Impacto: faltan UI finales y Photos; ni focal anterior ni captura manual
  sustituyen gate estándar ambas fases. No accepted/commit/push/PR.
- Resultado requerido: entorno XCTest propio operativo y gate final completo
  con ambas fases Passed. No declarar causa universal ni reparar producto por
  especulación; no debilitar assertions/timeout/worker policy.

### Implementation / Environment Repair Brief

1. Preservar este bundle/log/exit y manifest. STOP nuevas ejecuciones: autorización
   del intento único consumida; solicitar autorización posterior antes de
   diagnóstico runtime, recuperación del entorno o nueva prueba.
2. Padre diagnostica bajo hipótesis explícita la pérdida/no resolución del clon
   propio `0A5D5C42…` durante instalación (contrastar launcher/XCTestDevices y
   CoreSimulator); no resetear datos/root/ProMax ni otros recursos ajenos.
3. Tras autorización, recuperación únicamente de recursos propios y comprobación
   focal del escenario interrumpido/launcher afectado; conservar fallo anterior.
   No repetir tests pasados ni hacer retries para obtener verde.
4. Un gate completo futuro requiere justificación explícita de invalidación de
   la evidencia fallida/incompleta y autorización nueva, defaults estándar y
   ambas fases; revisión independiente entonces podrá emitir accept.
5. Registrar diagnóstico/commands/resultados reales, mantener feature passing
   hasta aceptación independiente; no implementar otra feature ni provisioning.

No cambio de producto/tests/spec/status requerido por un defecto demostrado;
no aceptación parcial ni permiso de entrega derivado de este informe.

---

## Apéndice V2 — veredicto vigente: BLOCK

2026-10-13, autorización posterior explícita de diagnóstico/recuperación y **un
nuevo gate final**. V1 y su exit65/296Passed/3Failed/PhotosNO permanecen íntegros,
no convertidos en verde. Original de este informe preservado byte-exacto hasta
este apéndice, SHA en `validator-v2/original-report.sha256` y copia ignorada.
No accepted ni cambios de producto/tests/spec/status/Git entrega por validator.

### Recuperación previa corroborada (REUTILIZADA, no repetida)

- `recovery/missing-clone-check.json`: UUID0A5D5C42 ausente de registro,
  directorio y device.plist. Logs filtrados describen creado/Booted→ShuttingDown→
  NoMatchingDevice404; actor/causa profunda **no acreditados**. Warning AMFI no
  acredita defecto de producto ni firma. Sin resets/borrados/globalservicekill.
- `recovery/interrupted-launcher.xcresult` summary independiente: **1/1Passed**,
  cero failed/skips/expectedFailures. Parent ejecutó solo Localization interrumpida,
  test-without-building/parallelYES/default5workers, clon XCTest nuevo.
  No se repiten las296unit verdes como diagnóstico ni se confunde esta focal con
  full gate o garantía de cinco clones.189inputs exactos antes/después de focal.
- Preflight V2 sin competidores. Root estabaShutdown; validator boot/bootstatus
  exclusivamente00BBB7EC autorizado (22:14:46–49 local); selección Booted-first
  de init confirmada antes de lanzar. ProMax/otros no tocados.
  Hubo únicamente preparación pública/evidencia antes de reanudación de usage;
  ausencia gate.log/exit y procesos verificada antes del lanzamiento único.

### Gate NUEVO V2: único comando original

```sh
XCODE_XCCONFIG_FILE="$PWD/DerivedData/evidence/app-launch-branding/validator-v2/NoLocalizationExtraction.xcconfig" caffeinate -dius ./init.sh
```

Override externo contiene SOLO `SWIFT_EMIT_LOC_STRINGS=NO`; efectivo en log,
init/scheme/assertions/timeouts/workers intactos. Misma fuente/config/destino,
sin full baseline ni tests focales adicionales. Wrapper23:29:37–23:52:37 +0200.
Notificación original y espera vnode/kqueue, sin polling/retry/relanzamiento.

- **Exit real65 (`gate_rc`)**, TEST BUILD SUCCEEDED / TEST EXECUTE FAILED.
- Bundle `DerivedData/TestResults/20261013-232938-51201/parallel.xcresult`;
 23:29:45.230–23:52:36.670 +0200. **Photos serial NO ejecutada** por set-e,
 no gallery.xcresult; no aprobación parcial ni gate final válido.
- Summary/árbol corroborados: **389 hojas únicas =388Passed (296unit+92UI)
 +1Failed infraestructura**, cero skipped/expectedFailures. Todos escenarios
 funcionales de paralela pasan, incluidos recursos2, emptyCollection,
 storedRelaunch, detalle y Localization. No assertion funcional fallida
 identificada; infraestructura **también hace fallar el gate**.
- Fallo original UI runner: `Failed to install or launch the test runner`,
 `FBSOpenApplicationServiceErrorDomain Code1 / RequestDenied`,
 `SBMainWorkspace Busy (Application failed preflight checks)`, al lanzar
 `org.plantcareai.prototype.uitests.xctrunner`. Registro en log23:31:39.782.
 No se equipara al missing-clone404 de V1 ni se infiere causa de signing/usuario.
- Summary confirma00BBB7EC iPhone17Pro iOS26.2/23C54/macOS26.5.1,
 Xcode26.2/17C52, normal según handoff/Light por plist/default5workers/capturas0.
 Sin matrices, APIreal ni lecturas/hash/copias de config real/xcuserdata.
- Evidencia NUEVA `DerivedData/evidence/app-launch-branding/validator-v2/`:
 gate.log/exit, wrapper-start/end, summaries/tests, manifest before/after,
 snapshots staged/unstaged, devices-before, original-report snapshot/hash.
 **189inputs públicos exactos antes/después**, iguales a implementer y recovery;
 manifest SHA256 `4688d1504b0064a5c80b464ada1a054c4253b8aea4a46ed6b7c2638dab69830f`.
 Staged/unstaged snapshots exactos antes de este apéndice; no staging alterado.
 pgrep de cierre sin xcodebuild/XCTRunner/init/caffeinate activos.

### Revisión vigente, documentación y seguridad

Reutilizada revisión independiente V1 de cuatro escenarios, recursos/offline,
firma ad hoc válida Debug/Release, visual REAL abierto,69grupos/161refs únicas,
settings SDK-only/membership/258localizations exactos, arquitectura y checklist
seguridad:189inputs relevantes no cambiaron. No nuevos builds Release, visuales,
focales ni artefactos diagnósticos atribuidos a captura normal. Addendum
PROGRESS/handoff coincide con autorización/recuperación, sin nuevo contrato.
Nota documental Low «sin imágenes» sigue no bloqueante; no reparación de
producto demostrada. Firma física/cuentas/profiles futuros y matrices fuera de
verificación habitual no son requisitos ni evidencia aprobada.

### B1 High sigue abierto — gate V2 fallido/incompleto

**BLOCK vigente, STOP**: autorización del único V2 consumida. La focal de
recuperación prueba su escenario, y388Passed prueban paralela funcional, pero
no autorizan accepted, commit/push/PR ni sustituyen Photos/gate completo.

Repair brief actualizado para el padre:

1. Preservar V1/V2 originales y manifiestos; no tercer gate ni retry automático.
2. Solicitar autorización nueva antes de diagnóstico runtime/recuperación/tests.
   Contrastar bajo hipótesis explícita el launcher del runner y el rechazo
   SBMainWorkspace23:31:39 del clon afectado; distinguirlo de missing-clone V1.
   No culpar ad hoc/AMFI sin evidencia ni modificar producto especulativamente.
3. Recuperar exclusivamente recursos propios si el diagnóstico lo justifica;
   no erase/reset/datos/root/ProMax/globalservicekill ni debilitar assertions,
   timeout o política de workers. Diagnóstico focal solo del fallo afectado,
   sin repetir388tests aprobados para forzar verde.
4. Gate futuro solo tras justificación explícita de recuperación/cambio que
   invalida evidencia fallida y autorización nueva, ambas fases estándar.
   Registrar todos resultados, sin borrar este fallo ni prometer causa universal.
5. Mantener `passing` hasta gate válido/aceptación independiente. No hace falta
   sourcefix demostrado; no accepted/entrega ni features/provisioning adicionales.

---

## Apéndice V3 — veredicto vigente: ACCEPT

2026-10-14. **accept** independiente para `app-launch-branding`: contrato y
ampliaciones autorizadas conformes, gate completo válido y revisión de
recursos/firma/visual/seguridad/arquitectura conforme. **B1 cerrado para esta
versión y entorno V3**; V1/V2 fallidos se conservan íntegros como prefijo del
informe y artefactos originales. No causa profunda ni recuperación de cinco
clones demostradas. Validator no persiste `accepted` ni ejecuta Git entrega.

### Autorización y mitigación ambiental (no reparación de producto)

Usuario autoriza diagnóstico/recuperación posterior a BusyV2 y único nuevo gate
completo con **TEST_WORKERS=1**, opción ya admitida1..5 por init. Default5 permanece
intacto. Necesario porque ningún gate completo anterior era válido, y V3 usa
entorno de workers mitigado distinto; no se convierte V2 en green ni se alega
igualdad del entorno de concurrencia.

Parent identificó Clone3 efectivoF0BA1C1F… en launchoptions (device_identifier
exterior era root), log creado/Booted→Busy/PID0 antes de tests. Hipótesis de
contención de startup de runner frío extra **no demostrada**; AMFI no prueba
fallo de firma/storyboard. Sin erase/delete/reset/globalservicekill. Focal mínima
original del launcher (escenario corto emptyCollection existente, no método
infra seleccionable), `recovery-v2/single-worker-launcher.xcresult`: summary
corroborada aquí **1/1Passed/exit0**, cero failures/skips/expectedFailures, con
un worker. Se reutiliza, no nueva focal/baseline ni repetición388funcionales.
No acredita full suite ni cinco clones simultáneos.189inputs before/after
recovery exactos a implementación y gate.

Preflight independiente sin procesos competidores; root estabaShutdown. Boot y
bootstatus dirigidos exclusivamente00BBB7EC (00:09:26–30 local), selector real
Booted-first de init comprobado. ProMax/otros/datos intactos; un solo modelo/
runtime iPhone17Pro iOS26.2/23C54 Xcode26.2/17C52 macOS26.5.1, texto normal del
handoff y Light por plist. Sin matrices/tamaños aumentados/AX Inspector, fuera
de verificación habitual/no ejecutados/no bloqueos automáticos.

### Gate NUEVO V3: original único completo

```sh
TEST_WORKERS=1 XCODE_XCCONFIG_FILE="$PWD/DerivedData/evidence/app-launch-branding/validator-v3/NoLocalizationExtraction.xcconfig" caffeinate -dius ./init.sh
```

- **Exit real0 (`gate_rc`)**, TEST BUILD y **ambas TEST EXECUTE SUCCEEDED**.
  Override público externo SOLO `SWIFT_EMIT_LOC_STRINGS=NO`, efectivo en log.
  Suite/assertions/timeouts/init/scheme/firma/source sin cambios ni retries.
- Resultado corroborado summary/árbol: **390/390 IDs únicos Passed =296unit+
  92UI paralela +2Photos serial**. Cero failures/skipped/expectedFailures;
  388IDs paralela y2gallery únicos/disjuntos, sin sumar focales reutilizadas.
- Bundles originales `DerivedData/TestResults/20261014-000939-58441/`:
  `parallel.xcresult`00:09:47.359–01:22:45.426 +0200,
  `gallery.xcresult`01:22:54.094–01:24:24.266 +0200.
  Wrapper00:09:38–01:24:24 +0200. Summary de ambas fases confirma mismo root
  `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`/iPhone17Pro/26.2/23C54.
- CLI real paralelaYES/worker1/maxdestination1, PhotosNO/serial. Clase Fotos
  completa sembrada por init y ambos tests Passed. Recursos2, emptyCollection,
  storedRelaunch, detalle y fallbackLocalization Passed en gate nuevo.
- Evidencia NUEVA `DerivedData/evidence/app-launch-branding/validator-v3/`:
  gate-command.txt/log/exit, wrapper-start/end, results-path.txt,
  parallel/gallery-summary/tests.json, inputs-before/after.json,
  devices-before.json, staged/unstaged-before/after.txt,
  original-report.md/sha256 (prefijoV1/V2 intacto).
- **189inputs públicos byte-exactos antes/después**, iguales a implementer,
  V1/V2/recovery. ManifestSHA256
  `4688d1504b0064a5c80b464ada1a054c4253b8aea4a46ed6b7c2638dab69830f`.
  Catálogo/PBX sin drift; override externo aparte. Snapshot staged/unstaged
  exactos antes de este apéndice. Ninguna lectura/hash/copia/overwrite de
  Config real ni xcuserdata; solo existencia. Sin APIreal/credenciales privadas.
- Espera por notificación original y evento vnode/kqueue, sin polling/iteraciones/
  gate extra/focal repetida. Pgrep de cierre sin xcodebuild/XCTRunner/init/
  caffeinate activos. No procesos manuales de test paralelos.

### Review reutilizada de inputs pertinentes exactos y aceptación

Revisión independiente previa íntegra reutilizada, no solo confianza del
implementer: PNG1024opaco y procedencia512aprobada, storyboard nativo static/
offline/textos/local artwork, firma ad hoc válida real Debug/Release/SDK-only,
Release sin cinco keysDebug, visual real de bundle normal abierta por validator
(contactsheet/frame11 durante animación), transición vacío/guardado,69grupos/
161refs físicas únicas sin symlinks/membership exacto y traducciones258keys
preservadas. No preview o vídeo de copia diagnóstica atribuidos al sistema
normal. No Releasebuild/firmaverify/visual nuevos por rutina ni otra UI focal.

Cuatro acceptance scenarios satisfechos con recursos/builds/visual y gate final;
Domain/Data/composición sin cambios, Presentation exclusivamente recurso UIKit,
script offline fuera de target, Portrait/Light autorizados. Sin nuevas pantallas,
red, persistencia, cuentas, permisos, timers o capas artificiales. Security
checklist previa sin hallazgos relevantes, mismo diff/config públicamente
contrastados; provisioning físico/distribución y calidad/APIreal fuera de scope.

Spec original pendiente/rechazo histórico correctamente sucedidos por
PROGRESS/handoff; addendum de recuperación/worker1 coherente con ejecución.
Docs durables describen política vigente; nota Low heredada ARCHITECTURE «sin
imágenes» sigue aclarable sin blocker (nueva sección explícita define artwork).
**No findings bloqueantes ni repair brief vigente**. Bloqueo de evidencia B1
cerrado por gateV3 válido, no por borrar fallos ni asegurar estabilidad universal
del launcher/default5workers.

### Handoff al padre

Persistir aceptación `accepted`/evidencia y proceder a commit/push/PR hacia main
según autorización explícita del usuario, tras corroboración propia. Preservar
staging externo y originales V1/V2; no nuevo gate por cambio de rol/docs/status.
Este validator solo añade informe/evidencia ignorada, no status/producto/tests/
spec/harness/stage/commit/push/PR/merge. No otros agentes/features. No pruebas de
dispositivo/certificados/perfiles ni garantía de cinco workers inferidas.
