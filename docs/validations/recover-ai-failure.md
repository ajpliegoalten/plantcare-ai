# Validación independiente documental — recover-ai-failure

2026-10-14 · Validator `openai/gpt-6.1-sol` · **Veredicto: accept**.
Spec: `docs/specs/recover-ai-failure.md`.

Aceptación del **cierre documental por comportamiento existente**, conforme a la aprobación explícita del usuario de cero código/tests adicionales y cobertura offline combinada. No es una nueva certificación ejecutable de la app. No findings bloqueantes ni repair brief. `feature_list.json` sigue `not_started`, con evidencia propia vacía, deliberadamente: el orquestador debe persistir `accepted` tras este veredicto, sin inventar una transición `passing` ni pruebas nuevas.

## Alcance, autorización y estado revisado

- Trabajo exclusivo en `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/recover-ai-failure`; `pwd` lo confirmó.
- HEAD observado por `git log -4 --oneline`: `6c259a4`, merge de PR50, precedido por `d16806f`, `52e0fb4` (producto de branding aceptado) y `3033dbc`.
- Estado recibido: modificaciones únicamente en `PROGRESS.md` y notas de `feature_list.json`; spec nueva sin seguimiento. Sin diff staged ni delta de producto/tests/harness. Dependencias identify-candidates/generate-care-sheet/analyze-current-photo y apoyos save-plant/plant-timeline/keep-analysis/app-launch-branding están `accepted`.
- Usuario autoriza esta revisión documental posterior; las frases de la spec/PROGRESS sobre autorización aún pendiente describen el paso anterior. Este informe sucede esa espera, sin reescribir historia ni specs aceptadas.
- Aplicadas feature-validator (rúbrica y security checklist) y guía local ios-clean-mvvm, leída desde `.agents/skills/ios-clean-mvvm/SKILL.md` antes de inspeccionar Swift.

## Fuentes revisadas

AGENTS, CONTEXT, ARCHITECTURE, CONSTRAINTS, DESIGN, brief, modelo de dominio y riesgos; spec seleccionada, feature_list/PROGRESS y diff actual. Informes independientes leídos:

| Evidencia histórica | Registro y pertinencia |
| --- | --- |
| E1 | `docs/validations/identify-candidates.md`, veredicto vigente accept 2026-10-10: recuperación explícita conservando foto; gate94/94 y focal28/28 corroborados entonces. Relato de API real atribuido al usuario, no a este validator. |
| E2 | `docs/validations/generate-care-sheet-V2.md`, accept 2026-10-11: fallo/retry sin ficha parcial, cancelación/aislamiento, gate146/146. Corresponde a cuidados antes del alta directa posterior, no certifica por sí solo esa cadena. FAILED145/146 permanece histórico. |
| E3 | `docs/validations/analyze-current-photo.md`, accept 2026-10-13: error/retry, query/zona fijos, sin huella y consentimiento; gate337/337. Sus botones futuros son antecedentes, no UI vigente. |
| E4 | `docs/validations/app-launch-branding.md`, **apéndice V3 vigente**, junto a registro accepted en feature_list/PROGRESS: gate390/390 (296unit+92UI+2Photos), worker1 autorizado/default5 intacto, 189inputs públicos referidos. No se toma la cabecera BLOCK histórica como veredicto final ni se convierte V1/V2FAILED en aprobados. |
| E5 | `docs/validations/keep-analysis.md`, accept 2026-10-13: lectores reales/texto durable, retry local literal sin HTTP; gate357/357. |
| Apoyos | Entradas accepted/evidencia independiente de save-plant (160/160) y plant-timeline (254/254 y corrección260/260) en feature_list. Estos números son registros históricos, no resultados nuevos. |

Inspección directa de los tres adaptadores `OpenAICompatible*Repository.swift`, IdentificationPhotoViewModel/View, GenerateCareSheetUseCase, PlantCreationStatusView, PlantPhotoAnalysisViewModel/View, AuthorizeExternalAIOperationUseCase, composición PlantCareAIApp, lectores Domain de colección/detalle/timeline y `LocalPlantRepository.loadPlants`. Se leyeron cuerpos de los 26 tests nombrados en la spec y los helpers UI de identificación, cuidados y relaunch de análisis. No basta con que un selector exista: se contrastaron sus aserciones y límites con el criterio.

## Mapa independiente de criterios

| Criterio | Comportamiento / cobertura existente contrastada |
| --- | --- |
| C1 Identificación | Adaptador tipa URLError/status/timeout y realiza una petición sin bucle de retry. Catch del VM no borra foto ni publica resultado falso; Identificar cruza de nuevo autorización. `testServiceFailureIsNotInsufficientAndRetryIsExplicit` comprueba network→foto/no resultado/1 llamada→retry humano/2. Transporte simula desconexión; `testIdentificationExplicitErrorRetry` usa **rate-limit**, comprueba sin manual/confirmación y preview120×80 conservada. E1 y continuidad E4. |
| C2 Cuidados | Domain exige seis campos; solo `.completed(sheet)` inicia alta, catch conserva identidad/foto y no guarda. Transporte cubre500/desconexión/inválidos; `testFailureIncompleteRetryAndEditingRestoresExactSheet` cubre network→incompleta→válida. UI `testCareSheetNetworkFailureAndExplicitRetry`/`testCareSheetIncompleteResponseAndExplicitRetry` comprueban error/identidad/contador1→2 y ficha tras alta recuperada; cancelación/cierre verifica dos plantas originales al relanzar sin reseed. E2 histórico más cadena actual estática/E4; no confundir la antigua ausencia de alta con el comportamiento vigente. |
| C3 Análisis | Fallo descarta prepared/result sin escritor, conserva identidad/queriedAt/zona; retry prepara de nuevo por intención. Transporte desconectado/timeout/status y conteo único; `testNetworkFailureExplicitRetryNoAutomaticRetryAndDiskExactRelaunch` comprueba fallo sin provisional,1→retry→resultado/2 y relaunch con verificadores de disco. `testRetryKeepsCapturedQueryAndReferenceZone` es **retry tras cancelar consentimiento**, no fallo remoto; estabilidad temporal además visible en propiedades `let` del VM. E3/E4. |
| C4 Local offline | App conecta colección/detalle/timeline al mismo actor local antes e independientemente de crear proveedores remotos. Lectores no exigen consentimiento/éxito/config IA; errores se propagan, no vacío ficticio. Tests reales `testRealViewSessionScrollRetryRefreshContextNeverCommitsOrChangesBytes`, `testRealStoreUnionAllKindsPhotosPreOriginIdentityAndReadOnlyReopen` y detalle sin JPEG verifican lectura/reopen/aislamiento/bytes y cero commits de consulta. UI storedRelaunch y texto guardado bajo placeholder apoyan durabilidad. E3/E5, accepted timeline y E4. **Cobertura combinada**, no un recorrido único de caída de las tres operaciones y apertura de todo el historial ni modo avión observado. |
| C5 Persistencia distinta | `retrySave` reutiliza creationSnapshot sin authorize/generateCare; análisis `save()` reutiliza acceptance literal, separado de error remoto. `testLocalRetryStableSnapshotNoAIAndEditingCancelNoAutoWrite` prueba incluso configuración IA ahora inválida; `testLocalSaveRetryKeepsLiteralSnapshotResultNoExtraHTTPAndCallbackOnce` comprueba snapshot igual/una llamada provider/callback único. UI local-failure de SavePlant y KeepAnalysis conserva resultado y no vuelve a IA. E5 y aceptación save-plant/E4. |
| C6 Cancelación/privacidad | Generaciones/closed/configuración protegen continuaciones; consentimiento cruza Domain antes del envío. Tres tests de cancelación/tardíos nombrados en spec mantienen foto o liberan sesión y no publican respuesta obsoleta. Adaptadores efímeros sin cache/cookies/credentials, redirects rechazados, deadlines y cancelación; no retry automático ni logs sensibles encontrados en los tres. E1/E2/E3/E5 y lectura actual. |

Conclusión: los seis escenarios tienen respaldo pertinente. El usuario aprobó expresamente la combinación transporte simulado + retry UI + almacenamiento real/read-only; no se exige añadir un E2E monolítico para cerrar esta entrada redundante. No se encontró una laguna de producto que justifique implementación adicional.

## Comprobaciones NUEVAS realmente ejecutadas

Todas estáticas/documentales, sin ejecución Swift ni acceso a configuración privada:

- `pwd`, `git status --short`, `git diff --stat`, `git diff --cached --stat`, `git diff -- PROGRESS.md feature_list.json`, `git log -4 --oneline`, `git diff HEAD --name-only`: raíz/estado/delta exclusivamente documental confirmados.
- `git diff --name-only 52e0fb4 HEAD -- PlantCareAI PlantCareAITests PlantCareAIUITests PlantCareAI.xcodeproj/project.pbxproj PlantCareAI.xcodeproj/xcshareddata/xcschemes init.sh scripts`: **sin salida**. Establece continuidad Git de las rutas ejecutables inspeccionadas desde el commit de producto asociado a E4, no igualdad con un manifest de gate ni configuración privada.
- Python parse JSON y unicidad de IDs: correctos; estados de dependencia comprobados. Extracción de selectores desde spec y búsqueda de declaraciones: **26 encontrados, 0 ausentes**; cuerpos/helpers revisados por lectura, no ejecutados.
- `git diff --check`: correcto antes y después de persistir informe. Comprobación adicional de whitespace de spec/informe nuevos mediante Python: correcta.
- Búsqueda scoped `print\(|debugPrint\(|NSLog|Logger|os_log` en adaptadores OpenAI-compatible: sin coincidencias. No auditoría global de logs.
- Dos incidencias de comandos de lectura se corrigieron, sin tests afectados: nombre supuesto `AuthorizeExternalAIOperation.swift` no existía (grep localizó `AuthorizeExternalAIOperationUseCase.swift`, leído después); `rg` no disponible en shell (usada herramienta grep). No se presentan esas invocaciones como exitosas.

## Historia frente a evidencia vigente y límites

Los informes E1–E5 contienen aceptación independiente y resultados ejecutables históricos suficientes como antecedente de capacidades existentes. La lectura de código/tests actuales corrobora **pertinencia funcional** y el diff muestra ausencia de impacto ejecutable en este cierre. E4 es el registro completo más reciente y ya posterior a las evoluciones de alta/Keep/Discard que importan aquí.

**No se reabrieron xcresults, manifests, capturas ni productos de sesiones anteriores, ni se cotejaron sus hashes con este worktree.** El digest de189inputs en E4 es una referencia histórica, no un hash recalculado/corroborado aquí. No se afirma igualdad del entorno/configuración actual con el probado entonces; tampoco se reutiliza390/390 como un gate nuevo o recertificado de estas fuentes. La continuidad Git observada no sustituye esos contrastes si hubiera cambios ejecutables futuros.

Gate nuevo **no aplicable** por cierre únicamente documental autorizado y política AGENTS. No se ejecutaron builds/tests/init, simuladores, API, smoke humano/visual, lectura de secretos/config real, staging/commit/push/PR/merge. Matrices ampliadas no solicitadas fuera de verificación habitual, no ejecutadas ni bloqueos. No se certifica servicio real actual, precisión botánica, estabilidad universal del simulador, restauración de borradores tras cierre, retirada de bytes/costes enviados ni resistencia del disco a daño físico.

## Calidad, seguridad y documentación

Sin nuevos contratos/capas/adaptadores/persistencia/harness: Presentation→Domain←Data y composición App coherentes con arquitectura. Lectura local no depende del proveedor; retry remoto y commit local siguen separados. Checklist de seguridad scoped: **sin hallazgos relevantes bloqueantes** en diff documental y caminos de apoyo revisados; no secretos publicados/leídos, autorización vigente no debilitada, input/output acotados y errores tipados sin contenido remoto crudo. Riesgo conocido de credencial Debug extraíble y cancelación sin revocación remota permanece; sin cuentas/servidor ni garantías comerciales nuevas.

No corresponde modificar ARCHITECTURE/CONSTRAINTS/DESIGN/dominio/testing porque no cambia comportamiento. Spec conserva correctamente la atribución histórica y la interpretación offline aprobada. Sus notas de etapa pendiente quedan sucedidas por autorización actual e informe; no requieren reparación editorial para aceptar. Harness intacto, no revalidado ejecutablemente en esta sesión.

## Handoff y archivos cambiados por este validator

- **Único archivo creado:** `docs/validations/recover-ai-failure.md`. Ninguna edición de spec, producto/tests o estado; cambios previos de planner/orquestador preservados.
- Orquestador: persistir `accepted` y enlazar este informe/spec/aprobación de cobertura existente en feature_list/PROGRESS, registrando **aceptación documental sin nueva ejecución**, sin falso `passing`. Suceder las notas de espera de autorización al registrar cierre, conservando los antecedentes.
- No reparación ni nueva implementación requerida. Publicación exclusivamente por orquestador bajo autorización del usuario; este rol se detiene tras el veredicto y no realiza operaciones Git de entrega.
