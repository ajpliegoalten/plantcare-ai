# Instrucciones para agentes: PlantCare AI

Prototipo iOS personal para identificar plantas, guardar cuidados e historial local y consultar una IA con el contexto de cada ejemplar.

## Leer antes de trabajar

- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md` y `docs/risks-and-open-questions.md` definen lenguaje, alcance y límites.
- `DESIGN.md` guía la interfaz, especialmente «Mis plantas»; no sustituye el brief funcional.
- `ARCHITECTURE.md` fija Clean Architecture + MVVM por funcionalidad y la dirección obligatoria de dependencias. Consultarlo antes de planificar, implementar y validar; anotar en la spec dónde vivirán Presentation, Domain, Data y la composición.
- Para trabajo Swift/SwiftUI, activar la skill de proyecto `ios-clean-mvvm` (`.agents/skills/ios-clean-mvvm/SKILL.md`) en planificación, implementación o revisión; es una guía de proceso, no sustituye `ARCHITECTURE.md` ni las skills de rol.
- `PROGRESS.md` indica el estado verificado; `feature_list.json` contiene las funcionalidades y dependencias.

## Arranque y verificación

1. Confirmar la raíz del repositorio con `pwd` y consultar `PROGRESS.md`.
2. Elegir la primera funcionalidad no completada cuyas dependencias estén completadas, según el orden de `feature_list.json`.
3. Antes de compilar/probar, si no existe `Config/IdentificationSecrets.xcconfig`, copiar `Config/IdentificationSecrets.xcconfig.example` (clave vacía suficiente para tests); nunca sobrescribir un fichero real existente ni versionarlo. Debug exige ese fichero; Release no lo usa. `./init.sh` sigue siendo el gate completo: exige Xcode, selecciona un iPhone Simulator disponible y ejecuta `xcodebuild build` y `test` (pruebas unitarias y UI funcionales). Su ejecución corresponde al validator según la política siguiente, no al arranque automático de cada rol. No comprueba visualmente la pantalla fuera de la prueba UI.
4. Para apertura visual, abrir `PlantCareAI.xcodeproj` o instalar `DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app` con `xcrun simctl install <UDID> ...` y lanzar `xcrun simctl launch <UDID> org.plantcareai.prototype`. Si falla la línea base, corregirla antes de ampliar la funcionalidad.

## Reglas de trabajo

### Política habitual de verificación

- **Implementer — verificación por impacto:** analizar el diff y las dependencias/callers afectados; registrar archivos/cambios → riesgos → tests seleccionados y comandos. Ejecutar unitarias, integración y UI focalizadas pertinentes, más regresiones directamente relacionadas y comprobaciones estáticas de archivos modificados. Compilar cuando sea necesario, sin lanzar toda la suite por defecto. Cambios transversales (persistencia, composición, navegación, recursos compartidos) pueden justificar ampliar la selección, explicando por qué.
- **Línea base:** reutilizar evidencia válida del mismo estado de fuentes/configuración relevante y destino; no ejecutar un gate completo antes y otro después de implementar por rutina. Si falta evidencia o hay un fallo previo, diagnosticar con build/pruebas focalizadas y reparar antes de ampliar comportamiento. No atribuir un resultado antiguo a fuentes nuevas.
- **Validator — gate final:** ejecutar `./init.sh` una vez sobre la versión final de cambios de producto/tests/harness ejecutable. No volver a ejecutar por separado tests focalizados ya cubiertos por ese gate salvo laguna concreta o diagnóstico de un fallo. Si ya existe un gate completo válido de esas mismas fuentes y entorno, contrastar y reutilizar sus resultados, sin duplicarlo por cambiar de rol. Para cambios solo documentales/instrucciones, revisar coherencia y diff; no lanzar tests iOS sin impacto ejecutable.
- **Reparaciones:** tras un fallo, repetir primero solo el escenario fallido y las pruebas afectadas por la reparación. Repetir el gate completo únicamente si la reparación/cambio de fuentes, tests, recursos o configuración relevante invalida su evidencia; documentar la razón. Un gate fallido nunca cuenta como aprobado. No usar repeticiones, retries o modos de iteraciones múltiples para convertir un fallo en verde; una repetición diagnóstica necesita hipótesis explícita y conserva el fallo anterior.
- **Evidencia y handoff:** registrar comando, selección/motivo, resultado, estado de fuentes y entorno; distinguir pruebas nuevas de reutilizadas y lo pendiente del validator. `passing` significa autoverificación focalizada superada y lista para validación, no suite completa aprobada. `accepted` exige gate completo válido (cuando aplica) y aceptación independiente. No duplicar ejecuciones dentro de una misma sesión ni al cambiar de rol.
- Usar un único iPhone Simulator estándar con tamaño de texto normal y una sola apariencia, sin matrices adicionales. Mantener `./init.sh`, todas las pruebas unitarias y UI funcionales, los escenarios concretos de la feature y la inspección visual básica de las pantallas afectadas.
- iPhone SE/pantallas pequeñas, Dynamic Type aumentado o máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia quedan fuera de la verificación habitual. Ejecutarlas **solo si el usuario las solicita expresamente**, nunca como requisito automático de aceptación ni por estar disponibles.
- Conservar soporte de accesibilidad en código, etiquetas, controles y diseño adaptable. No eliminar tests funcionales ni debilitar aserciones para ocultar fallos. Los textos largos y el desplazamiento funcional siguen comprobándose en el simulador estándar, sin cambiar su tamaño de texto.
- Registrar únicamente comprobaciones realmente ejecutadas. Las ampliadas no solicitadas son «fuera de la verificación habitual; no ejecutadas», no aprobadas ni bloqueos pendientes por defecto. Conservar las evidencias históricas sin reinterpretarlas.
- Esta política rige planificación, implementación y validación, y prevalece sobre obligaciones antiguas de gate completo por rol o verificación ampliada en specs/guías. No reescribir specs aprobadas ni evidencias históricas para aplicarla. Antes de probar, coordinar con la sesión activa del worktree: reutilizar ejecuciones válidas y no lanzar procesos duplicados ni pruebas simultáneas sobre el mismo simulador.

- Implementar una funcionalidad por sesión; implementer verifica por impacto y validator se responsabiliza de la comprobación estándar final.
- Mantener vistas y ViewModels en Presentation, contratos/modelos/casos de uso en Domain y adaptadores concretos en Data; conectar dependencias desde la entrada de la app. No ubicar pantallas de features en `ContentView` ni crear adaptadores que aparenten persistencia real cuando aún no existe.
- No marcar `passing` sin pruebas ejecutadas y evidencia en `feature_list.json` o `PROGRESS.md`.
- Mantener la clave de la API fuera del repositorio; no enviar fotos ni datos a la IA antes del aviso al usuario. No confundir propuestas de IA con hechos confirmados.
- Mantener persistencia e historial por ejemplar; no añadir cuentas, backend, sincronización, alertas ni chat persistente.
- Al terminar, registrar pruebas, cambios, riesgos y siguiente paso en `PROGRESS.md` y actualizar `feature_list.json`; ajustar la documentación de dominio si cambia el comportamiento.
