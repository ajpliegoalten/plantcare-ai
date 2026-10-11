# Arquitectura iOS: Clean Architecture + MVVM

## Decisión transversal (2026-10-09)

Organizar el código **por funcionalidad**, y dentro de cada funcionalidad separar explícitamente `Presentation`, `Domain` y `Data`, también en las primeras pantallas. Planificador, implementador y validador deben comprobar esta separación antes de dar una funcionalidad por terminada. `PlantCareAI.xcodeproj` contiene la app SwiftUI iPhone (iOS 17+) y las UI tests del scheme compartido; registra cada archivo Swift explícitamente en `project.pbxproj`.

- **Presentation**: vistas SwiftUI y `ObservableObject`/ViewModel. La vista representa el estado y envía intenciones; no crea repositorios, lee almacenamiento ni contiene reglas de dominio. El ViewModel obtiene el estado mediante un caso de uso inyectado; la vista de estado vacío es un componente independiente.
- **Domain**: modelos del negocio, protocolos de repositorio y casos de uso. No importa SwiftUI, conoce rutas de archivos, Xcode, proveedores externos ni detalles de persistencia. Los contratos se amplían cuando una capacidad real lo exige; no se inventan cuidados, fotos o plantas de ejemplo.
- **Data**: implementaciones de los protocolos del dominio (almacenamiento local o adaptadores futuros). Ningún tipo de `Data` se importa en `Domain` o en las vistas.
- **Composición**: `PlantCareAIApp.swift` elige las implementaciones concretas e inyecta el caso de uso en el ViewModel. `ContentView` solo delega en la vista raíz de la funcionalidad; no alberga la pantalla «Mis plantas». Las dependencias apuntan `Presentation → Domain ← Data` y la composición conecta las capas.

La separación no autoriza a adelantar comportamiento: existe persistencia local, consulta de ficha por UUID, edición de nombre/ubicación, selección/captura efímera e identificación orientativa Debug. El contrato vigente de ADR 007 añade confirmación humana seguida de generación de seis cuidados válidos y alta directa desde UI, sin revisión intermedia; el historial sigue fuera de esta implementación. Los contratos de IO son asíncronos y propagadores de errores; un fallo no representa una colección vacía.

## Implementación actual: `PlantList`, `PlantDetail` y `EditPlant`

```
PlantCareAI/
  PlantCareAIApp.swift                 # composición de dependencias y ventana
  ContentView.swift                    # delega en PlantListView
  Features/PlantList/
    Presentation/
      PlantListView.swift              # encabezado, estados, tarjetas y ruta UUID
      EmptyPlantView.swift             # tarjeta visual sin lógica de datos
      PlantListViewModel.swift         # estado observado, caso de uso inyectado
      PlantCardView.swift              # foto 4:3, identidad y acceso; reintento separado
      PlantCardViewModel.swift         # foto por demanda, cache de imagen acotada y generación
    Domain/
      Plant.swift, CareSheet.swift      # ejemplar confirmado y copia de seis cuidados
      PlantRepository.swift            # lectura, creación, update estrecho y foto; errores tipados
      LoadPlantsUseCase.swift          # contrato y caso de uso de consulta
      SavePlantUseCase.swift            # validación de campos obligatorios y foto no vacía
      LoadInitialPlantPhotoUseCase.swift # foto por UUID, sin rutas en Domain
    Data/
      LocalPlantRepository.swift       # actor: SwiftData + archivos JPEG independientes
      PersistedPlant.swift             # entidad interna y mapeo explícito
      StorageTestFixture.swift         # solo Debug Simulator, almacén aislado por argumento
  Features/PlantDetail/
    Presentation/
      PlantDetailView.swift            # foto, identidad, fecha y seis cuidados desplazables
      PlantDetailViewModel.swift       # metadata/foto independientes, cancelación y reintento
    Domain/
      LoadPlantDetailUseCase.swift     # relectura metadata + filtro UUID, nil distinto de error
  Features/EditPlant/
    Presentation/
      EditPlantView.swift              # Form modal nativo, cancelar/guardar y errores
      EditPlantViewModel.swift         # borradores aislados, save único y resultado confirmado
    Domain/
      UpdatePlantUseCase.swift         # nombre obligatorio y normalización name/location
```

`PlantCareAIApp` crea una misma instancia de `LocalPlantRepository` para `LoadPlants` y `LoadInitialPlantPhoto`, inyectados en `PlantListViewModel` con ciclo de vida `@StateObject`. El listado conserva modelos de tarjeta por UUID; no inicia fotos. Cada tarjeta solicita su foto con `.task` mediante `PlantCardViewModel → LoadInitialPlantPhoto → PlantRepository`, prepara un thumbnail ImageIO de máximo 1600 px fuera del MainActor y conserva solo la imagen. Cancelación/generaciones impiden que respuestas antiguas sustituyan el estado nuevo. No hay miniaturas en disco; Data sigue leyendo/validando el original completo. Vacío y error global siguen separados de errores por foto. El fixture Debug usa la misma instancia/raíz para ambos flujos. Ambas acciones Añadir abren ahora el borrador efímero de foto, incluso ante error local; no guardan una planta.

`PlantListView` contiene el único `NavigationStack` y rutas UUID. Para todo UUID construye un destino con VM propio `@StateObject`, sin IO en fábrica/init. `PlantDetailView → PlantDetailViewModel → LoadPlantDetail → PlantRepository ← LocalPlantRepository` relee metadata al abrir y filtra por UUID (coste O(n) para este prototipo), nunca reutiliza el snapshot de tarjeta como fallback. Reutiliza los modelos/contratos Domain de PlantList y su adaptador Data; no hay repositorio ni esquema nuevo. La composición inyecta detalle y foto sobre la misma instancia elegida después del override Debug, sin volver a seed/verify.

Metadata loading/loaded/notFound/failed y foto idle/loading/loaded/failed son independientes. Los seis cuidados aparecen antes de completar IO/decode de foto; un reintento solo solicita la foto propia. ImageIO prepara máximo 1600 px fuera del MainActor, sin cache global ni Data retenida con UIImage; cada destino conserva solo su imagen mientras vive. Generaciones y cancelación invalidan respuestas tardías al desaparecer. Ubicación blanca/ausente se omite, especie se muestra literal y fecha larga española deriva de `createdAt` persistido. No hay escrituras ni red en la consulta, ni riegos, salud o eventos sin contratos reales.

La app inyecta `UpdatePlant` sobre el mismo repositorio seleccionado después del override Debug. `EditPlantView → EditPlantViewModel → UpdatePlant → PlantRepository ← LocalPlantRepository` escribe solo nombre/ubicación por UUID. Domain normaliza extremos de ambos textos y ubicación blanca a nil; Data aplica la misma validación antes de mutar. El actor hace fetch/mutación/beforeCommit/save sin suspensión y rollback ante fallo, sin acceder al JPEG ni insertar. No cambia el esquema (ADR 002).

El editor se crea solo desde metadata loaded, incluso con foto fallida; nueva sheet crea borradores nuevos. Cancelar y gesto descartan sin escribir; durante save campos/cancelar/gesto están bloqueados. El resultado canónico tras commit se aplica al detalle y callback MainActor débil al listado antes del dismiss. El listado reemplaza solo metadata por UUID en state/cards; conserva VM/imagen/tareas de cada tarjeta. Generaciones protegen resultados confirmados de metadata tardía. No se recarga el fixture ni fotos por una edición.

El actor crea perezosamente `ModelContainer` y su `ModelContext` fuera del MainActor; todas las operaciones están serializadas, sin suspensiones entre comprobar duplicado y confirmar. Hay una sola instancia por almacén en producción; no se admiten escritores simultáneos de otros procesos/repositorios sobre el mismo directorio. Metadatos en `Application Support/PlantStore/Plants.store`, ficha embebida por ejemplar, referencia interna UUID.jpg; bytes únicamente en `Photos/UUID.jpg`. Listar no lee fotos. Domain recibe un UUID opaco, no una ruta ni binarios precargados.

Publicación: validar JPEG completo, escribir/verificar temporal, mover sin sobrescribir, insertar metadatos y guardar explícitamente (autosave desactivado). Un fallo revierte contexto y elimina los archivos nuevos. Tras interrupción de proceso, la próxima apertura primero lee/valida todos los metadatos y solo entonces elimina `.pending` y `.jpg` no referenciados. Si el almacén falla no hay limpieza ni fallback vacío/en memoria. Una foto referenciada ausente/corrupta produce error al solicitarla, no se elimina su planta ni se sustituye por otra. No es una transacción distribuida ni recuperación garantizada ante daño de disco; véase ADR 001.

JPEG es el formato del fundamento. SavePlant adopta el pipeline existente y su validador de fotografía preparada (ADR 007, apartado de alta abajo); add-plant-photo lo reutilizará sin implementarse en esta feature. La presentación de tarjetas acota su imagen, no el original.

## Selección efímera: `IdentificationPhoto`

Refinamiento de selección autorizado vigente 2026-10-11 (`docs/specs/manual-species-selection.md`): VM permite toggle exclusivo IA/manual; deselect manual descarta sesión/texto sin restaurar IA, liberando foto/consulta. Cancelar edición explícito conserva contrato transaccional anterior. Campo dentro de tarjeta manual, como hermano del botón (no control anidado). Guard `hasSuccessfulIdentification` exige resultado/revisión de foto actual y ausencia de error para habilitar manual; sin resultado, fallo/cancelación o foto nueva no permite editor ni lo muestra. Vista omite `uncertainty` e indicadores/avisos de propuesta IA, manteniendo estado insuficiente. Contrato Domain/validación/transporte sin cambios; no IO/casos de uso nuevos. Prevalece sobre disponibilidad histórica descrita más abajo.

`PlantListView` presenta una sheet con VM nuevo por apertura, creado por la fábrica inyectada desde la app. `IdentificationPhotoView → IdentificationPhotoViewModel → PrepareIdentificationPhoto → IdentificationPhotoPreparing ← LocalIdentificationPhotoPreparer`. Domain contiene únicamente UUID de selección, JPEG y dimensiones; no conoce UIImage, PhotosPickerItem, rutas ni repositorio. PhotosPicker y el puente de captura UIImagePickerController pertenecen a Presentation; entregan bytes al caso de uso. `CheckCameraAccess → CameraAccess ← SystemCameraAccess` consulta disponibilidad y AVFoundation solo por intención Tomar foto, reevaluando el permiso en cada intento. Abrir Ajustes es una intención explícita de Presentation. No se pide acceso global a Fotos ni micrófono.

Data prepara el primer frame fuera de MainActor mediante ImageIO, sin disco: entrada ≤30 MiB y ≤80 MP, thumbnail orientado de lado ≤2048 sin ampliar, alfa blanco, JPEG calidad 0.85 y ≤5 MiB sin metadata fuente EXIF/GPS. Las tareas propagan cancelación entre operaciones síncronas. VM conserva A durante reemplazo/error, bloquea selecciones duplicadas y verifica generación/cierre antes de publicar. Cancelar y dismiss de sheet liberan borrador/tareas; no hay restauración tras relanzar. Identificar solo actúa con foto lista e intención explícita, pasando por configuración y consentimiento; el resultado sigue efímero.

## Consentimiento externo: `ExternalAIConsent`

Domain contiene alcance/destinatario versionado, `ExternalAIConsentRepository` y `AuthorizeExternalAIOperation`. Presentation de foto inyecta la barrera y continuación; presenta `ExternalAIConsentView` sin repositorio ni segundo VM. Composición comparte un `UserDefaultsExternalAIConsentRepository` actor para la instalación; sin configuración válida devuelve indisponibilidad local/cero HTTP, con ella compone el caso de uso de identificación real. Preferencia global mínima, separada de PlantStore, sin fotos/contexto/claves. Cada operación futura (incluidas textuales) debe ejecutarse dentro de la continuación autorizada; ADR 003/004 describen renovación del alcance provisional y límites de UserDefaults. Estados/intención/generación cancelan cierres, gestos y respuestas tardías; una aceptación explícita ya registrada puede permanecer.

Los límites de salida se adoptan también en el alta (ADR 007). `loadTransferable(Data)` puede materializar el recurso completo antes de comprobar 30 MiB; UIKit entrega UIImage completa y su transporte JPEG se codifica fuera del actor UI. No se garantiza memoria constante. El fixture de UI está compilado solo en Debug Simulator, activado por argumento desde composición, y no simula cámara física. El gate siembra dos imágenes sintéticas desde macOS en Fotos del simulador para probar además el PhotosPicker real; no son assets de la app ni fotos del usuario.

## Propuestas efímeras: `IdentifyCandidates`

`IdentificationPhotoView → IdentificationPhotoViewModel → AuthorizeExternalAIOperation → IdentifyCandidates → SpeciesIdentificationRepository ← OpenAICompatibleSpeciesIdentificationRepository`. El contrato de continuación se mueve de consentimiento al Domain de identificación. `IdentificationResultView` presenta propuestas seleccionables, sin preselección; nombres/alternativas/incertidumbre no son identidad confirmada ni entidades persistentes. Resultado/error están ligados a la foto; cambio exitoso limpia ambos, fallo conserva A, cierre/cancelación descarta respuestas tardías.

Data usa **un único adaptador OpenAI-compatible Chat Completions**, sin perfiles/whitelist/vendor SDK. Cambio posterior explícitamente autorizado (ADR 004): cualquier base HTTPS/modelo bien formado configurable, `API_KEY` opcional; vacía omite Authorization, servicio puede rechazarla con 401/403 sin retry/fallback de auth. `API_SCHEME`/`API_HOST_PATH` llegan por plist puente; Data construye y valida/canonicaliza URL, preserva prefijo y añade `/chat/completions` una vez. Rechaza credenciales en URL, query/fragment/ambigüedades/endpoint duplicado/no HTTPS, sin relax ATS/TLS. Puertos HTTPS válidos se conservan salvo 443 canónico.

Único real `Config/IdentificationSecrets.xcconfig` ignorado y obligatorio Debug; plantilla `.example` pública sin secretos. No wrapper/include opcional; Debug falla sin fichero, Release no lo referencia ni incluye puente/clave. El plist puente no es config duplicada. Spec original conservada intacta. Pruebas actuales usan sandbox de fuentes/config sintética sin leer/modificar/copiar el real ni xcuserdata del usuario.

La app captura configuración/scope/aviso/transporte juntos por borrador y revalida antes de aceptar, enviar y publicar. SHA256 canónico de destino real/modelo/revisión de aviso, **versión 4** y prefijo openai-compatible: no hereda identificación v3, DevExpert v2 ni provisional v1. `ExternalAIDestinationNotice` Domain lleva endpoint/modelo de ese snapshot a la vista; aviso muestra destino HTTP completo y modelo, declara desconocidos operador/subprocesadores/retención/entrenamiento sin atribuir empresas. Incluye identificación fotográfica y generación textual de cuidados, sin reenviar JPEG para la ficha. Operación real sin notice falla localmente antes de autorización. Cambiar host/puerto/base path/modelo cambia alcance; clave/timeout no. Sin discovery ni fallback/envío automático; configurar no equivale a aceptar el aviso ni a acreditar visión/JSON del endpoint.

URLSession efímera, sin cache/cookies/credenciales persistentes, POST único con JPEG preparado actual + prompt, sin redirecciones ni retries automáticos. JSON es dato no confiable: parseo/invariantes/límites fallidos son error, no evidencia insuficiente. Timeout total 60 s (10–120 configurables), respuesta ≤1 MiB, salida solicitada ≤1000 tokens, JPEG ≤5 MiB; base64 y JSON generan copias en memoria, no memoria constante. Identificación fue aceptada con relato real del usuario sobre OpenAI gpt-4.1-mini (`docs/validations/identify-candidates.md`); bloqueos previos históricos. Esa evidencia no garantiza compatibilidad/presupuesto de otros destinos/modelos ni cuidados textuales. Cuidados fue aceptada independientemente en V2 146/146 (`docs/validations/generate-care-sheet-V2.md`) con corroboración del relato del usuario sobre ambas vías/seis campos/aviso/fallo/retry/sin alta, chat de inference.devexpert.io (modelo no comunicado) y gpt-4.1-mini de api.openai.com; no ejecución real del agente. Esta alta nueva no se acredita con aquella evidencia histórica. Transporte configurable HTTPS/modelo sin perfiles, aviso v4 antes del envío, solo demo Debug local privada; sin cuentas/backend/custodia de credencial para distribución.

## Confirmación local: `ConfirmSpecies`

`IdentificationPhotoView (selector compartido con IdentificationResultView) → IdentificationPhotoViewModel → ConfirmSpeciesUseCase ← ConfirmSpecies` es un flujo síncrono/puro. Domain (`ConfirmedDraftIdentity.swift`, `ConfirmSpeciesUseCase.swift`) conserva UUID de foto/revisión, nombres opcionales exactos y procedencia posicional; valida resultado y pertenencia sin IO. No hay Data nueva ni entidad persistida. App inyecta `ConfirmSpecies()`; el VM existente posee selección única, revisión, identidad y foto sin duplicar JPEG.

Cada resultado publicado obtiene revisión UUID nueva. La vista captura esa revisión en acciones; VM exige foto/revisión vigentes y disponibilidad (abierto, no busy/cámara). Seleccionar no confirma ni envía. Confirmar inicia exactamente una intención de cuidados en el mismo borrador, sin resumen intermedio (`ConfirmedSpeciesView` retirado). Cambiar especie oculta ficha y conserva identidad/ficha anteriores exclusivamente para Cancelar edición; reconfirmar crea una intención nueva incluso con nombres iguales.

Iniciar identificación limpia resultado/revisión/selección/identidad/cuidados/snapshot antes de configuración/aviso; cancelar/fallar no los restaura. Sustituir foto solo limpia al publicar B con éxito, incluso si bytes/recurso iguales; fallo/cancelación/cámara denegada conservan A y snapshot fallido. Cerrar antes de commit elimina borrador; durante commit se rechaza. Generaciones bloquean continuaciones obsoletas. Confirmación Domain continúa pura (ADR 005); Presentation inicia cuidados (ADR 006) y alta directa (ADR 007).

## Identidad manual local: `ManualSpecies` (2026-10-11)

`IdentificationPhotoView (confirmación compartida + campo ManualSpeciesView) → IdentificationPhotoViewModel → ConfirmManualSpeciesUseCase ← ConfirmManualSpecies` confirma texto humano mediante un caso puro/síncrono inyectado desde App. Ese caso no tiene Data/IO: después de confirmarlo, Presentation inicia la misma intención de cuidados autorizada que para IA. `ConfirmedDraftIdentity.Source` discrimina `.aiProposal(resultID:selection:commonName:scientificName:)` y `.manual(name:)`; los accesores IA son opcionales y devuelven nil para manual. No se infiere ningún nombre complementario ni revisión IA.

El VM posee `ManualSpeciesDraft` (UUID de sesión, photoID y texto) y error local separado. `isSelectingSpecies` muestra selector sin borrar identidad/ficha anteriores; `manualDraft` y `selectedProposal` son mutuamente excluyentes. Editar/confirmar/cancelar exige sesión/foto vigentes, borrador abierto y ausencia de operación/cámara. El editor bloquea foto/cámara/identificar, pero permite seleccionar candidata: descarta texto pendiente sin confirmar ni borrar identidad anterior. Cancelar edición restaura selección/identidad/ficha exactas, también al pasar de manual a candidata. Reabrir precarga exclusivamente identidad manual vigente. El botón común confirma, reemplaza identidad y termina selección antes de solicitar cuidados; callbacks antiguos/dobles no operan. Volver expresamente a propuestas desde revisión descarta identidad/ficha y exige reconfirmar sin consultar identificación.

Reidentificar invalida identidad/cuidados/snapshot desde el inicio; publicar B limpia identidad, ficha y sesión, incluso con mismos bytes; fallo/cancelación mantiene A. Cerrar antes del commit libera borrador; alta confirmada queda persistida. Generaciones impiden que una respuesta cancelada tardía sustituya identidad manual de la misma foto. SavePlant mapea y persiste según ADR 007, sin inventar procedencia persistida.

## Cuidados efímeros: `GenerateCareSheet` (ADR 006)

`PlantCreationStatusView → IdentificationPhotoViewModel → AuthorizeExternalAIOperation → GenerateCareSheet → CareSheetGenerationRepository ← OpenAICompatibleCareSheetGenerationRepository`. App compone ambos adaptadores con el mismo snapshot. Domain reutiliza `CareSheet` de PlantList, valida photoID/nombres (máximo 2000 caracteres por nombre sin truncar) y seis textos completos de máximo 1000 caracteres tras trim. Data envía exclusivamente nombres/procedencia como JSON no confiable en mensaje separado de instrucciones fijas españolas; ningún JPEG/UUID/alternativa/historial. Mismo endpoint/políticas de sesión, POST único, max_tokens 2000, respuesta ≤1 MiB y timeout total. `unavailable`, rechazo, truncamiento o ficha incompleta son error, nunca éxito parcial. ADR 007 sustituye la revisión efímera de ADR 006: éxito continúa directamente al alta.

El único VM del borrador mantiene estados de cuidados y alta validating/saving/saved/failed, tareas y tokens por intención/foto/identidad. No hay tarea de vista ni segundo VM. Confirmar humano inicia la cadena; selección/doble tap/busy/acciones obsoletas no la repiten. CareSheetReviewView se retira del target: no se renderizan ficha/resumen/formulario antes de guardar. Retry remoto y local distintos; editar oculta el snapshot fallido y cancelar edición lo restaura sin IO. Fixtures opt-in Debug Simulator y contadores separados solo desde composición.

## Alta confirmada: SavePlant (ADR 007)

`IdentificationPhotoViewModel → SaveConfirmedPlantUseCase → PreparedPlantPhotoValidating + SavePlant → PlantRepository ← LocalPlantRepository`. App inyecta el mismo escritor que listado/detalle/edición, tras overrides aislados. Domain mapea snapshot inmutable de UUID nuevo/fecha/foto/identidad/seis cuidados a Plant plano, ubicación nil y nombre inicial de especie. No migración ni procedencia persistida inventada.

Data LocalPreparedPlantPhotoValidator valida el JPEG preparado fuera de MainActor (marcadores/estado/decode/dimensiones/≤2048/≤5 MiB/sin EXIF-GPS-orientación), sin recomprimir. Se adopta la preparación existente: primer frame, orientación en pixels, alfa blanco, no ampliar, calidad .85. Buffers acotados por salida no implican memoria constante del original picker/cámara.

`willCommit` comprueba cancelación/token/foto/identidad en MainActor y bloquea cierre/gestos/cambios antes de despachar SavePlant. No se descarta éxito por cancelación técnica posterior. Retry local conserva UUID/fecha/bytes/modelo, no necesita API/config/consentimiento nuevos. DuplicateID solo es éxito si metadata completa y JPEG coinciden exactamente; conflicto no sobrescribe. Callback MainActor una vez y antes del dismiss aplica alta al listado por UUID, preserva tarjetas/imágenes, orden createdAt/UUID e invalida metadata atrasada. Lista loading/failed refresca metadata completa sin fotos; falla como error de lectura con retry, nunca como alta fallida o lista parcial completa. Colección se desplaza a tarjeta nueva y no abre detalle automáticamente. No compensar eliminando un commit válido tras cierre de proceso.

## Recursos y comprobación

- `PlantCareAI/Assets.xcassets`: ocho colores semánticos sRGB de `DESIGN.md`, sin imágenes. Las fotos de ejemplares proceden del repositorio local por UUID; la preview efímera muestra únicamente la selección/captura del usuario.
- `PlantCareAI/Localizable.xcstrings`: solo claves usadas por la pantalla actual, textos españoles con fallback español; las claves obsoletas de bootstrap se retiraron.
- `./init.sh` elige un modelo/runtime de iPhone Simulator, compila una vez (`build-for-testing`) y ejecuta unitarias/UI con 5 workers aislados de XCTest; el PhotosPicker real corre aparte, serial, en el simulador sembrado. Ambas fases reutilizan los productos (`test-without-building`) y generan sus propios xcresult; el gate solo pasa si ambas pasan. No sustituye a la inspección visual focalizada. Cobertura/consolidaciones en `docs/testing-ui.md`. Artefactos locales en `DerivedData/` ignorado. No hay cuentas ni backend; la API OpenAI-compatible usa base HTTPS/modelo configurables y clave opcional, únicamente habilitable con configuración local Debug privada y consentimiento v4 del destino/modelo reales.
