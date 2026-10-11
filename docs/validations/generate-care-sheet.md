# Validación independiente — generate-care-sheet

Fecha: 2026-10-11. Validator: openai/gpt-6.1-sol; skills feature-validator + ios-clean-mvvm. **Verdict: block** (evidencia real requerida ausente); además **H1 requiere reparación/diagnóstico** del gate y D1 corrección documental. No aceptación ni autorización de commit de entrega todavía.

## Contrato y alcance

Spec `docs/specs/generate-care-sheet.md` aprobada íntegra, SHA256 `86a52855ea0788238bda08e142c2ec13b3bf3e6f9c7e0cabc9a10ae08c974eee`, contrastado antes/después sin cambios. Rama `feature/generate-care-sheet`, base del handoff `8b0022d8049d8ac300820f5cfe2c6a542f69a54f`. Estado entregado `passing` significa autoverificación, no aceptación. Revisión de diff, nuevas fuentes y callers, spec, AGENTS, CONTEXT, ARCHITECTURE, CONSTRAINTS, DESIGN, brief/domain/risks, ADR006, testing/handoff y evidencia.

Producto revisado conforme en código: ambas confirmaciones inician directamente cuidados sin resumen/CTA intermedio; seis campos validados, nombres mínimos como datos no confiables, ficha efímera y ninguna alta/IO/esquema nuevo. Selección no envía; edición/cancelación conserva ficha anterior y reconfirmación crea intención nueva. Tokens/foto/identidad/configuración protegen publicación obsoleta; busy/cancel/retry explícito. Presentation → Domain ← Data, composición App y mismo snapshot, sin adaptadores en vistas/Domain. Scope v4/notice-4, no hereda v3 y cada operación cruza autorización. Cuatro E2E nuevos y regresiones adaptadas sin debilitar identidad, geometría, selección ni aislamiento. No reparación implementada por validator.

## Ejecución final nueva — FALLIDA, no passing

Única ejecución del gate, sin baseline completo ni focalizadas duplicadas:

```sh
# cwd: DerivedData/care-validator-public
caffeinate -dius ./init.sh > ../evidence/care-validator/gate.log 2>&1
# exit conservado: 65
```

`init.sh` intacto ejecutó build, seed de dos fotos sintéticas y todos los tests sin parallel/retries configurados. **BUILD SUCCEEDED / TEST FAILED: 145/146, 114/114 unit y 31/32 UI, una failure, cero skipped/expected failures.** Xcode26.2/17C52, macOS26.5.1; único iPhone17Pro iOS26.2/23C54 `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, texto normal/una apariencia light, serial/caffeinate. Sesión tests 15:33:20–16:11:33 +0200. Ningún competidor xcodebuild al arranque; final recibido por notificación original y espera única NOTE_EXIT, sin polling ni rerun.

Artefactos ignorados `DerivedData/evidence/care-validator/{gate.log,gate.exit,gate-summary.json,gate-tests.json,gate.xcresult,failed-activities.json,failed-attachments/,failure-frame-*.png,sources-before.json,sources-after.json,static-review.txt}`. Bundle original `DerivedData/care-validator-public/DerivedData/Logs/Test/Test-PlantCareAI-2026.10.11_15-33-20-+0200.xcresult` archivado como gate.xcresult fuera de rotación. Export diagnóstico local conserva contenido histórico del simulador; no debe publicarse ni interpretarse como evidencia de esta feature. Solo log runner pertinente y listado de informes examinados, no configuración privada.

Preparación: nuevo sandbox exclusivamente mediante 93 rutas públicas del delivery manifest, bytes root=delivery=implementer sandbox=validator sandbox al arrancar. Config creada únicamente desde `.example` pública vacía y plist puente público; sin lectura/copia de real ni xcuserdata, sin solicitudes reales. Hashes de las 93 entradas **del sandbox probado** intactos al terminar. La raíz presenta deriva posterior del catálogo: metadata extractionState/serialización y una clave vacía `Care invocations: %@`; equivalencia semántica contrastada ignorando metadata y esa clave instrumentada, ninguna traducción/locale cambiada. Otros 92 hashes root intactos. No atribuir igualdad byte-a-byte de raíz final al gate ni restaurar silenciosamente catálogo ajeno. Fuentes finales de reparación requerirán nuevo manifiesto.

Estáticos nuevos: parse Swift 15 archivos, plutil proyecto, JSON catálogo/feature list, bash -n init y git diff --check correctos; spec hash intacto. Release revisado por guards/proyecto (fixture solo DEBUG Simulator, localDemo indisponible y sin config/puente en Release); **no build Release ni audit binario nuevo ejecutados**.

## Evidencia focalizada corroborada, no repetida

`xcresulttool get test-results summary` sobre cuatro bundles originales concuerda con summaries guardados: unit-repair62/62, final-careVM7/7, initialUI11/12 FAILED y finalUI6/6. Handoff explica 64 unit +12 UI distintas por sustitución/reutilización pertinente, no suma de ejecuciones. Fallos de preparación/build/helper anteriores permanecen históricos y fallidos. Las cuatro care UI nuevas pasan individualmente también en el gate final, pero 145 éxitos individuales no convierten su agregado fallido en un gate válido.

Inspección visual independiente de capturas reales existentes, estados relevantes sin cambios: waiting C87A1ED7, manual DF371A7D, seis campos BF0F9248, Abonado largo3410A8A8, aviso combinado6097D2C5 y error final/retry blanco5E5FA005. Identidad/procedencia, orientación, scroll y acciones legibles, sin resumen/alta artificial. No interacción manual adicional declarada. Frames nuevos del fallo examinados aparte. Matrices ampliadas, cámara física y VoiceOver fuera de verificación habitual, no ejecutadas.

## Findings y acciones

### H1 — Gate final falla antes de preparar la foto

- **Severity: High.** `gate-summary.json`: `testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry()` falla «Failed to application org.plantcareai.prototype is not running»; gate.log15570–15734.
- Evidencia: primera preparación, foto todavía ausente/counters0. `prepareConsentPhoto` llama `reveal(fixture-photo-A)` con swipeUp global; primer swipe t4.04, pérdida de monitor t4.57, helper continúa buscando fixture inexistente y swiping hasta t59–62. Vídeo exportado3213FCE4: frame3 sheet vacía, frame6 blanco, frames18/57 colección vacía sin sheet. El flujo no llegó a HTTP ni a cuidados. No informe PlantCareAI crash identificado en diagnóstico exportado; **causa raíz todavía no acreditada**, no afirmar defecto de cuidados, crash, dismiss voluntario o transitoriedad sin prueba.
- Importancia: regresión ejecutable obligatoria sin evidencia final válida; anteriores éxitos focalizados no anulan este fallo.
- Required change: diagnosticar pérdida de sheet/proceso en esa preparación y corregir causa demostrada (producto o harness), manteniendo todos los modos y assertions. No usar reruns/retries para verde.
- Pasos: inspeccionar vídeo/snapshots/actividades y ciclo de proceso del bundle; contrastar si swipe global/captura de elemento y geometría o terminación externa explican el fallo. Si es harness, acotar gesto a contenido con guard de existencia de navegación/target, sin seguir swiping cuando desaparece sheet. Si es producto/proceso, reparar solo causa acreditada. Conservar este gate fallido y registrar hipótesis antes de cualquier repetición diagnóstica.
- Verification after fix: primero solo `-only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry`, mismo entorno público. Luego callers directamente afectados por helper si se cambia. Tras cambio ejecutable, validator ejecuta nuevo gate único porque cambia el estado de fuentes/tests y el gate anterior es fallido; exigir 146/146 (o total legítimamente aumentado), cero failures/skips. No suite completa nueva solo por confianza sin reparación justificada.

### B1 — Falta prueba real de cuidados por usuario

- **Severity: High; bloqueo externo de aceptación.** Spec191–195 exige prueba real por usuario, no sustituible por sintéticos. Handoff38/68 y testing documentan pendiente; no evidencia nueva suministrada a este validator.
- Importancia: no acreditados compatibilidad de Chat Completions textual/JSON, seis campos/budget reales ni fallo/reintento del proveedor. La evidencia de identificación histórica no prueba esta operación nueva.
- Required change: usuario ejecuta con su configuración privada y nombres/fotos autorizados: vía candidata/alternativa y vía nombre manual, aviso v4, seis cuidados completos, error/reintento explícito con foto/identidad conservadas, sin alta. Registrar resultado fechado, modelo/destino no sensible, pasos y limitaciones, atribuido al usuario; no requerir clave ni respuesta cruda.
- Pasos: padre solicita ese escenario según docs/testing-generate-care-sheet.md; usuario lo ejecuta localmente; persistir resumen sanitizado y entregar a validator. Agentes no leen/copian key/config ni realizan envíos por iniciativa propia. No cambiar spec/contrato para aceptar.
- Verification after fix: contrastar relato/evidencia con escenarios y adaptación; cerrar B1 solamente si cubiertos, sin repetir gate válido por añadido documental.

### D1 — Riesgos durables mezclan antecedentes con estado vigente

- **Severity: Medium.** `docs/risks-and-open-questions.md` sigue diciendo que identify-candidates está blocked/sin evidencia real y que aviso/alcance actual es v3; ARCHITECTURE párrafo Propuestas dice prueba real aún pendiente. Contradicen feature_list y docs/validations/identify-candidates.md (evidencia real del usuario y aceptación), y v4 de esta slice.
- Importancia: siguiente sesión puede pedir secretos/envíos innecesarios o confundir bloqueo nuevo de cuidados con identificación aceptada. Spec92/155 pide aclarar estado real sin arrastrar bloqueos históricos.
- Required change: en docs durables distinguir explícitamente aceptación/evidencia histórica de identificación de **cuidados reales aún pendientes**, y scope vigente v4. Mantener riesgos de proveedor/botánica y necesidad de nueva prueba para otro destino/modelo.
- Pasos: corregir solo esos párrafos vigentes, citar aceptación histórica y ADR006; actualizar resultado fallido del gate de cuidados y siguiente paso. No alterar specs aprobadas ni informes/evidencias históricas.
- Verification after fix: revisión de coherencia/diff/hash, sin pruebas iOS por documentos solamente.

## Seguridad

Checklist aplicado al diff y dependencias directas: sin secretos nuevos, key únicamente Debug privada/extraíble y configuración trusted HTTPS, snapshot compartido con aviso/autorización; texto mínimo sin JPEG/UUID/colección, límites2000/1000 y ≤1MiB, parseo estructural estricto, refusals/truncamiento/error sin ficha parcial; mensajes separados para nombres no confiables. Sesión efímera sin cache/cookies/credentials, timeout acotado, delegate bloquea redirects, no retries/logs crudos. Sin nueva persistencia, dependencia externa, cuentas o backend. **Sin finding explotable nuevo relevante**; límites remotos/calidad botánica/coste no acreditados y Debug no distribuible siguen riesgos conocidos, no garantías de producción.

## Implementation Repair Brief

Goal: cerrar H1 y D1, obtener B1 sin ampliar alcance ni autorización externa.

1. Diagnosticar el primer swipe/preparación del caso H1 con los artefactos preservados; escribir hipótesis y reparar exclusivamente causa demostrada, sin eliminar modos/assertions o tolerar desaparición inesperada.
2. Preparar manifiesto público final y plantilla vacía; probar primero el caso H1, después callers afectados según diff. No retries/iteraciones automáticas ni repetir por confianza.
3. Corregir documentación D1 y evidenciar cambios/comandos/resultados en PROGRESS/feature_list/handoff, sin reescribir historia. Registrar catálogo derivado final honestamente.
4. En paralelo, padre pide al usuario prueba B1; registrar resumen sanitizado sin claves/build Debug ni logs crudos. No implementar save-plant.
5. Entregar a validator independiente reparación y evidencia; nuevo gate solo tras reparación ejecutable que invalida fuentes anteriores, seguido de revisión de B1/D1. Hasta entonces no accepted ni commit de entrega posterior a aceptación.

Forma de prueba focalizada (sandbox público, bundle nuevo):

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
 -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
 -derivedDataPath DerivedData -resultBundlePath focused-H1.xcresult \
 -parallel-testing-enabled NO \
 -only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry test
```

## Handoff

Estado recomendado al padre: aceptación **bloqueada por B1**, reparación H1/D1 pendiente; conservar `passing` únicamente como claim histórico de autoverificación, no afirmar nuevo gate passing. No estado accepted ni transición de feature_list realizada por validator. Informe y PROGRESS persistidos por petición explícita. Sin stage/commit/push/PR/merge ni producto/test/harness reparados; save-plant continúa not_started.

Comprobación final Git confirma rama/base anteriores. `git status` también muestra project.xcworkspace/xcuserdata nuevos en raíz al cierre; no inspeccionados, copiados ni eliminados por validator. Preservarlos y excluir datos personales de cualquier entrega local del padre. Deriva de catálogo/artefactos raíz observada, origen no atribuido.
