# Rediseño visual del detalle de planta

## Contrato autorizado

Usuario confirmó implementación y documentación en español tras resolver dos decisiones: el riego es **solo diseño**, y los seis cuidados conservan sus textos completos, sin resúmenes nuevos. Ronda visual de `plant-detail`; no iniciar `quick-watering` ni modificar la aceptación histórica.

- Adaptar tarjeta de nombre/especie/icono/fecha y seis cuidados en dos columnas al HTML aportado, según `DESIGN.md`.
- Mantener fotografía propia, ubicación opcional, edición nativa, lectura local por UUID y estados de carga/error/reintento.
- Bloque de riego entre identidad y ficha: acción deshabilitada y «Próximamente» visible; registro y última fecha explícitamente indisponibles. Sin writes, eventos, toasts, fechas/ciclos/estado de salud o humedad inventados.
- Sin barra inferior de corazón/riego, cuenta/avatar, colección inventada, menú vacío, visor de foto ni consejo diario nuevo.
- Cada tarjeta conserva íntegro el texto propio, incluidos 1000 caracteres, en orden Luz/Riego, Humedad/Temperatura, Sustrato/Abonado. Sin elipsis, desbordamiento horizontal ni IA adicional. Aviso orientativo al final. Iconos/fondos según referencia, SF Symbols y tipografía iOS.

## Ubicación y arquitectura

- **Presentation:** `Features/PlantDetail/Presentation/PlantDetailView.swift`; composición visual y disponibilidad estática explícita del placeholder. Mantener VM y contratos sin cambios.
- **Domain/Data:** sin cambios; ni repositorios ficticios ni ampliaciones del esquema.
- **Composición:** `PlantCareAIApp.swift` conserva inyección existente. Flujo `PlantDetailView → PlantDetailViewModel → LoadPlantDetail/LoadInitialPlantPhoto → PlantRepository ← LocalPlantRepository`; EditPlant intacto.
- **Recursos:** cinco colores usados en `Assets.xcassets`, cinco textos españoles nuevos en `Localizable.xcstrings`; ninguna dependencia ni fuente Swift nueva que registrar.

## Verificación por impacto

Riesgos: geometría de dos columnas, contenido íntegro y scroll largo; identidad/fecha y ubicación; edición tras nuevo layout; foto fallida/retry; fallback español. Añadir caso de geometría y placeholder en `StoredCollectionUITests` sin retirar assertions existentes.

Seleccionar `StoredCollectionUITests`, `EditPlantUITests`, tres escenarios de `PlantCardsUITests` (selección UUID, foto fallida y texto largo), `LocalizationUITests` y `CareSheetUITests/testCareSheetThousandCharacterTextScrollsAndPersists`. Inspección visual focalizada del nuevo escenario, no capturas de todas las filas por rutina. Unitarias del VM de detalle y LoadPlantDetail como regresión directa; no nueva regla de Domain. Comprobar JSON, proyecto y diff.

Un iPhone 17 Pro iOS 26.2, texto normal, apariencia clara; clones gestionados por XCTest permitidos. No API real, config privada ni matrices ampliadas. Build-for-testing una vez y test-without-building focalizado; no gate completo por implementer. Validator independiente es dueño del gate estándar final y de `accepted`.
