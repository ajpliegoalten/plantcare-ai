# Feature Implementation Spec: Confirmar una especie propuesta

## Source Feature / Estado de revisión

- `id`: `confirm-species`; `area`: `identificacion`; fuente: `feature_list.json`.
- Título: «Confirmar una especie propuesta»; estado leído: `not_started` (sin modificar).
- `depends_on`: `[identify-candidates]`; `accepted` con aceptación independiente registrada en feature_list/PROGRESS.
- Comportamiento: aceptar candidata o alternativa antes de solicitar la ficha de cuidados.
- Verificación de origen: elegir alternativa distinta de la principal y comprobar identidad confirmada del borrador, sin alta automática; gate estándar.
- Fecha: 2026-10-10. **Spec revisada por el usuario: decisiones D1–D3 aprobadas explícitamente; no implementada.** Una feature de tamaño adecuado: una identidad efímera y un flujo de selección/confirmación.
- Único directorio autorizado: `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/confirm-species`; rutas absolutas de glob coinciden. Sin herramienta shell disponible para `pwd`/Git: rama `feature/confirm-species`, limpieza y base `a22879e20fdb012314412bcd73ad20d08822c692` son contexto comunicado por el orquestador, no comprobación propia.
- Solo se crea esta spec. No builds/tests/init, validación de código, secretos, modificaciones de estados, Git de escritura ni GitHub. No issue/PR creada o consultada.

## Goal

Sobre el resultado ya obtenido en el modal de identificación, permitir seleccionar explícitamente la principal o una alternativa y confirmar esa elección como identidad **del borrador en memoria**. Seleccionar no confirma; confirmar no identifica científicamente ni guarda una planta. La foto y los nombres elegidos quedan disponibles para la futura generación de cuidados.

## Non-Goals

- Introducción manual (`manual-species`), generación/solicitud de cuidados (`generate-care-sheet`), formulario y persistencia de alta (`save-plant`).
- Nuevo transporte, cambios de proveedor/configuración/consentimiento, inferencias al seleccionar/confirmar o catálogo global Species.
- Rehacer estados aceptados de espera/error/insuficiencia, importación, permisos o navegación de Mis plantas; cambiar specs aceptadas.
- Migraciones, escritura de UserDefaults de identidad, almacenamiento temporal en disco, historial, backend/cuentas o garantías de precisión botánica.
- Copiar HTML/Tailwind/Material Symbols, pills de demostración, tabs, barra de estado web o footer decorativo de Stitch.

## Job Story / Users And Permissions

Cuando veo varias propuestas para mi foto, quiero elegir la que considero correcta y confirmarla expresamente, para preparar los cuidados de mi ejemplar sin aceptar automáticamente la IA ni darlo de alta todavía.

- Único usuario local sin cuentas/roles; confirmación humana, no certificación botánica.
- Selección y confirmación son locales: cero nuevas llamadas IA y cero escrituras del borrador. Consentimiento de envío y confirmación de especie son acciones distintas.

## Acceptance Scenarios (Given / When / Then)

### 1. Principal sin aceptación implícita
Given foto A y resultado válido con principal, When se presenta el resultado, Then ninguna candidata está seleccionada, no hay identidad confirmada y «Confirmar especie» está deshabilitado. When selecciono la principal, Then aparece «Seleccionada», pero sigue siendo propuesta. When pulso Confirmar especie, Then el resumen muestra sus nombres como «Especie confirmada por ti», conserva A y aclara que la planta no se ha añadido.

### 2. Alternativa y selección única
Given principal y alternativas disponibles, When selecciono una alternativa y confirmo, Then la identidad contiene exactamente los nombres de esa alternativa, nunca los de la principal. Seleccionar otra tarjeta antes de confirmar reemplaza la selección, no acumula identidades. Principal sin alternativas también se puede seleccionar/confirmar; no hay sección vacía ni alternativas inventadas.

### 3. Cambiar una identidad confirmada
Given identidad confirmada de A, When pulso «Cambiar especie», Then se borra la confirmación, reaparece el resultado con la elección anterior seleccionada y se requiere otro toque explícito de Confirmar especie. Elegir otra propuesta no confirma por sí solo. El resumen no ofrece cuidados activos ni Añadir/Guardar.

### 4. Sustituir foto sin mezclar identidades
Given A seleccionada o confirmada, When se prepara B correctamente (incluso el mismo recurso elegido de nuevo con nuevo UUID), Then se invalidan resultado, selección, revisión e identidad de A; B queda sin identificar/confirmar y no envía nada. When cancelo el picker/cámara, falla la transferencia/preparación o el permiso no permite capturar, Then A, su resultado, selección e identidad permanecen; durante preparación/cámara no se puede confirmar.

### 5. Reidentificar, cancelar y recuperar
Given selección/confirmación de A, When inicio explícitamente Identificar de nuevo, Then se limpian resultado, selección e identidad desde el inicio, antes del aviso/validación de configuración, manteniendo A. When cancelo aviso o solicitud, hay error/indisponibilidad/insuficiencia, Then no se restaura la identidad anterior. Un nuevo resultado comienza sin selección aunque repita nombres. Reintentar es explícito y conserva la barrera de consentimiento existente.

### 6. Sin propuestas o con operación en curso
Given sin foto/resultado, insuficiencia, error, aviso, espera, preparación o cámara abierta, When intento seleccionar/confirmar, Then no se crea identidad. No aparecen tarjetas seleccionables en insuficiencia; espera y error mantienen sus acciones/foto actuales. Doble toque de confirmar no cambia revisión ni crea efectos duplicados.

### 7. Cierre y respuestas obsoletas
Given selección o identidad confirmada, When cierro por Cancelar/gesto o relanzo, Then reapertura empieza sin foto, resultado, selección ni identidad. When llega una respuesta o acción con revisión/foto antigua después de cancelar, sustituir, reidentificar o cerrar, Then se ignora y nunca confirma otra foto. El consentimiento ya registrado puede permanecer conforme al contrato anterior.

### 8. No alta y aislamiento local
Given dos plantas guardadas con modelos/fichas/JPEG distintos, When selecciono, confirmo alternativa, cambio especie/foto, cancelo y relanzo sin reseed/desinstalar, Then siguen exactamente dos plantas con sus modelos y bytes originales; no hay entidad/foto nueva de borrador ni ficha inventada. Confirmar no incrementa el contador de invocaciones IA.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md` (registro reciente y estado, líneas 1–172), `feature_list.json`, `CONTEXT.md`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `DESIGN.md`.
- `docs/{build-brief,domain-model,risks-and-open-questions}.md`; ADR 003/004; `docs/specs/identify-candidates.md` (líneas 1–70); skills feature-spec/template e ios-clean-mvvm.
- `PlantCareAI/PlantCareAIApp.swift`; `Features/PlantList/Presentation/PlantListView.swift`: fábrica de VM por apertura y cierre por binding de sheet.
- `Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift`, `Domain/IdentificationPhoto.swift`: foto UUID, resultado mutable privado, generaciones, cierre y sustitución.
- `Features/IdentifyCandidates/Domain/IdentificationResult.swift`, `Presentation/IdentificationResultView.swift`, `Data/IdentificationCandidatesTestFixture.swift`: nombres opcionales, validación, principal/0–3 alternativas, incertidumbre y fixtures.
- `PlantCareAITests/{IdentifyCandidatesTests,IdentificationPhotoViewModelTests,IdentificationConsentViewModelTests}.swift`; `PlantCareAIUITests/PlantCareAIUITests.swift` (búsqueda y líneas 235–371).
- `PlantCareAI.xcodeproj/project.pbxproj` (registros de fuentes/targets mediante búsqueda), `init.sh` completo (solo lectura).
- No existe spec anterior de confirm-species. No se inspeccionaron config real, productos/logs sensibles, fuentes fuera del worktree ni API real.

### Existing Patterns / Gaps

- iOS 17 SwiftUI, Clean Architecture + MVVM, inyección desde App, recursos semánticos/localización; fuentes registradas explícitamente en pbxproj.
- `IdentificationPhotoViewModel` es el dueño actual del borrador. `identifyPhoto()` borra resultado/error al iniciar; sustitución limpia solo al publicar B; fallo conserva A; `close()` descarta todo. Mantener esos puntos de invalidación.
- Resultados validados sin ID de candidata: `SpeciesCandidate` conserva commonName/scientificName opcionales y `displayName` prioriza común. No cambiar su semántica global por maquetación.
- `IdentificationResultView` es hoy solo lectura y un único panel; no existe selección ni identidad confirmada. Añadir interacción, no otro coordinador/VM duplicado.
- Fixture ya ofrece proposals/no-alternatives/insufficient/error/slow/long y contador. UI test existente exige ausencia de «Confirmar» como límite histórico: actualizar únicamente esa expectativa por el nuevo contrato, conservar el resto de regresiones.
- Riesgos/ADR 004 contienen bloqueos históricos de API; estado vigente accepted en feature_list/PROGRESS prevalece. Esta feature no vuelve a certificar transporte ni precisión.

## Technical Approach

### Domain — `Features/ConfirmSpecies/Domain`

- Crear `ConfirmedDraftIdentity.swift`: valor `Equatable, Sendable` con `photoID`, `resultID` (revisión opaca UUID), `commonName`, `scientificName` y procedencia de propuesta seleccionada. No JPEG duplicado, Plant UUID, ficha, timestamp de alta ni persistencia.
- Crear `ConfirmSpeciesUseCase.swift`: enum `SpeciesProposalSelection` (`primary`, `alternative(index: Int)`), protocolo estrecho `ConfirmSpeciesUseCase` y struct `ConfirmSpecies` síncrona/pura. Entrada: foto/revisión actuales, resultado y selección; salida: identidad confirmada o error tipado de selección/resultado inválido. Reutilizar `IdentificationResult.validated()`, exigir outcome proposals y pertenencia por posición; copiar exactamente los nombres sin completar/traducir/inventar campos. Rechazar índices negativos/fuera de rango.
- Confirmar no necesita repositorio ni actor ni adaptador Data. El caso de uso valida negocio; VM valida vigencia de foto/revisión y disponibilidad UI. Domain importa Foundation, no SwiftUI/Data/config/proveedor.

### Presentation — integrar el borrador existente

- Inyectar el caso de uso en `IdentificationPhotoViewModel`; añadir estado privado publicado `selectedProposal`, `confirmedIdentity` y revisión del resultado vigente. Asignar UUID nuevo al publicar cada resultado válido, aunque tenga los mismos nombres que el anterior.
- `selectProposal(_:resultID:)` y `confirmSpecies(resultID:)` reciben la revisión capturada por la vista: ignorar acciones obsoletas. Guardar/validar también el photoID asociado al resultado; no confiar en nombres/índice fuera de su revisión.
- `canSelectProposal`/`canConfirmSpecies`: VM abierto, foto y resultado proposals de la misma revisión/foto, sin busy/cámara; confirmar exige selección válida y ausencia de confirmación. Confirmación síncrona en MainActor, idempotente; sin tareas/IO. Error de contrato deja identidad nil y mensaje local prudente, nunca como error de API/insuficiencia.
- `changeConfirmedSpecies()` limpia identidad y vuelve al selector conservando elección de la misma revisión. Sin botón ficticio de cuidados ni callback que guarde. Confirmación se representa aparte, no mutando SpeciesCandidate o IdentificationResult a «hecho».
- Centralizar limpieza selección/identidad/revisión en los puntos ya existentes: inicio válido de `identifyPhoto()` (tras guard canIdentify, antes del check de configuración), publicación exitosa de foto B y `close()`. Publicación de resultado asigna nueva revisión y elección vacía. No limpiar al comenzar una sustitución que puede fallar ni restaurar nada al cancelar reidentificación.
- `cancelAuthorization()` sigue abandonando intención y manteniendo foto; generaciones actuales continúan bloqueando respuestas tardías. No alterar consentimiento/URLSession. Mantener `PlantListView` como propietario de presentación/cierre, sin nueva ruta o sheet para confirmar.
- Ampliar `IdentificationResultView` con selección/revisión/callback y capacidad de interacción; dejar incertidumbre/insuficiencia intactas. Crear `Features/ConfirmSpecies/Presentation/ConfirmedSpeciesView.swift` para resumen y Cambiar especie, sin ViewModel propio.

### Data / Composición / Handoff

- Data de esta feature: **no necesaria**, identidad real pero solo en memoria; no adaptador que aparente persistencia. Reutilizar fixtures explícitas Debug Simulator, no fallback de producción.
- Composición en `PlantCareAIApp.swift`, dentro de `makeIdentificationPhoto`: inyectar `ConfirmSpecies()` junto a prepare/camera/authorize/identify. Flujo local View → VM → ConfirmSpecies → identidad; flujo de identificación actual queda intacto.
- Futuro `generate-care-sheet` consumirá `confirmedIdentity` + `photo` del mismo VM, comprobando photoID vigente, dentro de su propia intención autorizada. `manual-species` definirá su procedencia/contrato sin fingir propuesta IA; cualquier ampliación deberá acordarse entonces. `save-plant` hará el mapeo a Plant y decidirá nombre/ficha/pipeline de alta.
- No activar ese handoff ahora: resumen «La especie está confirmada en este borrador. La planta aún no se ha añadido.» y «La ficha de cuidados estará disponible en un siguiente paso.» sin CTA deshabilitado engañoso ni invocación automática.

## Expected File Changes (futura implementación)

- Crear `PlantCareAI/Features/ConfirmSpecies/Domain/{ConfirmedDraftIdentity,ConfirmSpeciesUseCase}.swift` y `Presentation/ConfirmedSpeciesView.swift`.
- Modificar `PlantCareAI/Features/IdentificationPhoto/Presentation/{IdentificationPhotoViewModel,IdentificationPhotoView}.swift`: estado/invalidaciones y selector/resumen.
- Modificar `PlantCareAI/Features/IdentifyCandidates/Presentation/IdentificationResultView.swift`: tarjetas seleccionables y badges, sin tocar contrato/adapter de transporte.
- Modificar `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/Localizable.xcstrings` y `PlantCareAI.xcodeproj/project.pbxproj`: composición, claves usadas y registro app/test.
- Crear `PlantCareAITests/{ConfirmSpeciesTests,ConfirmSpeciesViewModelTests}.swift`; actualizar `PlantCareAIUITests/PlantCareAIUITests.swift` preservando regresiones.
- Fixture `Features/IdentifyCandidates/Data/IdentificationCandidatesTestFixture.swift`: solo ampliar si hace falta un resultado distinto en segunda petición para E2E de revisión; usar dobles suspendidos para obsolescencia en unitarias.
- Documentación posterior indicada abajo; no modificar repositorio local/entidad SwiftData, ContentView, Assets ni init.sh salvo necesidad aprobada independiente.

## Visual Design Impact

- UI: sí, mismo modal «Identificar planta». Autoridad: DESIGN.md y UI existente; referencia Stitch «Identificar planta» aportada por usuario resumida aquí, no archivo inspeccionado ni copia literal.
- Mantener NavigationStack/título inline/Cancelar nativos; grabber nativo si se habilita, nunca dibujarlo. Sin navegación entre variantes: las cuatro pills del HTML eran demostración, no pantallas/tabs requeridos.
- Mantener foto preparada arriba, tarjeta 4:3, radio 22 y margen 20 con `scaledToFit()` existente: no adoptar object-cover del HTML ni recortar detalles útiles de identificación.
- Fondo Background, tarjetas Surface, bloques SurfaceMuted, contornos Outline y acento PrimaryAction/Primary existentes; no añadir el gris #6F7A73 sin necesidad: usar TextSecondary semántico. Sistema iOS/SF Symbols, sin logo/footer decorativo.
- Resultado: «Propuesta de IA» y «Podría ser…»; principal con badge «Candidata principal», alternativas con «Alternativa» bajo «Otras posibilidades». Cada tarjeta es botón de selección única, con check y texto «Seleccionada» además del borde verde; principal no preseleccionada. Incertidumbre completa visible y pie que distingue propuesta de identidad confirmada.
- Jerarquía de cada tarjeta: científico primero si existe, común debajo si distinto; solo común si no hay científico. Renderizar datos reales, nunca ejemplos fijos de Stitch. Etiquetar ambos nombres para accesibilidad sin truncamiento.
- CTA primario «Confirmar especie» debajo de incertidumbre/selector; deshabilitado sin elección. Tras confirmar mostrar nombres elegidos, «Especie confirmada por ti», advertencia «Tu elección no garantiza la identificación botánica», estado de borrador y «Cambiar especie». Mantener controles actuales de galería/cámara/Identificar disponibles para cambiar foto/reidentificar cuando no busy.
- No rehacer espera/insuficiencia/error ni añadir botón redundante Probar otra foto: los controles existentes de galería/cámara satisfacen esa acción. Ningún texto de propuesta afirma que la confirmación humana elimina incertidumbre.
- Layout vertical desplazable, objetivos ≥44 pt, traits selected/labels locales y sin depender solo del color. Nombres 160/explicación 1000 caracteres envuelven y acciones siguen alcanzables con scroll normal. Nuevo artefacto visual: no necesario.

## Durable Documentation Impact (solo durante implementación)

- `ARCHITECTURE.md`: actualizar inventario, flujo local/propiedad de borrador y afirmaciones actuales «no confirmación»/«solo lectura»; dejar transporte y dirección de dependencias intactos.
- `docs/adr/005-confirmed-draft-identity.md`: crear nota breve del contrato de identidad efímera/foto/revisión y consecuencias para manual/cuidados/alta; no diseñar esas features. Aprobación de esta spec ratifica esta propuesta de frontera.
- `docs/domain-model.md`: actualizar capacidad implementada e invalidaciones; no adelantar ficha/alta. Aclarar que confirmación humana no equivale a verificación botánica.
- `CONSTRAINTS.md`: no necesario; reglas de privacidad/persistencia ya cubren límites. `AGENTS.md`: no necesario, sin cambio de workflow. `CONTEXT.md`, `docs/build-brief.md`, `DESIGN.md`: no necesario, comportamiento compatible.
- `PROGRESS.md`/`feature_list.json`: futura evidencia real/estado según rol; nunca passing sin pruebas ni accepted sin validator independiente. Ahora permanecen intactos.
- `docs/handoffs/confirm-species.md`: futura entrega con tipos/estado/tests/riesgos; guía de tests propia solo si aporta instrucciones no cubiertas en el handoff.

## Implementation Plan / Tasks

1. Tras aprobación humana, coordinar sesión/simulador y gate de línea base seguro; no iniciar otras features.
2. Implementar modelo/caso de uso puro y unitarias de validez/pertenencia/nombres.
3. Integrar estado/revisiones/guards/invalidaciones y composición; probar VM antes de maquetar.
4. Añadir selector/resumen/localización con diseño anterior y registrar fuentes explícitamente.
5. Actualizar E2E histórica del resultado y añadir escenarios confirmación/invalidación/aislamiento; ejecutar gate/inspección y documentar evidencia para validator.

- [ ] Identidad Domain real y efímera, selección no confirmada automáticamente, sin repositorio.
- [ ] Inyección en App y token foto/revisión protegiendo acciones obsoletas.
- [ ] Principal/alternativa, Cambiar especie y resumen honesto; recursos solo usados.
- [ ] Matriz de transiciones completa: éxito/fallo/cancelación de reemplazo, reidentificación, error/insuficiencia, cierre y tardías.
- [ ] Tests Domain/VM/UI registrados y expectativas históricas adaptadas sin debilitar regresiones.
- [ ] Gate, inspección visual habitual, documentación/handoff y revisión independiente.

## Verification Plan (planificado, no ejecutado)

- Antes de ejecutar, coordinar con sesión activa; un simulador estándar, texto normal, una apariencia, sin ejecuciones duplicadas. Sin acceso/copia de config real ni build con su secreto: si existe, acordar entorno de verificación de fuentes/config sintética **dentro del worktree autorizado**; nunca sobrescribirla. Si no existe, futura copia exclusiva de plantilla pública con clave vacía conforme AGENTS.
- `caffeinate -dius ./init.sh`: gate existente ejecuta build + unitarias + XCUITest y siembra fotos sintéticas; no servidor/proceso largo. Sin cambios al script. Mantener host despierto/tapa abierta.
- Focalizadas disponibles: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID>' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO -only-testing:PlantCareAITests/ConfirmSpeciesTests -only-testing:PlantCareAITests/ConfirmSpeciesViewModelTests -only-testing:PlantCareAIUITests/PlantCareAIUITests/testConfirmSpeciesAlternativeAndDraftInvalidation test` (adaptar ruta al entorno sintético acordado si procede).
- Domain: principal/alternativas exactas, nombres solo común/solo científico/ambos, resultado inválido/insuficiencia, índice inválido y revisión conservada en salida.
- VM: ninguna preselección; selección única; confirmación idempotente; guard busy/cámara/closed; tokens obsoletos incluso resultado con mismos nombres; fallos/picker cancelado conservan A; B limpia; reidentificar limpia antes del aviso/config check y no restaura al cancelar/fallar; close y continuaciones suspendidas no reviven identidad.
- E2E persistente de este repo es XCUITest, incluido en init: alternativa ≠ principal seleccionada y confirmada en resumen, cero invocaciones adicionales, cambio requiere reconfirmar, principal sin alternativas, insuficiencia/error/espera sin confirmación, textos largos/scroll y reemplazo fallido vs exitoso.
- Extender cierre por gesto existente para identidad confirmada y reapertura vacía en el mismo proceso; después relanzar sin reseed y usar --storage-verify/consulta de ambas fichas para modelos completos/JPEG intactos. Mantener también Cancelar y suite de consentimiento/picker existentes.
- Inspección visual básica de selector vacío, alternativa seleccionada, resumen y texto largo/acciones en simulador estándar; opcional captura de principal. No porcentajes ni certeza falsa. API real no requerida de nuevo: confirmación es local y no cambia transporte; fixtures son evidencia de interacción, no inferencia botánica.
- Comprobaciones estáticas futuras: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, `python3 -m json.tool PlantCareAI/Localizable.xcstrings`, `git diff --check`; no sustituyen gate/UI.
- SE, texto aumentado/máximo, VoiceOver/Inspector y matrices de apariencia: fuera de verificación habitual, no ejecutadas ni requisito pendiente por defecto. Conservar soporte en código.

## Evidence To Capture / Validator Checklist

- Capturas sin secretos de alternativa seleccionada vs confirmada y nueva foto sin identidad; logs/resumen de unitarias/UI/gate con conteos, destino y fuente exacta. Nunca productos/logs de build con clave real.
- Registrar solo pruebas realmente ejecutadas, fallos/reparaciones y límites; separar evidencia nueva de aceptación histórica de identify-candidates.
- [ ] Escenarios 1–8 comprobados; selección y confirmación separadas, principal/alternativa exactas.
- [ ] Revisión/foto vigentes, invalidaciones conservadoras y respuestas/acciones tardías ignoradas.
- [ ] Confirmación sin IA/escritura/alta; colección y JPEG de dos plantas sin cambios.
- [ ] Presentation → Domain, sin Data nueva innecesaria, composición App y fuentes en targets correctos.
- [ ] Diseño nativo adaptado, incertidumbre legible, scroll funcional y soporte accesible conservado.
- [ ] XCUITest focalizada y regresiones conservadas; evidencia de gate/inspección sin secretos.
- [ ] Documentación/estado veraces; no cuidados/manual/persistencia adelantados ni spec aceptada anterior reescrita.

## Decisions / Riesgos / Revisión humana requerida

- Propuesta D1: sin preselección; tarjeta selecciona y CTA separado confirma. Científico primero solo en este selector, sin cambiar displayName del dominio existente.
- Propuesta D2: confirmación termina en resumen local honesto, no navega ni solicita cuidados; Cambiar especie limpia confirmación y exige reconfirmar. Aprobar copy temporal antes de implementar.
- Propuesta D3: reidentificar invalida inmediatamente aun si cancelo el aviso/falla configuración; sustitución fallida/cancelada conserva identidad de A. Sigue semántica del código actual.
- Riesgos: confundir elección humana con certeza o planta guardada; trasladar selección entre revisiones iguales; borrar identidad al fallar reemplazo; snapshots de UI/E2E obsoletos al volver interactivo el panel. Tests/labels/guards anteriores los acotan.
- 2026-10-10 — Revisión humana: el usuario aprueba D1 («No preseleccionar nada como has indicado»), D2 («OK») y D3 («OK»). Quedan ratificadas la selección explícita con CTA separado, el resumen local sin alta/cuidados y las invalidaciones descritas. Esta aprobación no autoriza iniciar implementación ni publicación en esta sesión.
- Sin duda técnica bloqueante identificada tras lectura. Próximo paso: implementación únicamente cuando el usuario la solicite; feature-flow permanece detenido, sin implementación ni publicación.
