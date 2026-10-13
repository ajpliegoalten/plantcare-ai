# Feature Implementation Spec: conservar un análisis aceptado junto a su foto

## Source Feature / estado de este documento

- `id`: `keep-analysis`; `area`: `analisis-ia`; título fuente: «Guardar foto junto al análisis».
- `user_visible_behavior`: «Al pulsar Guardar se incorporan juntos foto actual y análisis al historial de esa planta».
- `depends_on`: `analyze-current-photo`, actualmente `accepted`, corroborado en `feature_list.json` y secciones recientes de `PROGRESS.md`.
- `status`: `not_started`; `verification`: guardar, reiniciar y comprobar un solo hito con foto y análisis, sin cuidado nuevo.
- Planner ONE STEP, 2026-10-13, skills `feature-spec` e `ios-clean-mvvm`; **borrador pendiente de revisión humana integral; no autoriza implementación**.
- Raíz indicada por entorno y herramientas de lectura: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/keep-analysis`.
- Rama `feature/keep-analysis`, base `main`, SHA `97e9e00fb6a79c85fa8809a53985041557060a78`, comunicadas por usuario/padre; no comprobadas mediante Git ni `pwd` en este paso (sin herramienta de shell disponible).
- Única salida de este paso: esta spec. No cambios a producto, `feature_list.json` o `PROGRESS.md`; no tests/build/init/simulador ni operaciones de entrega Git.

## Goal / Job Story

Cuando leo el resultado provisional de una foto de mi ejemplar, quiero guardarlo explícitamente para consultar después su texto junto a **esa misma foto**, incluso tras cerrar la app, y permitir que futuros análisis usen su texto como contexto anterior propio.

**Contrato visual confirmado por usuario:** el análisis aceptado aparece en el timeline **debajo de su foto asociada**, con estilo similar a los comentarios/notas de cuidados, dentro de su hito existente y sin duplicar foto ni evento. Aceptar es una intención; solo el commit local exitoso convierte el provisional en definitivo. No confirma un diagnóstico ni registra una acción de cuidado.

## Non-Goals / Users And Permissions

- Único usuario local, sin cuentas, backend, sincronización, chat, notificaciones, cambios de especie/ficha ni edición del texto IA.
- No implementar `discard-analysis`, `delete-plant`, nueva captura/galería o eliminación independiente de un análisis.
- El origen ya es una foto local: no insertar otra fotografía, copiar/recomprimir JPEG ni crear un hito «Análisis» separado.
- No comparar imágenes históricas, inferir evolución visual, generar un resumen ni convertir comprobaciones en cuidados realizados.
- Guardar y consultar lo guardado son operaciones locales sin API/configuración/consentimiento nuevos. Las solicitudes posteriores mantienen el aviso y barrera v5 existentes.
- La coherencia de borrar una adicional con análisis sí es integración necesaria del borrado ya existente, no una nueva acción de usuario.

## Decisiones confirmadas / incógnita pendiente

- Etiqueta del botón activo: **«Guardar análisis»**, conservando el ID `analysisAccept`; es el Aceptar del handoff y el Guardar de la feature. Confirmado por el usuario. El definitivo se reconoce después del commit y entonces se cierra el modal, sin toast nuevo.
- Un resultado `insufficientEvidence` no es una respuesta correcta/útil para guardar: confirmado por el usuario, **no permite guardar el análisis**. La acción Guardar no aparece o queda deshabilitada para ese resultado; Domain/Data también rechazan cualquier intento programático.
- Un definitivo por `(plantID, PlantPhotoIdentity)`; no reemplazo silencioso ni reanálisis. Confirmado por el usuario: para una foto ya analizada, el botón no aparece o aparece deshabilitado. El intento concurrente/obsoleto también debe rechazarse en Domain/Data. Reintento exacto de una aceptación ya confirmada devuelve el mismo registro; otra aceptación para la misma foto produce conflicto.
- Borrar una adicional elimina su análisis asociado en el mismo commit de metadata. Confirmado por el usuario: la alerta existente avisa que también se eliminará el análisis guardado, solo cuando exista. La inicial continúa protegida.
- No quedan preguntas funcionales pendientes de las decisiones consultadas. Revisar integralmente la spec antes de autorizar implementación. Si se exige conservar análisis sin foto o reemplazar definitivos, revisar el contrato explícitamente.
- Recursos visuales adjuntos mencionados: no hay ruta/adjunto legible en este contexto; búsqueda de `**/*.{html,png,jpg,jpeg,svg}` sin coincidencias. `DESIGN.md` referencia HTML histórico de conversación, no un archivo disponible. No afirmar inspección de esos adjuntos ni inventar equivalencia pixel-perfect; referencia operativa: dirección escrita y renderer real de notas.

## Acceptance Scenarios (Given / When / Then)

1. **Aceptación durable:** Dada inicial o adicional propia con resultado provisional válido, cuando pulso Guardar análisis, entonces el commit conserva vínculo y texto exactos, cierra tras éxito y el timeline muestra el análisis debajo de esa foto en un único hito. JPEG, fecha de foto, portada, cuidados y último riego no cambian.
2. **Solo intención explícita:** Dado resultado remoto, cuando aún no lo guardo o cierro con ×/Cancelar/gesto, entonces no existe definitivo; reabrir permite nueva consulta explícita. Descarta análisis sigue visible/inactivo hasta su feature y su ayuda no sugiere que Guardar también sea futuro.
3. **Reinicio y aislamiento:** Dadas dos plantas y dos identidades con JPEG iguales, cuando guardo una y relanzo sin reseed, entonces solo esa identidad conserva contenido/fechas, un hito y ningún cuidado nuevo. Otra planta/foto sigue elegible; almacenamiento y bytes ajenos exactos.
4. **Fallo de escritura:** Dado provisional válido, cuando falla antes de `context.save`, entonces rollback deja cero definitivo, foto intacta y el modal conserva resultado/snapshot; error «No pudimos guardar el análisis» con Reintentar guardado local, sin HTTP adicional. ×/Cancelar/gesto fuera de commit liberan ese retry.
5. **Doble tap/commit:** Dado guardado en curso, cuando pulso de nuevo o intento cerrar, entonces hay un solo despacho y cierre/gesto/cambios bloqueados hasta resolver. Un commit real no se elimina ni se ignora por cancelación técnica posterior; relanzar recupera el definitivo, no el borrador.
6. **Elegibilidad real:** Dada foto con definitivo en disco, cuando abro pager/timeline o invoco preparación/despacho programáticamente, entonces no se envía nueva petición. Error del lector no se trata como ausencia ni habilita envío. Las entradas reflejan la existencia del definitivo sin depender solo de un Boolean UI.
7. **Contexto anterior real:** Dados textos guardados de varias fotos/plantas, cuando analizo una foto posterior, entonces el lector real entrega solo los definitivos propios; el constructor existente filtra por día de foto origen, no `acceptedAt`, excluye mismo día/posteriores y aplica 5 bloques/16KiB/omisiones. No carga JPEG históricos.
8. **Origen obsoleto/conflicto:** Dada foto eliminada o vínculo/snapshot no vigente, cuando intento guardar, entonces notFound/conflict impide escritura, no recrea foto ni sobrescribe definitivo; error requiere relectura/nueva intención, no retry ciego ni confirmación falsa.
9. **Borrado integrado:** Dada adicional con análisis, cuando cancelo su alerta, entonces ambos siguen exactos; cuando confirmo, entonces metadata foto+análisis desaparecen juntas, contexto futuro no devuelve texto huérfano y JPEG cleanup mantiene las reglas actuales. Fallo precommit conserva ambos. Inicial nunca se vuelve eliminable.
10. **Lectura/scroll:** Dados texto largo o JPEG faltante y análisis confirmado, cuando consulto historial, entonces texto íntegro bajo su foto/placeholder sigue legible y desplazable; ningún resultado de evidencia insuficiente aparece como análisis guardado. Un error de lectura de análisis produce error global recuperable, no historial parcial presentado como completo.

## Repository Research

### Archivos inspeccionados

- `AGENTS.md`, ambas skills/template, `feature_list.json`, secciones recientes de `PROGRESS.md`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `CONTEXT.md`, `DESIGN.md`, `docs/{build-brief,domain-model,risks-and-open-questions}.md`.
- Spec aceptada `docs/specs/analyze-current-photo.md` y `docs/adr/013-contextual-photo-analysis.md`: provisional solo modal, definitivo futuro bloquea y texto bajo foto; no reescribir spec/evidencia histórica.
- `PlantCareAI/Features/AnalyzeCurrentPhoto/Domain/{PlantPhotoAnalysis,AnalyzePlantPhotoUseCase}.swift`: contenido validado, reader opcional real pendiente, guard previo a preparación/despacho, `revision` actualmente 1.
- `.../Presentation/PlantPhotoAnalysisView{,Model}.swift`: resultado/thumbnail propios de sesión, prepared se libera tras éxito remoto, botones futuros inactivos y cierre incondicional actual.
- `Features/PlantTimeline/Domain/{PlantTimelineEntry,LoadPlantTimelineUseCase}.swift`, renderer `Presentation/PlantTimelineView.swift` y símbolos de VM: unión fail-closed, initial/additional/care, notas `Text` completas sobre Surface, identidad/fechas/orden estables.
- `Features/PlantPhotos/Domain/PlantPhoto.swift`: identidad discriminada, descriptor/fecha de origen; inicial no es entidad adicional.
- `Features/PlantList/Data/LocalPlantRepository.swift` líneas 1–150 y búsqueda de métodos: único actor, schema actual Plant/CareEvent/PlantPhoto, validación global antes de cleanup, delete foto y rollback/cleanup separados. No auditoría completa del resto del actor en este planner.
- `PlantCareAIApp.swift` composición timeline/análisis y búsqueda de símbolos; inicio de PBX y `init.sh`; `docs/testing-ui.md`; inicio de `PlantPhotoAnalysisViewModelTests.swift` y discovery de clases XCTest existentes.

### Patrones y gaps

- SwiftUI iOS17+, Presentation → Domain ← Data, composición App después de overrides Debug; PBX registra fuentes explícitas, `ContentView` no alberga features.
- `AcceptedPlantPhotoAnalysisReading.loadAccepted(for:)` ya aporta identidad/fecha/contenido pero no fecha de consulta/aceptación; no existe escritor ni entidad persistida. `AnalyzePlantPhoto.acceptedReader` es nil actualmente, capacidad ausente, no disco vacío.
- Timeline todavía no une textos definitivos; pager/timeline ofrecen Analizar sin estado definitivo previo. VM remoto debe separar fallos de guardado local de `.failed` remoto para no reenviar por retry.
- Fotos: viewport/cache3/concurrency2 y renderer metadata VStack O(n); conservarlos, no introducir carga masiva por montar texto.

## Technical Approach

### Domain — `Features/KeepAnalysis/Domain`

- Crear `SavedPlantPhotoAnalysis` (único modelo persistente nuevo): UUID de aceptación, plantID, identidad discriminada, `photoDate`, `queriedAt`, revisión provisional, `acceptedAt`, contenido estructurado exacto. Fechas de origen/consulta/aceptación independientes; no ruta/JPEG/UIImage/framework ni hechos botánicos añadidos.
- Snapshot de intención inmutable con descriptor de origen validado y resultado provisional. Capturar UUID/acceptedAt una vez al primer Guardar y conservarlos en retry; no usar `revision == 1` como identidad global de aceptación.
- `KeepPlantPhotoAnalysisUseCase`/`KeepPlantPhotoAnalysis`: validar contenido con `validated()`, fechas finitas, identidad/pertenencia/descriptor, caso inicial exige UUID de planta. No rechazar aceptación porque la foto sea retroactiva ni recalcular sus fechas.
- Contrato estrecho `PlantPhotoAnalysisStoring.saveAccepted(snapshot)` devuelve registro canónico; lector de registros guardados para UI y adaptación explícita al `AcceptedPlantPhotoAnalysisReading` existente. Data implementa ambos sobre el mismo actor; evitar protocolos por cada tipo sin boundary real.
- `LoadPlantTimeline` obtiene los definitivos reales, verifica pertenencia/vínculos y adjunta texto a initial/additional sin crear otra entrada. Añadir asociación por identidad a la proyección/snapshot de lectura, no a Plant/PlantPhoto persistidos; adaptar formatter y callers según representación elegida sin cambiar claves/fechas de filas.

### Data — `Features/KeepAnalysis/Data` + actor compartido existente

- Crear `PersistedPlantPhotoAnalysis` SwiftData con identidad discriminada estable (raw initial/additional + UUID), campos anteriores y contenido codificado estrictamente. Validar raw/arrays/fechas y unicidad/pertenencia en mapeo, no convertir corrupción en vacío.
- Extender `LocalPlantRepository` y su ModelContainer aditivamente (schema documental V4). Sin modificar nombres/campos de entidades existentes ni reset/migración destructiva; probar upgrade real V3 y almacenes anteriores mediante fixtures de disco existentes.
- Unicidad lógica `(plantID, kind, photoUUID)` comprobada en actor sin suspensión entre lookup/insert/save. Mismo UUID+payload literal completo confirmado → devolver canónico; mismo UUID diferente o otra aceptación sobre foto definitiva → conflicto, nunca overwrite.
- Revalidar planta/origen/descriptor en el actor justo antes de insertar; origen ausente no se reconstruye. No leer/escribir/recomprimir JPEG para guardar: ya está local y protegido por metadata; foto faltante/corrupta continúa su error propio de lectura, no justifica borrar análisis.
- Save explícito, autosave apagado, seam de fallo precommit y rollback. No devolver éxito antes de save ni ignorar commit después por cancelación técnica. Guardar no necesita red ni configuración del proveedor original.
- Recuperación: validar también análisis, duplicados y todos sus vínculos ANTES de cualquier cleanup de JPEG. Metadata inválida falla cerrado sin limpiar/resetear. Lectores de texto no leen JPEG.
- `deletePhoto` borra análisis propio y foto en la misma transacción metadata; rollback conjunto; cleanup JPEG postcommit sigue best-effort. Nunca cascada a identidad initial/otra planta ni nuevo delete de análisis público.

### Presentation / composición

- Reutilizar modal/VM en `AnalyzeCurrentPhoto/Presentation`; inyectar Keep, no Data. Estados locales separados saving/saveFailed/saved o subestado equivalente; error conserva resultado y snapshot sin volver a `prepare/send`.
- Guardar enabled solo para resultado vigente válido con respuesta útil y origen conocido, no para `insufficientEvidence` ni mientras espera/guarda/cierra. Capturar descriptor durante preparación (hoy se pierde al soltar prepared), sin retener JPEG tras respuesta remota.
- Bloquear toolbar ×/Cancelar y interactiveDismiss exclusivamente durante commit; `close()` debe rechazar cierre entonces. Callback canónico una vez antes de dismiss; separar éxito durable de error posterior de refresco, que nunca revierte guardado ni invita a guardar de nuevo.
- Timeline renderiza tres secciones completas debajo del bitmap adicional o del bloque inicial con miniatura existente: misma tipografía/body/alineación de nota, no nuevas tarjetas dentro de tarjetas. Etiqueta «Análisis guardado · orientación de IA»; no repetir fecha/hora de fila ni mostrar provisional.
- Inyectar lector real en TODOS los `AnalyzePlantPhoto` desde `PlantCareAIApp`, incluido proveedor sintético Debug. Reader de elegibilidad UI local independiente de que exista configuración API (lo guardado se consulta también en Release).
- Pager/timeline mantienen un estado loaded/unknown/failed de definitivos por planta: definitivo deshabilita Analizar; desconocido/fallo no se trata como vacío. Reentrada/foreground reconsulta y callback de save invalida consumidores retenidos propios, aun detalle suspendido bajo timeline; guard Domain sigue autoritativo para acciones obsoletas.
- No reemplazar pager/selección/cache por guardar. Refrescar proyección metadata después del callback y proteger respuestas tardías con generaciones; si lectura falla, error real con retry de lectura, no saveFailed. Modal gate sigue débil/sin cache provisional compartida.

## Expected File Changes (futuras, tras aprobación)

- Crear `Features/KeepAnalysis/Domain/{SavedPlantPhotoAnalysis,KeepPlantPhotoAnalysisUseCase,PlantPhotoAnalysisStoring}.swift` y `Data/PersistedPlantPhotoAnalysis.swift` bajo `PlantCareAI/`; nombres propuestos.
- Modificar `Features/PlantList/Data/LocalPlantRepository.swift`: schema, escritor/lectores, recuperación y borrado integrado; no adapter paralelo/sidecar ni default no-op.
- Modificar `Features/AnalyzeCurrentPhoto/Presentation/PlantPhotoAnalysisView{,Model}.swift`, contratos Domain solo si el descriptor/snapshot lo exige; reader existente sigue conectado sin alterar contexto/presupuestos/transportes.
- Modificar `Features/PlantTimeline/{Domain/PlantTimelineEntry,Domain/LoadPlantTimelineUseCase,Presentation/PlantTimelineView,Presentation/PlantTimelineViewModel}.swift`: unión/renderer/callback/copy delete.
- Modificar `Features/PlantPhotos/Presentation/PlantPhotoPagerView{,Model}.swift`, `Features/PlantDetail/Presentation/PlantDetailViewModel.swift`, `Features/PlantList/Presentation/PlantListViewModel.swift`, `PlantCareAIApp.swift`: elegibilidad/invalidaciones por UUID/fábricas.
- Modificar `Localizable.xcstrings` solo claves usadas y traducciones pertinentes; preservar cambios ajenos/orden innecesario. `PlantCareAI.xcodeproj/project.pbxproj`: registrar fuentes app/tests nuevas.
- Crear `PlantCareAITests/{KeepPlantPhotoAnalysisTests,LocalPlantPhotoAnalysisRepositoryTests}.swift`; ampliar VM análisis, Analyze/BuildContext/LoadTimeline/TimelineVM/PagerVM/DeletePhoto y pruebas de disco/migración pertinentes.
- Añadir clase `KeepAnalysisUITests` en `PlantCareAIUITests/PlantCareAIUITests.swift`; extender fixture Debug UUID real existente para fallo/busy/save/relaunch/verify, sin API real ni almacén simulado.

## Visual Design Impact

- UI sí: modal resultado/guardado/error y timeline; fuente `DESIGN.md`, decisión humana de texto bajo foto y renderer real de notas inspeccionado. No adjunto visual utilizable ni nuevo artefacto obligatorio.
- Guardar cápsula primaria verde ≥52pt; Descarta sigue neutral/deshabilitado y ayuda específica solo para esa acción. No rediseñar CTA terracota del pager, cabeceras, preview ni loading centrado accepted.
- Estado Guardando análisis con spinner y error local/retry legibles; guardar no muestra definitivo hasta commit. Texto completo/verbatim, subtítulos semánticos, espacios equivalentes a notas, soporte adaptable/AX/objetivos≥44; no HTML/copias decorativas ni color como única señal.

## Durable Documentation Impact (solo al implementar)

- `ARCHITECTURE.md`: update — dominio/escritor/lectores/schema y composición real, callback y cascada metadata.
- `CONSTRAINTS.md`: update — aceptación explícita durable, foto única/vínculo, lector real fail-closed y unicidad; conservar reglas provisionales anteriores.
- `AGENTS.md`: not needed — no cambio de workflow/gate. `CONTEXT.md`: not needed — vocabulario vigente suficiente.
- `DESIGN.md`, `docs/{build-brief,domain-model,risks-and-open-questions}.md`: update — definitivo debajo de foto, fechas separadas, retry local/cascada/bloqueo y límites de migración; aclarar menciones históricas de guardar/descartar foto nueva sin reescribir evidencia.
- Crear ADR014 de aceptación durable sobre foto existente/schema/cascada; referencias a ADR013 sin alterar spec aprobada ni historia de validación.
- Crear `docs/testing-keep-analysis.md`; actualizar `docs/testing-ui.md` y handoff con selectors/evidencia real. PROGRESS/feature_list corresponden a roles posteriores, **no modificados por este planner**.

## Implementation Plan / Tasks (no autorizadas todavía)

1. Obtener revisión humana integral de esta spec. Resolver cualquier cambio de contrato antes de código.
2. Implementar modelo/validación/use case y actor/persistencia; probar upgrade/rollback/idempotencia/vínculos antes de conectar UI.
3. Conectar lector real al análisis/contexto y unión timeline; probar fail-closed y coherencia delete/recuperación.
4. Integrar Guardar/retry/callback/elegibilidad en ambas entradas, sin perder selección ni modificar fotos/cuidado.
5. Registrar PBX/recursos/fixtures, E2E y documentación; autoverificar por impacto y entregar al validator independiente.

- [ ] Modelo/snapshot/contratos y pruebas puras de identidad/fechas/content/idempotencia.
- [ ] Entidad V4/actor/upgrade/lectores/cascada/rollback y pruebas de disco real.
- [ ] Guardar local/estados/bloqueo/callback y lector real conectado en composición.
- [ ] Texto bajo foto/elegibilidad/contexto anterior y regresiones retenidos/tardíos/scroll.
- [ ] Tests UI, PBX/localización/docs/handoff/evidencia; passing no equivale a accepted.

## Verification Plan (comandos futuros; ninguno ejecutado en este paso)

### Implementer — por impacto

- Domain/escritor → aceptación falsa/conflictos → Keep tests con inicial/adicional/ajena, contenido inválido, rechazo de `insufficientEvidence`, descriptor obsoleto, fechas separadas y retry snapshot literal.
- Actor/schema/delete/recuperación → pérdida de datos/huérfanos → LocalAnalysis disco real: save/reopen, dos plantas/bytes iguales, idempotencia/conflicto, rollback, V3→V4 más upgrades anteriores existentes, entidad corrupta/duplicada/origen inválido sin cleanup; delete conjunto rollback/postcommit cleanup fallido y inicial protegida. Regresiones LocalPlantRepository/LocalPlantPhoto/LocalCareEvent por ModelContainer compartido.
- Reader/contexto/timeline → datos cruzados/parciales → Analyze/BuildContext/LoadTimeline y VM: real definitivo bloquea prepare/execute sin HTTP; error lector aborta; texto anterior real con aceptación posterior/fechas invertidas, mismo día excluido, 5/16KiB/omisiones, cero JPEG históricos. Unión conserva IDs/fechas/orden/hito inicial y no agrega cuidado.
- Presentation/composición → red accidental/doble write/cierre/tardíos → VM análisis y Timeline/Pager: guardar doble, busy close rechazado, fallo retry sin nueva API/config/consent, origen borrado/conflicto, callback una vez incluso suspensión y refresh tardío/error sin falsear commit.
- E2E persistente disponible XCUITest: añadir KeepAnalysisUITests para save desde pager inicial y timeline adicional, texto bajo foto/relaunch sin reseed/aislamiento/un hito/cero cuidados, fallo retry local/busy/×/Cancelar/gesto, cierre sin save, largo, bloqueo de Guardar ante `insufficientEvidence`, definitivo sin reconsulta y delete adicional confirmado/cancelado. Actualizar expectativas de botones futuros en AnalyzeCurrentPhotoUITests, no eliminar assertions funcionales.

```sh
# Futuro: confirmar/coordinar un destino estándar; no ejecutar procesos competidores.
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/KeepPlantPhotoAnalysisTests \
  -only-testing:PlantCareAITests/LocalPlantPhotoAnalysisRepositoryTests \
  -only-testing:PlantCareAITests/PlantPhotoAnalysisViewModelTests \
  -only-testing:PlantCareAITests/LoadPlantTimelineTests \
  -only-testing:PlantCareAIUITests/KeepAnalysisUITests test
```

- Nombres nuevos propuestos: registrar selectors reales tras implementar y añadir regresiones por diff/callers al comando; productos válidos permiten test-without-building. Build solo necesario por cambios; no gate completo del implementer ni baseline completo rutinario.
- Baseline accepted 337/337 histórica no valida fuentes nuevas; reutilizar solo evidencia corroborada de inputs relevantes/config/destino idénticos. Sin evidencia válida diagnosticar/build focal. Tras fallo conservarlo y repetir primero fallido/repair afectados con hipótesis, no retries/iterations para verde.
- Config Debug: si falta copiar ejemplo vacío, nunca leer/sobrescribir real. No API real para esta feature local ni inspección/logging de secretos/payloads.
- Estáticos futuros: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON catálogo cuando cambie, `git diff --check`, dirección Domain Foundation y auditoría Release sin fixtures/config por impacto.
- Inspección visual básica solo modal save/error y timeline bajo foto con texto largo en único iPhone estándar/texto normal/una apariencia; capturas focales con helper de `docs/testing-ui.md`, sin duplicar tests solo por rol. SE/Dynamic Type ampliado/VoiceOver/matrices fuera de verificación habitual; no ejecutadas ni bloqueos automáticos.

### Validator — gate final

- Tras autorización y fuentes finales, único `caffeinate -dius ./init.sh`, o reutilizar gate completo corroborado de idénticos inputs/entorno. Script ejecuta build-for-testing y paralelo + PhotosPicker serial test-without-building; termina con estado, no inicia servidor ni proceso permanente. No modificar harness por rutina.
- Revisar ambos xcresult y cobertura/visuales; no repetir focales cubiertas salvo laguna concreta. Repair ejecutable invalida evidencia y justifica gate nuevo después de checks focales afectados, conservando fallo histórico.
- Este paso es solo documental: revisión de coherencia/spec, sin ejecutar tests iOS/build/init/simulador.

## Evidence To Capture / Validator Checklist

- Comandos/selectors/motivos, diff→riesgos→tests, estado inputs/config/destino, exit/xcresult, pruebas nuevas vs reutilizadas, fallos preservados, capturas realmente abiertas y límites. Verificación disco/modelos/JPEG antes-después sin contenido sensible en logs.
- Handoff/evidencia posterior distingue passing focal y accepted independiente; no atribuir prueba sintética a API real ni aceptación de esta spec por crearla.
- [ ] Aprobación humana integral previa; único modelo/flujo, sin features adyacentes ni archivos ajenos.
- [ ] Commit explícito único durable; foto existente no duplicada, contenido/fechas exactos, ningún cuidado/ficha/último riego mutado.
- [ ] Reader real en todas las composiciones; elegibilidad fail-closed y contexto anterior textual presupuestado sin JPEG históricos.
- [ ] Timeline texto íntegro bajo foto/miniatura, un hito y fecha de grupo única; selección/cache/scroll/hit-regions conservados.
- [ ] Rollback/retry local/idempotencia/conflictos/cierre busy/tardíos/callback/refresh/error aplicados sin red extra ni confirmación falsa.
- [ ] Upgrade no destructivo/recovery validado antes de cleanup y cascada adicional atómica; inicial protegida.
- [ ] E2E actualizado, gate final válido/evidencia/docs/estado por rol correctos; spec accepted anterior e historia intactas.

**Siguiente acción exclusiva:** revisión humana de esta spec. Detener flujo; no iniciar implementación ni validación automáticamente.
