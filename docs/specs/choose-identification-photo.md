# Feature Implementation Spec: Elegir foto inicial desde galería o cámara

## Source Feature

- `id`: `choose-identification-photo`; `area`: `identificacion`.
- `depends_on`: `[empty-collection]`, estado `accepted` comprobado en `feature_list.json`.
- `status`: `not_started`; fuente: `feature_list.json`.
- Comportamiento: desde Añadir, escoger o tomar una foto y repetir la selección antes de identificar.
- Verificación de origen: galería y, en dispositivo compatible, cámara; cambio de foto, permisos, ausencia de alta prematura y gate estándar.
- Planificación 2026-10-10, worktree exclusivo `choose-identification-photo`; base/rama comunicadas por orquestador: `a81e97d77cf986f758ef823c4317e3b2c6527e81`, `feature/choose-identification-photo` (no verificadas mediante Git en este rol).
- Documento propuesto para revisión humana; no autoriza implementación. No se ejecutaron init.sh, builds ni pruebas y no cambia ningún estado.

## Goal

Habilitar las dos acciones Añadir de Mis plantas y abrir un flujo modal nativo donde se elige una única foto desde galería o cámara, se previsualiza y se puede sustituir. La foto es un borrador efímero: cerrar/cancelar o relanzar la app lo descarta, sin crear ejemplar ni modificar la colección.

Esta entrega termina en la foto preparada, no en una identificación ficticia. Mostrar «Identificar» deshabilitado y explicación «La identificación estará disponible próximamente.» incluso con foto; el punto de continuación se habilitará en `identify-candidates`, después de `external-ai-consent`.

## Non-Goals

- Ningún envío a IA, credencial, aviso de consentimiento externo, candidata, especie manual, cuidados ni alta (`external-ai-consent` y siguientes tienen su propio contrato).
- Sin llamadas a SavePlant/PlantRepository, SwiftData, archivos PlantStore, historial, fechas de alta o cambios en plantas existentes.
- Sin restauración persistente de borradores, guardado en Fotos, permisos de micrófono, acceso general al fotolibrario, editor de recorte, filtros ni múltiples imágenes.
- Sin pipeline definitivo de persistencia de fotos: `save-plant` sigue siendo responsable de aprobar formato/límites y memoria de la imagen que se guardará; no tratar este JPEG efímero como alta validada.
- Sin recursos externos, nuevas dependencias, cuentas, backend o matrices ampliadas de accesibilidad/apariencia.

## Job Story / Users And Permissions

Cuando quiero añadir una planta, quiero elegir una foto clara y poder repetirla antes de identificar, para no continuar con una imagen equivocada.

- Único usuario local, sin autenticación ni roles; la imagen aún no pertenece a ningún ejemplar persistido.
- Galería mediante `PhotosPicker` de selección única `.images`: picker de sistema, sin solicitar autorización global Photos ni `NSPhotoLibraryUsageDescription` por esta vía. Acceso solo al elemento elegido; limited/denied de acceso general no deben bloquear este picker.
- Cámara: comprobar disponibilidad y autorización solo al tocar «Tomar foto». `notDetermined` solicita acceso; authorized abre cámara; denied/restricted explica el motivo y ofrece galería. Denied permite «Abrir Ajustes» por intención explícita; restricted no promete que Ajustes lo resuelva.
- `NSCameraUsageDescription` en Debug/Release: «Usamos la cámara para que puedas tomar una foto de tu planta antes de identificarla.» No solicitar permisos al lanzar, al tocar Añadir o al abrir galería.

## Acceptance Scenarios (Given / When / Then)

### 1. Entrada desde ambas acciones
Given una colección vacía o con ejemplares, When pulso Añadir del encabezado o «Añadir mi primera planta», Then se abre el mismo flujo «Foto de tu planta», sin foto previa, con «Elegir de galería», «Tomar foto» y Cancelar. Volver mantiene la colección original. El encabezado permite abrirlo también durante carga/error local, sin ocultar ese error ni usarlo como permiso para guardar.

### 2. Elegir y repetir desde galería
Given el flujo abierto, When elijo una imagen válida, Then veo progreso de carga y después la imagen orientada correctamente, con controles para elegir otra o tomar foto. When elijo una segunda imagen distinta, Then solo la segunda pasa a ser la foto vigente; ninguna se guarda como planta y Identificar sigue deshabilitado con explicación veraz.

### 3. Cancelación sin pérdida accidental
Given ninguna foto o una foto A, When cancelo el picker/cámara, Then sigo sin foto o con A, respectivamente, sin error por cancelar. When cancelo/cierro por gesto el flujo, Then se liberan borrador/tareas; reabrir Añadir o relanzar muestra el flujo sin foto. No se recupera el borrador por accidente.

### 4. Cámara real y permiso
Given un iPhone compatible con permiso sin decidir, When pulso Tomar foto, Then el sistema solicita cámara una sola vez; aceptar abre captura real. When confirmo una captura, Then aparece esa imagen en el mismo borrador; repetir/cancelar conserva las reglas de galería. Con permiso ya concedido no se repite el diálogo; no se exporta captura al fotolibrario.

### 5. Cámara no disponible o permiso rechazado
Given simulador sin cámara, permiso denegado o restringido, When pulso Tomar foto, Then aparece un mensaje específico («La cámara no está disponible en este dispositivo.» o explicación del permiso), nunca un picker de cámara inválido ni una falsa captura. Galería y Cancelar siguen operativos. Tras volver de Ajustes se consulta de nuevo el estado al reintentar; no se usa autorización obsoleta.

### 6. Error recuperable y concurrencia
Given una foto A o ninguna, When falla la transferencia (incluida descarga iCloud), el decode o la preparación por límites, Then se explica el fallo sin contenido sensible y se permite otra selección; A sigue vigente si existía. When cancelo/cierro mientras carga o una respuesta antigua llega después de otra selección, Then no reaparece una foto descartada ni se actualiza un flujo cerrado.

### 7. Sin efectos de alta ni red propia
Given colección vacía o dos plantas A/B persistidas, When elijo/cambio/capturo/cancelo y relanzo sin reseed/desinstalar, Then la colección y modelos/fotos de A/B siguen exactamente iguales y no hay ejemplares nuevos ni archivos de borrador en PlantStore. Ningún cliente IA/red de app se incorpora; Photos puede descargar la imagen seleccionada de iCloud por cuenta del sistema, lo que no es envío a IA ni prueba de selección offline.

## Repository Research

### Files Inspected

- `AGENTS.md`, `PROGRESS.md`, `feature_list.json`, `.agents/skills/feature-spec/references/spec-template.md`, `.agents/skills/ios-clean-mvvm/SKILL.md`: roles, dependencia y política vigente.
- `CONTEXT.md`, `docs/build-brief.md`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`, `DESIGN.md`, `ARCHITECTURE.md`, `CONSTRAINTS.md`, `docs/adr/001-local-plant-storage.md`, `docs/adr/002-local-plant-editing.md`: borrador, privacidad, arquitectura y límites de importación.
- `PlantCareAI/PlantCareAIApp.swift`, `ContentView.swift`, `Features/PlantList/Presentation/{PlantListView,PlantListViewModel,EmptyPlantView,PlantCardViewModel}.swift`: composición, NavigationStack, botones deshabilitados y protección por generaciones.
- `PlantCareAI/Localizable.xcstrings`, inventario `Assets.xcassets`, `PlantCareAI.xcodeproj/project.pbxproj`, `PlantCareAIUITests/PlantCareAIUITests.swift` (líneas 1–160 y búsqueda de tests/isEnabled), `init.sh`: catálogo español, tokens, registro explícito y gate XCTest/XCUITest existente.
- Inventarios `docs/`, `docs/specs/` y `docs/adr/`: no existía spec de esta feature. No hay docs product-brief/user-and-access-model/technical-discovery/mvp-scope en ese inventario; se usa build-brief.

### Existing Patterns / Gaps

- App SwiftUI iPhone iOS 17+, Swift 5; composición desde PlantCareAIApp, ContentView delgado, adaptadores inyectados y VMs @MainActor con tareas/generaciones.
- Hay persistencia real y detalle/edición aceptados; no hay selección/captura de fotos, permisos de cámara ni flujo de identificación.
- Ambas acciones Añadir están deshabilitadas y EmptyPlantView muestra `collection.add.unavailable`; deben activarse, retirar esa explicación y actualizar aserciones antiguas de deshabilitado, sin suprimir los escenarios de vacío/fallback/scroll/persistencia.
- El proyecto genera Info.plist y registra cada Swift/test explícitamente. Assets contiene ocho colores, cero imágenes: reutilizar tokens y SF Symbols, foto real del usuario; no se inspeccionó HTML/captura de Stitch porque no está incorporado.
- `./init.sh` ya ejecuta build + suite unitaria/UI serializada y termina; no inicia servicios. XCUITest es el E2E persistente del repositorio, no hace falta arnés web.

## Technical Approach

### Presentation / navegación

- Nueva feature `Features/IdentificationPhoto/Presentation`; sheet única desde PlantListView mediante fábrica de VM inyectada desde composición (puede pasar por PlantListViewModel). VM nuevo por apertura; no singleton de borrador. EmptyPlantView recibe closure de entrada, sin adaptadores.
- Modal con NavigationStack local para barra nativa/Cancelar, no cambiar rutas UUID del listado. Presentar el picker/cámara desde este modal, secuenciando cierres para evitar dos sheets activas a la vez.
- `IdentificationPhotoViewModel` conserva foto preparada opcional, fase idle/loading y error tipado independiente. No borrar foto vigente hasta que la nueva termine correctamente; durante carga mostrar A con progreso, o placeholder si no existía.
- Controles de selección/captura bloqueados durante transferencia/preparación para evitar duplicados; Cancelar/gesto siempre descartan. Reset del elemento PhotosPicker tras cancel/error/éxito para poder seleccionar la misma imagen otra vez.
- Puentes nativos `PhotosPicker` y `UIImagePickerController` (sourceType camera, foto, sin edición) viven en Presentation: únicamente presentación, callbacks y transporte de bytes; no reglas de preparación ni IO persistente. No pasar PhotosPickerItem/UIImage a Domain. Captura entrega codificación de transporte de la imagen con orientación conservada; Data normaliza y valida como galería.
- MainActor solo para controles/estado/render. Decode/reescalado/codificación fuera de MainActor; tarea cancelable + generación por apertura/selección, verificación antes de publicar. No retener originales tras éxito/error/cierre ni UIImage completa de cámara durante preparación más de lo necesario.

### Domain / Data y composición

- Un modelo `IdentificationPhoto` Foundation-only: UUID de selección (no plantID), JPEG preparado `Data`, ancho/alto. Sin especie, fecha de alta, rutas, Photos/UIKit ni vinculación al repositorio.
- `PrepareIdentificationPhoto` caso de uso sobre `IdentificationPhotoPreparing` async/throws; errores tipados empty/unsupported/tooLarge/decodeFailed, transfer failure mapeado por Presentation. `LocalIdentificationPhotoPreparer` Data usa ImageIO/CoreGraphics para validar y preparar imagen fija (primer frame), sin disco.
- Límites propuestos para este borrador: entrada codificada ≤30 MiB, dimensiones positivas y ≤80 megapíxeles antes de decode, lado final ≤2048 px sin ampliar, JPEG calidad 0.85 y salida ≤5 MiB. Aplicar orientación al thumbnail, fondo blanco si alfa y omitir metadata EXIF/GPS al recodificar. Rechazar datos corruptos/no imagen/salida fuera de límites; no intentar decode de resolución completa para galería.
- Se aceptan imágenes fijas decodificables por ImageIO (incluidos JPEG/HEIC/PNG); no vídeos. PhotosPicker se configura para representación de imagen, no recurso de vídeo de Live Photo.
- `CameraAccess` contrato Domain + `CheckCameraAccess` caso de uso: disponibilidad y estado autorizado/denegado/restringido, solicitud solo por intención de captura; `SystemCameraAccess` Data adapta AVFoundation/UIKit. Composición inyecta ambos casos de uso; abrir Ajustes es intención de sistema de Presentation, no acceso directo a Data.
- Flujo concreto: View → ViewModel → PrepareIdentificationPhoto → IdentificationPhotoPreparing ← LocalIdentificationPhotoPreparer; y VM → CheckCameraAccess → CameraAccess ← SystemCameraAccess. Ningún caso de uso de guardado se inyecta al flujo.
- Consumidor real del JPEG ahora: preview de este modal. Futuros `identify-candidates`/`external-ai-consent` podrán usarlo tras sus specs; no crear hoy coordinador general, cliente falso ni contratos IA. Preview acotada se genera desde JPEG, no conserva original paralelo.

## Expected File Changes (durante implementación, no en este paso)

- Crear `PlantCareAI/Features/IdentificationPhoto/Domain/{IdentificationPhoto,PrepareIdentificationPhotoUseCase,CameraAccess}.swift` (contrato/caso de uso de cámara juntos si conviene).
- Crear `.../Data/{LocalIdentificationPhotoPreparer,SystemCameraAccess}.swift`.
- Crear `.../Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel,CameraPickerView}.swift`; PhotosPicker puede quedar en la vista o helper en esta capa.
- Modificar `PlantCareAI/Features/PlantList/Presentation/{PlantListView,PlantListViewModel,EmptyPlantView}.swift` y `PlantCareAI/PlantCareAIApp.swift`: acciones/fábrica/composición. ContentView permanece delegador sin pantalla nueva (solo transporte de dependencia si imprescindible).
- Modificar `PlantCareAI/Localizable.xcstrings`: claves `identificationPhoto.*`, permiso/error/acciones y quitar únicamente claves de alta deshabilitada ya sin uso; no reordenación masiva.
- Modificar `PlantCareAI.xcodeproj/project.pbxproj`: grupos/referencias/build phases y CameraUsageDescription ambas configuraciones; conservar iOS 17 y firma local fuera del repositorio.
- Crear `PlantCareAITests/{IdentificationPhotoPreparationTests,IdentificationPhotoViewModelTests,CameraAccessTests}.swift`; actualizar `PlantCareAIUITests/PlantCareAIUITests.swift` para entrada, selección/cambio/cancelación y regresión.
- Si hace falta seam UI determinista, crear `.../Data/IdentificationPhotoTestFixture.swift` solo `#if DEBUG && targetEnvironment(simulator)`, inyectado exclusivamente por composición. No sustituye prueba del picker real ni finge cámara real; ausente en Release.

## Visual Design Impact

- UI: sí; fuente `DESIGN.md`, tokens existentes y convenciones iOS. Usuario confirma que no requiere aportar diseño adicional; no se solicita material ni se añade artefacto gráfico.
- Mis plantas conserva diseño; acciones activas y sin texto «Disponible cuando puedas elegir una foto.».
- Modal «Foto de tu planta»: columna desplazable, foto dominante en marco aproximado 4:3 con aspectFit para inspeccionar imagen completa (no guardar recorte), fondo crema/superficie blanca/radio ~22/margen ~20.
- Placeholder con SF Symbol discreto y «Elige una foto de tu planta»; botones «Elegir de galería» y «Tomar foto», progreso «Preparando foto…», errores textuales y opción de galería en todo fallo de cámara. Identificar deshabilitado y su explicación visible; no aparente éxito IA.
- Cancelar nativo; etiquetas/identificadores estables, foto con descripción «Foto seleccionada para identificar», controles ≥44 pt, texto adaptable y colores semánticos. Sin foto decorativa, logos ni diseños web.

## Durable Documentation Impact

- Ahora: crear solo esta spec; no editar PROGRESS/feature_list ni registrar evidencia funcional de planificación.
- `ARCHITECTURE.md`: actualizar durante implementación para feature, adaptadores de permisos/preparación, borrador efímero y habilitación de Añadir; retirar afirmación de ausencia de cámara, conservar límite de save-plant.
- `CONSTRAINTS.md`: actualización no necesaria; no cambia política iOS/firma/verificación/secretos. Límites de borrador aquí y en documentación técnica, no nuevas reglas operativas globales.
- `AGENTS.md` y `DESIGN.md`: no necesario; se aplican normas/dirección existentes.
- `docs/domain-model.md`, CONTEXT/build-brief: no necesario, borrador no persistido ya definido. `docs/risks-and-open-questions.md`: precisar preparación efímera/límites y memoria pendiente, sin declarar cerrado el pipeline de alta.
- Crear `docs/testing-identification-photo.md` al implementar: seed de fotos del simulador, flujos reales, permisos/cámara física, límites y limpieza. Actualizar PROGRESS/feature_list solo con pruebas realmente ejecutadas por roles posteriores.
- ADR nuevo no necesario en este alcance: sigue dirección existente, no cambia contrato compartido de persistencia ni almacenamiento. Proponer ADR/revisión antes de implementar si se necesita cache en disco o pipeline compartido con otras features.

## Implementation Plan / Tasks

1. Tras aprobación humana, coordinar simulador/baseline con orquestador; revisar APIs Apple de PhotosPicker/UIImagePickerController/autorización antes de integrar. No activar herramientas XcodeBuildMCP sin su skill instalada.
2. Implementar contratos Domain, preparación acotada y adaptador de cámara con doubles y pruebas; registrar fuentes.
3. Construir VM y modal, puentes nativos y composición; habilitar ambas entradas sin acoplar al almacenamiento.
4. Añadir UI tests, actualizar expectativas antiguas justificadas por nuevo comportamiento, guía de selección real y docs; ejecutar gate/escenarios/inspección visual y registrar límites.

- [ ] Domain Foundation-only y errores; Data no persiste ni envía imágenes.
- [ ] Preparación/orientación/límites/metadata comprobados y autorización comprobada por intención.
- [ ] Selección única, preview, sustitución atómica, cancelación/gesto/reset y generaciones.
- [ ] Añadir operativo en vacío/con plantas/error; sin guardar ni identificar ficticiamente.
- [ ] Registro Xcode, propósito de cámara, catálogo español y soporte accesible.
- [ ] Tests funcionales conservados/ampliados, guía reproducible, evidencia sincera y handoff independiente.

## Verification Plan (futuro; no ejecutado por planner)

- Coordinar con sesión activa: un iPhone Simulator estándar, texto normal, una apariencia; ejecuciones serializadas, sin procesos/simuladores duplicados, tapa abierta. Reutilizar baseline válida si existe; si falla, reparar antes de ampliar.
- `caffeinate -dius ./init.sh`: gate build + todas las unitarias/UI funcionales, sin servicios largos; no modificar init.sh para automatizar cámara inexistente ni omitir tests.
- Focalizadas: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=<UDID_ESTANDAR>' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO -only-testing:PlantCareAITests/IdentificationPhotoPreparationTests -only-testing:PlantCareAITests/IdentificationPhotoViewModelTests -only-testing:PlantCareAITests/CameraAccessTests -only-testing:PlantCareAIUITests/PlantCareAIUITests test` (ejecutar sin solapar con gate).
- Unitarias Data: JPEG/HEIC/PNG, orientación rotada, alfa, corrupto/vacío/no imagen, límites de entrada/píxeles/salida, dimensiones y EXIF/GPS ausentes; cancelación no publica. VM: primera imagen, reemplazo, cancel picker con A, fallo con/sin A, respuesta tardía, cierre, nueva apertura y duplicados. Cámara: unavailable/notDetermined/authorized/denied/restricted y reevaluación, cero solicitudes antes de intención y sin segundo prompt indebido.
- XCUITest E2E: ambas entradas, cierre/gesto y reapertura limpia, selección A→B y cancel/fallo preserva A, explicación de Identificar y cámara no disponible. Actualizar assertions de Añadir ahora habilitado (incluida reapertura persistente y scroll); mantener todos los restantes escenarios/aserciones.
- Picker real en simulador: importar dos imágenes locales diferenciables con `xcrun simctl addmedia <UDID> <fotoA> <fotoB>` (sin descargar assets de terceros), escoger/cancelar/reescoger usando UI de sistema y comprobar orientación/sustitución visual. Documentar nombres/pasos; si automatización del picker depende del runtime, hacer comprobación manual reproducible además de E2E por seam. Los fixtures no prueban integración real por sí solos.
- Reusar fixture de almacenamiento aislado: verificar dos modelos/fotos completos tras cerrar/reabrir sin reseed/desinstalar; comparar vacía antes/después. Inspección de dependencias demuestra que flujo no escribe PlantStore ni tiene cliente IA; no declarar prueba de modo avión por ello.
- Inspección visual básica de modal vacío, preview A/B, progreso, error y regreso en el mismo simulador. Comprobar textos/controles y scroll con texto normal.
- Cámara en iPhone compatible, con firma local preparada fuera de Git: aceptar/rechazar permiso, captura/confirmación/cancelación/repetición, vuelta de Ajustes. Si no hay dispositivo, registrar «cámara real no ejecutada; pendiente»; seam cubre estados, nunca sustituye evidencia de captura. El validator debe distinguir aceptación del flujo simulado de verificación física pendiente exigida por feature en dispositivo compatible.
- `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON del catálogo y `git diff --check`; Release build genérico para comprobar ausencia de seams Debug si se añadieron. No confundir estática con pruebas funcionales.
- SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices de apariencia: fuera de verificación habitual; no ejecutadas salvo solicitud expresa, no bloqueo por defecto.

## Evidence To Capture / Risks And Unknowns

- Logs/xcresult con resultados reales, destino/fecha, capturas inspeccionadas y pasos picker real/cambio/cancelación; contraste de modelos/bytes antes/después y permisos solicitados solo por intención.
- Registrar separado cámara física/dispositivo/permiso de simulación y transferencia iCloud; no guardar fotos privadas en repo/logs ni credenciales. Artefactos locales ignorados.
- Riesgo acotado: PhotosPicker loadTransferable(Data) puede materializar bytes antes de comprobar 30 MiB; ese límite no es garantía de memoria constante. Cámara UIKit también entrega UIImage completa; liberar pronto, probar fotos representativas y no fingir resuelto el riesgo global. Si es inviable, volver a revisión antes de ampliar a transferencias por archivos.
- Cámara compatible y firma no inspeccionadas/disponibilidad desconocida en este rol; limitación de futura evidencia, no motivo para inventar resultados. No hay bloqueo documental/de dependencia para revisión.
- Decisiones propuestas a aprobar: modal efímero, Identificar deshabilitado, conservación de A al cancelar/fallar y límites de preparación. API/credencial externa no son requisito de esta feature.

## Validator Checklist

- [ ] Alcance limitado a selección/captura efímera; ninguna alta, IO PlantStore, IA o permisos globales Photos.
- [ ] Capas, flujo inyectado, threading y registro Xcode conformes; ningún Data concreto en vistas/VM.
- [ ] Escenarios de entrada, selección/cambio/cancelación/error/permisos comprobados sin falsas capturas.
- [ ] Picker real probado; evidencia física de cámara o pendiente explícita con veredicto acotado, sin equivalencia entre fixture y hardware.
- [ ] Orientación/límites/metadatos/cancelación/respuestas tardías y preservación de A cubiertos.
- [ ] Gate completo + E2E persistente conservado, ausencia de alta contrastada y visual básica inspeccionada.
- [ ] Español sin claves crudas, acciones accesibles, estado futuro de Identificar honesto y sin diseño adicional requerido.
- [ ] Docs y evidencias reflejan solo comprobaciones ejecutadas; passing no es accepted, aceptación independiente exclusiva del rol correspondiente.

**Siguiente acción de esta sesión: revisión del usuario; detenerse sin implementer/validator.**
