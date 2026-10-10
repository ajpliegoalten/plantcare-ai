# Feature Implementation Spec: Mostrar Mis plantas vacía

> Especificación histórica de la primera implementación. El refactor de arquitectura aprobado posteriormente conserva sus escenarios funcionales y se documenta en `ARCHITECTURE.md` y `PROGRESS.md`; el cambio de archivos esperados de esta spec no reescribe los criterios originales.

## Source Feature

> Política de verificación vigente: `AGENTS.md`. Un único iPhone Simulator estándar con texto normal y una apariencia, `./init.sh`, pruebas unitarias/UI funcionales e inspección visual básica. SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia solo si el usuario lo solicita expresamente. Se conserva soporte de accesibilidad y todas las aserciones funcionales; no declarar superadas comprobaciones no ejecutadas. Este ajuste sustituye únicamente obligaciones de verificación ampliada, no alcance ni evidencias históricas.

- `id`: `empty-collection`; `area`: `coleccion`; `title`: Mostrar Mis plantas vacía.
- `user_visible_behavior`: Al abrir sin ejemplares se ve «Mis plantas» con un estado vacío y acción Añadir.
- `depends_on`: [`design-resources`] (`accepted`); `status` al planificar: `not_started`.
- `verification` de origen: abrir instalación sin datos en simulador; comprobar encabezado, estado vacío y acción accesible, más gate estándar.
- Fuente: `feature_list.json`, 2026-10-09; feature lista y correctamente acotada.

## Goal

Reemplazar el texto de bootstrap por la pantalla inicial nativa «Mis plantas» para una colección aún vacía. Mostrar una única composición amable, legible y adaptativa, con entrada «Añadir» en cabecera y CTA «Añadir mi primera planta». La futura elección de foto se implementa únicamente en `choose-identification-photo`.

## Non-Goals

- No crear modelos de planta, datos de ejemplo, almacenamiento, tarjetas de plantas, detalle o alta de ejemplares; `local-plant-storage` y `plant-cards` son trabajos separados.
- No abrir cámara/galería, pedir permisos, crear un borrador de identificación ni enviar información a servicios externos; `choose-identification-photo` implementará el flujo real.
- No simular una planta añadida, presentar confirmaciones de éxito, toasts decorativos o una pantalla «Actividad». No copiar HTML/CSS, imágenes web, Material Symbols, avatar, logo o barra de estado de Stitch.
- No introducir un destino de navegación vacío que finja ofrecer selección de foto, ni una acción habilitada que no haga nada. Ver decisión de transición en «Technical Approach».

## Job Story

Cuando abro por primera vez la app y todavía no he guardado plantas, quiero reconocer enseguida mi colección vacía y dónde iniciaré la incorporación de una planta, para comprender qué hacer cuando el flujo de foto esté disponible.

## Users And Permissions

- Una única persona en su iPhone local. Esta pantalla no solicita permisos, credenciales o acceso de red y no modifica datos.
- Los dos puntos de entrada de alta se identifican por nombre y se exponen de forma honesta si el flujo posterior aún no está implementado.

## Acceptance Scenarios

### Scenario 1: primera apertura sin datos

Given una instalación limpia, sin plantas guardadas
When se inicia la app en español
Then aparece el título grande «Mis plantas», el control «Añadir» junto al encabezado y una tarjeta blanca centrada con símbolo vegetal SF Symbols, título «Todavía no tienes plantas», explicación breve y CTA «Añadir mi primera planta»; no se ven textos de bootstrap, tarjetas ficticias ni pestaña «Actividad».

### Scenario 2: límites del alta incompleta

Given que aún no existe `choose-identification-photo`
When la persona explora los dos puntos de entrada de alta
Then se reconocen sus etiquetas y se comunica accesiblemente que el alta todavía no está disponible; ninguno simula un guardado, solicita permisos, presenta un flujo falso ni altera la colección. Al integrarse el flujo real, ambos se conectarán a la misma ruta.

### Scenario 3: adaptabilidad

Given un iPhone Simulator estándar con tamaño de texto normal
When se consulta la pantalla vacía
Then título, mensaje y controles siguen legibles y ordenados, no se cortan ni solapan; controles e información tienen nombres/hints comprensibles y área táctil de al menos 44 × 44 pt cuando estén activos. La superficie permanece legible en apariencia clara y oscura.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json` — estado y dependencia aceptada, límites y gate.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, `DESIGN.md` — lenguaje por ejemplar, alcance, dirección visual y Stitch como referencia sin archivos/capturas versionados.
- `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/ContentView.swift` — ventana única y pantalla de bootstrap SwiftUI sin navegación ni estado de colección.
- `PlantCareAI/Localizable.xcstrings`, `PlantCareAI/Assets.xcassets/`, `PlantCareAI.xcodeproj/project.pbxproj` — español como idioma fuente, ocho colores semánticos, registro explícito de fuentes en target.
- `PlantCareAIUITests/PlantCareAIUITests.swift`, `init.sh` — dos tests de bootstrap/fallback y build + test reproducibles en simulador.
- `ARCHITECTURE.md`, `CONSTRAINTS.md`, `docs/specs/design-resources.md`, `.agents/skills/feature-spec/references/spec-template.md` — arquitectura existente y precedente de especificación.

### Existing Patterns To Follow

- SwiftUI iPhone iOS 17+, `ContentView` raíz, `Color("Background")`, catálogo `.xcstrings` con claves semánticas y fallback español; SF Symbols nativos, sin imágenes de catálogo por anticipado.
- Test de interfaz XCTest incluido en scheme compartido; `./init.sh` selecciona destino iPhone disponible y ejecuta `xcodebuild build` y `test`, no verifica una captura visual.
- El proyecto usa referencias de archivo explícitas, no grupos sincronizados: cualquier nueva fuente requiere actualizar `project.pbxproj` y el target.

### Current Gaps / Unknowns

- No hay almacén, modelos, colección con datos ni flujo de identificación; la instalación limpia se considera vacía sin persistencia ficticia. La futura bifurcación vacío/tarjetas depende de `local-plant-storage` + `plant-cards`.
- Los dos HTML de Stitch revisados antes de planificar son referencias visuales idénticas según el usuario; no hay screenshots o ficheros HTML locales inspeccionables. `DESIGN.md` y el brief tienen autoridad funcional.
- La entrada «Añadir» es un affordance requerido antes de existir la ruta de foto. Decisión de transición: exponer ambos controles identificables pero **deshabilitados explícitamente** con explicación accesible de disponibilidad futura; no convertir el toque en una promesa vacía. Si se considera indispensable activarlos ya, se requiere adelantar/dependender del flujo `choose-identification-photo`, no inventar una acción.

## Technical Approach

Sustituir la composición de bootstrap dentro de `ContentView` por una pantalla única desplazable y de una columna, con fondo `Color("Background")` a los bordes. Arriba, título `Mis plantas` y control `Añadir` en un encabezado adaptable; a continuación, tarjeta `Color("Surface")` de esquinas suaves con símbolo `leaf`/`leaf.fill` o `leaf.arrow.circlepath` si se aprecia claramente como brote (preferir `leaf` a un asset inventado), título, texto de apoyo breve y CTA. El texto exacto propuesto del cuerpo: «Guarda aquí tus plantas para tener sus cuidados a mano.» No atribuir cuidado realizado o estado de salud. Mantener flexibilidad vertical y scroll para pantallas pequeñas/lectores grandes; centrar la tarjeta en el espacio disponible cuando quepa, sin depender de alturas fijas ni ocultar el título al crecer Dynamic Type.

Agregar claves españolas semánticas, por ejemplo `collection.title`, `collection.add`, `collection.empty.title`, `collection.empty.body`, `collection.empty.add`, `collection.add.unavailable`, y resolver *todos* los textos nuevos desde `Localizable.xcstrings`. El título y CTA deben tener identifiers estables para las UI tests (p. ej. `collectionTitle`, `emptyCollectionTitle`, `addPlantHeader`, `addFirstPlant`). Ambos puntos de entrada de alta comparten intención semántica y estilo diferenciable (cabecera secundario, CTA primario); mientras no haya flujo, `disabled(true)` y hint/explicación visible o accesible clara: «Disponible cuando puedas elegir una foto». Evitar habilitar un botón vacío o navegar a un placeholder engañoso. Al llegar `choose-identification-photo`, sustituir solo esta indisponibilidad por navegación real común y revisar el test correspondiente; no crear ahora un flujo parcial.

Usar tipografía escalable (`.largeTitle`/`.title`/`.body` o estilos métricos), no puntos rígidos; colores nombrados `Primary`, `PrimaryAction`, `TextPrimary`, `TextSecondary`, `Surface`; espaciamiento según `DESIGN.md`, no medidas HTML. Dar nombre y orden VoiceOver naturales, ocultar símbolo decorativo para evitar lectura redundante, y mantener contraste adecuado sobre crema y verde incluso en modo oscuro.

## Expected File Changes

- `PlantCareAI/ContentView.swift` — reemplazar bootstrap por colección vacía; si se extrae una vista pequeña, registrar su nuevo archivo en `PlantCareAI.xcodeproj/project.pbxproj`.
- `PlantCareAI/Localizable.xcstrings` — añadir únicamente cadenas usadas por el estado vacío y explicación de indisponibilidad; conservar claves de bootstrap existentes salvo limpieza verificada.
- `PlantCareAIUITests/PlantCareAIUITests.swift` — sustituir tests de contenido bootstrap por tests de estado vacío en español y fallback inglés; cubrir controles accesibles/deshabilitados, sin datos inventados.
- `ARCHITECTURE.md`, `PROGRESS.md`, `feature_list.json` — actualizar al implementar con raíz nueva y evidencia real, sin marcar `accepted` antes de revisión independiente.
- `init.sh`, assets, `PlantCareAIApp.swift`, `project.pbxproj` — no requieren cambio salvo extracción de archivo Swift justificada.

## Visual Design Impact

- UI involucrada: sí, pantalla raíz «Mis plantas» vacía. Fuente: `DESIGN.md`, `docs/build-brief.md` y descripción de la referencia Stitch revisada; no existe archivo/captura reutilizable.
- Crema `#F8FAF2`, título grande, botón de encabezado y tarjeta blanca de radio aproximado 22 pt, elevación muy suave opcional, SF Symbol vegetal, CTA sobrio verde `#3E6553`. Márgenes ~20 pt, padding de tarjeta ~16 pt; ajustar con Dynamic Type/espacio seguro. Sin pestaña «Actividad» ni footer inventado; footer nativo solo si aporta navegación real.
- Estado de verificación habitual: vacío en simulador estándar con texto normal y una apariencia. Texto aumentado/máximo, VoiceOver y apariencias adicionales solo por petición expresa; conservar su soporte. No diseñar todavía la tarjeta con fotografía 4:3 para una planta guardada.
- Nuevo artefacto de diseño: no; guía escrita suficiente, no generar imagen nueva ni recrear Stitch como web.

## Durable Documentation Impact

- `ARCHITECTURE.md`: actualizar — la raíz deja de ser bootstrap y pasa a estado vacío; documentar que no hay almacén ni navegación de foto todavía.
- `CONSTRAINTS.md`: no necesario — no aparecen nuevas reglas transversales MUST/MUST NOT; siguen las de iOS 17 y secretos.
- `AGENTS.md`: no necesario — startup y reglas de agentes no cambian.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `DESIGN.md`, `docs/risks-and-open-questions.md`: no necesario — la vista no altera dominio, brief ni diseño; actualizar solo si la implementación decide algo contradictorio, que debe escalarse antes.
- `PROGRESS.md` y `feature_list.json`: actualizar al implementar, registrar gate, inspección visual y siguiente dependencia; esta planificación no altera estados.

## Implementation Plan

1. Confirmar raíz/estado y gate de línea base; conservar recursos aceptados y fijar textos/hints españoles.
2. Cambiar la vista raíz a colección vacía adaptable y accesible, con dos puntos de entrada honestamente no operativos hasta el flujo de foto; sin estado ni persistencia ficticia.
3. Añadir claves locales y actualizar UI tests para nuevo contrato observable y fallback, eliminando expectativas de bootstrap.
4. Ejecutar gate y abrir una instalación limpia en el único simulador estándar con texto normal; inspección visual básica, registrar resultados y actualizar arquitectura/estado. Dynamic Type aumentado/máximo, VoiceOver y otras apariencias solo por petición expresa.

## Implementation Tasks

- [ ] Construir encabezado y tarjeta vacía de una columna con símbolo SF decorativo y textos específicos, usando tokens de `Assets`.
- [ ] Agregar textos nuevos en `Localizable.xcstrings`; verificar fallback al español sin claves crudas.
- [ ] Declarar dos puntos de entrada reconocibles con identifiers, indisponibilidad explícita y accesibilidad sin acciones que finjan el alta.
- [ ] Reemplazar tests obsoletos y agregar aserciones de estado vacío/control deshabilitado y fallback.
- [ ] Ejecutar pruebas, apertura visual y revisión accesible; actualizar `ARCHITECTURE.md`, `PROGRESS.md` y `feature_list.json` con evidencias.

## Verification Plan

- `python3 -m json.tool PlantCareAI/Localizable.xcstrings >/dev/null` y `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`; inspeccionar que todas las cadenas nuevas se resuelven por clave y no se añadieron assets de imagen ni permisos.
- `./init.sh` desde raíz: ejecuta build + UI tests no bloqueantes en iPhone Simulator disponible (no solo imprime instrucciones, no inicia servidores). Actualizar tests persistentes XCTest para `Mis plantas`, título/mensaje vacío, ambos botones por identifier y estado disabled/hint, ausencia de bootstrap/«Actividad»; segunda prueba de preferencia inglesa verifica fallback español. UI test es el E2E persistente del repo; no existe `pnpm test:e2e` ni se necesita otro harness.
- Para apertura sin datos usar simulador limpio o `xcrun simctl uninstall <UDID> org.plantcareai.prototype` (solo dispositivo de prueba) antes de `xcrun simctl install <UDID> DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app` y `xcrun simctl launch <UDID> org.plantcareai.prototype -AppleLanguages '(es)' -AppleLocale es_ES`; revisar visualmente la pantalla, sin aceptar sólo build/UI test como validación visual.
- Inspección visual básica con texto normal en el único simulador estándar y una apariencia, sin recortes ni contraste pobre. Texto aumentado/máximo, VoiceOver/Accessibility Inspector, pantallas pequeñas/SE y otras apariencias solo bajo petición expresa. `git diff --check`; revisar ausencia de navegación ficticia, datos de planta y secretos.

## Evidence To Capture

- En `PROGRESS.md`/`feature_list.json`: fecha, modelo/UDID/runtime, `./init.sh` build/test y nombres/resultados de UI tests, apertura real sin datos, captura local ignorada en `DerivedData/` si se obtiene e inspección visual básica. Comprobaciones ampliadas solo si solicitadas; fuera de la rutina no declararlas aprobadas ni pendientes obligatorios. No declarar `passing` sin pruebas ejecutadas ni `accepted` sin validador independiente.

## Validator Checklist

- [ ] Instalación limpia abre «Mis plantas» y estado vacío completo según escenarios, sin bootstrap ni datos falsos.
- [ ] Dos entradas de alta etiquetadas y accesibles; hasta la foto real no hay no-op habilitado, toast, permisos o flujo ficticio.
- [ ] Diseño nativo respeta tokens, una columna, scroll, tamaños grandes y 44 × 44 pt para controles activos; no hay «Actividad».
- [ ] Strings españoles/fallback, UI tests y `./init.sh` pasan; apertura visual y accesibilidad tienen evidencia independiente.
- [ ] `ARCHITECTURE.md`, `PROGRESS.md` y `feature_list.json` reflejan el estado realmente verificado; ningún cambio a persistencia, IA o fotos.
