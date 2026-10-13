# Feature Implementation Spec: Eliminar ejemplar y memoria local

## Source Feature

- `id`: `delete-plant`; `area`: `coleccion`; fuente: `feature_list.json`.
- Comportamiento: tras confirmar desaparecen planta, ficha, fotos, cuidados y análisis sin afectar a otras plantas.
- `depends_on`: `plant-timeline`, `keep-analysis`, ambas `accepted` comprobadas.
- Estado: `not_started`; **decisiones funcionales y visuales aprobadas por el usuario el 2026-10-13; implementación no iniciada ni autorizada en esta sesión**.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/delete-plant`.
- Rama: `feature/delete-plant`; base `main`: `59cd1ebdf16e4f55688da1fd28cc0c156a12ab69`, corroborada por el orquestador después de fetch.
- Planner: `openai/gpt-6.1-sol`, feature-flow un solo paso. El orquestador persiste el borrador por denegación de edición del planner.
- Verificación fuente: cancelar/confirmar una de dos plantas con memoria, reiniciar y comprobar cascada/aislamiento; gate estándar.
- Planificación solamente: no código implementado, builds, tests, init ni inspección de simulador.

## Goal

Una acción humana confirmada desde el detalle elimina el ejemplar y toda su memoria local.
El éxito corresponde a un commit único de metadata y devuelve a «Mis plantas» actualizada.
La eliminación no afecta a otro ejemplar aunque comparta especie, fechas o bytes de fotografía.

## Non-Goals

- Sin archivado, Deshacer, recuperación garantizada, borrado independiente de análisis ni otra feature.
- Sin IA nueva, cuentas, servidor, sincronización, permisos adicionales ni eliminación remota.
- Sin borrar consentimiento global/configuración, toda PlantStore, bibliotecas de Fotos, originales importados o backups.
- Sin promesa de borrado físico seguro o transacción distribuida entre SwiftData y JPEG.
- Sin schema nuevo, migración, tombstones persistentes, refactor general de navegación o rediseño de ficha/historial.
- La inicial sigue protegida en delete de historial; **solo borrar su planta completa elimina inicial y su análisis**.

## Job Story

Cuando ya no quiero conservar un ejemplar, quiero eliminarlo desde su detalle con confirmación clara,
para que desaparezcan su ficha y toda su memoria local sin borrar otro ejemplar de la misma especie.

## Users And Permissions

- Único usuario local del dispositivo; no hay roles ni acceso remoto.
- La acción destructiva requiere intención explícita y confirmación humana.
- No solicita acceso adicional a Fotos, cámara ni proveedor externo.

## Acceptance Scenarios — Given / When / Then

1. **Entrada y confirmación.** Dado detalle loaded, incluso con JPEG fallido, cuando desplazo al final,
   entonces veo «Eliminar planta» rojo **después de `detailDisclaimer` (leyenda final de cuidados)**.
   Al tocar abre alerta iOS centrada como el borrado de cuidado/foto; no sheet, menú ni borrado directo.
2. **Cancelar.** Dadas dos plantas con memoria, cuando cancelo la alerta o abandono el detalle antes de confirmar,
   entonces cero escrituras/callbacks, metadata y JPEG exactos; si sigo en detalle, conserva selección del pager.
3. **Cascada completa.** Dada A con ficha, inicial, varias adicionales, cinco tipos de cuidado/notas y análisis en inicial/adicional,
   cuando confirmo, entonces un commit elimina todos los registros propios; limpieza intenta todos los JPEG propios.
   Vuelvo a colección sin A, no a detalle notFound; B conserva modelos, fechas, textos, bytes y consumidores retenidos.
4. **Persistencia y última planta.** Dado commit correcto, cuando relanzo sin reseed,
   entonces A y su memoria no reaparecen; B sigue íntegra. Si borro la última, aparece el vacío real con Añadir disponible.
5. **Rollback.** Dada falla inyectada después de mutar y antes de save, cuando confirmo,
   entonces no navego ni quito tarjeta; planta/ficha/cuidados/fotos/análisis y JPEG siguen exactos en actor y al reabrir.
   Banner permite Reintentar la misma intención local; ×/Cancelar la abandonan, siguiente intento exige nueva alerta.
6. **Obsolescencia/lectura.** Dado snapshot de planta cambiado, ausente o metadata ilegible,
   cuando confirmo, entonces no elimino ni emito éxito; error distinto de rollback, sin retry destructivo ciego.
   Releer detalle/lista permite nueva selección/confirmación, o notFound real sin fingir commit propio.
7. **JPEG faltante/cleanup.** Dados JPEG ausentes/corruptos, cuando borro metadata válida, entonces no bloquean cascada.
   Si falla cleanup tras save, éxito no se revierte ni ofrece retry de delete; huérfanos se recuperan al abrir tras validar TODAS las entidades.
8. **Commit y tardíos.** Dadas lecturas/decode anteriores y commit demorado, cuando confirmo dos veces o intento back/gesto/otra acción,
   entonces un despacho, controles bloqueados hasta resolver; tras éxito resultados/callbacks antiguos no reviven A ni sus imágenes.
   Un owner desaparecido después del despacho no cancela/compensa un commit exitoso; callback canónico exactamente una vez.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json`, `.agents/skills/feature-spec/references/spec-template.md`,
  `.agents/skills/ios-clean-mvvm/SKILL.md` — roles, plantilla, dependencias y guía iOS activada por lectura.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`,
  `ARCHITECTURE.md`, `CONSTRAINTS.md`, `DESIGN.md` — alcance, identidad por ejemplar y límites.
- `docs/adr/012-local-history-deletion.md`, `docs/adr/014-durable-photo-analysis-acceptance.md` — rollback, cleanup, definitivos.
- `PlantCareAI/Features/PlantList/Data/{LocalPlantRepository,PersistedPlant}.swift` — actor único, recuperación y ficha embebida.
- `PlantCareAI/Features/{CareEvents/Data/PersistedCareEvent,PlantPhotos/Data/PersistedPlantPhoto,KeepAnalysis/Data/PersistedPlantPhotoAnalysis}.swift` — pertenencia por `plantID`, no relaciones cascade declaradas.
- `PlantCareAI/Features/{CareEvents/Domain/DeleteCareEventUseCase,PlantPhotos/Domain/DeletePlantPhotoUseCase}.swift` — escritores estrechos.
- `PlantCareAI/Features/PlantDetail/Presentation/{PlantDetailView,PlantDetailViewModel}.swift` — pie exacto, sheets y generaciones.
- `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel,PlantCardViewModel}.swift` — NavigationPath local, cards estables, detalles débiles.
- `PlantCareAI/Features/PlantTimeline/Presentation/{PlantTimelineView,PlantTimelineViewModel}.swift` — alerta/binding independiente, banner, commit retenido.
- Secciones lifecycle de `PlantCareAI/Features/PlantPhotos/Presentation/PlantPhotoPagerViewModel.swift`,
  `PlantCareAI/Features/LastWateringHint/Presentation/LastWateringHintViewModel.swift`,
  `PlantCareAI/Features/AnalyzeCurrentPhoto/Presentation/PlantPhotoAnalysisViewModel.swift` — invalidación, cache y cierre.
- `PlantCareAI/PlantCareAIApp.swift`, referencias de `PlantCareAI.xcodeproj/project.pbxproj` — composición después de overrides; registro explícito.
- `PlantCareAITests/{LocalPlantRepositoryTests,DeletePlantPhotoTests}.swift`; selectores de DeleteCareEvent/Keep/List tests;
  secciones `DeleteCareEventUITests` de `PlantCareAIUITests/PlantCareAIUITests.swift` — rollback, fixtures y gestos reales.
- `PlantCareAI/Localizable.xcstrings` (claves delete), `docs/testing-ui.md`, `init.sh` — copy, comandos focales y gate.

### Existing Patterns To Follow / Current Gaps

- No spec previa ni escritor de eliminación de planta. Domain/Data nuevos mínimos, no entidad nueva.
- `PersistedPlant` lleva seis campos de ficha; borrar ese registro borra ficha. Cuidados/adicionales/análisis requieren fetch/delete explícitos.
- `store()` valida los cuatro conjuntos antes de limpiar `Photos`/`AdditionalPhotos`; con contexto cacheado no repite todo: revalidar antes de mutar delete.
- `deletePhoto` confirma metadata+análisis y luego limpia JPEG best-effort; no encadenar deletes de historial: rompería atomicidad.
- Alerta real en `PlantTimelineView`: `.alert(..., isPresented:)`, Cancelar `.cancel` / Eliminar `.destructive`, contexto y advertencia de irreversibilidad.
- `PlantTimelineViewModel.showingDeletionConfirmation` está separado del snapshot porque iOS baja el binding antes de ejecutar la acción.
- `NavigationPath` pertenece a `PlantListView`; no puede limpiarlo Domain ni Data. ListVM conoce el detalle REAL mediante referencia débil.
- `PlantCardViewModel.cancelLoading()` y `LastWateringHintViewModel.disappear()` no purgan todos los loaded: añadir invalidación terminal específica si quedan owners retenidos.
- Investigación visual: DESIGN y vistas/catálogo reales consultados; búsqueda `**/*.{png,jpg,jpeg,html}` no encontró recursos en este worktree.
  No adjuntos visibles, HTML/capturas originales ni simulador inspeccionados; no inventar comparación con ellos.

## Technical Approach

### Domain / Data / Composition

- Crear `Features/DeletePlant/Domain/PlantDeletingRepository.swift`: protocolo Sendable `deletePlant(_ expected: Plant) async throws -> Plant`;
  error tipado `notFound`, `conflict`, `readFailure`, `storage`. Sin defaults no-op en lectores existentes.
- Crear `Features/DeletePlant/Domain/DeletePlantUseCase.swift`: protocolo y caso `DeletePlant`, snapshot Plant propio e inmutable;
  sin revalidar fechas históricas contra now. Resultado = planta canónica eliminada, no lista parcial ni estado UI.
- Data vive en el **mismo** `Features/PlantList/Data/LocalPlantRepository.swift`, conformando al escritor estrecho.
- Antes de mutar: fetch/validar cuatro conjuntos, pertenencias, referencias canónicas y análisis mediante helpers reales;
  localizar planta por UUID y comparar todos los campos del snapshot esperado, incluida ficha, sin comparar JPEG.
  Error de fetch/mapeo = readFailure, ausencia = notFound, snapshot distinto = conflict; cero mutación/cleanup propios.
- La confirmación autoriza **toda la memoria vigente de ese UUID al commit**, no un inventario leído por UI:
  nuevos hijos válidos también se eliminan; cambio de Plant exige nueva confirmación. No fingerprint del historial.
- Capturar referencias JPEG validadas; eliminar análisis por plantID (inicial y adicionales), cuidados por plantID,
  adicionales por plantID y planta/ficha en **un** delete→`beforeDeletionCommit`→`beforeCommit`→save síncrono sin await/autosave.
- Throw pre-save: `context.rollback()`, storage; JPEG nunca borrados antes de save. No borrar entidades ajenas con UUID coincidente en otro tipo.
- Post-save: intentar cada fichero capturado de `Photos/<plantID>.jpg` y `AdditionalPhotos/<photoID>.jpg` por separado;
  ausente = no-op, fallo de uno no impide intentar restantes. Usar `beforeDeletionCleanup` para fallo testeable, sin convertir éxito en error.
- Reutilizar recuperación actual al abrir, fail-closed antes de ambos directorios; no reset, rutas externas ni eliminación de carpetas completas.
- `PlantCareAIApp.swift` inyecta DeletePlant sobre actor elegido tras overrides Debug a ListVM/fábrica de Detail.
  Flujo: DetailView → DetailVM → DeletePlantUseCase → PlantDeletingRepository ← LocalPlantRepository.

### Presentation / Errors / Navigation

- Mantener UI en `Features/PlantDetail/Presentation`; no nuevo VM por cada tipo ni pantalla en ContentView.
- DetailVM: estado separado idle/confirming/deleting/failed/deleted; snapshot de confirmación y Bool nativo separados.
  Guard loaded, sin sheet/editor/commit activo; double tap y reintentos guardados.
- Al confirmar invalidar lecturas metadata previas, diferir foreground/refresco que sustituya snapshot; conservar UI hasta resultado.
  Durante deleting bloquear Editar, registrar, añadir, analizar, historial, delete y back/gesto; conservar scroll funcional.
- Task de commit retiene owner hasta resolución y no se cancela por disappear; después de éxito marcar terminal antes del callback.
- Banner superior coherente con Timeline: «No pudimos eliminar la planta», ×, Cancelar; storage ofrece Reintentar literal.
  Garantizar solo metadata retenida; no prometer JPEG sano si faltaba. readFailure/conflict/notFound usan copy propio, Releer,
  sin retry destructivo; releer falla como error, nunca colección vacía. Cerrar abandona snapshot/retry; salida no restaura banner.
- Callback MainActor único a ListVM: incrementar metadataGeneration, quitar solo A de plants/cards, cancelar/purgar sus consumers,
  retirar referencia débil Detail y limpiar newlyAddedPlantID si era A. Mantener identidad/cache/orden de B.
  Si lista no loaded, relectura completa fail-closed, no snapshot parcial fingido; invalidar resultados anteriores.
- Invalidación terminal de Detail: metadata/photo generations, sesiones care/photo/editor, confirmaciones, formPhoto/pager cache,
  LastWatering tareas/observadores; guards impiden load/foreground/callbacks tardíos de update/care/add/analysis tras delete.
  Card eliminada libera foto y LastWatering. Consumers de Timeline abandonados por pop cancelan/liberan resultados e imágenes.
- ListView observa evento de eliminación confirmado (UUID/token de evento, no count de cards) y limpia **su path a raíz**,
  únicamente por éxito propio del detalle; no usar dismiss para dejar ruta inválida. No toast, navegación optimista ni IO para fabricar éxito.
- Sheets exclusivas ya cubren escritores interactivos: no permitir delete si una sigue abierta/busy; no nuevo gate global de red.
  Actor serializa escrituras: altas de hijos despachadas antes se incluyen; posteriores fallan planta inexistente, no resurrección.

## Visual Design Impact

- UI sí; fuente DESIGN.md + instrucción explícita usuario + patrón de alerta existente. Sin nuevo mockup requerido.
- Botón desplazable como último bloque loaded, después de careSheet y su leyenda, margen20/spacing24 existentes,
  cápsula nativa ≥52pt, SF Symbol trash opcional decorativo, etiqueta «Eliminar planta», rol destructivo y color rojo o rojizo acorde con el diseño de la app, según confirmación del usuario.
  No verde ni reutilización automática de un color de acción no destructiva; tampoco toolbar, sticky footer ni acción en tarjetas. Elegir el tono en implementación respetando DESIGN.md, su significado destructivo y contraste legible.
- Alerta título «¿Eliminar esta planta?», nombre humano literal separado, mensaje:
  «Se eliminarán esta planta, su ficha de cuidados, todas sus fotografías, cuidados registrados y análisis guardados del almacenamiento local. Esta acción no se puede deshacer.»
  Botones «Cancelar» y «Eliminar» destructivo; no contar hijos ni repetir avisos remotos innecesarios.
- Busy «Eliminando planta…»; IDs propuestos `deletePlant-UUID`, `deletePlantBusy`, `deletePlantError`, `retryDeletePlant`,
  `cancelDeletePlantError`, `closeDeletePlantError`, `reloadDeletePlant`. Copy nuevo `deletePlant.*` en xcstrings con fallback español.
- Mantener textos completos, soporte adaptable/AX, targets ≥44, nada de nuevas matrices de verificación por rutina.

## Expected File Changes

- Crear los dos Domain Swift indicados; modificar LocalPlantRepository, DetailView/VM, ListView/VM, App, xcstrings.
- CardVM/LastWateringVM: método terminal mínimo para purge si necesario; pager/timeline solo cleanup/guards afectados, sin rediseño.
- Crear `PlantCareAITests/DeletePlantTests.swift`; ampliar DetailVM/ListVM tests y regresiones afectadas de cache/lifecycle.
- Añadir `DeletePlantUITests` al archivo UI existente; fixture/verifier Debug en
  `PlantCareAI/Features/DeletePlant/Data/DeletePlantTestFixture.swift`.
  Verifier de disco real comprueba ausencia y B exacta tras relaunch; no usar viejo storage verifier que exige dos plantas.
- `PlantCareAI.xcodeproj/project.pbxproj`: registrar cada fuente nueva en grupo/target/build phase correctos, sin membership ajeno.

## Durable Documentation Impact

- `ARCHITECTURE.md`: update al implementar, escritor/callback/invalidación terminal.
- `CONSTRAINTS.md`: update, excepción inicial solo planta completa y cascada atómica.
- `AGENTS.md`: no necesario; proceso, startup y verificación no cambian.
- `DESIGN.md`: update pequeño del pie/alerta/busy/error aprobado, no rediseño.
- `docs/domain-model.md`, `docs/build-brief.md`, `docs/risks-and-open-questions.md`: update delta implementado y límites metadata/JPEG/remoto.
- Proponer `docs/adr/015-local-plant-deletion.md` en implementación: contrato transversal snapshot/cascada/terminal y excepción inicial,
  sujeto a esta revisión; no modificar ADR/specs aprobados históricos.
- `docs/testing-ui.md`: añadir cobertura/IDs, sin conteos inventados.
- `docs/testing-delete-plant.md` y `docs/handoffs/delete-plant.md`: comandos/verifier/evidencia futura; init.sh intacto.
- Ahora: solo spec, nota de planificación PROGRESS y puntero en notes de feature; status/evidence no acreditan ejecución.

## Implementation Plan

1. Definir contratos Domain y tests de despacho/snapshot; documentar ADR015 acordado.
2. Implementar cascada en actor con tests de disco/rollback/cleanup/aislamiento antes de UI.
3. Integrar estado UI/alerta/banner, callback de List, purga terminal y navegación a raíz; registrar fuentes/composición.
4. Añadir fixture/verifier opt-in Debug Simulator, UUID-store aislado y E2E; exclusión Release de flags/tipos.
5. Verificar selección por impacto/visual estándar autorizada, actualizar docs/evidencia/handoff; validator independiente después.

## Implementation Tasks — solo después de aprobar spec

- [ ] Añadir escritor estrecho/error/caso de uso sin ampliar consumidores read-only con capacidades ficticias.
- [ ] Añadir fetch/validación/cascada/save único/rollback y cleanup por archivo; no encadenar deletes de historial.
- [ ] Añadir intención/alerta/commit/fallo/terminal en Detail y guards ante sheets/acciones obsoletas.
- [ ] Aplicar callback único, purga por UUID y evento de navegación a raíz; preservar consumidores de B.
- [ ] Añadir tests Domain/Data/VM y E2E persistentes con fixture real/verifier de ausencia y aislamiento.
- [ ] Registrar Swift nuevos, copy localizado y documentación durable acordada.
- [ ] Ejecutar verificación focal autorizada y preparar handoff sin marcar aceptación independiente.

## Verification Plan — comandos futuros, ninguno ejecutado por planner

### Implementer — impact-selected checks

| Cambio → riesgo | Selección mínima / casos nuevos |
| --- | --- |
| Actor/contrato → cascada parcial y cruces de UUID | DeletePlantTests: dos plantas misma especie, hijos con IDs coincidentes ENTRE tipos, cinco cuidados, inicial/adicional+análisis; actor y reopen; singleton/sin hijos. |
| Save/cleanup → pérdida irreversible | Fallo después de todos los deletes/before save, retry literal y reopen intacto; JPEG missing/corrupt; cleanup parcial/fallo total, ambos directorios y recovery bloqueada por cada conjunto corrupto incluido análisis V4. |
| Validación → delete obsoleto o daño ajeno | Snapshot cambiado, absent/double delete (notFound, NO éxito), corrupt store/metadata antes de mutación; hijos vigentes; save/add/keep tras delete rechazan origen ausente. |
| VM/list/path → resurrección o navegación rota | DetailVM/ListVM nuevos casos confirming cancel, alert binding, duplicate, busy, owner disappear, callback once, lista loading/failed/tardía, terminal y consumers B idénticos. |
| Cleanup terminal → imágenes/textos tardíos | Lecturas/decode detenidas con respuesta después de delete; loaded e in-flight card/pager/LastWatering; callbacks antiguos update/care/add/keep ignorados. |
| UI/localización → pie errado/falsa confirmación | DeletePlantUITests: pie después disclaimer con textos largos, alerta/cancel, cascada+relaunch/verifier B, última→vacío, error/retry/×/Cancelar/reconfirmar, busy/back/gesto, JPEG fallido, fallback inglés. |
| Writers compartidos → regresión | LocalPlantRepositoryTests, DeleteCareEventTests, DeletePlantPhotoTests, LocalPlantPhotoAnalysisRepositoryTests; guards/cache tests de consumers modificados. UI DeleteCareEvent/Keep cascada y Timeline back/selección por métodos afectados, no todas las pantallas por rutina. |

Comando base futuro: `$UDID` acordado de un único iPhone estándar, texto normal/una apariencia; coordinar sin competidores.

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/DeletePlantTests \
  -only-testing:PlantCareAITests/PlantDetailViewModelTests \
  -only-testing:PlantCareAITests/PlantListViewModelTests \
  -only-testing:PlantCareAIUITests/DeletePlantUITests test
```

Ampliar `-only-testing` con clases/métodos de tabla conforme diff real; registrar motivos, sin tests manuales simultáneos.
Para visual focalizada: build-for-testing válido + `scripts/configure-ui-test-environment.py` valor1 + selección test-without-building,
según docs/testing-ui.md: pie/alerta/error/busy, no capturas de todas las filas. Mantener E2E persistentes, no solo spies.
Estáticos futuros: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON catálogo/feature sin duplicados y `git diff --check`.
Release build/auditoría por nuevos seams: ausencia de fixture/flags/puente; no leer config privada ni API real.
Preparar example vacío solo si Config real no existe antes de build, nunca overwrite. No preparar config en planning.
Reusar baseline solo corroborada de mismas fuentes pertinentes/config/destino; base histórica accepted no valida delete nuevo.
Si falta baseline, diagnóstico/build focal, no full gate rutinario; preservar fallos y repetir solo escenario/reparaciones afectadas con hipótesis.

### Validator — final gate

- Una `caffeinate -dius ./init.sh` final sobre fuentes ejecutables definitivas, o corroborar gate válido idéntico existente; ambas fases obligatorias.
- init ejecuta checks/build/tests y termina; no inicia servidores. No modificar harness ni duplicar focales cubiertas por gate sin laguna concreta.
- Reparación executable/config/resources/tests que invalide evidencia exige justificar nuevo gate después de diagnóstico focal; fallo nunca verde retroactivo.
- Este planning solo documental: revisión de coherencia, no builds/tests/init.
- SE/DT aumentado/VoiceOver/matrices fuera habitual: no ejecutadas, ni requisitos/bloqueos automáticos de aceptación.

## Evidence To Capture

- Aprobación de spec; comandos completos, selección/motivo, resultado/exits, fuentes/config/destino y entorno único.
- Diferenciar nueva ejecución, evidencia pertinente reutilizada y gate pendiente del validator.
- Modelos/UUIDs/textos/bytes antes-después y reopen: ausencia completa de A y B íntegra, incluidos definitivos.
- xcresult/logs y capturas focales realmente inspeccionadas del pie, alerta, error y busy.
- Fallos originales/diagnósticos/reparaciones conservados; no sumar duplicados ni presentar gate parcial como aprobado.
- Registrar evidencia real en feature/PROGRESS/handoff; passing solo focal, accepted solo tras aceptación independiente.

## Validator Checklist

- [ ] Scope de una feature, aprobación explícita y escenarios Given/When/Then satisfechos.
- [ ] Cascada metadata atómica/rollback y JPEG best-effort explícitos; B completa/bytes antes-después/reopen.
- [ ] Inicial/análisis inicial borrados solo vía planta completa; delete de historial sigue protegido.
- [ ] Pie rojo tras leyenda, alerta nativa, error sin promesas falsas, busy/back/gesture, raíz/última planta.
- [ ] E2E persistentes añadidos, no solo pruebas con spies ni desaparición visual de tarjeta.
- [ ] Capas/composición, único actor, terminal/tardíos, registros PBX y exclusión de seams en Release correctos.
- [ ] feature/PROGRESS/docs actualizados con evidencia REAL y estados correctos.
- [ ] Sin datos remotos/consent/config borrados, scope adyacente, tests debilitados o publicación no autorizada.

## Decisiones y dudas para revisión

### Confirmación del usuario — 2026-10-13

- Aprobados los cinco puntos presentados: botón rojo o rojizo acorde al diseño después de la leyenda y alerta Cancelar/Eliminar; cascada completa sin Deshacer; vuelta a Mis plantas sin mensaje adicional; conservación de datos ante fallo de commit con opción de reintentar; limpieza JPEG posterior best-effort con recuperación al reabrir.
- Las propuestas siguientes quedan confirmadas en ese alcance. No hay dudas de producto bloqueantes identificadas; el tono exacto se elegirá respetando DESIGN.md y contraste en implementación.
- Esta confirmación no inicia el siguiente rol: se mantiene la instrucción de detenerse tras planner, sin implementación, validación ejecutable ni entrega Git.

- Propuesta: éxito sin toast/Deshacer y vuelta directa a raíz, coherente con deletes existentes. Confirmar copy/estilo rojo del pie.
- Propuesta: misma frontera de ADR012: metadata atómica + JPEG cleanup best-effort;
  **no garantía de desaparición física inmediata ante fallo de filesystem**.
  Si se exige esa garantía, parar y replantear protocolo/UX antes de implementar; no disfrazar cleanup de transacción atómica.
- Propuesta: snapshot Plant completo, cascada de hijos vigentes al commit; sin inventario/count en alerta.
  Conflicto exige reread/reconfirmar, ausencia no significa éxito idempotente.
- Tamaño adecuado: un flujo y contrato de eliminación, sin modelo persistente nuevo; riesgos transversales tratados mediante pruebas por impacto.
- No duda de producto bloqueante identificada bajo estas decisiones aprobadas.
- Siguiente paso: esperar petición explícita para ejecutar implementer. **No implementación automática.**
