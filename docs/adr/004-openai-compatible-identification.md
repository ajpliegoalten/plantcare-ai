# ADR 004 — Identificación orientativa compatible con OpenAI

Fecha: 2026-10-10. Decisión: spec íntegra aprobada posteriormente en conversación; archivo original se conserva intacto aunque contenga pendientes históricos.

## Contexto y decisión

Una continuación `.unavailable` en Domain de consentimiento no representa un resultado de identificación. Se mueve al Domain `IdentifyCandidates`, con propuesta principal/0–3 alternativas o evidencia insuficiente, incertidumbre descriptiva y validación estricta. No añade especie confirmada, ficha ni persistencia.

Perfil inicial revisado: DevExpert `https://inference.devexpert.io/v1/chat/completions`, modelo `chat`, mapping comunicado `deepseek/deepseek-v4.1-flash`, Bearer required. Otros destinos/modelos no se autorizan por ser HTTPS/compatibles: requieren perfil revisado y aviso concordante. Scope v2 es SHA256 de array JSON canónico (base, endpoint, modelo, nombre, revisión del mapping). Clave/timeout no cambian scope. Configuración y transporte capturados por borrador, vigencia comprobada antes de aceptar/enviar/publicar; no redirects ni fallback/retries automáticos.

Input: Chat Completions, mensaje user con prompt fijo español e `image_url` data URL JPEG actual. JSON solicitado mediante prompt, sin asumir soporte `response_format`/Schema. Parseo estricto del envelope y objeto, finish_reason stop, rechazo/modelo/truncamiento como error; nunca convertirlos en insufficientEvidence. Límites locales: JPEG 5 MiB, HTTP 1 MiB, nombres 160 caracteres, incertidumbre 1000, 0–3 alternativas, max_tokens solicitado 1000 y timeout total default 60 s (10–120). No son garantías de límites del proveedor. La compatibilidad real del gateway exige credencial/fotos autorizadas y evidencia distinta de URLProtocol/fixtures.

## Configuración y consecuencias

**Autorización posterior explícita del usuario (2026-10-10), sin editar la spec aprobada:** sustituir wrapper/include opcional por un único `Config/IdentificationSecrets.xcconfig` real, ignorado y obligatorio en Debug. Versionar únicamente `Config/IdentificationSecrets.xcconfig.example` sin secretos. Separar `API_SCHEME = https` y `API_HOST_PATH = inference.devexpert.io/v1`; Data construye `://` y aplica la misma validación/canonicalización/perfil/consentimiento, sin relajar HTTPS/ATS/auth. `API_MODEL`, `API_KEY` y timeout completan las cinco variables del puente. No SLASH, `.local.`, API_BASE_URL ni default wrapper duplicado. Comillas xcconfig tampoco protegen `//` (prueba sintética Xcode 26.2 documentada en PROGRESS).

Debug referencia directamente el fichero real como baseConfigurationReference, y falla al faltar; para tests se copia la plantilla pública con API_KEY vacío (DevExpert unavailable/cero HTTP). Si existe un fichero real, nunca sobrescribirlo ni leer/imprimir sus secretos para migrarlo sin acuerdo. El plist de entrada Debug solo contiene enlaces de build settings a cinco claves runtime: es el puente necesario de Xcode, **no un segundo fichero de configuración**. Lectura Bundle en composición/Data, no Domain/VM. Release no tiene base config ni plist Debug/entradas sensibles y compila sin fichero real. Credencial Debug es extraíble: demo personal únicamente, artefactos privados y revocación/rotación al terminar; no seguridad de distribución comercial. Ver guía de pruebas para provisión segura y comprobación de roundtrip. Spec original conservada SHA256 `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`; este apartado registra la modificación autorizada posterior.

Session efímera sin cache/cookies/credential storage. Cancelación se propaga a URLSession y generaciones impiden resultado tardío; no garantiza retirar datos/consumo remoto. Base64/serialización duplican bytes: memoria proporcional a la imagen y varias copias, no memoria constante. Aviso no promete retención, borrado, región ni entrenamiento desconocidos.

## Migración

### Autorización posterior: un único adaptador genérico (2026-10-10)

Usuario ordena explícitamente adaptar a **un único adaptador OpenAI-compatible** y retirar la limitación de perfiles DevExpert. Esta decisión posterior sustituye las restricciones de destinatario/modelo/auth de los apartados históricos anteriores **sin editar la spec original** (SHA256 `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`). No añade SDK/adaptadores vendor/Responses ni otra feature.

Configuración split/real obligatorio Debug se conserva. Base HTTPS arbitraria y modelo no vacío/acotado, puerto HTTPS 1–65535 (443 se normaliza), base path preservado, endpoint Chat Completions añadido exactamente una vez. Rechazar URL con userinfo/query/fragment/segmentos ambiguos/encoded path/endpoint ya añadido/no HTTPS, sin ATS/TLS relax. No whitelist ni mapping/procesador declarado como conocido. API_KEY opcional genéricamente: ausente/vacía/whitespace omite Authorization; no Bearer vacío, no retry 401/403 sin/con auth, sin fallback. El servicio puede exigir una clave, no lo decide la app por vendor.

Scope v3 = SHA256 de array JSON inequívoco (base canónica, endpoint real canónico, modelo exacto, revisión de aviso). Prefijo `openai-compatible:` distinto, nunca hereda v2 DevExpert/v1. Misma clave rotada/timeout no cambian alcance. Host/puerto/base path/modelo/cuerpo/finalidad cambian destino o revisión y requieren aviso nuevo. Configuración/notice/transporte capturados juntos, checks de vigencia antes de aceptar/enviar/publicar y generaciones/cancelación; falta notice de una operación real bloquea antes de autorizar. Todos los redirects siguen rechazados.

Aviso nativo muestra URL HTTP real y modelo del snapshot, sin clave ni datos de otra planta; explica que la app no verifica operador legal/subprocesadores/retención/entrenamiento. Host/modelo no garantizan visión ni compatibilidad del envelope/JSON; pruebas reales con recursos y permiso del usuario siguen obligatorias, no se infieren por autorizar cambios de código. Modelo remoto puede cambiar mapping oculto sin detección; no se promete observarlo.

Retirado exclusivamente print temporal ajeno de respuesta API cruda en Debug por privacidad, hallazgo registrado en PROGRESS; no se leyeron logs/respuestas reales ni el real xcconfig, no se tocaron xcuserdata ni otros cambios ajenos. Verificación en sandbox privado de mismas fuentes/proyecto/shared scheme y plantilla pública, sin copiar secretos reales ni renombrarlos; tests instrumentados no equivalen a inferencia real. Release sin config/seams. Estado blocked hasta prueba real y revisión independiente posterior.

Consentimiento conserva contratos genéricos, no conoce modelos botánicos. Pruebas históricas mantienen spy provisional opt-in separado; nuevas fixtures identifican resultados sin HTTP y solo Debug Simulator. App cambia continuación por caso de uso real exclusivamente cuando configuración válida; falta de configuración es error local sin envío ni éxito ficticio. Confirmación/alta pertenecen a features siguientes.
