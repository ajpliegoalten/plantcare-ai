# Veredicto vigente — accept

Validación independiente final, 2026-10-10, `identify-candidates`. **D1 documental y B1 de evidencia real cerrados.** Aceptación de la feature conforme a spec original y modificaciones posteriores expresamente autorizadas (configuración split y único adaptador genérico). No se certifica precisión botánica, fiabilidad del servicio al 100%, seguridad comercial ni compatibilidad de cualquier API. Informes anteriores se conservan históricos.

## Cierre B1: pruebas reales reportadas por el usuario

El orquestador transmite confirmaciones concretas del usuario, admitidas como evidencia humana, **no como pruebas ejecutadas por validator**:

- OpenAI, modelo de app `gpt-4.1-mini`, sin fixtures y aviso aceptado: **Sí**, en respuesta a la aclaración del aviso v3/entorno real.
- Planta real: captura anteriormente descrita con foto, propuesta `Ficus elastica`, alternativas `Ficus robusta`/`Ficus rubiginosa`, incertidumbre y texto de propuesta no confirmada; usuario confirma que esta feature no selecciona candidata. No inspeccioné nuevamente esa captura ni infiero exactitud de nombres.
- Cancelar solicitud conserva la foto: confirmado por usuario.
- Reintento tras error del servicio sin volver a subir la foto: **Sí**.
- Última confirmación literal: «Error del servicio → permite reintentar. -> Si / Imagen sin planta → muestra “No hay evidencia suficiente”, sin candidata. -> Si».

Esta confirmación concreta cubre la aclaración que impedía cerrar el caso real insuficiente y la recuperación del error. No se sigue afirmando ausencia de acceso/pruebas reales. El curl 200 de texto previo **no** se usa como prueba de visión; el caso real de planta/insuficiencia es evidencia humana de la app. Los 401/403/fallos intermitentes previos siguen registrados: **no** se afirma su desaparición ni causa diagnosticada. Se confirmó comportamiento recuperable; fallos externos recuperables no incumplen por sí solos la spec. No exigir nueva inferencia solo para duplicar evidencia suficiente.

## Comprobaciones independientes y atribución

- Revisión previa independiente de capas/composición, seguridad scoped/consentimiento v3/configuración/contrato genérico y pruebas conservada. Sin hallazgos de código bloqueantes identificados. D1 arquitectura fue reparado y revalidado documentalmente.
- En esta sesión: raíz correcta, `git diff --check` correcto; releídas frases/contexto vigente de arquitectura, coherentes con único adaptador HTTPS/modelo configurable, key opcional y aviso v3. SHA256 spec intacto `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`.
- Comparación propia actual de **67 archivos públicos** contra sandbox anteriormente probado: cero diferencias. Se revisaron fuentes/app/unit/UI, catálogo/proyecto/shared scheme, plantilla pública/plist puente, init/script; no configuración real ni userdata. No nuevos cambios de implementación que requieran rerun.
- Gate **94/94 (74 unit + 20 UI)** y focused **28/28 (24 unit + 4 UI)**, cero fallos/omitidas: ejecuciones del implementer en sandbox sin secretos, cuyos bundles fueron contrastados directamente con xcresulttool por validator en revisión anterior; summaries nuevamente consultados, sin atribuir nuevos tests. Auditoría propia previa del producto Release sandbox y static/typecheck/inspección de capturas controladas siguen válidos para mismas fuentes.
- **No** gate/build/tests/runtime/API nuevos ni envío de fotos/red, lectura/impresión/modificación de configuración/clave/productos reales/xcuserdata, edición de código/spec, stage/commit/push/PR/GitHub. Evidencia humana concreta más revisión/evidencia determinista independiente bastan; no se inventa ejecución propia de API.

## Evaluación final y límites

Resultado solo lectura, sin confirmar/seleccionar/guardar plantas; incertidumbre e insuficiencia legibles. Consentimiento v3 liga destino/modelo al mismo snapshot de transporte, renueva v1/v2 y cambios de destino/modelo; no autoenvíos ni redirects/retries/fallback. HTTPS/modelo genéricos no garantizan identidad legal/retención/subprocesadores ni capacidades de otros servicios. Cambios posteriores autorizados documentados fuera de spec intacta; reparación D1 resuelta. Harness/doc/handoff suficientes, evidencia histórica conservada y atribución explícita.

Riesgos residuales: alucinaciones/incertidumbre no calibrada; intermitencia del servicio sin causa diagnosticada; cancelación no retira bytes/coste ya transmitidos; memoria proporcional/base64/JSON y varias copias; clave Debug extraíble y productos privados; UserDefaults no transacción de disco; operador/retención/procesadores/coste remoto no certificados; otros destinos/modelos requieren comprobación propia, no heredan visión acreditada de estos escenarios. Ninguno exige feature extra ni bloquea aceptación del alcance actual.

No pruebas de cámara/dispositivo físico, fiabilidad longitudinal, ampliaciones SE/Dynamic Type/VoiceOver/matrices, nuevas garantías legales ni API por validator. Ampliaciones fuera de habitual, no bloqueos automáticos.

## Handoff al main

- **Validator devuelve accept; main persiste estado.** Feature_list permanece `blocked` en este rol por instrucción expresa; main puede registrar transición `passing` → `accepted` con evidencia humana real y revisión independiente transparentes. No describir 94/94 como gate propio del validator ni API como ejecución automatizada.
- Main puede continuar commit/publicación previamente autorizados **sin merge**, fuera de este rol. Excluir configuración real, userdata y artefactos; preservar spec original y documentación/evidencias sanitizadas. No leer/publicar claves ni logs reales sensibles para preparar entrega.
- No otra reparación pendiente ni prueba extra requerida para esta aceptación. Si cambia código, realizar regresiones pertinentes y revalidar cambios; para gate futuro con real posiblemente sensible, usar sandbox seguro descrito en `docs/testing-identify-candidates.md`, no sobrescribir real existente.
- Comandos manuales de referencia, **no ejecutados aquí**: en sandbox sin secretos `caffeinate -dius ./init.sh`; auditoría `python3 scripts/verify-identification-config.py <Release-sandbox.app> --release`. Para demo privada solo por usuario autorizado: script `<Debug-privado.app>` (entrada de clave oculta), `xcrun simctl install <UDID-estandar> <Debug-privado.app>` y `xcrun simctl launch <UDID-estandar> org.plantcareai.prototype` sin flags fixture/spy; no adjuntar esos productos/logs con clave. No repetir API por este handoff.

---

## Revalidación anterior histórica — block por aclaraciones (B1 ahora cerrado)

# Veredicto vigente — block: aclaración mínima de pruebas reales humanas

Revalidación independiente 2026-10-10 tras declaración del usuario: **«He estado realizando pruebas reales y le doy mi accept de pruebas reales»**. Se admite como aceptación humana general reportada, **no como ejecución del validator ni detalle implícito de todos los escenarios**. No acepto todavía la feature completa: B1 queda acotado a evidencia concreta pendiente, ya no a una afirmación general de ausencia de acceso/pruebas reales. D1 permanece resuelto; sin reparación nueva de código identificada.

## Evidencia humana admitida (contexto transmitido por orquestador)

- Curl a OpenAI con `gpt-4.1-mini`: 200 OK **solo texto**, no acredita visión ni ejecución desde app.
- Request de app reportado a `https://api.openai.com/v1/chat/completions`, cuerpo con JPEG y tamaño reportado 178204; clave ocultada por usuario. No leí petición/body/headers/clave/logs/productos reales. Modelo efectivo de la petición de app no quedó identificado inequívocamente en este contexto; no heredo automáticamente el del curl.
- Reportados 401/403 previos y después 200 con decode; fallos intermitentes sin causa diagnosticada. No demuestra defecto de código, pero tampoco permite afirmar que desaparecieron o que todos se recuperaron correctamente.
- Captura posterior **descrita en conversación**, no reabierta ni inspeccionada directamente por este validator: foto de planta, propuesta `Ficus elastica`, alternativas `Ficus robusta`/`Ficus rubiginosa`, incertidumbre y aviso de propuesta no confirmada. Aporta evidencia humana de resultado visible de planta; no prueba precisión botánica, insuficiencia, aviso v3 ni ausencia de fixtures/breakpoints por sí sola. Usuario confirma que no hay selección, conforme al alcance.
- Se explicaron al usuario pruebas manuales reales de planta, insuficiente/no vegetal, cancelación y revisión de intermitencia; después concede su accept general. Esa secuencia es favorable, pero la frase no enumera resultados y no autoriza al validator a inventarlos. **No se rechaza evidencia humana por no haberla ejecutado el validator:** una confirmación concreta/sanitizada puede bastar para cerrar el vacío sin nuevas llamadas nuestras.

## Comprobaciones propias y evidencia reutilizada

Confirmados raíz/estado, diff check correcto y spec hash intacto `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`. Comparación propia actual de 67 archivos públicos con sandbox anterior: cero diferencias (fuentes Swift/app/unit/UI, catálogo/proyecto/shared scheme, plantilla pública/plist puente, init/script). No copié ni leí configuración real, userdata ni productos/logs reales. Feature_list sigue `blocked` y no se modificó.

Reutilizo revisión independiente previa de arquitectura/seguridad/consentimiento v3 y bundles deterministas previamente contrastados: gate implementer 94/94, focused 28/28, Release sandbox auditado. No nueva extracción/rerun/build/visual/runtime/API en esta sesión: el vacío es testimonial/específico, no se resuelve repitiendo dobles. D1 documental ya revalidado. Sin stage/commit/push/PR/GitHub ni edición de implementación/spec.

## B1 pendiente — resultado real insuficiente y alcance del test manual

- **Severidad High (evidencia requerida incompleta).** La spec Verification Plan exige foto real de planta **y** de evidencia insuficiente con API real; fixtures no sustituyen este requisito. Solo el resultado de planta está concretamente reportado. La aceptación humana general no dice qué ocurrió con la foto insuficiente/no vegetal.
- Impacto: no se puede dar por probado que el servicio devolvió `insufficientEvidence`/mensaje prudente sin inventar candidata, en vez de error de auth/parseo o propuesta falsa. Tampoco se puede cerrar incertidumbre sobre entorno real, modelo efectivo y recuperación de errores reportados.
- Cambio requerido: **aclaración mínima por usuario/orquestador**, no implementar cambios ni solicitar clave/fotos/logs sensibles. Registrar como evidencia humana explícita los resultados concretos. Si no se ejecutó el caso insuficiente, reconocerlo y completar manualmente con foto autorizada bajo aviso, no sustituirlo por test controlado.
- Verificación tras aclaración: confirmar foto planta y foto insuficiente reales con servicio/modelo identificado, resultado prudente válido de insuficiencia (sin candidata/porcentajes ni confundirse con error), entorno sin fixture/spy y aceptación de aviso v3. Respecto a intermitencia, indicar si persiste y si errores mantienen foto/reintento explícito sin publicar resultados incorrectos; no exigir causa raíz de fallo externo para aceptar si comportamiento recuperable cumple contrato.

### Preguntas mínimas para cerrar B1

1. ¿Qué **modelo usó la app**, y confirmas que probaste sin fixtures/spy y tras aceptar el aviso v3 de ese destino/modelo?
2. ¿Probaste una foto insuficiente/no vegetal real? ¿Mostró **evidencia insuficiente sin candidata**, o error/propuesta? ¿Al cancelar se conservó la foto sin publicar resultado tardío? Basta describir resultados; no aportar foto/clave/log crudo.
3. ¿Los fallos intermitentes siguen ocurriendo? Cuando ocurrieron, ¿mostró error recuperable conservando foto y un reintento explícito permitió continuar, sin confirmación/guardado automático? No asumir desaparición ni atribuir causa aún no diagnosticada.

## Repair / Unblock Brief

Orquestador recoge esas respuestas breves y persiste evidencia humana sanitizada; no hacer API nosotros ni leer secretos. Si resultados satisfacen escenarios, entregar a validator para posible accept independiente sin repetir gate idéntico. Si caso faltó, usuario completa prueba autorizada; si hay fallo funcional concreto, abrir reparación scoped y regresiones pertinentes, no diagnosticar por conjetura. Mantener blocked hasta veredicto independiente, no accepted en feature_list ni commit/publish/PR por este rol. Autorización de publicación comunicada al main no elimina este gate.

**Resultado: block por aclaración de evidencia real, no revise de código ni negación del accept humano.** No se afirma falta actual de credencial/recursos ni incompatibilidad del servicio; sí falta acreditación concreta del escenario insuficiente. Riesgos/limitaciones previos de API/retención/modelo/cancelación/Debug extraíble siguen sin nuevas garantías. Verificación ampliada no solicitada fuera de habitual.

---

## Veredicto documental anterior histórico (antes de pruebas humanas reportadas)

# Veredicto vigente — block (D1 documental resuelto)

Revalidación independiente documental, 2026-10-10. **D1 resuelto; B1 API real permanece. No accept ni aceptación condicionada del código.** Los informes revise/block anteriores se conservan abajo como evidencia histórica.

- Comprobación propia: leídas las frases corregidas de `ARCHITECTURE.md:89,95` y su contexto. Ya describen un único adaptador OpenAI-compatible, HTTPS/modelo configurables sin perfiles, clave opcional, consentimiento v3 y demo Debug privada; coherentes con la autorización posterior y ADR 004/CONSTRAINTS/guía revisados previamente. No restaura whitelist ni atribuye operador legal por host.
- Contrastados registro de reparación en PROGRESS y handoff: cambio exclusivamente documental, sin declarar aceptación ni API real. `git diff --check` correcto. Spec hash propio intacto: `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`.
- No pruebas/build/runtime/API nuevos ni lectura/impresión/modificación de configuración secreta, productos reales o userdata; no edición de código/spec, stage/commit/push/GitHub. Evidencias 94/94 y 28/28 siguen siendo ejecuciones previas del implementer contrastadas en la revisión anterior, no ejecuciones de esta reparación.
- No otra reparación pendiente identificada en este alcance documental. Evaluación scoped de seguridad/consentimiento genérico de la revisión anterior se mantiene con sus límites; no es auditoría nueva de código ni aceptación completa.

**Único bloqueo vigente B1:** falta escenario API real autorizado/acreditado con destino/modelo elegido, acceso al servicio (clave solo si la exige) y dos fotos propias o autorizadas para ese destino: planta e insuficiencia. No se conoce contenido/validez de configuración real y no se presume autorización de envío. Ejecutar prueba privada sin fixture/spy bajo aviso v3, verificar roundtrip y registrar evidencia sanitizada; reparar incompatibilidades demostradas si aparecen y solicitar validación independiente posterior.

Mantener `identify-candidates` **blocked**, sin passing/accepted, commit ni siguiente feature antes de accept. D1 no requiere gate adicional: revisión documental/diff check bastan; B1 no se sustituye por dobles. Matrices ampliadas siguen fuera de verificación habitual.

---

## Revalidación anterior histórica — revise documental (D1 ahora resuelto)

# Revalidación independiente — adaptación OpenAI-compatible genérica

Fecha: 2026-10-10. **Veredicto actual: revise (documentación); bloqueo externo API real permanece.** No aceptación total, parcial ni condicionada del código. Mantener feature_list en `blocked` y detener entrega/feature siguiente hasta corrección y escenario real, seguidos de validación independiente. El informe inicial que sigue es histórico, no describe la configuración actual.

## Contrato revisado y límites de acceso

Usuario autoriza posteriormente un único adaptador OpenAI-compatible con HTTPS/modelo arbitrarios y clave opcional, sin whitelist DevExpert; ADR 004/PROGRESS documentan la sustitución de las restricciones originales. También consta autorización de configuración split única. Spec original comprobada intacta SHA256 `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`; no se editó ni se exige restaurar whitelist/clave obligatoria por proveedor.

**No leí, imprimí, copié, modifiqué ni renombré `Config/IdentificationSecrets.xcconfig`, ni abrí productos/logs reales con posible clave.** No builds, tests nuevos, inferencia, envío de fotos, búsqueda externa de recursos ni inspección de xcuserdata. Comprobé solo ignore/no tracking de la ruta real. No se conoce si contiene clave ni si esa clave es válida; el requisito real ahora es acceso al servicio elegido (clave solo si la exige), fotos autorizadas para ese destino y permiso de ejecución, no necesariamente una nueva clave DevExpert.

## Comprobaciones propias frente a evidencia ajena

- Revisión propia del diff/fuentes públicas: configuración, adaptador único, scope/notice Domain, App/composición, VM/vistas, localización pertinente, pruebas, puente/proyecto/plantilla/script, docs/ADR/handoff/estado. Sin editar implementación/spec ni stage/commit/push/GitHub.
- Ejecutados static: diff check, lint proyecto/plist puente, JSON feature_list/localización, bash syntax e ignore/no tracking: correctos. Typecheck propio Domain/Data en host correcto; no es build iOS.
- Comparación propia de **67 archivos públicos** actuales con sandbox de tests (Swift app/unit/UI, catálogo, proyecto/shared scheme, plantilla pública/plist puente, init/script): idénticos, sin copiar ni comparar configuración real o userdata. Sandbox consistente con fuentes revisadas; no prueba API.
- Reextraídos summaries directamente de bundles del implementer `identify-generic-sandbox/DerivedData/evidence/{generic-gate,generic-focused}.xcresult`: **94/94** y **28/28**, Passed, cero fallos/omitidas. Gate 74 unit + 20 UI y focused 24 unit + 4 UI son ejecuciones ajenas reutilizadas, no tests ejecutados por validator. No repetí gate por inercia ni abrí artefactos de builds con real del usuario.
- Auditoría propia script `--release` sobre producto existente **sandbox genérico sin secretos reales** `DerivedData/evidence/identify-generic-release-sandbox/Products/Release-iphonesimulator/PlantCareAI.app`: correcta, sin entradas de configuración/seams que comprueba script. Release build, runtime/script roundtrip sintético y visual del implementer son evidencia ajena; no se reconstruyó ni se verificó clave real.
- Inspección visual propia de capturas existentes, no runtime/interacción nueva: focused `0B553F15...` (primer aviso), gate `DEE0FB05...` (destino/modelo renovados) y `1F9779ED...` (espera con foto/cancelación). Destinos/modelos distintos y advertencia honesta legibles, Cancelar visible; botón Aceptar queda fuera de viewport en esas capturas, acceso/desplazamiento probado por E2E existente, no observado directamente aquí. No se atribuye screenshot a API real.
- Evidencia propia local ignorada: `DerivedData/evidence/identify-validator-generic-static.log`, `identify-validator-generic-reused-{gate,focused}-summary.json`. Gate/Release/focalizadas/roundtrip del implementer se separan explícitamente de comprobaciones propias.

## Seguridad, contrato y arquitectura

Revisión scoped con checklist: **sin hallazgo de código bloqueante identificado**, no garantía de ausencia de defectos ni aceptación del código. Un único repositorio Chat Completions; ninguna capa Presentation/Domain construye transporte ni importa proveedor. Notice Domain son strings de destino/modelo, no dependencia de API externa.

HTTPS validado/canonicalizado, prefijo preservado y endpoint añadido una vez; userinfo/query/fragment/path codificado/segmentos ambiguos/endpoint duplicado rechazados; ATS/TLS intactos. Clave opcional omite Authorization al faltar, no Bearer vacío/recorte/retry 401 ni fallback. URL configurable ahora es decisión del usuario, no atribución de empresa o permiso automático de envío; tampoco garantiza visión/JSON/modelo compatible.

Scope `openai-compatible:` v3 SHA256 de base/endpoint/modelo/revisión; no hereda v2/v1. Aviso y transporte proceden de la misma configuración inmutable en composición; vigencia revisada antes de aceptar/enviar/publicar. VM bloquea operación real sin notice, conserva cancelación/generaciones/foto e intención única. UI muestra endpoint/modelo literal y desconocimiento de operador/subprocesadores/retención/entrenamiento. Tests revisados cubren host/path/puerto/modelo nuevos, 0 antes→1 tras aceptación, rechazo v2, aviso renovado misma suite y siguiente intención sin aviso repetido. No envíos al abrir/configurar/reabrir. Mapping remoto oculto no detectado automáticamente, limitación declarada.

Adapter conserva rechazo de todos los redirects, session efímera, límites/deadline/parseo de datos no confiables, solo JPEG actual + prompt y no persistencia. Print de respuesta cruda ya no está en adaptador; retirada informada en PROGRESS, logs anteriores potencialmente sensibles no inspeccionados. Debug con clave sigue extraíble y exclusivamente privado, no seguridad comercial. Sin nuevos SDK/vendor adapters, auth bypass o fallback ficticio observado.

## Hallazgo D1 — Arquitectura vigente contradice autorización genérica

- **Severidad: Medium; reparación documental requerida.**
- Evidencia: `ARCHITECTURE.md:89` aún dice «DevExpert es el único perfil de IA habilitable»; `:95` presenta DevExpert como perfil externo aprobado. Son afirmaciones operativas actuales, no apartados marcados históricos, y contradicen el mismo documento (:81–87), ADR 004 y código sin whitelist. `PROGRESS.md`, sección Estado verificado, también conservaba resumen split 90/90 y afirmación actual de real con clave vacía; corregido solo ese resumen en esta revalidación, sin inspeccionar clave.
- Importancia: ARCHITECTURE es fuente normativa obligatoria; un agente nuevo podría restaurar restricciones eliminadas expresamente o aplicar consentimiento equivocado. No basta preservar apartados históricos de ADR/spec: estas líneas se presentan como arquitectura actual.
- Cambio requerido: reemplazar las dos afirmaciones vigentes DevExpert por adaptador genérico HTTPS/modelo configurable, aviso v3 y demo Debug local privada; no modificar la spec, restaurar whitelist ni reescribir evidencia histórica. No otra reparación de código prescrita.
- Pasos: editar únicamente esas frases de ARCHITECTURE, contrastar con ADR/CONSTRAINTS/guía/handoff, actualizar evidencia de corrección. En PROGRESS no afirmar contenido/validez de configuración real.
- Verificación: revisión documental de las líneas corregidas y `git diff --check`; no repetir gate por un cambio solo documental ni compilar con secretos reales.

## Bloqueo B1 — Escenario obligatorio API real no acreditado

**High, recurso/verificación externa pendiente, no defecto demostrado.** No nuevos recursos/autorización/escenario real comunicados; pruebas controladas no acreditan visión, data URL `image_url`, JSON/envelope/max_tokens, límites/presupuesto o incertidumbre del destino/modelo elegidos. Autorización de cambiar código no autoriza enviar fotos. El bloqueo previo persiste pero ya no se limita a DevExpert/clave requerida.

Requiere que usuario confirme destino/modelo/acceso y autorice dos fotos propias o permitidas (planta e insuficiente) para ese destino; configurar/verificar roundtrip solo de forma local privada, ejecutar sin fixture/spy bajo aviso v3, registrar evidencia sanitizada. Si falla, reparar incompatibilidad concreta sin relajar autorización/validación ni convertir doble en éxito. Confirmar propuesta/alternativas disponibles/incertidumbre española y caso insuficiente, cancelación/retry explícitos y ninguna confirmación/alta/persistencia. Revalidar independientemente después. No hay acceptance antes de ello.

## Implementation Repair / Unblock Brief

1. Corregir únicamente las dos frases normativas obsoletas en `ARCHITECTURE.md:89,95` según D1; preservar spec/evidencia histórica y configuración real. Validar documentalmente y diff check; no gate necesario por esa reparación sola.
2. Mantener `blocked`: usuario aporta/confirma acceso (clave si servicio lo exige), destino/modelo con visión y dos fotos autorizadas para ese destino, más permiso de prueba real. No buscar/leer credenciales ni asumir recursos ausentes/válidos por inspección del archivo.
3. Implementer con autorización ejecuta build/roundtrip privados y escenario real sin fixtures bajo aviso v3; sanitizar evidencia y proteger todos los productos/logs. Registrar/reparar solamente incompatibilidades demostradas y ejecutar regresiones coordinadas si cambia código.
4. Entregar a validator para revalidar; orquestador no commit/accepted/siguiente feature hasta accept. No backend/SDK/whitelist ni nueva feature.

Limitaciones: no runtime/tests/builds nuevos, API real, legal/retención/coste/precisión, cámara física/dispositivo ni contenido de configuración del usuario. SE/texto aumentado/VoiceOver/matrices fuera de habitual y no ejecutados, no bloqueos automáticos. **Revise se debe a D1; aunque se repare, B1 obliga a block hasta prueba real.**

---

## Informe inicial histórico (configuración DevExpert v2 anterior; no estado vigente)

# Validación independiente — identify-candidates

Fecha: 2026-10-10. Rol: validator independiente (feature-validator + ios-clean-mvvm).

## Veredicto: block

**No es aceptación del código ni aceptación condicionada.** La verificación obligatoria con API real no se puede completar sin credencial local y dos fotos autorizadas. Mantener `identify-candidates` en **blocked**, no passing/accepted; detener feature-flow y no hacer commit ni iniciar la siguiente feature.

Contrato: `docs/specs/identify-candidates.md`, aprobado íntegramente posteriormente según contexto explícito del usuario/orquestador, aunque conserve pendientes históricos. SHA256 comprobado intacto: `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`. No se reabren decisiones de modelo/diseño ni se modifica la spec.

## Alcance y comprobaciones propias

- Confirmados `pwd`, estado/diff del worktree exclusivo; revisados cambios rastreados y fuentes nuevas no rastreadas de IdentifyCandidates, Config, pruebas, script y documentación. No stage/commit/push/PR/merge/GitHub, búsquedas externas de recursos, inferencia ni envío de fotos.
- Leídos AGENTS, PROGRESS, feature_list, spec, arquitectura, constraints, diseño, contexto/brief/dominio/riesgos, ADR 004, guía de pruebas/handoff y rúbrica/checklist de seguridad.
- Ejecutados `git diff --check`, `plutil -lint` del proyecto y plist Debug, parseo JSON de feature_list/localización, `bash -n init.sh`: correctos. `init.sh` sigue intacto y ejecuta build + unitarias/UI, no solo imprime comandos ni inicia servicio permanente.
- `git check-ignore` confirma ruta local ignorada, `git ls-files` no la rastrea y el archivo `Config/IdentificationSecrets.local.xcconfig` está ausente. No se buscó credencial fuera de esa ruta. Producto Debug existente comprobado sin imprimir secreto: URL/modelo/timeout aprobados y clave vacía.
- Typecheck propio Swift de host de contratos Domain/configuración/adaptador Data correcto (no equivale a build iOS).
- Auditoría propia sobre producto Release existente con `scripts/verify-identification-config.py --release`: sin las cuatro entradas sensibles ni seams de identificación/consentimiento comprobados por el script. No se reconstruyó Release ni se hizo auditoría completa de todos los artefactos.
- Extraídos **de nuevo** summaries con xcresulttool desde bundles preservados del implementer: gate `identify-gate-final.xcresult` Passed **88/88**, 0 fallos/omitidas; focused `identify-focused-final.xcresult` Passed **22/22**, 0 fallos/omitidas. Logs gate contrastados: BUILD/TEST SUCCEEDED, 69 unit + 19 UI. Son ejecuciones del implementer reutilizadas, no tests propios nuevos. Evidencia propia local ignorada: `DerivedData/evidence/identify-validator-static.log` y `identify-validator-reused-{gate,focused}-summary.json`.
- Inspección visual propia de capturas existentes del gate en `identify-gate-final-attachments`: proposals, real-recipient-notice-fixture, waiting, insufficient, error y long-result-actions. Aviso DevExpert legible con acción, foto durante espera/cancelación, resultado prudente solo lectura, insuficiencia distinta de error y desplazamiento hasta acciones con texto largo. No apertura ni interacción nueva del simulador; esas acciones proceden de XCUITest del implementer.

No repetí gate/focalizadas/builds/roundtrip de secreto sintético ni inferencia: el bloqueo es concluyente y el usuario pidió reutilizar evidencias válidas sin procesos duplicados. Baseline, Release build, memoria host sintética, roundtrip y apertura manual quedan como evidencia del implementer, no como ejecuciones propias.

## Revisión del comportamiento, arquitectura y seguridad

- Flujo actual: View → VM de foto → AuthorizeExternalAIOperation → IdentifyCandidates → contrato Repository ← Data, conectado en App. Domain Foundation-only, sin SwiftUI/proveedor/persistencia; vistas/VM no construyen Data. Contrato de continuación retirado de consentimiento y movido a identificación. No confirmación/selección/alta/cuidados/historial añadidos.
- Configuración valida HTTPS/origen/puerto/camino/modelo contra único perfil revisado; DevExpert required no admite clave ausente. Optional existe como seam de perfil revisado/test, no override local ni nuevo destinatario habilitado. Scope v2 depende de destino/modelo/revisión y no de clave; snapshot revalidado antes de aceptar/enviar/publicar. Aceptación provisional no autoriza HTTP real.
- Único POST explícito con JPEG actual + prompt, sin colección/UUID/historial. Session efímera sin cache/cookies/credential store, redirects rechazados incluso mismo host, sin bucle de retries. Timeout total y stream/respuesta acotados; cancelación y generaciones descartan resultado tardío.
- Respuesta externa se trata como datos: envelope/finish/refusal, invariantes/tamaños/duplicados y porcentajes con `%` validados; texto nativo sin ejecutar acciones/instrucciones. Forma inválida es error, no insuficiencia ficticia. Español/incertidumbre semántica/precisión del proveedor solo podrán valorarse en prueba real.
- UI/VM mantienen foto, retry explícito y estados separados; reemplazo exitoso limpia A, fallido conserva A. Tests nuevos persistentes cubren lectura/alternativas/insuficiencia/espera/cancelación/error/long text y conservación de modelos/JPEGs de dos plantas tras relanzar; regresiones históricas siguen en gate. Prueba de ausencia de configuración se adapta razonablemente al bloqueo previo al aviso, no elimina cobertura histórica del consentimiento.
- Checklist de seguridad scoped: **sin hallazgo adicional de código que requiera reparación identificado en esta revisión**, no garantía de ausencia de defectos. Riesgo conocido y aprobado: credencial Debug extraíble; solo demo privada, no distribución. No nuevos paquetes, ATS relajado, secretos reales visibles en cambios revisados, guardado del resultado o logs de payload en el adaptador. Retención/subprocesadores/coste remotos no acreditados.
- Docs/handoff y estado blocked describen límites sin atribuir visión real a dobles. ADR explica input plist Debug adicional necesario para puente runtime, sin alterar exclusión Release. Spec permanece histórica e intacta por instrucción expresa, aprobación posterior documentada fuera de ella. No reparación documental obligatoria adicional identificada.

## Hallazgo bloqueante B1 — Falta prueba obligatoria DevExpert real

- **Severidad: High (recurso/verificación, no defecto de código demostrado).**
- Evidencia: Verification Plan/Validator Checklist de la spec prohíben passing/accept sin foto/API real; guía/handoff y PROGRESS declaran ausencia de recursos. Comprobación propia confirma archivo local ausente y clave Debug vacía. No hay escenario real acreditado; URLProtocol/fixtures solo prueban límites controlados.
- Importancia: ni elección de modelo con visión ni HTTP simulado demuestran que el gateway acepte `chat`, data URL `image_url`, el envelope/JSON solicitado o presupuesto/límites reales. La feature exige ese resultado observable.
- Cambio requerido: aportar recursos autorizados y completar escenario real con evidencia sanitizada; si falla, reparar únicamente incompatibilidad demostrada dentro del contrato aprobado antes de volver a validar.
- Pasos sugeridos: seguir brief siguiente; no sustituir prueba por doble, no relajar consentimiento/validación ni habilitar fallback silencioso.
- Verificación posterior: planta real produce propuesta orientativa/alternativas disponibles sin confirmar; foto insuficiente produce explicación prudente sin éxito ficticio. Una intención/una petición tras aviso v2; cancelación/reintento explícitos sin persistir draft ni alterar plantas existentes. Verificar gateway/input/JSON/límites y registrar solo metadatos/resultados sanitizados. Revalidación independiente posterior necesaria.

## Implementation Repair / Unblock Brief

1. **Usuario/demo:** aportar una credencial DevExpert válida solo mediante editor local privado en `Config/IdentificationSecrets.local.xcconfig` ignorado/no rastreado. Nunca chat, argumentos, esquema o settings publicados. Aportar/importar dos fotos propias o expresamente autorizadas para envío a DevExpert: una planta y una borrosa/no vegetal; comunicar solo existencia/ruta y autorización.
2. **Implementer tras recursos:** build Debug privado y comprobar roundtrip exacto contra original con entrada oculta del script; no compartir producto/logs/xcresult con clave. Abrir sin fixture/spy y ejecutar los dos escenarios reales bajo aviso vigente. No cambiar modelo aprobado por inercia, no buscar recursos externos ni fotos ajenas.
3. Capturar evidencia sanitizada de destino/modelo, éxito/insuficiencia/errores, incertidumbre y no confirmación/persistencia. Si gateway falla, documentar y reparar el defecto concreto sin alterar spec ni eludir límites; ejecutar regresiones pertinentes sobre fuentes finales de manera coordinada.
4. Actualizar PROGRESS/feature_list/guía únicamente con verificaciones realizadas y entregar a validator. **No pasar a accepted ni hacer commit antes de accept independiente.** No reparación de implementación prescrita por ahora aparte de posibles fallos que revele la API real.

## Limitaciones

Sin runtime nuevo, inferencia, compatibilidad real del gateway, precisión botánica, retención/coste legal, cámara/dispositivo físico ni garantía de apagado abrupto. SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Inspector y matrices: fuera de verificación habitual; no ejecutadas y no bloqueos automáticos. La revisión estática/evidencia reutilizada no constituye aceptación del código.
