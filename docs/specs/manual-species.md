# Feature Implementation Spec: Introducir una especie conocida

## Source Feature / Estado de revisión

- `id`: `manual-species`; `area`: `identificacion`; fuente: `feature_list.json`.
- Título: «Introducir una especie conocida»; estado leído: `not_started`, sin modificar.
- Comportamiento: ante identificación incierta, introducir una especie conocida y continuar sin aceptar una propuesta IA.
- `depends_on`: `[choose-identification-photo]`, `accepted`; `confirm-species` también está `accepted` en esta base y aporta el contrato reutilizado, sin cambiar dependencias declaradas.
- Verificación de origen: introducir nombre desde el borrador, comprobar especie confirmada sin alta; gate estándar. El nombre manual no evita los cuidados posteriores.
- Fecha: 2026-10-11. **Borrador de planificación, NO aprobado por el usuario.** Feature-flow en modo explícito **UN SOLO PASO (planner)**; detenerse para revisión humana.
- Único directorio autorizado: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/manual-species`; listado/glob concuerdan con esa raíz.
- Rama `feature/manual-species` y base main/origin/main `3910d2c47f50944ad291dafc724f7c9a7a84af12`: contexto del orquestador, no comprobación Git propia. No hay herramienta shell disponible para `pwd`, status o diff.
- Solo crear esta spec: sin implementación, build/tests/init, validación de código, config secreta, Git de escritura ni GitHub. Tamaño adecuado: ampliar una identidad efímera y añadir un formulario local.

## Goal

Con foto preparada en el borrador existente, permitir confirmar explícitamente un nombre común **o** científico conocido, sin resultado IA obligatorio ni configuración/red/consentimiento requeridos para esta acción local. Dejar foto e identidad manual disponibles para `generate-care-sheet`, manteniendo claro que no se han generado cuidados ni añadido una planta.

## Non-Goals

- Generar/revisar cuidados, guardar planta, editar especie de una planta persistida, catálogo/autocompletado, verificación taxonómica, traducción o inferencia de nombres.
- Nueva API, consentimiento, persistencia, migración SwiftData, copia JPEG, historial, cuentas o backend.
- Rediseño global, cambiar comportamiento o estilo de `EditPlantView`, tocar specs aceptadas, rehacer colección/foto/propuestas.
- Copiar HTML, teclado simulado, controles de demostración, contador, avatar/Close, fuentes Google, Material Symbols o decoraciones.

## Job Story / Users And Permissions

Cuando conozco la especie o no me convencen las propuestas, quiero escribir el nombre y confirmarlo yo, para preparar después sus cuidados sin atribuir mi texto a la IA ni guardar todavía el ejemplar.

- Único usuario local; sin permisos nuevos. Especie confirmada por una persona no significa certeza botánica.
- Escribir/confirmar/cancelar/cambiar de vía: cero llamadas IA y cero escrituras de foto/identidad/consentimiento. La futura solicitud de cuidados será una intención externa distinta, con su barrera de consentimiento.

## Acceptance Scenarios (Given / When / Then)

### 1. Entrada local sin identificación previa
Given foto A preparada, incluso sin configuración IA o con error/insuficiencia, When pulso «Introducir especie conocida», Then abre «Introduce la especie» con foto actual y procedencia «Aportada por ti», sin pedir aviso ni consultar IA. Sin foto la acción no permite abrir/confirmar.

### 2. Campo y confirmación explícita
Given formulario nuevo, When el texto está vacío o solo contiene espacios/saltos de línea, Then «Confirmar especie» está deshabilitado y el dominio rechaza confirmar. When escribo `  Ficus lyrata  ` y confirmo, Then cierra solo el editor y el resumen muestra `Ficus lyrata`, identidad manual ligada a A y «Identificación manual aportada por ti (no generada por IA)». No se inventa nombre común/científico complementario.

### 3. Cancelar no es cambiar identidad
Given resultado/selección/identidad IA, o identidad manual existente, When abro el editor, modifico texto y cancelo por botón o gesto, Then se descarta solo esa edición y permanecen exactamente foto, resultado, selección e identidad anteriores. Reabrir: vacío salvo si la identidad vigente es manual, en cuyo caso precarga su nombre confirmado; no conserva texto cancelado.

### 4. Sustituir y editar identidad
Given propuesta IA seleccionada o confirmada, When confirmo un nombre manual, Then la única identidad activa es manual, sin aceptar implícitamente la propuesta ni aumentar invocaciones. Given identidad manual, When pulso «Cambiar especie», Then abre editor precargado; escribir no cambia identidad hasta confirmar. Cancelar conserva la anterior; confirmar sustituye el nombre y cierra el editor una sola vez.

### 5. Volver a propuestas sin consulta automática
Given identidad manual y resultado proposals vigente de A, When pulso «Elegir propuesta de IA», Then elimina la confirmación manual y muestra el selector conservado, incluida su selección previa si existía, pero exige confirmar explícitamente. No consulta IA. Sin propuestas vigentes no ofrece esa acción: permanecen foto, edición manual y los controles existentes para identificar expresamente.

### 6. Foto e invalidación
Given identidad manual de A y editor cerrado, When sustitución falla/cancelo picker o cámara/permiso denegado, Then A e identidad permanecen. When publica B con éxito, incluso mismos bytes/recurso con UUID nuevo, Then borra identidad y estado manual. When inicio Identificar explícitamente, Then invalida identidad desde el inicio antes de configuración/aviso; cancelar/fallar/insuficiencia no la restaura.

### 7. Disponibilidad y acciones obsoletas
Given preparación, cámara, autorización/aviso o solicitud en curso, When intento abrir/confirmar manual, Then no muta identidad ni inicia otra operación. Given editor abierto, Then bloquea las intenciones del padre (foto, cámara, identificar, seleccionar/confirmar propuesta/cambiar vía). When llega callback con sesión/foto antigua, doble confirmación o respuesta IA cancelada tardía, Then se ignora, incluso si A sigue siendo la misma foto.

### 8. Cierre y aislamiento
Given texto en edición o identidad manual, When cierro el borrador padre por Cancelar/gesto o relanzo, Then libera texto/foto/identidad y reapertura está vacía. Given dos plantas persistidas, When completo/cancelo/cambio esta vía y relanzo sin reseed/desinstalar, Then siguen los dos modelos, fichas y JPEG originales, sin alta ni archivos de borrador.

## Repository Research

### Files Inspected

- `AGENTS.md`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `CONTEXT.md`, `DESIGN.md`, `feature_list.json`, `PROGRESS.md` (registro reciente, lectura devuelta 1–164).
- `docs/{build-brief,domain-model,risks-and-open-questions}.md`, `docs/adr/005-confirmed-draft-identity.md`, `docs/specs/confirm-species.md`; skills feature-spec/template, ios-clean-mvvm y feature-flow.
- `PlantCareAI/PlantCareAIApp.swift`; `Features/PlantList/Presentation/PlantListView.swift`: fábrica nueva por apertura, cierre por binding de sheet.
- `Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift`, `Domain/IdentificationPhoto.swift`: dueño del borrador, tareas/generaciones, guards, preview `scaledToFit` y limpieza.
- `Features/ConfirmSpecies/Domain/{ConfirmedDraftIdentity,ConfirmSpeciesUseCase}.swift`, `Presentation/ConfirmedSpeciesView.swift`: identidad hoy obligatoriamente de propuesta IA y guard dependiente de resultID.
- `Features/IdentifyCandidates/Domain/IdentificationResult.swift`, `Presentation/IdentificationResultView.swift`; `Features/EditPlant/Presentation/EditPlantView.swift`: Form nativo, campos verticales con etiqueta y altura mínima 44, sin campo tonal custom.
- `PlantCareAITests/{ConfirmSpeciesTests,ConfirmSpeciesViewModelTests}.swift`; UI tests mediante búsqueda y lectura 420–544; búsquedas de callers en app, registros de fuentes/targets en `project.pbxproj` y claves relevantes en `Localizable.xcstrings`; `init.sh` completo solo lectura.
- No spec manual anterior en listado. HTML originales no están en repo: se evaluó el resumen de ambas referencias transmitido por usuario/orquestador, no archivos/capturas inspeccionados. Sin config real, productos/logs sensibles, otros worktrees ni API.

### Existing Patterns / Gaps

- Presentation → Domain ← Data, composición App, iOS 17, recursos semánticos/localizados y registro explícito de fuentes en Xcode.
- `isBusy` cubre preparación/cámara/autorización; `canIdentify` añade cámara/cierre. La nueva exclusión del editor debe aplicarse también a métodos, no solo a botones.
- `ConfirmedDraftIdentity` exige `resultID` y `proposal`: no puede representar manual honestamente. Callers reales: ConfirmSpecies, VM/changeConfirmedSpecies, resumen y tests; no hay consumidor de cuidados/alta aún.
- Inicio de identificación limpia inmediatamente; reemplazo limpia al publicar éxito; fallo mantiene A. `cancelAuthorization` incrementa generación: permite abrir manual después de cancelar aunque el doble remoto no coopere.
- Brief menciona guardar ficha al confirmar, pero el desglose vigente separa confirmación → cuidados → alta; no interpretar esa frase como escritura en esta feature. Riesgos de API con estado blocked son históricos, no bloqueos para este flujo local.

## Technical Approach

### Domain — contrato de identidad y caso de uso puro

- Ampliar `Features/ConfirmSpecies/Domain/ConfirmedDraftIdentity.swift`, conservando `Equatable, Sendable` y `photoID`. Sustituir procedencia obligatoria de propuesta por enum `Source`: `.aiProposal(resultID: UUID, selection: SpeciesProposalSelection, commonName: String?, scientificName: String?)` / `.manual(name: String)`.
- Los nombres y revisión IA pertenecen solo a esa variante. Mantener accesores `commonName`/`scientificName` derivados para el resumen IA; manual devuelve nil en ambos y expone `manualName`. No colocar texto manual en scientificName/commonName, ni fabricar resultado, alternativa, revisión IA o certeza.
- Actualizar `ConfirmSpecies` para producir `.aiProposal` sin cambiar validación/pertenencia/nombres exactos. Migrar callers/tests al switch de source (o accesores opcionales derivados), nunca hacer resultID/proposal falsos para conservar compilación.
- Crear `Features/ManualSpecies/Domain/ConfirmManualSpeciesUseCase.swift`: protocolo estrecho para inyección/test de fallo y struct `ConfirmManualSpecies` síncrona/pura. Entrada `photoID`, texto; salida identidad `.manual` o error tipado `.emptyName`.
- Normalizar **solo extremos** con `.whitespacesAndNewlines`; rechazar vacío resultante; preservar mayúsculas, tildes, puntuación y espacios/saltos interiores. Sin límite/contador nuevo, autocorrección, clasificación común/científico ni validación taxonómica. No reutilizar límites/prohibición de porcentajes de propuestas IA para texto humano. Texto seguirá siendo dato no confiable para futuros prompts.

### Presentation — propiedad y transiciones

- Reutilizar `IdentificationPhotoViewModel` como único dueño de foto, identidad y sesión manual; no VM/repository paralelo. Inyectar `any ConfirmManualSpeciesUseCase`.
- Añadir sesión publicada privada `ManualSpeciesDraft` (tipo Presentation, en el archivo VM): UUID nuevo por apertura, photoID y texto editable mediante intención del VM; error local separado de error IA. No duplicar JPEG; vista recibe preview de la foto ya existente.
- Intenciones concretas: `beginManualSpecies()`, `updateManualName(_:sessionID:)`, `confirmManualSpecies(sessionID:)`, `cancelManualSpecies(sessionID:)`, `returnToAIProposals()`. VM comprueba abierto, !busy, !presentsCamera, photoID vigente y sesión exacta para cada edición/confirmación/cancelación.
- Abrir no borra identidad/resultado/selección ni errores de la identificación. Precargar solo identidad manual vigente. Guardar confirmación solo tras éxito del caso de uso; error deja sesión/texto y confirmación previa intactos, con mensaje local. Éxito reemplaza identidad, limpia error local de confirmación y termina sesión; doble callback no opera sin esa sesión.
- Conservar resultado/revisión/selección IA de A como opciones no activas al confirmar manual; ocultarlas en resumen, sin dos identidades. `returnToAIProposals` exige resultado proposals asociado a foto/revisión actuales y no editor/busy/cámara; borra solo identidad y error local, vuelve al selector, no confirma ni envía.
- `changeConfirmedSpecies`: switch de source; IA conserva guard de revisión y comportamiento aceptado de borrar/reconfirmar; manual exige photoID y abre editor sin borrar confirmación. No exigir revisión IA a identidad manual.
- Añadir `canEnterManualSpecies` y `isEditingManualSpecies`; abrir exige además ausencia de sesión (doble apertura no reemplaza su token/texto). Excluir editor en `canIdentify`, `canSelectProposal`, `select`, `takePhoto`, change/return. No redefinir espera IA ni permitir editor sobre el aviso/cámara. Cancelar solicitud existente es el paso previo si estaba en curso.
- `clearIdentification()`/close/publicación de B también eliminan sesión/error manual. Ninguna cancelación del editor llama `close()` ni `cancelAuthorization()`; cerrar padre sí libera todo con generaciones existentes. Binding/onDismiss captura UUID: no cancelar accidentalmente una sesión nueva o la identidad recién confirmada.

### Data / Composición / Handoff

- Data nueva: ninguna. No disco/UserDefaults/red para manual. Flujo real: ManualSpeciesView → IdentificationPhotoViewModel → ConfirmManualSpecies → ConfirmedDraftIdentity; sin repositorio artificial.
- `PlantCareAIApp.swift` inyecta `ConfirmManualSpecies()` en la fábrica ya existente. Identificación/configuración/consentimiento y LocalPlantRepository permanecen intactos.
- Futuro generate-care-sheet consumirá photo + identidad del mismo dueño, exigirá photoID coincidente y tratará manual como nombre aportado por usuario. Será el paso real que sustituya el resumen provisional (decisión registrada en PROGRESS), no un paso adicional obligatorio. Save-plant decidirá mapeo/persistencia; no activarlos aquí.

## Visual Design Impact / Alternativas evaluadas

- UI: sí. Autoridad `DESIGN.md`, SwiftUI nativo y coherencia con EditPlantView; ambas referencias son propuestas, no aprobaciones.
- **A — sheet «Introduce la especie» (RECOMENDADA, pendiente de aprobación):** encaja con editor transaccional Cancelar/confirmar, patrón Form de EditPlant y sheets existentes; evita intercalar teclado y propuestas en el scroll largo, y separa procedencia de IA. Coste: sheet encima del modal actual, por lo que hay que probar gesto del editor vs cierre del padre y no presentar dos sheets a la vez.
- **B — formulario integrado bajo foto:** reutiliza scroll/preview sin segundo modal y permite comparar foto grande al escribir. Pero introduce modo alternativo con vuelta/cancelación dentro de un scroll con resultados/acciones y estilo Form distinto del editor actual; aumenta riesgo de confundir edición con reidentificación. No se recomienda para esta slice. Si el usuario lo elige, revisar esta spec antes de implementar.
- A adaptada: NavigationStack + Form, título inline, Cancelar nativo, confirmación explícita «Confirmar especie» en sección con botón nativo primario; nada de «Guardar». Miniatura orientativa de ~64 × 64 usando foto preparada y `scaledToFit`, junto a «Borrador actual» y procedencia; no prometer «100% encuadre» ni usar imagen de ejemplo.
- Campo exactamente con patrón actual de EditPlantView: etiqueta visible «Especie», `TextField` vertical nativo, mínimo 44 pt, sección Surface/fondo Background/texto TextPrimary/tint PrimaryAction. Placeholder orientativo «Ficus lyrata, Potus, Costilla de Adán»; ayuda acepta nombre común o científico. Sin nuevo campo tonal redondeado/icono interior ni componente compartido extraído por anticipación.
- Mantener estilo y comportamiento de EditPlantView **sin cambios**. Si después se aprueba un campo tonal distinto, revisar alcance: aplicarlo coherentemente a ambos formularios, sin cambiar reglas de edición, y añadir regresiones unit/UI de editar/cancelar/guardar/ubicación; no implementarlo solo en manual.
- Teclado real con autocorrección y autocapitalización desactivadas, acción «Listo» para quitar foco (no confirmar automáticamente), scroll que permite alcanzar confirmación. No copiar teclado HTML, contador demo ni botón limpiar custom que no existe en EditPlant; borrado normal del campo suficiente.
- Ayuda: «Esta acción solo confirma la identidad del borrador. No guarda la planta ni genera cuidados todavía». No usar el reclamo B «se guardará textualmente»; explicar si hace falta que se eliminan espacios de extremos, sin corregir el nombre.
- Añadir entrada «Introducir especie conocida» junto al área de identidad, separada de consulta IA; visible con foto lista en sin resultado/propuestas/insuficiencia/error, deshabilitada mientras busy/cámara, no escondida por configuración ausente. En resumen IA puede ofrecerla para cambiar de vía; manual usa Cambiar especie y, solo si existe, Elegir propuesta de IA.
- Resumen existente adaptado por source: manual muestra su texto una vez y procedencia explícita; IA mantiene nombres/advertencias actuales. Ambos mantienen aviso de borrador/no certeza/cuidados futuros y bloque secundario de foto/Identificar. Mostrar separación/título de reidentificación si hay identidad manual incluso sin resultado IA.
- Textos en `Localizable.xcstrings` con fallback español; SF Symbols si se usan, tokens existentes, etiquetas/traits y objetivos ≥44 pt. No assets ni nueva fuente. Estados vacío/rellenado/teclado/error/cancelación/largos deben ser funcionales, no controles para alternar demos. No artefacto gráfico adicional requerido.

## Expected File Changes (solo futura implementación)

- Crear `PlantCareAI/Features/ManualSpecies/Domain/ConfirmManualSpeciesUseCase.swift` y `Presentation/ManualSpeciesView.swift` (Form sin VM nuevo).
- Modificar `Features/ConfirmSpecies/Domain/{ConfirmedDraftIdentity,ConfirmSpeciesUseCase}.swift`, `Presentation/ConfirmedSpeciesView.swift`: source discriminada y representación/manual/change/return.
- Modificar `Features/IdentificationPhoto/Presentation/{IdentificationPhotoViewModel,IdentificationPhotoView}.swift`: sesión/guards/transiciones, sheet/entrada y bloque de acciones. No cambio necesario a IdentificationResultView.
- Modificar `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/Localizable.xcstrings`, `PlantCareAI.xcodeproj/project.pbxproj`: inyección, claves usadas y registro explícito app/test.
- Crear `PlantCareAITests/{ConfirmManualSpeciesTests,ManualSpeciesViewModelTests}.swift`; migrar aserciones de source en `ConfirmSpeciesTests`/`ConfirmSpeciesViewModelTests`; ampliar `PlantCareAIUITests/PlantCareAIUITests.swift`.
- Docs según sección siguiente. No tocar EditPlantView, transporte/config, entidad/repositorio local, ContentView, Assets ni init.sh. Dobles suspendidos existentes bastan para concurrencia; ampliar fixture solo si falta un seam concreto, siempre Debug Simulator.

## Durable Documentation Impact (después de aprobación / implementación)

- `ARCHITECTURE.md`: actualizar inventario/flujo manual, identidad source y propiedad/guards del borrador; dirección de dependencias sin cambio.
- `docs/adr/005-confirmed-draft-identity.md`: ampliar con variante manual, migración de callers IA y reglas cancelación/vuelta. Cambio del contrato compartido requiere ratificación en revisión humana de esta spec; no reescribir spec confirm-species aceptada.
- `docs/domain-model.md`: actualizar capacidad local y transiciones manual/IA, sin cuidados/alta todavía. `DESIGN.md`: registrar alternativa A adaptada solo cuando el usuario la apruebe, conservando estilo Form común.
- `CONSTRAINTS.md`: no necesario, límites locales/privacidad ya cubiertos. `AGENTS.md`: no necesario, workflow no cambia. `CONTEXT.md` y `docs/build-brief.md`: no necesario, manual ya contemplado.
- `PROGRESS.md`/`feature_list.json`: futuros estado/evidencia veraces por rol; ahora intactos. `docs/handoffs/manual-species.md`: futura entrega con comandos, riesgos y límites, sin evidencia inventada.

## Implementation Plan / Tasks

1. Obtener revisión humana D1–D3; confirmar worktree/status y coordinar sesión/simulador. No iniciar siguiente rol por defecto.
2. Ampliar source y migrar callers IA; implementar caso puro manual con unitarias.
3. Integrar sesión/tokens/guards/transiciones e inyección; comprobar VM con dobles, incluidos fallos/tardías.
4. Añadir sheet/Form/entrada/resumen/localización y registrar fuentes; conservar estilo de edit-plant.
5. Añadir E2E focalizadas/regresiones, inspeccionar pantallas, registrar documentación/evidencia; entregar al validator.

- [ ] Source discriminada sin nombres/revisión IA fingidos; caso de uso puro y caller IA sin regresiones.
- [ ] Sesión manual aislada, cancelación no destructiva, tokens foto/sesión y exclusión de operaciones.
- [ ] Sheet A nativa, Form consistente con EditPlant, resumen/procedencia/no alta y vuelta explícita.
- [ ] Unit/VM/UI registradas, confirmación local sin invocaciones/escrituras y aislamiento de dos plantas.
- [ ] Verificación por impacto, documentación y handoff con gate final pendiente del validator.

## Verification Plan (futuro, NO ejecutado por planner)

### Implementer — checks por impacto

- Identidad/caso de uso → nombres/procedencia/callers → ConfirmManualSpeciesTests + ConfirmSpeciesTests: trim, blancos/newlines, Unicode/interior/200+ caracteres y copia IA exacta/selección inválida. Sin límite arbitrario de entrada.
- VM/guards → cancelar/editar/cambiar vía/obsolescencia → ManualSpeciesViewModelTests + ConfirmSpeciesViewModelTests + IdentificationPhotoViewModelTests + IdentificationConsentViewModelTests: todos los escenarios, sesión antigua con misma foto, fallo de caso puro conserva identidad, cámara/busy, cierre, reemplazo y reidentificar antes del aviso; continuación suspendida cancelada que termina después de confirmar manual nunca la sustituye.
- Sheet/composición/localización → cierre equivocado/scroll/counter → nuevas UI `testManualSpeciesWithoutAIAndCancelEdit`, `testManualSpeciesFromProposalsAndReturn`, `testManualSpeciesInvalidationCloseAndStorageIsolation`; actualizar harness sin debilitar assertions históricas. Regresión `testConfirmSpeciesAlternativeAndDraftInvalidation` y `testIdentificationInsufficientNoAlternativesAndExplicitErrorRetry` por callers/layout compartidos. No UI edit-plant focalizada si su código/estilo no cambia; suite completa final la conserva.
- Comando base, añadir `-only-testing:<target>/<suite o método>` para la selección anterior: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO -only-testing:PlantCareAITests/ConfirmManualSpeciesTests -only-testing:PlantCareAITests/ManualSpeciesViewModelTests test`. Nombres UI anteriores son nuevos a crear; scheme/targets actuales existen.
- XCUITest es el E2E persistente del repo, incorporado en init; cubrir blancos, manual antes de cualquier IA/config ausente (contador 0), propuestas/insuficiencia/error, cancelación por botón/gesto del editor, edición precargada, ida/vuelta IA sin incremento, largos y teclado real/scroll. Cierre de padre confirmado y reapertura vacía, relaunch sin reseed + `--storage-verify`/ambos detalles para modelos/JPEG exactos. Sin prueba de API real nueva necesaria: transporte no cambia.
- Reusar evidencia histórica 108/108 solo como baseline si se corrobora mismo estado relevante/config/destino, nunca como prueba de manual. Si falta, build/diagnóstico focalizado antes de ampliar; no gates completos por rutina.
- Coordinar entorno seguro dentro del único worktree, simulador estándar/texto normal/una apariencia, ejecución serial. No leer/copiar/modificar config real: acordar fuentes/config sintética para futuras builds si existe; sin ella, preparación de plantilla pública vacía según AGENTS en el rol autorizado. Nada de red real ni logs de texto/fotos/secretos.
- Estáticos futuros: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, `python3 -m json.tool PlantCareAI/Localizable.xcstrings`, `git diff --check`; no sustituyen comportamiento. Tras fallo, conservarlo y repetir primero escenario fallido/pruebas afectadas con hipótesis explícita, sin retries para lograr verde.

### Validator — gate final

- Un único `caffeinate -dius ./init.sh` sobre fuentes finales o evidencia íntegra corroborada de esas mismas fuentes/entorno; no repetir focalizadas cubiertas sin laguna. Init ejecuta build + unitarias + UI/siembra fotos sintéticas y termina, no inicia servicios; no modificarlo.
- Inspección visual básica en simulador estándar de formulario vacío/rellenado/teclado/largo y resumen manual/IA, cancelación y acciones alcanzables; coherencia del campo con EditPlant por lectura/inspección. Mantener host despierto/tapa abierta.
- Una reparación de producto/tests/harness/config relevante invalida evidencia y puede justificar nuevo gate; primero diagnóstico focalizado. Gate fallido nunca aprobado. SE/texto aumentado/VoiceOver/Inspector/matrices no solicitadas: fuera de habitual, no ejecutadas ni requisito pendiente; soporte de accesibilidad se conserva.
- Este paso de planificación es solo documental: revisión de coherencia/contenido; no build ni suite iOS.

## Evidence To Capture / Validator Checklist

- Comandos/selección y motivo, estado exacto de fuentes/config sintética/destino, conteos/fallos, evidencia nueva vs reutilizada, gate pendiente o final válido; no compartir artefactos compilados con clave real.
- Capturas sin secretos: formulario vacío/rellenado/teclado/largo, resumen manual con aviso, vuelta a propuesta y B sin identidad. Registrar counter 0/sin incremento, aislamiento completo y límites en PROGRESS/feature_list solo después de ejecutar.
- [ ] Escenarios 1–8, manual no es propuesta IA ni certificación botánica; sin alta/cuidados/invocación/escritura.
- [ ] Source honesta, photoID/sessionID vigentes, cancelar conserva anterior, editor/cámara/aviso mutuamente excluyentes, tardías no reviven estado.
- [ ] Regresión IA/confirmación/cancelación/foto y dos plantas persistidas intactas; E2E funcional sin assertions debilitadas.
- [ ] Presentation/Domain/composición correctas, sin Data falsa, fuentes registradas y recursos locales nativos.
- [ ] Form coherente con EditPlant sin rediseño, teclado/scroll/largos funcionales y accesibilidad conservada.
- [ ] Docs/estado/evidencia veraces; passing focalizado no es accepted; aceptación independiente y gate final válido cuando corresponda.

## Decisions / Riesgos / Revisión humana requerida

- **D1 aprobada por el usuario (2026-10-11):** alternativa A adaptada con sheet/Form nativo compartiendo el estilo actual de EditPlant, sin rediseñar los campos. B no seleccionada.
- **D2 aprobada por el usuario (2026-10-11):** aceptar nombre común o científico, sin autocompletado ni comprobación botánica y sin límite de caracteres. Quitar solo espacios/saltos de línea de los extremos al confirmar el campo «Especie» de «Introduce la especie», sin modificar su interior ni EditPlant. Nombre manual en su variante propia, sin commonName/scientificName inferidos.
- **D3 aprobada parcialmente por el usuario (2026-10-11):** cancelar conserva la identidad anterior; volver a propuestas exige reconfirmación explícita. Se mantienen los escenarios 3–5 con esas reglas. Esta confirmación no aprueba D1/D2 ni la spec completa; las reglas adicionales de invalidación al reidentificar y al reemplazar foto siguen siendo la propuesta técnica descrita, no una aprobación expresa en este mensaje.
- Riesgos principales: fuente IA/manual mezclada, guard antiguo de resultID que impida editar manual, doble sheet/cierre del padre por gesto, callback obsoleto con misma foto, borrar identidad ante fallo de reemplazo y texto presentado como guardado. Contrato/tokens/UI/tests anteriores los acotan.
- No duda técnica bloqueante adicional tras las lecturas indicadas; decisiones de producto/visual requieren revisión humana. **Detenerse aquí: siguiente acción revisión de esta spec, no implementación/validación/commit ni aprobación inferida.**

## Comprobaciones de este paso documental

- Relectura de la spec creada, cotejo con plantilla, metadatos/dependencias, arquitectura, código investigado y requisito de coherencia con EditPlant. Escenarios, archivos/tareas, ambas alternativas y verificación por rol incluidos; dentro del objetivo 100–250 líneas.
- Único archivo escrito por planner: `docs/specs/manual-species.md`. PROGRESS/feature_list y código intactos por este rol; no cambios de estado ni aprobación humana registrada.
- No ejecutados `pwd`, Git status/diff ni `git diff --check` (sin herramienta shell); no atribuirlos como checks superados. Sin build/tests/init, simulador, lectura/configuración de secretos ni Git/GitHub de escritura.
