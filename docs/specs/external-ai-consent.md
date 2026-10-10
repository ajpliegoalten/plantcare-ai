# Feature Implementation Spec: Avisar antes del primer envío a IA

## Source Feature

- `id`: `external-ai-consent`; `area`: `privacidad-ia`; fuente: `feature_list.json`.
- Título: «Avisar antes del primer envío a IA»; estado al planificar: `not_started`.
- `depends_on`: `[choose-identification-photo]`; `accepted` comprobado en feature_list y PROGRESS.
- Comportamiento: antes del primer envío de foto o contexto a un proveedor externo, solicitar confirmación informada; cancelar evita el envío.
- Verificación de origen: cliente IA instrumentado, rechazo con cero solicitudes, aceptación sin repetir indebidamente el aviso y gate estándar.
- Planificación: 2026-10-10; único directorio autorizado `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/external-ai-consent`.
- Rama/base comunicadas por orquestador: `feature/external-ai-consent`, `a68a09f6899c407362dfa5413dec51f34570e7d3`; no verificadas mediante Git/pwd por este rol (herramientas disponibles de lectura/edición, sin shell).
- **Propuesta para revisión humana, no aprobada.** Solo se crea esta spec; no implementación, validación de código, builds/tests/init.sh ni operaciones Git/GitHub. No cambia estados.

## Goal

Establecer una barrera reutilizable de consentimiento previo para cualquier operación externa de IA. El usuario conoce qué puede salir del dispositivo, decide expresamente y su aceptación se recuerda localmente entre aperturas y relanzamientos, sin estar vinculada a un ejemplar concreto.

Integrar el primer punto de entrada en el borrador fotográfico existente: con foto preparada, «Identificar» permite revisar el aviso. Esta entrega **no identifica ni envía a un proveedor real**: tras autorizar, comunica honestamente que la identificación todavía no está disponible. El cliente instrumentado es un doble de pruebas, nunca una simulación de éxito en producción. `identify-candidates` conectará la petición real a la misma barrera.

## Non-Goals

- Sin URLSession/SDK IA, endpoint, modelo, clave, mecanismo de credenciales, costes ni respuesta botánica; pertenecen a `identify-candidates` y siguientes.
- Sin confirmar especie, generar cuidados, alta, análisis, chat, historial ni guardar el JPEG del borrador.
- Sin permisos nuevos de cámara/Fotos; elegir una foto o añadirla localmente no implica consentimiento externo.
- Sin ajustes generales, pantalla de revocación, cuentas, sincronización o garantías legales sobre el proveedor.
- Sin persistencia de rechazos, payloads, imágenes, contexto, preguntas o claves; sin migración de PlantStore.
- Sin trabajo en main/otros worktrees, modificación de specs aceptadas ni matrices ampliadas de verificación.

## Job Story / Users And Permissions

Cuando pido una función de IA por primera vez, quiero saber qué datos pueden salir de mi iPhone y poder cancelar, para decidir antes de cualquier envío sin perder mis plantas ni mi foto seleccionada.

- Único usuario local; la aceptación es una preferencia de esta instalación, no un dato por planta ni un permiso iOS.
- Consentir habilita futuras solicitudes explícitas; no inicia envíos en segundo plano, al abrir una pantalla ni al consultar datos locales.
- Alcance propuesto: fotos seleccionadas para IA y texto pertinente de la planta para identificación, cuidados, análisis y pregunta puntual. No autoriza exportar toda la colección ni fotos antiguas en análisis.

## Acceptance Scenarios (Given / When / Then)

### 1. Solo por intención explícita
Given instalación sin aceptación, When abro Mis plantas, Añadir, galería o cámara y preparo una foto, Then no aparece aviso externo ni hay solicitudes IA. Identificar está deshabilitado sin foto y mientras se prepara/comprueba cámara; con foto lista queda habilitado para revisar el aviso.

### 2. Primer aviso informado
Given foto A lista y ninguna aceptación vigente, When pulso Identificar, Then aparece el aviso con alcance, carácter externo y acciones «Cancelar» y «Aceptar y continuar». A sigue visible al volver y el cliente instrumentado mantiene contador cero mientras el aviso está abierto.

### 3. Cancelar, gesto y abandono
Given aviso abierto, When cancelo o cierro el aviso por gesto, Then no se guarda aceptación ni se ejecuta la operación; vuelvo al borrador con A intacta. Reintentar muestra el aviso otra vez. Cerrar el borrador o terminar la app mientras espera confirmación tampoco autoriza ni envía; una respuesta tardía no reabre el flujo.

### 4. Aceptar una vez
Given aviso abierto, When acepto explícitamente, Then se registra el alcance/versión vigente y se continúa exactamente una vez. El doble instrumentado recibe una invocación, nunca antes de registrar aceptación; el camino de producción muestra «La identificación todavía no está disponible. No se ha enviado ninguna foto.» sin candidatas ni éxito ficticio.

### 5. Recordar sin enviar automáticamente
Given aceptación vigente, When cierro/reabro el borrador o relanzo y preparo otra foto, Then no hay operación automática. When pulso Identificar, Then se continúa una vez sin repetir el aviso. El doble comprueba una nueva invocación por intención; producción sigue sin red y explica indisponibilidad.

### 6. Alcance inválido y fallo de lectura/registro
Given registro ausente, malformado o de otra versión/destinatario, When solicito IA, Then no sirve como autorización y aparece el aviso vigente. Given un repositorio doble que falla al leer o registrar, When intento continuar, Then aparece error recuperable, no se invoca el cliente y se conserva A. No asumir aceptación en memoria tras un fallo.

### 7. Cancelación y duplicados
Given confirmación/continuación en curso, When hago doble toque o cierro el flujo antes de invocar la operación, Then no se duplican invocaciones ni se envía después del cierre. Una aceptación ya registrada por acción explícita puede permanecer aunque se cancele después; cancelar no deshace un consentimiento anterior ni puede retirar bytes ya enviados en futuras features.

### 8. Barrera común y aislamiento local
Given operaciones instrumentadas de foto y de contexto textual sin foto, When piden continuar sin consentimiento, Then ambas quedan bloqueadas hasta confirmar. En ambas rutas, rechazar produce cero invocaciones. Given dos plantas persistidas, When cancelo/acepto y relanzo sin reseed/desinstalar, Then modelos y JPEG de ambas permanecen íntegros, sin planta ni archivo de borrador nuevos.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md` (estado y registro reciente), `feature_list.json`, `ARCHITECTURE.md`, `CONSTRAINTS.md`: dependencia, separación de capas, política y secretos.
- `.agents/skills/feature-spec/{SKILL.md,references/spec-template.md}` y `.agents/skills/ios-clean-mvvm/SKILL.md`: skills aplicadas en planificación.
- `CONTEXT.md`, `docs/{build-brief,domain-model,risks-and-open-questions}.md`, `DESIGN.md`, `docs/adr/002-local-plant-editing.md`, `docs/specs/choose-identification-photo.md`: vocabulario, privacidad, diseño y punto de continuación previo.
- `PlantCareAI/PlantCareAIApp.swift`, `Features/PlantList/Presentation/PlantListView.swift`: fábrica inyectada, VM por apertura y binding de sheet que llama close al descartar.
- `Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift`: Identificar actualmente vacío/deshabilitado, tareas/generaciones, JPEG efímero y conservación de A.
- `PlantCareAITests/IdentificationPhotoViewModelTests.swift`: dobles controlados y respuestas tardías; `PlantCareAIUITests/PlantCareAIUITests.swift` (320–504): seam de foto, picker real, descarte por gesto y verificación de dos plantas.
- `PlantCareAI.xcodeproj/project.pbxproj` y `PlantCareAI/Localizable.xcstrings` (búsquedas focalizadas): registro explícito, Swift 5/iOS 17, textos de Identificar y fallback español.
- `init.sh` completo; inventarios `docs/`, `docs/specs/`, `docs/adr/` y fuentes Swift. No existía esta spec ni docs product-brief/user-and-access-model/technical-discovery/mvp-scope; build-brief cubre producto.

### Existing Patterns / Gaps

- Clean Architecture + MVVM: View → VM → Domain ← Data, composición exclusivamente desde App; ninguna feature IA real todavía.
- El borrador se libera al cerrar y no escribe PlantStore. Reutilizar su protección de cierre/generación, no singleton de foto.
- XCUITest es el E2E persistente. `./init.sh` hace build, siembra fotos sintéticas locales y ejecuta todas las unitarias/UI serializadas; termina sin servicios largos.
- No hay almacén de consentimiento ni cliente IA. El proveedor exacto sigue abierto; no inventar OpenAI como destinatario por usar una API compatible.
- La spec previa reservaba Identificar hasta las features de consentimiento/identificación. Se propone habilitar aquí **solo el acceso al aviso**, con indisponibilidad explícita; no reescribir el contrato histórico aceptado.

## Technical Approach

### Domain: barrera reusable, no cliente ficticio

- Crear `Features/ExternalAIConsent/Domain/ExternalAIConsent.swift`: valor mínimo de alcance con identificador lógico de destinatario y versión de aviso; sin payload, UUID de planta, framework UI o API.
- `ExternalAIConsentRepository` expone lectura y registro async/throws de aceptación. Ausente/malformado/no coincidente significa no aceptado; fallo operativo significa error, nunca autorización.
- `AuthorizeExternalAIOperation` es el caso de uso inyectado: lee aceptación vigente; sin ella devuelve `requiresConfirmation` **sin ejecutar** la continuación. Tras confirmación explícita registra la aceptación antes de ejecutar. Con aceptación vigente ejecuta directamente, siempre con cancelación comprobada antes/entre lectura, registro e invocación.
- Continuación async/throws inyectada por operación (no protocolo de cliente IA vacío): devolver resultado o propagar error; tests pasan spy/contador sin HTTP. No exponer una mera bandera UI como único control de envío.
- El caso de uso no guarda continuaciones/payloads para ejecutarlos posteriormente, no lanza tareas desestructuradas y no reintenta automáticamente. El VM conserva la intención pendiente mientras el aviso está vivo y la invalida al cancelar/cerrar.
- Este boundary lo reutilizarán `identify-candidates`, `generate-care-sheet`, `analyze-current-photo` y `one-turn-question`, incluso si el primer uso futuro es textual desde especie manual. Sus adaptadores de red solo se invocarán dentro de esta continuación autorizada.

### Data y composición

- `UserDefaultsExternalAIConsentRepository`: preferencia local mínima en clave propia `externalAIConsent.acceptance`, con destinatario lógico y versión; sin SwiftData, JPEG, fecha obligatoria ni metadata de planta.
- Leer/escribir mediante instancia inyectada; aislar ejecución (actor) y validar estructura estrictamente. UserDefaults es persistencia real de preferencia, **no una transacción de disco ni prueba de durabilidad ante apagado brusco**; no usar synchronize como garantía.
- Producción usa UserDefaults estándar. Tests usan suite UUID propia, conservada en relanzamientos del mismo test y limpiada al terminar; jamás borrar el dominio estándar para sembrar pruebas.
- App crea un repositorio/caso de uso compartidos por instalación e inyecta la misma barrera a cada nuevo VM de foto. El VM no instancia UserDefaults ni Data.
- Alcance provisional propuesto: destinatario lógico `prototype-external-ai`, aviso versión `1`; no representa una empresa concreta. Antes de conectar red, `identify-candidates` debe fijar identidad real del destinatario, actualizar el texto y cambiar el alcance para renovar confirmación si cambia destinatario o datos/finalidades materiales. No hace falta configurar una clave para probar esta entrega.

### Presentation y operación actual

- El VM de foto recibe la barrera y una continuación de identificación. Producción inyecta un resultado explícito `unavailable`, sin red ni candidatas; la composición lo documenta como límite temporal reemplazado por `identify-candidates`.
- Estados explícitos: idle, checkingAuthorization, awaitingConfirmation, continuing, failed/unavailable; mantenerlos separados de error de preparación y permiso de cámara.
- Al pulsar Identificar capturar identidad de selección/foto vigente. Mientras autoriza/avisa/continúa bloquear sustitución/cámara y doble toque; Cancelar/cerrar sigue disponible. Al confirmar, verificar flujo vivo y misma selección antes de continuar. Limpiar intención/tarea al cancelar y comprobar generación antes de publicar resultados.
- Vista de aviso propia `ExternalAIConsentView` presentada como sheet nativa desde el modal de foto; binding de dismiss/gesto cancela la intención, no equivale a aceptar. La vista solo comunica aceptar/cancelar al VM existente; no requiere un segundo ViewModel artificial.
- Una aceptación confirmada no se borra al cerrar la foto. Rechazar un aviso posterior no revoca una aceptación previa de otro alcance.
- Debug Simulator opt-in puede inyectar un spy sin red y exponer **solo contadores/estado técnico** para E2E; no fotos/contexto/secretos. Nunca ofrecer candidatas simuladas ni atribuir solicitudes reales al spy; excluirlo de Release.

## Expected File Changes (futuros, no realizados por planner)

- Crear `PlantCareAI/Features/ExternalAIConsent/Domain/{ExternalAIConsent,ExternalAIConsentRepository,AuthorizeExternalAIOperationUseCase}.swift`.
- Crear `.../Data/UserDefaultsExternalAIConsentRepository.swift` y `.../Presentation/ExternalAIConsentView.swift`.
- Modificar `PlantCareAI/Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift`: intención, estados, aviso, continuación veraz y cancelación.
- Modificar `PlantCareAI/PlantCareAIApp.swift`: composición de consentimiento/continuación y aislamiento Debug opt-in. PlantList/ContentView no necesitan pantallas ni lógica nueva.
- Modificar `PlantCareAI/Localizable.xcstrings` y `PlantCareAI.xcodeproj/project.pbxproj`: claves usadas y registro explícito de todos los Swift/tests; sin permisos/configuración sensibles.
- Crear `PlantCareAITests/{ExternalAIConsentTests,UserDefaultsExternalAIConsentRepositoryTests}.swift`; extender `IdentificationPhotoViewModelTests.swift` y `PlantCareAIUITests/PlantCareAIUITests.swift`.
- Opcional si E2E lo requiere: `.../ExternalAIConsent/Data/ExternalAIConsentTestFixture.swift`, compilado solo Debug Simulator, activado por composición, sin cliente real ni datos sensibles.
- Crear `docs/testing-external-ai-consent.md` y ADR propuesto abajo; actualizar docs duraderas/evidencias durante implementación. No cambiar init.sh por defecto.

## Visual Design Impact

- UI: sí; `DESIGN.md`, tokens y barras nativas existentes. Usuario no necesita diseño adicional; no se solicita ni se crea artefacto gráfico.
- Sheet desplazable con título «Antes de usar IA externa», cuerpo legible, dos acciones inequívocas ≥44 pt; fondo crema, texto semántico, primario verde con contraste, SF Symbols solo si aportan significado.
- Texto propuesto: «Para identificar plantas y ofrecer orientación, las funciones de IA enviarán al proveedor externo configurado para esta demo la foto que elijas para IA o el texto necesario de tu planta (especie, cuidados, historial pertinente y tu pregunta, según la función). No se envía toda tu colección ni fotos antiguas para analizar una foto actual. Puedes cancelar antes de continuar. Recordaremos tu aceptación en este dispositivo para futuras solicitudes de IA que tú inicies.»
- En esta entrega añadir «La identificación todavía no está disponible; aceptar este aviso no enviará tu foto ahora.»; retirar esta aclaración cuando exista petición real, sin ocultar el alcance externo.
- Acciones «Cancelar» y «Aceptar y continuar», sin toggle preseleccionado, aceptación implícita ni promesas de retención/no entrenamiento del proveedor desconocido.
- Mantener foto/preview y galería existentes; cambiar explicación de Identificar para distinguir aviso disponible de identificación pendiente. Etiquetas/identificadores estables, texto adaptable y soporte accesible conservado.

## Durable Documentation Impact

- Ahora: solo esta spec. `PROGRESS.md`/`feature_list.json` no cambian por planificación ni se declara passing/accepted.
- `ARCHITECTURE.md`: actualizar al implementar con nueva feature, preferencia global, barrera común, dependencia concreta y continuación indisponible; ajustar afirmación sobre Identificar deshabilitado.
- `CONSTRAINTS.md`: actualizar con regla de pasar toda operación externa por la barrera y renovar consentimiento si cambia destinatario/alcance; mantener reglas de secretos.
- `AGENTS.md`, `DESIGN.md`, `CONTEXT.md`, `docs/build-brief.md`: no necesario; no cambia flujo operativo, dirección visual ni producto aprobado.
- `docs/domain-model.md`: precisar alcance por instalación, aceptación explícita y cancelación sin envío; no añadir entidad de consentimiento por planta.
- `docs/risks-and-open-questions.md`: registrar proveedor pendiente, UserDefaults sin garantía de apagado brusco y validación instrumentada sin API real.
- Proponer `docs/adr/003-external-ai-consent.md` tras revisión: preferencia versionada global y barrera compartida con futuros callers; sin migración SwiftData ni dependencias externas. No registrar decisión aprobada antes de aprobación.
- `docs/testing-external-ai-consent.md`: pasos, suite aislada, spy, limpieza y límites. Roles posteriores registran únicamente evidencia ejecutada en PROGRESS/feature_list.

## Implementation Plan / Tasks

1. Tras revisión humana, comprobar rama/estado del worktree y coordinar baseline con sesión activa; preservar trabajo ajeno y spec revisada.
2. Implementar modelo, repositorio y caso de uso con pruebas de bloqueo/invocación/errores/cancelación antes de integrar UI.
3. Implementar preferencia real aislable y composición; inyectar continuación indisponible, nunca cliente que aparente éxito.
4. Integrar aviso/estados/descartes en foto, localización y registro Xcode; añadir E2E instrumentado sin red.
5. Documentar límite/proveedor futuro, verificar en secuencia y entregar a validator independiente sin iniciar otra feature.

- [ ] Confirmar propuesta de alcance/versionado y habilitación limitada de Identificar en revisión.
- [ ] Barrera Foundation-only y repositorio Data con tests aislados y errores fail-closed.
- [ ] Cero invocaciones antes de aceptar; exactamente una por intención, con cancelación y duplicados cubiertos.
- [ ] Aviso/cancelar/gesto/relanzamiento y preservación de A; continuación indisponible honesta.
- [ ] Xcode/catalogo/tests registrados, seam Debug excluido de Release, documentación actualizada.
- [ ] Gate, visual básica, evidencias y límites reales para validación independiente.

## Verification Plan (futuro; nada ejecutado por planner)

- Un único iPhone Simulator estándar, texto normal, una apariencia; coordinar con sesión activa, sin tests simultáneos. Reutilizar baseline válida cuando corresponda; tapa abierta y no editar arnés durante ejecución.
- `caffeinate -dius ./init.sh`: build y todas las unitarias/UI funcionales. Mantener propagación de errores/escenarios; script termina, no inicia servicios ni exige red/credencial para esta feature.
- Focalizadas seriales: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID_ESTANDAR>' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO -only-testing:PlantCareAITests/ExternalAIConsentTests -only-testing:PlantCareAITests/UserDefaultsExternalAIConsentRepositoryTests -only-testing:PlantCareAITests/IdentificationPhotoViewModelTests -only-testing:PlantCareAIUITests/PlantCareAIUITests test`.
- Domain con spy: operaciones de foto y texto; requerir confirmación/cancelar = 0 invocaciones, aceptar = 1 después del registro, aceptación vigente sin aviso, registro no coincidente/malformado, fallo de lectura/escritura, cancelación entre etapas y doble toque. No inferir cero solicitudes solo de ausencia de UI.
- Data: suite UUID propia, lectura desde nueva instancia y relanzamiento UI, ausencia/registro inválido/versionado; sin tocar dominio estándar ni PlantStore. Tests que fallen no se silencian con try? o fallback autorizado.
- XCUITest E2E persistente: aviso por intención, cancelar y gesto con A conservada/contador 0; reintento; aceptar/contador 1; nueva intención sin aviso/contador 2; relanzar misma suite sin reset y comprobar aceptación sin envío automático; nueva suite vuelve a avisar. Producción sin seam: aceptar muestra indisponibilidad, sin candidatas.
- Extender, no eliminar, regresiones de foto/picker/gesto vacío y con A, fallback español, almacenamiento/detalle/edición. Ajustar solo expectativas de Identificar justificadas por comportamiento nuevo; vacío continúa deshabilitado y picker real sigue probado.
- Verificar dos plantas/modelos/JPEG completos antes/después mediante fixture existente, relanzando sin reseed/desinstalar; consentimiento no toca PlantStore.
- Inspección visual básica de aviso, texto completo mediante scroll, acciones, error y estado indisponible en el mismo simulador; etiquetas españolas sin claves crudas y controles alcanzables con texto normal.
- Comprobaciones posteriores: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON catálogo/feature_list y `git diff --check`; build Release genérico y auditoría del binario si se añaden seams para comprobar su exclusión. No sustituyen pruebas funcionales.
- Sin API real en este alcance: spy prueba bloqueo del boundary, no conexión/retención externa. `identify-candidates` deberá instrumentar además transporte real, configurar proveedor/credencial fuera del repo y verificar que no lo elude.
- SE/pantallas pequeñas, texto aumentado/máximo, VoiceOver/Accessibility Inspector y matrices: fuera de verificación habitual; no ejecutadas salvo solicitud expresa, no bloqueos automáticos.

## Evidence To Capture / Risks And Unknowns

- Logs/xcresult, resultado completo, fecha/destino, capturas realmente inspeccionadas y conteos 0/1/2 con orden registro→invocación; aceptación tras relanzamiento sin reset y conservación de plantas.
- Separar pruebas con spy de camino indisponible de producción; nunca afirmar envío/IA real ni cumplimiento legal por esos tests. No registrar payloads, imágenes, contexto, claves ni endpoint sensible.
- Propuestas no bloqueantes para revisión: aceptación por instalación y alcance versionado, UserDefaults, sheet y activación limitada de Identificar. No constan aprobadas por el usuario.
- Proveedor/nombre/condiciones siguen sin determinar: no bloquea spec ni pruebas instrumentadas; sí obliga a revisar destinatario/texto/alcance antes de habilitar cualquier envío real. Nunca reutilizar silenciosamente el identificador provisional para un destinatario distinto.
- UserDefaults no demuestra durabilidad ante apagado abrupto; si el registro se pierde, volver a pedir aviso (fallo seguro). No prometer eliminación del registro tras desinstalación/restauración sin comprobar ese entorno.
- Riesgo futuro: bypass del boundary por un adaptador IA nuevo; ADR/regla duradera y tests de transporte deberán comprobarlo en cada feature de red. Esta entrega no puede demostrar un cliente inexistente.
- Sin bloqueos de dependencia/tamaño identificados; una preferencia mínima y un flujo de confirmación reutilizable, no varios flujos IA.

## Validator Checklist

- [ ] Alcance limitado: consentimiento real local, sin proveedor/red/candidatas/alta ficticios ni nuevas credenciales.
- [ ] Capas y composición correctas; future callers documentados y operación solo dentro del boundary autorizado.
- [ ] Rechazo/gesto/abandono = cero invocaciones y ningún registro; aceptación = una y persistencia real entre relanzamientos.
- [ ] Versión/destinatario inválidos y errores no autorizan; cierre/cancelación/duplicados no envían tardíamente.
- [ ] Identificar disponible solo con foto lista; aviso claro, indisponibilidad de producción explícita y A intacta.
- [ ] E2E/gate/regresiones conservados; modelos/JPEG de dos plantas intactos y visual básica inspeccionada.
- [ ] Seams aislados y ausentes en Release; no pruebas/secretos sensibles en logs ni escrituras al almacenamiento real por fixtures.
- [ ] Docs/evidencias reflejan solo comprobaciones ejecutadas y límites; passing no equivale a aceptación independiente.

**Siguiente acción: revisión del usuario. Detenerse tras planner; no iniciar implementer ni validator.**
