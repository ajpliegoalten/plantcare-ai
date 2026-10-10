# Feature Implementation Spec: Obtener candidatas de especie

## Source Feature / Estado de revisión

- `id`: `identify-candidates`; `area`: `identificacion`; fuente: `feature_list.json`; issue #18 comunicada por orquestador, no consultada en GitHub.
- Título: «Obtener candidatas de especie»; estado leído: `not_started` (sin modificar).
- `depends_on`: `[choose-identification-photo, external-ai-consent]`; ambas `accepted` en feature_list y registro reciente de PROGRESS.
- Comportamiento: IA propone candidata y alternativas disponibles con incertidumbre comprensible, sin confirmar automáticamente.
- Verificación de origen: API de visión configurada, foto real, candidata/alternativas y evidencia insuficiente sin porcentajes inventados; gate estándar.
- Planificación: 2026-10-10; único worktree autorizado: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/identify-candidates`.
- Rama/base comunicadas: `feature/identify-candidates`, main `0ce0bf0664b90b259b1365e5dcf20315d40daf63`; no verificadas mediante Git/pwd (sin herramienta shell disponible). Las rutas absolutas devueltas por lectura/glob coinciden con el worktree.
- **Borrador actualizado para revisión humana, no aprobado íntegramente ni listo para conectar red.** D1 y elección `chat` aprobados; URL/modelo configurables y clave opcional para APIs aprobadas sin autenticación. Visión DeepSeek V4.1 Flash acreditada a nivel modelo, no compatibilidad gateway DevExpert (input/JSON/límites). Puente runtime y vinculación del consentimiento a configuración pendientes de revisión. Solo se modifica esta spec; no implementación, builds/tests/init.sh, validación de código ni operaciones Git/GitHub.
- Respuestas del usuario incorporadas en continuación de planner: DevExpert, base `https://inference.devexpert.io/v1`, `/chat/completions`, Bearer; `.xcconfig` local no subido + plantilla `.example` sin secretos; bloque nativo mínimo solo lectura aprobado explícitamente. Son decisiones comunicadas, no evidencia de una API ejecutada.
- Revisión posterior: usuario **aprueba `API_MODEL=chat`**, configurable junto a `API_BASE_URL` y `API_KEY` opcional genéricamente. DevExpert requiere clave según documentación comunicada por usuario; opcionalidad no autoriza enviar sin ella a DevExpert ni cambiar destinatario bajo consentimiento anterior.

## Goal

Desde el borrador fotográfico, obtener mediante API compatible con OpenAI y visión una propuesta efímera: candidata principal, alternativas cuando haya evidencia y explicación prudente en español. Mostrar el resultado al usuario sin convertirlo en especie confirmada ni planta guardada.

La feature no es solo un adaptador API: feature_list, build-brief y DESIGN exigen un resultado observable e incertidumbre legible. La selección/confirmación y su maquetación interactiva corresponden a `confirm-species`; el usuario aprobó aquí únicamente el bloque nativo mínimo de lectura (D1).

## Non-Goals

- Seleccionar/aceptar candidata o alternativa, confirmar identidad, introducir especie manual, generar cuidados o guardar plantas: features posteriores.
- Catálogo Species global, nueva persistencia, historial, chat, análisis de salud, RAG, precisión botánica garantizada o probabilidades calibradas.
- Rediseñar Mis plantas, galería/cámara o pipeline de importación; no envío de fotos antiguas ni colección/contexto de ejemplares guardados.
- SDK adicional, backend, cuentas, sincronización, distribución pública con clave de demo o configuración real por este planner.
- Recuperación transversal de todas las operaciones IA (`recover-ai-failure`); sí error/cancelación y nuevo intento explícito mínimos de esta operación.
- Modificar specs aceptadas, eliminar regresiones o ejecutar matrices ampliadas no solicitadas.

## Job Story / Users And Permissions

Cuando tengo una foto preparada, quiero ver qué especie podría ser y qué dudas hay, para decidir después si confirmo una propuesta o tomo otra foto.

- Único usuario local, sin roles ni cuentas. Identificar exige foto lista e intención explícita; elegir/preparar/abrir/reabrir no envía.
- Todo transporte pasa por `AuthorizeExternalAIOperation`. La aceptación provisional anterior no autoriza silenciosamente al proveedor real.
- Esta operación envía solo el JPEG preparado actual y la instrucción de identificación; no UUID de selección, metadata original, plantas, historial ni claves en logs.

## Acceptance Scenarios (Given / When / Then)

### 1. Identificación autorizada
Given foto A lista y API configurada/aprobada, When pulso Identificar y acepto el aviso vigente si corresponde, Then se realiza una única petición de visión con A; durante espera A sigue visible y puedo cancelar. Al completar se muestran candidata, alternativas disponibles e incertidumbre en español, todas como propuestas no confirmadas.

### 2. Renovar consentimiento y rechazar
Given aceptación previa `prototype-external-ai`/versión 1, When intento identificar con destinatario real, Then se solicita el aviso actualizado antes de cualquier HTTP. When cancelo/descarto el aviso por gesto, Then transporte instrumentado = 0 solicitudes y A permanece. Given aceptación del alcance real vigente, When inicio otra identificación explícita, Then no repite aviso ni duplica petición; abrir/reabrir nunca envía automáticamente.

### 3. Evidencia insuficiente y alternativas ausentes
Given foto borrosa/no vegetal o respuesta válida de evidencia insuficiente, When completa la petición, Then se explica que no hay evidencia suficiente y se ofrece cambiar foto; no se inventan candidata ni porcentajes. Given candidata válida sin alternativas, Then no se fabrican alternativas ni se presenta ausencia como fallo. Introducción manual queda fuera de esta entrega.

### 4. Configuración ausente o servicio fallido
Given falta configuración local, When intento identificar, Then se explica indisponibilidad de configuración y no hay HTTP ni éxito ficticio. Given error de red/timeout, 401/403, 429, 5xx, rechazo del modelo o respuesta inválida, Then error legible distinto de evidencia insuficiente, foto conservada y nuevo intento explícito posible; ningún reintento automático ni alta incompleta.

### 5. Cancelación, duplicados y respuesta tardía
Given petición en curso, When hago doble toque, Then solo una petición. When cancelo solicitud, Then se cancela la tarea/transporte y vuelvo a A sin publicar resultado tardío. When cierro borrador/gesto o termino app, Then no se restaura borrador ni resultado. Cancelar no garantiza retirar bytes ya enviados ni revertir consumo remoto.

### 6. Sustitución y aislamiento
Given resultado/error de A, When preparo B correctamente, Then se descarta resultado/error de A y B no se identifica automáticamente; si sustitución falla se conserva A y su resultado asociado. Given dos plantas locales, When identifico/cancelo/reintento y relanzo sin reseed/desinstalar, Then sus modelos/JPEG completos siguen iguales y no hay planta/foto de borrador nueva persistida.

### 7. Configuración y destinatario vinculados
Given aceptación de DevExpert/chat, When cambia base URL (origen o camino), proveedor o modelo, Then no se reutiliza ese consentimiento: destino no aprobado bloquea localmente con cero HTTP; destino/perfil aprobado exige su aviso/alcance nuevo. Given DevExpert sin clave, Then unavailable/cero HTTP. Given otro endpoint aprobado con política optional sin clave y aceptación de su alcance, Then se permite petición sin Authorization, nunca `Bearer` vacío. Cambiar configuración durante un aviso invalida intención y obliga a reevaluar destino/consentimiento, no redirige la foto.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md` (estado/registro reciente; lectura devuelta hasta línea 156), `feature_list.json`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `.gitignore`.
- Skill `feature-spec` cargada y su `references/spec-template.md`; `.agents/skills/ios-clean-mvvm/SKILL.md` leída/aplicada.
- `CONTEXT.md`, `docs/{build-brief,domain-model,risks-and-open-questions}.md`, `DESIGN.md`, `docs/adr/003-external-ai-consent.md`, `docs/specs/external-ai-consent.md`.
- `PlantCareAI/PlantCareAIApp.swift`: composición, fábrica por apertura, continuación de producción `.unavailable`, spies Debug.
- `PlantCareAI/Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift` y `Domain/IdentificationPhoto.swift`: JPEG efímero, estados/tareas/generaciones y punto de integración.
- `PlantCareAI/Features/ExternalAIConsent/Domain/{ExternalAIConsent,AuthorizeExternalAIOperationUseCase}.swift`, `Presentation/ExternalAIConsentView.swift`, `Data/ExternalAIConsentTestFixture.swift`.
- `PlantCareAITests/IdentificationConsentViewModelTests.swift`: bloqueo, duplicados, errores y cierre tardío; inventario de unitarias existente mediante glob.
- `PlantCareAIUITests/PlantCareAIUITests.swift` y `PlantCareAI.xcodeproj/project.pbxproj`: búsquedas focalizadas (no lectura completa), tests de consentimiento/foto y registro explícito Swift 5/iOS 17.
- `init.sh` completo: build, seed de fotos de prueba y unitarias/UI serializadas. Inventario `docs/specs`: esta spec no existía.
- Continuación documental: relectura de esta spec y aplicación de respuestas del usuario e investigación pública comunicada por orquestador. Fuentes externas siguientes consultadas por el orquestador, no directamente por este planner; sin credenciales ni solicitudes de inferencia/fotos.

### Investigación pública comunicada por orquestador (2026-10-10)

- `https://huggingface.co/deepseek-ai/DeepSeek-V4.1-Flash`: ficha oficial DeepSeek indica explícitamente procesamiento multimodal de imágenes/texto y ejemplos Chat Completions con `image_url`. Acredita visión **a nivel modelo** DeepSeek V4.1 Flash; resuelve esa duda sin pedir al usuario investigar de nuevo.
- `https://api-docs.deepseek.com/guides/vision/`: guía oficial de API directa DeepSeek para `deepseek-flash`, imágenes en mensajes user mediante `image_url` con `data:image/jpeg;base64`. No verifica el gateway DevExpert ni permite heredar sus límites, configuración o formato de salida.
- `https://huggingface.co/XiaomiMiMo/MiMo-V2.6-Pro-RL`: ficha oficial Xiaomi indica Text/Image/Video/Audio, native omnimodal y vision encoder. La variante Pro-RL respalda capacidad multimodal de la familia V2.6, pero no acredita el mapping exacto `mimo-v2.6-pro` servido por DevExpert.
- `https://inference.devexpert.io`: según orquestador, no devolvió texto útil y la búsqueda no encontró documentación `image_url`. Ausencia de documentación localizada no demuestra falta de soporte; compatibilidad del gateway sigue sin acreditar.
- Recomendación inicial del planner: `chat` por mapping comunicado a DeepSeek V4.1 Flash con visión oficial. **Posteriormente aprobado por usuario como modelo elegido**, no probado en DevExpert. `chat-pro` sigue alternativa plausible no elegida, sin fallback automático ni superioridad demostrada para plantas. Comprobación futura real requiere autorización/configuración local; no enviar fotos ni solicitudes de inferencia en planificación.

### Patterns / Gaps

- View → VM → Domain ← Data, composición App; Domain Foundation-only. Reutilizar borrador/preview y autorización, no Data en vistas ni lógica en ContentView.
- `IdentificationContinuationResult` vive actualmente en Domain de consentimiento y solo tiene `.unavailable`; VM ignora el valor `.completed`. Se debe migrar al contrato real de identificación, no agregar modelos botánicos al consentimiento.
- No hay transporte IA/configuración real. El aviso declara explícitamente que aún no envía; debe actualizarse antes de conectar API.
- XCUITest es E2E persistente mediante `./init.sh`. Fixtures actuales prueban consentimiento sin red; no equivalen a visión real.
- Proveedor/ruta/autenticación ahora confirmados por usuario: DevExpert, POST `https://inference.devexpert.io/v1/chat/completions`, `Authorization: Bearer <clave local>`. Sin clave suministrada ni petición ejecutada.
- Aliases comunicados: `chat` = `deepseek/deepseek-v4.1-flash`; `chat-pro` = `mimo-v2.6-pro`. Usuario elige `chat` como valor de `model`; fuentes oficiales acreditan visión del primero a nivel modelo y respaldan familia multimodal del segundo con límite de variante/mapping, no input de visión del gateway. `jev` (`/decisions`), `tts`, `transcribe`, `embedding`, `image` (`/images/generations`) e `image-edit` (`/images/edits`) fuera de esta feature; generación/edición no demuestra identificación. Verificar posteriormente que gateway acepta `model: "chat"`, sin convertir esa comprobación en una nueva pregunta de elección al usuario.

## Technical Approach (propuesta condicionada a revisión)

### Domain: `Features/IdentifyCandidates/Domain`

- `IdentificationResult.swift`: resultado efímero ligado en Presentation a `IdentificationPhoto.id`, con outcome `proposals` o `insufficientEvidence`, principal opcional según outcome, alternativas y explicación de incertidumbre. `SpeciesCandidate` contiene nombre común/científico opcionales, al menos uno no vacío; sin porcentaje, `confirmed`, UUID de planta ni entidades persistentes.
- `SpeciesIdentificationRepository.swift`: una frontera real `identify(photo:) async throws -> IdentificationResult` y errores tipados (configuración, red/timeout, autorización del servicio, rate limit, servicio, rechazo/invalidResponse). No distinguir consentimiento fallido como fallo HTTP.
- `IdentifyCandidatesUseCase.swift`: caso de uso inyectado sobre repositorio; validar invariantes del resultado, cancelación y foto no vacía/acotada. Solo invocarlo dentro de la continuación autorizada del VM; el caso de uso no introduce una segunda barrera ni tareas automáticas.
- Invariantes: propuestas requieren principal; insufficientEvidence no admite principal/alternativas; no duplicados vacíos ni resultados presentados como confirmados. No mapear fallo de parseo a insufficientEvidence.
- Retirar/mover `IdentificationContinuationResult` del dominio de consentimiento y adaptar consumidores/tests/spy explícitos a un contrato propio de identificación con caso unavailable de configuración si se mantiene ese camino. La barrera genérica de consentimiento no cambia ni conoce candidatas.

### Data: `Features/IdentifyCandidates/Data`

- `OpenAICompatibleSpeciesIdentificationRepository.swift`: URLSession inyectable, serialización/mapeo internos, sin SDK ni DTO externos en Domain. Solicitud única no streaming; JPEG preparado como imagen según protocolo elegido, prompt fijo en español; no enviar ni recuperar datos locales extra.
- `IdentificationAPIConfiguration.swift`: leer configuración runtime mediante composición; variables `API_BASE_URL`, `API_MODEL`, `API_KEY`. Valores de demo aprobados: `https://inference.devexpert.io/v1` y `chat`; URL/modelo configurables no implican aprobación de otros destinos/procesadores. URL/modelo ausentes, placeholder o destino no aprobado → unavailable/cero HTTP. No fallback automático a `chat-pro`/modelo textual.
- Construir POST a base normalizada + segmentos `chat/completions` **una vez**, preservando `/v1`: ejemplo final `https://inference.devexpert.io/v1/chat/completions`. Normalizar solo slash final; rechazar base que ya termina en `/chat/completions`, query/fragment, userinfo, segmentos ambiguos (`..`, slash codificado) o URL no HTTPS. Validar origen (host normalizado/puerto efectivo) y camino contra perfil aprobado, sin relajar ATS/TLS ni perder prefijo usando una ruta absoluta.
- Auth: política `required` para perfil DevExpert; `optional` solo para otros endpoints aprobados que no requieran autenticación. Derivarla del perfil de destinatario validado, **no agregar flag local para desactivar auth**. `API_KEY` ausente/vacía/solo espacios: DevExpert unavailable/cero HTTP; perfil optional permite omitir Authorization. Clave no vacía válida → `Authorization: Bearer <clave exacta>`; nunca Bearer vacío. Rechazar placeholders, CR/LF/caracteres inválidos o espacios exteriores inesperados, no recortar/modificar una clave real silenciosamente. Un 401/403 no dispara retry sin auth.
- Input/salida pendientes del gateway: `image_url` data URL JPEG + texto y JSON con `outcome`, `primary`, `alternatives`, `uncertainty`. No asumir que DevExpert admite data URLs, `response_format`, JSON Schema estricto o Responses API. Confirmar contrato/ejemplo antes de cerrar serialización/parseo; no fallback silencioso.
- Prompt solicita nombres solo cuando respaldados por imagen, incertidumbre descriptiva, alternativas solo plausibles, y insufficientEvidence cuando no pueda identificar; no porcentajes. Tratar respuesta como datos no confiables, no instrucciones ejecutables, HTML ni acciones de app.
- Propuesta de límites a aprobar: 0–3 alternativas, campos de nombre ≤160 caracteres, explicación ≤1000, respuesta HTTP ≤1 MiB, timeout total 60 s y límite de salida equivalente a ≤1000 tokens según API. Rechazar exceso/forma inválida sin truncar JSON ni fabricar éxito. Ajustar límite JPEG a capacidad real sin cambiar pipeline silenciosamente.
- Session efímera sin cache persistente de payload/respuesta, sin registro de headers/body/clave; no retries automáticos. Impedir redirecciones que reenvíen credencial/foto a otro host y no relajar ATS/TLS. Base64 aumenta memoria respecto al JPEG ≤5 MiB; medir/documentar, no afirmar memoria constante.
- Cancelación cooperativa propagada al URLSessionTask; no guardar resultado en UserDefaults/SwiftData/disco. HTTP success no basta: validar envelope, rechazo, contenido e invariantes.

### A2: configuración local aprobada; puente runtime propuesto para revisión

- Aprobado: `.xcconfig` local con clave nunca subido y plantilla `.example` sin secretos. Propuesta concreta para demo iOS: crear `Config/IdentificationDebug.xcconfig` versionado (sin clave), con include opcional de `IdentificationSecrets.local.xcconfig`; plantilla `Config/IdentificationSecrets.local.xcconfig.example` con valores vacíos/placeholder y guía de sintaxis xcconfig para URL/clave. Archivo local cubierto por `*.local.xcconfig` existente; verificar que está ignorado y no rastreado antes de introducir clave. No crear ninguno en planner.
- Variables necesarias: `API_BASE_URL`, `API_MODEL`, `API_KEY` (opcional según perfil). No introducir switches de auth/visión/consentimiento, rutas configurables adicionales ni matriz de configs. Propuesta opcional única `API_TIMEOUT_SECONDS`: default 60, rango 10–120 s, valor inválido → configuración inválida/cero HTTP; acota timeout total de operación y transporte, no solo inactividad. Los demás límites siguen propuestas constantes pendientes de aprobación.
- La plantilla futura debe preservar URLs pese a `//` como comentario xcconfig: técnica propuesta `SLASH = /` y `API_BASE_URL = https:$(SLASH)$(SLASH)inference.devexpert.io/v1` (SLASH es ayuda sintáctica, no variable runtime). Documentar escape/expansión xcconfig para clave y verificar roundtrip exacto con secretos sintéticos que incluyan caracteres especiales; no prometer que comillas bastan ni truncar por `//`, `$()` o comentarios. Si no es representable sin pérdida, fallar explícitamente y revisar codificación local, no enviar clave alterada.
- **Una variable de build no llega sola al runtime.** Puente todavía propuesto, no aprobado expresamente: solo target app Debug conecta `API_BASE_URL`, `API_MODEL`, `API_KEY` y timeout opcional a `INFOPLIST_KEY_PlantCareAIBaseURL`, `INFOPLIST_KEY_PlantCareAIModel`, `INFOPLIST_KEY_PlantCareAIAPIKey`, `INFOPLIST_KEY_PlantCareAITimeoutSeconds` del Info.plist generado. Composición lee entradas via Bundle y entrega valor a Data; VM/Domain no leen Bundle/build settings. Falta de include no rompe gate: defaults no sensibles DevExpert/chat, clave ausente → unavailable.
- Release no incluye configuración local ni estas entradas sensibles; configuración real limitada a demo Debug (simulador o iPhone firmado localmente), no a distribución. Comprobar recursos/binario Release para ausencia de clave usando inspección que no imprima su valor; fixtures no requieren clave. La plantilla debe documentar caracteres especiales/sintaxis y una comprobación local sin mostrar el secreto; no pegar claves en chat, esquema, argumentos de lanzamiento ni comandos/logs.
- **Este puente no custodia una clave en distribución:** Info.plist del Debug y app firmada contienen credencial extraíble; Keychain posterior u ofuscación no eliminan exposición al incluirla en app. Solo demo personal, credencial de alcance/cuota restringidos si DevExpert lo permite y rotación/revocación al terminar; no asegurar esas capacidades del proveedor. Mantener DerivedData/artefactos locales privados, no compartir .app/.ipa/xcresult/settings/logs con secreto, no usar `-showBuildSettings` con clave ni publicar archivos de configuración.
- El mecanismo no es seguridad comercial: sin backend no hay custodia apropiada. Confirmar el puente Debug→Info.plist y exclusión Release antes de implementarlo; no añadir ahora llave, SDK, Keychain, permiso ni backend.

### Vincular destino configurable a consentimiento (propuesta para aprobación)

- Resolver en composición un perfil aprobado, no confiar en etiquetas configurables: perfil inicial DevExpert fija nombre visible, origen `https://inference.devexpert.io:443`, base `/v1`, endpoint `/v1/chat/completions`, modelo `chat`, procesador/mapping comunicado `deepseek/deepseek-v4.1-flash`, auth required y versión de aviso. No hay variables `recipient`/`consentAccepted` que permitan disfrazar otro host como DevExpert.
- Propuesta de alcance: Domain conserva identificador opaco y versión, sin URLs ni proveedor imports. Composición/Data generan `recipient = "devexpert:" + SHA256(serialización canónica de origen + camino base/endpoint + modelo exacto + revisión del mapping/procesador aprobado)` y `noticeVersion = 2`, con serialización inequívoca. Aviso usa nombre legible del mismo perfil y versión/alcance de datos/finalidad aprobado. Clave y timeout **no** forman parte del fingerprint; rotar clave no renueva consentimiento por sí solo.
- Cualquier cambio de origen, puerto, camino, proveedor, modelo o mapping/procesador cambia fingerprint; cambio de texto/datos/finalidad incrementa versión. Cambio incluso conservador de modelo renueva, aunque se desconozca si afecta procesador. Un cambio remoto de mapping conocido exige actualizar revisión/aviso antes de red; no prometer detección automática de subproveedores ocultos ni inventar su identidad.
- URL/modelo distintos del perfil inicial son configurables pero fail-closed hasta registrar **otro perfil revisado/aprobado** con identidad visible, destino canónico, modelo/procesador conocido o incertidumbre declarada, auth required/optional y aviso. Nunca reutilizar scope DevExpert para endpoint arbitrario, ni autorizarlo solo por HTTPS o por API compatible. Aprobar otros endpoints no implementa selector UI, cuentas ni discovery automático.
- Capturar configuración/perfil/scope inmutables por intención y usar la **misma instancia** para barrera, aviso y transporte. Inyectar scope explícito en `AuthorizeExternalAIOperation`, no `.current` provisional fijo. Antes de invocar comprobar que snapshot sigue vigente; cambio invalida intención/resultado pendiente y exige nueva validación/aviso. Transporte rechaza destino distinto del snapshot y toda redirección (también mismo host con otro camino) para impedir bypass de consentimiento/credencial.

### Presentation y composición

- Extender `IdentificationPhotoViewModel` existente, sin segundo VM artificial: inyectar caso de uso mediante continuación tipada, consumir `.completed(value)` y separar estado de autorización de identificación `idle/loading/result/failed/unavailable`.
- Resultado pertenece al snapshot de selección; generaciones/cancelación impiden publicar después de cierre/cancelación. Bloquear sustitución y doble toque durante aviso/petición; habilitar sustitución tras terminar/cancelar. Sustitución exitosa limpia resultado anterior, fallida lo conserva.
- Agregar `Features/IdentifyCandidates/Presentation/IdentificationResultView.swift`, solo lectura. La foto y modal actuales continúan; acción explícita «Cancelar solicitud» cancela sin perder foto, distinta de «Cancelar» del modal que descarta todo.
- App compone configuración/perfil validado → scope explícito de consentimiento y Data adapter del mismo snapshot → IdentifyCandidates → continuación dentro de AuthorizeExternalAIOperation; no HTTP en init/fábrica. Aplicar fingerprint/versión propuestos arriba, nunca `prototype-external-ai`/1 ni `devexpert` fijo independiente de URL/modelo. Aviso nombra **DevExpert**, no OpenAI ni modelos como destinatarios legales; otro perfil aprobado usa su propio nombre/aviso.
- Texto de identificación propuesto: «Para proponer una especie, enviaremos a DevExpert la foto que has elegido y una instrucción de identificación. La propuesta puede ser incorrecta y no confirma ninguna especie. Puedes cancelar antes del envío; una vez enviado, cancelar no retira los datos ya transmitidos. Recordaremos tu aceptación en este dispositivo para futuras solicitudes que tú inicies dentro del alcance de este aviso». Revisar cuerpo completo vigente para que nombre DevExpert y describa también el alcance textual/fotos de futuras funciones si se conserva autorización común; no afirmar retención, borrado remoto, no entrenamiento, región ni subproveedores desconocidos. Retirar la aclaración «no se envía todavía» solo al habilitar transporte configurado.
- Tests usan repositorio/URLProtocol controlados y fixture opt-in Debug Simulator, excluido de Release; sin fallback de resultados falsos en producción. Conservar spy aislado de consentimiento para pruebas históricas, adaptando tipos sin debilitar conteos.

## Expected File Changes (futuros; solo spec escrita ahora)

- Crear `PlantCareAI/Features/IdentifyCandidates/Domain/{IdentificationResult,SpeciesIdentificationRepository,IdentifyCandidatesUseCase}.swift`.
- Crear `.../Data/{IdentificationAPIConfiguration,OpenAICompatibleSpeciesIdentificationRepository}.swift` y `.../Presentation/IdentificationResultView.swift`; DTO privado o archivo Data adicional solo si necesario.
- Modificar `PlantCareAI/Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift` y `PlantCareAI/PlantCareAIApp.swift`.
- Modificar `PlantCareAI/Features/ExternalAIConsent/Domain/ExternalAIConsent.swift`, `Presentation/ExternalAIConsentView.swift` y `Data/ExternalAIConsentTestFixture.swift`: scope opaco inyectado/aviso parametrizado por perfil aprobado y migración del tipo temporal; no cambiar algoritmo fail-closed de barrera ni introducir URLs en Domain.
- Modificar `PlantCareAI/Localizable.xcstrings`, `PlantCareAI.xcodeproj/project.pbxproj`: textos realmente usados, registro de nuevas fuentes/tests y conexión Debug de configuración tras aprobar puente runtime; sin valores sensibles versionados.
- Crear en implementación `Config/IdentificationDebug.xcconfig` y `Config/IdentificationSecrets.local.xcconfig.example` sin secretos. `Config/IdentificationSecrets.local.xcconfig` lo aporta localmente quien prepara la demo, ignorado/no rastreado, jamás entregado. `.gitignore` no necesita cambio si cobertura real de nombre elegido se verifica.
- Crear `PlantCareAITests/{IdentifyCandidatesTests,OpenAICompatibleSpeciesIdentificationRepositoryTests}.swift`; extender tests VM de foto/consentimiento y `PlantCareAIUITests/PlantCareAIUITests.swift`.
- Opcional fixture `.../Data/IdentificationCandidatesTestFixture.swift` Debug Simulator opt-in; crear `docs/testing-identify-candidates.md`. No cambio de init.sh por defecto.

## Visual Design Impact / D1 aprobado

- UI: sí, mínima necesaria por comportamiento observable y DESIGN §Identificación: espera con foto, resultado, incertidumbre y errores. No hay adjuntos visuales accesibles; el usuario aprobó explícitamente D1, bloque nativo mínimo solo lectura. No se requiere artefacto visual adicional.
- Bloque aprobado en el ScrollView actual, debajo de foto, encabezados «Propuesta de especie»/«Otras posibilidades», nombres y explicación «Es una propuesta de IA, no una especie confirmada»; sin filas seleccionables, checkmarks ni CTA Confirmar/Continuar.
- insufficientEvidence propone texto prudente y reutiliza galería/cámara para otra foto; no botón de especie manual sin feature implementada. Loading con foto visible, ProgressView y Cancelar solicitud; error con explicación/reintento explícito.
- Conservar tokens semánticos, tipografía sistema, contraste, objetivos ≥44 pt, texto envolvente/desplazable y etiquetas accesibles. No inventar porcentajes, badges de certeza ni estética diagnóstica.
- **D1 resuelto por aprobación explícita posterior:** no volver a pedir diseño para este bloque; selección/confirmación y su diseño pertenecen a `confirm-species`. D1 no implica aprobación íntegra de spec, modelo/API, límites ni puente runtime.

## Durable Documentation Impact

- Ahora: solo `docs/specs/identify-candidates.md`; feature_list/PROGRESS sin cambios de estado ni evidencia funcional nueva.
- `ARCHITECTURE.md`: actualizar durante implementación para nuevas capas, transporte/configuración, resultados efímeros y desaparición de indisponibilidad cuando esté configurado.
- `CONSTRAINTS.md`: actualizar si mecanismo aprobado añade regla duradera de configuración/redirecciones/límites; conservar barrera/secretos y límites de distribución.
- `AGENTS.md`: no necesario, workflow y política no cambian. `DESIGN.md`: no necesario, D1 aprueba bloque mínimo compatible; no se redefine dirección visual durable.
- `docs/domain-model.md`: actualizar afirmación temporal sin IA/red, precisar propuesta efímera vs confirmación; sin nueva entidad persistente. `CONTEXT.md`/`docs/build-brief.md`: no necesario, producto/vocabulario existentes bastan.
- `docs/risks-and-open-questions.md`: actualizar decisiones API aprobadas y límites reales de validación/memoria/coste; no inventar garantías de retención externa.
- Proponer `docs/adr/004-openai-compatible-identification.md` tras revisión: contrato multimodal, configuración local, renovación de consentimiento y migración del tipo temporal que afecta callers/tests de dos features; no registrarlo como aprobado ahora.
- `docs/testing-identify-candidates.md`: fixtures, pasos con API real/clave fuera del repo, limpieza y evidencia sanitizada. Roles posteriores registran resultados reales en PROGRESS/feature_list.

## Implementation Plan / Tasks

1. Resolver contrato gateway/input/JSON/límites, puente runtime A2 y binding/aviso/acceso A3; D1 y `chat` aprobados, visión del modelo acreditada. Completar spec y obtener aprobación íntegra antes de implementer; no sustituir compatibilidad DevExpert por API directa DeepSeek.
2. En rol posterior, verificar worktree/estado y coordinar baseline; preservar spec aprobada y cambios ajenos.
3. Implementar contrato/caso de uso y migración del tipo temporal; tests de invariantes y seam real de repositorio.
4. Implementar adaptador/configuración aprobados, tests HTTP/mapping/cancelación, límites y consentimiento renovado.
5. Integrar resultado/espera/error mínimo aprobado, pruebas VM y E2E; registrar fuentes y actualizar docs.
6. Ejecutar verificación serial y escenario real autorizado, capturar evidencias/limitaciones y entregar a validator independiente; no iniciar otra feature.

- [x] D1 aprobado; DevExpert/base/ruta/Bearer y modalidad `.xcconfig` local + plantilla confirmados.
- [x] Investigación pública del orquestador acredita visión de DeepSeek V4.1 Flash a nivel modelo; no acredita gateway DevExpert.
- [x] Usuario aprueba `chat` configurable, URL configurable y clave opcional según API; DevExpert sigue required.
- [ ] Revisar puente runtime, binding perfil/scope, aviso/límites y contrato gateway/input/JSON; aprobar spec completa.
- [ ] Domain no confirma ni persiste; transporte únicamente dentro de barrera vigente.
- [ ] Parseo/errores/configuración/cancelación/redirecciones y respuesta insuficiente cubiertos.
- [ ] Resultado asociado a A; doble toque, cierre, B y respuestas tardías cubiertos.
- [ ] UI mínima/E2E, proyecto/localización, docs y seams excluidos de Release.
- [ ] Gate completo, inspección básica y prueba real documentados por roles posteriores.

## Verification Plan (futuro; NO ejecutado en planificación)

- Coordinar con sesión activa, un iPhone Simulator estándar/texto normal/una apariencia, ejecuciones seriales y tapa abierta; reutilizar evidencia válida cuando proceda.
- `caffeinate -dius ./init.sh`: build y todas las unitarias/UI; sigue terminando sin servicios largos y sin exigir credencial/red en el gate determinista. No modificar mientras corre.
- Focalizadas: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID_ESTANDAR>' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO -only-testing:PlantCareAITests/IdentifyCandidatesTests -only-testing:PlantCareAITests/OpenAICompatibleSpeciesIdentificationRepositoryTests -only-testing:PlantCareAITests/IdentificationConsentViewModelTests -only-testing:PlantCareAIUITests/PlantCareAIUITests test`.
- HTTP con URLProtocol/contador: rechazo aviso=0, aceptación antigua renueva/0 hasta aceptar, vigente=1 por intención, payload contiene exactamente JPEG actual + prompt (sin UUID/contexto ajeno); validar POST `/v1/chat/completions`/host DevExpert y Bearer sin imprimir secreto sintético, modelo/input/salida según A1 resuelto, errores/status, malformed/refusal/límites/timeout y redirección bloqueada.
- Configuración: base `/v1` con/sin slash final → exactamente `/v1/chat/completions`; rechazar doble endpoint/URL ambigua/no HTTPS. DevExpert sin clave → 0 HTTP; endpoint optional aprobado sin clave → sin Authorization; clave válida → Bearer exacto nunca vacío. No retry sin auth tras 401. Timeout default/rango y roundtrip URL/clave sintética (incluidos caracteres xcconfig problemáticos) sin truncamiento.
- Consentimiento: aceptación DevExpert/chat no autoriza otro host/puerto/camino/modelo/procesador; perfil desconocido → 0 HTTP, perfil nuevo aprobado → nuevo aviso; misma clave rotada no cambia scope. Cambio durante aviso bloquea snapshot viejo, redirecciones bloqueadas incluso mismo host. Verificar scope/aviso/transporte concordantes, sin recipient configurable falso.
- Debug obtiene variables mediante Info.plist generado (no solo build settings); Release sin clave/entradas sensibles ni seams. Auditar ignorado/no rastreado y plantilla sin secretos antes de clave real; registrar solo resultado de comprobación, nunca contenido/settings con secreto.
- VM/Domain: propuestas sin confirmar, sin alternativas, insufficientEvidence, ningún porcentaje sintetizado, error distinto de insuficiencia, cancelación/late response, doble toque, reintento, B limpia A y fallo de B conserva A.
- XCUITest E2E persistente: bloque de lectura, alternativas/ausencia/insuficiencia mediante fixtures explícitos, progreso con foto/cancelación, error/reintento, aviso/gesto, cerrar/reabrir vacío y dos plantas/modelos/JPEG completos intactos tras relanzamiento sin reseed/desinstalar. Conservar picker real y todas las assertions funcionales previas; actualizar solo expectativas obsoletas de indisponibilidad cuando la configuración real existe.
- Inspección visual básica de espera/resultado/insuficiencia/error/aviso actualizado en ese simulador: español sin claves crudas, nombres/explicación largos y desplazamiento con texto normal, acciones alcanzables y no seleccionables hasta confirm-species.
- Con A1–A3 resueltos y autorización, identificar una foto real de planta y una de evidencia insuficiente con API real; registrar solo evidencia sanitizada, modelo/destinatario no sensible, incertidumbre y ausencia de confirmación/persistencia. Fixture/URLProtocol NO sustituyen este requisito de feature_list. Sin acceso real no marcar passing ni aceptar feature completa; informar bloqueo.
- En roles posteriores: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON catálogo/feature_list, `git diff --check` y build Release/auditoría de seams si se añaden; nunca sustituyen gate/escenario real.
- SE/pantallas pequeñas, texto aumentado/máximo, VoiceOver/Accessibility Inspector y matrices: fuera de verificación habitual, no ejecutadas salvo petición expresa; no bloqueos automáticos.

## Evidence To Capture / Riesgos y pendientes bloqueantes

- Capturar logs/xcresult/resultados/destino, capturas realmente inspeccionadas, contadores de transporte 0/1 y orden aceptación→HTTP, cancelación y conservación completa de ambas plantas. Separar dobles de API real; no logs de JPEG/base64/contexto/headers/clave ni respuesta cruda sensible.
- **A1 elección resuelta:** usuario aprueba `API_MODEL=chat`, `API_BASE_URL=https://inference.devexpert.io/v1`, ambos configurables; `API_KEY` opcional solo donde perfil aprobado lo permita, DevExpert required según documentación comunicada por usuario. Visión DeepSeek acreditada a nivel modelo; `chat-pro` no elegido ni fallback. No volver a preguntar elección ni capacidad del modelo.
- **A1 pendiente de gateway:** verificar aceptación de `model: "chat"`, `image_url` data URL JPEG, límites y salida JSON/`response_format`/rechazos en DevExpert, sin heredar límites DeepSeek directo. Comprobación real futura autorizada con clave local/foto permitida, no requests ahora; aprobar/adaptar límites y presupuesto de demo.
- **A2 modalidad aprobada:** `.xcconfig` local + plantilla sin secretos; variables mínimas API_BASE_URL/API_MODEL/API_KEY y timeout opcional acotado propuesto. Puente Debug→Info.plist/Release sin clave aún no aprobado expresamente; revisar escape/roundtrip y exposición de clave extraíble. No aportar secretos al planner/conversación.
- **A3 parcialmente resuelto:** destinatario visible DevExpert. Revisar binding perfil canónico + modelo/procesador → fingerprint/scope/versión y aviso completo; ningún otro endpoint aprobado todavía. Confirmar quién aportará acceso local/fotos autorizadas para prueba futura. No inventar retención/subproveedores ni permitir URL nueva bajo aceptación anterior.
- **D1 resuelto:** bloque nativo mínimo solo lectura aprobado explícitamente; no queda duda de diseño para esta feature.
- Otros riesgos: alucinaciones, incertidumbre verbal no calibrada, incompatibilidad de APIs «compatibles», coste/latencia y memoria de base64; mitigación mediante validación de forma, cancelación, límites y confirmación humana posterior, no garantía de exactitud.
- Tamaño adecuado: un agregado efímero de resultado y un flujo de identificación sobre foto existente; no requiere dividir mientras no se añadan selección/alta/configuración de cuenta.

## Validator Checklist

- [ ] Spec íntegra aprobada antes de implementar; D1/`chat`/configuración flexible confirmados; gateway/input/JSON acreditado; puente runtime/binding consentimiento/aviso/límites aprobados.
- [ ] Capas/composición y migración del contrato temporal correctas; ninguna candidata en Domain de consentimiento.
- [ ] Transporte pasa barrera del mismo snapshot destino/modelo/procesador; scope nuevo ante cambios, perfil desconocido bloqueado; rechazar=0, una petición por intención y sin envíos al abrir/reabrir. Auth required DevExpert no eludible; optional sin Bearer vacío solo en perfil aprobado.
- [ ] Propuestas/alternativas/insuficiencia visibles sin porcentajes ficticios, confirmación, cuidado ni persistencia.
- [ ] Cancelación/error/reintento/late responses/sustitución e integridad de dos plantas comprobados.
- [ ] Gate/regresiones/E2E y visual básica presentes; fixtures distintos de verificación real con API.
- [ ] Credencial/payload no versionados/registrados, seams ausentes en Release, límites/redirecciones verificados.
- [ ] Docs y estados reflejan solo pruebas ejecutadas; passing no es aceptación independiente.

**Siguiente paso exclusivo: revisión del usuario y resolución de pendientes. Detener planner; no implementar ni validar.**
