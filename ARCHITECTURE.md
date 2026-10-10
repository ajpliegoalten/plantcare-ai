# Arquitectura iOS: Clean Architecture + MVVM

## Decisión transversal (2026-10-09)

Organizar el código **por funcionalidad**, y dentro de cada funcionalidad separar explícitamente `Presentation`, `Domain` y `Data`, también en las primeras pantallas. Planificador, implementador y validador deben comprobar esta separación antes de dar una funcionalidad por terminada. `PlantCareAI.xcodeproj` contiene la app SwiftUI iPhone (iOS 17+) y las UI tests del scheme compartido; registra cada archivo Swift explícitamente en `project.pbxproj`.

- **Presentation**: vistas SwiftUI y `ObservableObject`/ViewModel. La vista representa el estado y envía intenciones; no crea repositorios, lee almacenamiento ni contiene reglas de dominio. El ViewModel obtiene el estado mediante un caso de uso inyectado; la vista de estado vacío es un componente independiente.
- **Domain**: modelos del negocio, protocolos de repositorio y casos de uso. No importa SwiftUI, conoce rutas de archivos, Xcode, proveedores externos ni detalles de persistencia. Los contratos se amplían cuando una capacidad real lo exige; no se inventan cuidados, fotos o plantas de ejemplo.
- **Data**: implementaciones de los protocolos del dominio (almacenamiento local o adaptadores futuros). Ningún tipo de `Data` se importa en `Domain` o en las vistas.
- **Composición**: `PlantCareAIApp.swift` elige las implementaciones concretas e inyecta el caso de uso en el ViewModel. `ContentView` solo delega en la vista raíz de la funcionalidad; no alberga la pantalla «Mis plantas». Las dependencias apuntan `Presentation → Domain ← Data` y la composición conecta las capas.

La separación no autoriza a adelantar comportamiento: existe persistencia local, consulta de ficha por UUID, edición de nombre/ubicación y selección/captura efímera de foto, pero no identificación IA, alta desde UI ni historial. Los contratos son asíncronos y propagadores de errores; un fallo no representa una colección vacía.

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

JPEG es el formato aceptado de este fundamento, no un pipeline de importación. `save-plant` debe definir orientación, resolución, límite de bytes, compresión y memoria antes de aceptar fotografías reales; `add-plant-photo` reutilizará ese pipeline. La presentación de tarjetas acota su imagen, pero no resuelve el pipeline de importación ni limita el original.

## Selección efímera: `IdentificationPhoto`

`PlantListView` presenta una sheet con VM nuevo por apertura, creado por la fábrica inyectada desde la app. `IdentificationPhotoView → IdentificationPhotoViewModel → PrepareIdentificationPhoto → IdentificationPhotoPreparing ← LocalIdentificationPhotoPreparer`. Domain contiene únicamente UUID de selección, JPEG y dimensiones; no conoce UIImage, PhotosPickerItem, rutas ni repositorio. PhotosPicker y el puente de captura UIImagePickerController pertenecen a Presentation; entregan bytes al caso de uso. `CheckCameraAccess → CameraAccess ← SystemCameraAccess` consulta disponibilidad y AVFoundation solo por intención Tomar foto, reevaluando el permiso en cada intento. Abrir Ajustes es una intención explícita de Presentation. No se pide acceso global a Fotos ni micrófono.

Data prepara el primer frame fuera de MainActor mediante ImageIO, sin disco: entrada ≤30 MiB y ≤80 MP, thumbnail orientado de lado ≤2048 sin ampliar, alfa blanco, JPEG calidad 0.85 y ≤5 MiB sin metadata fuente EXIF/GPS. Las tareas propagan cancelación entre operaciones síncronas. VM conserva A durante reemplazo/error, bloquea selecciones duplicadas y verifica generación/cierre antes de publicar. Cancelar y dismiss de sheet liberan borrador/tareas; no hay restauración tras relanzar. Identificar permite revisar consentimiento solo con foto lista; la identificación real permanece indisponible.

## Consentimiento externo: `ExternalAIConsent`

Domain contiene alcance/destinatario versionado, `ExternalAIConsentRepository` y `AuthorizeExternalAIOperation`. Presentation de foto inyecta la barrera y continuación; presenta `ExternalAIConsentView` sin repositorio ni segundo VM. Composición comparte un `UserDefaultsExternalAIConsentRepository` actor para la instalación y devuelve `unavailable` sin cliente/red. Preferencia global mínima, separada de PlantStore, sin fotos/contexto/claves. Cada operación futura (incluidas textuales) debe ejecutarse dentro de la continuación autorizada; ADR 003 describe renovación del alcance provisional y límites de UserDefaults. Estados/intención/generación cancelan cierres, gestos y respuestas tardías; una aceptación explícita ya registrada puede permanecer.

Estos límites son del borrador, no del contrato de alta. `loadTransferable(Data)` puede materializar el recurso completo antes de comprobar 30 MiB; UIKit entrega UIImage completa y su transporte JPEG se codifica fuera del actor UI. No se garantiza memoria constante ni se da por resuelto `save-plant`. El fixture de UI está compilado solo en Debug Simulator, activado por argumento desde composición, y no simula cámara física. El gate siembra dos imágenes sintéticas desde macOS en Fotos del simulador para probar además el PhotosPicker real; no son assets de la app ni fotos del usuario.

## Recursos y comprobación

- `PlantCareAI/Assets.xcassets`: ocho colores semánticos sRGB de `DESIGN.md`, sin imágenes. Las fotos de ejemplares proceden del repositorio local por UUID; la preview efímera muestra únicamente la selección/captura del usuario.
- `PlantCareAI/Localizable.xcstrings`: solo claves usadas por la pantalla actual, textos españoles con fallback español; las claves obsoletas de bootstrap se retiraron.
- `./init.sh` elige un iPhone Simulator disponible y ejecuta build, XCTest de repositorio y UI tests; no sustituye a la inspección visual. Artefactos locales en `DerivedData/` ignorado. No hay cuentas, backend ni proveedor de IA.
