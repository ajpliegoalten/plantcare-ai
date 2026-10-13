# Handoff: app-launch-branding

## Contrato y autorización

- Worktree `plantcare-ai-launch-branding`, rama `feature/app-launch-branding`,
  base main `3033dbc`; spec `docs/specs/app-launch-branding.md` conservada.
- Usuario confirma «Sí» a icono descargado512→1024 y LaunchScreen estático.
  Sucede pendiente de aprobación del borrador sin reescribirlo.
- Fuente: `img` del HTML proporcionado, URL de googleusercontent/Stitch;
  original descargado en temporal aprobado, JPEG512×512 brote verde opaco.
- URL original:
  `https://lh3.googleusercontent.com/aida/AEtjO1V38QRJnygTLoyyuHWqe5ssS-KdEJIRnKIDaWU0mHY60H2ydS1rRD9YxhjZKdKS3s0xczo-vntPXRTa_PZx0qIV2Dg7x9yOeZGMAw9sLb_3urAZCLNju_BpPzhKSVDR-nixQaqkYENrlGp3zNP2b3-fCQMR9DtF0iyohuD3FTAA5CFw1fvXK8JXlG72xhXdKM5EF1wmHrVlQAvDizeouAZh6XLQPgEmaG9NZJrxxqG_oprCpkRarsdMMAg`.
- No dependencia runtime del enlace. La ampliación no crea detalle. No permiso
  para enviar plantas/credenciales a un servicio IA ni pruebas reales inferido.

## Cambios → riesgos → selección

| Cambio | Riesgo | Comprobación |
| --- | --- | --- |
| AppIcon/artwork | Alfa, resolución, orientación, empaquetado | PNGs y catálogo, build Debug/Release, SpringBoard |
| Storyboard/PBX | Launch vacío, layout, plist incorrecto | ibtool/build, bundles, vídeo arranque y frames; LaunchBrandingResourcesTests2 |
| Recursos comunes sin cambios Swift | Llegada a app/localización/colección | EmptyCollection, Localization, StoredCollection2 |
| Script macOS offline | Generación inválida | ejecución real, revisión PNG; nunca target/build |

Sin nueva lógica Domain/Data/composición; no unitarias de negocio nuevas.
Dos tests de recursos UIKit añadidos después del primer vídeo: comprueban
contrato de bundle/icono/artwork y layout real de storyboard/UILabels sin
ambigüedad, con attachment focal explícitamente denominado preview, no captura
del sistema. Target unitario registra el nuevo archivo en PBX.
No cambios al catálogo de traducciones ni al init/scheme. Storyboard mantiene
español y marca como la app, con UILabels reales en vez de imagen de pantalla.

## Entorno y preparación

- Xcode26.2/17C52; iPhone17Pro iOS26.2
  `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, apariencia light consultada.
- Preflight `pgrep -fl 'xcodebuild|XCTRunner|init.sh'`: sin competidores.
  ProMax ajeno booted no alterado. Sin matrices/SE/tamaños aumentados/VoiceOver.
- Config Debug ausente: solo copia de example público vacío guardando existencia,
  nunca lectura/copia de configuración privada de otro worktree.
- `SWIFT_EMIT_LOC_STRINGS=NO` como override externo del build para no reescribir
  catálogo ajeno por extracción automática; harness/config runtime intactos.

## Comandos y resultados

Artefactos ignorados: `DerivedData/evidence/app-launch-branding/`.

- Generador: `swift scripts/generate-launch-assets.swift <temporal-approved-source>`.
  Primer intento falló SIGTRAP: NSGraphicsContext no soporta bitmapRGB24bpp.
  Reparado con CGContext32bpp sRGB y alpha noneSkipLast para AppIcon; ejecución
  exit0. Inspección inicial detectó halo duro de NSGradient; reemplazado por
  radial CGContext de alpha hasta0 y regeneración exit0 antes de build/tests.
- `sips -g pixelWidth -g pixelHeight -g hasAlpha
  PlantCareAI/Assets.xcassets/AppIcon.appiconset/AppIcon.png` →1024×1024/sin alfa.
- `plutil -lint PlantCareAI.xcodeproj/project.pbxproj` →OK.
- Build Debug lanzado: `caffeinate -dius xcodebuild -project
  PlantCareAI.xcodeproj -scheme PlantCareAI -destination
  'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886'
  -derivedDataPath DerivedData SWIFT_EMIT_LOC_STRINGS=NO build-for-testing`.
  Log `debug-build.log`; **TEST BUILD SUCCEEDED**, sin errores storyboard.
- Release mismo proyecto/scheme/destino/DerivedData/override, `-configuration
  Release build` →**BUILD SUCCEEDED**, `release-build.log`. Info.plist confirma
  UILaunchStoryboardName=LaunchScreen, CFBundlePrimaryIcon/AppIcon, ausencia
  UILaunchScreen generado y de las cinco keys puente Debug; storyboardc incluido.
- Instalación Debug `xcrun simctl install <UDID> DerivedData/Build/Products/
  Debug-iphonesimulator/PlantCareAI.app` exit0. Vídeo `cold-launch.mp4` con
  recordVideo codecH264, arranque usando UUID aislado vacío, screenshot final,
  limpieza exclusiva de UUID/terminate. Comandos/exits `visual-commands.json`.
- Frames AVAssetImageGenerator0.0–1.9s cada0.1s/contact sheet inspeccionada:
  icono SpringBoard correcto; primer arranque pasa por negro brevemente antes
  del listado, **no** se declara LaunchScreen aprobado visualmente todavía.
  `collection-after-launch.png` abierto: colección vacía existente intacta.
  Diagnóstico mediante tests de bundle/render antes de otra observación;
  no ralentizar app ni eliminar datos de usuario para conseguir screenshot.
- Unit2 +UI4 focal lanzado serial (`-parallel-testing-enabled NO`), con
  `-resultBundlePath DerivedData/evidence/app-launch-branding/focused.xcresult`,
  `SWIFT_EMIT_LOC_STRINGS=NO test`; selectores exactos:
  `PlantCareAITests/LaunchBrandingResourcesTests`,
  `PlantCareAIUITests/CollectionLayoutUITests/testEmptyCollectionCenteredBelowFixedHeaderAndAddWorks`,
  `PlantCareAIUITests/LocalizationUITests/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys`,
  `PlantCareAIUITests/StoredCollectionUITests`. Log `focused.log`, pendiente.
- Estáticos: JSON de assets, XML launchScreen/sin customClass/runtimeAttributes,
  plutil PBX, diff-check, features ajenas idénticas aHEAD: pasan. Manifest190
  inputs públicos `final-inputs.json`, excluye secretos/xcuserdata/evidencias.

## Pendiente

Builds/bundles, E2E focal y visual aún en curso: no `passing` ni aceptación.
Validator independiente ejecutará un único `./init.sh` final ambas fases;
no lanzar full gate por rutina desde implementer ni duplicar focales cubiertas.

## Resultados y ampliaciones autorizadas posteriores

- Focal inicial **6/6 Passed=2 recursos UIKit+4 UI**, cero fallos/skips/expectedFailures.
  `focused.xcresult` summary original corroborado; preview exportada y abierta
  `focused-attachments/1E3BBE4F-8A03-4E7E-B09B-4BC42B1D8967.png`: fondo/halos,
  icono/título/cápsula/subtítulo correctos. No es captura real del sistema.
- Diagnóstico del negro: bundle Release copiado a artefacto ignorado, únicamente
  identificador temporal `org.plantcareai.launchbrandingdiagnostic`/displayName
  cambiados. Vídeo nuevo sin firma también negro; instalado/desinstalado solo
  ese bundle propio, sin tocar datos app habitual. Log SplashBoard filtrado
  `launch-diagnostic-system.log`: **Resource validation Security-67056** leyendo
  nib compilado. `security error -67056`: code has no resources but signature
  indicates they must be present. Se descarta hipótesis de simple caché anterior.
- Misma copia diagnóstica, `codesign --force --sign - --timestamp=none
  DerivedData/evidence/app-launch-branding/LaunchDiagnostic.app`: vídeo
  `signed-diagnostic-cold-launch.mp4` y contact sheet realmente abierta muestran
  LaunchScreen nativo correcto y transición a colección. No cambio de fuentes,
  targets, firma de dispositivo ni certificado/cuenta; instalación propia retirada.
- Usuario elige expresamente **No cambiar la firma**. CODE_SIGNING_ALLOWED=NO
  sigue intacto en app/tests. La captura con firma aislada es prueba diagnóstica,
  NO evidencia de funcionamiento de launch en builds habituales sin firmar.
  **Bloqueo de aceptación visual del LaunchScreen real en simulador vigente**;
  no declarar passing/accepted ni arreglar firma a espaldas del usuario.
- Usuario amplía alcance: reparar grupos como ronda previa PBX y forzar
  **Portrait/Light en Info.plist**, en Debug/Release. Spec original intacta;
  este addendum conserva nueva autorización y sustituye lo pendiente anterior.
- DeletePlant existía como grupo virtual raíz/name sin path con archivos
  SOURCE_ROOT, no symlink de filesystem. Ahora `Features/DeletePlant/Domain|Data`
  con path físico; DeletePlantTests pasa a grupo real PlantCareAITests.
  Grupo nuevo duplicado LaunchBrandingTests eliminado; nuevo test va también
  a PlantCareAITests. No mover fuentes ni alterar membership previo.
- Resolver PBX: **69 grupos físicos,161 refs existentes únicas/no symlinks**,
  todos PBXBuildFile previos/phases/membership intactos; solo dos nuevos
  buildfiles añadidos (storyboard/test). `group-resolution.json`.
- Xcode guardó/stageó assets, agregó workspace y reserializó Localizable
  incluyendo stale de extracción de deletePlant durante la sesión. No revertir
  trabajo externo ni deshacer staging. No se alegan como cambios solicitados
  de localización; contrastar traducciones/keys, conservar metadatos externos.
- Nueva focal tras PBX/Info/test changed: `portrait-light-focused.xcresult`,
  mismo comando/contexto/override serial; selección recursos2+empty1+stored
  relaunch1. Bundles nuevos y UI de arranque afectados requieren evidencia
  actualizada; no repetir fallback/detail-grid por simple cambio de rol.
  Resultado pendiente al escribir; Release actualizado pendiente.

### Resultado final focal Portrait/Light

- `portrait-light-focused.xcresult`: **4/4 Passed=2recursos+2UI**, cero
  fallos/skips/expectedFailures,13oct21:40–21:41 local. Debug Info.plist:
  `UISupportedInterfaceOrientations=[UIInterfaceOrientationPortrait]`,
  `UIUserInterfaceStyle=Light`, `UILaunchStoryboardName=LaunchScreen`.
- Todas las keys/valores de localización previos exactos; cambios externos
  únicamente serialización/metadatos extractionState conservados, sin revert.
- Selección final deliberada por cambio transversal de configuración de
  ventana: dos recursos y dos arranques vacío/persistido; locale/detail-grid
  iniciales permanecen como evidencia de sus inputs pertinentes, no nueva
  ejecución ni fuenteconfiguración final alegada para el bundle inicial.
- Estado **blocked**, NO passing/accepted: listo artwork/config/grupos,
  bloqueo visual del launch real unsigned conocido y solución no autorizada.
  No gate completo mientras este bloqueo siga abierto, ni agente validator
  delegado en esta sesión. Sin stage/commit/push/PR/merge propios.
- Release final `portrait-light-release.log` **BUILD SUCCEEDED**; ambos bundles
  verifican Portrait/Light/AppIcon/LaunchScreen, Release sin keys sensibles.
  Preview final `portrait-light-attachments/E9A8D667-146E-469D-A75E-A94EB988266C.png`
  exportada y realmente abierta, mantiene diseño correcto.
- Verificación hash encontró PBX cambiado por guardado externo Xcode: no
  declarar fuente byte-exacta completa. AST esperado conserva todos objetos
  salvo delta planeado + Manual/teamvacío/profilevacío, cleanup grupo huérfano
  vacío y objectVersion77→71. `verify-final.py` pasa tras diagnosticar dos
  assertions estrictas de comparación (hash/objeto raíz), sin producto/tests
  reparados para ocultarlos ni tests repetidos. Fuente final189inputs,188
  ficheros ajenos aPBX exactos; `final-public-inputs.json`, `final-project-semantics.json`.
  Firma sigue NO: settings externos añadidos no activan firma ni requieren team.
  Metadatos de proyecto no cambian fuentes/callers/comportamiento probado,
  no nuevo rerun del gate/focal por esa serialización; full gate continúa pendiente.

## Nueva autorización: corrección SDK acotada (sucede BLOCK histórico)

- Usuario prevé cuenta Apple/provisioning/certificado futuros y autoriza adaptar
  lo necesario. Cambios SOLO app Debug/Release: valor general signingNO permanece,
  se añade `CODE_SIGNING_ALLOWED[sdk=iphonesimulator*]=YES` y
  `CODE_SIGN_IDENTITY[sdk=iphonesimulator*]="-"`.
- Ningún signing/provisioning/team de dispositivo ni testtargets modificado.
  No certificados/perfiles/entitlements/downloads nuevos ni codesign postbuild.
  Xcode produce la firma ad hoc como parte del build normal; futura provisión
  física separada según docs/testing-ui.md/CONSTRAINTS.md, sin identidad ad hoc.
- Scope/arquitectura/docs actualizados; spec original y negativos de firma previos
  intactos. Estado in_progress mientras se verifica seal/LaunchScreen auténtico.
- Mapa firma→riesgos→checks: Debug/Release builds y codesign verify real;
  hostunit→LaunchBrandingResourcesTests2; arranque/ventana→EmptyCollection1+
  StoredRelaunch1; vídeo producción real/sourcesfinales para visual.
- Build Debug `simulator-signing-debug-build.log`: mismo comando de build-for-testing
  previo sin flags signing externos; solo settings nuevos del app target. En curso.
  Release y focales pertinentes después, serial sin testprocesos competidores.
  Full gate reservado al validator, sin repeats/refirmaartefacto para green.

### Verificación de firma y visual del bundle normal

- Debug build-for-testing **TEST BUILD SUCCEEDED**, CodeSign app por Xcode con
  Signing Identity «Sign to Run Locally». `codesign --verify --strict --verbose=2
  DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app`: valid on disk,
  satisfies designated requirement. Display: Signature=adhoc, TeamIdentifier
  not set, Sealed Resources version2/files43; ya no es solo firma Mach-O de linker.
- AST antes/después: exactamente cuatro settings condicionales de SDK agregados,
  dos por configuración app; todos otros objetos/settings idénticos. Inputs189
  públicos en `simulator-signing-inputs.json`, antes/después sin cambios durante
  build/visual. No lectura/copia de config real ni signing manual del producto.
- Bundle Debug normal instalado sobre mismo bundleID de app habitual, arranque
  frío con UUID aislado y limpieza solo de ese UUID. Vídeo
  `simulator-signing-cold-launch.mp4`, comandos/exits completos
  `simulator-signing-visual-commands.json`. Contact sheet y frame11 realmente
  abiertos: icono instalado, LaunchScreen nativo legible durante animación iOS,
  fondo/halos/icono/PlantCare/AI/subtítulo correctos, transición a colección
  sin negro en secuencia observada. Sin tiempo mínimo artificial/splash SwiftUI.
- Focal cuatro escenarios con productos de ese build, `test-without-building`,
  mismo proyecto/scheme/DerivedData/destino serial/override; selectores de
  portrait-light-focused previos. Bundle `simulator-signing-focused.xcresult`,
  log `simulator-signing-focused.log`, resultado pendiente al escribir.
- Consulta READ-ONLY efectiva Release `-target PlantCareAI -sdk iphoneos
  -showBuildSettings -json`, proyectando SOLO6keys de signing/SDK en memoria:
  signingAllowedNO, identityAppleDevelopment(default), Manual, sin team/profile.
  `device-signing-settings-projection.json`. No build/test/dispositivo físico,
  no cuenta ni provisioning inferido; demuestra overrideSimulator no se extiende.
  Release simulador firmado pendiente, gate validator aún pendiente.

### Focal con firma SDK actual

- `simulator-signing-focused.xcresult`: **4/4 Passed=2recursosUIKit+2UIarranque**,
  cero failed/skipped/expectedFailures,13oct21:50–21:52 local, mismo
  iPhone17ProiOS26.2/23C54/normal/Light, sin concurrencia manual ni retries.
  Firma del host no impide XCTest ni colección vacía/persistida/relaunch.
- No cambios a init.sh/scheme/helpers/sourceSwift desde rondaPortrait;
  solo cuatro settingsSDK de app y docs. Evidencia anterior no se atribuye
  al bundle nuevo ni se suman escenarios duplicados a un total inflado.
- Pendiente únicamente build/sealRelease actual antes de declarar passing;
  gate independiente final sigue responsabilidad de validator.

### Cierre PASSING

- Release actual **BUILD SUCCEEDED**, `simulator-signing-release-build.log`;
  Xcode «Sign to Run Locally». `codesign --verify --strict --verbose=2` válido
  ambos modos; display Signatureadhoc/TeamIdentifiernotset/SealedResourcesv2,
  Debugfiles43/Releasefiles7. Ambos Info.plist Portrait/Light/LaunchScreen;
  `_CodeSignature/CodeResources` presentes, Release sin cinco keys puente.
- 189 inputs públicos `simulator-signing-inputs.json` byte-exactos tras build/test/
  visual/Release. Firma cambiada solamente por cuatro settingsSDK de app;
  instancia/provisioning/account/device/team/profile y targetsTests intactos.
  No modificaciones Swift/source ni membership desde ronda anterior.
- **passing**, listo para validator independiente, NO accepted. El bloqueo
  anterior de firma está resuelto por autorización posterior y evidencia real
  del bundle normal; fallos/rechazos antiguos se conservan como antecedentes.
  Validator debe ejecutar un único `./init.sh` final ambas fases y revisar
  firmaSDK/recursos/visual/docs; reutilizar focales/visuales de estas mismas
  fuentes, no reenviar API real ni iniciar features adyacentes.
- Futura cuentaApple: habilitar firma en iphoneos/equipo/perfiles/certificados
  apropiados cuando el usuario los aporte; no identityadhoc en device. Detalle
  en docs/testing-ui.md/CONSTRAINTS.md. Esa capacidad está fuera de esta feature,
  no bloquea aceptación de simulador y no se afirma probada.

## Recuperación ambiental autorizada tras primer validator BLOCK

- Usuario autoriza diagnóstico/recuperación y un nuevo gate final tras confirmar
  launcher operativo. V1exit65 y todos bundles/logs originales se conservan.
- Diagnóstico filtrado host `/usr/bin/log` ventana21:56–21:59 del UDID0A5D5C42…:
  clon creado→booted→shuttingDown→NoMatchingDevice404. SetXCTestDevices actual
  vacío y ese UUID sin directorio/plist. No inferir causa universal ni culpar
  signature/usuario/producto; no hay clon propio restante que borrar.
- Root17Pro00BBB7EC y ProMax estabanShutdown al inicio; preflight sin tests.
  Única recuperación: boot/bootstatus root, sin erase/reset/globalservicekill
  ni tocar ProMax/datos. Selector init Booted-first elige00BBB7EC. Artefactos
  `recovery/boot-and-selector.json`, `missing-clone-check.json`, dos logs filtrados.
- 189 inputs públicos fuenteconfiguración idénticos antes de focal; no secretos
  ni configreal/xcuserdata leídos/copied. No modificación producto/tests/harness.
- Focal diagnóstica EXACTA interrumpida: `caffeinate -dius xcodebuild -project
  PlantCareAI.xcodeproj -scheme PlantCareAI -destination
  'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886'
  -derivedDataPath DerivedData -parallel-testing-enabled YES
  -parallel-testing-worker-count 5 -maximum-concurrent-test-simulator-destinations 5
  -only-testing:PlantCareAIUITests/LocalizationUITests/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys
  -resultBundlePath DerivedData/evidence/app-launch-branding/recovery/interrupted-launcher.xcresult
  test-without-building`, log `recovery/interrupted-launcher.log`, en curso.
- XCTest crea su clon nuevo; no workers manuales/modelos/matrices adicionales.
  Esta focal comprueba launcher/escenario perdido, no valida todo el gate ni
  repite las unitarias verdes. Tras resolución, validator independiente podrá
  usar autorización del nuevo gate único; evidencia V1 nunca verde ni borrada.

### Diagnóstico focal completado

- Resultado original `recovery/interrupted-launcher.xcresult`: **1/1 Passed**,
  cero failed/skipped/expectedFailures; TEST EXECUTE SUCCEEDED. Console identifica
  Clone1 nuevo y runner47612; escenario33.950s. No UIassertions debilitadas.
- 189 inputs públicos exactos antes/después de recuperación/focal (`public-inputs-
  before/after-focused.json`). No producto/test/harness/entorno global modificado.
- Esto demuestra launcher/escenario afectado operativo, no equivalencia del
  gate completo ni garantía de cinco clones simultáneos. Usuario autorizó V2
  gate independiente ambas fases por recuperación ambiental/no gate válido;
  sesión validator previa retoma para único intento nuevo, conserva V1fail.

## Diagnóstico posterior a BLOCK V2 (autorizado 2026-10-14)

- V2 completó388funcionales (296unit+92UI) pero registró rechazo extra del UI
  runner; ningún fallo de assertion funcional, PhotosNO. Informe original intacto.
- `RUN_DESTINATION_DEVICE_UDID` identifica Clone3F0BA1C1F… (device_identifier
  exterior del reporte es root común, no el clon efectivo). Host log filtrado
  muestracreated/booted y rechazoBusy con PID0 antes de comenzar tests.
  `recovery-v2/runner-preflight-system.log`; AMFI sin evidencia causal de defecto.
- Estado actual setXCTest vacío; root y ProMaxShutdown sin procesos tests activos.
  No delete/erase/globalservicekill ni resets de datos. Única recuperación boot/
  bootstatusroot00BBB7EC; selectorinit confirmado, ProMax permaneceShutdown.
- Hipótesis de preparación/concurrencia de lanzamiento del tercer clon. Mitigación
  acotada **TEST_WORKERS=1 por esta validación**, valor ya permitido1..5; default5
  del proyecto y init/scheme/source/coverage intactos. No se promete demostrar
  causa profunda ni validar cinco clones con prueba de un worker.
- Focal mínima del **launcher** afectado, no revalidación de sus assertions:
  CollectionLayoutUITests/testEmptyCollectionCenteredBelowFixedHeaderAndAddWorks,
  test-without-building en productosfinales, parallelYES/worker1/maxdestination1.
  Se usa el escenario corto existente porque el error de runner no tiene método
  de XCTest seleccionable; no crear test ficticio ni repetir388green para green.
  Comando exacto JSON/log/exit/xcresult `recovery-v2/single-worker-*`, en curso.
- 189inputs públicos exactos antes de esta focal, `recovery-v2/public-inputs-before.json`.
  Tras comprobar frontera, validator independiente podrá ejecutar único gateV3
  completo ambas fases con worker1, explicitando mitigación/entorno distinto;
  V1/V2 fallidos conservados. Ninguna reducción de suite/tests/timeouts/aserciones.

### Mitigación comprobada y handoff V3

- Focal original `recovery-v2/single-worker-launcher.xcresult` **1/1Passed/exit0**,
  cero failed/skipped/expectedFailures; Clone1runner58016, escenario14.843s.
  Fuente pública189inputs antes/después idéntica; producto/harness sin reparación.
- No evidencia de que cinco clones estén recuperados ni causa profunda demostrada:
  únicamente frontera de launcher operativa con un worker. ValorTEST_WORKERS=1
  permitido por init; se usa como mitigación temporal, no se edita default5.
- V3validator independiente ejecutará un único gate completo ambas fases con
  TEST_WORKERS=1 +overrideextracciónexterno+caffeinate, sin retries/iteraciones/
  baseline/focales adicionales. Misma suite/destino/normalLight, sin cobertura
  eliminada ni producto alterado; V1/V2 nunca se convierten en passing aggregate.
  Si V3falla, STOP con informe/evidencia, no nuevo gate automático.

## Aceptación independiente y entrega

- Validator **ACCEPT V3**, informe `docs/validations/app-launch-branding.md`.
  Gate completo original exit0,390Passed=296unit+92UI+2Photos, sin failures/skips/
  expectedFailures; ambas fases en `DerivedData/TestResults/20261014-000939-58441/`.
  TEST_WORKERS1mitigación/default5intacto, no cobertura retirada ni retries;
  V1/V2FAILED originales intactos. No garantía de estabilidad con cinco clones.
- Parent corrobora gate-exit/summaries388+2 y189inputs actuales byte-exactos,
  persiste `accepted` sin repetir tests, firma o visual. B1evidencia cerrado
  para fuentes/entornoV3; cuenta/certificado/provisioning/device futuros fuera scope.
- Commit/push/PR hacia main solicitados/autorizados por usuario. Conservar
  spec original/stagingexterno/catálogo metadata/sources; excluir config real,
  DerivedData/xcuserdata/credenciales. No merge ni auto-merge/force-push.
