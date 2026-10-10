# Handoff — identify-candidates (adaptador único genérico)

## Estado final de entrega — 2026-10-10

`accepted` registrado por orquestador tras veredicto independiente `accept`; pruebas reales OpenAI gpt-4.1-mini reportadas por usuario y evidencia determinista 94/94 + 28/28 contrastada. Ver `docs/validations/identify-candidates.md` y `PROGRESS.md`. Los estados blocked y pendientes del handoff de implementación conservados abajo son históricos, no bloqueos vigentes. Spec intacta, configuración real y userdata excluidos de entrega. Push/PR autorizados, sin merge.

Rol implementer, no validator. Worktree exclusivo identify-candidates, rama feature/identify-candidates, base indicada `0ce0bf0664b90b259b1365e5dcf20315d40daf63`. Spec aprobada original **no editar**, SHA256 `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`.

## Decisión posterior y fuentes

Usuario autoriza explícitamente un único adaptador OpenAI-compatible Chat Completions: retirados perfiles/whitelist/obligatoriedad de clave DevExpert. HTTPS/base/modelo arbitrarios bien formados, API_KEY opcional omite Authorization al faltar, sin Bearer vacío/retry auth/vendor SDK/adaptadores adicionales. URL segura mantiene prefijo y endpoint una vez, sin ATS/TLS relax. Config split/real Debug obligatorio se conserva; Release sin ella. ADR 004 y docs registran modificación fuera de spec.

Scope nuevo `openai-compatible:`/v3 deriva de base/endpoint/modelo/revisión de aviso, no hereda v2/v1. Aviso visible muestra endpoint/modelo del mismo snapshot y desconocimiento de operador/subprocesadores/retención. Domain `ExternalAIDestinationNotice`, composición/VM y vista conectados; notice real faltante/config cambiada bloquean antes de HTTP, cancelación/generaciones impiden publicación tardía. Sin confirmación/persistencia/alta ni otra feature.

## Secretos y cambios ajenos

Real `Config/IdentificationSecrets.xcconfig` existe, **contenido no leído ni impreso, no se afirma que esté vacío ni que clave sea válida**. No se modificó/sobrescribió/renombró/copió. Usuario puede haber añadido clave. Únicamente `.example` pública tiene valores reservados `.invalid` y key vacía. No copiar plantilla encima del real. User xcuserdata y reformato de localización preexistentes preservados; no inspeccionar ni stage userdata. Informe validator anterior conservado histórico (block), sin aceptación del código nuevo.

Encontrado print temporal ajeno de respuesta API cruda en adaptador Debug y retirado **solo ese bloque** por privacidad, explicado al usuario y registrado en PROGRESS. No se leyeron logs/respuestas reales; podrían contener contenido sensible previo y no se deben compartir por defecto. No otros cambios ajenos descartados.

## Verificación y estado

Reparación documental posterior a validator `revise` (D1, 2026-10-10): leído repair brief de `docs/validations/identify-candidates.md`, reemplazadas únicamente las frases normativas DevExpert obsoletas de `ARCHITECTURE.md:89,95` por adaptador genérico HTTPS/modelo configurable, aviso v3 y demo Debug privada. Contrastadas con ADR 004/CONSTRAINTS/guía; `git diff --check` correcto y hash spec original conservado. Registrado en PROGRESS, sin código/spec/config real/informe validator modificados ni nuevos builds/tests/API/commit. D1 listo para revalidación; B1 mantiene **blocked**, no aceptación ni cambio de estado por esta reparación.

**blocked**, no passing/accepted. Prueba real pendiente, autorización de cambio de código no autoriza inferencia/recursos nuevos. Gate split anterior 90/90 e implementación inicial 88/88/focalizada 22/22 son históricos, no pruebas de este cambio.

Verificación actual en `DerivedData/evidence/identify-generic-sandbox`: misma app/proyecto/shared scheme/tests/scripts/init, real del sandbox copiado **solo de plantilla pública** sin clave. No real/userdata copiados. Build-for-testing pasó; focalizada **28/28 (24 unit + 4 UI)** y gate original `caffeinate -dius ./init.sh` **BUILD/TEST SUCCEEDED, 94/94 (74 unit + 20 UI)**, cero fallos/omitidas, seriales en el mismo iPhone estándar B52F5194-6A81-4FAA-B094-B0D248084877 light/texto normal. Gate 18:45–19:05 +0200 terminado; salida original esperada por evento macOS/notificación, no procesos duplicados/rerun. Logs/summaries `DerivedData/evidence/identify-generic-{focused,gate}*`; xcresults/attachments preservados bajo sandbox/DerivedData/evidence. Capturas final/focalizada inspeccionadas (avisos primero/renovado, propuesta, espera/error/texto largo/acciones), evidencia detallada en PROGRESS/feature_list. Release separado sin real pasó y auditoría sin config/seams. Script genérico prueba optional-key/base/model roundtrip/mismatch sin valores; static/hash/ignore y comparación sandbox/fuentes actuales correctos. `init.sh` intacto, todos los procesos terminados, sin matrices ampliadas ni API real. Listo para revisar código/evidencia independientemente, **no** para aceptar la feature completa sin escenario real.

## Cómo probar y siguiente paso

Configurar localmente API_SCHEME=https, API_HOST_PATH=<host[:puerto]/base>, API_MODEL=<modelo con visión>, API_KEY opcional según servicio, timeout 10–120. App añade /chat/completions. Servicio compatible puede no admitir visión/JSON/max_tokens solicitados; 401/403 sin retry ni auth fallback. Usar script en artifact **privado** con base/modelo originales y entrada oculta de key (blank si omitida). No mostrar settings/clave ni distribuir build Debug con ella.

Usuario confirma destino/modelo, acceso y dos fotos propias/expresamente autorizadas para **ese destino** (planta e insuficiente); no buscar key/fotos fuera del alcance ni inferir autorización. Abrir sin fixtures/spy, revisar/aceptar notice v3, probar ambos escenarios y conservar solo evidencia sanitizada. Dobles no equivalen a API real. Después revisión independiente y orquestador; no aceptación/feature siguiente/commit por este rol. Guía completa `docs/testing-identify-candidates.md`.

Riesgos: modelo/visión/contrato/coste/operador/subprocesadores/retención desconocidos hasta comprobación pertinente, cambios remotos ocultos no detectados, memoria base64/JSON varias copias, cancelar no retira bytes/consumo remoto, UserDefaults no transacción de disco. No cámara/dispositivo físico ni SE/texto aumentado/VoiceOver/matrices probados por este cambio.

Sin stage/commit/push/PR/merge/GitHub; preservados archivos ajenos/spec. No usar artefactos reales para evidencia compartida.
