# Feature Implementation Spec: Consultar la ficha de un ejemplar

## Source Feature

> Política de verificación vigente: `AGENTS.md`. Un único iPhone Simulator estándar con texto normal y una apariencia, `./init.sh`, pruebas unitarias/UI funcionales e inspección visual básica. SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia solo si el usuario lo solicita expresamente. Se conserva soporte de accesibilidad y todas las aserciones funcionales; no declarar superadas comprobaciones no ejecutadas. Este ajuste sustituye únicamente obligaciones de verificación ampliada, no alcance ni evidencias históricas.

- `id`: `plant-detail`; `area`: `detalle`; `title`: Consultar la ficha de un ejemplar.
- `user_visible_behavior`: Desde su tarjeta se ven foto, especie confirmada, ubicación opcional y cuidados guardados de esa planta.
- `depends_on`: `plant-cards`, `accepted`; transitivas `empty-collection`, `local-plant-storage`, `design-resources`, `ios-bootstrap`, `accepted` en `feature_list.json`.
- `status`: `not_started` al planificar; `source`: `feature_list.json`.
- `verification`: Abrir dos plantas con fichas diferentes y comprobar que cada detalle presenta solo los datos propios; gate estándar.
- `notes`: Consejos orientativos, no diagnósticos.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/plant-detail`; rama indicada `feature/plant-detail`; base indicada `c3542e5abea1d1fa6bc6e8e4f3e91e03e8df5d91`.
- Planner ONE-STEP, 2026-10-10: decisiones visuales aprobadas por el usuario posteriormente, incluida fecha solo si está persistida (confirmado abajo). Solo esta spec; sin implementación, build/test/init.sh, validación de código, stage/commit/push/PR/merge ni inicio de otros roles. Implementación pendiente de autorización explícita.
- Raíz constatada mediante contexto del entorno y rutas absolutas devueltas al inspeccionar el worktree; no se ejecutó `pwd` ni se verificaron rama/SHA/limpieza con Git. Esos últimos datos proceden del encargo.

## Goal

Reemplazar el destino provisional de las tarjetas por un detalle nativo desplazable del UUID seleccionado. Consultar la fotografía inicial local, nombre propio, especie confirmada literal, ubicación cuando existe, fecha real de alta y los seis cuidados guardados **en ese ejemplar**, incluso sin red o si falla su fotografía.

Una sola pantalla de consulta, sin modelos persistentes nuevos: dos plantas de la misma especie conservan fichas y fotos independientes. La ficha es una copia orientativa guardada, no un catálogo de especie actualizado ni un diagnóstico.

## Non-Goals

- Edición, eliminación, historial/cronología, último riego, registro de riego u otros cuidados, añadir fotos, IA o preguntas; no mostrar botones, pestañas ni placeholders de esas futuras features.
- Alta, permisos de cámara/galería, importación de fotografías reales, límites del original o migraciones SwiftData.
- Cuentas, avatar/perfil incluso decorativo, estado activo/salud, sincronización, conexión, catálogo global, fuentes botánicas verificadas o consejos recalculados.
- Inferir condiciones del salón/cocina, taxonomía o frecuencia de riego desde ubicación/foto; añadir datos o fotografías de producto ficticios.
- HTML/Tailwind/JavaScript, Plus Jakarta Sans externa, Material Symbols, descargas web, temporizador simulando recuperación o nuevos paquetes.

## Job Story / Users And Permissions

Cuando selecciono una planta guardada, quiero reconocerla y consultar sus cuidados propios, para usar esa orientación sin confundirla con otra de la misma especie ni con un diagnóstico.
Único usuario local; lectura offline, sin permisos nuevos, credenciales ni envío de imágenes o contexto a servicios externos.

## Acceptance Scenarios

### 1. Detalle correcto y aislamiento
Given dos plantas locales con UUID/nombres/fotos/fichas diferentes y la misma especie,
When se toca la foto de la primera tarjeta y se abre su detalle,
Then el nombre, especie, fotografía, fecha y seis valores de cuidados corresponden exclusivamente al primer UUID; no aparece el aviso provisional.
When se vuelve con Atrás/gesto nativo y se abre el cuerpo de la segunda tarjeta,
Then solo aparecen datos del segundo UUID; la primera foto/ficha no se reutiliza por compartir especie; el listado conserva sus tarjetas y Añadir deshabilitado.

### 2. Ubicación y fecha veraces
Given una planta con ubicación y otra con `location == nil`,
When se consulta cada detalle,
Then la primera muestra su ubicación literal y la segunda no muestra fila, icono, hueco reservado ni «Sin ubicación»; un valor vacío/blanco tampoco produce placeholder.
Then «Guardada el …» se deriva de `createdAt`, no de hoy, del HTML ni de la fecha del archivo; especie se muestra literalmente, sin inventar nombre común/científico adicional.

### 3. Foto lenta o fallida, cuidados disponibles
Given metadatos legibles y una fotografía lenta, ausente, corrupta o no decodificable,
When se abre el detalle,
Then identidad y cuidados aparecen antes de terminar la foto; solo el marco muestra carga y después imagen o fallback local; no se oculta la ficha ni se muestra foto stock/ajena.
When se pulsa «Reintentar carga»,
Then se solicita realmente la foto de ese mismo UUID, sin resembrar/reparar archivos ni cargar de nuevo los cuidados; si persiste el fallo vuelve al fallback.
Given que el repositorio vuelve a entregar bytes válidos,
When termina ese reintento,
Then aparece la imagen propia, sin cambio de metadata ni de la otra planta; no basta cambiar una etiqueta durante 1200 ms.

### 4. Metadata ausente o error local
Given un UUID no encontrado en una lectura correcta, o un fallo leyendo el almacén,
When se intenta resolver el detalle,
Then se muestra respectivamente «No se encontró esta planta en el dispositivo.» o «No se pudieron leer los datos locales de esta planta. Vuelve a Mis plantas e inténtalo de nuevo.»; Atrás sigue disponible.
Then no aparece pantalla vacía silenciosa, ficha de otra planta ni datos obsoletos tomados de la tarjeta como fallback; no se solicita foto si no se obtuvo metadata válida.

### 5. Cancelación y reapertura offline
Given carga pendiente del primer detalle,
When se vuelve y se abre el segundo, o una respuesta antigua llega tras cancelar,
Then ninguna respuesta del primer UUID modifica el segundo ni convierte cancelación en error visible.
Given el fixture persistido,
When se termina y relanza la app sin desinstalar/resembrar y sin conectividad,
Then ambos detalles conservan sus datos/fotos/cuidados; no se solicita red ni se presenta error de conexión.

### 6. Accesibilidad y consejo orientativo
Given un iPhone Simulator estándar con texto normal y nombre/especie/cuidados largos,
When se recorre el detalle y sus controles con desplazamiento,
Then todos los textos y seis filas son alcanzables sin elipsis horizontal; Atrás y reintento tienen objetivo >=44×44 pt; etiquetas y orden son comprensibles.
Then la ficha se identifica como orientación guardada de ese ejemplar, no diagnóstico, pauta urgente, salud confirmada o guía sincronizada/permanente.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `CONTEXT.md`, `DESIGN.md` — reglas, estados aceptados y alcance.
- Skill `feature-spec` cargada y su `references/spec-template.md`; `.agents/skills/ios-clean-mvvm/SKILL.md` leída y aplicada para planificación.
- `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, `docs/adr/001-local-plant-storage.md`, `docs/specs/plant-cards.md` — propiedad por ejemplar y transición del shell. ADR conserva encabezado pendiente; aceptación actual consta en PROGRESS/feature list.
- Directorios raíz, `docs/`, `docs/specs/` y listado de Swift — no existía spec de `plant-detail`; los documentos opcionales product-brief/user-and-access-model/technical-discovery/mvp-scope no existen aquí.
- `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel,PlantCardView,PlantCardViewModel,PlantSelectionDestinationView}.swift` — NavigationStack UUID, estados y carga de imágenes.
- `PlantCareAI/Features/PlantList/Domain/{Plant,CareSheet,PlantRepository,LoadPlantsUseCase,LoadInitialPlantPhotoUseCase}.swift` — modelos/contratos reales.
- `PlantCareAI/Features/PlantList/Data/{LocalPlantRepository,PersistedPlant,StorageTestFixture}.swift` — metadata separada de JPEG, copia de cuidados y fixtures aislados.
- `PlantCareAI/{PlantCareAIApp,ContentView}.swift`, `PlantCareAI/Localizable.xcstrings`, `PlantCareAI.xcodeproj/project.pbxproj` — composición, recursos y registro manual de fuentes.
- `PlantCareAITests/{LocalPlantRepositoryTests,PlantCardViewModelTests,PlantListViewModelTests}.swift`, `PlantCareAIUITests/PlantCareAIUITests.swift`, `docs/testing-local-plant-storage.md`, `init.sh` — pruebas y comandos futuros.
- `.git` leído solo como archivo de enlace del worktree; no se accedió al gitdir externo. No se inspeccionó HTML original ni captura: se incorpora críticamente el resumen visual del encargo, no se afirma cotejo pixel a pixel.

### Existing Patterns / Current Gaps

- SwiftUI iOS 17+, VM `@MainActor`/`ObservableObject`, `.task`, ownership `@StateObject`; dependencias inyectadas desde app, `ContentView` delgado.
- Listado conserva tarjetas por UUID; destino actual resuelve contra `selectedPlant(id:)` y solo muestra nombre/aviso. Quitar el shell y la condición que dejaría un destino silencioso si el UUID no está.
- `Plant` contiene `name`, un único `confirmedSpecies: String`, `createdAt: Date`, `location: String?`, `careSheet`; `initialPhotoID == id`. No hay estados activo/salud ni condiciones ambientales.
- `CareSheet` tiene light/watering/humidity/temperature/substrate/fertilizer; `PersistedPlant` los guarda embebidos por planta, no por especie.
- Auditoría tras revisión del usuario: `PersistedPlant.createdAt: Date` se almacena desde `Plant.createdAt` en el inicializador y se recupera en `domain()`. Por tanto se aprueba mostrar la fecha real de alta; si un futuro modelo carece de ese dato persistido, se omitirá, nunca se fabricará. La base de datos es local (SwiftData), no un backend separado.
- Todos los campos persistidos útiles para esta consulta quedan cubiertos: nombre, especie confirmada, fecha, ubicación y seis cuidados; la referencia de foto se usa para mostrar la imagen. `id` y `photoReference` son técnicos y no se muestran. No hay otros datos de usuario guardados que añadir a este detalle; riegos, eventos, fotos adicionales y análisis corresponden a futuras features y siguen aplazados.
- `PlantRepository` no tiene fetch individual: `loadPlants()` devuelve metadata sin fotos y propaga fallo; `loadInitialPhoto(for:)` lee JPEG por UUID con errores locales.
- Foto de tarjeta: generación/cancelación, ImageIO fuera de MainActor, máximo 1600 px; solo cache de UIImage. Data aún lee/valida el JPEG original completo.
- Fixture Debug Simulator ya ofrece dos UUID, misma especie, seis cuidados distintos, ubicación solo en uno y motivos 640×480 diferenciados; `--storage-photo-missing` afecta solo al primero. Seed/verify leen bytes expresamente para pruebas, no demuestran precarga de producto.

## Technical Approach

### Domain / Data / metadata por UUID

- Crear `Features/PlantDetail/Domain/LoadPlantDetailUseCase.swift`: caso concreto `LoadPlantDetail`, `repository: any PlantRepository`, `execute(for id: UUID) async throws -> Plant?`.
- Resolver con `repository.loadPlants().first { $0.id == id }`: UUID, nunca índice/nombre/especie. `nil` significa no encontrado solo si la lectura fue correcta; error se propaga. Ninguna llamada a fotos ni escritura en este caso.
- Decisión mínima para el prototipo: relectura de metadata en apertura, no snapshot de la tarjeta ni nuevo fetch/método de repositorio. Coste O(n) conocido y aceptable; evitar rediseñar persistencia para esta pantalla.
- Reutilizar `Plant`, `CareSheet`, `PlantRepository` y `LoadInitialPlantPhoto` en Domain de PlantList; no duplicar entidades ni crear catálogo/repository de detalle. Dependencia explícita entre features solo hacia esos contratos Domain.
- Data de PlantDetail no necesita adaptador nuevo: reutiliza `Features/PlantList/Data/LocalPlantRepository.swift`. No modificar esquema, validación, orden, recuperación ni contrato público del repositorio.
- Flujos: `PlantDetailView → PlantDetailViewModel → LoadPlantDetail → PlantRepository ← LocalPlantRepository`; foto mediante `LoadInitialPlantPhoto → PlantRepository` sobre la misma instancia.

### Presentation / composición / ciclo de vida

- Crear `Features/PlantDetail/Presentation/PlantDetailView.swift` y `PlantDetailViewModel.swift`; VM recibe UUID inmutable y ambos casos de uso, sin rutas/Data concretos.
- Separar estado de metadata (`loading/loaded(Plant)/notFound/failed`) y foto (`idle/loading/loaded(UIImage)/failed`). Publicar metadata antes de esperar foto. No crear campos de cuidado con defaults cuando falla la lectura.
- Cargar metadata al aparecer el destino; después pedir foto inicial por ese UUID. Guardas evitan duplicados en loading/loaded. Fallo de foto nunca modifica `loaded(Plant)`.
- Preparación de imagen en Presentation: seguir algoritmo ImageIO existente de tarjeta, transformación de orientación y thumbnail máximo 1600 px fuera de MainActor. No retener Data junto a UIImage ni escribir thumbnails; no requiere refactor de tarjeta/infraestructura compartida en esta slice.
- Generación y comprobación de cancelación para metadata y foto; invalidar cargas pendientes al desaparecer. Cancelación vuelve a un estado recargable, no failure; respuestas tardías no se aplican. Reintento permitido solo tras fallo de foto, con guardas ante doble toque.
- No cache global por especie ni retención indefinida de VM/imagen de detalle en listado. Cache local mientras vive el destino; reapertura puede releer metadata/foto propias.
- Mantener el único NavigationStack y route UUID del listado. `PlantListViewModel` recibe `LoadPlantDetail` y ofrece fábrica de VM por UUID; `PlantListView` construye destino para todo UUID, sin condicionar a `selectedPlant`.
- Destino posee VM con `@StateObject` por UUID durante el push (no recrearlo por cada render); iniciar IO solo en `.task`, no en fábrica/init. Atrás/gesto nativos vuelven a tarjetas existentes sin resembrar ni reiniciar listado.
- `PlantCareAIApp` compone listado, detalle y foto con la misma instancia de repositorio elegida **después** del override Debug; detalle no ejecuta `StorageFixtureLoad` ni seed/verify otra vez. Views no crean adaptadores. `ContentView` intacto.
- Retirar `PlantSelectionDestinationView` y `collection.selection.pending`; cambiar hint a «Consultar la ficha de esta planta». Conservar `selectedPlant-<UUID>` en nombre real para compatibilidad de selección.
- IDs de detalle: `plantDetail-<UUID>`, `detailSpecies-<UUID>`, `detailLocation-<UUID>`, `detailCreatedAt-<UUID>`, `detailPhoto-<UUID>`, `detailPhotoError-<UUID>`, `retryDetailPhoto-<UUID>`, `detailCare-<campo>-<UUID>` (light/watering/humidity/temperature/substrate/fertilizer), `detailNotFound`, `detailStorageError`.

## Visual Design Impact

- UI: sí, detalle loaded/loading/error metadata y foto. Fuente normativa: `DESIGN.md` + brief; dos referencias HTML resumidas en el encargo, la de fallback repetida es **una** referencia, no tercer diseño. No nuevo recurso externo necesario.
- Barra nativa con título «Detalle de planta» y regreso, sin avatar, perfil, barra de estado dibujada ni cabecera duplicada. Una columna ScrollView sobre Background.
- Foto local protagonista ancho disponible, marco aproximado 4:3, radio 22 pt; blanco Surface en tarjetas de identidad/cuidados; márgenes 20 pt, interiores 16 pt, separación ~24 pt. Usar los ocho tokens actuales, SF y SF Symbols, no hex inline ni fuentes web.
- Identidad: nombre propio predominante (~22 pt semibold escalable); especie literal secundaria en cursiva (~15–17 pt, aun si el único String guardado es común); ubicación opcional con símbolo discreto; «Guardada el …» debajo.
- Fecha: `createdAt` con formato largo español (`es_ES`), día/mes/año sin hora, zona local del dispositivo; respetar timestamp almacenado. Tests fijan zona/locale para expectativas deterministas y prueban fechas distintas. Los fixtures existentes datan de 1970: no sustituirlas por septiembre de 2024 ni por hoy.
- Sección «Ficha de cuidados» + «Guía orientativa guardada para este ejemplar». Tarjeta blanca con seis filas en orden Luz, Riego, Humedad, Temperatura, Sustrato, Abonado; cada valor es el String guardado propio, sin traducir/reformular ni generar.
- SF Symbols propuestos: sun.max, drop, humidity, thermometer, leaf, leaf.circle; decorativos si etiqueta textual ya aporta significado. Separadores Outline discretos. Etiqueta y valor pueden apilarse a tamaños grandes, nunca alturas fijas/ellipsis para consejos.
- Cierre «Estos cuidados son orientativos y no constituyen un diagnóstico.»; no «Las condiciones de tu salón…» (no constan datos ambientales), «Guía permanente» ni «Ficha sincronizada y preservada…». No insignia «Ejemplar activo»: el modelo no tiene ese estado.
- Fallback: SurfaceMuted, SF Symbol de foto no disponible, «No se pudo cargar la fotografía», «La fotografía se lee desde este dispositivo. Puedes reintentar la carga local.» y «Reintentar carga». No «Comprueba tu conexión»: todo es local/offline. No afirmar que el archivo aún existe ni prometer recuperación o conservación garantizada.
- Carga/reintento reales con progreso mientras se espera IO/decode; sin demora artificial/JS. Marco normalmente 4:3; en accesibilidad permitir altura extra del fallback o botón/texto inmediatamente debajo para que nada quede recortado dentro del marco.
- VoiceOver: encabezados, orden foto/identidad/cuidados, lectura de cada etiqueta+valor, estado de foto y reintento independiente; evitar símbolos/imagen duplicando nombre. Todos los controles >=44×44 pt, texto flexible, contraste en claro/oscuro. UUID solo en IDs de tests, nunca texto de usuario.

## Expected File Changes (implementación futura; no cambios de código en planner)

- Crear `PlantCareAI/Features/PlantDetail/Domain/LoadPlantDetailUseCase.swift` — resolución read-only por UUID con contrato existente.
- Crear `PlantCareAI/Features/PlantDetail/Presentation/PlantDetailView.swift`, `PlantDetailViewModel.swift` — pantalla y estados separados.
- Modificar `PlantCareAI/Features/PlantList/Presentation/PlantListView.swift`, `PlantListViewModel.swift` — destino/fábrica e inyección; preservar listado y cards.
- Eliminar `PlantCareAI/Features/PlantList/Presentation/PlantSelectionDestinationView.swift` — shell retirado.
- Modificar `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/Localizable.xcstrings` — composición sobre repo común, copys españoles realmente usados y retirada de provisional.
- Crear `PlantCareAITests/LoadPlantDetailTests.swift`, `PlantDetailViewModelTests.swift`; modificar `PlantCareAITests/PlantListViewModelTests.swift` para nueva inyección.
- Modificar `PlantCareAIUITests/PlantCareAIUITests.swift` — reemplazar aserción provisional por ficha real y extender escenarios persistentes.
- Modificar `PlantCareAI/Features/PlantList/Data/StorageTestFixture.swift` solo si se requiere flag Debug de **cuidados largos**; preservar modelo/base normal y verificación coherente al relanzar. No nuevo fixture en producción.
- Modificar `PlantCareAI.xcodeproj/project.pbxproj` — fuentes/grupos/build phases app y unit tests, retirar shell; no autodiscovery.
- Docs futuras: `ARCHITECTURE.md`, `docs/testing-local-plant-storage.md`, `PROGRESS.md`, `feature_list.json` según siguiente sección.
- Sin cambios previstos: `ContentView`, `PlantCardView/PlantCardViewModel`, `EmptyPlantView`, modelos/contratos/adaptador persistente, assets, `init.sh` y tests de repositorio/tarjeta existentes.

## Durable Documentation Impact

- Ahora: crear solo `docs/specs/plant-detail.md`; feature list/PROGRESS permanecen intactos, sin estado/evidencia nueva.
- `ARCHITECTURE.md`: actualizar durante implementación mapa PlantDetail, reutilización Domain/Data, relectura metadata y sustitución shell; eliminar afirmaciones «no ficha de detalle». No cambia dirección de dependencias.
- `CONSTRAINTS.md`, `AGENTS.md`: no necesario; no cambian restricciones ni workflow.
- `DESIGN.md`: no necesario; aplicar dirección y conservar decisiones específicas de referencias en esta spec, sin cambiar diseño de otras pantallas.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`: no necesario; implementa reglas existentes, no amplía modelo ni resuelve importación.
- ADR 001: no necesario; medio/contratos persistentes no cambian. No nuevo ADR: caso de consulta sobre frontera existente, sin nuevo contrato storage/concurrencia ni migración. Encabezado desactualizado no bloquea esta feature.
- `docs/testing-local-plant-storage.md`: actualizar instrucciones/aserciones obsoletas del shell y añadir consultas de dos fichas y foto fallida; conservar reapertura/cleanup reales.
- `PROGRESS.md`, `feature_list.json`: implementer registra únicamente pruebas reales y límites; `passing` solo tras autoverificación, `accepted` exige validador independiente. No cambiar aceptación previa para satisfacer tests nuevos.

## Implementation Plan / Tasks (solo después de aprobación y autorización)

1. Confirmar raíz/rama/diff y baseline `./init.sh`; reparar baseline antes de ampliar. No forma parte de esta sesión planner.
2. Implementar caso de metadata por UUID y tests sin fotos; después VM con metadata/foto independientes, decode acotado y cancelación/reintento.
3. Componer sobre repo común, sustituir shell y construir UI/localización/IDs; registrar fuentes, adaptar tests del listado.
4. Extender UI tests persistentes y fixture largo opcional; ejecutar gate, focalizadas, Release e inspección visual/accesible.
5. Actualizar docs/evidencia y entregar a validación independiente sin adelantar otras features.

- [ ] Caso de uso por UUID distingue nil/error y no solicita fotos ni escribe.
- [ ] VM publica seis valores reales antes de foto; evita duplicados y respuestas tardías.
- [ ] Navegación nativa, propiedad estable del VM y composición real/fixture coherentes.
- [ ] Layout de referencia adaptado a iOS y copys locales veraces; sin shell ni falsas acciones.
- [ ] Tests unitarios/UI conservan cobertura previa y demuestran aislamiento/reapertura/error.
- [ ] Evidencia y documentación de implementación con limitaciones explícitas.

## Verification Plan (futuro; nada ejecutado por planner)

- E2E persistente nativo disponible: XCUITest en `./init.sh`; añadir/extender cobertura de esta navegación, no sustituirla solo por unit tests.
- `LoadPlantDetailTests`: dos plantas de misma especie con fichas diferentes, orden invertido, lookup exacto, UUID desconocido -> nil, lectura fallida -> error; contador asegura cero solicitudes de fotos/save. Integración sobre repositorio real reabierto recupera `Plant` completo, incluso al faltar foto.
- `PlantDetailViewModelTests`: metadata aparece con foto suspendida; mismo UUID en demanda, cache local y guardas de duplicación; missing/corrupt/decode inválido solo afectan foto; reintento exitoso pide mismo UUID y no relee metadata; fallo repetido estable; cancelación/obsolescencia de metadata y foto no mutan estado vigente. Usar puertas/continuations, no sleeps ni temporizadores ficticios.
- Unit: dos VMs conservan sus seis cuidados/ubicación/createdAt e imágenes distintas; imagen <=1600 px; fechas largas derivadas de instantes distintos con zona fija en tests. Mantener los tests actuales de tarjeta/listado/repositorio.
- UI `testPlantCardsSelectCorrectIdentity`: retirar expectativa de «próximamente», mantener foto/cuerpo de selección y Atrás; añadir especie, ubicación condicional, fecha real, seis valores correctos y ausencia de valores del otro UUID, incluso tras A→B→A.
- UI `testStoredCollectionSurvivesProcessRelaunch`: consultar ambos detalles antes/después de relanzar sin desinstalar, mantener `--storage-verify` y sus modelos/bytes completos. No confundir conteo de tarjetas con persistencia de fichas.
- UI foto fallida: `--storage-seed --storage-photo-missing`, abrir primera, verificar identidad/cuidados, reintento que vuelve a error local sin navegar/escribir; abrir segunda con foto válida. No usar `--storage-verify` sobre JPEG eliminado. Recuperación real determinista en unit tests; UI no promete reparar archivos.
- UI/texto largo: extender prueba existente a seis cuidados largos con apoyo Debug si necesario; scroll hasta Abonado/cierre, ubicación ausente sin placeholder, fallback/reintento accesibles. Mantener vacío/fallo global/Añadir deshabilitado y fallback español; ampliar fallback inglés a detalle sin claves crudas.
- UUID ausente/error de metadata del destino se cubren con dobles unitarios y revisión de sus estados de vista; no añadir rutas de producto ni flags que corrompan producción solo para alcanzarlos.
- Comandos disponibles, únicamente para futuras sesiones autorizadas (seleccionar `UDID` con `xcrun simctl list devices available`):

```sh
./init.sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAITests/LoadPlantDetailTests' \
  '-only-testing:PlantCareAITests/PlantDetailViewModelTests' \
  '-only-testing:PlantCareAIUITests/PlantCareAIUITests' test
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/DerivedData/ReleaseCheck" build
plutil -lint PlantCareAI.xcodeproj/project.pbxproj
python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null
git diff --check
```

- `init.sh` sigue ejecutando build/unit/UI, termina y puede imprimir guía; no modificarlo para imprimir solamente ni arrancar servidores/procesos de desarrollo largos.
- Manual habitual con fixture aislado: dos fichas, Atrás/gesto, fotografías distintas y fallback, comportamiento local offline e inspección visual básica de textos/controles/contraste en el único simulador estándar con texto normal y una apariencia; limpiar solo fixture.
- VoiceOver/Accessibility Inspector, pantalla pequeña/SE, texto aumentado/máximo y apariencias adicionales solo por petición expresa; no requisitos de aceptación habitual ni pruebas aprobadas si no se ejecutaron.
- Release sin flags/símbolos fixture según patrón existente. No descargar fotos; motivos locales de prueba no demuestran importación de fotografías reales.

## Risks / Decisions / Open Questions

- Sin bloqueo funcional/técnico identificado para planificar: dependencia aceptada y los datos necesarios existen. **Límite de ejecución actual:** falta autorización posterior para implementar; no iniciar implementer/validator.
- Confirmación del usuario: fecha visible únicamente si está almacenada (cumplido por `PersistedPlant.createdAt`); omitir avatar/estado activo, usar copys de carga local y cuidados orientativos, y omitir ubicación ausente sin placeholder. No quedan preguntas abiertas sobre estas cuatro decisiones.
- Se mantiene la propuesta técnica de relectura metadata mediante `loadPlants` + filtro UUID, sin nuevo contrato storage. La auditoría de campos no identifica otros datos útiles persistidos fuera del alcance aprobado; capacidades de futuras features siguen aplazadas.
- Riesgos residuales: lectura metadata O(n), JPEG completo en Data pese a thumbnail acotado, duplicación acotada del algoritmo de preparación de tarjeta en VM de detalle. No resolver importación/memoria del original aquí; pertenece a `save-plant`.
- Los HTML no están disponibles como archivos/capturas en este contexto: especificación conserva composición y crítica del resumen recibido; cotejo visual fino futuro si se facilitan originales, no bloquea contrato funcional.

## Evidence To Capture / Validator Checklist

- Futuro: logs/xcresult, entorno/UDID, resultados unitarios/UI, capturas básicas de ambos detalles/foto fallida con texto normal, reapertura sin resembrar y límites manuales reales en PROGRESS/feature list. Texto aumentado/máximo y otras variantes solo si solicitadas expresamente. No logs de fotos/datos sensibles ni evidencia inventada.
- [ ] Solo plant-detail; shell retirado; ninguna edición, historial, riego, IA o acción nueva ajena.
- [ ] Lookup por UUID, metadata/foto separadas, mismo repo en composición producción/fixture; sin escrituras ni red de consulta.
- [ ] Dos ejemplares de misma especie mantienen seis cuidados e imágenes propios al navegar/reabrir.
- [ ] Ubicación ausente omitida y fecha desde createdAt; especie literal, sin taxonomía/ambiente inferido.
- [ ] Foto fallida no oculta cuidados; reintento real aislado, cancelación/respuestas antiguas seguras.
- [ ] Layout iOS/recursos existentes, texto accesible, copy local/orientativo sin estado activo/salud/sincronización.
- [ ] Pruebas previas preservadas y focalizadas/E2E ejecutadas, fuentes registradas, evidencia durable y límites sinceros.
- [ ] Estado actualizado solo por rol autorizado con evidencia; esta planificación no modifica passing/accepted.
