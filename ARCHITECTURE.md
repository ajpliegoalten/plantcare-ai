# Arquitectura iOS: Clean Architecture + MVVM

## Decisión transversal (2026-10-09)

Organizar el código **por funcionalidad**, y dentro de cada funcionalidad separar explícitamente `Presentation`, `Domain` y `Data`, también en las primeras pantallas. Planificador, implementador y validador deben comprobar esta separación antes de dar una funcionalidad por terminada. `PlantCareAI.xcodeproj` contiene la app SwiftUI iPhone (iOS 17+) y las UI tests del scheme compartido; registra cada archivo Swift explícitamente en `project.pbxproj`.

- **Presentation**: vistas SwiftUI y `ObservableObject`/ViewModel. La vista representa el estado y envía intenciones; no crea repositorios, lee almacenamiento ni contiene reglas de dominio. El ViewModel obtiene el estado mediante un caso de uso inyectado; la vista de estado vacío es un componente independiente.
- **Domain**: modelos del negocio, protocolos de repositorio y casos de uso. No importa SwiftUI, conoce rutas de archivos, Xcode, proveedores externos ni detalles de persistencia. Los contratos se amplían cuando una capacidad real lo exige; no se inventan cuidados, fotos o plantas de ejemplo.
- **Data**: implementaciones de los protocolos del dominio (almacenamiento local o adaptadores futuros). Ningún tipo de `Data` se importa en `Domain` o en las vistas.
- **Composición**: `PlantCareAIApp.swift` elige las implementaciones concretas e inyecta el caso de uso en el ViewModel. `ContentView` solo delega en la vista raíz de la funcionalidad; no alberga la pantalla «Mis plantas». Las dependencias apuntan `Presentation → Domain ← Data` y la composición conecta las capas.

La separación no autoriza a adelantar comportamiento: existe persistencia local y selección por UUID desde tarjetas, pero no cámara, alta desde UI ni ficha de detalle. Los contratos son asíncronos y propagadores de errores; un fallo no representa una colección vacía.

## Implementación actual: `PlantList`

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
      PlantSelectionDestinationView.swift # shell temporal con nombre; plant-detail lo reemplaza
    Domain/
      Plant.swift, CareSheet.swift      # ejemplar confirmado y copia de seis cuidados
      PlantRepository.swift            # lectura, creación y foto bajo demanda; errores tipados
      LoadPlantsUseCase.swift          # contrato y caso de uso de consulta
      SavePlantUseCase.swift            # validación de campos obligatorios y foto no vacía
      LoadInitialPlantPhotoUseCase.swift # foto por UUID, sin rutas en Domain
    Data/
      LocalPlantRepository.swift       # actor: SwiftData + archivos JPEG independientes
      PersistedPlant.swift             # entidad interna y mapeo explícito
      StorageTestFixture.swift         # solo Debug Simulator, almacén aislado por argumento
```

`PlantCareAIApp` crea una misma instancia de `LocalPlantRepository` para `LoadPlants` y `LoadInitialPlantPhoto`, inyectados en `PlantListViewModel` con ciclo de vida `@StateObject`. El listado conserva modelos de tarjeta por UUID; no inicia fotos. Cada tarjeta solicita su foto con `.task` mediante `PlantCardViewModel → LoadInitialPlantPhoto → PlantRepository`, prepara un thumbnail ImageIO de máximo 1600 px fuera del MainActor y conserva solo la imagen. Cancelación/generaciones impiden que respuestas antiguas sustituyan el estado nuevo. No hay miniaturas en disco; Data sigue leyendo/validando el original completo. Vacío y error global siguen separados de errores por foto. El fixture Debug usa la misma instancia/raíz para ambos flujos. Los botones de alta permanecen deshabilitados hasta `choose-identification-photo`.

`PlantListView` contiene `NavigationStack` y rutas UUID resueltas contra la colección cargada, sin lectura/escritura al seleccionar. `PlantSelectionDestinationView` muestra solo el nombre y el aviso provisional: **no es la ficha de detalle**. `plant-detail` sustituirá este shell conservando la identidad. No se muestran riegos, salud ni eventos sin contratos reales.

El actor crea perezosamente `ModelContainer` y su `ModelContext` fuera del MainActor; todas las operaciones están serializadas, sin suspensiones entre comprobar duplicado y confirmar. Hay una sola instancia por almacén en producción; no se admiten escritores simultáneos de otros procesos/repositorios sobre el mismo directorio. Metadatos en `Application Support/PlantStore/Plants.store`, ficha embebida por ejemplar, referencia interna UUID.jpg; bytes únicamente en `Photos/UUID.jpg`. Listar no lee fotos. Domain recibe un UUID opaco, no una ruta ni binarios precargados.

Publicación: validar JPEG completo, escribir/verificar temporal, mover sin sobrescribir, insertar metadatos y guardar explícitamente (autosave desactivado). Un fallo revierte contexto y elimina los archivos nuevos. Tras interrupción de proceso, la próxima apertura primero lee/valida todos los metadatos y solo entonces elimina `.pending` y `.jpg` no referenciados. Si el almacén falla no hay limpieza ni fallback vacío/en memoria. Una foto referenciada ausente/corrupta produce error al solicitarla, no se elimina su planta ni se sustituye por otra. No es una transacción distribuida ni recuperación garantizada ante daño de disco; véase ADR 001.

JPEG es el formato aceptado de este fundamento, no un pipeline de importación. `save-plant` debe definir orientación, resolución, límite de bytes, compresión y memoria antes de aceptar fotografías reales; `add-plant-photo` reutilizará ese pipeline. La presentación de tarjetas acota su imagen, pero no resuelve el pipeline de importación ni limita el original.

## Recursos y comprobación

- `PlantCareAI/Assets.xcassets`: ocho colores semánticos sRGB de `DESIGN.md`, sin imágenes. Las vistas usan los ocho tokens por nombre; las fotos proceden exclusivamente del repositorio local por UUID.
- `PlantCareAI/Localizable.xcstrings`: solo claves usadas por la pantalla actual, textos españoles con fallback español; las claves obsoletas de bootstrap se retiraron.
- `./init.sh` elige un iPhone Simulator disponible y ejecuta build, XCTest de repositorio y UI tests; no sustituye a la inspección visual. Artefactos locales en `DerivedData/` ignorado. No hay cuentas, backend ni proveedor de IA.
