# Base iOS

- `PlantCareAI.xcodeproj` contiene la app iPhone `PlantCareAI` (SwiftUI, iOS 17+) y el target `PlantCareAIUITests`, ambos en el scheme compartido `PlantCareAI`.
- `PlantCareAIApp.swift` crea una única ventana con `ContentView`: una pantalla de arranque estática. No hay todavía navegación, almacenamiento ni proveedor de IA.
- `init.sh` elige un simulador iPhone disponible (prefiere uno ya arrancado), ejecuta build y UI tests con Xcode y deja artefactos en `DerivedData/` ignorado. El lanzamiento visual manual se verifica por separado.
- Los recursos visuales del target de app están en `PlantCareAI/Assets.xcassets` (ocho colores semánticos sRGB de `DESIGN.md`; todavía ninguna imagen). `ContentView` resuelve los tres colores usados por nombre, sin RGB en la vista.
- `PlantCareAI/Localizable.xcstrings` es el catálogo de textos de interfaz: idioma fuente y de desarrollo español (`es`), con fallback español para idiomas no traducidos. Los dos textos del bootstrap usan claves semánticas SwiftUI; el catálogo se compila a `es.lproj/Localizable.strings` dentro de la app. Las próximas pantallas añaden entradas cuando se utilicen, sin anticipar flujos.
