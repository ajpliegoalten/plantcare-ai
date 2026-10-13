# Feature Implementation Spec: analizar una fotografía con contexto propio

## Source Feature

- `id`: `analyze-current-photo`; `area`: `analisis-ia`.
- `depends_on`: `plant-timeline`, `external-ai-consent`, `save-plant`: los tres `accepted` en `feature_list.json`, con evidencia independiente registrada.
- `status`: `not_started`; fuente: `feature_list.json`.
- Borrador planner ONE STEP, 2026-10-13, revisado con respuestas del usuario. **Q1 y Q2 resueltas; pendiente revisión humana integral, no aprobada por responder preguntas; no autoriza implementación.**
- Worktree único: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/analyze-current-photo`.
- Rama/base comunicadas por padre: `feature/analyze-current-photo`, `6b3c82ba63620f0f65e200e9cc68176508d2709b`; no comprobadas mediante Git en este paso.

## Goal / Job Story

Cuando consulto cualquier foto de mi ejemplar en el paginador o historial, quiero solicitar observaciones prudentes sobre **esa foto**, con especie/ficha, cuidados anteriores a su fecha y análisis aceptados textuales de fotos anteriores exclusivamente de esa planta, y leer el resultado en un modal sin guardarlo automáticamente. Solo se envía la imagen seleccionada; los textos aceptados se incorporarán cuando exista su lector real, no se inventan ahora.

El usuario exige: acceso desde cualquiera de las fotos del paginador y desde acciones en fotos del timeline; no lanzar si la foto ya tiene análisis; modal similar a Editar planta/Registrar cuidado, con cabecera, estados y resultado; botones aceptar/descartar visibles, **sin ejecutar todavía sus acciones**. No habrá pantalla/adjunto de diseño adicional.

## Non-Goals / Users And Permissions

- Único usuario local; sin cuentas, roles remotos, backend, sincronización, chat ni preguntas de seguimiento.
- No alta de fotos, captura/galería, reidentificación, cambio de especie/ficha, evento de cuidado ni modificación de portada.
- No persistencia de análisis, migración SwiftData, duplicación de fotos/hitos ni implementación de `keep-analysis` / `discard-analysis`.
- No comparar imágenes antiguas, inferir evolución visual, porcentajes inventados, diagnóstico definitivo o fuentes verificadas inexistentes.
- `recover-ai-failure` será dueña de la revisión transversal de fallos; esta feature necesita error/cancelación/retry propios mínimos, no adelanta aquella auditoría.
- Leer foto local no requiere permisos de cámara/Fotos; envío externo solo tras intención y autorización del alcance vigente.

## Decisiones confirmadas y pendientes

### Q1 — resuelta por usuario: solo el análisis definitivo cuenta

El código actual **no tiene entidad, campo ni lector de análisis guardados**. `PlantPhoto` contiene siete campos sin análisis; inicial es `.initial(plantID)`, no una fila adicional. `keep-analysis` aún no está iniciada.

El usuario confirma: un resultado **provisional NO cuenta** como «ya tener análisis». Vive únicamente en el modal y se elimina al salir; no cache retenida para reabrir ni guard por provisional fuera del modal. Reabrir una foto sin análisis definitivo permite una nueva solicitud explícita.

Aceptar en la futura feature lo convierte en definitivo; rechazar lo descarta. **Ambos botones siguen sin funcionalidad en analyze-current-photo**: no aceptar, persistir, rechazar ni cerrar por ellos ahora. ×/Cancelar/gesto se proponen como cierres técnicos que cancelan la operación y liberan el provisional sin guardar ni borrar la foto origen.

Mantener guard de solicitudes simultáneas por `(plantID, identity)` y de modal activo, independiente de si existe resultado provisional. Fallo/cancelación no son análisis definitivo; mismo JPEG en identidades distintas no deduplica. Nunca usar un Boolean persistido ni un adaptador vacío presentado como persistencia real. Cuando exista `keep-analysis`, su lector real aportará la elegibilidad definitiva y el contexto previo; no construir ese almacén ahora. Esta decisión sustituye la propuesta anterior de provisional compartido/retenido durante la sesión del ejemplar.

### Q2 — resuelta por usuario: análisis aceptados textuales y cuidados anteriores

Ahora se permite analizar **cualquier** foto, incluida inicial o retroactiva; «actual» significa seleccionada, no necesariamente tomada hoy.

El usuario precisa su respuesta «Usar contexto de las fotos anteriores»: significa **sus análisis ACEPTADOS textuales, SIN enviar imágenes anteriores**. También confirma **solo cuidados ANTERIORES a la fecha de la foto analizada**, excluyendo posteriores. No existe autorización de JPEG históricos ni comparación visual; se elimina la pregunta bloqueante Q2.

Los análisis previos se seleccionan/ordenan por **fecha de su foto asociada**, no por fecha de generación/aceptación/guardado como si fuera captura. Solo textos definitivos de fotos anteriores propias; nunca provisionales, textos de fotos posteriores ni el resultado de la foto consultada. Una aceptación realizada después de la fecha de la foto seleccionada no cambia la fecha de la foto origen: es texto retrospectivo de IA, no un hecho conocido entonces. `keep-analysis` aportará su lector real cuando exista; no inventar filas/textos anteriores ni un adapter vacío que aparente persistencia.

**Regla técnica propuesta para revisión integral, no decisión humana sobre empates:** usar día gregoriano en una zona de referencia capturada e inyectada por intención (propuesta: zona actual al abrir modal), igual para foto seleccionada y registros. Solo días estrictamente anteriores; excluir el mismo día porque las fechas de adicionales/cuidados son date-only y no prueban orden de captura/acción. Inicial usa fecha de alta proyectada, no EXIF ni hora de captura inventada. Dentro de los elegibles ordenar fotos por photoDate DESC/identidad estable ASC para empate exacto, nunca acceptedAt; cuidados por occurredAt DESC/createdAt DESC/identidad estable ASC. La zona/calendario permanecen constantes durante la intención/retry; no depender del orden visual del timeline/pager. La exclusión conservadora del mismo día y su zona son propuestas explícitas no bloqueantes, revisables al aprobar la spec; no queda duda funcional bloqueante.

### Handoff confirmado a `keep-analysis` (feature futura)

- El análisis **aceptado/definitivo** se mostrará en el timeline **DEBAJO de su foto asociada**, similar a los textos opcionales de los cuidados, dentro del hito de esa foto sin duplicarla.
- `keep-analysis` será dueña de aceptación explícita, persistencia/vínculo, lector de elegibilidad definitiva y render del texto aceptado bajo la foto. `discard-analysis` será dueña del rechazo explícito sin conservar análisis ni borrar una foto origen ya local.
- Ese lector futuro entregará textos aceptados y fecha/identidad de su foto origen para contexto anterior de la planta. Conservar fecha de foto separada de generación/aceptación; filtrar/ordenar por la primera y aplicar los presupuestos del constructor. No leer JPEG históricos. Su implementación y pruebas con disco pertenecerán a keep-analysis; aquí solo contratos puros/seams sintéticos del contexto futuro, sin nuevas entidades persistidas.
- `analyze-current-photo` entrega resultado provisional ligado a identidad discriminada/plantID para ese handoff; no crea entidades, aceptación, escritura ni render de datos definitivos inexistentes. Esta decisión futura está confirmada, pero no aprueba íntegramente esta spec ni autoriza roles siguientes.

### Propuestas no bloqueantes para revisión integral

- Acción textual «Analizar foto» con SF Symbol sparkles, debajo de controles del pager; en cabecera de fotos del timeline, separada de papelera. Incluir inicial en ambos accesos.
- Cabecera PlantFormHeader con nombre y especie, snapshot de **foto seleccionada** (56 pt), más preview propia 4:3 y fecha. Editar/cuidado/añadir foto mantienen su cabecera inicial accepted.
- Resultado: «Aceptar análisis» / «Descartar análisis» deshabilitados, ayuda «Estas acciones estarán disponibles en una próxima versión». Nunca enabled con no-op, confirmación falsa, dismiss, escritura o eliminación. ¿Se prefieren otras etiquetas? `keep-analysis` usa «Guardar» en su contrato; aceptar aquí no confirma botánica.
- ×/Cancelar/gesto son cierres técnicos propuestos del modal, no la futura acción «Descartar»: cancelan tareas y liberan siempre el provisional, sin guardar ni borrar la foto ya local. Reabrir no restaura resultado.
- Límites de contexto/salida de abajo son propuesta técnica revisable, no elección ya aprobada.

## Acceptance Scenarios (Given / When / Then)

1. **Paginador**: Dada inicial o adicional propia seleccionada, cuando pulso Analizar foto, entonces abre el modal para esa identidad exacta; no usa índice ni portada como sustituto. Selección al cerrar/back sigue intacta.
2. **Timeline**: Dada una fila de foto adicional o alta/inicial, cuando pulso su acción, entonces abre el mismo flujo para esa foto, sin navegar al detalle ni eliminarla. Una fila cuidado no tiene acción de análisis.
3. **Análisis definitivo / provisional**: Dada foto con análisis definitivo, cuando intento analizar desde cualquiera de las entradas o programáticamente, entonces cero peticiones nuevas; un fake de elegibilidad definitiva prueba ese guard futuro sin simular disco inexistente. Dado solo provisional, cuando cierro y reabro, entonces no se restaura y se permite una nueva solicitud explícita. Dada petición en curso, doble tap/otra entrada no lanza una simultánea; no convertir este guard en bloqueo persistente por provisional.
4. **Consentimiento**: Dada aceptación v4 previa o ninguna, cuando inicio este nuevo envío de contexto, entonces el aviso renovado muestra destino/modelo/foto/contexto pertinente; rechazar/cerrar o fallar registro implica cero HTTP. Aceptar despacha una vez; intención posterior del mismo alcance no repite aviso indebidamente.
5. **Aislamiento**: Dadas dos plantas, cuando solicito para cada una, entonces cada payload lleva exactamente un JPEG propio seleccionado y texto propio; ningún JPEG histórico, otra planta, UUID interno, clave o chat. Un fallo de lectura nunca se presenta como contexto vacío.
6. **Espera/resultado**: Dada solicitud autorizada, cuando espera, entonces foto/cabecera y estado no conversacional siguen visibles; éxito presenta observaciones, causas posibles y comprobaciones completas, prudentes, provisionales, sin autoescritura.
7. **Fallos/cancelación**: Dados config inválida, foto ausente/corrupta, lectura fallida, timeout/red/rechazo/JSON inválido, cuando ocurren, entonces error distinguible y siguiente acción explícita; retry una vez por intención, nunca automático. Cierre/cancelación invalida tareas y respuestas tardías; no restaura borrador tras relanzar.
8. **Controles futuros**: Dado resultado, cuando inspecciono los dos botones, entonces están visibles/inactivos y explicados; no guardan, borran, cierran ni cambian historial/JPEG/último riego.
9. **Sin huella local de producto**: Dadas fotos y cuidados existentes, cuando consulto, cancelo, fallo o cierro resultado y relanzo, entonces modelos, bytes y cronología siguen exactos; solo la preferencia de consentimiento puede cambiar por aceptación explícita.
10. **Contexto anterior/textos largos**: Dada foto retroactiva y cuidados previos/posteriores, cuando construyo payload, entonces solo entran anteriores a la fecha de esa foto, nunca posteriores. Dados análisis aceptados sintéticos de fotos anteriores y posteriores, cuando construyo contexto, entonces solo entran textos propios de fotos anteriores, ordenados por fecha de foto incluso si su aceptación fue posterior; ningún JPEG histórico ni provisional. Empates/date-only aplican la regla técnica propuesta de día estrictamente anterior tras aprobarla. Payload cumple presupuestos y textos/acciones UI son alcanzables en simulador estándar sin cambiar tamaño de texto. Hoy, sin lector real de análisis guardados, no se fabrica ese historial: contexto previo de análisis vacío por capacidad inexistente, no por fallos ignorados.

## Repository Research

### Files Inspected

- `AGENTS.md`, skills `feature-spec` (incluido template) e `ios-clean-mvvm`, `PROGRESS.md` (sección reciente), `feature_list.json` (dependencias/features futuras), `ARCHITECTURE.md`, `CONSTRAINTS.md`.
- `CONTEXT.md`, `DESIGN.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, ADR004/006/011: privacidad, orientación, identidad y contratos actuales.
- `PlantCareAI/Features/PlantList/Domain/Plant.swift`: especie plana confirmada, nombre/ubicación, seis cuidados; procedencia manual/IA no persistida: no inventarla.
- `Features/PlantPhotos/Domain/{PlantPhoto,PlantPhotoRepository,LoadPlantPhotoUseCase}.swift` y `Features/PlantTimeline/Domain/{PlantTimelineEntry,LoadPlantTimelineUseCase}.swift`: identidad discriminada/pertenencia, lecturas secuenciales propias sin snapshot transaccional.
- `Features/PlantPhotos/Presentation/PlantPhotoPagerView.swift`, `Features/PlantDetail/Presentation/PlantDetailView{,Model}.swift`, `Features/PlantTimeline/Presentation/PlantTimelineView.swift`; símbolos de TimelineVM: sheets, selección, push/back, viewport/hit-testing y eliminación existentes.
- `Features/EditPlant/Presentation/EditPlantView.swift`, `Features/CareEvents/Presentation/RegisterCareView.swift`, `Shared/Presentation/PlantFormHeader.swift`: modal blanco, scroll, toolbar, snapshot y controles ≥44.
- `Features/ExternalAIConsent/{Domain/AuthorizeExternalAIOperationUseCase,Presentation/ExternalAIConsentView}.swift`, `Features/IdentifyCandidates/Data/{IdentificationAPIConfiguration,OpenAICompatibleSpeciesIdentificationRepository}.swift`, `Features/GenerateCareSheet/Data/OpenAICompatibleCareSheetGenerationRepository.swift`: alcance v4, aviso y límites reales.
- `PlantCareAIApp.swift`, inicio de `project.pbxproj`, `init.sh`, `docs/testing-ui.md`, inicios de `PlantPhotoPagerViewModelTests.swift` / `ExternalAIConsentTests.swift`: composición y seams/comandos. LocalPlantRepository solo búsqueda de métodos; no auditoría completa del actor en este planner.
- Búsqueda `Analysis|analysis|analy` en Swift de producto: sin coincidencias; no spec previa para análisis. Los nombres nuevos abajo son propuestos, no archivos existentes.

### Existing Patterns / Gaps

- SwiftUI iOS17+, dependencias Presentation → Domain ← Data; fábricas sin IO, composición App después de overrides Debug, registro PBX explícito.
- Cache de thumbnails ≤3 /1600px y timeline IO/decode concurrente≤2; thumbnails UI no son los bytes a enviar. No montar tareas remotas por página/fila/onAppear.
- Aviso v4 solo declara identificación/ficha; **no autoriza silenciosamente historial/notas/ubicación**. ExternalAIConsentView usa cuerpo fijo: precisa nueva variante, no copy de identificación erróneo.
- No análisis guardados ni lector de ellos ahora. Contexto previo de análisis será vacío porque la capacidad no existe, no porque un fallo de lectura se ignore.

## Technical Approach (Q1/Q2 confirmadas; detalles técnicos propuestos para revisión integral)

### Domain — `Features/AnalyzeCurrentPhoto/Domain`

- Un resultado efímero `PlantPhotoAnalysis` (plantID + PlantPhotoIdentity + revisión/fecha de consulta + tres arrays de textos); no `@Model`, rutas, UIImage ni procedencia botánica inventada.
- `AnalyzePlantPhotoUseCase` y `PlantPhotoAnalysisRepository`: validar identidad/pertenencia/elegibilidad; leer Plant/contexto metadata con lectores existentes y **solo** bytes iniciales o adicionales de la foto elegida. Errores locales antes de red; rechazo nunca éxito parcial.
- `BuildPlantAnalysisContext` puro: especie confirmada/ficha, ubicación opcional como condición aportada y foto/consulta fechadas; no enviar nombre personalizado/UUID ni cronología completa por defecto. Filtrar ANTES del recorte por fecha de foto seleccionada: cuidados anteriores y análisis ACEPTADOS textuales de fotos anteriores, según decisión Q2 y regla date-only propuesta. Parámetros explícitos calendario/zona de intención; no reinterpretar ficha/ubicación actuales como condiciones históricas demostradas.
- Presupuesto técnico propuesto: hasta20 cuidados de últimos90 días ANTERIORES al día de foto seleccionada, no respecto a hoy, orden occurredAt DESC/createdAt DESC/identidad estable ASC. Hasta5 análisis textuales aceptados de fotos anteriores más próximas, sin límite de90 días para ellos, orden photoDate DESC/identidad estable ASC; conservar vínculo/fecha de foto en DTO sin UUID en payload. No ordenar/seleccionar por aceptación ni incluir provisionales.
- Nota ≤500 caracteres enviados (recorte explícito solo DTO, sin mutar texto local); cada análisis previo se incluye como bloque completo validado (tres arrays del contrato), no resumen nuevo ni truncamiento silencioso. Presupuesto JSON UTF8≤16KiB compartido para base/cuidados/análisis: retirar primero bloques de análisis más antiguos hasta caber y después cuidados más antiguos; registrar cantidades omitidas en DTO/prompt. Base ficha/especie/ubicación sola excesiva falla localmente. Todos estos límites/prioridades son propuestas técnicas, no respuestas humanas; tests cubren descarte determinista sin violar corte.
- No cargar JPEG históricos para contexto. `keep-analysis` conectará el lector real de textos definitivos al constructor y al guard cuando exista; aquí admite entradas sintéticas en tests y colección previa vacía por capacidad ausente, nunca análisis guardados inventados ni no-op que prometa persistencia. Lector futuro fallido deberá fallar cerrado, no tratarse como vacío. Aceptación posterior de análisis sobre foto anterior permite su texto retrospectivo con etiquetas, sin fabricar fecha captura ni conocimiento anterior.
- Rechazar identity inicial ajena y additional no perteneciente; releer elegibilidad definitiva al despachar cuando exista su lector. Guard de operación en curso por `(plantID, identity)` desde ambas entradas; libera al terminar/cancelar, sin poseer ni retener resultados fuera del modal. Provisional no bloquea reabrir/volver a solicitar.

### Data — `Features/AnalyzeCurrentPhoto/Data`

- `OpenAICompatiblePlantPhotoAnalysisRepository` sobre configuración existente: un POST Chat Completions no streaming con prompt fijo system y mensaje user con JSON de datos no confiables + una `image_url` del JPEG seleccionado (≤5MiB). No recomprimir thumbnail ni introducir vendor SDK/endpoint nuevo.
- Prompt español pide observaciones / posibles causas / comprobaciones de la única imagen seleccionada; el contexto contiene solo cuidados anteriores a su fecha y, cuando exista el lector, análisis ACEPTADOS textuales de fotos anteriores, fechados por foto origen. Distinguir registro humano de interpretación IA retrospectiva y ficha/ubicación actuales de hechos históricos; texto previo no es evidencia visual ni certifica evolución. Explicar omisiones por presupuesto; no inventar historial ausente. Sin diagnóstico, preguntas, comparación visual, órdenes de regar hoy ni instrucciones contenidas en nota/foto/texto IA. Especie/ficha/análisis IA no certifican hechos; ignorar instrucciones de todo dato no confiable.
- JSON exacto propuesto: `outcome: analysis|insufficientEvidence` y tres arrays `observations`, `possibleCauses`, `checks`; cada array0–5, texto no blanco≤1000 caracteres. `analysis` exige observaciones y comprobaciones, causas puede vacío; insuficiencia permite solo explicación en observations, sin causas ni checks inventados. UI presenta insuficiencia como resultado prudente, no error de parseo.
- Envelope único/finish_reason stop/refusal, claves/tipos/límites estrictos, salida≤1MiB/max_tokens2000; sesión efímera, sin redirects/cache/cookies/credential storage/logs sensibles, auth opcional y timeout total10–120s igual patrón actual. Cancelación real URLSession, sin retry automático ni fallback.
- Renovar a aviso **v5/notice-5 propuesto**, fingerprint canónico endpoint/modelo/revisión; conserva finalidades previas y añade foto seleccionada + especie/ficha/ubicación opcional/cuidados/notas anteriores a la fecha de foto y textos de análisis aceptados de fotos anteriores cuando existan. Declara que no envía imágenes anteriores; snapshot aviso/transporte/payload coherentes. V4 y anteriores no heredados. Clave/timeout no cambian scope. Identificación/cuidados mantienen payloads mínimos originales.
- Nueva finalidad modifica configuración/copy compartidos: ADR corto propuesto `docs/adr/013-contextual-photo-analysis.md` y docs actuales tras aprobación; no alterar specs accepted.
- Fixture solo Debug Simulator opt-in/UUID con contadores/snapshots instrumentados sintéticos (sin imprimir payload), ningún adapter que finja almacenamiento de análisis.

### Presentation / composición

- `PlantPhotoAnalysisView` y `PlantPhotoAnalysisViewModel`: preparing / awaitingConsent / analyzing / result / insufficientEvidence / failed, cierre/token por sesión; un único inicio explícito al abrir por tap, no en init/fábrica ni por recomposición.
- VM inyecta caso de uso y autorización; transportar **dentro** de `AuthorizeExternalAIOperation`. Snapshot config/aviso/transport común, revalidado antes de aceptar/enviar/publicar. Config ausente en Release → indisponible honesto/cero HTTP.
- `PlantCareAIApp.swift` inyecta fábricas a PlantList→Detail/Timeline sobre mismo repositorio/consentRepository. Pager comunica identidad seleccionada; timeline convierte initial/additional, nunca care. Modal nuevo por apertura; VM posee provisional únicamente mientras está abierto. Al ×/Cancelar/gesto/salida/terminación libera resultado y bytes, cancela tareas/invalida tokens y no deja cache para reabrir.
- Sheet nueva no resetea selección ni activa abandono del detalle/timeline; separar cobertura por sheet de salida real, cancelar loaders ocultos cuando proceda sin eliminar metadata/resultados de otro UUID. No cerrar mientras espera por un flag de commit: aquí no hay commit local.
- Timeline bloquea lanzar durante confirmación/delete/busy o modal ya activo. Al desaparecer origen/cambiar sesión, ignorar respuesta tardía; no permitir análisis de identidad eliminada con snapshot UI viejo.

## Expected File Changes (implementación futura, no cambios de este paso)

- Crear `PlantCareAI/Features/AnalyzeCurrentPhoto/Domain/{PlantPhotoAnalysis,BuildPlantAnalysisContext,AnalyzePlantPhotoUseCase,PlantPhotoAnalysisRepository}.swift`.
- Crear `.../Presentation/{PlantPhotoAnalysisView,PlantPhotoAnalysisViewModel}.swift`; ninguna sesión/cache de resultados compartida entre aperturas. Si hace falta coordinación entre entradas, limita su propiedad a modal activo/solicitudes simultáneas, no provisionales retenidos.
- Crear `.../Data/{OpenAICompatiblePlantPhotoAnalysisRepository,PlantPhotoAnalysisTestFixture}.swift`.
- Modificar `PlantCareAIApp.swift`, `Features/PlantList/Presentation/PlantListViewModel.swift`, `Features/PlantDetail/Presentation/PlantDetailView{,Model}.swift`, `Features/PlantPhotos/Presentation/PlantPhotoPagerView.swift`, `Features/PlantTimeline/Presentation/PlantTimelineView{,Model}.swift`: inyección/intenciones/sheet/lifecycle, no reordenar datos.
- Modificar `Features/IdentifyCandidates/Data/IdentificationAPIConfiguration.swift`, `Features/ExternalAIConsent/Presentation/ExternalAIConsentView.swift`, `Localizable.xcstrings`: scope/copy finalidades/estados y controles locales. No editar secretos/config real ni `init.sh`.
- Crear `PlantCareAITests/{BuildPlantAnalysisContextTests,AnalyzePlantPhotoTests,PlantPhotoAnalysisViewModelTests,OpenAICompatiblePlantPhotoAnalysisRepositoryTests}.swift`; ampliar configuración/consentimiento y callers/lifecycle afectados.
- Añadir `AnalyzeCurrentPhotoUITests` en `PlantCareAIUITests/PlantCareAIUITests.swift` y registrar fuentes/targets nuevos en `PlantCareAI.xcodeproj/project.pbxproj`.
- No cambiar PersistedPlant/PersistedPlantPhoto/schema/LocalPlantRepository para guardar análisis.

## Visual Design Impact

- UI sí; fuente `DESIGN.md` y modales reales inspeccionados, sin nuevo artefacto de diseño necesario.
- Sheet blanca, NavigationStack local/toolbar «Analizar foto» y Cancelar, grabber/radio24/detent0.95, scroll/margen20/spacing16; header SurfaceMuted/radio12, preview 4:3 recortada/hit-region acotada. No formulario de cuidados ni selección de especie.
- Progreso «Preparando contexto…»/«Analizando foto…», foto visible, error local/remoto legible/Reintentar; resultado en tres secciones completas, aviso orientativo/provisional y controles futuros según propuesta anterior. Sin interfaz conversacional/toast ni fecha nueva falsa de captura.
- Objetivos≥44pt, símbolos decorativos AXhidden, controles independientes y textos españoles/fallback; preservar Dynamic Type/código adaptable. Una fecha de foto en modal no modifica regla de fechas únicas de las filas timeline.

## Durable Documentation Impact (al implementar tras aprobación)

- `ARCHITECTURE.md`: update — nueva feature/capas, sesión/contexto/consentimiento y límites de readers.
- `CONSTRAINTS.md`: update — alcance renovado y ninguna persistencia de resultado por éxito remoto; guard de análisis existente aprobado.
- `AGENTS.md`: not needed — workflow/gates sin cambio.
- `CONTEXT.md`: not needed — conceptos ya definidos; `DESIGN.md`: update — acciones/modal y controles temporalmente inactivos.
- `docs/build-brief.md`, `docs/domain-model.md`: update — Q1/Q2 confirmadas, provisional solo modal, contexto de textos aceptados de fotos anteriores y solo cuidados anteriores; regla técnica date-only/empates tras revisión, sin JPEG históricos ni aceptación usada como captura. Handoff de texto definitivo bajo foto/lector real a keep-analysis, sin adelantarlo aquí.
- `docs/risks-and-open-questions.md`, ADR013: update/create — presupuestos, semántica temporal, nueva finalidad y riesgo provisional/guard futuro. Documentar sin prometer calidad botánica ni privacidad remota.
- `docs/testing-analyze-current-photo.md`: create; `docs/testing-ui.md`: update — escenarios/selectores reales, sin regenerar informes de rendimiento.
- `PROGRESS.md`/`feature_list.json`: evidencia real por rol; planner solo notas, status/evidence intactos.

## Implementation Plan / Tasks (no autorizadas aún)

1. Obtener revisión/aprobación ÍNTEGRA de spec/copy/presupuestos y regla técnica propuesta date-only/empates; Q1/Q2 ya resueltas no equivalen a esa aprobación. Aplicar provisional solo modal, contexto anterior textual y handoff futuro definitivo bajo foto/lector real, sin ampliar alcance ni adelantar keep-analysis.
2. Implementar contratos/constructor puro/tests de aislamiento/fechas/presupuestos; readers propios, errores fail-closed, deduplicación según decisión.
3. Renovar alcance/aviso de finalidad y añadir adapter real con URLProtocol; regresiones identificación/cuidados sin ampliar sus payloads.
4. Integrar mismo modal por ambas entradas, sesión/lifecycle/tokens/resultados y botones deshabilitados; registrar PBX/recursos.
5. Añadir fixture aislado/E2E persistente y autoverificación por impacto, documentación/handoff con límites/evidencia. Gate final independiente solo tras autorización posterior.

- [ ] Contratos Domain/resultados/elegibilidad/contexto y pruebas puras.
- [ ] Payload/transporte/parseo/configuración/aviso renovado y cancelación instrumentados.
- [ ] Fábricas compartidas/intenciones pager/timeline/modal/estados/controles futuros.
- [ ] Lifecycle/guard doble/tardíos/deletes/back/aislamiento y pruebas UI focalizadas.
- [ ] Registro targets/localización/docs/evidencia; no marcar accepted por autoverificación.

## Verification Plan (comandos futuros, **no ejecutados**)

### Implementer — impact-selected checks

- Contexto/lectores → pertenencia/filtrado temporal/fallo → tests BuildPlantAnalysisContext/AnalyzePlantPhoto: dos plantas, initial/additional/prealta, fake definitivo; excluir cuidados posteriores y mismo día según propuesta, comparar días/calendario/zona estable/DST/retry; entradas sintéticas de textos aceptados de fotos anteriores ordenadas por photoDate aunque acceptedAt sea posterior/invertido. Excluir fotos posteriores, provisionales y foto consultada; contexto real hoy sin análisis inventados, futuro lector fallido distinto de vacío. Recorte90 días/20cuidados/5análisis/16KiB determinista y omisiones explícitas, cero lecturas JPEG históricas/ajenas y cero commits.
- Adapter/consent config/copy → fuga/renovación/callers → URLProtocol del nuevo adapter + ExternalAIConsentTests, tests actuales configuración/identificación/cuidados afectados: v4→v5 obliga aviso, rechazar/fail-record/config drift0, aceptar1, no redirects/retry ni auth vacío, cancel/timeout/JSON inválido/insuficiencia.
- VM/modal/sheets → duplicados/tardíos/selección/delete/hit-region → nuevos VM + regresiones PlantPhotoPagerViewModelTests y TimelineVM/loader solo afectadas; desde dos entradas misma identidad0 nuevas solo si definitivo, doble tap1 simultánea, identidad distinta independiente. Cierre libera provisional/bytes/tokens; reabrir la misma foto sin definitivo crea nueva intención, sin restaurar resultado ni bloqueo por provisional.
- UI persistente disponible XCUITest: AnalyzeCurrentPhotoUITests cubre pager inicial/adicional, timeline inicial/adicional, aviso, espera/cierre ×/Cancelar/gesto, retry explícito, resultado largo, botones inactivos, reapertura sin provisional/nueva petición explícita y disco/JPEG íntegros tras relaunch. No render de análisis aceptados bajo foto en esta feature: prueba correspondiente será de keep-analysis. Regresiones directas selección push/back, portrait controles/papelera, modales Edit/Care y cambio de aviso de identificación/cuidados.
- Comando focal base (selección propuesta; registrar nombres reales tras implementación):

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886 # confirmar destino estándar/coordinar sesión antes
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/BuildPlantAnalysisContextTests \
  -only-testing:PlantCareAITests/AnalyzePlantPhotoTests \
  -only-testing:PlantCareAITests/PlantPhotoAnalysisViewModelTests \
  -only-testing:PlantCareAITests/OpenAICompatiblePlantPhotoAnalysisRepositoryTests \
  -only-testing:PlantCareAIUITests/AnalyzeCurrentPhotoUITests test
```

- Selecciones de regresión se añaden por diff/callers con mismo comando; no repetir verdes por rol. Preparar config vacía solo si falta, nunca leer/copiar/sobrescribir real; productos válidos permiten test-without-building sin doble build.
- Capturas solo nuevas pantallas afectadas con helper `scripts/configure-ui-test-environment.py` valor1 y selección focal como `docs/testing-ui.md`; inspección real en único iPhone estándar/texto normal/una apariencia. No SE/DynamicType ampliado/VoiceOver/matrices no solicitadas ni regenerar CSV.
- Estáticos futuros: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON catálogo/feature si cambian, `git diff --check`, auditoría Domain/Foundation y Release/config/fixtures por impacto. No sustituyen escenarios ejecutados.
- Reutilizar baseline corroborada solo del mismo estado relevante/destino; aceptación histórica298 no valida nuevos cambios. Sin baseline válida diagnosticar/build focal, no gates completos rutinarios. Tras fallo conservarlo y repetir primero fallido/reparación afectada con hipótesis, sin retries para verde.
- Inferencia real requiere permiso expreso/foto autorizada/credencial aportada por usuario, nunca envíos automáticos de agentes. Relato real previo identificación/cuidados no demuestra análisis contextual; registrar por separado evidencia real y sintética y falta de ella, sin inventarla.

### Validator — final gate

- Una vez autorizada implementación/validación, un único `caffeinate -dius ./init.sh` final o reutilización corroborada de gate completo de esas mismas fuentes/config/destino. Script ejecuta build-for-testing y ambas fases paralela/Fotos serial test-without-building, sale con estado; no servidor ni procesos de desarrollo permanentes.
- Revisar ambos xcresult, aislamiento/consentimiento/guard/cero writes/visuales. No repetir focales cubiertas sin laguna concreta; reparación que cambie inputs ejecutables invalida gate y justifica uno nuevo después de repair focal.
- Este paso solo documental: coherencia de spec/feature/modelos/diseño, sin build, tests iOS, simulador o gate.

## Evidence To Capture / Validator Checklist

- Comandos/selección/motivo, diff→riesgos→tests, fuentes/config/destino, exit/xcresult, fallos preservados, nuevas vs reutilizadas, capturas realmente inspeccionadas; real API solo si autorizada/acreditada, sin fotos/payloads/secretos en registros.
- Handoff y PROGRESS/feature_list distinguen passing focal de accepted independiente y gate pendiente; fotos/metadata antes-después exactas y contador por identidad/HTTP.
- [ ] Q1/Q2 confirmadas aplicadas: solo definitivo bloquea, provisional solo modal; textos ACEPTADOS de fotos anteriores y solo cuidados anteriores a fecha de foto seleccionada, sin JPEG históricos. Revisión/aprobación integral de spec/regla técnica date-only/presupuestos obtenida antes de implementar; respuestas no son aprobación integral.
- [ ] Entradas todas las fotos propias, guard real de elegibilidad/deduplicación y pertenencia también programático.
- [ ] Nuevo aviso renovado y transporte dentro de autorización; solo JPEG seleccionado/contexto presupuestado propio, filtros anteriores al recorte, fotos previas por fecha de foto no aceptación; ningún análisis inexistente ni lector persistente ficticio.
- [ ] Resultado prudente/insuficiencia/error/cancel/retry/tardíos y selección/lifecycle conformes.
- [ ] Aceptar/descartar visibles inactivos, ninguna persistencia/migración/eliminación adelantada; requisito confirmado de definitivo bajo foto registrado para keep-analysis, sin render de datos inexistentes aquí.
- [ ] Cobertura E2E focal añadida y gate final válido sin duplicaciones; docs/estados/evidencia honestos.
