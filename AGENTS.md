# Instrucciones para agentes: PlantCare AI

Prototipo iOS personal para identificar plantas, guardar cuidados e historial local y consultar una IA con el contexto de cada ejemplar.

## Leer antes de trabajar

- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md` y `docs/risks-and-open-questions.md` definen lenguaje, alcance y límites.
- `DESIGN.md` guía la interfaz, especialmente «Mis plantas»; no sustituye el brief funcional.
- `PROGRESS.md` indica el estado verificado; `feature_list.json` contiene las funcionalidades y dependencias.

## Arranque y verificación

1. Confirmar la raíz del repositorio con `pwd` y consultar `PROGRESS.md`.
2. Elegir la primera funcionalidad no completada cuyas dependencias estén completadas, según el orden de `feature_list.json`.
3. Ejecutar `./init.sh`: exige Xcode, selecciona un iPhone Simulator disponible y ejecuta `xcodebuild build` y `test` (UI test de arranque). No comprueba visualmente la pantalla fuera de la prueba UI.
4. Para apertura visual, abrir `PlantCareAI.xcodeproj` o instalar `DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app` con `xcrun simctl install <UDID> ...` y lanzar `xcrun simctl launch <UDID> org.plantcareai.prototype`. Si falla la línea base, corregirla antes de ampliar la funcionalidad.

## Reglas de trabajo

- Implementar una funcionalidad por sesión y verificar su escenario concreto además de la comprobación estándar.
- No marcar `passing` sin pruebas ejecutadas y evidencia en `feature_list.json` o `PROGRESS.md`.
- Mantener la clave de la API fuera del repositorio; no enviar fotos ni datos a la IA antes del aviso al usuario. No confundir propuestas de IA con hechos confirmados.
- Mantener persistencia e historial por ejemplar; no añadir cuentas, backend, sincronización, alertas ni chat persistente.
- Al terminar, registrar pruebas, cambios, riesgos y siguiente paso en `PROGRESS.md` y actualizar `feature_list.json`; ajustar la documentación de dominio si cambia el comportamiento.
