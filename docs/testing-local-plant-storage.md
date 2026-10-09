# Verificación local de `local-plant-storage` y `plant-cards`

Desde la raíz del worktree, Xcode 26.2 / iPhone Simulator instalado:

```sh
./init.sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886 # sustituir por uno disponible: xcrun simctl list devices available
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAITests/LocalPlantRepositoryTests' test
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAIUITests/PlantCareAIUITests/testStoredCollectionSurvivesProcessRelaunch' test
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAITests/PlantCardViewModelTests' \
  '-only-testing:PlantCareAITests/PlantListViewModelTests' \
  '-only-testing:PlantCareAIUITests/PlantCareAIUITests' test
```

Los tests de repositorio usan disco temporal y lo limpian. Los UI tests usan `Application Support/StorageTests/<UUID>` y limpian al terminar. El relanzamiento verifica exactamente los dos modelos completos y los bytes JPEG propios antes de mostrar las tarjetas; no basta con contar plantas. No se desinstala entre lanzamientos.

## Inspección manual de los estados (solo Debug Simulator)

No ejecutar mientras XCTest está usando el simulador. Estos argumentos no existen en Release ni en dispositivo físico:

```sh
xcrun simctl install "$UDID" DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app
FIXTURE=$(uuidgen)
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-seed -AppleLanguages '(es)'
# Ver dos tarjetas con motivos locales de prueba diferenciables, sin estado vacío.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-verify -AppleLanguages '(es)'
# Debe conservar las tarjetas: se verifican modelos y fotos al cargar.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-corrupt -AppleLanguages '(es)'
# Debe mostrar error local distinto del vacío (corrompe solo el fixture).
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-cleanup -AppleLanguages '(es)'
# Limpia el fixture y muestra vacío. Terminar y abrir sin argumentos usa PlantStore real.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
```

Esperar a que desaparezca la pantalla de arranque/carga antes de inspeccionar (los UI tests esperan hasta 10 segundos). Si se interrumpió un UI test antes de su limpieza, sus carpetas UUID pueden permanecer en `StorageTests`; nunca son la colección de producción `PlantStore`.

Para error aislado de foto, lanzar un fixture nuevo con `--storage-seed --storage-photo-missing`: se verifican modelos/bytes y después se elimina solo el JPEG del ejemplar 1. Debe mantener ambas tarjetas, error «No se pudo cargar la foto» y «Reintentar foto» separado sin navegación. El reintento no re-siembra ni repara el archivo. La recuperación se prueba con repositorio doble en `PlantCardViewModelTests`. No usar `--storage-verify` sobre un fixture cuya foto se eliminó: su error global es intencionado.

Para nombres/especie/ubicación largos, añadir `--storage-long-text` al sembrar un fixture nuevo y al verificarlo tras reapertura (solo datos de prueba). No cambia el esquema ni los datos reales.

Para Dynamic Type: `xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large`; repetir los estados y desplazarse hasta la segunda tarjeta. Restaurar `content_size large`. Para VoiceOver, comprobar nombre/especie/ubicación, hint de selección y reintento independiente, además de cabecera y controles deshabilitados; los identificadores XCTest no prueban la lectura auditiva real. Tocar foto/contenido abre un destino provisional con nombre y Atrás, no la ficha de `plant-detail`.

No existe alta de usuario aún. El almacenamiento acepta JPEG ya preparado; no probar fotos reales de alta hasta planificar orientación/reescalado/límites en `save-plant`. Las tarjetas preparan imágenes de presentación acotadas, no un pipeline de importación. No hay ficha de detalle todavía. Desinstalar elimina el almacén local real: no usarlo para demostrar reapertura.
