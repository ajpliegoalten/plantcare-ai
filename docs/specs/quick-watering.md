# Feature Implementation Spec: Registrar un riego rápidamente

## Source Feature

- id: `quick-watering`; area: cuidados; fuente: `feature_list.json`.
- Estado: `not_started`, evidence vacía. Planner ONE STEP, 2026-10-11, `openai/gpt-6.1-sol`, skills `feature-spec` e `ios-clean-mvvm`.
- Dependencias `plant-detail` y `save-plant`: `accepted`; rediseño del detalle también accepted.
- Comportamiento: desde una planta registrar un riego fechado en unas 2–3 interacciones y recibir confirmación del registro real.
- Verificación prevista: contar interacciones, reiniciar y comprobar evento persistido solo para ese ejemplar; gate estándar.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/quick-watering`; rama `feature/quick-watering`, base `main`/`origin/main` `e9a18b053e9668c9a5508552e1e75ce6651e7fc0` comprobadas por el orquestador. Checkout base limpio; rama/worktree nuevos; sesión trasladada.
- Referencia: HTML del modal aportado por el usuario en la conversación, leído como dirección visual, no código ejecutable ni contrato de persistencia.
- Delta autorizada: cabecera con foto y formulario inset homogéneos también en `edit-plant`, exclusivamente visual. No reescribir su spec ni aceptación histórica.
- **Pendiente revisión humana. No autoriza implementación ni validación.**
- Usuario confirma bloquear fechas futuras, permitir anteriores al alta y normalizar nota mediante trim de extremos/blanca→nil/sin límite arbitrario. Solicita conservar zona horaria. Interpretación explicitada: instante absoluto + identificador IANA de origen persistido, visualización convertida a zona ACTUAL del dispositivo; el día puede cambiar al viajar. Estas respuestas resuelven decisiones funcionales, no constituyen aprobación integral ni autorización de implementación.

## Goal / Job Story / Usuarios

Cuando consulto un ejemplar que he regado, quiero registrar fecha y nota opcional rápidamente, para conservar una acción humana local perteneciente solo a su UUID.

Desde detalle loaded: Registrar riego → sheet precargada → Guardar riego. Dos taps para el caso por defecto, sin teclado ni confirmación adicional. Contar desde el detalle, no desde el arranque.

Único usuario local; sin permisos nuevos ni red/API/consentimiento externo. Funciona aunque falte o falle la fotografía.

## Non-Goals

- Otros cuidados, cronología, fotos nuevas, análisis, recomendaciones nuevas, cuentas/backend/sync/notificaciones.
- Acción desde tarjetas, autosave o guardar al abrir/cancelar.
- Deshacer/eliminar: corresponde a `delete-care-event`.
- Última fecha de riego, “Hoy” permanente o sugerencias calculadas: `last-watering-hint`.
- Deduplicación por día/contenido/especie: dos intenciones explícitas pueden registrar dos riegos iguales.
- Demo/avatar/selector de cuatro estados, falso detalle/salud/luz/fechas, badge verified y recursos externos.
- Footer “Registro manual del usuario. No altera las recomendaciones de IA.”, ni paráfrasis inferior sustitutiva: excluido expresamente por el usuario.
- Cambiar campos editables, validación, cancelación, persistencia o refresco aprobado de `edit-plant`.

## Acceptance Scenarios

### 1. Defaults y registro real

Given detalle A loaded y B de igual especie con UUID/ficha/foto propios,
When pulso Registrar riego,
Then abre “Registrar riego”, cabecera de A, fecha local actual y nota vacía; abrir no escribe ni anuncia éxito.

When pulso Guardar riego,
Then confirma exactamente un evento watering para A; solo tras commit dismiss y confirmación “Riego registrado” en detalle.
Then son dos taps; B y todos los campos/fotos de A permanecen intactos.
Then no cambia una fecha de último riego ni aparece Deshacer.
Given metadata loading/notFound/failed, Then no permite abrir formulario; foto fallida con metadata loaded sí permite registrar.

### 2. Fecha y nota

Given formulario abierto,
When selecciono Ayer/Hoy o fecha anterior y escribo nota multilínea,
Then chips y selector reflejan la misma fecha; guardar conserva selección y nota normalizada, sin ejemplos precargados ni truncamiento.

Given nota vacía o blanca, Then persiste nil.
Given nueva apertura, Then fecha actual y nota vacía, nunca borrador anterior.
Given fecha futura manipulada o valor no finito, When guardo, Then validación explícita y cero writes.
Then no es recordatorio ni exige fecha posterior al alta: permite cuidados anteriores al alta.

Reglas de fecha/nota confirmadas por el usuario.

Given evento con instante absoluto y zona origen persistidos,
When cambia la zona del dispositivo,
Then mostrar fecha convertida a zona ACTUAL, aunque cambie el día; conservar instante/zona sin reescribir. UI solo fecha, sin afirmar hora observada.

Given fallo local y cambio de zona antes del retry,
When reintento sin edición humana,
Then mismo UUID y siete campos; únicamente cambia la representación visible de fecha.

### 3. Cancelar, gesto y busy

Given borrador sin despacho de escritura,
When Cancelar o gesto de cierre,
Then cero writes/callbacks/confirmación; reabrir limpio. Relanzar no restaura borrador.

Given escritura despachada,
Then campos/chips/CTA/Cancelar/gesto bloqueados, spinner y “Guardando riego…”.
Then doble tap no duplica; éxito confirmado no se descarta por cancelación técnica tardía.

### 4. Error local y retry

Given fallo antes de context.save,
When guardo,
Then rollback deja cero eventos nuevos también al recrear repositorio.
Then sheet conserva fecha/nota y muestra “No se pudo guardar el riego en este dispositivo. Inténtalo de nuevo.” y “Reintentar guardado”, sin alusión a conexión.

When reintento sin editar,
Then reutiliza UUID/createdAt/payload y produce una sola inserción final, callback una vez, sin IA ni retry automático.

Given UUID de evento ya confirmado y siete campos exactamente iguales,
Then devuelve éxito canónico sin insertar/actualizar.
Given mismo UUID con payload distinto,
Then conflicto, nunca overwrite/upsert.

Given planta inexistente,
Then ausencia explícita, cero inserciones/éxito; Cancelar permite salir.
Given almacenamiento ilegible,
Then error, nunca lista vacía.

### 5. Persistencia y nuevas intenciones

Given riego confirmado para A,
When termino/reabro sin desinstalar/reseed y leo eventos por UUID,
Then recupero id/plantID/kind/occurredAt/note/createdAt/timeZoneIdentifier completos, B sin eventos y ambos Plant/JPEG exactos.

When registro otro riego explícito el mismo día con igual nota,
Then UUID nuevo y segundo evento legítimo.

Given cierre abrupto tras commit,
Then evento permanece, sin borrarlo como compensación.
Then no se promete restauración de banner ni borrador/retry entre procesos.

### 6. Editor homogéneo sin cambio funcional

Given ambos modales sobre A,
Then comparten sheet blanca/grabber/toolbar, cabecera con foto o placeholder, márgenes, grupo inset/inputs/CTA cápsula.

When edito nombre/ubicación o cancelo como antes,
Then conserva precarga/trim/nil/validación/save único/bloqueo/error/refresco detalle-tarjeta/relaunch/aislamiento aprobados.
Then no crea CareEvent ni añade IO fotográfico desde el editor.

Then textos largos, teclado, errores y CTA son alcanzables por scroll en simulador estándar; etiquetas/IDs intactos, sin claves crudas ni recorte horizontal.

## Repository Research

Planner inspeccionó `AGENTS.md`, `PROGRESS.md` reciente, `feature_list.json`, `CONTEXT.md`, `CONSTRAINTS.md`, `ARCHITECTURE.md`, `DESIGN.md`, ambas skills/template; `docs/{build-brief,domain-model,risks-and-open-questions,testing-ui}.md`; ADR 001/002 y spec histórica `edit-plant`.

Fuentes relevantes bajo `PlantCareAI/Features`: PlantList Domain `Plant`/`PlantRepository`, Data `PersistedPlant`/`LocalPlantRepository`/`StorageTestFixture`, Presentation `PlantListViewModel`; PlantDetail View/VM; EditPlant View/VM. También `PlantCareAIApp.swift`, tests LocalPlantRepository/EditPlantViewModel y búsquedas de métodos/verify UI, `init.sh` y registro manual de fuentes en `project.pbxproj`.

Búsqueda `CareEvent|VersionedSchema|SchemaMigrationPlan`: sin resultados. No había spec quick-watering previa.

### BD real frente al modelo documental

Única entidad actual `PersistedPlant`:
`id`, `name`, `confirmedSpecies`, `createdAt`, `location`, `photoReference`, `light`, `watering`, `humidity`, `temperature`, `substrate`, `fertilizer`.

**`watering` es texto orientativo de ficha, NO evento, última fecha, intervalo ni humedad observada.** Domain Plant no expone rutas y reutiliza id como initialPhotoID. No existen CareEvent, tabla/relaciones de cuidados, última-fecha ni procedencia persistida.

Modelo mínimo nuevo, con persistencia/mappeo/roundtrip reales de todos sus campos:

| Campo | Tipo | Origen / control |
| --- | --- | --- |
| id | UUID | Automático, por intención |
| plantID | UUID | Ejemplar del detalle, no selector |
| kind | String | Fijo `watering`, no selector |
| occurredAt | Date | Selector Fecha y chips Ayer/Hoy |
| note | String? | Nota opcional multilínea |
| createdAt | Date | Instante automático del primer despacho |
| timeZoneIdentifier | String | Identificador IANA de origen automático, no control ni offset fijo |

Cabecera utiliza nombre/foto existentes, no copias dentro del evento. No añadir cantidad/unidad/humedad/origen IA/updatedAt o campos inexistentes por imitar el HTML. Una entidad y un flujo; editor solo Presentation.

## Technical Approach

### Domain

Crear `Features/QuickWatering/Domain/{CareEvent,CareEventRepository,RegisterWateringUseCase}.swift`.
Foundation/Sendable/Equatable; sin SwiftUI/SwiftData/rutas/IO. Kind mínimo `.watering` con raw estable; otros tipos se añadirán en other-care-events.

Contrato `CareEventRepository`:
- `saveCareEvent(_ event: CareEvent) async throws -> CareEvent`.
- `loadCareEvents(for plantID: UUID) async throws -> [CareEvent]`.

Nueva frontera real de eventos; no ampliar PlantRepository obligando a todos sus doubles a simular historial. Errores validation/plantNotFound/conflict/storage. Planta existente sin eventos → []; ausencia/error no equivalen a []. Orden occurredAt descendente, desempate createdAt descendente/id estable.

`RegisterWatering.execute(event:now:)` normaliza nota y valida estructura/tipo/zona. Las reglas temporales puras viven en Domain y Data también las aplica a llamadas directas. La comprobación contra now para una inserción nueva ocurre después de reconciliar el UUID en Data: el caso de uso no debe rechazar anticipadamente un duplicado exacto ya confirmado por un retroceso del reloj. Reloj/zona de presentación inyectables para tests, sin protocolo por cada valor.

Contrato temporal confirmado:
- UI solo fecha. Al abrir capturar zona actual IANA y fecha actual. Al seleccionar una fecha/chip, resolver inicio del día elegido mediante calendario gregoriano en zona ACTUAL y conservar esa zona como origen.
- occurredAt es ese instante absoluto; no una fecha civil UTC ni la hora observada del riego. createdAt es el instante real del primer despacho.
- timeZoneIdentifier es String no opcional en Domain/Data: identificador no vacío, resoluble y perteneciente al catálogo IANA admitido por Foundation, p. ej. Europe/Madrid. Rechazar abreviaturas/offsets fijos/identificadores desconocidos; sin fallback silencioso. Preservar el identificador capturado, sin recanonicalizarlo durante retry.
- Calendar.startOfDay determina el primer instante válido del día, incluido DST a medianoche. Rechazar un día civil completo inexistente comprobando los componentes solicitados frente a los resueltos; no desplazarlo silenciosamente al siguiente.
- Ayer utiliza Calendar.date(byAdding: .day, value: -1), no restar 86400. Picker/chips/formatters usan gregoriano y zona ACTUAL explícitos.
- Cambiar zona mientras la sheet está abierta convierte solo la visualización del instante seleccionado: no modifica occurredAt/timeZoneIdentifier, no constituye edición ni crea intención nueva. La siguiente selección humana de fecha/chip captura la nueva zona.
- Para nueva inserción: fechas finitas, zona válida, occurredAt normalizado a startOfDay en origen; comparar su día con Hoy calculado mediante now fresco en ESA MISMA zona y rechazar occurredAt > now. Admitir prealta.
- Retry conserva los siete campos, incluida zona origen, al cambiar zona/DST/medianoche. Nunca renormaliza payload con zona actual. Si retrocede el reloj y el instante resulta realmente futuro, informar validation conservando snapshot, sin mutarlo ni escribir automáticamente.
- Reconciliar duplicado exacto confirmado antes de validación temporal dependiente de now. Lectura valida estructura/zona/normalización, no fecha contra reloj actual.
- Toda fecha guardada se presenta convertida a zona ACTUAL; el día puede cambiar al viajar. Zona origen conserva contexto de interpretación/validación, no obliga a mostrar el día original ni añade selector de zona/hora.
- No añadir historial/último-riego para demostrar este contrato.

Nota confirmada: trim extremos, blanca→nil; preservar interiores/saltos/Unicode; sin límite arbitrario ni truncamiento.

### Data / atomicidad / migración

Crear `QuickWatering/Data/PersistedCareEvent.swift`, siete campos e id único. plantID opaco; no cambiar PersistedPlant ni añadir relaciones obligatorias/cascadas prematuras. timeZoneIdentifier String no opcional; V1 no contiene eventos, por lo que no hay filas antiguas a rellenar ni zonas que inventar.

El mismo `LocalPlantRepository` actor conforma a ambos contratos y comparte ModelContainer/Context/raíz. No segundo actor/container escritor ni adaptador ficticio. Data vive en adaptador existente por propiedad del almacén.

Schema ampliado `[PersistedPlant, PersistedCareEvent]`, mismo Plants.store/Photos. Comprobar planta/duplicado → insert → beforeCommit → save sin await entre pasos. Rollback en fallo; no mutar Plant ni leer/escribir JPEG por registrar eventos. Conservar cleanup aprobado de store(): IO de apertura existente no es nueva carga de foto.

Duplicado exacto compara literalmente los siete campos canónicos y pertenencia existente; retorna confirmado sin nuevo save. Cambiar únicamente la zona es conflicto, aunque ambas zonas tengan el mismo offset. Conflicto nunca modifica/deja contexto dirty. No confiar en upsert implícito de `@Attribute(.unique)`: fetch/check antes de insertar.

Migración requerida:
1. V1 actual no versionado → V2 aditivo: conservar exactamente nombre/campos/tipos de PersistedPlant y añadir entidad vacía.
2. Plan: migración ligera automática SwiftData, **a demostrar** con test real de disco V1→V2 y ADR 008.
3. Fixture V1 usa ModelContainer solo PersistedPlant con configuración/ruta anterior; inserta dos plantas/JPEG conocidos y libera contexto/container antes de abrir V2. No generar supuesto fixture antiguo con schema V2.
4. V2 comprueba todos los campos/bytes, cero eventos, registra riego y reabre conservándolo.
5. Si upgrade automático falla, detener y diseñar/aprobar migración explícita/versionada preservando V1.
6. Prohibidos reset/reinstalación/fallback memoria/cambiar identidad de entidad/debilitar assertions. Error de apertura/migración honesto, sin cleanup destructivo; downgrade a V1 no prometido.

Un actor escritor por store; sin exact-once multiproceso. Solo metadatos: context.save es frontera de commit, sin nueva transacción distribuida.

### Presentation / composición

Crear `QuickWatering/Presentation/{QuickWateringView,QuickWateringViewModel}.swift`.
VM MainActor/Identifiable, borrador nuevo por apertura e identidad de sheet distinta de plantID. Estados editing/saving/error/saved; payload inmutable al primer guardado y bloqueo antes del await.

Retry sin editar conserva payload completo. Editar tras error crea nueva intención/UUID/createdAt al siguiente despacho y limpia error. No replay incierto: Data devuelve éxito después de save; error de commit significa rollback. Payload distinto nunca reutiliza UUID antiguo.

Cancel/gesto solo antes del despacho, sin use case. Callbacks verifican sesión/plantID, una vez antes de saved/dismiss. No checkCancellation posterior a commit que convierta éxito en error.

PlantDetailViewModel recibe RegisterWatering y fabrica VM solo loaded. PlantDetailView habilita entrada actual y retira Próximamente/indisponibilidad; no crea bloque Último riego. Callback publica confirmación efímera canónica del mismo UUID; no cambia Plant/listado ni recarga ficha/foto.

“Riego registrado” accesible en detalle tras cerrar sheet exitosamente, sin Deshacer/fecha inventada. Nueva apertura limpia confirmación anterior para que Cancelar no aparente éxito. Banner no persistente, no historial simulado.

`View → VM → RegisterWatering → CareEventRepository ← LocalPlantRepository`.
PlantCareAIApp compone después de overrides Debug y pasa caso a PlantListViewModel/fábrica detalle. Sin IO en fábrica/init/Domain/View ni pantallas en ContentView.

Foto: snapshot Presentation de photoState existente del detalle para ambos modales; reutilizar UIImage acotada cargada, sin nueva lectura JPEG/decode. Loading/failed → placeholder SF Symbol, sin impedir guardar. Snapshot puede permanecer placeholder esa apertura; reapertura recoge estado actual.

## Visual Design Impact / delta edit-plant

Referencia HTML aportada y `DESIGN.md`; sin descargar fonts/CDN/imágenes ni copiar Tailwind/Material Symbols.

Ambas sheets:
- Surface blanca, esquinas superiores aprox24, grabber nativo.
- NavigationStack/toolbar Cancelar izquierda/título centrado.
- Contenido scroll, margen20/spacing16.
- Cabecera SurfaceMuted, foto real48×48/radio12 y nombre literal multilínea.
- Riego: “El registro se guardará exclusivamente para este ejemplar”.
- Editor: nombre persistido de apertura y especie literal secundaria, no texto de registro ni nombre del borrador.

Riego: grupo inset radio16; fila calendario/Fecha con DatePicker compacto date; Nota (opcional) multilínea blanca/radio12; chips Ayer/Hoy derecha, min44pt y selección no solo color; CTA full-width PrimaryAction cápsula min50 “Guardar riego”; spinner/retry local inline. Teclado/errores/CTA alcanzables por scroll; Done solo quita foco.

Editor: misma cabecera/grupo inset/inputs/CTA inferior “Guardar”. Sustituir guardado trailing por ese mismo comando único inferior. Conservar Cancelar/título/Done/IDs. Solo Nombre personalizado y Ubicación (opcional); misma semántica de retry/validación/cancel/refresco.

Componente pequeño compartido `PlantCareAI/Shared/Presentation/PlantFormHeader.swift`, solo datos Presentation, sin VM/repository/design-system global. SF nativo/SF Symbols, colores semánticos existentes, español/fallback español. Sin badge verified ni footer prohibido.

No copiar los errores de la demo: Cancelar **no** conduce a éxito; error no pide conexión; éxito no añade Deshacer ni Último riego; nota empieza vacía y fechas reales, nunca 12 octubre hardcoded.

## Expected File Changes

- Seis Swift QuickWatering y Shared/Presentation/PlantFormHeader descritos arriba.
- LocalPlantRepository: schema y conformidad/event insert/load. PersistedPlant, Plant y PlantRepository sin cambio de campos/contrato.
- PlantDetailView/VM, PlantListViewModel, PlantCareAIApp: inyección/modal/confirmación.
- EditPlantView layout; EditPlantViewModel solo metadata cabecera si necesaria; no tocar UpdatePlant/Data de edición.
- Localizable.xcstrings: solo claves usadas; project.pbxproj: registro explícito de nuevas fuentes app/tests.
- Nuevos `PlantCareAITests/{RegisterWateringTests,QuickWateringViewModelTests,LocalCareEventRepositoryTests}.swift`; ampliar Detail/List tests y regresiones storage/edit.
- QuickWateringUITests en archivo UI existente.
- Fixture Debug Simulator WateringTestFixture.swift y/o StorageTestFixture: fallo local/commit observable/verify de eventos real. Sin faults globales que rompan seed; namespace UUID/cleanup existente; seam excluido Release.
- ContentView/assets/init.sh/config privada sin cambios previstos.

## Durable Documentation Impact

En implementación aprobada:
- ARCHITECTURE: entidad/contrato/inyección/actor compartido.
- Nuevo `docs/adr/008-local-care-events.md`: schema aditivo/upgrade/atomicidad/retry.
- DESIGN: ambos modales y riego funcional sin último-riego; retirar placeholder autorizado en esta feature.
- domain-model: campos realmente persistidos, temporalidad/nota/retry.
- testing-local-plant-storage/testing-ui: upgrade/selectores/fixture/event verify/assertions placeholder sustituidas.
- risks si quedan riesgos nuevos. CONTEXT/build-brief/CONSTRAINTS/AGENTS no requieren cambios previstos.
- No reescribir ADR/specs históricas, especialmente edit-plant, ni regenerar CSV históricos.

Planner: solo spec, handoff PROGRESS y notes feature, sin código/evidencia ejecutada. Siguientes roles registran resultados reales; aceptación histórica editor intacta.

## Implementation Plan / Tasks

Solo tras revisión y autorización:
1. Confirmar raíz/rama/diff y revisión integral/autorización aún pendientes; aplicar decisiones temporales/nota resueltas y preservar historia.
2. Domain modelo/contrato/validación y tests puros.
3. Data schema/insert/load/rollback/idempotencia; upgrade V1→V2 primero.
4. VM/snapshot/cancel/retry/callback con continuaciones deterministas.
5. Composición mismo repositorio/fábrica detalle.
6. Sheet/confirmación; cabecera compartida/editor solo visual/localización/IDs/target.
7. E2E/fixture/regresiones/visual focal y documentación/evidencia.

- [ ] Siete campos persistidos y roundtrip, pertenencia por UUID.
- [ ] Upgrade conservador demostrado antes de declarar compatibilidad.
- [ ] Cancel/busy/error/retry/duplicado/conflicto honestos.
- [ ] Editor homogéneo conserva comportamiento aprobado.
- [ ] Tests/target/docs/handoff listos para validator.

## Verification Plan — futuro, no ejecutado por planner

### Implementer: cambios → riesgos → selección

- Domain → fechas/DST/medianoche/futuras/prealta/Unicode → RegisterWateringTests.
- RegisterWateringTests: Europe/Madrid invierno/verano, DST/inicio de día, día omitido Pacific/Apia, cruce de medianoche, futura/prealta, identificador desconocido/abreviatura/offset rechazados. Zonas/instantes inyectados: pruebas deterministas, no matrices adicionales de simulador.
- Formatter/VM: convertir mismo instante a zonas con distinto día; cambio de zona durante edición/error conserva payload; siguiente elección humana captura nueva zona; retry no recaptura Hoy ni renormaliza.
- LocalCareEventRepositoryTests: roundtrip literal de siete campos, zona corrupta produce error y no vacío; duplicate exacto no inserta; diferencia solo de zona produce conflicto incluso con offset equivalente; duplicado confirmado sigue siendo éxito tras retroceso del reloj, nueva inserción realmente futura se rechaza.
- Upgrade V1→V2: cero eventos antiguos, Plant/JPEG exactos; insertar evento con zona y recuperarlo íntegro al reabrir V2.
- VM → doble/busy/cancel/error/retry/edit/nueva intención/callback → QuickWateringViewModelTests con continuaciones, sin sleeps unitarios.
- Schema/actor → upgrade/rollback/aislamiento/idempotencia/foto → LocalCareEventRepositoryTests y LocalPlantRepositoryTests completos.
- Comparar Plant/JPEG exactos y siete campos evento, mismo repo y recreado; invalid persisted event no equivale a vacío; filtro/orden por plantID.
- Composición/cabecera → UUID/placeholder/cache → PlantDetailViewModelTests, PlantListViewModelTests, EditPlantViewModelTests. Foto fallida no bloquea; abrir modales no recarga binarios.
- E2E QuickWateringUITests: dos taps/relaunch/event verify A-B; fecha/nota/cancel/gesto/validación; error local/retry único/busy. Verify compara payload completo real, no contador constante; no crear cronología productiva para observar tests.
- Regresiones UI: ambos EditPlantUITests; StoredCollectionUITests persistencia/rediseño; PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation; SavePlantUITests por shared store/composición.
- Rediseño: sustituir solo Próximamente/disabled por entrada funcional y renombrar escenario coherentemente; conservar grid/seis cuidados/identidad/negativos de hechos inventados.

Baseline accepted164/164 reutilizable solo si coinciden fuentes/config/destino relevantes; nunca evidencia del schema nuevo. Si falta evidencia, diagnóstico/build focal, no gates automáticos antes/después. Conservar fallos; hipótesis y escenario fallido/afectados primero, sin retry para verde.

Comandos futuros autorizados, UDID estándar/DD dedicado, sin competidores, host despierto/tapa abierta; config vacía según AGENTS solo entonces:

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DD" build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$DD/Build/Products" 0)
xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -maximum-concurrent-test-simulator-destinations 5 \
  -only-testing:PlantCareAITests/RegisterWateringTests \
  -only-testing:PlantCareAITests/QuickWateringViewModelTests \
  -only-testing:PlantCareAITests/LocalCareEventRepositoryTests \
  -only-testing:PlantCareAITests/LocalPlantRepositoryTests \
  -only-testing:PlantCareAITests/PlantDetailViewModelTests \
  -only-testing:PlantCareAITests/PlantListViewModelTests \
  -only-testing:PlantCareAITests/EditPlantViewModelTests \
  -only-testing:PlantCareAIUITests/QuickWateringUITests \
  -only-testing:PlantCareAIUITests/EditPlantUITests \
  -only-testing:PlantCareAIUITests/StoredCollectionUITests \
  -only-testing:PlantCareAIUITests/SavePlantUITests \
  -only-testing:PlantCareAIUITests/PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation \
  -resultBundlePath "$DD/focused.xcresult" test-without-building
plutil -lint PlantCareAI.xcodeproj/project.pbxproj
python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null
python3 -m json.tool feature_list.json >/dev/null
git diff --check
```

Ajustar selección por diff/callers finales justificadamente. Capturas1 **solo** escenarios visuales afectados riego/editor/error/busy configurados con helper, sin repetir selección entera para capturas. Inspeccionar ambas sheets/placeholder/teclado/scroll en único iPhone normal/una apariencia.

Matrices ampliadas fuera de rutina, no ejecutadas ni requisitos por defecto. Release/auditoría de seam nueva justificada por WateringTestFixture Debug; reutilizar si no cambió. Sin API real/config sensible para riego.

### Validator: único gate final

Revisión independiente de arquitectura/diff/upgrade/campos/UI/escenarios. Un `caffeinate -dius ./init.sh` sobre fuentes finales, o corroborar gate válido de mismas fuentes/entorno. Ambas fases verdes; no repetir focalizadas incluidas salvo gap concreto.

init intacto: build una vez, unit/UI5workers y Fotos serial, test-without-building/xcresults separados; termina sin servicios. Obtener conteo nuevo real del descubrimiento, no prometer164 tras añadir tests.

Cambio relevante de schema/código/tests/resources/config invalida gate: focal afectada primero, gate nuevo solo por esa razón. Gate fallido nunca aprobado. Planner documental requiere coherencia, no tests iOS.

## Decisions / preguntas humanas / límites

Decisiones recogidas del pedido/referencia: foto/inset en ambos modales; controles humanos separados de metadatos; error LOCAL; fecha actual/nota vacía; Cancelar cero writes; sin footer prohibido, Deshacer ni último-riego de muestra.

Respuestas del usuario:
1. Sí: bloquear futuras y permitir anteriores al alta.
2. Sí: trim extremos/blanca→nil/sin límite arbitrario.
3. “Lo ideal es que se guarde con zona horaria para que si el dipositivo la cambia se muestre la fecha relativa a dicha zona.”

Interpretación explicitada: occurredAt absoluto + timeZoneIdentifier IANA origen persistido; mostrar en zona ACTUAL, permitiendo cambio de día al viajar. No civil inmutable ni hora observada.

No quedan preguntas funcionales fundamentales con esta interpretación. Decisiones puntuales no equivalen a aprobación integral ni permiso implementer/validator. Migración/APIs/tests permanecen pendientes de comprobación futura.

CareEvent debe crearse: no existe persistencia de eventos escondida. Migración ligera es plan técnico por demostrar, no resultado. Riesgos: upgrade/no-upsert/retry/identidad. Sin garantía frente a daño físico ni escritores multiproceso.

**Siguiente paso exclusivo: revisión humana integral de la spec actualizada. Detener planner; no implementar/validar/publicar.**

## Evidence To Capture / Validator Checklist

Futura evidencia: diff→riesgos→selecciones/comandos/log/exit/xcresult, fuentes/config pública/destino/entorno, nuevas vs reutilizadas y gate pendiente/verificado, UUID/payload reales tras relaunch, upgrade viejo→nuevo con Plant/JPEG exactos y capturas realmente abiertas de ambos modales.

- [ ] Siete campos reales; dos taps default; UUID/aislamiento/nueva intención mismo día; conversión de zona y retry inmutable.
- [ ] Cancel cero writes; busy; error/rollback/retry/duplicado/conflicto/ausencia.
- [ ] Upgrade V1 en disco conservador; sin reset/fallback/persistencia ficticia.
- [ ] Capas/actor/composición/target; foto reutilizada sin nuevo IO.
- [ ] Editor mantiene comportamiento aprobado.
- [ ] Sin último-riego/deshacer/footer/recursos externos.
- [ ] UI/teclado/Unicode/localización/E2E/regresiones conservadas.
- [ ] Evidencia honesta, gate único del validator y decisiones humanas resueltas.

## Planner Handoff

Planner investigó documentación/fuentes, sin shell/Git disponible. Su patch fue rechazado por permisos de edición y entregó contenido al orquestador; este persistió la spec y handoff en el worktree aislado. Sin implementación/build/tests/init/config privada/simulador/API/validación de código ni publicación. Estado `not_started`, evidence vacía.
