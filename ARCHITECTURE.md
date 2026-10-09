# Arquitectura iOS: Clean Architecture + MVVM

## Decisión transversal (2026-10-09)

Organizar el código **por funcionalidad**, y dentro de cada funcionalidad separar explícitamente `Presentation`, `Domain` y `Data`, también en las primeras pantallas. Planificador, implementador y validador deben comprobar esta separación antes de dar una funcionalidad por terminada. `PlantCareAI.xcodeproj` contiene la app SwiftUI iPhone (iOS 17+) y las UI tests del scheme compartido; registra cada archivo Swift explícitamente en `project.pbxproj`.

- **Presentation**: vistas SwiftUI y `ObservableObject`/ViewModel. La vista representa el estado y envía intenciones; no crea repositorios, lee almacenamiento ni contiene reglas de dominio. El ViewModel obtiene el estado mediante un caso de uso inyectado; la vista de estado vacío es un componente independiente.
- **Domain**: modelos del negocio, protocolos de repositorio y casos de uso. No importa SwiftUI, conoce rutas de archivos, Xcode, proveedores externos ni detalles de persistencia. Los contratos se amplían cuando una capacidad real lo exige; no se inventan cuidados, fotos o plantas de ejemplo.
- **Data**: implementaciones de los protocolos del dominio (almacenamiento local o adaptadores futuros). Ningún tipo de `Data` se importa en `Domain` o en las vistas.
- **Composición**: `PlantCareAIApp.swift` elige las implementaciones concretas e inyecta el caso de uso en el ViewModel. `ContentView` solo delega en la vista raíz de la funcionalidad; no alberga la pantalla «Mis plantas». Las dependencias apuntan `Presentation → Domain ← Data` y la composición conecta las capas.

La separación no autoriza a adelantar comportamiento: cada feature conserva su alcance y sus pruebas. En particular, no existe aún persistencia real, cámara ni navegación; el contrato síncrono de lectura se revisará si la persistencia futura exige errores/asíncronía, sin presentar un fallo de almacenamiento como colección vacía. Las tarjetas para colecciones no vacías pertenecen a `plant-cards`.

## Implementación actual: `PlantList`

```
PlantCareAI/
  PlantCareAIApp.swift                 # composición de dependencias y ventana
  ContentView.swift                    # delega en PlantListView
  Features/PlantList/
    Presentation/
      PlantListView.swift              # encabezado y selección de estado vacío
      EmptyPlantView.swift             # tarjeta visual sin lógica de datos
      PlantListViewModel.swift         # estado observado, caso de uso inyectado
    Domain/
      Plant.swift                      # identidad mínima del ejemplar, sin instancias ficticias
      PlantRepository.swift            # contrato de lectura
      LoadPlantsUseCase.swift          # contrato y caso de uso de consulta
    Data/
      EmptyPlantRepository.swift       # adaptador temporal que devuelve []
```

`PlantCareAIApp` crea `EmptyPlantRepository → LoadPlants → PlantListViewModel`, con ciclo de vida `@StateObject`; `PlantListView` lo observa. El repositorio vacío **no guarda ni recupera datos**: es una sustitución temporal explícita hasta `local-plant-storage`, que deberá reemplazarlo por un adaptador local verificable. Solo el caso vacío es visible hoy; la renderización de plantas guardadas llega con `plant-cards`. Los dos botones de alta permanecen deshabilitados y explican su indisponibilidad hasta `choose-identification-photo`.

## Recursos y comprobación

- `PlantCareAI/Assets.xcassets`: ocho colores semánticos sRGB de `DESIGN.md`, sin imágenes. Las vistas usan `Background`, `Primary`, `PrimaryAction`, `TextPrimary`, `TextSecondary` y `Surface` por nombre.
- `PlantCareAI/Localizable.xcstrings`: solo claves usadas por la pantalla actual, textos españoles con fallback español; las claves obsoletas de bootstrap se retiraron.
- `./init.sh` elige un iPhone Simulator disponible y ejecuta build y UI tests; no sustituye a la inspección visual. Artefactos locales en `DerivedData/` ignorado. No hay cuentas, backend, proveedor de IA ni almacenamiento en esta funcionalidad.
