# Base iOS

- `PlantCareAI.xcodeproj` contiene la app iPhone `PlantCareAI` (SwiftUI, iOS 17+) y el target `PlantCareAIUITests`, ambos en el scheme compartido `PlantCareAI`.
- `PlantCareAIApp.swift` crea una única ventana con `ContentView`: una pantalla de arranque estática. No hay todavía navegación, almacenamiento ni proveedor de IA.
- `init.sh` elige un simulador iPhone disponible (prefiere uno ya arrancado), ejecuta build y UI tests con Xcode y deja artefactos en `DerivedData/` ignorado. El lanzamiento visual manual se verifica por separado.
