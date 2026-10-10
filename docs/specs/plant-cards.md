# Feature Implementation Spec: Ver tarjetas de ejemplares guardados

## Source Feature

> Política de verificación vigente: `AGENTS.md`. Un único iPhone Simulator estándar con texto normal y una apariencia, `./init.sh`, pruebas unitarias/UI funcionales e inspección visual básica. SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia solo si el usuario lo solicita expresamente. Se conserva soporte de accesibilidad y todas las aserciones funcionales; no declarar superadas comprobaciones no ejecutadas. Este ajuste sustituye únicamente obligaciones de verificación ampliada, no alcance ni evidencias históricas.

- `id`: `plant-cards`; `area`: `coleccion`.
- `title`: Ver tarjetas de ejemplares guardados.
- `user_visible_behavior`: Mis plantas muestra una tarjeta fotográfica por ejemplar con nombre, especie y acceso al detalle.
- `depends_on`: `empty-collection`, `local-plant-storage`; ambas `accepted`.
- `status`: `not_started` al planificar; fuente: `feature_list.json`.
- `verification`: Mostrar dos ejemplares locales; comprobar tarjetas separadas y apertura del ejemplar correcto; gate estándar.
- Plan exclusivo para `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/plant-cards`, rama solicitada `feature/plant-cards`, base indicada por el orquestador `f1437dfb48423e9d96f60d50a02f8818c1f6cde5`.
- Sesión planner: solo este documento; sin implementación, build, validación de producto, commits ni avance de estado. Rama/base proceden del encargo, no de una comprobación Git ejecutada aquí.

## Goal

Sustituir el mensaje temporal de colección con datos por una columna desplazable de tarjetas de los ejemplares realmente guardados. Cada tarjeta conserva identidad UUID, foto inicial propia, nombre personalizado y especie confirmada; muestra ubicación solo si existe. Leer la colección no precarga fotografías.

Entregar la selección/navegación por UUID a una pantalla temporal que muestra el nombre de la planta seleccionada; `plant-detail` la sustituirá después. El alcance es una presentación de colección y un flujo de selección, sin nuevos modelos persistentes ni ficha de detalle anticipada.

## Non-Goals

- Implementar la ficha: foto ampliada, cuidados, edición e historial pertenecen a `plant-detail` y sucesoras.
- Alta, cámara/galería, importación, IA, permisos, red, sincronización o semillas de producción.
- Riego, último cuidado, fechas de riego, «Sin riegos registrados», salud, estaciones, urgencias o confirmaciones ficticias. No existe aún un contrato de eventos para afirmarlos.
- Insignias de luz o resumen de cuidados en esta entrega; aunque hay ficha, no son necesarios para reconocer el ejemplar.
- Pestañas «Mis plantas/Identificar» o «Actividad», avatar, Tailwind, tipografías web, fotos remotas o toast de detalle.
- Cambiar esquema SwiftData, orden del repositorio, contratos de persistencia o resolver el pipeline de importación de fotos reales pendiente de `save-plant`.

## Job Story / Users And Permissions

Cuando vuelvo a mi colección, quiero reconocer y seleccionar cada ejemplar por su fotografía y nombre, incluso si dos comparten especie, para continuar con el ejemplar correcto.
Único usuario local; lectura sin conexión y sin solicitar permisos ni enviar fotos/contexto fuera del dispositivo.

## Acceptance Scenarios

### 1. Dos ejemplares independientes
Given dos plantas guardadas con UUID, nombres y fotos distintos, misma especie y ubicación solo en una,
When se abre Mis plantas y se desplaza la lista,
Then aparecen dos tarjetas separadas, cada una con sus datos/foto propios; no aparece el mensaje temporal, vacío ni error global; Añadir sigue deshabilitado.

### 2. Selección y límite de detalle
Given esas dos tarjetas,
When se toca la foto o el área de contenido de la primera,
Then se hace un push nativo a una pantalla temporal que muestra el nombre real de esa planta y el texto «El detalle de esta planta estará disponible próximamente.»; el destino recibe exactamente su UUID.
When se vuelve mediante Atrás y se toca la segunda,
Then el destino corresponde al segundo UUID/nombre, nunca al primero; volver conserva una colección utilizable.
Este escenario comprueba acceso/ruta del ejemplar, **no** aceptación de la ficha de `plant-detail`.

### 3. Foto diferida o fallida
Given metadatos legibles y una foto lenta, ausente, corrupta o que no se puede decodificar,
When la tarjeta entra en la lista visible,
Then mantiene nombre/especie/ubicación y su acceso; el marco 4:3 muestra carga y después foto o «No se pudo cargar la foto», sin foto ajena ni imagen stock.
When se pulsa «Reintentar foto» tras recuperar el acceso a esa foto,
Then se vuelve a pedir solo la foto afectada y se actualiza esa tarjeta; no se borra ni modifica la planta y la otra tarjeta sigue funcionando.

### 4. Vacío y fallo local existentes
Given almacén vacío o ilegible,
When se carga,
Then se conserva respectivamente el vacío aceptado con sus dos acciones deshabilitadas o `storageErrorMessage`, nunca se oculta un error como vacío ni se muestran tarjetas simuladas.

### 5. Reapertura y accesibilidad
Given los dos ejemplares persistidos en un almacén de prueba aislado,
When se termina/reabre sin desinstalar ni resembrar en el simulador estándar con texto normal,
Then siguen las dos identidades, fotos y datos correctos, sin recorte horizontal; contenido y segunda tarjeta son alcanzables desplazándose; VoiceOver identifica nombre, especie, ubicación si existe y acción de apertura.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `DESIGN.md`, `CONTEXT.md` — reglas, aceptación de dependencias y límites visuales.
- `.agents/skills/feature-spec/SKILL.md` (skill cargada), `.agents/skills/feature-spec/references/spec-template.md`, `.agents/skills/ios-clean-mvvm/SKILL.md` — contratos de planificación y capas.
- `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, `docs/adr/001-local-plant-storage.md` — propiedad por ejemplar y fotos locales. El encabezado del ADR conserva «pendiente», pero aceptación actual consta en PROGRESS/feature list.
- `PlantCareAI/Features/PlantList/Presentation/PlantListView.swift`, `PlantListViewModel.swift`, `EmptyPlantView.swift` — cuatro estados, cabecera accesible, acciones deshabilitadas y mensaje temporal.
- `PlantCareAI/Features/PlantList/Domain/Plant.swift`, `PlantRepository.swift`, `LoadPlantsUseCase.swift`, `LoadInitialPlantPhotoUseCase.swift` — identidad/contratos reutilizables.
- `PlantCareAI/Features/PlantList/Data/LocalPlantRepository.swift`, `StorageTestFixture.swift` — listado solo de metadatos, fotos por UUID, errores explícitos y fixture Debug Simulator.
- `PlantCareAI/PlantCareAIApp.swift`, `ContentView.swift`, `PlantCareAI.xcodeproj/project.pbxproj` — composición, entrada delgada y registro explícito de fuentes/targets.
- `PlantCareAIUITests/PlantCareAIUITests.swift`, `PlantCareAITests/LocalPlantRepositoryTests.swift` (líneas 1–85), `docs/testing-local-plant-storage.md`, `init.sh` — harness y pruebas existentes.
- Directorio `docs/specs/` — no existía spec `plant-cards`. No hay HTML/captura original en el repo; se usa DESIGN y el resumen del encargo, no se afirma inspección del adjunto.

### Existing Patterns / Current Gaps

- SwiftUI iPhone iOS 17+, ViewModel `@MainActor`/`ObservableObject`, `@StateObject` en composición, `.task` para carga; Domain solo Foundation.
- `loadPlants()` (equivalente al listado del encargo) devuelve `[Plant]`, no bytes: el repositorio ordena por `createdAt` ascendente; conservar su orden.
- `Plant.confirmedSpecies` es un único String, no campos común/científico separados. Mostrarlo literalmente como especie secundaria (científico cuando sea el dato guardado); no inferir, traducir ni inventar taxonomía.
- `LoadInitialPlantPhoto` es un caso de uso concreto inyectable con repositorio protocolizado; no hace falta otro protocolo para probarlo.
- La composición Debug actual cambia solo el listado a `StorageFixtureLoad`; añadir fotos sin cambiar composición leería equivocadamente `PlantStore` real.
- No hay ruta/detalle ni UI de alta. Los fixtures de fotos son cuadrados sólidos 4×4: prueban identidad, no apariencia fotográfica; requieren imágenes de prueba mejores para revisión visual.

### Correspondencia de la tarjeta con los datos existentes

| Elemento visible | Soporte actual | Decisión en esta feature |
| --- | --- | --- |
| Nombre personalizado | `Plant.name` / `PersistedPlant.name` | Título de la tarjeta y de la pantalla temporal; conservar la identidad mediante `Plant.id` (UUID). |
| Especie confirmada | `Plant.confirmedSpecies` / `PersistedPlant.confirmedSpecies` | Texto secundario literal. No hay nombre común y científico separados: no se pueden mostrar ambos como campos independientes. |
| Fotografía inicial | `Plant.initialPhotoID` (derivado de `id`), referencia local `PersistedPlant.photoReference`, `LoadInitialPlantPhoto.execute(for:)` | Carga diferida por UUID y presentación 4:3. Los bytes no forman parte de `loadPlants()` ni implican una URL remota. |
| Ubicación | `Plant.location` / `PersistedPlant.location`, opcional | Mostrar solo si existe; no inferir ubicación cuando es `nil`. |
| Fecha de alta | `Plant.createdAt` / `PersistedPlant.createdAt` | Existe y sirve para el orden actual de la colección; no hace falta mostrarla en la tarjeta. |
| Consejos de cuidados | `Plant.careSheet` y sus seis campos guardados por planta | Están disponibles, pero no equivalen a cuidados realizados ni se muestran en esta tarjeta. |
| Último riego/último cuidado, historial, estado de salud, luz observada | **No soportados** por `Plant`, `PersistedPlant` ni `PlantRepository` actuales: no hay eventos fechados ni observaciones confirmadas | Omitir fechas, icono/botón de riego, «Sin riegos registrados», insignias y diagnósticos del HTML. No añadir campos ni datos simulados. |

Las fotos son locales y pueden faltar o fallar aun si se pudieron leer los metadatos; mostrar un error por tarjeta sin convertir la colección en vacío. Esta auditoría describe el almacenamiento actual, no solicita ampliar el esquema.

## Technical Approach

### Presentation / navigation

- `PlantListView`: mantener cabecera y estados; en `.loaded` no vacío usar `LazyVStack(spacing: 24)` con `ForEach` por UUID. Quitar los espaciadores de centrado solo en la rama con tarjetas; no desplazar una tarjeta de tamaño fijo fuera de pantalla artificialmente.
- Crear `PlantCardView` y `PlantCardViewModel` en Presentation. El modelo recibe un `Plant` y `LoadInitialPlantPhoto`; publica estado de foto `idle/loading/loaded/failed`. La imagen decodificada es un recurso de Presentation, nunca parte de `Plant`.
- Crear modelos de tarjeta estables por UUID una vez recibido el listado; `PlantListViewModel` los conserva mientras vive esa colección. `.task` de cada tarjeta solicita su imagen; no un bucle de precarga desde `load()`.
- Evitar solicitudes duplicadas mientras carga/está cargada; cachear solo la imagen preparada, no Data más imagen permanentemente. Usar generación/cancelación para que una respuesta antigua no sustituya una más nueva ni convierta cancelación de tarea en fallo visible. Reintento explícito desde failed.
- Marco de foto 4:3 estable con recorte `scaledToFill`/clip; placeholder tonal neutral, carga y error legible. Decodificación fuera del MainActor, con downsampling ImageIO para imagen de presentación acotada (máximo 1600 px de lado largo), sin escribir miniaturas ni cambiar originales. Mantener límites de memoria/importación futura explícitos: el adaptador actual aún lee y valida el JPEG completo.
- Un solo control de apertura abarca foto y textos; botón «Reintentar foto» separado, no anidado en NavigationLink/Button de apertura. Su pulsación no navega. Nombre/especie/ubicación pueden envolver líneas sin `lineLimit(1)` obligatorio.
- `NavigationStack` en `PlantListView`, ruta tipada por UUID, no índices, nombre o especie. La selección se resuelve contra los modelos cargados; no se persiste la ruta ni se consulta/actualiza almacenamiento al tocar.
- Crear `PlantSelectionDestinationView`: pantalla temporal de Presentation de PlantList, con el nombre real de la planta seleccionada como título visible, aviso de que el detalle aún no está disponible y Atrás nativo; sin foto, especie, cuidados ni acciones de ficha. Exponer identificador `selectedPlant-<UUID>` para comprobar selección, no mostrar UUID técnico al usuario.
- `plant-detail` reemplazará ese destino usando la misma identidad; retirar shell/texto provisional entonces. No crear ahora carpetas, repositorios o casos de uso de PlantDetail ni prometer «detalle implementado». Esta transición explícita resuelve la dependencia circular de alcance sin un toast falso.

### Domain / Data / composition

- Flujo listado: `PlantListView → PlantListViewModel → LoadPlantsUseCase → PlantRepository ← LocalPlantRepository`.
- Flujo foto: `PlantCardView → PlantCardViewModel → LoadInitialPlantPhoto → PlantRepository ← LocalPlantRepository`; transformación visual/estado en Presentation, lectura/validación JPEG en Data.
- Domain sin cambios; no nuevo modelo de especie/evento ni ampliación del repositorio. Data de producción sin cambios.
- `PlantCareAIApp` compone listado y foto sobre la **misma instancia/raíz** de repositorio; inyecta ambos a PlantListViewModel, que pasa el caso de foto a los modelos de tarjeta. Views no construyen adaptadores; ContentView permanece delgado.
- En Debug Simulator, elegir repositorio de fotos sobre `StorageTests/<UUID>` junto con el listado fixture. Adaptar `StorageFixtureLoad` para recibir esa misma instancia (no crear escritores alternativos); conservar seed/verify/corrupt/cleanup existentes y sus verificaciones de bytes/modelos. Todo soporte de fixture sigue bajo `#if DEBUG && targetEnvironment(simulator)`.
- Para error UI añadir modo explícito de fixture que quite/corrompa solo la foto de un UUID después de sembrar/verificar, sin resembrar en reintento; el error de foto no debe disparar el verificador global. No alterar los flags de almacenamiento ya usados ni el directorio real.

## Expected File Changes

- `PlantCareAI/Features/PlantList/Presentation/PlantListView.swift` — modificar listado, layout y navegación.
- `PlantCareAI/Features/PlantList/Presentation/PlantListViewModel.swift` — inyección de foto y modelos estables de tarjeta.
- `PlantCareAI/Features/PlantList/Presentation/PlantCardView.swift` — crear componente fotográfico/accesible.
- `PlantCareAI/Features/PlantList/Presentation/PlantCardViewModel.swift` — crear carga de imagen por UUID, decode y reintento.
- `PlantCareAI/Features/PlantList/Presentation/PlantSelectionDestinationView.swift` — crear shell honesto, sustituible por plant-detail.
- `PlantCareAI/PlantCareAIApp.swift` — modificar composición real/fixture de ambos casos de uso.
- `PlantCareAI/Features/PlantList/Data/StorageTestFixture.swift` — modificar solo apoyo Debug Simulator: instancia compartida, fotos diferenciables 4:3 y fallo de foto aislado. Mantener dos ejemplares de la misma especie y ubicación opcional.
- `PlantCareAI/Localizable.xcstrings` — añadir textos usados de error/reintento/destino/hint en español; retirar `collection.stored` cuando deje de usarse. Conservar fallback y claves vacías/error.
- `PlantCareAITests/PlantCardViewModelTests.swift`, `PlantCareAITests/PlantListViewModelTests.swift` — crear pruebas de estados, identidad y límites de carga mediante dobles de contratos existentes.
- `PlantCareAIUITests/PlantCareAIUITests.swift` — actualizar relanzamiento sin eliminar su evidencia de persistencia; añadir tarjetas/selección/error de foto.
- `PlantCareAI.xcodeproj/project.pbxproj` — registrar cada nueva fuente en grupo y build phase del target app/unit tests apropiado.
- `EmptyPlantView.swift`, `ContentView.swift`, Domain, `LocalPlantRepository.swift`, `PersistedPlant.swift`, assets de producción e `init.sh` — sin cambios previstos.

## Visual Design Impact

- UI: sí; colección con datos, carga/error de foto y shell transitorio. Autoridad: `DESIGN.md`; no hace falta otro artefacto de diseño.
- Una columna, margen 20 pt, separación 24 pt, Surface blanca, radio ~22 pt, padding ~16 pt y contorno suave Outline; elevación mínima. Foto de ancho disponible 4:3, sin degradado decorativo ni URLs externas.
- Nombre personalizado principal ~22 pt semibold escalable, especie secundaria ~15–17 pt, ubicación opcional debajo; no fechas/estado/metadata de cuidados decorativos.
- Reutilizar los ocho colores semánticos existentes, SF Symbols y fuentes iOS; no introducir dependencias. Cabecera una sola vez; no replicar barra de estado ni tabs del HTML.
- Accesibilidad: 44×44 pt mínimo, texto flexible/contraste, cabecera apilada a tamaños de accesibilidad, etiquetas de apertura con nombre/especie/ubicación y hint honesto «Seleccionar planta; detalle próximamente». Ocultar imagen decorativa duplicada al combinar la etiqueta, anunciar error y mantener reintento accesible separado.
- IDs propuestos: `plantCard-<UUID>`, `plantPhoto-<UUID>`, `plantPhotoError-<UUID>`, `retryPlantPhoto-<UUID>`, `selectedPlant-<UUID>`; reutilizar IDs de vacío/error/Añadir.

## Durable Documentation Impact

- En planificación, crear solo `docs/specs/plant-cards.md`; no modificar estado/evidencia de features.
- `ARCHITECTURE.md`: actualizar durante implementación mapa Presentation, flujo de foto/composición y alcance provisional de navegación; no redefinir capas.
- `CONSTRAINTS.md`, `AGENTS.md`: no necesario; no cambian restricciones ni workflow.
- `DESIGN.md`, `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, ADR 001: no necesario; comportamiento y contratos durables no cambian, importación sigue pendiente. No nuevo ADR requerido.
- `docs/testing-local-plant-storage.md`: actualizar durante implementación referencias obsoletas a mensaje/sin tarjetas y comandos de fixture si cambian; conservar pruebas de persistencia.
- `PROGRESS.md`, `feature_list.json`: implementación registra pruebas reales, límites y siguiente paso; sin `accepted` antes del validador independiente.

## Implementation Plan / Tasks

1. Confirmar raíz/rama/diff y ejecutar baseline `./init.sh` antes de ampliar producto; reparar fallo baseline antes de continuar.
2. Añadir inyección común listado/foto, modelos de tarjeta y tests de carga diferida, identidad, cancelación/fallo/reintento.
3. Construir tarjetas, preservar vacío/error y añadir ruta UUID + shell provisional honesto.
4. Adaptar fixture y UI tests, registrar fuentes/localización; ejecutar gate y comprobaciones focalizadas/manuales.
5. Registrar evidencia y límites sin adelantar plant-detail, alta o riego.

- [ ] Inyectar ambos casos de uso en producción y fixture con instancia/raíz coherentes.
- [ ] Preparar imagen fuera del MainActor y aislar carga/error por tarjeta; evitar precarga/lecturas duplicadas.
- [ ] Implementar una columna de tarjetas, navegación UUID y shell; preservar Añadir deshabilitado y estados previos.
- [ ] Añadir tests unitarios y UI concretos; no quitar comprobación de modelos/bytes ni aislamiento/cleanup existentes.
- [ ] Inspección visual básica con texto normal, fotos representativas y ausencia de affordances falsas; actualizar docs/evidencia. Dynamic Type aumentado/máximo y VoiceOver solo por petición expresa.

## Verification Plan (para implementador/validador; no ejecutado por planner)

- Gate persistente E2E nativo existente: `./init.sh` ejecuta build, XCTest de repositorio y XCUITest, termina sin servidor/proceso de desarrollo. No modificarlo para solo imprimir guía ni sustituirlo por inspección visual.
- Unit tests: listado no inicia fotos; pedir tarjeta 1 lee UUID 1, tarjeta 2 UUID 2; dos solicitudes simultáneas no duplican lectura; error/cancelación no cruza estados; reintento lee solo afectada; decode inválido falla; respuesta obsoleta no sobrescribe; vacío/fallo global originales intactos. Usar repositorio doble con contador/puertas async y bytes distintos, no sleep para sincronización.
- UI: actualizar `testStoredCollectionSurvivesProcessRelaunch` a esperar ambas tarjetas/imágenes en vez de `storedCollectionMessage`, conservando `--storage-verify` y relanzamiento sin desinstalar. Añadir `testPlantCardsSelectCorrectIdentity` y `testPhotoFailureKeepsCardsAndNavigation`; mantener los cuatro tests previos de vacío/fallback/scroll/error.
- La prueba de selección toca foto de una tarjeta y cuerpo de la otra (scroll cuando necesario), espera ID/nombre del shell correcto, aviso provisional y Atrás. No confundir shell con ficha aceptada.
- UI error de foto verifica error localizado, otra foto intacta, metadata presente, reintento sin navegación, acceso al UUID afectado y ausencia de vacío/error global. Recuperación determinista del reintento puede probarse unitariamente; no afirmar reparación del archivo desde UI de producto.
- Comandos focalizados, tras obtener `UDID` de `xcrun simctl list devices available`:

```sh
./init.sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAITests/PlantCardViewModelTests' \
  '-only-testing:PlantCareAITests/PlantListViewModelTests' \
  '-only-testing:PlantCareAIUITests/PlantCareAIUITests' test
plutil -lint PlantCareAI.xcodeproj/project.pbxproj
python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null
git diff --check
```

- Manual con fixture aislado según `docs/testing-local-plant-storage.md`: inspección visual básica en un único simulador estándar con texto normal y una apariencia; comprobar segunda tarjeta por scroll, nombres/especie/ubicación largos, foto 4:3, Atrás y Añadir deshabilitado. Pantallas pequeñas/SE, texto aumentado/máximo y apariencias adicionales solo bajo petición expresa.
- Usar fotos propias/de prueba locales diferenciables con motivo visible para revisión de recorte; jamás descargar fotos remotas o sembrar PlantStore. Los cuadrados de color solo prueban aislamiento de bytes.
- VoiceOver real/Accessibility Inspector: solo por petición expresa, fuera de la verificación habitual; no declarar superado si no se ejecutó. Comprobar Release compilado sin flags/símbolos de fixture según patrón de evidencia de almacenamiento.

## Risks / Decisions / Open Questions

- Decisión de alcance confirmada por el usuario: navegación real a una pantalla temporal con nombre propio y aviso honesto, no ficha implementada ni toast. El criterio «apertura» de esta feature se interpreta como selección UUID/push verificable; la ficha completa tiene su propia aceptación en `plant-detail`. El orquestador debe conservar esta distinción en el handoff.
- Decisión de datos: especie secundaria usa confirmedSpecies; no nueva separación taxonómica. No metadata de cuidados sin contrato de eventos.
- Riesgo de memoria: preparación acotada no evita lectura/validación completa del archivo en Data ni limita fotos reales importadas; no declarar resuelto el pipeline de `save-plant`. Carga por demanda y cache de imagen evitan el peor caso de precarga de colección.
- Riesgo de fixture: listado y foto deben apuntar al mismo almacén; seed/verify leen fotos por diseño de prueba, no son evidencia de precarga de producto. Tests de lectura diferida usan listado/dobles sin esos flags.
- Sin preguntas bloqueantes para este contrato. Sigue pendiente sustituir el shell por detalle real y cerrar límites/orientación de importación en sus features; no hacerlo aquí.

## Evidence To Capture / Validator Checklist

- Capturar logs build/test y xcresult, nombres/resultados focalizados, entorno/UDID, capturas de dos tarjetas, destino de ambos UUID y fallo de foto; documentar limitaciones reales en PROGRESS/feature list.
- [ ] Una tarjeta por UUID, especie compartida no fusiona identidades; foto/ubicación pertenecen al ejemplar correcto.
- [ ] Listado solo metadata; carga de foto bajo demanda por caso existente; composición real y fixture coherentes.
- [ ] Foto fallida/cancelación/reintento no elimina planta ni afecta otra; no bloquea navegación.
- [ ] Push UUID y Atrás funcionan; shell anuncia límite, no implementa ni declara aceptado plant-detail.
- [ ] Diseño una columna, recursos semánticos, accesibilidad y Dynamic Type; ninguna fecha/salud/riego/nav inferior ficticia.
- [ ] Vacío, error global, fallback y Añadir deshabilitado conservados; persistencia y cleanup siguen probados.
- [ ] Fuentes registradas, tests unitarios/UI ejecutados y evidencia durable; planner no cambió estados ni producto.
- [ ] Capas y dependencias respetadas, ningún seed/permiso/red en producción; importación y detalle futuros no adelantados.
