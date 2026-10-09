# Feature Implementation Spec: Conservar un ejemplar local al reabrir

## Source Feature

- `id`: `local-plant-storage`; `area`: `persistencia`; `title`: Conservar un ejemplar local al reabrir.
- `user_visible_behavior`: Un ejemplar de prueba con identidad, foto inicial y ficha propia permanece tras cerrar y reabrir la app.
- `depends_on`: [`ios-bootstrap`] (`accepted`); `status` al planificar: `not_started`.
- `verification` de origen: guardar dos ejemplares distintos, reiniciar y comprobar identidad, foto y ficha independiente; gate estándar.
- Fuente: `feature_list.json`, consultado 2026-10-09. `empty-collection` también está aceptada; `plant-cards` y `save-plant` siguen pendientes.

## Goal

Sustituir el adaptador que siempre devuelve una lista vacía por persistencia **real y local por ejemplar**. Permitir a un consumidor de dominio guardar y recuperar dos plantas distintas con identificador estable, nombre propio, especie confirmada, foto inicial, fecha de alta, ubicación opcional y copia individual de la ficha de cuidados. Demostrar recuperación tras recrear repositorio y tras relanzar el proceso de la app mediante una prueba automatizada, sin sembrar plantas de ejemplo en el producto.

## Non-Goals

- No crear alta desde UI, cámara/galería, identificación, generación de ficha por IA ni una planta en el arranque: pertenecen a `choose-identification-photo`, `generate-care-sheet` y `save-plant`.
- No mostrar tarjetas, ficha navegable ni detalle de plantas guardadas; corresponden a `plant-cards` y `plant-detail`. No fingir que una colección con datos está vacía.
- No implementar todavía edición, eliminación, cuidados/eventos, fotos adicionales, historial, sincronización, cuentas ni catálogo global de especies. Tampoco importar, reescalar, comprimir o generar miniaturas de fotos del iPhone: la preparación de la imagen antes de guardarla corresponde a `save-plant` (foto inicial) y `add-plant-photo` (fotos posteriores), y debe planificarse explícitamente allí.
- No aceptar un borrador incompleto o una propuesta de IA como especie confirmada; los datos de prueba son exclusivamente fixtures de tests.

## Job Story

Cuando guardo un ejemplar ya confirmado y con su ficha, quiero que su foto y sus cuidados permanezcan ligados solo a él tras cerrar y abrir la app, para poder consultarlos cuando lleguen las pantallas de colección y detalle.

## Users And Permissions

- Una persona en un único dispositivo; almacenamiento privado de la app, sin permisos de galería, red, credenciales ni acceso remoto. Solo el flujo de dominio guarda plantas válidas; por ahora no existe acción de alta de usuario.

## Acceptance Scenarios

### 1. Dos ejemplares distintos sobreviven a la reapertura

Given un contenedor local vacío y dos ejemplares de prueba (incluso de la misma especie) con UUID diferentes, fotos JPEG diferentes, nombres y fichas diferentes
When el caso de uso guarda ambos, se libera el repositorio y se crea otro con la misma ubicación local (simulando cerrar y reabrir)
Then la lectura obtiene exactamente los dos UUID, fechas, nombres, especies confirmadas, ubicaciones opcionales y los seis campos de ficha respectivos, sin cruces ni datos compartidos; al solicitar la foto inicial de cada UUID se recuperan sus **bytes propios** desde archivos independientes. Un relanzamiento del proceso de app sobre esos datos tampoco los borra.

### 2. Instalación sin datos

Given un contenedor limpio sin registros
When la app abre y consulta el almacén
Then se presenta el estado vacío existente, sin planta de demostración, sin foto ficticia y con las entradas de alta aún deshabilitadas.

### 3. Datos incompletos, duplicados y error local

Given un ejemplar sin foto/ficha/especie confirmada, un UUID ya guardado, un registro local ilegible o un archivo de foto ausente/corrupto
When se intenta guardar, se intenta guardar de nuevo con el mismo UUID, o se carga la colección/foto, respectivamente
Then la operación falla de forma diferenciable; no se sobrescribe una planta anterior ni se convierte un fallo de lectura en `[]`/estado vacío. Una escritura fallida no deja un ejemplar parcial consultable; una foto ausente no se sustituye por otra planta ni por una imagen ficticia.

### 4. Colección existente antes de las tarjetas

Given que el almacén contiene una o más plantas y `plant-cards` aún no está implementada
When la pantalla «Mis plantas» carga la colección
Then no muestra el estado «Todavía no tienes plantas» ni simula tarjetas/detalle; indica de forma breve y veraz que hay ejemplares locales pendientes de visualización, con conteo si resulta útil. Si la lectura falla, muestra un mensaje de error local distinto del estado vacío.

## Repository Research

### Files Inspected

- `AGENTS.md`, `ARCHITECTURE.md`, `PROGRESS.md`, `feature_list.json`, `CONSTRAINTS.md` — reglas, capas, estado aceptado y gate.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, `DESIGN.md` — identidad por ejemplar, foto inicial, ficha orientativa, privacidad y diseño.
- `PlantCareAI/Features/PlantList/Domain/{Plant,PlantRepository,LoadPlantsUseCase}.swift` — `Plant` solo contiene UUID; lectura síncrona infalible hoy.
- `PlantCareAI/Features/PlantList/Data/EmptyPlantRepository.swift`, `PlantCareAI/Features/PlantList/Presentation/{PlantListViewModel,PlantListView}.swift`, `PlantCareAI/{PlantCareAIApp,ContentView}.swift` — adaptador temporal, composición en app y bifurcación UI vacío/no vacío.
- `PlantCareAIUITests/PlantCareAIUITests.swift`, `PlantCareAI.xcodeproj/project.pbxproj`, `init.sh` — tres pruebas UI de estado vacío, fuentes/targets explícitos, build + test en simulador.
- `docs/specs/empty-collection.md`, `.agents/skills/feature-spec/references/spec-template.md` — precedente y estructura. No hay `docs/adr/` ni target de pruebas unitarias en el repositorio actual.

### Existing Patterns / Gaps

- iOS 17+ SwiftUI, `Presentation → Domain ← Data`; `PlantCareAIApp` compone el adaptador, `ContentView` solo delega. Recursos españoles en `.xcstrings`; las UI tests se ejecutan con `./init.sh`.
- Aún no hay persistencia, operación de escritura ni test unitario. El ViewModel carga en `init` y `PlantListView` solo representa `[]`; hay que introducir estados `loaded/empty/error` sin disfrazar errores. El proyecto **no** descubre automáticamente archivos Swift nuevos.
- Antes de esta spec, persistencia nativa/formato de fotos eran decisiones abiertas: aquí se fija SwiftData para metadatos y archivos independientes para fotos; el reescalado de imágenes reales se decidirá antes de `save-plant`.

## Technical Approach

- **Domain (`Features/PlantList/Domain`)**: completar `Plant` con UUID, nombre propio, especie confirmada como texto (sin catálogo), fecha de alta, ubicación opcional y `CareSheet` propia con luz, riego, humedad, temperatura, sustrato y abonado. Representar la foto inicial con un identificador opaco de pertenencia al ejemplar (por ejemplo, el UUID de la planta), **no** una ruta, URL de almacenamiento ni bytes en cada resultado de lista. Un caso de uso `SavePlant` recibe planta completa y bytes de una foto inicial de prueba; `LoadInitialPlantPhoto` obtiene los bytes bajo demanda por UUID. Sin SwiftUI, UIKit, SwiftData ni rutas en Domain. Validar campos obligatorios y bytes no vacíos; Data comprueba formato de imagen admitido. No confirmar automáticamente una candidata de IA.
- **Contrato y errores**: extender `PlantRepository` con lectura de metadatos, creación con foto inicial y lectura separada de la foto; `LoadPlants`, `SavePlant` y `LoadInitialPlantPhoto` propagan fallos sin convertirlos en `[]` o en imagen vacía. Distinguir al menos validación, UUID duplicado, archivo de foto ausente/corrupto y error de almacenamiento. Las fotos pueden ser grandes: evitar leerlas al listar; no realizar lectura/escritura pesada en el hilo principal (usar operaciones asíncronas/aislamiento apropiado y estados de carga y error explícitos en Presentation).
- **Data (`Features/PlantList/Data`)**: usar **SwiftData para metadatos y ficha por ejemplar**, mediante modelo(s) persistentes privados de Data y `ModelContainer`/`ModelContext` inyectables; el contenedor de producción reside en Application Support privado y los tests usan un contenedor persistente aislado (no `inMemory`, porque se comprueba reapertura). Cada foto inicial se guarda en un **archivo de imagen independiente** en Application Support, con identificador interno estable vinculado al UUID de la planta; SwiftData guarda solo la referencia, **nunca los bytes de la foto**. No usar JSON por ejemplar ni SQLite directo como almacén alternativo de metadatos. Data mapea explícitamente entidades SwiftData ↔ modelos Domain; ni Domain ni Presentation importan SwiftData. No hay datos previos que migrar. Para crear una planta, escribir primero la imagen en destino temporal y verificarla, luego hacerla disponible y confirmar el registro SwiftData solo cuando la imagen esté lista; serializar comprobación de UUID duplicado y publicación para no sobrescribir. Ante error, limpiar temporales/archivo nuevo y no exponer registro parcial; documentar cómo detectar/limpiar archivos huérfanos tras interrupción de proceso y cómo señalar una foto referenciada que falta, sin ocultar corrupción. No duplicar imágenes al listar ni precargar fotos de toda la colección.
- **Preparación diferida de fotos**: los fixtures de esta feature usan imágenes pequeñas válidas; aquí no se importan fotos reales del iPhone ni se eligen resolución, calidad, formato definitivo o miniaturas. Antes de implementar `save-plant`, especificar un pipeline de orientación y reescalado, límite de dimensiones y bytes, codificación/compresión, uso de memoria y fidelidad suficiente; aplicar también en `add-plant-photo`. Una imagen de entrada grande no debe terminar sin control dentro de SwiftData ni en memoria al listar. Si el trabajo de preparación es demasiado amplio para `save-plant`, proponer una feature previa en `feature_list.json` con dependencias explícitas, no adelantarla aquí.
- **Composition/Presentation**: crear el contenedor SwiftData y reemplazar `EmptyPlantRepository` en `PlantCareAIApp` por la implementación local inyectada; retirar el adaptador temporal. Si falla la inicialización del contenedor, mostrar error local, nunca usar silenciosamente un almacén en memoria o el adaptador vacío. `PlantListViewModel` expone vacío, no vacío y error; `PlantListView` conserva intacto el vacío y, solo para no vacío/error, presenta texto localizable honesto sin tarjetas, navegación ni CTA falsa. `ContentView` permanece delegado. El flujo real será View → ViewModel → `LoadPlants`/`SavePlant` → `PlantRepository` ← `LocalPlantRepository` (guardar será invocado por un futuro flujo, no por esta vista).
- **Pruebas**: añadir target XCTest de pruebas unitarias (`@testable import PlantCareAI`) con fixtures locales de dos plantas completas, `ModelContainer` persistente aislado en directorio temporal y directorio de fotos temporal; verificar lectura después de recrear contexto/repositorio con el **mismo almacén en disco**, metadatos sin imágenes precargadas, fotos recuperadas individualmente por UUID, vacío, duplicado, incompleto, archivo de imagen ausente, fallo de SwiftData y fallo entre escritura de imagen/guardado de metadatos sin registros parciales. Para cubrir **relaunch de proceso** sin sembrado en producción: UI test de integración configura un fixture mediante argumento de lanzamiento **solo en configuración de prueba** o mecanismo equivalente del test target, inicia la app, la termina y la vuelve a lanzar contra el mismo contenedor; comprueba el estado no vacío honesto y la ausencia de estado vacío. Aislar y limpiar el contenedor de prueba para no contaminar los tests existentes; evitar backdoor de fixture en builds de distribución.

## Expected File Changes

- `PlantCareAI/Features/PlantList/Domain/{Plant,PlantRepository,LoadPlantsUseCase}.swift` — ampliar modelo y propagar errores.
- `PlantCareAI/Features/PlantList/Domain/{CareSheet,SavePlantUseCase,LoadInitialPlantPhotoUseCase}.swift` — ficha propia, escritura validada y foto inicial bajo demanda.
- `PlantCareAI/Features/PlantList/Data/{LocalPlantRepository,PersistedPlant}.swift` — adaptador, modelo SwiftData y mapeo; metadatos en SwiftData, fotos en archivos; eliminar `Data/EmptyPlantRepository.swift` al sustituirlo.
- `PlantCareAI/Features/PlantList/Presentation/{PlantListViewModel,PlantListView}.swift`, `PlantCareAI/PlantCareAIApp.swift` — estados y composición del contenedor SwiftData/repositorio; `ContentView.swift` no necesita cambio.
- `PlantCareAI/Localizable.xcstrings` — solo mensaje de colección con datos aún sin tarjetas y error local.
- `PlantCareAITests/LocalPlantRepositoryTests.swift` (target nuevo) y `PlantCareAIUITests/PlantCareAIUITests.swift` — persistencia SwiftData + archivos aislados y apertura/reapertura; mecanismo de fixture aislado si se utiliza.
- `PlantCareAI.xcodeproj/project.pbxproj` — registrar cada fuente Swift y el nuevo target/test scheme. `ARCHITECTURE.md`, `PROGRESS.md`, `feature_list.json` — actualizar con decisión y evidencia al implementar.

## Visual Design Impact

- UI involucrada: sí, solo el estado provisional no vacío y el de error en «Mis plantas»; fuente `DESIGN.md`, colores semánticos existentes, texto español, Dynamic Type y VoiceOver. No dibujar tarjetas 4:3 ni proponer detalle antes de `plant-cards`.
- Nuevo artefacto de diseño: no; son mensajes transitorios. Mantener estado vacío aceptado y entradas de alta deshabilitadas; no afirmar que se ha añadido una planta desde la UI.

## Durable Documentation Impact

- `ARCHITECTURE.md`: actualizar — cambia adaptador temporal por persistencia real, contrato de error/escritura, formato/ubicación y estado transitorio no vacío.
- `CONSTRAINTS.md`: no necesario salvo que la implementación fije una nueva regla transversal MUST/MUST NOT; las decisiones de almacenamiento locales se documentan en arquitectura.
- `AGENTS.md`: no necesario — no cambia el flujo de agentes ni gate.
- `docs/adr/`: crear una ADR breve al implementar — SwiftData para metadatos y archivos para fotos afecta `save-plant`, `add-plant-photo` y eliminación futura; registrar decisión, consecuencias (incluidas referencias rotas/huérfanos), alternativas y migración si se cambia el medio, manteniendo `ARCHITECTURE.md` alineado.
- `docs/domain-model.md`, `docs/build-brief.md`, `CONTEXT.md`, `DESIGN.md`: no necesario si se respeta el comportamiento documentado; `docs/risks-and-open-questions.md`: actualizar la decisión de persistencia/fotos que deja de estar abierta y el riesgo de formato/tamaño cuando se concrete.
- `PROGRESS.md` y `feature_list.json`: registrar pruebas/limitaciones y estado realmente alcanzado; esta planificación no marca `passing` ni `accepted`.

## Implementation Plan

1. Confirmar baseline con `./init.sh`; fijar contrato de dominio y casos de uso de lectura/escritura, con validación y errores.
2. Crear modelo/adaptador SwiftData de metadatos por UUID y fotos en ficheros separados, con contenedor/directorio inyectables y publicación/compensación ante fallos; sustituir composición temporal. Añadir estados de vista de no vacío/error sin tarjetas.
3. Registrar fuentes y target XCTest; probar dos instancias, fallos y fixture de relanzamiento de app sin datos de producción.
4. Ejecutar gate y comprobaciones focalizadas; registrar decisión de persistencia, evidencia y riesgos en docs de implementación.

## Implementation Tasks

- [ ] Definir `Plant`/`CareSheet`, invariantes, `SavePlant`, contrato de repositorio y propagación de errores a `LoadPlants`/ViewModel.
- [ ] Implementar lectura/escritura de metadatos en SwiftData y foto en archivo por UUID, sin precargar imágenes al listar, con publicación consistente y compensación ante fallos, aislable en tests y sin sobreescritura silenciosa.
- [ ] Sustituir `EmptyPlantRepository` en app; conservar el estado vacío y añadir mensajes accesibles para no vacío/error.
- [ ] Registrar archivos y target XCTest en `project.pbxproj`; pruebas de dos plantas con imágenes independientes, persistencia al recrear contexto/repositorio SwiftData, validación/duplicado, foto ausente/fallo del almacén e interrupción entre imagen y metadatos.
- [ ] Añadir cobertura de relanzamiento en UI test sin fixture persistente en producto; mantener los tres UI tests de vacío y evitar contaminación entre pruebas.
- [ ] Ejecutar verificación, revisar diff/capas, actualizar docs durables y evidencia según resultados reales.

## Verification Plan

- `./init.sh` desde raíz: **ejecuta** build y tests no bloqueantes en simulador (incluido nuevo target XCTest en el scheme compartido y UI tests); no inicia servidores ni se limita a imprimir instrucciones. No hay `pnpm test:e2e`: XCTest UI es el E2E persistente apropiado, por eso se añade prueba focalizada de relanzamiento además de integración del repositorio.
- Ejecutar por separado `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO '-only-testing:PlantCareAITests/LocalPlantRepositoryTests' test` y el UI test de relanzamiento; confirmar resultados reales y que los tres tests UI existentes siguen pasando.
- Verificar seis campos por UUID tras recrear contexto/repositorio usando el mismo almacén SwiftData en disco y bytes de **cada foto solicitada bajo demanda**; comprobar que la lectura de lista no carga binarios. Probar almacén vacío, duplicado, incompleto, imagen ausente, fallo de SwiftData y escritura fallida antes de confirmar metadatos, sin estado vacío falso ni registro parcial; cubrir huérfanos tras interrupción conforme a la política documentada. Relanzar app en el mismo contenedor de prueba y comprobar que el estado no vacío persiste; instalación limpia mantiene vacío. No usar desinstalación para la prueba de reapertura (elimina datos).
- `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`; `python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null`; `git diff --check`. Revisar que la app no trae fixture, imagen o clave y que no hay accesos cruzados Domain→Data ni I/O desde la vista. Si se cambia UI, inspeccionar mensaje no vacío/error en simulador, VoiceOver y Dynamic Type; registrar lo no comprobado.

## Evidence To Capture

- En `PROGRESS.md`/`feature_list.json`: fecha, simulador/UDID, resultados de gate y tests focalizados, IDs/nombres de tests, prueba de dos ejemplares/fotos/fichas tras reinstanciar y relanzar (sin desinstalar), estado vacío en instalación limpia, separación de ficheros, fallos entre imagen/metadatos y limitaciones de tamaño/inspección accesible. Próximo paso: `plant-cards` para mostrar datos; `save-plant` debe definir preparación/reescalado de fotos reales antes del alta. No marcar `accepted` antes de validación independiente.

## Validator Checklist

- [ ] Contrato Domain independiente de SwiftData, Data guarda metadatos en SwiftData y fotos como archivos, con composición única en app; no queda adaptador vacío activo ni JSON por ejemplar.
- [ ] Dos plantas distintas se recuperan completas e independientes después de recrear repo y relanzar proceso; listado sin cargar imágenes, fotos separadas accesibles por UUID; duplicado/incompleto/imagen ausente/lectura fallida no se confunden con vacío ni sobrescriben datos.
- [ ] UI vacía no regresa; no hay semillas en producto, alta ficticia, tarjetas, foto externa, red o catálogo compartido. Mensajes transitorios accesibles.
- [ ] Nuevas fuentes/target registrados, `./init.sh` y pruebas focalizadas pasan; tests originales permanecen, evidencia y documentos durables coinciden con el diff.
