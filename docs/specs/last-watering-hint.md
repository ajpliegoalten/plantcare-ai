# Feature Implementation Spec: último riego sin alarmas

## Source Feature

- `id`: `last-watering-hint`; `area`: `detalle`; título: Mostrar último riego sin alarmas.
- Fuente: `feature_list.json`; estado de planificación: **not_started**, evidencia vacía; esta spec no autoriza implementación.
- Comportamiento fuente: «El detalle muestra la fecha del último riego y, si procede, sugiere comprobar humedad sin ordenar regar hoy».
- `depends_on`: `[quick-watering]`, accepted con `validator_evidence` independiente explícita. `other-care-events` también accepted e integrado: el código vigente es CareEvents, no QuickWatering.
- Verificación fuente: comparar plantas con/sin riego, fecha correcta, ausencia de fecha/urgencia inventada y gate estándar.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/last-watering-hint`; rama/base comunicadas por orquestador: `feature/last-watering-hint`, main/origin main `dd87eaac018981d34725ccdbcca69a8d86630050` limpia. No se corroboraron mediante comandos Git en este planner.

## Goal y decisión de alcance para revisión humana

Mostrar un resumen local y veraz del último **riego registrado por el usuario**, tanto en detalle como bajo identidad de cada tarjeta de Mis plantas, usando los eventos existentes por UUID y solo tras lectura correcta. Mantener Registrar cuidado real y el consejo estático prudente SOLO en detalle, sin interpretar el tiempo transcurrido como necesidad de regar.

**Decisiones humanas puntuales confirmadas:** incluir Mis plantas + detalle en esta misma feature y conservar los formatos de fecha propuestos (hoy/anterior). Son dos representaciones de una sola consulta/regla, sin modelo persistente ni flujo humano nuevos; `feature_list.json` todavía solo nombra detalle. Además, idle/loading/failed ocultan completamente el resumen, y el consejo pertenece exclusivamente al detalle. Estas confirmaciones NO constituyen aprobación integral de la spec ni autorización de implementar.

Delta mínimo propuesto para el harness tras aprobación integral: `user_visible_behavior` = «Tras lectura correcta, Mis plantas y el detalle muestran el último riego registrado de cada ejemplar, o su ausencia; sin resultado el resumen se oculta, y solo el detalle recuerda comprobar la humedad sin ordenar regar hoy»; ampliar `verification` a refresh listado/detalle, persistencia, ocultación en idle/loading/failed, recuperación por lifecycle y otros tipos excluidos. Mantener id/area/dependencia/status/evidencia; no añadir dependencia artificial: la composición actual ya usa CareEvents. Este planner **no modifica** el harness.

## Non-Goals

- Historial visible, eliminación/edición de eventos, nuevos tipos, nuevas fotos, cuenta, backend, sincronización, alarmas o notificaciones al usuario.
- Frecuencia, contador de días, «regar hoy», urgencia, estado de salud/humedad observada, calendario/anillos o recomendaciones IA nuevas.
- Registrar al pulsar Registrar cuidado, preseleccionar Riego, cambiar CTA a «Registrado ahora», simular toast/fecha o copiar scripts HTML.
- Rediseñar foto/identidad/editor/seis cuidados IA, navegación, tabs/perfil/header; acción rápida adicional desde tarjeta.
- Cambiar Plant/PersistedPlant/PersistedCareEvent, siete campos, schema V2, store/rutas/JPEG, migración/backfill o persistir último riego duplicado.
- Mostrar loading/error/placeholder/spinner/espacio reservado o retry manual para este resumen; loops automáticos de recuperación; consejo de sustrato en tarjetas/Mis plantas. No se alteran retries existentes de foto, metadata o guardado CareEvents.

## Job Story / Users And Permissions

Cuando consulto mis plantas, quiero saber qué último riego registré para ese ejemplar, para recordar su cuidado sin confundir una fecha con una obligación de regar. Único usuario local; consulta sin permisos nuevos, red, IA ni consentimiento adicional. Leer no escribe eventos.

## Acceptance Scenarios (Given / When / Then)

1. **Ausencia real.** Dada una planta sin eventos o solo con abonado/poda/trasplante/otro, al terminar lectura correcta en loaded(nil), tarjeta muestra «Sin riegos registrados» y detalle «Último riego» / «Sin riegos registrados», sin fecha. CTA y frase prudente permanecen SOLO en detalle; tarjetas no muestran consejo.
2. **Hoy.** Dado un watering cuyo occurredAt cae en el día actual en zona actual, al consultar, tarjeta muestra «Último riego: hoy»; detalle etiqueta «Último riego» y valor «Hoy, 12 oct 2026» si hoy real es 12/10/2026. Las fechas de ejemplo no son constantes del producto.
3. **Anterior/orden.** Dados varios watering insertados fuera de orden, un cuidado no watering más reciente y un riego antiguo registrado después, al consultar se muestra el máximo occurredAt de watering del UUID propio, no createdAt, primer elemento ni último insertado. Ejemplo: tarjeta «Último riego: 8 oct 2026»; detalle valor «8 oct 2026».
4. **Commit y refresh.** Dada ausencia/fecha previa, al abrir sheet no cambia el resumen; cancelar/fallar/busy tampoco cambian la fecha. Solo después del commit watering exitoso se invalida y relee el resumen del detalle y de su tarjeta retenida; durante lectura se oculta y solo reaparece con loaded(Date?). Al volver al listado y completar lectura está actualizado sin recrear imágenes/metadata; un riego retroactivo no desplaza uno más reciente. Otros tipos confirman «Cuidado registrado» pero no cambian ni invalidan último riego. Un fallo de relectura deja el resumen oculto sin deshacer la confirmación real.
5. **Aislamiento/persistencia.** Dadas dos plantas, incluso misma especie, al registrar en A y terminar/reabrir proceso sin reseed, A conserva su máximo y B su valor/ausencia. Plant completo, foto y ficha de ambos siguen exactos.
6. **Sin resultado / recuperación normal.** Dados idle/loading o un error de consulta con metadata de planta disponible, al renderizar no existe view de resumen: sin fila/icono/texto/spinner/placeholder/espacio reservado/error/Reintentar ni accesibilidad/IDs del resumen. El error permanece failed interno, no loaded(nil): nunca «Sin riegos registrados» ni fecha ficticia ni fallo de guardado para commit confirmado. Metadata/foto/ficha y, en detalle, box Cuidados/Registrar cuidado/consejo siguen disponibles. Al reaparecer/abrir, entrar en foreground o invalidar tras commit watering, se admite una nueva consulta normal; si tiene éxito reaparece fecha/ausencia real. Si falla otra vez queda oculto sin retry manual ni loop automático.
7. **Lecturas tardías.** Dada lectura suspendida anterior al commit o desaparición/reapertura, cuando termina tarde no sobrescribe el nuevo máximo ni un estado de error/lectura más reciente. Cambiar de UUID no mezcla datos; cancelación técnica no produce error visible ni pierde commit reconocido.
8. **Día/zona/reloj.** Dado un instante con origen IANA distinto, al convertir se usan calendario gregoriano y zona ACTUAL, no el día almacenado en origen. Viaje/medianoche/retorno a foreground actualizan fecha/«hoy» sin writes. Reloj retrocedido no elimina un evento válido: si ya no es hoy se muestra su fecha absoluta, sin urgencia aunque resulte posterior al reloj actual.
9. **Composición y accesibilidad.** Dados nombres/especies/ubicaciones largos en simulador estándar, al desplazarse se mantienen texto completo, cabecera fija, navegación UUID y CTA alcanzable. Solo loaded(Date?) añade etiqueta/valor accesibles del resumen, sin leer icono decorativo ni ocultarlo por la accessibilityLabel del NavigationLink; idle/loading/failed eliminan también su accessibilityValue, IDs y espacio/separaciones propios. Fallback inglés conserva español, sin claves crudas; consejo de sustrato nunca en Mis plantas.

## Repository Research

### Files Inspected

- `AGENTS.md`, `ARCHITECTURE.md`, `DESIGN.md`, `CONSTRAINTS.md`, `PROGRESS.md`, `feature_list.json`; skills feature-spec (incluido template) e ios-clean-mvvm leídas/activadas.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, ADR008/009: vocabulario, eventos locales y tiempo origen/actual.
- `PlantCareAI/Features/CareEvents/Domain/{CareEvent,CareEventRepository}.swift`: cinco kinds, siete campos, `loadCareEvents(for:) async throws -> [CareEvent]`.
- `PlantCareAI/Features/PlantList/Data/LocalPlantRepository.swift` (apertura, lecturas/eventos y escrituras, líneas 1–140): mismo actor/schema V2, validación antes de cleanup; lectura por UUID, plantNotFound/storage propagados; orden occurredAt desc, createdAt desc, UUID asc.
- `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel,PlantCardView,PlantCardViewModel}.swift`: tarjetas retenidas por UUID, .task de foto, metadatos y cache separados; actualmente ningún resumen de riego.
- `PlantCareAI/Features/PlantDetail/Presentation/{PlantDetailView,PlantDetailViewModel}.swift`: box careRegistration entre identidad y ficha, CTA52/frase ya existente; callback canónico por sesión solo publica banner, sin refresh de riego.
- `PlantCareAI/PlantCareAIApp.swift`: composición única tras overrides Debug. `PlantCareAI.xcodeproj/project.pbxproj` (registro localizado mediante búsqueda): fuentes explícitas, no autodiscovery.
- `PlantCareAI/Localizable.xcstrings` (búsqueda de texto/clave existente), `PlantCareAI/Features/CareEvents/Data/CareEventTestFixture.swift`: sidecar de expectativas no es fuente de producto.
- `PlantCareAITests/PlantListViewModelTests.swift`, `PlantDetailViewModelTests.swift` (1–180), `LocalCareEventRepositoryTests.swift` (1–150): seams asíncronas y pruebas reales Plant/JPEG/orden/error.
- `PlantCareAIUITests/PlantCareAIUITests.swift` (clases localizadas, detalle/rediseño y primeras pruebas CareEvents 1283–1452), `docs/testing-ui.md`, `init.sh`: XCUITest persistente, selección y gate de dos fases.

### Patterns / Gaps

- No caso de uso de último riego ni estado/formatter compartido; el callback ya recibe el CareEvent canónico correcto. Foto/metadata no deben recargarse para este resumen.
- No se asume que lista ordenada implique primer evento watering. Lectura falla ante planta ausente/store corrupto; no usar `try?` → nil.
- La .task actual del detalle espera la foto: la consulta nueva debe iniciar independientemente, no detrás de su IO/decode. Mis plantas debe mostrar metadata aunque el resumen tarde/falle.
- Referencia Stitch recibida como descripción explícita del padre: no se inspeccionó aquí HTML completo, captura ni recurso externo. Esta spec preserva solo el delta pertinente transmitido, no diferencias accidentales entre HTMLs.

## Technical Approach

### Domain / Data / composition

- Crear `Features/LastWateringHint/Domain/LoadLastWateringUseCase.swift`: protocolo `LoadLastWateringUseCase: Sendable` con `execute(for plantID: UUID) async throws -> Date?` y implementación `LoadLastWatering` sobre `any CareEventRepository`.
- Regla pura: filtrar plantID propio y kind == watering, devolver máximo occurredAt. nil solo tras lectura exitosa sin watering; no consultar CareSheet.watering ni createdAt ni validar contra reloj de hoy. Empate no cambia la fecha mostrada: no hace falta seleccionar evento/nota ni criterio arbitrario nuevo.
- **Data ahora:** reutilizar `LocalPlantRepository.loadCareEvents` sin adaptador/protocolo/schema nuevo. Coste actual fetch completo + filtro por planta, repetido por tarjetas visibles; aceptable para prototipo, documentar límite, no prometer batch/escala ni adelantar refactor transversal.
- **Composición:** `PlantCareAIApp` crea `LoadLastWatering(repository: repository)` con el mismo actor DESPUÉS de overrides Debug y lo inyecta al listado/fábrica de detalle y tarjetas. Nunca repositorio en vista, init de VM sin IO; ContentView intacto.
- Dependencia: vistas tarjeta/detalle → VM de resumen inyectado → LoadLastWatering → CareEventRepository ← LocalPlantRepository. Domain Foundation únicamente; SwiftUI/UIKit, notificaciones y formato son Presentation.

### Presentation / estados / actualización

- Crear `Features/LastWateringHint/Presentation/LastWateringHintViewModel.swift` reutilizable por UUID, con estado explícito idle/loading/loaded(Date?)/failed y generation/task independiente. Retener un VM por tarjeta y otro en cada destino; el subcomponente observa directamente ese VM para evitar pérdida de updates de ObservableObject anidado.
- Crear `LastWateringHintView.swift` con variantes compactCard/detailRow; renderiza exclusivamente loaded(Date?), sin controles de retry ni lógica de almacenamiento. En idle/loading/failed devuelve contenido vacío sin layout/espaciado/accesibilidad propios; el padre tampoco reserva fila/padding/separador para él. Asociar arranque/cancelación a lifecycle del contenedor estable (tarjeta/detalle), NO a la view condicional del resumen: su ocultación no debe impedir la consulta o crear ciclos de montaje/lectura. Cargas de foto y resumen independientes; solicitudes concurrentes/coincidentes se deduplican.
- Detalle crea VM/inicia lectura solo con metadata loaded; notFound/error global no muestran ausencia de riego. Error del resumen se conserva internamente y oculta solo el resumen, sin sustituir ficha ni box/CTA/consejo. Tarjeta tampoco depende de foto exitosa y nunca incluye consejo.
- Al callback confirmado existente, conservar guard sesión/plantID y banner genérico; si watering, invalidar generation, marcar lectura pendiente y solicitar máximo otra vez, no asignar occurredAt del nuevo evento como último directamente. Callback MainActor débil al listado invalida/refresca SOLO el VM retenido del UUID afectado. No insertar/cambiar Plant ni recrear cards ni JPEG para refresh. Tarjeta invisible queda invalidada y carga al reaparecer; tarjeta visible refresca sin esperar navegación.
- Lectura tras commit fallida es error de consulta independiente interno, no fallo de registro ni razón para repetir save. Confirmación permanece válida y resumen oculto. Otros kinds/cancel/error no disparan callback de cambio de último riego. No suponer lecturas infalibles por ser DB local, ni convertir throws en nil.
- Crear `LastWateringDateFormatter.swift` Presentation: entrada Date/now/timeZone inyectables para tests; es_ES + gregoriano/zona actual, formato breve día/mes abreviado/año **sin punto** («8 oct 2026»), hoy por `calendar.isDate(_:inSameDayAs:)`, no por 24h transcurridas. Card usa hoy minúscula; detalle Hoy + fecha. Sin ayer relativo, días transcurridos ni hora observada.
- Mantener Date canónica, no cachear string indefinidamente. VM actualiza contexto de presentación al aparecer/scene active, cambio de zona/tiempo significativo/día; mientras visible programar una única tarea cancelable al próximo inicio de día gregoriano actual, reprogramada ante cambio de contexto. Esa tarea solo reformatea un loaded, NO recupera failed/idle ni consulta store. Sin polling/timer por segundo/notificaciones al usuario/writes. Inyectar reloj/zona y scheduler/activación de frontera con seam mínimo testeable, sin dependencia externa.
- En invalidación no conservar fecha vieja como vigente: estado interno loading y view ausente; failed conserva error como desconocido, nunca loaded(nil). Cancelación por salida vuelve a idle si no había resultado válido; rechazar completions obsoletas por generation. Consulta inicial al abrir/relanzar; recuperación normal de idle/failed al reaparecer o foreground visible, y nueva lectura ante invalidación postcommit watering. Cada disparador admite como máximo una solicitud deduplicada; fallar no programa otra, y publicaciones de estado/render no disparan consultas. Un loaded válido sin invalidación se conserva al reaparecer/foreground y reformatea; zona/día solo reformatean, no releen store. No retry manual ni loops automáticos.

## Visual Design Impact

- UI: sí, tarjetas y box Cuidados del detalle. Fuentes: DESIGN + descripción Stitch explícita de usuario, adaptada a SF Symbols/tokens nativos.
- **Tarjeta (solo loaded):** línea debajo nombre/especie y antes de ubicación opcional, gota `drop.fill` ~17pt + texto ~13pt medium escalable (caption), Primary para fecha. Ausencia `drop` outline/TextSecondary. Mantener foto4:3, margen16, radio22, una columna, cabecera única fija y navegación actual. Nunca añadir consejo de sustrato a tarjetas/Mis plantas.
- **Detalle con fecha:** dentro del box Cuidados existente, encima del CTA (banner conservado aparte), fila compacta SurfaceMuted (equivalente surface-container-low), radio12, gota en círculo CareMint (equivalente primary-fixed), etiqueta izquierda «Último riego», valor derecha «Hoy, 12 oct 2026» o fecha anterior; permitir wrap/adaptación, no truncar.
- **Detalle sin riego (loaded(nil)):** mismo box/fila tenue, gota outline en círculo neutro, dos líneas «Último riego»/«Sin riegos registrados». CTA Registrar cuidado y debajo «Antes de regar, comprueba la humedad del sustrato.» permanecen en TODOS los estados internos del resumen, también oculto/error, SOLO dentro de detalle con metadata loaded: recordatorio estático, no resultado de humedad ni condición/frecuencia inventada.
- **idle/loading/failed:** resumen totalmente ausente, sin fila/icono/texto/spinner/placeholder/espacio reservado/mensaje de error/Reintentar ni accesibilidad. No ocultar box Cuidados, CTA, banner o consejo del detalle. No generar claves de loading/error/retry para esta feature. No icono de alarma.
- Textos visibles loaded en Localizable.xcstrings, claves literales en Presentation, fallback español. Iconos decorativos ocultos; label/value accesibles por UUID SOLO loaded. Añadir únicamente IDs `cardLastWatering-UUID`, `detailLastWatering-UUID` cuando existe resumen. La accessibilityValue de tarjeta conserva siempre estado foto y añade resumen solo loaded; al ocultarlo elimina cualquier valor accesible residual.
- No assets web ni nuevos colores necesarios; recurso nuevo: no. No rediseño de componentes no afectados ni footer/sheet nuevos.

## Expected File Changes (implementación futura, no realizados)

- Crear cuatro fuentes anteriores bajo `Features/LastWateringHint/{Domain,Presentation}`; Data nuevo **no necesario**.
- Modificar `Features/PlantList/Presentation/{PlantListViewModel,PlantCardViewModel,PlantCardView,PlantListView}.swift`: inyección, lifecycle/contexto, callback dirigido y línea accesible.
- Modificar `Features/PlantDetail/Presentation/{PlantDetailViewModel,PlantDetailView}.swift`: carga independiente, callback confirmado y fila condicional sin espacio residual; conservar box/CTA/consejo.
- Modificar `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/Localizable.xcstrings`, `PlantCareAI.xcodeproj/project.pbxproj`: composición, textos/keys únicas y registrar fuentes app/tests explícitamente.
- Crear `PlantCareAITests/{LoadLastWateringTests,LastWateringHintViewModelTests,LastWateringDateFormatterTests}.swift`; extender PlantList/PlantDetail VM tests e integración `LocalCareEventRepositoryTests.swift` sin quitar contratos previos.
- Extender `PlantCareAIUITests/PlantCareAIUITests.swift` con `LastWateringHintUITests`, regresiones/callers precisos y fallback. Si hace falta fallo de lectura aislado, extender seam `CareEventTestFixture.swift` y composición SOLO Debug Simulator/UUID; jamás usar sidecar como datos reales ni corromper PlantStore del usuario.
- LocalPlantRepository / CareEventRepository / modelos persistidos / init.sh: sin cambio previsto; una modificación necesitaría justificar impacto y ampliar tests pertinentes, no ejecutarla por rutina.

## Durable Documentation Impact

- `ARCHITECTURE.md`: update tras aprobación/implementación, nuevo caso de uso compartido, consumidores y refresh/contexto; sustituir descripción actual sin última-fecha, manteniendo historia.
- `CONSTRAINTS.md`: not needed; ya prohíbe hechos inventados y fija verificación/privacidad; no nueva regla operativa.
- `AGENTS.md`: not needed; ningún cambio de workflow/startup.
- `DESIGN.md`, `docs/domain-model.md`: update solo delta listado/detalle, máximo watering/zona actual, ocultación sin resultado, distinguir failed/loaded(nil) y recuperación por lifecycle, consejo estático exclusivo del detalle. No reescribir specs/ADR008/009 aceptados.
- ADR nuevo propuesto `docs/adr/010-last-watering-summary.md`: breve frontera compartida de consulta, dos callers y refresh postcommit, sin migración; documentar coste fetch existente. Crear tras aprobación, alinear arquitectura.
- `docs/testing-ui.md`: update cobertura nueva e IDs, no repetir conteos históricos como actuales. `docs/risks-and-open-questions.md`: update límites tiempo/lectura/coste; build brief no necesita duplicar comportamiento ya definido para detalle.
- `PROGRESS.md`, `feature_list.json`: actualización futura por rol con evidencia real y delta de alcance aprobada; hoy sin cambio. No cambiar passing/accepted ni evidencias vacías por una spec.

## Implementation Plan / Tasks (solo tras revisión humana)

1. Obtener aprobación integral de spec antes de implementar; alcance listado + detalle, formatos y ocultación ya son decisiones puntuales confirmadas. Tras aprobación actualizar delta del harness/doc durable y conservar base contractual aprobada.
2. Implementar y probar regla de máximo puro sobre repo existente; formato separado y fechas/zonas deterministas.
3. Implementar VM de resumen con lectura/error interno/generaciones, recuperación por lifecycle deduplicada y contexto día/zona testeable; registrar fuentes explícitas, sin retry manual ni loops.
4. Componer mismo actor en lista/cards/detalle; enlazar callback watering real y refresh aislado sin tocar cache ni metadata.
5. Añadir línea/fila SOLO loaded, localización/accesibilidad condicionales sin espacio residual; conservar sheet/CareEvents/banner y frase exclusiva del detalle.
6. Añadir integración/UI focalizadas, verificar por impacto y documentar evidencia/handoff para validator.

- [ ] Máximo con input desordenado, distintos kinds/UUID, vacío/error y empate.
- [ ] Formato exacto hoy/anterior/año distinto; zona/DST/frontera de día/reloj retrocedido.
- [ ] Tareas independientes, cancelación/late response, solicitudes deduplicadas y refresh postcommit; recuperación al reaparecer/abrir/foreground sin retry manual ni loops.
- [ ] Riego retroactivo no reduce máximo; otros cuidados/cancel/error/busy no alteran resumen.
- [ ] Dos plantas/relaunch sin reseed, modelos siete campos/Plant/JPEG exactos.
- [ ] UI/lista/detalle con fecha/ausencia SOLO loaded; idle/loading/failed sin view/espacio/accesibilidad, textos largos/scroll/fallback y consejo solo detalle incluso con resumen oculto.
- [ ] Docs y registro de fuentes/keys coherentes; revisión estática del diff y handoff por impacto.

## Verification Plan (comandos futuros; ninguno ejecutado por planner)

### Implementer — impact-selected checks

- Coordinar sesión activa antes de pruebas; único iPhone Simulator estándar/texto normal/una apariencia, workers XCTest5, sin procesos competidores ni matrices extra. Preparación Debug solo plantilla pública vacía si falta config, nunca leer/overwrite config existente; no API necesaria.
- Regla/formatter/VM nuevo → fecha falsa, failed confundido con nil, carreras/loops → LoadLastWateringTests, LastWateringDateFormatterTests, LastWateringHintViewModelTests. Dobles asíncronos suspenden/fallan lectura y cuentan invocaciones: conservar failed interno, no publicar ausencia, aceptar éxito tras lifecycle/invalidación, rechazar completions viejas y no relanzar por fallo/render ni timer de día/zona.
- Composición/callback/card y detalle → cache/aislamiento/cancel/otros tipos → PlantListViewModelTests, PlantDetailViewModelTests, PlantCardViewModelTests y RegisterCareViewModelTests directamente relacionadas; LocalCareEventRepositoryTests para lectura real/reopen/orden/modelos/JPEG.
- UI y recursos → layout/navegación/negativos → LastWateringHintUITests con registro real/retroactivo/otros kinds/cancel/fallo de save y lectura, volver lista/relaunch/foreground; comprobar resumen/IDs/valor accesible ausentes en idle/loading/failed, sin spinner/error/retry/espacio reservado, y loaded(nil) distinto de fallo. Seam de lectura suspendida/fallida independiente de foto/metadata permite comprobar box/CTA/consejo persistentes SOLO detalle y recuperación al reaparecer/foreground sin botón. Conservar retry existente de guardado CareEvents en su cobertura, no introducir retry de resumen. Regresiones StoredCollectionUITests (dos escenarios), PlantCardsUITests textos largos/foto fallida, EditPlantUITests y LocalizationUITests por callers; actualizar assertions «sin última fecha» si aparecen, no debilitar salud/urgencia ni resto de cobertura.
- Comando focal de referencia (ajustar nombres finales y registrar selección concreta):

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/LoadLastWateringTests \
  -only-testing:PlantCareAITests/LastWateringHintViewModelTests \
  -only-testing:PlantCareAITests/LastWateringDateFormatterTests \
  -only-testing:PlantCareAITests/PlantListViewModelTests \
  -only-testing:PlantCareAITests/PlantDetailViewModelTests \
  -only-testing:PlantCareAITests/LocalCareEventRepositoryTests \
  -only-testing:PlantCareAIUITests/LastWateringHintUITests test
```

- Para capturas solo escenarios afectados: `build-for-testing` si productos no válidos, `TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 1)` y `xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" -parallel-testing-enabled YES -parallel-testing-worker-count 5 -only-testing:PlantCareAIUITests/LastWateringHintUITests test-without-building`. Abrir/inspeccionar capturas lista y box detalle fecha/ausencia real y resumen oculto durante lectura/fallo, sin huecos; verificar consejo solo detalle. No repetir pruebas ya válidas solo para capturar por rutina.
- E2E persistente disponible es XCUITest (no web): ampliar cobertura observable, UI no se sustituye solo por unitarias. Sin exigir cambio del día/zona del simulador global: calendario/foreground/frontera se prueban con seams deterministas, no matriz de destinos.
- Estáticos cuando aplique: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON único/traducciones previas para catálogo/harness y `git diff --check`; no sustituyen behavior tests.
- Gate accepted de main es antecedente, no prueba de fuentes nuevas. Reutilizar solo evidencia corroborada del mismo estado relevante/destino; si falta baseline diagnosticar focalmente, no full gate automático antes/después.
- Fallo: conservar bundle/resultado, hipótesis explícita; reparar y repetir escenario fallido/callers afectados primero. Sin retries/iterations para volver verde.

### Validator — final gate

- Un `caffeinate -dius ./init.sh` final sobre producto/tests/harness finales, o corroborar gate válido idéntico de esas fuentes/entorno. init ejecuta build-for-testing y ambas fases test-without-building, termina sin servidor; no modificar script. Exigir paralela y PhotosPicker serial verdes y descubrimiento/cobertura nuevos sin omisiones.
- No duplicar focalizadas cubiertas por gate sin laguna concreta. Fuente ejecutable/config relevante reparada invalida gate y justifica nuevo gate; cambios documentales de estado no.
- Esta entrega planner es documental: solo revisión de coherencia/lectura de spec; sin tests iOS, build, init ni configuración privada. SE/Dynamic Type aumentado/VoiceOver/otras apariencias fuera de rutina, no ejecutadas ni bloqueos por defecto.

## Evidence To Capture / Validator Checklist

- Evidencia futura: diff → riesgos → selección/comandos/resultados/logs/xcresult, SHA/estado de fuentes y entorno, tests nuevos vs reutilizados, capturas realmente inspeccionadas, fallos conservados y gate pendiente/resultado por rol.
- [ ] Alcance listado + detalle y formatos confirmados reflejados en harness tras aprobación integral; una feature sin extras, no autorización inferida de decisiones puntuales.
- [ ] Máximo occurredAt de watering propio; hoy/zona/fechas veraces, ausencia/error distintos.
- [ ] Solo loaded(Date?) renderiza resumen/IDs/accesibilidad; idle/loading/failed sin view ni hueco/error/retry. Error interno y recuperación normal por lifecycle/invalidación conservados, sin infalibilidad asumida ni loops.
- [ ] Commit confirmado actualiza lista/detalle; retroactivo, cancel/error/otros kinds correctos y tardías rechazadas.
- [ ] Plant/JPEG/schema/eventos existentes intactos; sin writes al consultar ni datos/red/IA nuevos.
- [ ] Referencia aplicada dentro de composición vigente, sin script/CTA falso/rediseños externos; accesibilidad y fallback conservados.
- [ ] Consejo exclusivamente detalle; box Cuidados/CTA/consejo y confirmación real permanecen cuando resumen se oculta.
- [ ] Pruebas unit/integración/UI y gate según ownership, inspección estándar real, evidencia durable sin passing/accepted anticipados.

## Dudas/propuestas para revisión humana y cierre planner

- Resuelto por usuario: **Mis plantas + detalle**, formatos hoy/anterior propuestos, ocultación completa idle/loading/failed sin retry manual y consejo SOLO en detalle; se registran como decisiones humanas puntuales, NO aprobación integral ni autorización de implementar.
- No dudas funcionales bloqueantes restantes ni nuevas preguntas. Propuestas técnicas aún sujetas a revisión integral: VM compartido por comportamiento con instancias por UUID/consumidor, mapeo SurfaceMuted/CareMint y ADR breve; no se presentan como decisiones humanas ya aprobadas.
- Riesgos de implementación conservados: refresh/generaciones con tarjetas retenidas, lifecycle estable que no depende de montar resumen, fecha/zona/frontera de día, failed interno vs nil, deduplicación sin loops, coste fetch por tarjeta visible y accesibilidad condicional del enlace.
- Planner ONE STEP termina aquí para **revisión humana integral**. Solo esta spec creada/actualizada; feature_list/PROGRESS/código intactos. Ninguna implementación/validación de código, build/tests/init/simulador/config privada, stage/commit/push/PR/merge ni escritura GitHub ejecutados.
