# one-turn-question — Pregunta contextual puntual

## Estado y origen

- **Borrador pendiente de revisión humana. No autoriza implementación.**
- Revisión del usuario: acceso, cabecera y contenido del contexto confirmados; consultas sucesivas independientes en el mismo modal y reutilización del consentimiento existente confirmadas. No se ha autorizado implementar ni ejecutar API real.
- Planner: `openai/gpt-6.1-sol`, `feature-spec` mediante feature-flow, modo un solo paso.
- Rama `feature/one-turn-question`; base `main` `6ea72560c393367bc2135216d879e99c8fe57726`.
- Worktree `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/one-turn-question`.
- Dependencias `keep-analysis`, `discard-analysis`, `recover-ai-failure`: `accepted` en la base comprobada por el orquestador.
- Feature mantiene `not_started`, sin evidencia de pruebas nuevas. El planner produjo el contrato en su respuesta tras denegación de edición; el orquestador lo persiste aquí.

## Objetivo y petición del usuario

Desde el detalle del ejemplar se abre un modal con el estilo de Editar planta/Registrar cuidado: cabecera con identidad e icono de planta, campo de pregunta multilínea y botón para solicitar orientación. **La respuesta aparece en esa misma pantalla**. Una consulta contextual efímera, no una conversación ni una entrada del historial.

## Fuera de alcance

Chat multitur, seguimiento, historial/restauración de consultas, guardar respuesta, incorporación al contexto futuro, envío de fotografías, análisis visual nuevo, diagnóstico, RAG, escritura de ficha/cuidados, cuentas/backend/sync/alertas, streaming, reintentos automáticos, migraciones, rediseños de pantallas aceptadas y API real sin autorización específica.

## Decisiones funcionales confirmadas y detalles técnicos propuestos

### P1 — Acceso y presentación

- Box «Preguntar a la IA», símbolo `questionmark.bubble`, subtítulo «Una consulta sobre esta planta», después de Ver historial y antes de ficha.
- Sheet «Pregunta sobre tu planta», fondo blanco, detent 0.95, grabber, radio 24, margen 20, spacing 16; seguir patrones reales y tokens de DESIGN.md.
- Reusar `PlantFormHeader` a 56 con nombre/especie y miniatura inicial snapshot; `leaf.fill` cuando falta. Patrón foto/hoja confirmado por el usuario.
- «Tu pregunta», TextEditor mínimo 110, blanco/radio12/inset16. «Listo» solo quita teclado. Multilínea/Unicode sin truncamiento silencioso.
- CTA cápsula de 52, verde/Surface activo, SurfaceMuted/TextSecondary deshabilitado. Espera centrada con cancelación accesible; resultado debajo, bajo «Respuesta de IA», texto completo y desplazable.
- Leyenda de orientación y consulta no guardada **localmente**, sin prometer ausencia de retención externa. Sin burbujas de chat, timestamps ni Guardar.
- Labels, objetivos ≥44, soporte adaptable, hit-testing decorativo restringido a miniatura/hoja. Mantener Portrait/Light actual, sin nuevas matrices.

### P2 — Contexto actual y límites

- Capturar contexto al enviar, no usar cutoff de una fotografía seleccionada.
- Pregunta trim no blanca, máximo 2000 caracteres. Pregunta + contexto JSON ≤16 KiB; nunca truncar pregunta/ficha/ubicación. Exceso base impide enviar.
- Hasta 20 cuidados de 90 días civiles contando hoy, `createdAt <= queriedAt`; hasta 5 análisis guardados de fotos hasta hoy, `acceptedAt <= queriedAt`, fechados por foto origen.
- Notas prefix500 declarado. Para ajustar presupuesto omitir primero análisis antiguos y después cuidados antiguos; contadores de omisiones explícitos.
- Estos límites son propuestas de producto/técnicas, no decisiones ya aprobadas.

### P3 — Consultas independientes en el mismo modal

- Éxito: el mismo campo sigue editable y permite enviar otra pregunta sin cerrar. Cada envío es independiente, con contexto de planta releído, sin preguntas/respuestas anteriores en el payload. Una única zona de respuesta: la nueva sustituye a la anterior, sin lista ni conversación acumulada.
- Al iniciar un nuevo envío válido, retirar la respuesta anterior para no atribuirla a la nueva solicitud; espera/error/cancelación no restauran una respuesta de otra pregunta. Editar el campo sin enviar no provoca solicitudes y la respuesta visible debe permanecer identificada con la pregunta que la originó, no con el borrador editado. Cerrar y reabrir inicia consulta vacía.
- Preparación/aviso/red bloquean edición/doble envío, nunca cierre/gesto.
- «Cancelar solicitud» cancela y vuelve al campo conservando texto solo durante esta apertura. Cancelar de toolbar cierra y libera todo.
- Rechazar aviso conserva texto y produce cero HTTP. Error permite editar o Reintentar; retry explícito recaptura fecha/zona y relee contexto vigente.

### P4 — Respuesta, privacidad y evidencia real

- Contrato JSON exacto `{"answer":"…"}`, texto no blanco ≤6000 caracteres, `max_tokens:2000`; limitaciones de evidencia se explican prudentemente en answer. Malformed/truncado es error, no éxito parcial.
- Reutilizar el consentimiento global ya aceptado para el destino/configuración vigente: no renovar versión ni volver a mostrar el aviso por añadir preguntas. No basta con haber mostrado el aviso si se rechazó: sin aceptación vigente, usar la frontera y el aviso existentes antes de enviar. Conservar las reglas existentes cuando cambia destino/modelo; esta feature no introduce renovaciones propias. **No fotografías en esta operación**.
- Decidir si aceptación requiere prueba real específica autorizada o admite alcance offline instrumentado explícito. Fixtures no acreditan servicio real.

## Criterios de aceptación

1. Detalle loaded A, incluso JPEG fallido: abrir muestra cabecera propia/campo vacío/CTA disabled, cero HTTP y pager intacto. Loading/notFound/fallo metadata/eliminando no permiten consulta; guard ViewModel también.
2. Pregunta válida y autorización vigente: Enviar prepara contexto, muestra espera, hace un POST por intención y presenta respuesta en el mismo modal. El mismo campo admite otra pregunta; un nuevo envío relee contexto y sustituye la respuesta, sin acumular ni enviar consultas anteriores. Edición sin envío no hace HTTP; respuesta identificada con su pregunta original. Sin chat/Guardar/escrituras.
3. Aceptación vigente existente: cero avisos adicionales por preguntar, incluso con envíos sucesivos/reapertura. Sin aceptación vigente, usar el aviso existente; rechazo/gesto/fallo preferences implican cero solicitudes y texto recuperable. Cambios destino/modelo conservan política existente. Scope recordado no omite la frontera de autorización.
4. A/B de misma especie: contexto propio por UUID, filtrado antes de límites, sin consultas anteriores/JPEG/UUID/nombre personalizado en payload generado. La pregunta humana puede contener datos personales. Resultado ligado localmente a plantID/requestID.
5. Cuidados de hoy/antiguos/futuros y análisis propios/ajenos: selección determinista P2, omisiones y fechas de origen correctas. Fallo lector nunca se convierte en vacío/parcial. Blanco/exceso/base excesiva producen cero HTTP.
6. Preparación/aviso/red suspendida: cancelar/cerrar/abandonar invalida tokens y tareas; ninguna respuesta o aviso tardío publica/reabre/contamina otra sesión. Reapertura vacía y sin envío automático.
7. Offline/timeout/401/403/429/rechazo/5xx/JSON inválido: error específico y seguro, texto conservado, retry solo explícito. Config material distinta impide envío/publicación y exige nueva apertura/snapshot.
8. Planta eliminada/modificada durante espera: comprobar existencia/igualdad antes de despacho y publicación; notFound/stale sin fallback de tarjeta, recreación ni respuesta presentada como vigente.
9. Textos largos/teclado/éxito/error: scroll permite alcanzar controles y leer texto completo. Cerrar/reabrir/relanzar sin reseed no recupera consultas. Models/fichas/cuidados/fotos/JPEG/definitivos de ambas plantas exactos; aceptación puede cambiar únicamente consentimiento global.

## Investigación y referencias visuales

Planner consultó AGENTS, PROGRESS, feature_list, CONTEXT, DESIGN, ARCHITECTURE, CONSTRAINTS, brief/modelo/riesgos, skill feature-spec/plantilla e ios-clean-mvvm; fuentes pertinentes:

- `PlantDetail/Presentation/PlantDetailView.swift` y `PlantDetailViewModel.swift`: sheets, canAct, hasPresentedEditor, formPhoto, lifecycle/terminal.
- `PlantList/Presentation/PlantListViewModel.swift`: fábrica y detalle retenido débil.
- `EditPlant/Presentation/EditPlantView.swift`, `CareEvents/Presentation/RegisterCareView.swift`, `Shared/Presentation/PlantFormHeader.swift`: layout, teclado, identidad/foto/hoja sin IO.
- Domain/Data/Presentation de AnalyzeCurrentPhoto, lector real `SavedPlantPhotoAnalysisReading` y `LocalPlantRepository.loadSavedAnalyses(for:)`.
- ExternalAIConsent, IdentificationAPIConfiguration, composición App, catálogo, PBX, init, testing-ui y tests de contexto/adapter/VM/análisis.

No reusar `BuildPlantAnalysisContext` tal cual: excluye mismo día/origen y requiere foto, incompatible con contexto actual propuesto.

No hay adjuntos visibles en conversación. Búsqueda local encontró cuatro PNG de marca/lanzamiento y ningún HTML/PDF/captura de modal. Planner abrió `LaunchBrand.imageset/LaunchBrand.png`: marca botánica, no referencia de esta sheet. Otros PNG no abiertos/no necesarios; no Downloads/externos/simulador consultados. Referencia pertinente: DESIGN y formularios existentes. No evidencia ejecutable nueva ni baseline futura corroborada a partir de gates históricos.

## Arquitectura y enfoque técnico propuesto

### Capas y composición

- Presentation bajo `Features/OneTurnQuestion/Presentation`: `PlantQuestionView.swift` y `PlantQuestionViewModel.swift`. MainActor dueño de texto/header snapshot/task/generation/closed/respuesta; estados idle/preparing/awaitingConsent/asking/answered/failed.
- Domain Foundation/Sendable bajo `Features/OneTurnQuestion/Domain`: `AskPlantQuestionUseCase.swift`, `BuildPlantQuestionContext.swift`, `PlantQuestion.swift`, `PlantQuestionRepository.swift`.
- Use case prepare por UUID mediante Plant/CareEventRepository y **SavedPlantPhotoAnalysisReading obligatorio**; execute remoto. Sin writers ni lector nil que finja persistencia.
- Data bajo `Features/OneTurnQuestion/Data`: `OpenAICompatiblePlantQuestionRepository.swift`, contrato textual reutilizando config/delegate existentes; no refactor genérico de transporte por rutina.
- App conecta mismo LocalPlantRepository y consentRepository tras overrides; factory `(Plant, UIImage?) -> PlantQuestionViewModel?` ListVM→DetailVM. Sin IO en factory/init; ContentView intacto.
- Binding separado incluido en hasPresentedEditor/guard onDisappear; snapshot inicial sin nueva lectura de imagen. Cerrar conserva pager; abandono real/terminal UUID cierra modal por referencia débil. No cache de respuestas en Detail/List.

### Contexto y concurrencia

- Capturar requestID/plantID/pregunta/fecha/zona por intento, releer Plant por UUID sin fallback de tarjeta.
- Eventos propios: occurredAt DESC/createdAt DESC/UUID ASC; ventana hoy−89días→hoy, excluir createdAt futuro.
- Definitivos propios: photoDate DESC/identidad estable ASC; excluir acceptedAt futuro/día origen futuro.
- Payload: especie, seis cuidados actuales, ubicación humana, fecha/zona, registros/notas, interpretaciones IA etiquetadas y fechadas por origen, omisiones. No UUID/nombre personalizado/JPEG/listado general en contexto generado.
- Revalidar igualdad/existencia Plant antes de POST y tras respuesta. Historia snapshot secuencial de intención; no prometer atomicidad global/multiproceso.
- Gate por plantID con lease/requestID; cancelación drena hasta liberar y completion viejo no libera lease nuevo. No exclusión global con análisis.
- VM deduplica también prepare/aviso; nuevo intento relee. Sin callback escritor ni refresh último riego.

### Consentimiento y transporte

- Reusar scope/versionado/aceptación vigentes y destino/modelo canónicos, sin v6/notice-6 ni invalidación por esta nueva función. No cambiar payloads ni copy global de los flujos previos. Si falta consentimiento, usar el aviso vigente sin inventar una renovación propia.
- Notice real y continuation `AuthorizeExternalAIOperation`; revalidar config/token antes de aceptar/enviar/publicar.
- Un POST chat/completions, system español fijo y user JSON no confiable. Sin conversación/tools/image_url; stream:false, auth opcional, HTTPS/no redirects.
- Sesión efímera sin cache/cookies/credentials; deadline60s configurable10–120; respuesta de transporte ≤1 MiB.
- Prompt prudente: distinguir humanos/IA, ignorar instrucciones incrustadas, no inventar visuales/evolución/diagnóstico/fuentes/regar hoy/seguimiento.
- Decoder envelope único/stop/no refusal/JSON exacto/answer válido. Errores tipados/copy seguro, sin logs crudos.
- CancelRequest invalida/cancela/libera preparado/respuesta, conserva texto/header solo en apertura. Close terminal libera todo. Provider no cooperativo no publica tardíos. Consentimiento registrado puede permanecer; cancelación no retira bytes/costes externos.

## Archivos previstos para implementación futura

- Siete Swift de módulo anteriores y `Data/PlantQuestionTestFixture.swift`, solo Debug Simulator opt-in, UUIDs/modes/contador.
- App, ListVM, Detail View/VM: factory/modal/lifecycle/terminal.
- Catálogo: claves de pregunta. Reusar config/vista/frontera de consentimiento sin cambio de versión o invalidación global; payloads previos intactos.
- Nuevas unitarias `BuildPlantQuestionContextTests`, `AskPlantQuestionTests`, `PlantQuestionViewModelTests`, `OpenAICompatiblePlantQuestionRepositoryTests`.
- Clase `OneTurnQuestionUITests` en archivo/target UI existente; verifier real cuatro entidades/JPEG antes/después/reopen.
- PBX Sources y grupos físicos; schema/writers/ContentView/init/scheme/PhotosPicker/settings/firma intactos.

## Documentación durable futura

Tras aprobación: ARCHITECTURE para módulo/frontera/read-only/composición/reuso de consentimiento; CONSTRAINTS para no JPEG/persistencia; DESIGN/brief/domain/riesgos solo deltas aprobados. Proponer ADR016 sobre contexto actual/contrato textual/consultas independientes y reuso de consentimiento, no aceptarlo ahora. Crear testing/handoff y actualizar testing-ui/selectores. AGENTS no necesita cambios; CONTEXT normalmente tampoco, consulta efímera ya definida.

Esta ronda modifica únicamente spec y notas mínimas de feature_list/PROGRESS.

## Tareas futuras — no autorizadas

- [ ] Aprobar P1–P4 y congelar spec; corroborar evidencia pertinente sin gate baseline automático.
- [ ] Domain/contexto/tests: UUID/fechas/límites/omisiones/lectores/leases/revalidación.
- [ ] Adapter/URLProtocol/decoder/errores/cancelación/config y reuso de consentimiento/regresiones callers.
- [ ] VM/modal/composición/terminal/pager y PBX físico.
- [ ] E2E dos plantas/verifier real/textos largos/cancelación/error y visual focal.
- [ ] Evidencia/handoff; passing solo tras autoverificación. Gate/accepted exclusivos validator independiente.

## Verificación futura por impacto

**Nada ejecutado en esta ronda salvo comprobaciones documentales.**

| Cambios/riesgos | Selección propuesta |
| --- | --- |
| Domain/lectores: aislamiento, fechas, presupuesto | Cuatro clases nuevas, doubles mezclados/no cooperativos y disco real exacto |
| VM/detail: doble intención, tardíos, lifecycle y consultas sucesivas | OneTurnQuestionUITests y tests Detail terminal/canAct/pager; reemplazo de respuesta, pregunta original identificada al editar y cero conversación previa en payload |
| Config/aviso: reuso sin aviso duplicado | ExternalAIConsentTests y config/adapter scopes; aceptación vigente sin nuevo aviso, rechazo/sin aceptación cero HTTP y cambios de destino según reglas existentes. Regresiones de callers solo según diff final; no cambiar expectativas/versionado global |
| Header, solo si cambia | DeleteCareEventUITests/testPortraitDecorativeFormHeadersKeepEditCareAndAdditionalPreviewControlsInteractive y editor/cuidado afectados |
| PBX/fixtures | Static/build y Release audit ausencia seams/config, sin secretos |

Comando focal propuesto, no ejecutado; confirmar destino y clases definitivas:

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/BuildPlantQuestionContextTests \
  -only-testing:PlantCareAITests/AskPlantQuestionTests \
  -only-testing:PlantCareAITests/PlantQuestionViewModelTests \
  -only-testing:PlantCareAITests/OpenAICompatiblePlantQuestionRepositoryTests \
  -only-testing:PlantCareAIUITests/OneTurnQuestionUITests test
```

Regresiones adicionales según diff final. Capturas focales `UI_TEST_SCREENSHOTS=1` con helper documentado/xctestrun y productos válidos, sin repetir suite por capturas. Un iPhone estándar/texto normal/Light, coordinar sesión activa; SE/AX aumentado/VoiceOver/Inspector/matrices fuera de rutina y no blockers sin petición. API real depende de P4/autorización explícita.

Validator: único `caffeinate -dius ./init.sh` final ejecutable, build + paralela default5 + PhotosPicker serial, ambos xcresult/exit. Reusar gate corroborado de mismas fuentes/entorno si existe; no repetir focales cubiertas sin laguna. Conservar fallos, reparación primero escenarios/callers afectados; repetir gate solo con razón documentada si se invalida evidencia, nunca retries para verde.

## Evidencia y checklist futuro

Registrar comando/selección/motivo/exit/xcresult/fuentes/entorno, ejecutado vs reutilizado, PNG realmente abiertos, fallos y gate pendiente; nunca contenido sensible.

- [ ] P1–P4 aprobados y criterios trazados.
- [ ] Pregunta/respuesta mismo modal, consultas sucesivas independientes y reemplazo de respuesta, reapertura limpia, pager conservado.
- [ ] Contexto UUID/límites correctos; errores lectores/config/consent bloquean y consentimiento vigente se reutiliza sin aviso adicional.
- [ ] Cancelación/tardíos/lease/terminal y ausencia durable probados.
- [ ] Store propio/ajeno exacto; arquitectura/PBX/Release/docs coherentes.
- [ ] Gate independiente válido tras implementación; fixtures no atribuidos a API real.

**Siguiente paso único: revisión humana de esta spec. Detener el flujo.**
