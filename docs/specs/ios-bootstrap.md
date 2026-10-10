# Feature Implementation Spec: Abrir y compilar la app iOS vacía

## Source Feature

> Política de verificación vigente: `AGENTS.md`. Un único iPhone Simulator estándar con texto normal y una apariencia, `./init.sh`, pruebas unitarias/UI funcionales e inspección visual básica. SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia solo si el usuario lo solicita expresamente. Se conserva soporte de accesibilidad y todas las aserciones funcionales; no declarar superadas comprobaciones no ejecutadas. Este ajuste sustituye únicamente obligaciones de verificación ampliada, no alcance ni evidencias históricas.

- `id`: `ios-bootstrap`
- `area`: `base-ios`
- `title`: Abrir y compilar la app iOS vacía
- `user_visible_behavior`: La app iPhone abre en simulador con una pantalla inicial nativa; existe una comprobación repetible de compilación.
- `depends_on`: `[]`
- `status` al planificar: `not_started`
- `verification` de origen: crear proyecto iOS, compilar y arrancar en simulador; actualizar `./init.sh` con comandos reales y destino disponible.
- Fuente: `feature_list.json` (2026-10-09).

## Goal

Crear una aplicación iPhone SwiftUI mínima que se abra en un simulador disponible y deje reproducible la compilación y pruebas básicas desde `./init.sh`. Este es el soporte para las siguientes funcionalidades, no una implementación anticipada del recorrido de plantas.

## Non-Goals

- No implementar la colección vacía «Mis plantas» con su acción «Añadir» (`empty-collection`), tarjetas, persistencia, fotos, IA ni navegación adicional.
- No instalar bibliotecas, configurar credenciales, permisos de cámara, backend, cuenta o sincronización.
- No dar por verificada la app por el mero hecho de generar un proyecto o pasar `bash -n`.

## Job Story

Cuando inicio el prototipo en un iPhone simulado, quiero ver una pantalla nativa estable para comprobar que el proyecto se puede compilar, probar y abrir antes de añadir funcionalidades.

## Users And Permissions

- Usuario local único: puede iniciar la app y ver una pantalla inicial neutra; no se piden permisos ni se transmite información.
- Agente/desarrollador: puede reproducir la compilación y prueba en una máquina con Xcode y un simulador iPhone instalado.

## Acceptance Scenarios

### Scenario 1: primera apertura

Given un simulador iPhone disponible y la app instalada sin datos previos
When se ejecuta la app desde Xcode o `simctl launch`
Then abre sin cierre inesperado y presenta una única pantalla SwiftUI inicial legible, sin controles de alta ni datos ficticios.

### Scenario 2: gate estándar reproducible

Given Xcode CLI configurado y al menos un destino iPhone Simulator disponible
When se ejecuta `./init.sh` desde cualquier directorio
Then termina con código cero únicamente tras ejecutar `xcodebuild` para compilación y pruebas en un destino real; no afirma que el lanzamiento visual se haya verificado por el script si no lo comprueba.

### Scenario 3: prerequisito ausente

Given no hay Xcode configurado o no existe simulador iPhone disponible
When se ejecuta `./init.sh`
Then falla con código distinto de cero y un mensaje accionable (instalar/configurar Xcode o runtime/simulador); no imprime un falso «OK» de pruebas ni inicia servidores/procesos duraderos.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json` — flujo de trabajo, estado y alcance de la primera funcionalidad.
- `init.sh` — provisional: hace `cd` a raíz y solo anuncia pre-bootstrap; no compila ni prueba.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md` — límites funcionales, lenguaje y decisiones pendientes.
- `DESIGN.md` — SwiftUI iPhone nativo, tipografía de sistema, paleta/contraste y accesibilidad.
- `.agents/skills/feature-spec/references/spec-template.md` — estructura del contrato.
- Listado de raíz y búsquedas de `*.swift`, `*.xcodeproj`, `*.xcworkspace`, `*.pbxproj`, `*test*`, `docs/adr/*.md` — no se encontraron fuentes iOS, tests ni ADR.

### Existing Patterns To Follow

- `./init.sh` debe ejecutarse desde cualquier ubicación: ya cambia al directorio del repositorio; conservar `set -euo pipefail`.
- `PROGRESS.md` distingue explícitamente el aviso pre-bootstrap de verificación real y exige evidencia de pruebas.
- `DESIGN.md` es referencia visual, no código HTML reutilizable.

### Current Gaps / Decisions

- No hay proyecto, scheme, tests, verificación persistente E2E ni destino de simulador registrado.
- Elegir despliegue mínimo iOS 17 para el proyecto inicial (alineado con SwiftUI moderno; SwiftData no se introduce aún); documentar la versión efectiva si Xcode instalado exige otra. No bloquear este bootstrap por decisiones futuras de persistencia/API.
- No se comprobó desde esta sesión la instalación de Xcode, `xcodebuild` ni los dispositivos disponibles: el implementador debe inspeccionarlos antes de fijar comandos/destino. Si faltan herramientas, el arranque visual y gate no pueden darse por validados.

## Technical Approach

Crear un proyecto Xcode iOS App (Swift, SwiftUI, iPhone, sin paquetes externos) con un identificador de bundle local apropiado y un scheme compartido, por ejemplo `PlantCareAI.xcodeproj`, target/scheme `PlantCareAI`. Pantalla raíz estática con nombre de app y mensaje de preparación, usando colores y texto accesibles de `DESIGN.md`; no titularla «Mis plantas» como si ya existiera el estado vacío.

Añadir un target de pruebas XCTest mínimo que ejecute una prueba determinista de arranque/estado de la raíz (UI test de lanzamiento si el simulador lo permite), no una prueba vacía. El script `init.sh` selecciona un destino **disponible** de iPhone Simulator mediante `xcrun simctl list devices available` (o mecanismo fiable equivalente), registra el destino elegido, ejecuta `xcodebuild -project ... -scheme ... -destination 'platform=iOS Simulator,id=<UDID>' build` y `... test`, propaga fallos, sin arrancar procesos de larga duración. No elegir a ciegas un modelo/OS codificado. El script puede imprimir, tras superar el gate, cómo abrir el proyecto y lanzar manualmente la app; el escenario de arranque visual debe comprobarse aparte (o automatizarse con UI test real). Preferir un destino de pruebas efímero/no sobrescribir datos de un simulador ajeno si la configuración lo permite.

## Expected File Changes

- `PlantCareAI.xcodeproj/project.pbxproj` y configuración compartida bajo `PlantCareAI.xcodeproj/xcshareddata/xcschemes/` — crear proyecto y scheme ejecutable/testable; nombres propuestos, adaptables solo si se actualizan todos los comandos.
- `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/ContentView.swift` y recursos iOS necesarios (`Assets.xcassets`, `Info.plist` si procede) — crear app y pantalla inicial; ubicaciones propuestas al no existir app.
- `PlantCareAIUITests/PlantCareAIUITests.swift` (o target XCTest equivalente) — crear prueba de lanzamiento no trivial y asociarla al scheme.
- `init.sh` — sustituir anuncio provisional por comprobación no bloqueante y diagnóstico de prerequisitos.
- `PROGRESS.md`, `feature_list.json` — registrar ejecución/resultado y estado únicamente con evidencia real; no marcar `passing` por planificación.
- `.gitignore` — crear para excluir `DerivedData`, `*.xcuserstate`, archivos locales/secrets y artefactos de build sin ignorar proyecto/scheme compartido.

## Visual Design Impact

- UI involucrada: sí; pantalla inicial neutra exclusivamente.
- Fuente: `DESIGN.md`; base crema, verde sobrio, tipografía del sistema, márgenes generosos; respetar Dynamic Type, VoiceOver y contraste.
- Estados afectados: primer lanzamiento, sin contenido de producto; texto visible y accesible que no prometa acciones aún inexistentes.
- Nuevo artefacto de diseño: no; referencia escrita suficiente para esta pantalla mínima.

## Durable Documentation Impact

- `ARCHITECTURE.md`: crear — registrar proyecto/targets, punto de entrada SwiftUI y límites de esta base, sin inventar arquitectura de almacenamiento/IA.
- `CONSTRAINTS.md`: crear — registrar restricciones duraderas de iPhone/iOS mínimo elegido, configuración local y ausencia de secretos versionados; evitar duplicar el brief.
- `AGENTS.md`: actualizar — sustituir descripción de arranque provisional por comandos verificados si cambia el flujo, conservando la exigencia de pruebas y evidencia.
- `PROGRESS.md` y `feature_list.json`: actualizar al completar implementación, con comandos, destino y resultados concretos.
- `docs/domain-model.md`, `CONTEXT.md`, `DESIGN.md`: no necesario — no se modifica el dominio ni la dirección visual.
- `docs/risks-and-open-questions.md`: actualizar solo si se resuelve formalmente la versión mínima de iOS; mantener abiertas persistencia y API.

## Implementation Plan

1. Inspeccionar `xcodebuild -version`, runtimes y simuladores disponibles; elegir configuración de proyecto viable y versión de iOS documentada.
2. Generar proyecto iPhone SwiftUI, scheme compartido y pantalla raíz mínima; añadir prueba de lanzamiento que verifique texto/estado real.
3. Actualizar `init.sh` para ejecutar build y test en destino disponible y fallar claramente si falta algún requisito; asegurar que se puede invocar fuera de raíz.
4. Ejecutar gate y arranque visual real; registrar evidencia y actualizar documentación/estado sin adelantar `empty-collection`.

## Implementation Tasks

- [ ] Crear proyecto iOS y configurar target de app para iPhone con deployment target acordado y scheme compartido.
- [ ] Añadir pantalla inicial SwiftUI estática y accesible sin controles de funcionalidades posteriores.
- [ ] Incorporar test XCTest/UI que compruebe lanzamiento y un elemento identificable de la pantalla.
- [ ] Implementar selección de simulador y `xcodebuild build` + `xcodebuild test` en `init.sh`, incluyendo errores de prerequisitos.
- [ ] Ignorar artefactos locales; revisar que no hay credenciales ni archivos de usuario en el proyecto.
- [ ] Completar documentación duradera y evidencia de compilación, prueba y apertura real.

## Verification Plan

- Antes de ejecutar: `xcodebuild -version`, `xcrun simctl list devices available`; anotar versión, modelo, runtime y UDID usados.
- `bash -n init.sh && ./init.sh` desde raíz y `cd <otro-directorio> && <ruta-absoluta-del-repo>/init.sh`; ambos deben ejecutar build + tests con salida y estado de éxito; no basta un aviso.
- Para diagnosticar individualmente: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID-disponible>' build` y el mismo comando con `test` (ajustar nombres si varían).
- Abrir/lanzar en simulador iPhone por Xcode, o instalar producto compilado vía `xcrun simctl install <UDID> <ruta-app>` y arrancar vía `xcrun simctl launch <UDID> <bundle-id>`; comprobar pantalla legible, sin crasheos ni acciones ficticias y capturar evidencia visual.
- Simular ausencia de prerequisito (por entorno controlado o inspección del manejo de errores) para confirmar fallo explícito; no desconfigurar Xcode del anfitrión innecesariamente.
- No existe comando E2E persistente hoy. El UI test de arranque incluido en el scheme cubre esta única conducta visible; no se necesita un harness externo adicional para un shell sin flujos de negocio.

## Evidence To Capture

- En `PROGRESS.md`/`feature_list.json`: fecha, Xcode y iOS runtime/destino, comandos exactos, resultado de build, nombre/resultado del test, resultado de lanzamiento visual y, si se captura, ruta de screenshot sin datos personales.
- Anotar explícitamente fallos/limitaciones de entorno; `passing` solo si compilación, tests y apertura se han ejecutado y verificado.

## Validator Checklist

- [ ] Proyecto iPhone abre, pantalla inicial coincide con escenario 1 y no incluye funcionalidades futuras.
- [ ] `./init.sh` realmente ejecuta build y test en simulador disponible sin procesos de larga duración; errores se propagan.
- [ ] Existe test de lanzamiento significativo y scheme compartido reproducible.
- [ ] Escenarios 1–3 verificados, o limitación de prerequisito reportada sin falsa aceptación.
- [ ] Evidence y estados de `feature_list.json` / `PROGRESS.md` coinciden con los comandos ejecutados.
- [ ] Documentación duradera actualizada; ningún secreto, cuenta, backend ni persistencia prematura.
