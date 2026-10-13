# Feature Implementation Spec: Eliminar cuidados y fotografías adicionales

## Source Feature y estado

- ID: `delete-care-event`; área: historial; fuente: `feature_list.json`.
- Dependencia: `plant-timeline` **accepted**, incluida la corrección de scroll aceptada.
- Rama: `feature/delete-care-event`; base `main`/`origin/main`: `ac94624ca7e45a65729004cf01087d56a639a82b`.
- Worktree exclusivo: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/delete-care-event`.
- Estado: `not_started`, evidencia nueva vacía. **BORRADOR: decisiones de alcance resueltas; revisión humana integral pendiente.**
- Contrato ampliado expresamente por el usuario: eliminar solo el cuidado o fotografía adicional seleccionados, previa confirmación, sin afectar otra planta ni la inicial. Cancelar/confirmar, reiniciar y comprobar último riego recalculado y carrusel reconciliado.

## Objetivo y autoridad

Eliminar un cuidado humano incorrecto o una fotografía adicional desde su tarjeta del historial, previa confirmación nativa, con persistencia local aislada por ejemplar. Ante fallo de commit, conservar registro/nota o metadata/JPEG de la fotografía, explicar el error y permitir reintento explícito.

Requisitos expresos: **«La foto principal no puede ser borrada»** y **«Ante cualquier duda pregúntame»**. Autoridad funcional: brief y dominio; interfaz: `DESIGN.md`; capas: `ARCHITECTURE.md`.

Las referencias son tres HTML inline del usuario, no archivos ni capturas inspeccionadas. Del timeline se toma únicamente la papelera derecha; de las otras referencias, la confirmación iOS y el banner superior de error. No se importan sus datos ficticios, estilos externos ni navegación web.

## Decisiones humanas confirmadas y revisión pendiente

1. **Q1 resuelta:** eliminar cuidados Y fotografías adicionales; contrato ampliado sin renombrar `delete-care-event`.
2. **Q2 resuelta:** proteger SOLO la inicial de alta/portada persistida. Una adicional seleccionada en el carrusel puede eliminarse: selección no equivale a principal.
3. **Q3 resuelta:** × y Cancelar cierran banner y abandonan reintento, sin borrar. Otra intención exige nueva papelera y confirmación.
4. **Q4 resuelta:** basta desaparición de tarjeta después de commit; SIN toast de éxito.

No quedan preguntas funcionales bloqueantes identificadas. Fallback del carrusel a inicial cuando se borra la seleccionada, textos específicos de fotografía y tratamiento técnico commit/cleanup se proponen abajo para revisión integral; resolver Q1–Q4 no los aprueba automáticamente.
**No existe aprobación integral de esta spec ni autorización de implementación/validación.**

## Job story y usuario

Cuando encuentro un cuidado incorrecto o una foto adicional que no quiero conservar, quiero confirmar su eliminación para mantener veraz la memoria local del ejemplar. Único usuario local, sin cuentas/permisos remotos; pertenencia por plantID e identidad discriminada delimitan cada operación.

## No objetivos

- Rediseñar timeline/detalle, filtros, perfiles, salud/porcentajes IA, sincronización o metadatos ficticios.
- Borrar planta, ficha, foto inicial/alta o análisis; eliminación por lotes, editar eventos, deshacer o papelera recuperable.
- Red, cuentas, backend, chat persistente o nuevas capacidades de contexto IA.
- Cambiar fechas humanas/origen IANA, orden contextual accepted, orden del carrusel, portada o esquema persistente.
- Sustituir/borrar inicial, promover adicional a portada, copiar HTML/Tailwind o construir alerta web.
- Toast de éxito, borrado físico seguro de backups o transacción distribuida entre SwiftData y archivos.

## Escenarios de aceptación

1. **Acceso:** cuidados de los cinco tipos y fotos adicionales ofrecen papelera derecha, etiqueta española apropiada y área táctil ≥44pt; nota/foto íntegras. Alta/origen sin papelera. Una adicional seleccionada sigue siendo eliminable.
2. **Confirmación diferenciada:** `.alert` iOS centrada. Cuidado: «¿Eliminar este cuidado?», contexto tipo real + fecha humana en zona actual, «Este registro se eliminará permanentemente del historial de esta planta. Esta acción no se puede deshacer.». Foto, copy propuesto: «¿Eliminar esta fotografía?», contexto Fotografía + fecha humana, «Esta fotografía se eliminará permanentemente del historial de esta planta. Esta acción no se puede deshacer.». Cancelar y Eliminar destructivo; no repetir fechas en tarjetas ni llamar cuidado a una foto.
3. **Cancelar:** cuidado o foto: cero escrituras/callbacks; historial, notas, JPEG, selección y último riego intactos, también tras relanzar. Sin eliminación optimista.
4. **Confirmar cuidado:** una operación elimina solo registro propio/nota. Tarjeta desaparece después de commit confirmado, sin salir del historial ni toast. Doble tap no duplica operaciones. Resto de cuidados, todas las fotos, Plant/CareSheet y otra planta exactos tras reinicio sin reseed.
5. **Último riego:** eliminar watering máximo hace que detalle y card retenidos muestren el máximo restante; eliminar el último muestra ausencia real. Eliminar otro watering recalcula sin inventar fecha. No-watering no invalida último riego. Cancelar/fallar tampoco. Fallo de lectura posterior oculta resumen según ADR010, sin convertir commit confirmado en fallo de eliminación.
6. **Fallo de commit diferenciado:** fallo después de mutar y antes de save produce rollback real; evento/nota o metadata/JPEG y resto exactos en memoria/disco tras reopen. Banner superior warning «No pudimos eliminar el cuidado» o copy propuesto «No pudimos eliminar la fotografía», explicación apropiada, ×, Reintentar y Cancelar. No vacío ficticio ni promesas de sincronización.
7. **Reintento y abandono:** repite solo snapshot/identidad discriminada/plantID confirmados; éxito notificado una vez. × y Cancelar cierran/descartan snapshot/error/retry, sin escribir. Otra papelera exige nueva confirmación. Estado efímero no reaparece tras relanzar.
8. **Aislamiento y protección:** llamada programática ajena/obsoleta no modifica otra planta ni inicial/principal, incluso con JPEG ausente/corrupto. Proteger por contrato Domain y filtro Data, no solo ocultando un botón; identidades discriminadas, nunca convertir `.initial(plantID)` en UUID de adicional.
9. **Lecturas tardías:** refresh, foreground o imagen en vuelo no resucitan un registro eliminado. Commit confirmado no se pierde por visibilidad/navegación. Reentrada relee disco; grupos/pie/ausencia recalculados con reglas accepted.
10. **Confirmar foto adicional:** desaparece de metadata/timeline/carrusel tras commit, SIN toast; inicial/portadas exactas, cuidados/último riego sin cambios. Tras relanzar sin reseed no es consultable; otra planta exacta. Solo inicial protegida.
11. **Pager retenido:** borrar no seleccionada conserva selección superviviente por identidad y ajusta contador/extremos, orden createdAt ASC intacto. Si seleccionada borrada, fallback propuesto `.initial(plantID)`, no índice desplazado. Back/gesto devuelve pager reconciliado sin metadata/imagen borradas ni force-unwrap inválido; cabeceras de formularios conservan inicial propia.
12. **Purga/tardíos:** foto borrada no renderizable en caches timeline/pager; owners/cola/tokens/tareas/viewport no la solicitan. Lectura/decode/metadata anteriores no la repueblan. Scroll ida-vuelta carga supervivientes con cache3/concurrencia2 accepted.
13. **Cleanup postcommit:** fallo retirando JPEG tras save no revierte metadata ni produce error reintentable de eliminación ni afirma foto intacta. Callback una vez; huérfano para recuperación posterior que valida todas las entidades antes de limpiar. Reopen no resucita foto; sin prometer borrado físico inmediato/seguro.
14. **Protección por capas:** `.initial` rechazada antes del escritor. Adaptador adicional con UUID inicial sin fila adicional propia no toca Photos/Plant. Identidades care/additional/initial no se intercambian aunque coincidan UUID; adicional seleccionada válida sigue eliminable.

## Investigación del planner

Leídos: AGENTS, PROGRESS (primeros 197 renglones), feature_list, CONTEXT, CONSTRAINTS, brief, dominio, riesgos, ARCHITECTURE, DESIGN, skills/template; ADR010/011, testing-ui e init.sh. Fuentes pertinentes:

- `PlantCareAI/Features/PlantTimeline/Domain/{PlantTimelineEntry,LoadPlantTimelineUseCase}.swift`.
- `PlantCareAI/Features/PlantTimeline/Presentation/{PlantTimelineView,PlantTimelineViewModel}.swift` y primeras 115 líneas del loader `PlantTimelinePhotoViewModel.swift`.
- `PlantCareAI/Features/CareEvents/Domain/CareEventRepository.swift`.
- `PlantCareAI/Features/PlantPhotos/Domain/{PlantPhoto,PlantPhotoRepository,LoadPlantPhotosUseCase}.swift`.
- `PlantCareAI/Features/PlantList/Data/LocalPlantRepository.swift` completo; pager completo y lifecycle/invalidate de `LastWateringHintViewModel.swift`.
- Fragmentos de composición `PlantCareAIApp.swift`, PlantListView/ViewModel y callbacks/lifecycle de PlantDetailViewModel.
- LocalCareEventRepositoryTests, PlantTimelineViewModelTests, bloque inicial de PlantTimelineUITests y registros pertinentes de project.pbxproj.

En investigación inicial no se encontró spec previa. Continuación relee spec REAL persistida, PROGRESS y feature actuales para incorporar respuestas Q1–Q4. No contexto IA futuro inspeccionado: capacidad no iniciada. Investigación para planificar no equivale a validación de código.

### Patrones y lagunas

- Repositorios de cuidados/fotos ofrecen save/load, no delete; CareEvents no tiene error notFound específico.
- Un actor `LocalPlantRepository` comparte SwiftData para Plant/CareEvent/PlantPhoto, autosave=false, mutación/save síncronos, rollback y seam `beforeCommit`. Borrar fila existente no necesita migración.
- Inicial: `Photos/<plantID>.jpg`, referenciada por Plant. Adicionales: `AdditionalPhotos/<photoID>.jpg`. Identidades `.initial` son proyecciones, no filas PlantPhoto; selección del pager es Presentation.
- Timeline une lecturas sin segunda copia persistida; error metadata no es vacío/parcial. Orden: día visible DESC, interior createdAt DESC/clave ASC, una fecha por grupo. Carrusel createdAt ASC; no modificar sorts accepted.
- Timeline/pager retienen caches independientes. Conservar viewport coalescido/cache3/concurrencia2 del scroll-fix. `setEntries` no constituye por sí solo purga completa de una foto borrada.
- `makeTimeline` recibe UUID pero no callback a card/detalle. Último riego loaded y metadata del pager suspended se conservan: reaparecer no garantiza recalcular/reconciliar.

## Plan técnico por capas

### Domain

- Nuevo `Features/CareEvents/Domain/DeleteCareEventUseCase.swift`, con seam protocol de caso de uso y contrato de eliminación estrecha en `CareEventRepository.swift`.
- Entrada: snapshot esperado de CareEvent, incluyendo id y plantID; retorno canónico eliminado. Propuesta: errores tipados notFound/conflict, sin borrar payload cambiado silenciosamente ni revalidar un histórico contra el reloj actual.
- Caso de cuidados acepta CareEvent, no entrada genérica; no capacidad para eliminar Plant/initial. Sin UIKit/SwiftData ni dependencia a Presentation.
- Ausente/obsoleto exige reconciliar lectura, no afirmar «intacto» sin comprobarlo ni éxito idempotente no acreditado.
- Nuevo `Features/PlantPhotos/Domain/DeletePlantPhotoUseCase.swift`, seam protocol y contrato estrecho en PlantPhotoRepository. Solo `.additional` con snapshot PlantPhoto esperado y plantID; `.initial` rechazada antes del repositorio. Retorno canónico y errores notFound/conflict/identidad protegida; selección no interviene en elegibilidad.
- No eliminación genérica por UUID/ruta entre entidades. Snapshots cuidado/foto separados, comparados con registro actual. Domain no conoce rutas ni cambia Plant/CareSheet.

### Data

- Implementación en `Features/PlantList/Data/LocalPlantRepository.swift` sobre el actor/contexto existentes.
- Localizar planta/evento por pertenencia, mapear/comparar snapshot antes de mutar; `context.delete` → seam síncrona → `context.save`, rollback si throw. Ningún await dentro de mutación/commit ni JPEG leído/borrado por un cuidado.
- Cuidados: solo PersistedCareEvent propio. Pruebas reales disco/reopen/rollback tras mutación/dos plantas, no solo dobles.
- Fotos: verificar planta y PersistedPlantPhoto por photoID Y plantID, comparar snapshot/referencia canónica antes de mutar. Solo entidad adicional y `AdditionalPhotos/<photoID>.jpg`; nunca Photos/PersistedPlant/inicial proyectada. No exigir JPEG legible para eliminar metadata propia con archivo ausente/corrupto.
- Commit metadata ANTES de retirar JPEG: fallo pre-save revierte contexto sin tocar archivo; delete/seam/save síncronos sin await. Después de save, cleanup propio best-effort; archivo ya ausente no revierte eliminación.
- Fallo cleanup no deshace éxito ni devuelve error reintentable/garantía de foto intacta. Recuperación existente valida TODAS las entidades antes de limpiar directorios; sin tombstone/modelo/schema ni reinserción compensatoria.
- Seams pre-save/post-save independientes y pruebas de otro JPEG/inicial/nota/modelo exactos. Documentar eliminación lógica local, no borrado físico seguro/backups ni transacción distribuida.

### Presentation

- PlantTimelineView → PlantTimelineViewModel → caso CareEvents o PlantPhotos → contrato Domain ← LocalPlantRepository. VM posee snapshot discriminado care/additional (nunca initial) y estado idle/confirming/deleting/failed separado de loaded metadata.
- Bloquear deletes duplicados; fallo de escritura no vacía historial. Invalidar/cancelar lecturas antiguas antes de despacho y diferir refresh foreground mientras commit activo.
- No cancelar engañosamente commit irreversible al salir: operación despachada debe resolver/notificarse. Propuesta técnica revisable: impedir back/gesto únicamente durante commit y restaurarlo después.
- Tras éxito retirar solo entrada confirmada y recalcular grupos/pie/ausencia. No refresh global/JPEG eager por cuidado; conservar caches/scroll no afectados y lectura habitual al reentrar. Sin toast.
- Foto: purga específica en PlantTimelinePhotoViewModel de allowed/cache/LRU/states/owners/visible/queue/tokens/hiding/viewportFrames; cancelar lectura/decode y rechazar publicación tardía. Mantener contabilidad de cancelaciones drenando para concurrencia2, caches supervivientes y viewport real (no volver a onAppear).
- Pager retenido recibe resultado incluso suspended: invalidar generación/cancelar metadata anterior, retirar snapshot/descriptor/cache/LRU y cancelar imagen pertinente. Selección superviviente conservada; borrada → fallback propuesto inicial. Publicar descriptores/selección/estado coherentes sin índices inválidos; preservar inicial de formularios, no IO eager suspendido.
- Marcar reconciliación metadata pendiente al retorno; lectura vieja no repuebla. Fallo de relectura es error pager, no fallo delete ni total parcial presentado como completo. Mantener orden/extremos/fechas; abandono real sigue reseteando a inicial.
- ×/Cancelar limpian intención/error/retry sin invocar caso; nueva intención exige confirmación. Sin avisos/reintentos persistentes.

### Composición y consumidores

- Inyectar desde `PlantCareAIApp.swift` usando mismo actor, después de overrides Debug; sin Data concreto en vistas ni feature en ContentView.
- Callback canónico discriminado desde fábrica timeline a consumidores propios retenidos, una vez/solo postcommit. CareEvent watering invalida último riego detalle/card con patrones onWatering/invalidate; otros cuidados/fotos no lo invalidan.
- PlantPhoto notifica pager REAL retenido incluso suspended; no reemplaza card/portada ni reconstruye detalle. Wiring PlantListView/ViewModel/PlantDetailViewModel con referencias débiles/fábricas sin IO; evitar ciclos/VM distinto al visible. Ambos escritores sobre mismo actor.
- Contexto IA futuro consumirá repositorios actualizados; no segunda copia/cache persistida ni transporte nuevo. No se borran solicitudes remotas previas.

## Interfaz

- SF Symbol `trash` a derecha de cabecera cuidado Y foto adicional, ≥44×44pt, etiquetas «Eliminar cuidado» con tipo y «Eliminar fotografía». Notas/spacing/tokens/nodos/orden intactos. Alta sin control; adicional seleccionada conserva papelera.
- `.alert` SwiftUI nativa, Cancelar seguro y Eliminar destructivo; no sheet/full-screen ni alerta dibujada. Contexto tipo/fecha sin confundir occurredAt/createdAt ni inventar hora observada.
- Banner superior nativo con warning/texto/acciones alcanzables y cierre accesible. Respetar safe area, back, scroll y notas largas.
- Copy cuidado rollback: «No pudimos eliminar el cuidado» / «No se ha eliminado este registro del almacenamiento local. El cuidado y sus notas siguen intactos.».
- Copy foto propuesto: «No pudimos eliminar la fotografía» / «No se ha eliminado esta fotografía del almacenamiento local. El registro y la imagen siguen intactos.». Si JPEG ya faltaba/corrupto, no garantizar imagen intacta: «El registro de la fotografía sigue en el historial.». Obsolescencia/lectura fallida exige copy propio, nunca commit exitoso como fracaso.
- ×/Cancelar cierran/abandonan retry; Reintentar mismo snapshot. Alerta/copy de foto pendientes revisión integral, no preguntas bloqueantes nuevas.
- Busy visible/acciones protegidas; éxito solo desaparición y consumidores actualizados, SIN toast. Accesibilidad/contraste/adaptabilidad conservados, sin matrices ampliadas automáticas.

## Archivos previstos — futuros, no modificados ahora

- Crear casos `Features/CareEvents/Domain/DeleteCareEventUseCase.swift` y `Features/PlantPhotos/Domain/DeletePlantPhotoUseCase.swift`; ampliar ambos repositorios; LocalPlantRepository Data y conformancias/dobles sin default no-op.
- PlantTimelineView/ViewModel; composición App; PlantListView/ViewModel; PlantDetailViewModel según wiring retenido.
- Localizable.xcstrings y registro explícito de fuentes/tests en PlantCareAI.xcodeproj/project.pbxproj, conservando cambios ajenos/traducciones/IDs únicos.
- Crear `PlantCareAITests/DeleteCareEventTests.swift` y `DeletePlantPhotoTests.swift`; ampliar LocalCareEventRepositoryTests/LocalPlantPhotoRepositoryTests, PlantTimelineViewModelTests, PlantList/Detail y LastWateringHint tests pertinentes.
- Clase `DeleteCareEventUITests` en archivo UI existente y fixture Debug Simulator de fallo/commit aislada por UUID.
- Modificar `Features/PlantPhotos/Presentation/PlantPhotoPagerViewModel.swift` y `Features/PlantTimeline/Presentation/PlantTimelinePhotoViewModel.swift`; tests pager/loader de purga/tardíos/suspended/reconciliación. Revisar impacto/callers antes de verificar.

## Documentación durable

- Ahora: solo spec, PROGRESS y contrato/planner_notes feature_list por ampliación expresa; ID/dependencia/estado/evidencia intactos. Respuestas no aprueban spec integral.
- Tras aprobación/implementación: ARCHITECTURE (contrato/callbacks), domain-model (eliminación/protección), DESIGN (papelera/alerta/banner/feedback confirmado), risks (rollback/cleanup), testing-ui y handoff con evidencia real.
- CONSTRAINTS tras aprobación/implementación: inicial protegida, no selección efímera. ADR propuesto `docs/adr/012-local-history-deletion.md`: ambos contratos/commit/rollback/cleanup/consumidores, no crear ahora.
- AGENTS/init no cambian; CONTEXT no necesita vocabulario nuevo. Brief/domain-model precisarán cuidados/fotos adicionales e inicial protegida al documentar comportamiento implementado. No reescribir specs/evidencia histórica.

## Tareas

1. [ ] Aprobar spec INTEGRAL incluidos copy foto/fallback/cleanup; Q1–Q4 resueltas, no volver a preguntarlas.
2. [ ] Ambos casos/contratos/errores/pruebas Domain incluida protección inicial; conformancias/dobles.
3. [ ] Deletes actor/rollback/reopen/aislamiento y cleanup adicional postcommit/seams separados, sin schema nuevo.
4. [ ] Confirmación/banner/retry/generaciones/commit único preservando layout/scroll.
5. [ ] Callback a consumidores retenidos y recálculo watering máximo/ausencia/error sin IO fotos.
6. [ ] Purga timeline/pager, fallback inicial/reconciliación suspended, cobertura metadata/imagen tardías y cleanup.
7. [ ] Recursos/PBX/docs, autoverificación por impacto y handoff al validator independiente.

## Verificación futura — no ejecutada por planner

### Implementer, por impacto

- Domain/Data → aislamiento y rollback → DeleteCareEventTests + LocalCareEventRepositoryTests: cinco tipos, nota literal, notFound/conflict/ajeno/duplicado, fallo tras mutación, reopen sin reseed, máximo/empates/ausencia; modelos/fichas/JPEG/adicionales exactos salvo objeto borrado.
- Timeline/callbacks → lecturas tardías/consumidores → PlantTimelineViewModelTests + PlantList/Detail y LastWateringHint tests: delayed reads, foreground, cancel/fallo sin callback, éxito watering único, loaded previo invalidado.
- UI → DeleteCareEventUITests: cuidado Y foto cancel/confirm/fallo/retry/×/Cancelar/relaunch/otra planta, copy propio/ausencia toast. PlantTimelineUITests: ocho fotos ida-vuelta/nota larga/back/grupos/pie; fecha única sin debilitar assertions.
- Fotos Domain/Data → DeletePlantPhotoTests + LocalPlantPhotoRepositoryTests: initial rechazada sin writer, pertenencia/conflict/snapshot, UUID discriminados coincidentes, pre-save fault conserva metadata/JPEG, post-save cleanup fault no falsea éxito, JPEG ausente/corrupto, reopen limpia solo huérfanos tras validación global y conserva inicial/otra planta.
- Pager/loader → tests respectivos: purga/metadata/decode tardíos, cancelación drenando, selected/no-selected, fallback inicial/snapshot formularios, callback suspended/relectura fallida, extremos/una sola foto, viewport supervivientes/cache3/concurrencia2.
- UI fotos: selected eliminable→back inicial según fallback propuesto; no seleccionada conserva selección; alta sin papelera; prealta eliminada sin orden/pie incorrectos; relaunch no restaura. No repetir IA/PhotosPicker por defecto; justificar impacto transversal.

Ejemplo futuro desde raíz, con entorno preparado conforme AGENTS:

```sh
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -only-testing:PlantCareAITests/DeleteCareEventTests \
  -only-testing:PlantCareAITests/DeletePlantPhotoTests \
  -only-testing:PlantCareAITests/LocalCareEventRepositoryTests \
  -only-testing:PlantCareAITests/LocalPlantPhotoRepositoryTests \
  -only-testing:PlantCareAITests/PlantTimelineViewModelTests \
  -only-testing:PlantCareAITests/PlantPhotoPagerViewModelTests \
  -only-testing:PlantCareAITests/PlantTimelinePhotoViewModelTests \
  -only-testing:PlantCareAIUITests/DeleteCareEventUITests \
  -only-testing:PlantCareAIUITests/PlantTimelineUITests test
```

Ajustar selección a callers/diff final; E2E debe probar disco real, no borrado solo en memoria. Inspección visual focal papelera/alerta/banner con configurador UI_TEST_SCREENSHOTS documentado, único iPhone estándar/texto normal/una apariencia. No suite extra solo para capturar.

Estáticos futuros: proyecto/PBX, JSON feature/catalog, imports/typecheck Domain Foundation, git diff --check. Reusar baseline solo si coinciden inputs/config/destino relevantes; gate histórico de timeline no valida deletes nuevos. Si falta evidencia, build/diagnóstico focal, nunca gate inicial/final rutinarios. Reparaciones focales con hipótesis/fallos conservados.

### Validator, gate final

Revisión independiente y un único `caffeinate -dius ./init.sh` final sobre fuentes ejecutables: build-for-testing, fase paralela y Fotos serial. Coordinar sesión/simulador, no duplicar tests cubiertos ni gate válido exacto al cambiar de rol. Cambios relevantes invalidan evidencia: reparar focalmente primero y repetir gate solo si justificado. Para documentos solos, coherencia/diff, no tests iOS.

SE/texto ampliado/VoiceOver/matrices adicionales fuera de rutina salvo petición expresa. No se han ejecutado build/tests/init/simulador, inspección visual de app ni secretos en esta planificación.

## Evidencia futura y checklist

Registrar diff→riesgos→selección/comandos/exits/xcresult/inputs/config/destino, nuevo vs reutilizado, capturas realmente abiertas y fallos/reparaciones sin convertir aggregate Failed en verde.

- [ ] Q1–Q4 respetadas y spec INTEGRAL aprobada por separado: cuidados/fotos, SOLO inicial protegida, SIN toast, ×/Cancelar abandonan retry.
- [ ] Disco/reopen/otra planta literal, cancel cero writes, rollback real, callback postcommit.
- [ ] Último riego actualizado en detalle/card retenidos; no resurrección, scroll/cache/navegación accepted preservados.
- [ ] Foto purgada timeline/pager suspended sin repoblación tardía; fallback/selección coherentes, inicial/formularios exactos y cleanup no falsea fallo.
- [ ] UI/copy/diseño/capturas pertinentes, contratos Foundation y composición correctos; sin secretos/recursos externos.
- [ ] Harness/docs distinguen passing focalizado de accepted independiente; gate final válido cuando proceda.

## Handoff

Planner `openai/gpt-6.1-sol`, feature-flow ONE STEP, continuación documental. Usuario confirma cuidados Y fotos, SOLO inicial protegida, ×/Cancelar abandonan retry, SIN toast. Mismo ID/flujo individual y dos entidades existentes sin migración; mayor riesgo archivos/consumidores cubierto por contratos separados/cobertura ampliada, no nueva feature adyacente.
Sin dudas funcionales bloqueantes adicionales; fallback/copy/cleanup visibles como propuestas para revisión integral. Subagente tuvo edición denegada; orquestador persiste propuesta. Sin evidencia nueva ni passing/accepted.

**Siguiente exclusivo: revisión humana INTEGRAL de spec actualizada. Respuestas Q1–Q4 no implican aprobación integral. Detenerse: no implementación, validación código, builds/tests, secretos, stage/commit/push/PR/merge ni escrituras GitHub.**
