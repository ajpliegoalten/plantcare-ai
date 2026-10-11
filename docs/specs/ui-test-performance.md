# ui-test-performance — Contrato de validación del refactor

## Ajuste posterior solicitado: reparación y 5 workers

Autorización posterior de entrega: el usuario confirma reparar H3, validar independientemente y después hacer commit, push y abrir PR de `feature/ui-test-performance` hacia `main` en este repositorio; no merge. Esta autorización levanta la restricción original de publicación para esta entrega exclusivamente. No requiere repetir el gate por registrar aceptación/publicación documental.

Tras el verdict revise, el usuario autoriza reparar H1 (vacío nativo/placeholder en typeManual) y H2 (entorno TestAction para capturas), pide **5 workers por defecto** y aclara que los informes detallados de tiempos/orden/duplicados eran puntuales. Esta delta prevalece sobre los dos workers y las entregas de mediciones de los puntos 3, 6, 7 y Durable Documentation Impact originales: conservar la referencia ya generada, sin repetir extractores/CSV/tablas. Mantener verificación funcional/cobertura y evidencia estándar. Reparación por impacto: 7 callers UI afectados y comprobación de entorno/capturas; gate completo final independiente pendiente, sin convertir el gate anterior fallido en aprobación. TestAction tiene default0 literal y entorno propio; `scripts/configure-ui-test-environment.py` aplica0/1 al xctestrun generado tras build-for-testing, utilizado explícitamente por ambas fases del gate. No confiar en expansión de macros custom desde build settings CLI. Helper nuevo sin dependencias fuera de Python stdlib ya requerido.

## Origen y alcance

Formalización del contrato ya solicitado por el usuario e implementado, no una nueva decisión de producto. Solicitud original: eliminar tests/pasos duplicados o sin utilidad, mejorar tiempos y definiciones y habilitar paralelismo sin ejecutar entonces. Solicitud posterior: usar validator para comprobar comportamiento/cobertura anterior y medir duraciones, orden y duplicados; esta petición autoriza ahora el gate. No se requiere autoverificación ficticia para cambiar `in_progress` a `passing`.

## Objetivo y no objetivos

Reducir trabajo redundante de UI preservando los contratos funcionales previos. No cambiar flujos de producto, arquitectura, persistencia real, consentimiento, límites, accesibilidad ni tests para ocultar fallos. No separar archivos, iniciar otra feature, enviar solicitudes reales a IA, acceder a secretos, hacer commits/publicación ni añadir matrices ampliadas. No garantizar un tiempo sin medirlo.

## Referencia anterior

Comparar el diff real con su base anterior y las condiciones aceptadas en `docs/validations/save-plant.md`: 125 unitarias y 35 métodos UI. Estos últimos incluían bucles con varios escenarios; los números por sí solos no prueban cobertura equivalente. Las specs originales y evidencias históricas son referencias conservadas, no se reescriben para justificar el refactor.

## Acceptance Scenarios

1. **Equivalencia funcional:** revisar cada método anterior, sus assertions y la cobertura sustituta de `docs/testing-ui.md`. Las tres eliminaciones y recortes tienen cobertura equivalente de vacío/acciones, selección de foto/no mutación, modelos/JPEG completos, detalle/navegación/edición, identidad IA/manual, invalidación, cuidados/retry/cancelación y alta/commit/relaunch. Registrar explícitamente cualquier gap; el mapa del implementer no basta como prueba independiente.
2. **Descubrimiento y éxito:** 125 unitarias sin cambios y 38 métodos UI actuales descubiertos/ejecutados sin fallos ni omisiones. La fase paralela debe cubrir 125 unitarias +37 UI; la fase serial, 1 UI de PhotosPicker. No presentar un gate parcial/fallido como aprobado.
3. **Paralelismo aislado:** scheme y gate habilitan dos workers por defecto, gestionados por XCTest en clones del mismo modelo/runtime estándar y misma apariencia/texto normal. Confirmar actividad concurrente real en los resultados si se expone; distinguir configuración de ejecución observada. UUID propios para almacenamiento/consentimiento, sin contaminación entre escenarios.
4. **Gate eficiente completo:** `./init.sh` compila una vez con `build-for-testing` y ejecuta dos fases `test-without-building`. Fotos se siembra en el destino conocido y su integración real se ejecuta serial fuera de los clones. Fallo de cualquiera de las fases produce exit no cero; sin retries/iteraciones múltiples.
5. **Helpers y fixtures:** primera assertion fallida detiene el escenario; gestos limitados sin quitar geometría; fixtures normales sin esperas artificiales y demoras explícitas conservadas donde se observa progreso/cancelación/commit. Limpieza agrupada solo de UUID en namespaces Debug Simulator, nunca datos reales. Reemplazo manual de texto mantiene valores exactos. Capturas de éxito opt-in no sustituyen diagnósticos de fallo ni cobertura funcional.
6. **Mediciones:** conservar timestamps/duraciones reales de gate/fases/tests y agrupar por archivo de fuente y clase. Registrar suma de duración y ventana wallclock como métricas distintas en paralelo. Entregar cronología por inicio con solapamientos y fase/worker/destino cuando estén disponibles; datos no expuestos se declaran no disponibles. El archivo UI sigue único, de modo que el desglose por clase UI complementa el de archivos unitarios.
7. **Duplicados:** contar invocaciones reales por identificador target/clase/método entre ambos bundles. No confundir resumen repetido, activities/assertions o runners con otra invocación. Informar recuentos y lista de duplicados si existen, sin ejecutar tests extra solo para medirlos.

## Archivos y arquitectura

- Tests: `PlantCareAIUITests/PlantCareAIUITests.swift`, base de helpers y 14 clases dentro del mismo archivo; unitarias en `PlantCareAITests/` conservadas.
- Harness/composición: `init.sh`, scheme compartido y seam de limpieza en `PlantCareAI/PlantCareAIApp.swift`.
- Presentation: únicamente seam Debug Simulator de selección demorada en `IdentificationPhotoView.swift`.
- Data: únicamente demora del fixture `IdentificationCandidatesTestFixture.swift`. Domain y adaptadores reales sin modificaciones; no hay nuevas dependencias entre capas.

## Verification Plan

Validator independiente revisa contrato/diff/cobertura/seguridad/docs y luego ejecuta **un** gate `./init.sh` (caffeinate si procede), sin gate baseline previo ni focalizadas redundantes. Reutilizar un gate únicamente si cubre exactamente fuentes/configuración/entorno actuales. Coordinar antes para no competir en simuladores. Usar sandbox público y plantilla vacía sin copiar/leer configuración privada cuando corresponda. Un fallo se conserva y produce repair brief; no se autoriza reparar ni repetir automáticamente por esta solicitud de validación. Inspección visual básica de pantallas afectadas según AGENTS, aprovechando evidencia disponible, sin matrices adicionales.

## Durable Documentation Impact

`docs/testing-ui.md` contiene definiciones y consolidaciones; guías de tests, AGENTS y ARCHITECTURE deben concordar con selectores y gate actuales. Persistir resultado independiente en `docs/validations/ui-test-performance.md`, cronología/duraciones en CSV/JSON con referencias a bundles y evidencia en PROGRESS. El orquestador persiste estado después del verdict; no marcar aceptación sin evidencia. La prohibición original de ejecutar sigue siendo historia de la implementación, no bloqueo de la validación posteriormente autorizada.
