# Feature Implementation Spec: Centralizar colores, imágenes usadas y textos visibles

## Source Feature

- `id`: `design-resources`
- `area`: `diseno-ios`
- `title`: Centralizar colores, imágenes usadas y textos visibles
- `user_visible_behavior`: La pantalla inicial conserva su aspecto y textos en español usando recursos de color y localización preparados para las próximas pantallas.
- `depends_on`: [`ios-bootstrap`] (aceptada); `status` al planificar: `not_started`.
- `verification` de origen: comprobar colores en `Assets.xcassets`, imágenes solo realmente usadas y textos desde `Localizable.xcstrings`; ejecutar gate estándar y revisar apertura en simulador.
- Fuente: `feature_list.json` (2026-10-09). `empty-collection` depende de esta funcionalidad y queda fuera de este cambio.

## Goal

Preparar recursos nativos compartibles de la paleta de `DESIGN.md` y un catálogo de textos visibles de la pantalla de arranque. Mantener al abrir la app el mismo fondo crema, jerarquía tipográfica, texto español y ausencia de acciones que tiene el bootstrap aceptado. No agregar imágenes por anticipado: hoy la pantalla no usa ninguna.

## Non-Goals

- No implementar «Mis plantas» vacío ni «Añadir», navegación, tarjetas, iconos, fotografías de ejemplo o nuevos mensajes de producto.
- No añadir un logotipo/ilustración placeholder, paquetes de tipografía, descargas de Stitch, Material Symbols ni imágenes no utilizadas.
- No cambiar almacenamiento, modelos, servicios, permisos, despliegue mínimo ni el funcionamiento del gate `init.sh`.
- No traducir la app a otros idiomas en esta tarea; fuente en español y valores españoles explícitos para la pantalla existente. El nombre de producto «PlantCare AI» permanece como marca.

## Job Story

Cuando abro el prototipo antes de disponer de una colección, quiero que su pantalla de preparación sea coherente y legible en español, para que los colores y textos usados por las siguientes pantallas partan de recursos mantenibles sin aparentar que ya existe el flujo de plantas.

## Users And Permissions

- Único usuario local: solo visualiza la pantalla de preparación, sin permisos, cuenta ni transmisión de datos.
- Implementadores siguientes: pueden reutilizar tokens y catálogo; deberán añadir claves/imágenes al implementarse su uso real, sin atribuir a estos recursos un flujo ya construido.

## Acceptance Scenarios

### Scenario 1: apertura conservada

Given la app iPhone instalada en un simulador y un lanzamiento en español
When se abre la app
Then siguen visibles «PlantCare AI» y «Preparando tu espacio para cuidar plantas.» con tipografía nativa, título verde oscuro `#264D3C`, cuerpo `#191C18` y fondo crema `#F8FAF2` hasta los bordes; no hay botón «Añadir» ni pantalla «Mis plantas».

### Scenario 2: recursos reales y conectados

Given el proyecto compilado con los recursos del target de app
When se inspeccionan `Assets.xcassets`, `Localizable.xcstrings` y `ContentView.swift`
Then existen los ocho colores de `DESIGN.md` como colores nombrados con sus valores exactos, los tres usados en el bootstrap se obtienen por nombre del catálogo en vez de RGB inline, y las dos cadenas en pantalla tienen entradas españolas en `Localizable.xcstrings` que usa SwiftUI; no hay imágenes sin uso incorporadas.

### Scenario 3: comprobación de regresión

Given el scheme compartido y un simulador iPhone disponible
When se ejecuta `./init.sh` y se inspecciona la app lanzada en simulador
Then pasan build y UI tests; la apertura es legible sin regresión visual, y el test sigue comprobando los textos de arranque y ausencia de «Añadir».

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json` — alcance, estado aceptado de `ios-bootstrap`, dependencias y gate.
- `DESIGN.md` — ocho colores, prioridades visuales y rechazo de recursos decorativos no autorizados.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md` — límites de MVP y de fotografías reales; contraste por comprobar al aplicar tokens.
- `PlantCareAI/ContentView.swift`, `PlantCareAI/PlantCareAIApp.swift` — pantalla raíz, dos literales visibles y tres colores RGB embebidos; no hay imágenes ni más vistas.
- `PlantCareAIUITests/PlantCareAIUITests.swift` — prueba de texto y ausencia de botón.
- `PlantCareAI.xcodeproj/project.pbxproj`, `init.sh`, `.gitignore`, `ARCHITECTURE.md`, `CONSTRAINTS.md` — proyecto con referencias explícitas y fase de recursos vacía, script de build/test, reglas y restricciones.
- `docs/specs/ios-bootstrap.md` y `.agents/skills/feature-spec/references/spec-template.md` — precedente y estructura del contrato.

### Existing Patterns To Follow

- SwiftUI iOS 17+, ventana única y `ContentView` sin navegación; conservar `.accessibilityIdentifier("bootstrapTitle")` y la prueba UI.
- Proyecto Xcode de referencias/fases explícitas (no grupo sincronizado por filesystem): cualquier catálogo nuevo debe estar incluido en la fase de recursos de **app**, no solo creado en disco. `DEVELOPMENT_LANGUAGE` actual: `developmentRegion = en`, `knownRegions = (en, Base)`.
- `./init.sh` selecciona un simulador disponible, ejecuta build y test; apertura visual aparte. No hay comando E2E adicional: el UI test es el comprobador persistente.

### Current Gaps / Unknowns

- No existe `Assets.xcassets`, `Localizable.xcstrings` ni fichero de imagen; no hay mecanismos previos de localización ni colores compartidos.
- Hay que verificar la sintaxis concreta de `.xcstrings` admitida por Xcode instalado y que la inclusión en bundle resuelva español en tiempo de ejecución; no basta JSON válido o compilar. El idioma del simulador puede no ser español: fijarlo explícitamente para la prueba o configurar español como idioma de desarrollo con fallback comprobado.
- La comprobación de contraste y apariencia oscura exige inspección en runtime; no cambiar los hex definidos para simular variantes sin validar. Evitar texto ilegible por Dynamic Type o dark mode.

## Technical Approach

Crear `PlantCareAI/Assets.xcassets` con `Contents.json` y ocho `*.colorset/Contents.json`: `Background`, `Surface`, `SurfaceMuted`, `Primary`, `PrimaryAction`, `TextPrimary`, `TextSecondary`, `Outline` para los tokens existentes (background, surface, surfaceMuted, primary, primaryAction, text, secondaryText, outline). Cada uno debe mapear exactamente al hex del encabezado de `DESIGN.md`: `#F8FAF2`, `#FFFFFF`, `#F2F4ED`, `#264D3C`, `#3E6553`, `#191C18`, `#414844`, `#C1C8C2` respectivamente. Usar componentes sRGB y apariencias universales al inicio; si se introduce variante dark, validar y documentar antes. `ContentView` utiliza `Color("Primary")`, `Color("TextPrimary")` y `Color("Background")` como mínimo, conservando distribución y accesibilidad. Evitar reserva de `*.imageset` sin uso; SF Symbols del sistema tampoco necesitan image assets.

Crear `PlantCareAI/Localizable.xcstrings` (formato Xcode String Catalog, `sourceLanguage: "es"`) con claves semánticas estables como `bootstrap.title` y `bootstrap.subtitle`, traducciones `es` exactamente «PlantCare AI» y «Preparando tu espacio para cuidar plantas.». Conectar `Text` mediante claves localizables (por ejemplo `Text("bootstrap.title")`), no `Text` de cadenas literales sin referencia al catálogo; para pruebas UI mantener el identifier del título y comprobar el texto resuelto. Declarar `es` en `knownRegions` y `developmentRegion` del proyecto para que español sea el fallback de los recursos; verificar efectivamente el comportamiento en simulador bajo español y, si se prueba inglés, que no aparezcan claves crudas. La marca `CFBundleDisplayName` fija del `project.pbxproj` no es texto de la pantalla SwiftUI; no hace falta cambiar el nombre/icono de la app en este corte.

Agregar ambos catálogos al target de app en `PBXResourcesBuildPhase` con referencias apropiadas; no al target UI test salvo necesidad técnica demostrada. No crear recursos extras para uso futuro sin consumidor actual (la paleta completa sí está requerida explícitamente por esta funcionalidad).

## Expected File Changes

- `PlantCareAI/Assets.xcassets/Contents.json` y ocho `*.colorset/Contents.json` — crear paleta de `DESIGN.md`, sin `imageset` anticipados.
- `PlantCareAI/Localizable.xcstrings` — crear catálogo con dos claves visibles y traducciones españolas.
- `PlantCareAI/ContentView.swift` — sustituir colores inline y resolver dos textos desde el catálogo; conservar contenido y layout.
- `PlantCareAI.xcodeproj/project.pbxproj` — registrar catálogos en fase de recursos de app y región española/de desarrollo (Debug y Release del mismo target).
- `PlantCareAIUITests/PlantCareAIUITests.swift` — ajustar/completar test de pantalla para lanzar en español y verificar cadenas resueltas sin perder prueba de no «Añadir».
- `PROGRESS.md`, `feature_list.json` — al implementar, registrar evidencia, estado y siguiente funcionalidad; no modificar durante planificación.

## Visual Design Impact

- UI involucrada: sí, solo apariencia/textos ya visibles de la pantalla inicial.
- Fuente: `DESIGN.md` (tokens del frontmatter y dirección de contraste/accesibilidad); `docs/build-brief.md` para límites funcionales.
- Estado afectado: lanzamiento bootstrap, sin acciones; conservar fondo a pantalla completa y textos legibles bajo Dynamic Type; revisar también modo oscuro por ausencia actual de colores adaptativos.
- Nuevo artefacto de diseño: no; el catálogo de colores y strings son recursos de implementación, no una pantalla nueva.

## Durable Documentation Impact

- `ARCHITECTURE.md`: actualizar — documentar localización fuente en español y `Assets.xcassets`/`Localizable.xcstrings` como recursos del target para pantallas futuras.
- `CONSTRAINTS.md`: no necesario — no aparece una nueva restricción de seguridad/despliegue ni una regla MUST/MUST NOT independiente de `DESIGN.md`.
- `AGENTS.md`: no necesario — gate y flujo de agentes permanecen iguales.
- `DESIGN.md`, `CONTEXT.md`, `docs/domain-model.md`, `docs/build-brief.md`, `docs/risks-and-open-questions.md`: no necesario — sin cambio de diseño, dominio ni decisiones de API; documentar solo discrepancias verificadas si las hay.
- `PROGRESS.md`, `feature_list.json`: actualizar al completar implementación, con pruebas concretas; no declarar aceptación por implementación sin validación independiente.

## Implementation Plan

1. Confirmar línea base y revisar en Xcode la convención de String Catalog y Asset Catalog soportada; no tocar el estado vacío.
2. Añadir los ocho colorsets semánticos y dos traducciones; cablear recursos y desarrollo español en el proyecto.
3. Sustituir solo literales de `ContentView` por recursos; actualizar el UI test para probar resolución española y ausencia de acciones.
4. Ejecutar gate y lanzamiento visual, inspeccionar catálogo integrado/idioma/contraste y registrar evidencia y límites.

## Implementation Tasks

- [ ] Crear catálogo con ocho colorsets sRGB y ningún imageset sin consumidor; cotejar valores hex con `DESIGN.md`.
- [ ] Crear String Catalog fuente `es` con claves de título/subtítulo y valores existentes; asociar a `Text` sin alterar VoiceOver ni identifier.
- [ ] Incluir ambos catálogos en fase de recursos del target app y declarar regiones/fallback coherentes; verificar bundle generado.
- [ ] Mantener/ampliar UI test para español, título, subtítulo y falta de «Añadir».
- [ ] Ejecutar build/test y apertura real en simulador; actualizar arquitectura y evidencia de progreso/feature.

## Verification Plan

- Comprobar estructura y valores de todos los `Contents.json` y `Localizable.xcstrings` (`plutil -lint PlantCareAI.xcodeproj/project.pbxproj`; `python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null`; revisar colorsets). Inspeccionar la fase de recursos y producto compilado para confirmar catálogos presentes y ausencia de imágenes de muestra.
- `./init.sh` desde raíz: **ejecuta**, no solo imprime, build + test no bloqueantes en simulador iPhone; no arranca servidor ni requiere modificar `init.sh`. Prueba UI con launch language español (`-AppleLanguages '(es)'` en `XCUIApplication.launchArguments` o mecanismo equivalente), afirma ambos textos resueltos, identifier y ausencia de «Añadir». Un build aislado no demuestra localización.
- `xcrun simctl install <UDID> DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app` y `xcrun simctl launch <UDID> org.plantcareai.prototype`; observar/capturar fondo, color y textos en español frente al bootstrap, sin acción «Añadir»; comprobar tamaño de texto grande y modo oscuro al menos manualmente para detectar regresiones de legibilidad. Si idioma de dispositivo no es español, fijar español o comprobar fallback explícitamente.
- No existe comando E2E externo; el UI test persistente ejecutado por `./init.sh` cubre la única conducta visible de esta funcionalidad, más inspección visual de colores que el test no mide.
- `git diff --check` y revisar que no se añaden fotos/secretos ni UI de `empty-collection`.

## Evidence To Capture

- En `PROGRESS.md` y `feature_list.json`: fecha, comandos ejecutados, simulador/idioma, build + UI test y resultado, revisión visual/captura bajo `DerivedData/`, conteo de colorsets (8) e imagesets (0), presencia de claves españolas y recursos en bundle; anotar límites si no se pudo comprobar alguna variante.

## Validator Checklist

- [ ] Ocho colores semánticos igualan los hex de `DESIGN.md`; `ContentView` obtiene sus tres colores de Assets, no RGB inline; catalogación conectada al target.
- [ ] Los dos textos existentes se resuelven en español desde `Localizable.xcstrings`; no se ven claves de localización ni cambió el mensaje.
- [ ] Sin imágenes de adorno, nueva pantalla, «Añadir», navegación ni persistencia.
- [ ] `./init.sh` pasa build y UI tests, y la apertura visual en simulador confirma pantalla/contraste; evidencia verificable registrada.
- [ ] `ARCHITECTURE.md`, `PROGRESS.md` y `feature_list.json` reflejan cambios y estado real; no se marca `accepted` sin veredicto independiente.
