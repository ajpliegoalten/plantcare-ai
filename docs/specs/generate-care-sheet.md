# Feature Implementation Spec: Revisar ficha orientativa generada

## Source Feature

- `id`: `generate-care-sheet`; `area`: `cuidados-ia`.
- `depends_on`: `confirm-species`, `manual-species`, `external-ai-consent`, todas `accepted` en `feature_list.json`.
- `status`: `not_started`; fuente: `feature_list.json`, título «Revisar ficha orientativa generada».
- Comportamiento: tras confirmar especie, generar cuidados breves revisables antes del alta.
- Verificación origen: vía propuesta y manual, seis campos esenciales y fallo sin alta incompleta.
- Planificación: 2026-10-11, worktree exclusivo `generate-care-sheet`, rama/base comunicadas por padre `feature/generate-care-sheet` / `8b0022d8049d8ac300820f5cfe2c6a542f69a54f`.
- Contrato pendiente de revisión del usuario. Esta ejecución solo crea la spec; no implementa, prueba ni cambia estados.

## Goal

El botón común «Confirmar especie» confirma la opción activa e inicia directamente la generación de cuidados, tanto para candidata/alternativa como para nombre manual. **No mostrar la pantalla/resumen temporal `ConfirmedSpeciesView`, ni añadir otro botón «Generar cuidados» entre confirmación y solicitud.** La espera, el consentimiento si procede, los errores y la ficha son estados del mismo borrador efímero.

Obtener una ficha orientativa válida de seis campos, revisable y vinculada exactamente a foto e identidad confirmadas. No persistir ni añadir todavía: `save-plant` consumirá posteriormente ese resultado validado.

## Non-Goals

- Alta, formulario de nombre/ubicación, escrituras de plantas/JPEG, historial o cambios de esquema SwiftData.
- Editar cuidados, regeneración arbitraria de una ficha válida, RAG/fuentes verificadas, diagnóstico, calendarios o alertas de riego.
- Nuevos proveedores, SDK, backend, configuración/clave adicional o refactor general del transporte de identificación.
- Poda/trasplante/problemas comunes opcionales: no imprescindibles en este corte; no ampliar `CareSheet` para ellos.
- Nuevo diseño Stitch, assets decorativos, matrices ampliadas de dispositivos/apariencia/accesibilidad.

## Job Story / Users And Permissions

Cuando confirmo la especie de mi foto, quiero recibir cuidados claros directamente para revisarlos antes de crear mi ejemplar. Usuario único local; confirmación humana no equivale a certificación botánica ni a consentimiento implícito de cualquier destino. Cada envío externo cruza `AuthorizeExternalAIOperation`.

## Acceptance Scenarios

### 1. Propuesta o alternativa → cuidados directamente
Given foto actual identificada y opción elegida explícitamente, sin preselección,
When pulso «Confirmar especie»,
Then se confirma esa opción y empieza una sola intención de cuidados; foto visible, espera «Generando cuidados…» y cancelación; no aparece el resumen temporal ni otro CTA previo. Seleccionar/deseleccionar por sí solo hace cero llamadas de cuidados. Al terminar se ven únicamente identidad escogida y los seis cuidados completos, no los de la principal si elegí alternativa.

### 2. Manual vigente → el mismo recorrido
Given identificación exitosa actual con cero o más candidatas, opción «Aportado por ti» seleccionada y nombre manual válido,
When confirmo mediante el mismo botón,
Then se normalizan solo extremos, se mantiene el nombre/procedencia humana sin inventar nombres botánicos y se solicita la misma ficha directamente. Texto blanco no confirma/envía. Manual sigue oculto antes de identificar, durante espera o ante error; no restaurar su disponibilidad histórica anterior.

### 3. Consentimiento y configuración
Given alcance no aceptado, antiguo o destino/modelo/aviso cambiado,
When la confirmación intenta generar cuidados,
Then el aviso informa datos/finalidades/destino/modelo antes de HTTP; rechazar/gesto/cerrar deja cero solicitudes de cuidados. Aceptar ejecuta una sola solicitud. Alcance vigente ya aceptado no repite el aviso. Configuración ausente/no vigente o fallo de lectura/registro impide HTTP y muestra error recuperable, conservando foto/identidad.

### 4. Fallo, respuesta incompleta o especie no utilizable
Given una solicitud autorizada,
When falla conexión/timeout/401/429/servicio, hay rechazo, JSON inválido/truncado o falta/vacío un cuidado,
Then no se publica ficha parcial ni hay alta/guardar habilitado; se conservan foto e identidad, mensaje específico sanitizado y «Reintentar cuidados»/«Cambiar especie». Cada reintento explícito crea una sola solicitud; nunca retry automático ni texto de relleno que aparente éxito. Nombre desconocido/ambiguo puede resultar en rechazo explícito, no cuidados inventados.

### 5. Cancelar, duplicados y respuestas tardías
Given solicitud en marcha o aviso abierto,
When cancelo solicitud/aviso, cierro o hago dismiss del borrador,
Then se cancela trabajo local y se descarta cualquier respuesta tardía; cancelar solicitud conserva identidad/foto y permite reintento, cerrar elimina todo. Doble tap/reaparición de vista no duplica envío. Cancelar no promete retirar bytes ni coste remoto ya producido.

### 6. Cambiar identidad o foto
Given ficha válida, fallida o cancelada,
When cambio especie,
Then vuelvo al selector vigente sin envío automático, con precarga manual cuando corresponda y reconfirmación requerida. Durante edición se oculta la ficha y su elegibilidad; Cancelar edición restaura identidad/ficha anteriores sin llamada. Confirmar nueva elección descarta ficha anterior e inicia nueva generación incluso con nombres iguales (nueva intención/revisión). Volver explícitamente a propuestas desde manual requiere reconfirmar.
Given foto A con ficha,
When publico foto B o inicio reidentificación,
Then invalido cuidados junto a identidad según reglas actuales; reemplazo fallido/cancelado conserva A y ficha. En busy no se permite cambiar foto/especie/identificar; cancelar primero. Respuestas de otra foto/identidad/revisión nunca se publican.

### 7. Revisión efímera y aislamiento
Given respuesta válida,
When reviso/scroll hasta Abonado y cierro/reabro o relanzo,
Then los seis textos son íntegros y legibles en español, con aviso breve de orientación, identidad/procedencia y foto existentes; no persiste el borrador. Dos plantas guardadas conservan metadata/fichas/JPEG idénticos. No hay CTA falso de alta ni formulario adelantado.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md` (estado reciente), `feature_list.json`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `CONTEXT.md`, `DESIGN.md`.
- `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`; ADR `004-openai-compatible-identification.md`, `005-confirmed-draft-identity.md`.
- Skills locales `feature-spec`/plantilla e `ios-clean-mvvm/SKILL.md`, aplicadas a este plan.
- `PlantCareAI/Features/IdentificationPhoto/Presentation/IdentificationPhotoView{,Model}.swift`: dueño único del borrador, generaciones, selección manual/IA y autorización hoy solo de identificación.
- `PlantCareAI/Features/ConfirmSpecies/{Domain/ConfirmedDraftIdentity.swift,Presentation/ConfirmedSpeciesView.swift}`: identidad discriminada y resumen a retirar del recorrido.
- `PlantCareAI/Features/PlantList/Domain/CareSheet.swift`: modelo existente con seis Strings; no duplicarlo ni cambiar persistencia.
- `PlantCareAI/Features/IdentifyCandidates/Data/{IdentificationAPIConfiguration,OpenAICompatibleSpeciesIdentificationRepository}.swift`: snapshot, scope v3, endpoint Chat Completions, parseo y límites.
- `PlantCareAI/Features/ExternalAIConsent/{Domain/AuthorizeExternalAIOperationUseCase,Presentation/ExternalAIConsentView}.swift`: barrera genérica y aviso hoy específico de identificación.
- `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI.xcodeproj/project.pbxproj` (registro explícito), `init.sh`.
- `PlantCareAITests/{ConfirmSpeciesViewModelTests,ManualSpeciesViewModelTests,OpenAICompatibleSpeciesIdentificationRepositoryTests}.swift` (secciones de patrones relevantes).
- `PlantCareAIUITests/PlantCareAIUITests.swift` (escenarios manual/confirmación y nombres de regresiones); claves relevantes localizadas en `Localizable.xcstrings`, no catálogo completo inspeccionado.

### Existing Patterns / Gaps

- SwiftUI iOS 17+, `@StateObject`, MVVM por feature, casos Domain inyectados; composición exclusiva en App. `ContentView` no recibe pantalla/lógica nueva.
- Foto y selección tienen UUID; generaciones/cancelación impiden respuestas obsoletas. Tests con dobles Domain, URLProtocol y fixtures Debug Simulator; XCUITest es E2E persistente.
- No existe `GenerateCareSheet`, repositorio de cuidados ni estado de generación; resumen vigente explícitamente dice que cuidados son futuros. `CareSheet` por sí solo no valida campos.
- Specs/evidencias aceptadas son históricas: no reescribirlas para aplicar este delta. Algunas frases durables aún dicen «resumen» o guardado al confirmar especie: corregir al implementar.
- Búsqueda local de PNG/JPEG/HTML/PDF sin resultados; recursos MCP disponibles: ninguno. No adjunto visual nuevo disponible ni referencia Stitch recuperable; `DESIGN.md` es autoridad. No se inspeccionaron secretos/artefactos privados.
- Raíz comprobada mediante lectura absoluta del directorio autorizado; no hay herramienta shell/pwd disponible en este planner. Rama/SHA/base limpia son contexto del padre, no verificación Git nueva.

## Technical Approach

### Domain — `Features/GenerateCareSheet/Domain`

- `CareSheetGenerationRepository.swift`: contrato async/Sendable para generar desde `ConfirmedDraftIdentity`; errores tipados (configuration, invalidInput, network, timeout, unauthorized, rateLimited, service, rejected, invalidResponse).
- `GenerateCareSheetUseCase.swift`: `GenerateCareSheet` valida identidad ligada al `photoID` actual, nombres necesarios y límites de entrada antes de IO; devuelve `CareSheet` existente tras validar seis textos. Sin UIKit/proveedor/rutas/persistencia.
- Foto se usa solo para vinculación local; **no se vuelve a enviar JPEG**. Payload contiene exclusivamente nombres confirmados y procedencia; sin alternativas, análisis de identificación, UUID, ubicación, otras plantas ni historial.
- Manual conserva contrato sin límite de edición/botánica. Límite defensivo de envío: máximo 2000 caracteres por nombre; superar produce error local claro, permite cambiar nombre, cero HTTP, sin truncar ni modificar identidad. IA actual tiene límite 160.
- Ficha válida: seis Strings no blancos, trim exterior, máximo 1000 caracteres por campo; sin HTML/Markdown renderizado, URLs/fuentes atribuidas ni nombres inferidos. Validación en caso de uso y mapper Data; no ampliar esquema local.

### Data — `Features/GenerateCareSheet/Data`

- `OpenAICompatibleCareSheetGenerationRepository.swift`: adaptador del mismo protocolo HTTP aprobado, misma `IdentificationAPIConfiguration` capturada; no segundo fichero de configuración ni proveedor diferente.
- POST único a endpoint existente, `stream:false`, `max_tokens:2000`, mensajes separados: instrucciones fijas español + objeto JSON serializado de nombres/procedencia como datos no confiables (también los de IA). No interpolar nombre como instrucciones; pedir ignorar órdenes en esos datos.
- Respuesta pedida por prompt, sin asumir `response_format`: `{outcome:"careSheet",careSheet:{light,watering,humidity,temperature,substrate,fertilizer}}` o `{outcome:"unavailable",careSheet:null}` si no puede orientar responsablemente. No campos vacíos para simular éxito. `unavailable` es rechazo recuperable sin ficha.
- Consejos breves escaneables, prudentes sobre condiciones/sustrato; no pauta universal «regar hoy», certezas, diagnóstico ni fuentes verificadas. Envelope una choice, finish_reason stop, sin refusal; JSON estructural estricto y tipos/invariantes verificados, rechazo/truncamiento como error.
- Reutilizar políticas actuales: sesión efímera sin cache/cookies/credentials, todos los redirects bloqueados, key opcional sin Bearer vacío, timeout snapshot 10–120 s/default 60, respuesta HTTP ≤1 MiB durante streaming, cancelación propagada, errores sanitizados, cero retries/logs crudos. Mantener identificación intacta salvo renovación de aviso; extracción compartida de transporte no necesaria en esta slice.

### Presentation / composición

- `Features/GenerateCareSheet/Presentation/CareSheetReviewView.swift`: componente de estados de cuidados sin adaptadores ni IO; usa el VM existente `IdentificationPhotoViewModel` como dueño único. No segundo VM/JPEG ni NavigationStack/modal nuevos para cuidados.
- VM inyecta caso de uso, autorización/notice/snapshot; añade estado explícito idle/checking/awaitingConsent/loading/loaded/failed/cancelled y token de generación asociado a foto + identidad + intención. `isBusy` incluye autorización/generación de cuidados.
- Confirmación local exitosa de **cualquiera** de las dos vías dispara generación exactamente una vez. Métodos puros Domain de confirmar no reciben red. Guard común/entrada programática impide bypass o confirmación obsoleta; aparición/render no dispara llamadas.
- Distinguir operación pendiente identification/careSheet al aceptar/cancelar aviso; el callback no debe ejecutar identificación por error ni borrar identidad con `clearIdentification()`. Verificar snapshot antes de autorizar/enviar/publicar y no comparar solamente nombres.
- Reintento explícito conserva identidad, revalida configuración/alcance, invalida token previo. Cierre/reidentificación/nueva foto exitosamente publicada invalidan ficha/tareas. Edición conserva snapshot anterior solo para cancelación no destructiva; no elegible durante edición.
- `PlantCareAIApp.swift` inyecta repositorio/caso de uso real con el mismo snapshot y repositorio de consentimiento; Release sigue indisponible honestamente. Fixture opt-in `CareSheetGenerationTestFixture.swift` solo Debug Simulator, seis campos distintivos por especie, error/incompleta/espera/long-text y contador separado de identificación.

### Consentimiento propuesto para aprobar con esta spec

- Renovar aviso real a **v4** para identificación de foto **y** generación textual de cuidados de especie confirmada; fingerprint incorpora revisión `notice-4`, mismo destino canónico/modelo. No heredar aceptación v3 porque cambia finalidad/payload; v1/v2 tampoco.
- Aviso declara foto para identificación y nombres/procedencia para cuidados, no reenvío de foto para ficha; conserva destino/modelo y límites remotos desconocidos. Con v4 aceptado al identificar, confirmar no repite aviso; operación de cuidados sigue cruzando boundary. Tests de migración v3→v4 obligatorios.
- Usar una aceptación global mínima ya existente, sin duplicar repositorio o prometer consentimiento por planta. Actualizar texto/claves con fallback español sin crear locale parcial.

## Expected File Changes

- Crear los tres archivos Domain/Data y `Presentation/CareSheetReviewView.swift` descritos bajo `Features/GenerateCareSheet/`; crear fixture Data Debug Simulator.
- Modificar `IdentificationPhotoView.swift`/`IdentificationPhotoViewModel.swift`: transición directa, estados, guards, tokens, acciones y edición/cancelación.
- Retirar uso de `ConfirmSpecies/Presentation/ConfirmedSpeciesView.swift`; eliminar archivo/registro y claves exclusivamente obsoletas si no quedan callers. No conservar fallback visible de resumen temporal.
- Modificar `PlantCareAIApp.swift`, `IdentifyCandidates/Data/IdentificationAPIConfiguration.swift`, `ExternalAIConsent/Presentation/ExternalAIConsentView.swift`, `Localizable.xcstrings` y registro explícito de app/tests en `project.pbxproj`.
- Crear `PlantCareAITests/{GenerateCareSheetTests,GenerateCareSheetViewModelTests,OpenAICompatibleCareSheetGenerationRepositoryTests}.swift`.
- Adaptar tests VM de confirmación/manual/consentimiento según callers y E2E `PlantCareAIUITests.swift`; conservar escenarios/assertions funcionales, sustituir solo expectativas del resumen/contador por nueva transición.
- Sin cambios necesarios en `CareSheet.swift`, repositorio local, `ContentView.swift`, `init.sh` ni configuración privada.

## Visual Design Impact

- UI: sí; fuente `DESIGN.md` y componentes SwiftUI actuales, sin artefacto Stitch adicional por instrucción del usuario.
- Mantener foto dominante y nombre exacto/procedencia en cabecera compacta de cuidados; no tarjeta intermedia «Especie confirmada»/aviso de cuidados futuros. Título nativo puede pasar a «Cuidados» en esta etapa, sin navegación apilada artificial.
- Carga/cancelado/error mantienen foto, identidad y acciones honestas. Éxito: seis bloques verticales etiquetados Luz, Riego, Humedad, Temperatura, Sustrato y Abonado; textos multilinea y scroll, aviso «Cuidados orientativos generados por IA» una vez, no certeza botánica.
- Paleta semántica crema/blanco/verde, márgenes 20/padding16/radio22 aproximados, tipografía sistema y cápsulas ≥44pt, labels accesibles y contraste. Selector inline/manual/toggle vigentes sin cambios estéticos ajenos; acciones secundarias Cambiar especie/Volver a identificar separadas.
- En éxito no añadir Guardar/Añadir/Continuar deshabilitado de utilería: alta pertenece a siguiente feature. No convertir identificación en chat.

## Durable Documentation Impact

- `ARCHITECTURE.md`: actualizar durante implementación, nueva feature/callers/estados, vínculo efímero y composición sin persistencia.
- `CONSTRAINTS.md`: actualizar referencia v3 a renovación v4; límites de privacidad existentes siguen rigiendo.
- `AGENTS.md`: no necesario, no cambia workflow ni startup.
- `DESIGN.md`: actualizar destino de Confirmar (IA/manual) del resumen a cuidados directos; conservar selección vigente.
- `docs/domain-model.md`, `docs/build-brief.md`: actualizar delta vigente y aclarar ficha solo en memoria hasta alta (corregir «se guarda ... al confirmar»); no reescribir historias aceptadas.
- Crear ADR breve `docs/adr/006-care-sheet-generation.md` al implementar/aprobar: intención combinada confirmación→cuidados, datos mínimos, vínculo/sesiones, consentimiento v4 y migración.
- `docs/risks-and-open-questions.md`: registrar límites de cuidados y evidencia real actual sin arrastrar bloqueos históricos como nuevos resultados.
- Crear `docs/testing-generate-care-sheet.md` y handoff con comandos seguros/escenarios reales; `PROGRESS.md`/`feature_list.json` solo al implementar con evidencia real. Planner no altera estado ni docs durables todavía.

## Implementation Plan / Tasks

1. Aprobar esta spec y renovación de aviso; revisar callers/tests afectados y documentación contradictoria sin tocar specs aceptadas.
2. Añadir contrato/caso de uso con validación, adapter y tests URLProtocol (payload textual, límites/errores/privacidad); registrar fuentes.
3. Integrar estado/token/operación pendiente en VM; conectar ambas confirmaciones y edición/cancelación/invalidation; tests con respuestas suspendidas.
4. Componer dependencias/fixture opt-in y aviso v4; tests de migración/config snapshot, cero HTTP antes de consentimiento.
5. Sustituir resumen por review/espera/error; adaptar E2E de confirmación/manual y añadir escenarios cuidados, revisar aspecto normal.
6. Verificar por impacto, documentar evidencia/límites, entregar al validator independiente solo cuando autorizado.

- [ ] Domain y tests: identidad/foto, límites de entrada y seis campos completos.
- [ ] Data y tests: contrato real Chat Completions textual, errores/cancelación/timeout/redirects.
- [ ] VM y tests: dos vías, una llamada, autorización correcta, stale/closed, edición no destructiva.
- [ ] Composición/aviso v4 y migración; sin secretos nuevos ni fallback ficticio.
- [ ] UI/fixture/E2E: transición directa sin resumen, revisión íntegra, fallos/cancelación/aislamiento.
- [ ] Documentación y evidencia focalizada; ningún alta/esquema adelantado.

## Verification Plan

**Solo plan; ninguno de estos comandos ejecutado por planner.** Coordinar simulator/sesión activa antes de pruebas; no ejecutar sobre config privada ni copiarla. Si se necesita build, usar sandbox de fuentes públicas bajo este worktree con plantilla vacía y plist puente público, por sesión autorizada; jamás sobreescribir config existente.

### Implementer — impacto seleccionado

- Domain/Data nuevos → campos incompletos, prompt injection, payload excesivo/privacidad → `GenerateCareSheetTests`, `OpenAICompatibleCareSheetGenerationRepositoryTests`: seis faltantes/blancos/tipos/longitud, refusal/truncamiento/unavailable, nombre largo/instrucciones, ausencia JPEG/otras plantas, endpoint/model/key optional, 401/429/timeout/redirect/cancel y un request.
- VM/confirmación → duplicados, operación equivocada, identidad vieja → `GenerateCareSheetViewModelTests`, `ConfirmSpeciesViewModelTests`, `ManualSpeciesViewModelTests`, `IdentificationPhotoViewModelTests`, `IdentificationConsentViewModelTests`: ambas vías, no llamada al seleccionar, precondiciones/cancelación, nueva revisión mismos nombres, cerrar/respuesta tardía, config cambiada y edición cancelada.
- Aviso/config compartidos → autorización antigua/fallback idioma/regresión identificación → `ExternalAIConsentTests`, `OpenAICompatibleSpeciesIdentificationRepositoryTests` y E2E consentimiento/renovación. Ampliación justificada por composición y scope compartidos, no persistencia nueva.
- Comando unit focalizado (en raíz pública preparada; elegir un único UDID estándar disponible):
  `caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath DerivedData -resultBundlePath DerivedData/care-unit.xcresult -parallel-testing-enabled NO -only-testing:PlantCareAITests/GenerateCareSheetTests -only-testing:PlantCareAITests/GenerateCareSheetViewModelTests -only-testing:PlantCareAITests/OpenAICompatibleCareSheetGenerationRepositoryTests test`.
  Ejecutar regresiones impactadas con la misma forma y sus `-only-testing:PlantCareAITests/<clase>`; registrar selección concreta tras diff, sin duplicar tests de otras selecciones.
- E2E obligatorio vía XCUITest existente: añadir `testCareSheetDirectAlternativeAndManualReview`, `testCareSheetFailureIncompleteRetryAndConsentCancellation`, `testCareSheetCancellationLateResponseAndStorageIsolation`, `testCareSheetLongTextAndIdentityInvalidation`. Usar `-only-testing:PlantCareAIUITests/PlantCareAIUITests/<método>` en comando anterior con bundle UI distinto. Adaptar y seleccionar regresiones confirmación/manual/max-alternativas y aviso renovado; no retirar aislamiento/modelos/JPEG/assertions por desaparición del resumen.
- Inspección visual básica de espera, error, manual/alternativa y seis campos largos/Abonado alcanzable en un iPhone estándar, texto normal/una apariencia; verificar ausencia del resumen temporal y controles reales. SE/Dynamic Type aumentado/VoiceOver/matrices: fuera de verificación habitual, no ejecutadas salvo solicitud expresa.
- Estáticos sobre diff: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, `python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null`, `git diff --check`; comprobar targets/fallback español/boundaries y exclusión de seams/config Release por revisión focalizada.
- Base: aceptación previa 128/128 solo evidencia histórica de fuentes base, no pruebas de nueva feature; reutilizar únicamente estado relevante contrastado. Sin gate automático inicial/final del implementer; si falta evidencia diagnosticar con build/focalizadas. Fallos preservados y reparación primero escenario fallido/callers afectados; no retries para verde.

### Validator — gate final

- Una ejecución final `caffeinate -dius ./init.sh` en entorno público seguro autorizado, o corroborar gate válido de idénticas fuentes/config/destino. Script intacto ejecuta build+unit+UI, siembra fotos sintéticas y termina, no servidor; imprime guía visual, no hace inspección visual por sí solo.
- No repetir focalizadas cubiertas por gate sin laguna/diagnóstico; cambios ejecutables posteriores invalidan evidencia y justifican nuevo gate tras reparación focalizada. Este plan documental solo requiere revisión de coherencia, no tests iOS.
- Prueba real de cuidados por **usuario** con su configuración local y nombre IA/manual autorizados: seis campos completos, fallo/reintento y ausencia de alta. Agentes no leen/copían clave ni envían por iniciativa propia; pruebas sintéticas no acreditan proveedor real. Si falta permiso/evidencia, registrar bloqueo de aceptación real, no fingir éxito ni acceso. No compartir builds/logs Debug con credencial.

## Evidence To Capture / Risks And Questions

- Comandos/selección/motivo, fuentes/hash y entorno/destino, resultados nuevos/reutilizados, bundles sanitizados y capturas de estados/scroll; fallos preservados, gate pendiente del validator y prueba real atribuida al usuario.
- Contadores separados identificación/cuidados; cero antes de aviso y tras seleccionar/cancelar, uno por intención; metadata/JPEG de dos ejemplares intactos tras relaunch sin reseed. Evidencia de ausencia del resumen en ambas vías.
- Riesgos principales: confirmación antes pura ahora inicia intención externa; aviso v4 afecta identificación; VM existente puede mezclar callbacks/errores; fichas atrasadas de identidad igual; nombre manual no certificado o malicioso; servicio puede rechazar JSON/token budget y no se sustituye por mock.
- Sin duda esencial bloqueante para redactar. **Decisiones propuestas pendientes de aprobación**: cuidados solo textuales/sin reenviar foto, aviso combinado v4, seis campos sin extras y límite defensivo de nombre 2000 sin truncado. No son implementación ni permiso para consulta real. Revisar usuario antes de otro rol.

## Validator Checklist

- [ ] Ambas vías confirman y generan directamente; resumen temporal ausente, seleccionar no envía.
- [ ] Manual conserva disponibilidad/toggle/precarga/cancelación vigentes; no alta ni IO local nuevo.
- [ ] Seis campos completos, errores/rechazos/cancelación/stale y reintento explícito correctos.
- [ ] Aviso v4/snapshot/boundary, cero HTTP antes de aceptación; payload mínimo y sin logs/secretos.
- [ ] Arquitectura/targets/composición y UI DESIGN/fallback/scroll comprobados, E2E adaptadas sin debilitarlas.
- [ ] Evidencia focalizada y gate final válidos, reales diferenciados de dobles; aislamiento preservado.
- [ ] Docs/estado actualizados con evidencia, specs/evidencias históricas intactas y sin trabajo de `save-plant`.

## Stop / Handoff

Feature bien dimensionada: un flujo con dos entradas existentes y reutilización de `CareSheet`, sin modelo persistente nuevo. **UN SOLO PASO: detener aquí para revisión del usuario; no iniciar implementer/validator ni cambiar passing/accepted.**
