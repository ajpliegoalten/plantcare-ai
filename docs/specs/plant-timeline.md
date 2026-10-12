# Feature Implementation Spec: Consultar cronología por ejemplar

## Source Feature

- `id`: `plant-timeline`; `area`: `historial`; fuente: `feature_list.json`.
- `depends_on`: `quick-watering`, `other-care-events`, `add-plant-photo`, todas `accepted` corroboradas en harness; refinamiento de fotos también accepted.
- `status`: `not_started`; `evidence`: `[]`; planner ONE STEP `openai/gpt-6.1-sol`, 2026-10-12.
- **Pendiente aprobación humana integral; no autoriza implementación.**
- Worktree exclusivo `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/plant-timeline`, rama `feature/plant-timeline`, base main/origin/main `52958d28ec907f0f7f4fbb0e6b298bd371f0fb28`, comprobadas por orquestador.
- Comportamiento fuente: «El detalle presenta fotos y cuidados ordenados por fecha, exclusivamente de esa planta». Se concreta como acceso desde detalle a extensión push, no lista adicional embebida.

## Goal / Job Story / Users And Permissions

Cuando reviso un ejemplar, quiero recorrer sus cuidados y fotografías por fecha para comprender lo registrado, sin mezclar otra planta ni confundir orientación IA con acciones humanas.
Una feature acotada: proyección no persistida y flujo detalle → historial → atrás; sin nuevo modelo de almacenamiento.
Único usuario local, sin cuenta/roles/permisos nuevos. Lectura offline; no envío externo ni aviso IA al consultar.

## Non-Goals

- No eliminación/edición de eventos, análisis, preguntas, registro desde historial, notas de foto, zoom ni galerías nuevas.
- No segunda copia del historial, migración/backfill/schema/almacén/actor nuevo ni cambio de fecha humana/origen IANA.
- No cambiar carrusel accepted `createdAt ASC`, selección/portadas, alta, sheets, último riego, seis cuidados ni resto del diseño del detalle.
- No perfil/avatar/favoritos/menu sin acciones, salud, completado/nutrición inventados, ciclos/alertas, pestaña Actividad, web/fonts/Tailwind/imágenes remotas.
- No modelos especulativos de análisis futuro. Inicial una sola vez como hito de alta, no fotografía duplicada.

## Acceptance Scenarios — Given / When / Then

1. **Push:** Given detalle loaded de A, incluso con foto fallida; When pulso Ver historial; Then se empuja Historial de cuidados en el stack existente y back nativo regresa al mismo A, sin sheet/Cancelar/stack anidado/rediseño de otras secciones.
2. **Unión propia:** Given cinco tipos de cuidados y adicionales de A; When consulto; Then cada registro aparece una vez, más alta/inicial una vez, días visibles más recientes arriba y dentro de cada día createdAt DESC, sin datos de B/ficha IA/resultados efímeros.
3. **Fecha elegida:** Given foto occurredAt10oct/createdAt11oct y cuidado11oct; When consulto en zona de origen; Then foto agrupa10oct detrás del cuidado11oct, aunque HTML la colocara11oct.
4. **Empates de día visible:** Given elementos del mismo día mostrado, aunque sus Date de elemento difieran; When consulto; Then createdAt más reciente primero; si también igual, clave discriminada ASC decide, sin desempate por occurredAt ni dependencia de fetch/tipo privilegiado.
5. **Día único/inversión de instantes:** Given foto y cuidado con occurredAt distintos del mismo día visible y orden occurredAt contrario a createdAt; When consulto; Then manda createdAt DESC, hay una sola cabecera de ese día y ninguna tarjeta de foto/cuidado/alta repite fecha, hora ni createdAt (tampoco como etiqueta/valor accesible redundante).
6. **Sin cuidados:** Given lecturas correctas sin eventos/adicionales; When abro; Then veo Aún no hay cuidados ni fotografías adicionales y Planta añadida con inicial/placeholder bajo cabecera de su día real, no pantalla totalmente vacía ni fecha repetida en tarjeta. Con fotos pero cero cuidados: fotos visibles y indicador discreto Sin cuidados registrados.
7. **Prealta:** Given cuidado/foto anterior al alta; When llego al final; Then alta ocupa su posición según día visible/createdAt/clave, sin forzarla última. Si alta no es último elemento, pie exacto Has llegado al primer registro de este ejemplar; si es último, Has llegado al origen de este ejemplar.
8. **Error metadata:** Given falla lectura de eventos o metadata de fotos; When consulto/reintento; Then error global con Reintentar, no vacío ni unión parcial presentada como completa.
9. **Error JPEG:** Given solo imagen ausente/corrupta; When consulto; Then cabecera de día/hito/cuidados permanecen, con error/retry exclusivamente de esa imagen y sin fecha duplicada en placeholder/error.
10. **Cancelación/read-only:** Given lectura/decode suspendidos; When vuelvo atrás/abro B/reintento; Then tardíos no publican en sesión/UUID nuevos; consultar/scroll/refrescar/reintentar no guarda ni modifica registros/JPEG/portada.
11. **Refresco:** Given vuelvo al detalle, registro cuidado/foto y reabro historial; When carga; Then muestra commit una vez en fecha elegida. Relanzar sin reseed conserva lo mismo; cancelar/fallar registro no inventa elementos.
12. **Contexto/textos:** Given viaje/medianoche/reloj retrocedido o nota larga; When activa/foreground; Then grupos/cabeceras usan contexto actual, Hoy/Ayer son calendario y texto íntegro es alcanzable por scroll. Cambio de zona recalcula día visible y orden final: puede unir/separar grupos y cambiar orden relativo por createdAt, sin relectura por zona, urgencia ni cambios persistidos; no fechas repetidas por tarjeta.

## Repository Research

### Files Inspected

- `AGENTS.md`, `.agents/skills/{feature-spec,ios-clean-mvvm}/SKILL.md`, template feature-spec, `PROGRESS.md`, `feature_list.json`: rol/estado/dependencias/verificación.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, `DESIGN.md`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `docs/adr/011-local-additional-plant-photos.md`: lenguaje, reglas y carrusel vigente.
- `PlantCareAI/Features/CareEvents/Domain/{CareEvent,CareEventRepository,RegisterCareEventUseCase}.swift`: cinco raws/siete campos/fecha inicio de día en origen/createdAt real/prealta permitido.
- `PlantCareAI/Features/PlantPhotos/Domain/{PlantPhoto,PlantPhotoRepository,LoadPlantPhotosUseCase,AddPlantPhotoUseCase}.swift`: misma temporalidad, identidad discriminada y descriptor carrusel por createdAt ASC.
- `PlantCareAI/Features/PlantList/Data/LocalPlantRepository.swift` (lecturas pertinentes): actor filtra plantID; eventos/fotos occurredAt DESC/createdAt DESC/UUID ASC; loadPhoto exige id+plantID; metadata sin JPEG.
- `PlantCareAI/Features/PlantDetail/{Presentation/PlantDetailView,Presentation/PlantDetailViewModel,Domain/LoadPlantDetailUseCase}.swift`: loaded/sheets/onDisappear; relectura Plant propia, nil distinto de throws.
- `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel}.swift`, `PlantCareAI/PlantCareAIApp.swift`: único NavigationStack/destino UUID/fábricas sin IO/inyección tras overrides Debug.
- `PlantCareAI/Features/PlantPhotos/Presentation/PlantPhotoPagerViewModel.swift`, `PlantCareAI/Features/LastWateringHint/Presentation/LastWateringHintViewModel.swift`: cache/generaciones/contexto/medianoche.
- `PlantCareAI.xcodeproj/project.pbxproj` (registro explícito), `PlantCareAITests/PlantPhotoPagerViewModelTests.swift` (seam real read-only), `PlantCareAIUITests/PlantCareAIUITests.swift` (búsqueda clases/selectores), `docs/testing-ui.md` (comandos E2E).

### Existing Patterns / Gaps

- SwiftUI iOS17+, Presentation→Domain←Data, Foundation-only Domain, recursos semánticos/español fallback, thumbnails ImageIO fuera de MainActor.
- No pantalla/caso de uso mixto existentes. Rutas UUID significan detalle: historial requiere tipo distinto.
- Referencias HTML aportadas en mensaje/contexto usuario, **no archivos/capturas inspeccionados**. No recursos remotos aprobados; no descargarlos.
- Investigación para planificación, no compilación/validación de código ni resultados nuevos de producto acreditados.

## Technical Approach

### Orden, día, zona y hito inicial

- **Confirmado usuario:** fecha del elemento determina su DÍA VISIBLE en zona actual; grupos por ese día DESC. Dentro del mismo día visible manda `createdAt DESC`, NO occurredAt, aunque los instantes sean distintos.
- Contrato inequívoco: `elementDate = CareEvent.occurredAt | PlantPhoto.occurredAt | Plant.createdAt (alta/inicial)`; `visibleDay = GregorianCalendar(timeZone: currentZone).startOfDay(for: elementDate)`. Orden final `(visibleDay DESC, createdAt DESC, stableKey ASC)`; agrupar por visibleDay y ordenar cada grupo con esas dos últimas claves. No sort absoluto final obligatorio ni occurredAt como desempate interno.
- Identidades: enum `care(UUID)`, `additional(UUID)`, `initial(UUID)`; stableKey `care-<uuidString>`, `additional-<uuidString>`, `initial-<uuidString>`. Evita colisiones aunque UUID coincida entre tipos. Alta usa Plant.createdAt también para desempate.
- occurredAt es instante de inicio del día elegido en zona IANA persistida, NO hora observada de cuidado/captura. No EXIF ni createdAt mostrado como fecha de fotografía.
- “Misma fecha” resuelto como MISMO DÍA MOSTRADO, no igualdad exacta de Date. Distintos orígenes/instantes en mismo día visible se ordenan solo por creación y clave estable; no preservar orden ocurrido del fetch. Sorts Data existentes y carrusel createdAt ASC no se modifican.
- Presentation posee agrupación/orden final mediante helper Foundation puro `PlantTimelineDateFormatter.groups(entries:now:timeZone:)` con contexto inyectado en VM (sin .current/Date() ocultos en helper). Retorna grupos con dayID/día/cabecera/entries ordenados. Hoy/Ayer según now; resto fecha española completa con año. Ayer calendario, no86400s. Día mostrado UNA SOLA VEZ como cabecera por grupo, también en lectura accesible; tarjetas de foto/cuidados/alta/errores no muestran ni repiten fecha de elemento/creación/hora.
- No reconstruir fecha civil de origen para mostrar ni migrar. Viaje puede cambiar día conforme contrato accepted;10oct añadida11oct agrupa10oct en misma zona. Conservar metadata original sin sort final absoluto; recalcular grupos Y orden final al cambiar zona/día/tiempo significativo/foreground/próxima medianoche, sin writes/relectura por cambio de contexto. Al cambiar zona pueden unirse/separarse grupos y cambiar orden relativo por createdAt; identidad y cache de imágenes no dependen del grupo/índice. Reloj retrocedido no invalida/oculta registros ahora futuros.
- Alta/inicial proyectada una vez en Plant.createdAt, no fila adicional persistida, sin zona de captura inventada. Tarjeta Planta añadida, miniatura inicial, Incorporada a PlantCare AI con foto inicial / Inicio del seguimiento.
- Nunca forzar alta última contra orden confirmado. Pie aceptado: si alta es último elemento de grupos aplanados, Has llegado al origen de este ejemplar; en cualquier otro caso, Has llegado al primer registro de este ejemplar (sin “cronológico”). Origen de seguimiento rotulado solo en alta. Recalcular condición tras reagrupar/reordenar por zona; no inferirla solo de comparar occurredAt.

### Capas y lectura

- `Features/PlantTimeline/Domain/PlantTimelineEntry.swift`: enum/payload no persistido, identidad/plantID/elementDate/createdAt, referencias a CareEvent/PlantPhoto/alta; reutilizar modelos, no copiarlos a SwiftData.
- `LoadPlantTimelineUseCase.swift`: protocolo `LoadPlantTimelineUseCase: Sendable` para seam VM y `LoadPlantTimeline` compuesto con LoadPlantDetail/CareEventRepository/PlantPhotoRepository. Relee Plant primero; nil→notFound; consulta metadata, verifica/filtra UUID propio y proyecta unión con alta, sin imponer sort absoluto final ni agrupación por zona global. No JPEG/writes/fallback de snapshot detalle. Throws de cualquiera→error, nunca publicar unión parcial. Domain conserva fechas/identidades originales; orden de entrada no es contrato visual.
- Lecturas secuenciales mismo actor bastan: sin promesa de snapshot transaccional/multiproceso. No escritores desde historial; reentrada/foreground refrescan. No protocolo agregado de repositorio sin necesidad.
- **Data:** reutilizar LocalPlantRepository intacto; PlantTimeline/Data solo fixture Debug Simulator si E2E requiere, no adaptador productivo nuevo.
- **Presentation:** `PlantTimelineView → PlantTimelineViewModel → LoadPlantTimeline → contratos existentes ← LocalPlantRepository`; vista sin Data. VM @MainActor idle/loading/loaded/failed/notFound, tarea/generaciones por sesión/UUID, metadata original y grupos derivados por helper Foundation con now/zone inyectables. Init/fábricas sin IO. Metadata antes de imágenes; errores sanitizados. Orden/agrupación/etiquetas de día pertenecen a Presentation, no a la vista ni a Data.
- Primera apertura/cada reentrada releen; foreground visible refresca una vez, deduplicar pending; retry explícito, sin polling/bucles. Refresh fallido→failed/Reintentar, no lista antigua presentada vigente/completa. Cambio de zona/día/tiempo recalcula grupos/orden/cabeceras sin IO; foreground conserva además su refresh de metadata previsto. Disappear cancela metadata/imagenes/timer/observadores/libera cache; tardíos protegidos por active+generation+identidad.

### Imágenes por demanda

- `PlantTimelinePhotoViewModel.swift`: loader central, estado por identidad idle/loading/loaded/failed; LoadInitialPlantPhoto/LoadPlantPhoto(id:for:) inyectados App; sin rutas ni fallback de otra planta.
- LazyVStack; fila visible solicita bytes propios, sin eager load/precarga de todas. VM central posee tareas/estados y cache LRU **máximo3 thumbnails ≤1600px**, sin JPEG retenido ni UIImage adicional en entry/VMs de filas.
- Decode ImageIO cancelable fuera de MainActor; máximo dos lecturas/decode en vuelo; al desaparecer fila cancelar solo petición propia. Cache reutilizable mientras sesión activa; evicción devuelve víctima a idle sin imagen retenida en otro published estado, sin hot-loop de recargas por eviction. Revisitar pide imagen ausente.
- Alta miniatura y adicional4:3 solo fotos locales. Error individual conserva grupo de día/tipo/espacio estable, No pudimos cargar esta foto y retry≥44pt, sin fecha propia repetida; retry no relee metadata. Deduplicar petición/decode por identidad. Reagrupación/reordenación no vincula bytes por índice ni duplica peticiones de identidad ya cacheada/en vuelo.
- Disappear sesión cancela/libera; no garantía de memoria constante de originales ni cancelación instantánea de IO síncrono ya iniciado. Placeholder loading distinto de error/ausencia.

### Push y lifecycle del detalle

- `PlantTimelineRoute: Hashable` con plantID en Presentation. NavigationLink(value:) detalle; `.navigationDestination(for: PlantTimelineRoute.self)` junto al UUID en PlantListView. Un stack, back/gesto nativos; nunca modal.
- App→PlantListViewModel fábrica `(UUID)->PlantTimelineViewModel`, destino StateObject propio, mismo actor tras overrides Debug, sin IO/snapshots como verdad en fábrica.
- Solo loaded muestra acceso. Orden actual exacto: paginador → identidad → Añadir foto/feedback → careRegistration → **Ver historial** → careSheet (equivalente actual de Guía Inteligente). No mover/renombrar resto ni fabricar bloques ausentes.
- **Confirmado usuario:** conservar foto seleccionada al regresar al detalle, tanto inicial como cualquier adicional/nueva confirmada. Revisar PlantDetailView.onDisappear y PlantPhotoPagerViewModel.disappear: push historial suspende trabajo visible sin resetear selección; back nativo/gesto restaura misma identidad. Separar suspensión temporal vs abandono real mediante flag/ruta/lifecycle explícito. Pop detalle a colección sí libera/resetea inicial. No eliminar cancelación general; conservar distinción sheet/cámara y guardas accepted.
- Nuevos commits se realizan en detalle mientras historial no visible: reentrada relee, sin cache global/copia/callback ficticio. Último riego conserva invalidación watering-only.

## Visual Design Impact

- UI sí; DESIGN y requisitos explícitos extraídos del HTML. Sin nuevo artefacto externo obligatorio.
- **Único cambio visual detalle:** card inset Surface blanca, radio≈16/padding16, clock.arrow.circlepath verde en SurfaceMuted≈44×44/radio12, Ver historial + Cuidados y fotografías, chevron discreto derecha. Fila completa NavigationLink≥44pt, textos adaptables; icono/chevron decorativos ocultos a accesibilidad.
- Historial de cuidados inline/back nativo, Background crema/márgenes≈20, encabezados Hoy/Ayer/fecha completa; línea vertical sutil Outline izquierda y nodos SF Symbols. Línea/nodos decorativos, no señal exclusiva del tipo.
- Tarjetas Surface radio≈16/padding16. Cuidados Riego/Abonado/Poda/Trasplante/Otro, nota literal íntegra si existe, sin Completado/Nutrición. Mapa Presentation explícito drop.fill/leaf.fill/scissors/arrow.triangle.2.circlepath/ellipsis.circle; comprobar símbolos visualmente.
- Fotografía adicional: título Fotografía e imagen grande4:3/radio suave; alta miniatura≈56/textos reales anteriores. **Fecha solo cabecera del grupo, una vez**, nunca en tarjeta foto/cuidados/alta/placeholder/error ni createdAt visible; sin hora falsa/comentario generado. Textos alta no interpolan fecha.
- Reutilizar tokens/acento local/SF Symbols/patrones thumbnail/error. Omitir barras web/status/menu/avatar/perfil/favoritos/salud/alertas/fuentes remotas y resto del HTML detalle; requisito textual fecha prevalece sobre agrupación errónea10→11oct.
- IDs: `detailHistory-UUID`, `plantTimeline-UUID`, `timelineDay-<yyyy-MM-dd>`, `timelineEntry-<stableKey>`, `timelinePhoto-<stableKey>`, `timelinePhotoError-<stableKey>`, `retryTimelinePhoto-<stableKey>`, `timelineError`, `retryTimeline`, `timelineNoRecords`, `timelineOriginFooter` solo cuando aplica. Español/fallback, targets≥44, soporte Dynamic Type/VoiceOver sin exigir matrices ampliadas.

## Expected File Changes — futuros, no realizados por planner

- Crear `PlantCareAI/Features/PlantTimeline/Domain/{PlantTimelineEntry,LoadPlantTimelineUseCase}.swift`.
- Crear `PlantCareAI/Features/PlantTimeline/Presentation/{PlantTimelineRoute,PlantTimelineView,PlantTimelineViewModel,PlantTimelinePhotoViewModel,PlantTimelineDateFormatter}.swift`; filas/grupos privados salvo reutilización real.
- Modificar `PlantCareAI/Features/PlantDetail/Presentation/{PlantDetailView,PlantDetailViewModel}.swift` y `PlantPhotos/Presentation/PlantPhotoPagerViewModel.swift` solo box/lifecycle suspensión push vs abandono.
- Modificar `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel}.swift`, `PlantCareAI/PlantCareAIApp.swift`: ruta/fábrica/inyección; ContentView intacto.
- `PlantCareAI/Localizable.xcstrings`: solo nuevas claves usadas españolas/fallback, previas intactas; Assets solo token realmente ausente, sin imagesets.
- Crear `PlantCareAITests/{LoadPlantTimelineTests,PlantTimelineViewModelTests,PlantTimelinePhotoViewModelTests,PlantTimelineDateFormatterTests}.swift`; seam real read-only en LoadPlantTimelineTests y extender lifecycle tests detalle/paginador.
- `PlantCareAIUITests/PlantCareAIUITests.swift`: PlantTimelineUITests; eventual `Features/PlantTimeline/Data/PlantTimelineTestFixture.swift` Debug Simulator/UUID opt-in, seed/read real store, doubles solo demoras/fallos. No sidecar como historial/counter de verdad/API real.
- `PlantCareAI.xcodeproj/project.pbxproj`: registro explícito app/tests, IDs únicos. LocalPlantRepository/modelos/schema/init.sh sin cambios productivos previstos; justificar delta inesperado antes de implementarlo.

## Durable Documentation Impact

- **Ahora:** spec + mínima entrada planner PROGRESS/feature_list; no reescribir accepted specs/evidencias históricas.
- **Después de aprobación/implementación:** ARCHITECTURE update módulo/ruta/mismo actor/lifecycle y proyección Domain sin sort visual final/agrupación Presentation con contexto; docs/domain-model update día visible DESC/createdAt DESC/key ASC, independiente sorts Data/carrusel, alta/prealta/pie aprobado, sin borrar antecedentes.
- DESIGN update box/pantalla/estados aceptados; docs/risks-and-open-questions update temporalidad/cache/snapshot/lifecycle; docs/testing-ui update y crear docs/testing-plant-timeline.md selectores/fixtures/comandos; PROGRESS/feature_list según rol/evidencia real.
- CONSTRAINTS: no necesario, sin regla operativa global nueva. AGENTS: no necesario, workflow intacto. CONTEXT/brief: no necesario, alcance previsto.
- ADR nuevo no necesario al reutilizar fronteras accepted sin storage/contrato transversal nuevo. Cambio inesperado de contrato compartido: detener/proponer ADR/alinear ARCHITECTURE, no alterar ADR011 silenciosamente.

## Implementation Plan / Tasks — solo tras aprobación humana

1. [ ] Obtener aprobación humana INTEGRAL y congelar spec; empate día visible/pie/lifecycle ya resueltos, no autorización implementer. Corroborar worktree/rama/base/baseline relevante sin gate automático.
2. [ ] Implementar Domain unión/identidad/read use case sin sort visual final obligatorio y tests; UUID propio/no bytes/no writes/throws/alta única/prealta.
3. [ ] Implementar VM metadata/helper de grupos-sort por día visible/contexto y loader fotos acotado/cancelación; tests inversión occurredAt-createdAt, zona, cabecera única/tardíos/cache/errores/refresco.
4. [ ] Componer mismo actor/fábrica/push/box y lifecycle suspend vs abandon; regresiones selección accepted.
5. [ ] Implementar pantalla/estados/localización, registrar fuentes/fixtures y E2E persistencia/navegación/orden/aislamiento/error.
6. [ ] Actualizar docs aprobadas; diff→riesgos→selección; verificación focalizada/visual/handoff passing solo con evidencia. Validator/gate final separados.

## Verification Plan — futura, nada ejecutado por planner

### Implementer: por impacto

- Domain → LoadPlantTimelineTests: cinco tipos+fotos/inserción invertida/fechas originales10oct11oct/UUID igual entre tipos/alta-prealta/no eventos/error cada fuente/no fallback ni bytes; comparar contenido/identidad/fechas, sin exigir sort absoluto como resultado visual final.
- Persistencia → seam real dos UUID/modelos y JPEG exactos antes/después/reopen sin reseed, contador beforeCommit sin incremento al leer/scroll/retry/refresh tras setup. No migration test redundante si Data/schema intactos.
- VM/helper/contexto/fotos → nuevas clases VM/formatter: día visible DESC/createdAt DESC/key ASC; inversión occurredAt vs createdAt dentro del mismo día (incluyendo zonas origen distintas), empate creación con Date distintos/clave estable, grupos10oct11oct correctos y alta no forzada última/pie exacto. Cambio zona une/separa grupos y puede invertir orden relativo; comprobar reordenación/pie/identidades/cache sin writes ni IO por contexto, DST/medianoche/reloj. Además loading/failed/notFound/retry/refresh/cancel/tardíos, metadata antes de bytes, error imagen propio/cache≤3/sin UIImage extra/≤2 in-flight/no eager JPEG/decode cancel/A→B→A, clock-zone-sleep inyectables, no reloj global simulador.
- Navegación → PlantDetailViewModelTests/PlantPhotoPagerViewModelTests y PlantTimelineUITests: push/back nativo/gesto, misma selección inicial/adicional/nueva retroactiva antes/después historial, salida real/reentrada inicial, dos plantas/cinco tipos/notas largas/fotos orden exacto/relaunch/no cuidados/solo alta/errores/scroll/reapertura tras commit/fallback. UI exige una cabecera por día y ausencia de fecha/hora/createdAt repetidos en tarjetas de foto/cuidado/alta/errores y sus etiquetas accesibles (sin prohibir fechas que usuario escribió libremente en nota); no reducir aserciones a existencia global de la fecha.
- Regresiones por diff: AddPlantPhotoUITests (especialmente SuccessivePhotosRetroactiveSelectionPagerSwipeAndRelaunchIsolation), CareEventsUITests commit/cancel, PlantCardsUITests selección, StoredCollectionUITests detalle, EditPlantUITests, LocalizationUITests. Elegir métodos afectados, no todas por rutina; Fotos real no focal si picker intacto, gate validator lo conserva.
- E2E persistente XCUITest obligatorio para flujo observable, no sustituirlo solo por unitarias. Ejemplo focalizado, ajustar al diff final y registrar comando exacto:

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/LoadPlantTimelineTests \
  -only-testing:PlantCareAITests/PlantTimelineViewModelTests \
  -only-testing:PlantCareAITests/PlantTimelinePhotoViewModelTests \
  -only-testing:PlantCareAITests/PlantTimelineDateFormatterTests \
  -only-testing:PlantCareAIUITests/PlantTimelineUITests test
```

- Visual básico focalizado box/mixto/fotos/alta-prealta/error/nota larga: único simulador estándar/texto normal/una apariencia, capturas con configure-ui-test-environment.py valor1 y -only-testing según docs/testing-ui; no repetir suite para capturas.
- Futuros estáticos: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON/claves únicas/traducciones previas/imports Domain Foundation-only, `git diff --check`. Antes de build plantilla pública vacía solo si config Debug falta, nunca leer/overwrite real; coordinar simulador/no competidores. No prepararlo en planner.
- Reutilizar baseline válido mismas fuentes/config/destino, sin atribuir234/234 histórico a fuentes nuevas; si falta, diagnóstico/build focalizado. Fallos conservados; reparar y repetir fallido/callers afectados bajo hipótesis, sin retries para verde.

### Validator: gate final

- Un `caffeinate -dius ./init.sh` sobre fuentes finales: build-for-testing/unit-UI paralelas/Fotos serial, o corroborar gate válido exacto mismo estado/entorno. No duplicar focales cubiertas salvo laguna concreta.
- Script existente ejecuta checks y termina, sin servidores persistentes/cambios necesarios. Reparación ejecutable que invalida evidencia exige gate nuevo justificado después de focales fallidas/afectadas; gate fallido nunca aprobado.
- Planner documental solo consistencia, no suite iOS. SE/pantallas pequeñas/texto aumentado/VoiceOver/Inspector/matrices extra fuera habitual, no ejecutadas ni bloqueos por defecto; soporte conservado.

## Evidence To Capture / Validator Checklist

- [ ] Scope/escenarios aprobados, capas/composición/fábricas sin IO/UUID propio/sin persistir historial ni red/carrusel createdAt ASC intacto.
- [ ] Día visible de elementDate DESC/createdAt DESC/key ASC, sin occurredAt desempate interno; cabecera día única/sin fechas repetidas por tarjeta,10oct11oct/alta única/prealta/pie exacto y reagrupación-reordenación de zona sin writes/sorts Data-carrusel intactos.
- [ ] Push/back nativo/solo box, selección conservada al volver/salida definitiva limpia; sin acciones ficticias/HTML remoto.
- [ ] Vacío distinto error, imagen error/retry propios, refresh/cancel/tardíos/cache/inflight con pruebas reales y doubles identificados.
- [ ] Comando/selección→riesgo/fuentes-config-destino/exit-log-xcresult/IDs-tests/capturas realmente inspeccionadas; nuevos vs reutilizados/fallos conservados; no secretos/datos personales en logs.
- [ ] Docs/harness coherentes; passing solo autoverificación, accepted independiente+gate válido. Gate final pendiente validator; ninguna ejecución de producto por planner.

## Review Gate / Open Recommendations

Siguiente exclusivo: **revisión humana INTEGRAL**, no implementer autorizado. Tres dudas cerradas por usuario: MISMO DÍA VISIBLE y fecha una sola vez en cabecera (interior createdAt DESC/key ASC, no occurredAt), pie Has llegado al primer registro de este ejemplar cuando alta no sea último, y SÍ conservar foto seleccionada al regresar. Sustituyen propuestas previas de igualdad Date exacta/pie “cronológico”; sin dudas funcionales pendientes sobre esas tres decisiones. Push/box acotado/orden confirmado siguen obligatorios. Estas confirmaciones NO equivalen a aprobación integral ni permiso implementar/validar.
