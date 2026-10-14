# Feature Implementation Spec: icono y LaunchScreen

## Source Feature

- `id`: `app-launch-branding`; `area`: `diseno-ios`.
- Dependencias: `ios-bootstrap`, `design-resources`, ambas `accepted`.
- Fuente: `feature_list.json`; estado de planificación: `not_started`.
- Rama: `feature/app-launch-branding`, base `3033dbc`.
- **Borrador pendiente de aprobación de recurso y propuesta visual. No implementar todavía.**

## Goal / Job Story

Como usuario, quiero reconocer PlantCare AI por su icono y su arranque
botánico, para percibir una identidad coherente antes de entrar en Mis plantas.
Implementar icono instalado y LaunchScreen del sistema, no una pantalla web
ni una pantalla SwiftUI retenida por un temporizador.

## Non-Goals / Users And Permissions

- Sin nueva feature funcional, onboarding, navegación, permisos ni envíos IA.
- Sin carga/sincronización simulada, progreso ficticio, demoras o animaciones.
- Sin copiar barras de estado, hora 9:41 ni indicador de inicio del HTML.
- Sin fuentes descargadas, dependencias nuevas, cuentas o persistencia adicional.
- La marca no es una foto de un ejemplar; no pertenece al dominio Plant.

## Decisión pendiente

- `/Users/antonio.pliego/Downloads/DESIGN.md` es guía, no archivo de icono.
- El enlace `img` del HTML sí permite descargar el brote sobre fondo verde.
- Descarga inspeccionada: JPEG opaco, 512×512, cuadrado, sin texto.
- Propuesta: usar esa imagen tanto para icono como para la marca central.
- Confirmar si se acepta ampliarla a PNG 1024×1024 para AppIcon, sin inventar
  detalle, o si el usuario aportará un original de mayor resolución.
- Aprobación debe recogerse antes de incorporar recursos de producto.
- No reemplazar el DESIGN.md del repo por el de Downloads.

## Acceptance Scenarios

### 1. Icono instalado
Given recurso aprobado y app instalada, When se abre la pantalla de inicio
de iOS, Then aparece el brote verde, no un icono vacío ni placeholder.
El original es cuadrado/opaco; iOS aplica su máscara, sin esquinas transparentes.

### 2. Arranque frío
Given app terminada, When iOS muestra su LaunchScreen, Then se ve fondo
crema `#F8FAF2`, marca central, PlantCare + cápsula AI y subtítulo exacto
«Inteligencia botánica en tu bolsillo para un cuidado consciente.».
El sistema controla su duración; no se exige un mínimo visible.

### 3. Transición real
Given arranque frío con almacén vacío o datos aislados existentes, When
la app está lista, Then entra en Mis plantas y conserva sus acciones/datos.
No hay taps extra ni nuevo flujo de carga, HTTP o consentimiento automático.

### 4. Recursos autocontenidos
Given Debug o Release sin acceso a internet, When se arranca, Then icono
y lanzamiento se resuelven desde el bundle, nunca desde la URL de Stitch.

## Repository Research

- Consultados AGENTS.md, PROGRESS.md, feature_list.json, ARCHITECTURE.md,
  CONTEXT.md, brief, dominio, riesgos y DESIGN.md.
- `PlantCareAI.xcodeproj/project.pbxproj`: LaunchScreen generado en ambos
  modos; sin configuración AppIcon encontrada. Registra recursos explícitamente.
- `PlantCareAI/Assets.xcassets`: colores semánticos existentes; sin AppIcon.
- `Config/IdentificationDebugInfo.plist`: puente de configuración Debug;
  conservar su contenido, sin leer/copiar config privada.
- `docs/testing-ui.md` y selectores actuales de `PlantCareAIUITests.swift`:
  XCTest existente para colección/fallback; no prueba visual del LaunchScreen.
- No existe storyboard LaunchScreen en el árbol inspeccionado.

## Technical Approach / Layers

- Presentation de arranque: `PlantCareAI/Resources/LaunchScreen.storyboard`,
  con UIImageView/UILabels y Auto Layout, sin custom classes ni código ejecutable.
- Reutilizar colores del catálogo. Icono central aproximadamente 144 pt,
  título de sistema bold 32 pt, subtítulo 15 pt, ancho aproximado 270 pt.
- Esquinas/sombra y halos del HTML se pueden preparar como recurso raster
  local separado del AppIcon si UIKit de launch no reproduce el efecto.
- Fondo adaptable a pantalla completa, grupo centrado en safe area;
  icono→título separación aproximada32pt; título→subtítulo4–8pt.
- Tipografía de sistema, según DESIGN.md vigente; no importar Jakarta.
- AppIcon: catálogo universal iOS 1024×1024, opaco, sin máscara precortada.
- Configurar `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` y
  `INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen` en Debug/Release;
  retirar generación automática de launch y comprobar plist compilado.
- Domain y Data: no aplican, sin modelos/repositorios/casos de uso artificiales.
- Composición SwiftUI y ContentView: sin cambios; el sistema carga storyboard
  antes de ejecutar la entrada de app. No hay ViewModel de splash.

## Expected File Changes / Visual Design Impact

- `PlantCareAI/Assets.xcassets/AppIcon.appiconset/*`: recurso aprobado y JSON.
- `PlantCareAI/Assets.xcassets/LaunchBrand.imageset/*`: marca con acabado local.
- `PlantCareAI/Resources/LaunchScreen.storyboard`: presentación estática.
- `PlantCareAI.xcodeproj/project.pbxproj`: recurso y configuración ambos modos.
- `DESIGN.md`: delta acotado de marca/launch aprobados; excepción explícita
  a la ausencia histórica de fuente de logotipo aprobada, sin borrar historia.
- `docs/testing-ui.md`: cómo inspeccionar lanzamiento e icono realmente.
- `PROGRESS.md`, `feature_list.json`, handoff: estado y evidencia real.
- No rasterizar toda la pantalla con una relación fija ni alterar Mis plantas.

## Durable Documentation Impact

- ARCHITECTURE.md: nota breve del recurso estático del sistema, sin capas nuevas.
- CONSTRAINTS.md y AGENTS.md: no necesario; política y producto no cambian.
- Brief/dominio: no necesario; ninguna regla de ejemplares se altera.
- DESIGN.md: actualizar solo tras aprobar la fuente/visual del arranque.

## Implementation Plan / Tasks

1. Obtener aprobación del recurso y propuesta; guardar procedencia en handoff.
2. Preparar AppIcon y marca local, sin dependencia de URL en ejecución.
3. Crear storyboard y registrar recurso/configuración Debug/Release.
4. Verificar build, bundles, icono y lanzamiento; después regresiones focales.
5. Registrar fuentes/comandos/resultados y entregar `passing` al validator.

## Verification Plan

- Solo documentación en esta ronda: JSON y `git diff --check`, sin tests iOS.
- Implementer: coordinar primero simulador/sesiones, usar un único iPhone
  estándar, texto normal/una apariencia; config example vacía solo si falta.
- Assets/storyboard/PBX → riesgo empaquetado → build Debug y Release,
  `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, inspección Info.plist
  compilado y recursos reales; JSON y dimensiones/alfa del PNG.
- Comando previsto: `xcodebuild -project PlantCareAI.xcodeproj -scheme
  PlantCareAI -destination "platform=iOS Simulator,id=$UDID"
  -derivedDataPath "$PWD/DerivedData" build-for-testing` (en una sola línea).
- E2E focal: `xcodebuild` con el mismo proyecto/scheme/destino y
  `-only-testing:PlantCareAIUITests/CollectionLayoutUITests/testEmptyCollectionCenteredBelowFixedHeaderAndAddWorks`
  `-only-testing:PlantCareAIUITests/LocalizationUITests/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys`
  `-only-testing:PlantCareAIUITests/StoredCollectionUITests test`.
- Inspección: instalar bundle en simulador estándar y observar icono en
  SpringBoard; grabar arranque frío e inspeccionar frames del launch real.
  XCTest observa la app lista, no afirmar que captura el LaunchScreen.
- Si el launch es demasiado fugaz, inspeccionar storyboard como evidencia
  adicional diferenciada; no ralentizar producto para capturarlo ni declarar
  una preview como captura real del sistema. Documentar límites/caché de iOS.
- Sin unitarias de negocio nuevas: no lógica de dominio afectada.
- Reutilizar evidencia válida de mismos inputs, preservar fallos; reparar y
  repetir solo checks afectados antes del gate, sin retries para conseguir verde.
- Validator independiente: un único `./init.sh` final, ambas fases, más revisión
  de recursos/visual no cubiertos por gate. No duplicar focales ya cubiertas.
- init.sh permanece intacto: ejecuta gate y no inicia procesos permanentes.

## Evidence To Capture / Validator Checklist

- [ ] Fuente aprobada, dimensiones originales/finales y limitación de ampliación.
- [ ] Debug/Release con AppIcon y storyboard correctos, sin URL runtime.
- [ ] Icono instalado y frames reales o límites explícitos de observación.
- [ ] Llegada a colección vacía/guardada y acciones existentes sin cambios.
- [ ] Comandos, exit, xcresult, inputs y entorno; distinguir nuevo/reutilizado.
- [ ] passing solo con autoverificación; accepted solo tras aceptación independiente.
- [ ] Sin API real, secretos, nuevas capas, temporizadores ni features adyacentes.
