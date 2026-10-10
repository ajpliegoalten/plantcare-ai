# Pruebas de identify-candidates — adaptador único OpenAI-compatible

Spec original preservada SHA256 `70375f39ec186a00b8f58b055aec753ddc1ae9b841706edcc63ec9a8ec1012d5`. Autorizaciones posteriores explícitas: configuración única split y, después, URL/modelo HTTPS arbitrarios con clave opcional y sin perfiles DevExpert. ADR 004 registra la modificación; no editar spec para ocultar pendientes. Estado final: **accepted** tras revisión independiente y pruebas reales OpenAI gpt-4.1-mini reportadas por usuario (planta, insuficiencia sin candidata, aviso, cancelación y reintento); ver PROGRESS, feature_list y `docs/validations/identify-candidates.md`. Referencias de bloqueo de fases anteriores conservadas abajo son históricas. No se atribuye al agente nueva inferencia ni fiabilidad absoluta; mantener precauciones de secretos y consentimiento para nuevas ejecuciones.

## Configuración final

Único real `Config/IdentificationSecrets.xcconfig`, ignorado y obligatorio Debug; **solo** plantilla `Config/IdentificationSecrets.xcconfig.example` sin secretos para versionar. Si el real ya existe, no leer/imprimir/sobrescribir su clave ni copiar plantilla encima. En checkout nuevo copiar la plantilla pública antes del gate. No `.local.`, wrapper/include opcional ni SLASH. `IdentificationDebugInfo.plist` es únicamente puente de cinco settings al Info.plist generado, no segunda configuración. Release no usa fichero real/puente ni incluye clave/seams.

Ejemplo **no conectado** (dominio reservado `.invalid`):

```
API_SCHEME = https
API_HOST_PATH = api.example.invalid:8443/prefix/v1
API_MODEL = vision-family/model
API_KEY =
API_TIMEOUT_SECONDS = 60
```

La app construye `https://api.example.invalid:8443/prefix/v1/chat/completions`. HOST_PATH es **base**, no URL con esquema ni endpoint final. Se preserva prefijo y añade Chat Completions una vez. Base HTTPS/modelo bien formados configurables sin lista fija; puertos 1–65535, 443 normalizado. Rechaza userinfo/query/fragment, segmentos ambiguos/encoded paths/doble slash, endpoint ya añadido, no HTTPS; no relax ATS/TLS ni aceptación de certificados inválidos. Modelos deben ser no vacíos/acotados y sin controles/expansión no resuelta. Timeout total 10–120 s (default 60), incluyendo serialización. No SDK/vendor adapters/Responses ni fallback de modelo.

API_KEY opcional: nil/vacía/whitespace omite Authorization, nunca Bearer vacío. Clave no vacía debe ser exacta y válida, no se recorta/modifica. **El servicio puede exigir auth**: 401/403 es error recuperable, sin retry automático/con otra auth. No se deduce visión/JSON/retención/exención de auth por URL o alias de modelo.

xcconfig interpreta `//` como comentario incluso entre comillas y expande `$()`. Split evita el problema para la URL, no garantiza representación de toda clave/modelo. Para credencial complicada acordar representación segura sin revelar el valor; no introducir trucos ni enviar valor truncado. No clave en chat, argumentos/env/esquema, `-showBuildSettings` ni logs. Después de build **privada**, `python3 scripts/verify-identification-config.py <Debug.app>` pide base URL/modelo originales y clave oculta (blank si omitida), valida canonicalización/roundtrip y solo muestra OK/FAIL. `--empty-template` verifica artifact sintético sin clave/no request; ahora **no** significa indisponibilidad de la app, pues la auth es opcional. Script no prueba API ni visión.

La clave Debug es extraíble; no distribuir .app/.ipa/DerivedData/logs/xcresult de builds reales. Evitar recopilar artefactos reales que puedan contener clave. Rotar/revocar al terminar demo si corresponde. Print temporal de respuesta API cruda fue retirado por privacidad; logs previos con ese print pueden contener contenido sensible y no se inspeccionaron ni se deben compartir por defecto.

## Consentimiento y aislamiento

Aviso v3 muestra **endpoint HTTP real y modelo del mismo snapshot** que transporta. No atribuye compañía/subprocesador a host/alias ni garantías de retención/entrenamiento. Scope `openai-compatible:` SHA256 de base/endpoint canónicos/modelo/revisión; no hereda DevExpert v2 ni provisional v1. Cambio de host/puerto/base path/modelo exige nueva aceptación antes de HTTP; rotar clave/timeout no cambia alcance. Configurar no autoriza ni envía. Snapshot invalidado durante aviso/petición no redirige foto ni publica respuesta; operación real sin notice falla localmente. Todos los redirects (también mismo host) rechazados.

Solo foto JPEG preparada actual y prompt fijo, sin UUID/colección/historial/metadata ni persistencia. Propuestas son lectura: no Confirmar/alta/cuidados. Cancelación no retira bytes/consumo ya transmitidos. JSON/envelope/refusal/forma inválidos son error, no evidencia insuficiente; no porcentajes sintetizados. Base64/JSON producen varias copias; medición host sintética histórica en PROGRESS, no garantía del pico completo de app ni memoria constante.

## Gate determinista sin tocar secretos reales

Coordinar un iPhone estándar booted, texto normal/una apariencia, tapa abierta; no editar init ni ejecutar pruebas simultáneas. `caffeinate -dius ./init.sh` requiere real Debug presente. Si el usuario puede haber añadido clave, **no** construir artefactos de evidencia a partir de su real: usar sandbox privado ignorado con mismas fuentes/proyecto/shared scheme/unit/UI tests/scripts/init y copiar **solo plantilla pública** al nombre real del sandbox. No copiar/leer/renombrar real ni xcuserdata. Evidencia actual sigue este mecanismo, bajo `DerivedData/evidence/identify-generic-sandbox`; `init.sh` original intacto.

Unitarias cubren base/modelo genéricos, canonicalización/notice v3, host/path/port/model renew/0 antes→1 tras, auth optional/header exacto/401 sin retry, payload único/foto actual, invalidResponses/límites/timeout/cancelación y redirects. VM bloquea notice faltante/cambios durante aviso/tardías/duplicados. E2E conserva regresiones de galería real, 2 plantas/modelos/JPEGs tras relaunch sin reseed y resultado/insuficiencia/error/texto largo/cancelación/reemplazo.

Fixtures opt-in **solo Debug Simulator**, sin HTTP y no equivalentes a API: `--identification-candidates-fixture proposals|no-alternatives|insufficient|error|slow|long`, `--identification-photo-fixture`, UUID aislados `--storage-test-id`/`--consent-test-id`. Primer endpoint sintético `vision-one.invalid`/modelo `vision-test-a`; `--identification-second-destination` cambia a `vision-two.invalid`/modelo `vision-test-b` para renovar alcance en la misma suite. `--identification-no-configuration` fuerza indisponibilidad runtime para cobertura cero invocaciones; no mide falta del fichero obligatorio de build. Spy histórico de consentimiento queda separado, nunca fallback de producción.

Release genérico de sandbox sin real y `scripts/verify-identification-config.py <Release.app> --release` deben pasar; Debug sin real debe fallar, sin borrar/renombrar el real del usuario. Inspección básica del nuevo aviso/endpoint/modelo/cancelar/aceptar en simulador normal y regresiones de pantallas. SE/texto aumentado/VoiceOver/Inspector/matrices fuera de habitual, no ejecutar sin petición expresa.

## API real: aún requiere recursos y autorización explícita

Cambio de código **no** autoriza inferencia/fotos nuevas ni permite buscar credenciales/fotos ajenas. El real existe y no fue inspeccionado; no afirmar que esté vacío o que su clave sea válida. Usuario confirma servicio/base/modelo con visión, acceso (clave si servicio la exige) y aporta **dos fotos propias o expresamente autorizadas para ese destino**: planta e insuficiente. Comunicar solo ubicación/existencia/permiso, nunca clave en chat. Importarlas a Fotos del simulador usando ruta local privada si procede.

Build Debug privada, roundtrip original, app sin flags fixture/spy, elegir foto → Identificar → leer destino/modelo y aceptar aviso v3. Una intención/una petición; revisar candidata/alternativas disponibles/incertidumbre española sin confirmar ni guardar. Segunda foto insuficiente distingue prudencia de error de servicio. Cancelación/retry explícitos preservan A y almacenamiento de otras plantas. No bucles/retries/fallbacks automáticos.

Contrato transportado: Chat Completions, `image_url` data URL JPEG + prompt solicitando JSON, `max_tokens=1000`, sin asumir response_format/Schema. Registrar solo evidencia sanitizada del endpoint/modelo y resultado/incertidumbre/contadores, nunca headers/body/JPEG/base64/clave/respuesta cruda. API «compatible» no prueba que soporte visión, JSON y límites solicitados; si falla documentar y reparar incompatibilidad demostrada dentro del alcance autorizado. Sin este escenario no passing/accepted; revisión independiente posterior necesaria.
