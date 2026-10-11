# Validación independiente — save-plant

- **Verdict: accept**. Sin findings bloqueantes ni reparación requerida.
- Validator: openai/gpt-6.1-sol; skills feature-validator e ios-clean-mvvm. Fecha: 2026-10-11.
- Worktree exclusivo `save-plant`, rama `feature/save-plant`, base `f4473e33406bf4236c5382c65c2c0f5436ed30a8`, issue #26.
- Spec `docs/specs/save-plant.md` intacta SHA256 `b1da9160d037fa26aef29aace79398e01b25bb7c1a05b28d435c78fcb31fcd4e`. Autorización posterior del usuario habilita implementación; no se reescribe la spec histórica.
- `feature_list.json` permanece **passing**, no accepted. Padre persiste aceptación y entrega local; validator no stage/commit/push/PR/merge/GitHub ni otra feature.

## Gate final nuevo: ejecución única

CWD: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/save-plant/DerivedData/save-plant-public`.

```sh
caffeinate -dius ./init.sh > ../evidence/save-plant-validator/gate.log 2>&1
```

El wrapper registró fecha inicial/final y exit real. `init.sh` original ejecutó build, seed público de dos imágenes sintéticas para PhotosPicker y todas las pruebas unitarias/UI funcionales, seriales. No focalizadas adicionales, baseline, retries, iterations ni segunda ejecución del gate. Terminación del proceso ORIGINAL esperada por eventos macOS `kqueue/NOTE_EXIT` y notificación; los comandos de espera no lanzan tests.

- **BUILD SUCCEEDED / TEST SUCCEEDED, exit 0, 160/160 =125 unit +35 UI**, cero failures, skipped o expected failures.
- Wrapper: **19:21:48–20:05:35 +0200, 43m47s**. Sesión xcresult: 19:21:53.541–20:05:31.798, 43m38.257s. UI: 2575.869s, 35/35; todas las nuevas altas y regresiones incluidas.
- Xcode **26.2/17C52**, macOS **26.5.1/25F80**. Único iPhone17Pro iOS **26.2/23C54**, arm64, UDID `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, normal/light. Único iPhone booted verificado al arrancar; sin xcodebuild previo activo ni pruebas simultáneas.
- Bundle original: `DerivedData/save-plant-public/DerivedData/Logs/Test/Test-PlantCareAI-2026.10.11_19-21-53-+0200.xcresult`.
- Copia archivada fuera de rotación: `DerivedData/evidence/save-plant-validator/gate.xcresult`.
- Log/exit/start/end/summary/test tree: `DerivedData/evidence/save-plant-validator/gate.log`, `gate.exit`, `gate-start.txt`, `gate-end.txt`, `gate-summary.json`, `gate-tests.json`.
- Extracción independiente real: `xcrun xcresulttool get test-results summary --path DerivedData/evidence/save-plant-validator/gate.xcresult` y equivalente `tests`; no tests nuevos por extracción.

## Fuente, configuración y evidencia reutilizada

Antes del gate se contrastaron cada hash de **98 inputs públicos** root y sandbox, soporte init/seed y los hashes de summaries. Después del gate los98 continúan idénticos (`source-after.json`, diferencias vacías). No cambios ejecutables posteriores.

- Manifest `delivery-source-hashes.json`: SHA256 `fe6de5e8f97509825a6c48a5281fc1b91e6d0c263f0bab99788ff8f0c0c0e1d7`.
- `evidence-hashes.json`: SHA256 `823398fd0a6ba0d3c0bc77ccbf7a9bbd555703a275364eaa56bdc212860ee6d0`.
- Soporte `init.sh` SHA256 `aef891405f810deaeccaae915147367ce3cd3f78bd1285270e5c4d8e6f357b95`, seed SHA256 `ef8295193e3a705e94324b96c96870e92556d037309165a7644c5d9df24e8e79`.
- Solo config pública vacía: fichero obligatorio del sandbox comparado byte a byte con `.example`. Config privada root y xcuserdata NO leídos/copied/modificados; ningún envío API real por validator.

Focalizadas **88 distintas =68 unit+20 UI** corroboradas/reutilizadas, no duplicadas por confianza/rol. Se extrajeron de sus bundles reales los summaries finales14/14, VMoffline3/3, related19/19, dismiss1/1, errorVisual2/2, exactLong1/1 y los fallidos unit63/64/commit0/1; todos coinciden con exports originales (`reused-bundle-corroboration.json`). El cómputo sin duplicar y los comandos/selectores/intervalos originales están en `docs/handoffs/save-plant.md`, §§22–56: 11 cache-repair +3 offline +54 individuales pertinentes de unit-build-repair; UI16 related +2 errorVisual +1 dismiss +1 exactLong. Los54 éxitos individuales históricos no convierten el agregado FAILED63/64 en gate aprobado.

Fallos históricos permanecen: preparación exit1, missing plist/build65, escaping wait/build65, JPEG truncado tolerado/FAILED63/64, final-unit interrumpida73 por doble retenido, UInew FAILED2/3 y commit FAILED0/1. SOI/EOI, liberación del doble y espera de sheet tras commit están en fuentes finales y pasan ahora en gate nuevo. Ningún agregado fallido relabelled/reintentado sin cambio para obtener verde.

Release existente reutilizado, **no rebuild**: comando original `caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedDataRelease CODE_SIGNING_ALLOWED=NO build`, BUILD SUCCEEDED, log/audit en `DerivedData/evidence/save-plant/release.log` y `release-audit.log`. Validador corroboró plist sin claves Identification config y `strings`/`nm` sin nuevos tipos/seams ejecutables/flags. Último delta afecta fixture1000 completamente bajo DEBUG y assertion UI, no producción Release. Una assertion exploratoria excesivamente amplia sobre bytes crudos del binario falló por aparición del nombre fuera de strings/símbolos; diagnóstico preservado en `release-corroboration.txt`, no presentado como fallo de build/producto ni ocultado. Auditoría documentada strings/nm pasó.

Estáticos nuevos: `git diff --check`, `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, parse JSON de feature_list/catalog, `bash -n init.sh`, `xcrun swiftc -typecheck $(find PlantCareAI/Features -path '*/Domain/*.swift' -type f)` Foundation-only y SHA256 spec: correctos. No cambios de init/shared scheme/config pública ni dependencias.

## Ocho escenarios / contratos

| Escenario | Revisión y comprobación |
| --- | --- |
| 1 Selección / alta IA | Selección sola no genera/guarda; guards busy/saved excluyen doble confirmación. Care completada congela snapshot y ejecuta alta, callback/listado/dismiss, sin review/formulario/segundo CTA. Nueva UI alternativa y alta principal pasan. Review retirada del source/target: ausencia no depende de capturar un frame. |
| 2 Manual / datos iniciales | Misma cadena, trim humano, blanco rechazado/2000 antes de red; mapping común/científico exacto, nil location. Tests Domain y UI IA/manual pasan. |
| 3 Integridad | GenerateCareSheet valida seis textos y snapshot vuelve a validar; photoID/token/identity vigentes. JSON/rechazo/truncamiento/incompleta son error, no alta parcial. Nuevas unitarias y UI incomplete pasan. No certificación botánica. |
| 4 Consentimiento / remoto | Barrera v4 y snapshot de configuración preservados; rechazo/cancel/error no guarda. Retry explícito textual sin reidentificar/JPEG; éxito guarda. Regresiones de consentimiento, errores y cancelación pasan. |
| 5 Fallo local | beforeCommit real revierte metadata/JPEG; snapshot mismo UUID/fecha/bytes. Retry sin IA aun con API config inválida; editar oculta y cancelar restaura sin IO. Tests real rollback, VMoffline y UIlocal pasan. |
| 6 Cancelación / commit | Validador fuera de MainActor cancelable. willCommit MainActor comprueba token/cancel/photo/identity y bloquea close/gesto/cambios antes de despacho. No guard cancel posterior que oculte commit exitoso. Dobles suspendidos, UIcommit/relaunch pasan. |
| 7 Duplicados | UUID por nueva intención, busy/saved/callback una vez. duplicateID se acepta SOLO si Plant completo y JPEG exactamente coinciden; conflicto arroja error sin overwrite/UUID alternativo. Tests reconciliación/conflicto y doble confirm/retry pasan. |
| 8 Colección / aislamiento | Mismo escritor App, callback previo al dismiss, sort createdAt/UUID, invalidación metadata antigua y conservación de tarjetas/cache. Si loading/failed se relee completo y muestra error de lectura, no lista parcial. Dos mismas especies/fotos distintas/relaunch/previas/edición y1000 completos por scroll pasan; bytes propios además verificados por integración real. |

## Arquitectura, scope y seguridad

Flujo conforme `View → IdentificationPhotoViewModel → SaveConfirmedPlant → PreparedPlantPhotoValidating + SavePlant → PlantRepository ← LocalPlantRepository`, composición App tras overrides. Domain Foundation-only, Data ImageIO detached, Presentation navegación/estado, ContentView intacta. No segunda compresión, reimportación, esquema nuevo, procedencia persistida ficticia, historial, backend, cuenta, sincronización u otra feature. El desempate del repositorio es estrecho y consistente con colección. Protocol nuevo representa frontera real de validación media, no abstracción gratuita.

Checklist seguridad aplicada al diff y soporte: sin findings relevantes bloqueantes. JPEG actual acotado ≤5MiB/2048, dimensiones y decode/integridad/metadata EXIF-GPS-orientation comprobadas antes de IO; ruta local por UUID, sin nombre controlando rutas. Nombres/campos validados, datos no confiables del prompt siguen text-only sin almacenamiento/fotos extra. No nuevos servicios/URLs/auth/dependencias/logs de fotos, payloads o credenciales. Usuario único local sin autorización multiusuario aplicable. Riesgos residuales: clave Debug extraíble; originales picker/UIImage pueden materializarse completos; daños físicos/exact-once multiproceso/retención remota y precisión botánica no garantizados. API real previa atribuida al usuario no se reivindica como prueba de esta alta; aquí se prueba nueva persistencia real aislada y composición con transporte existente, sin nuevo contrato remoto que exija otro envío.

## Inspección visual realmente realizada

Se reutilizaron y abrieron independientemente seis PNG bajo `DerivedData/evidence/save-plant/`:

- `ui-error-visual-attachments/AB87DCDA-E9C4-4071-B807-9830D38107A0.png`: foto, especie/error local, retry blanco/verde y cambio.
- `ui-error-visual-attachments/0148909A-BD36-4A3C-8604-CD71B6C4B23A.png`: error ficha incompleta, retry remoto y foto.
- `ui-related-attachments/C28C3895-02DA-4BB1-960E-35C4D7DB2AED.png`: dos tarjetas/identidades/fotos distintas, retorno colección.
- `ui-exact-long-attachments/D65AD746-600C-4D94-A5AE-161717540812.png`: detalle largo/Abonado desplazable; exact1000 además probado por assertion antes/después de relaunch.
- `ui-dismiss-repair-attachments/0CA00A66-CC0D-4F53-91A0-B82F3C68CAF0.png`: Cancelar/foto actions bloqueadas al commit; progress queda encima del viewport y no se afirma visto en esta captura.
- `ui-dismiss-repair-attachments/BAA7268E-D6FD-4F38-A2B8-E1697E9365FD.png`: foto/Generando cuidados/cancelación visible.

Controles/textos/contraste conformes en normal/light; counter overlay es instrumental opt-in Debug, no UI de producto. No recorrido manual interactivo adicional ni capturas nuevas del gate atribuidas. SE/texto aumentado/VoiceOver/matrices/cámara física/iCloud fuera de habitual, no ejecutados ni bloqueos.

## Documentación / findings

ADR007, arquitectura de alta, restricciones operativas, DESIGN, brief/dominio/risks/testing/handoff reflejan delta autorizado y conservan evidencias/specs históricas. Gate ejecutable intacto y funcional; passing correctamente significa autoverificación.

**Nota Low, no bloqueante:** introducción bajo decisión histórica 2026-10-09 de ARCHITECTURE aún dice «no alta desde UI»; la sección explícita ADR007 posterior y brief vigente dejan claro el contrato nuevo. Las notas de feature_list conservan prose fechada del planner/not_started aunque status real es passing. Recomendación editorial al padre: aclarar ese resumen actual/notas sin alterar spec ni historia. No se requiere código, test ni nuevo gate por esa aclaración documental.

## Handoff / cómo probar

No repair brief requerido. Parent puede persistir accepted y commit local autorizado incluyendo spec intacta y cambios; sin push/PR/merge.

Manual (por usuario, con su configuración privada/autorización): Añadir → foto → Identificar/aviso → seleccionar alternativa o manual → Confirmar especie. Debe volver directamente a Mis plantas con tarjeta, sin review/Guardar/formulario; abrir detalle y comprobar seis cuidados/foto/fecha. Repetir misma especie y foto distinta, editar después nombre/ubicación, cerrar/reabrir sin reseed y comprobar ambos ejemplares/previas. Error remoto retry explícito; fixture local error permite retry sin llamadas IA; commit bloquea cierre. Guía completa `docs/testing-save-plant.md`. No compartir Debug con clave.

Validator solo añadió este informe y entrada PROGRESS (artefactos ignorados aparte); no producto/tests/harness/spec/feature_list/config modificados.
