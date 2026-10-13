# Feature Implementation Spec: descartar el análisis provisional

## Source Feature / estado del documento

- `id`: `discard-analysis`; `area`: `analisis-ia`; título: «Descartar análisis sin dejar huella».
- Fuente: `feature_list.json`; `status`: `not_started`; `evidence`: vacío al planificar.
- `user_visible_behavior` fuente: «Al descartar un resultado no se conserva ni su foto ni el análisis en la planta».
- `depends_on`: `[analyze-current-photo]`; dependencia **accepted**, incluida su reparación visual, según feature list y PROGRESS. `keep-analysis` también está accepted y su protección de commit/definitivos debe conservarse; no se añade dependencia al fichero.
- `verification` fuente: comparar cronología/almacenamiento antes y después de descartar/cancelar; reiniciar y verificar ausencia; gate estándar.
- Planner ONE STEP, 2026-10-13; `feature-spec` y guía local `ios-clean-mvvm`. **Borrador para revisión humana integral, no aprobación para implementar**.
- Worktree y rama comprobados por el orquestador: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/discard-analysis`, `feature/discard-analysis`, basado en `main` SHA `079a0f735f56e4a2b44dc8ce39ace05a405a8c9e`.
- Única salida: esta spec. No implementación, validación de código, build/tests/init/simulador, commit ni cambios a feature_list/PROGRESS.

## Goal / Job Story

Cuando leo un análisis provisional de una foto de mi planta, quiero pulsar **Descartar análisis** para cerrar el modal sin guardar nada y volver al lugar desde el que lo abrí.

Descartar abandona exclusivamente el resultado provisional y la operación/sesión de análisis. **Nunca borra la foto local de origen, un análisis previamente guardado, cuidados ni datos de otra planta**. «Sin huella» significa sin nuevo registro en memoria local, no borrado físico seguro ni retirada del envío externo ya realizado.

La frase fuente «ni su foto» se interpreta como no incorporar una copia/nueva fotografía del borrador: en el flujo actual la foto ya existe localmente. Prevalecen esta precisión explícita del usuario y ADR013/014 sobre una lectura destructiva del texto fuente y del ciclo histórico «descartar ambos» de domain-model.

## Non-Goals / Users And Permissions

- Único usuario local; sin roles/cuentas/backend/sincronización.
- Sin confirmación adicional, alerta destructiva, toast, Deshacer, rediseño ni nueva pantalla. DESIGN ya define modal y acciones; su confirmación de eliminaciones no aplica a este abandono efímero.
- No eliminar fotos, plantas o definitivos; no reemplazo/reanálisis de definitivos, nuevo cuidado, escritura de marca «descartado» ni cambios de schema/almacenamiento.
- No modificar transporte, consentimiento v5, contexto, payload, presupuestos, selección del pager ni caches del timeline.
- No retirar aceptación externa ya registrada ni prometer cancelar bytes/costes/retención en el proveedor.

## Decisiones y dudas abiertas

- Confirmado por usuario: Descarta cierra modal sin guardar, conserva origen y definitivos, sin nuevo diseño/confirmación.
- **Confirmado por el usuario:** botón activo con resultado útil **o evidencia insuficiente**, también después de fallo local de guardado mientras exista provisional. Durante commit `.saving`, deshabilitado y guard programático impide cerrar; no compensar un éxito durable con delete.
- En preparación/aviso/espera/error remoto sin resultado no se añade botón nuevo: Cancelar/×/gesto existentes abandonan la operación. No cambiar cancelación del aviso, que actualmente deja error recuperable dentro del modal.
- Reabrir es nueva sesión sin resultado restaurado; la consulta solo nace de nueva intención Analizar foto, no del descarte. Definitivo existente sigue bloqueando análisis mediante lector real.
- No quedan dudas funcionales bloqueantes identificadas. Las dos decisiones de disponibilidad (incluida insuficiencia/fallo local) y bloqueo durante guardado fueron confirmadas por el usuario el 2026-10-13. El estilo/composición no está abierto a rediseño: reutilizar el modal y el tratamiento de la acción secundaria ya definidos en `DESIGN.md` §§68–75. Las respuestas no equivalen por sí solas a aprobación integral de la spec.

## Acceptance Scenarios — Given / When / Then

1. **Resultado útil:** Dada foto inicial/adicional propia ya guardada y resultado provisional, cuando pulso Descarta, entonces desaparece modal sin alerta/toast, no se invoca Keep ni callback de guardado ni nuevo HTTP; foto/modelos/ficha/cuidados/análisis persistidos siguen exactos.
2. **Entrada y selección:** Dada adicional seleccionada en pager o acción inicial/adicional desde historial, cuando descarto, entonces regreso al caller, sin cambiar selección/fecha/portada/orden; historial no incorpora texto/hito nuevos. La foto adicional sigue visible y elegible si no tiene definitivo.
3. **Insuficiencia:** Dado resultado insufficientEvidence con Guardar deshabilitado, cuando descarto, entonces cierra igual y no se guarda resultado ni fotografía nueva; texto prudente/no diagnóstico intacto antes del cierre.
4. **Retry local abandonado:** Dado fallo local precommit con provisional/snapshot retenidos, cuando descarto, entonces libera resultado e intención/retry y cierra; ningún retry/guardar/callback tardío restaura o persiste la sesión cerrada. El intento fallido previo conserva su evidencia, no se cuenta como éxito.
5. **Commit protegido:** Dado Guardar ya despachado, cuando intento descartar por UI o llamada programática, entonces se rechaza, modal no cierra y hay una sola escritura. Éxito se reconoce/cierra por Keep; fallo permite después descartar. Nunca borrar commit exitoso aunque el owner desaparezca.
6. **Cancelación/tardíos:** Dada preparación o petición en curso, cuando cierro con Cancelar/×/gesto, entonces cancela e invalida sesión y no publica respuesta tardía ni escribe. Antes de transporte hay cero solicitudes; si ya se envió no se promete retirarlo. El gate de modal permite nueva apertura.
7. **Reapertura y proceso:** Dado descarte y cierre/reinicio sin reseed, cuando consulto cronología/almacenamiento, entonces no hay provisional/definitivo nuevo ni copia JPEG; origen y registros previos permanecen. Nueva intención Analizar abre VM limpio y puede generar una nueva solicitud autorizada; descartar en sí no genera ninguna.
8. **Definitivos y aislamiento:** Dadas dos plantas, otra foto con definitivo y origen sin definitivo, cuando descarto este provisional, entonces definitivos/contenido literal/UUIDs/JPEG propios y ajenos permanecen tras reapertura; foto con definitivo sigue no elegible. Doble tap/acción obsoleta en VM cerrado no guarda ni afecta sesión posterior.
9. **Lectura funcional:** Dado resultado largo en simulador estándar, cuando desplazo hasta Descarta, entonces control accesible español ≥44pt está activo fuera de commit y cierra realmente; no texto «próxima versión» residual. Guardar conserva su comportamiento y contraste.

## Repository Research

### Inspeccionado

- `AGENTS.md`, `CONTEXT.md`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `DESIGN.md`, feature_list y secciones recientes de PROGRESS; skills/template locales.
- `docs/{build-brief,domain-model,risks-and-open-questions}.md`, ADR013/014, spec histórica `docs/specs/keep-analysis.md`; preservar specs/evidencia aprobadas.
- `PlantCareAI/Features/AnalyzeCurrentPhoto/Presentation/PlantPhotoAnalysisView{,Model}.swift`: Descarta es futureButton inactivo; ayuda `keepAnalysis.discardFuture`; toolbar/onDisappear ya llaman `close()`.
- VM completo: `close()` idempotente devuelve Bool, rechaza `.saving`, cancela tarea/incrementa generación y libera prepared/result/thumbnail/plant/date/source/acceptance/consent UI. `save()` tiene snapshot y callbacks independientes; guard closed protege retry/save.
- `PlantCareAITests/PlantPhotoAnalysisViewModelTests.swift`: doubles de Keep/proveedor, retry literal, cierre busy, conflicto, late result y presentation gate existentes.
- `PlantCareAIUITests/PlantCareAIUITests.swift` sección AnalyzeCurrentPhoto: helper result exige discard disabled y ayuda futura; tests de selección/relaunch/insuficiencia/consent/espera. Discovery de KeepAnalysisUITests y sus pruebas busy/error/durable.
- `PlantCareAIApp.swift` fábrica de análisis (129–171): mismo actor/Keep/reader real/authorize, weak modal gate, fixtures solo Debug. `PlantDetailView.swift` inicio/sheet/lifecycle y búsquedas en `PlantTimelineView.swift`: ambas entradas reutilizan modal; sheet no abandona caller.
- `PlantPhotoAnalysisTestFixture.swift`: proveedor sintético cuenta solicitudes; verify actual compara cuidados/metadata adicionales/JPEG, **no verifica ausencia/preservación de definitivos**.
- `docs/testing-{analyze-current-photo,keep-analysis,ui}.md`, inicio de `init.sh` y PBX: comandos focales, gate dos fases, fuentes registradas explícitamente. No auditoría íntegra del repositorio/persistencia/harness en este planner.
- Búsqueda local `**/*.{png,jpg,jpeg,html,svg}` sin recursos; DESIGN declara referencias HTML históricas sin archivo incorporado. No adjunto visual accesible inspeccionado ni equivalencia pixel-perfect afirmada.

### Patrones / gaps

- Ya existe el abandono correcto en `close()`: reutilizar, no inventar use case/repository de borrado ni capa Data vacía.
- Cambio principal es conectar intención y disponibilidad del botón y quitar ayuda obsoleta. Pruebas aún fijan deliberadamente botón inactivo; actualizarlas sin retirar sus negativos de persistencia/consent/selección.
- Evidencia accepted 357/357 de Keep es histórica y no valida esta feature; no se ejecutó ninguna verificación nueva aquí.

## Technical Approach — Clean Architecture + MVVM

- **Presentation** permanece en `Features/AnalyzeCurrentPhoto/Presentation`, no nueva feature vacía ni pantalla en ContentView. Vista envía intención Descarta; VM expone `canDiscard`/`discard()` o equivalente guardado explícito. Guard: abierto, result presente, state result/insufficientEvidence, saveState distinto de saving/saved. Método devuelve Bool y delega en `close()`; vista hace dismiss solo si autorizado. Cierre técnico conserva alcance más amplio durante espera.
- Mantener `close()` como única limpieza idempotente. No llamar `save`, `onSaved`/`didSave`, prepare/send ni callbacks de delete/invalidación durable desde Descarta. Acción cerrada/obsoleta se ignora; después de failure libera también snapshot de aceptación.
- **Domain** sigue en AnalyzeCurrentPhoto y KeepAnalysis/Domain: modelos y contratos actuales sin modificaciones previstas. Abandonar estado UI sin IO no necesita caso de uso ficticio. Guardar mantiene ruta VM → KeepPlantPhotoAnalysisUseCase → PlantPhotoAnalysisStoring; analizar mantiene VM → Analyze/Authorize → lectores/transporte Domain.
- **Data**: adaptadores existentes y LocalPlantRepository sin cambio productivo. Descarta no llega a escritor ni protocolo de eliminación, no crea entidad, tombstone, JPEG ni cleanup del almacenamiento.
- **Composición**: `PlantCareAIApp.swift` conserva inyección actual tras overrides Debug, reader real, gate débil y fábrica por plantID/identity. No nuevas dependencias para descarte; cambios de seam solo si pruebas necesitan lector/verificador real más completo.
- View → VM.discard → close/cancel/invalidate → dismiss es la ruta de esta intención, deliberadamente termina en Presentation. No forzar pasos Domain/Data sin comportamiento real; mantener dirección Presentation → Domain ← Data en operaciones existentes.

## Riesgos y mitigaciones

- **Borrado por ambigüedad «ni su foto»:** ninguna ruta a delete/cleanup; snapshots semánticos y JPEG exactos antes/después/reopen con origen y definitivo previo.
- **Carrera con Guardar:** guard MainActor y botón disabled durante saving; reconocer commit/callback existente, sin compensación destructiva. Acción obsoleta no opera sobre sesión nueva.
- **Provisional tardío o retenido:** reutilizar generación/cancelación/close y gate débil; pruebas con proveedor suspendido, reapertura limpia y retry abandonado. Cancelación no garantiza liberación instantánea del IO/retención remota.
- **Falso negativo en persistencia:** verify actual no incluye definitivos; ampliar evidencia real sin atribuirle cobertura inexistente. Comparar entidades/contenido, no bytes internos SQLite.
- **Regresión visual/lifecycle:** conservar cápsula/caller/sheet existentes; tests de scroll largo, selección y busy Keep. No rediseño ni matrices ampliadas automáticas.

## Expected File Changes — después de aprobación

- `PlantCareAI/Features/AnalyzeCurrentPhoto/Presentation/PlantPhotoAnalysisView.swift`: reemplazar futureButton por acción neutral activa, disponibilidad VM, quitar ayuda futura y helper si ya no tiene callers.
- `.../PlantPhotoAnalysisViewModel.swift`: disponibilidad/intención explícita y guard contra saved/saving/closed; reutilizar close, sin nueva persistencia.
- `PlantCareAI/Localizable.xcstrings`: conservar `analysis.discard`/ID `analysisDiscard`; retirar solo `keepAnalysis.discardFuture` si queda sin uso. Verificar claves reales antes de editar; no reserializar traducciones ajenas.
- `PlantCareAITests/PlantPhotoAnalysisViewModelTests.swift`: tests descarte, insuficiencia/error local/busy/closed/callbacks/late/gate con spies existentes.
- `PlantCareAIUITests/PlantCareAIUITests.swift`: extender AnalyzeCurrentPhotoUITests para descarte inicial/adicional/relaunch/insuficiencia; ajustar helper result; KeepAnalysis busy/error como regresiones.
- Test de integración nuevo o ampliación en `PlantCareAITests/LocalPlantPhotoAnalysisRepositoryTests.swift`: usar actor/disco real con VM para snapshots antes/después, origen inicial/adicional, ausencia nuevo definitivo y preservación de otro ya guardado. No exigir igualdad binaria de archivo SQLite: comparar modelos/identidades/textos y bytes JPEG.
- Fixture/verificación Debug en `Features/AnalyzeCurrentPhoto/Data/PlantPhotoAnalysisTestFixture.swift` o fixture Keep existente **solo si necesario** para E2E exacto de definitivos; no falsear capacidad del verify actual. `PlantCareAIApp.swift` solo para conectar ese seam, no refactor productivo.
- PBX solo si aparecen Swift nuevos; extensiones de archivos ya registrados no necesitan registro adicional. Sin cambios a init.sh/Assets/ContentView por rutina.

## Visual Design Impact

- UI sí, solo acción Descarta en modal existente; fuente DESIGN §§Análisis/componentes. **No diseño nuevo** ni adjuntos requeridos.
- Conservar sheet Surface blanca, radio24/detent0.95/grabber/scroll/margen20/spacing16, cabecera/preview/fecha/resultados/CTA Guardar y loading centrado.
- Descarta conserva cápsula neutral secundaria ≥52pt existente, texto activo semántico legible; no verde primario ni rojo de eliminación. Disabled durante commit, sin label futuro. Mantener soporte adaptable, etiqueta española, contraste y hit region, no modificar alertas de delete.

## Durable Documentation Impact — posterior implementación

- `ARCHITECTURE.md`: update mínimo — Descarta ya activo y ruta Presentation sin nueva frontera; conservar antecedentes ADR013/014.
- `CONSTRAINTS.md`: not needed — cierre provisional no persistente y protección commit ya fijados.
- `AGENTS.md`, `CONTEXT.md`: not needed — workflow/vocabulario no cambian.
- `DESIGN.md`: update del estado futuro de Descarta y disponibilidad, no nueva composición/diseño.
- `docs/{build-brief,domain-model,risks-and-open-questions}.md`: update delta vigente que elimina ambigüedad «descartar ambos» para foto ya local/definitivo protegido; preservar historia y límites remotos.
- ADR nuevo: not needed — aplica decisiones ADR013/014, no esquema/frontera/tradeoff nuevos.
- `docs/testing-analyze-current-photo.md`, `docs/testing-ui.md`: update selectors/cobertura activa; handoff/evidencia/PROGRESS/feature_list por roles posteriores. Este planner no modifica estos archivos ni specs aprobadas.

## Implementation Plan / Tasks — no autorizadas todavía

1. Obtener revisión humana integral; no iniciar código automáticamente.
2. Añadir guard/intención VM y tests focales sobre cierre idempotente, Keep busy y ausencia de side effects.
3. Conectar botón/recursos sin rediseño; extender E2E y verificación durable real (no solo texto desaparecido).
4. Revisar callers/fixtures por impacto, documentación y evidencia; entregar passing focal al validator independiente.

- [ ] VM availability/discard y negativos saving/saved/closed/callback/late response.
- [ ] Botón neutral activo útil/insuficiente/error local; sin ayuda futura/alerta/toast.
- [ ] Disco antes/después/reopen con ambas plantas, JPEG origen y definitivo previo intactos.
- [ ] E2E inicial/adicional, selección/caller/scroll/relaunch y regresiones Keep busy/error.
- [ ] Recursos/PBX cuando aplique, documentación, handoff y evidencia real por rol.

## Verification Plan — futura, ninguna ejecución en este paso

### Implementer — selección por impacto

- VM/discard/close → cierre durante commit, retry/tardíos → PlantPhotoAnalysisViewModelTests nuevos + existentes de local retry/commit/close during provider.
- View/helper result → control aún inactivo, scroll/insuficiencia/selección → AnalyzeCurrentPhotoUITests actualizado; KeepAnalysisUITests error y busy directamente relacionados, sin retirar assertions ni ampliar timeouts/retries para verde.
- Ausencia de escritor y disco → borrado accidental/definitivo perdido → integración con LocalPlantPhotoAnalysisRepositoryTests real. Snapshot semántico de Plant/CareEvent/PlantPhoto/SavedAnalysis propios y ajenos, JPEG exactos, cero nuevo registro tras reopen. Contador Keep/callback =0 para descarte puro; fallo local previo puede tener un intento fallido, pero descarte no añade otro.
- E2E persistente disponible: XCUITest, añadir/actualizar flujo activo; no basta unit test de nil ni esperar solo desaparición de texto. Fixtures UUID aislados, relaunch sin reseed, verifier real que incluya definitivos.

```sh
# Receta posterior: coordinar destino estándar y comprobar ausencia de pruebas competidoras.
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/PlantPhotoAnalysisViewModelTests \
  -only-testing:PlantCareAITests/LocalPlantPhotoAnalysisRepositoryTests \
  -only-testing:PlantCareAIUITests/AnalyzeCurrentPhotoUITests \
  -only-testing:PlantCareAIUITests/KeepAnalysisUITests/testLocalFailureRetryNoRemoteRequestAndCloseAbandonsUncommittedResult \
  -only-testing:PlantCareAIUITests/KeepAnalysisUITests/testBusyBlocksDoubleSaveCancelCloseAndGestureUntilDurableCommit test
```

- Ajustar selectors al diff real; ampliar solo por seam/callers realmente afectados. Productos válidos del mismo estado/destino permiten test-without-building; no gate completo rutinario implementer ni baseline completo previo.
- Baseline reutilizable solo si inputs/config/destino relevantes coinciden; sin ella build/diagnóstico focal. Mantener fallo, hipótesis de reparación y repetir fallido/afectados, no retries/iterations para verde.
- Config Debug: copiar ejemplo vacío solo si falta, nunca leer/sobrescribir real. Descarte local no requiere API real ni nuevo consentimiento; fixtures/URLProtocol no acreditan servicio remoto.
- Estáticos futuros: git diff --check; JSON del catálogo cuando cambie; plutil PBX si cambia. Conservar archivos ajenos y traducciones previas; auditoría Release si se cambia seam Debug/composición.
- Visual básico focal del botón activo y disabled/error en único iPhone estándar, texto normal/una apariencia, capturas mediante helper de docs/testing-ui; no duplicar pruebas solo para cambiar rol. Matrices ampliadas fuera habitual/no ejecutadas/no bloqueos automáticos.

### Validator — gate final

- Sobre producto/tests finales autorizados: un `caffeinate -dius ./init.sh`, o corroborar gate válido de mismos inputs/entorno sin duplicarlo. Gate ejecuta build-for-testing y test-without-building paralelo + Fotos serial; ambas fases deben pasar, no inicia servicio permanente.
- No repetir focales ya cubiertas salvo laguna concreta/diagnóstico. Repair ejecutable relevante invalida evidencia y justifica nuevo gate tras pruebas focales de reparación; preservar fallos.
- Paso actual solo documental: revisar coherencia spec, sin iOS tests/build/init/simulador ni validación de código.

## Evidence To Capture / Validator Checklist

- Registrar comando/selectors, cambios→riesgos→tests, inputs/config/destino, exit/xcresult, pruebas nuevas vs reutilizadas, fallos/hipótesis, capturas realmente abiertas y pendientes de gate; sin logs de fotos/payload/claves.
- Evidencia durable semántica antes/después/reopen; contador HTTP sin incremento por Descarta, Keep sin nuevo despacho, callbacks de guardado ausentes, caller/selección y definitivo previo intactos.
- [ ] Aprobación humana integral previa; una sola feature, sin nueva confirmación/rediseño.
- [ ] Descarta cierra sin persistir/eliminar nada, conserva foto origen y definitivos, no añade huella «descartado».
- [ ] Útil/insuficiencia/fallo local/scroll, guards busy/saved/closed y cancelación tardía cubiertos.
- [ ] Keeper reconoce commit y sigue bloqueando descarte durante escritura; no delete compensatorio.
- [ ] Ambas entradas/selección/relaunch/aislamiento y verificación real de definitivos cubiertas por E2E/integración.
- [ ] Capas/composición actuales intactas; Domain/Data no se inventan para abandono UI.
- [ ] Documentación/recursos/estado por rol y gate válido posteriores, specs/evidencia históricas conservadas.

**Siguiente acción exclusiva:** revisión humana de esta spec y detención del flujo. Crear este documento no aprueba implementación ni aceptación de la feature.
