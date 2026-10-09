# Verificación local de almacenamiento, tarjetas y `plant-detail`

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
  '-only-testing:PlantCareAITests/LoadPlantDetailTests' \
  '-only-testing:PlantCareAITests/PlantDetailViewModelTests' \
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
# Abrir ambas tarjetas: fotos distintas, seis cuidados propios, especie literal,
# ubicación solo en Fixture 1 y fecha de alta real de 1970. Volver con Atrás/gesto.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-verify -AppleLanguages '(es)'
# Debe conservar tarjetas y ambos detalles: se verifican modelos y fotos al cargar.
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

Para nombres/especie/ubicación largos, añadir `--storage-long-text`; para seis cuidados largos, `--storage-long-care`. Usar los mismos flags al sembrar un fixture nuevo y al verificarlo tras reapertura (solo datos de prueba). No cambia el esquema ni los datos reales.

En detalle de la foto ausente, identidad y cuidados deben permanecer legibles y «Reintentar carga» vuelve a solicitar el JPEG de ese mismo UUID, sin reparar/resembrar ni releer metadata. El fallback explica carga local, no conexión. Volver y abrir la segunda conserva su foto válida. Recuperación real, nil/error de metadata y respuestas tardías están cubiertos por dobles deterministas en `PlantDetailViewModelTests`; `LoadPlantDetailTests` también consulta un almacén real reabierto sin la primera foto.

Para Dynamic Type: `xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large`; repetir estados y desplazarse hasta Abonado y el aviso orientativo de ambos detalles. Restaurar `content_size large`. Para VoiceOver, comprobar orden foto/identidad/seis cuidados, encabezados, Atrás y reintento independiente; los identificadores XCTest no prueban la lectura auditiva real. Tocar foto/contenido abre la ficha de ese UUID. Probar también sin conectividad: no existen solicitudes de red en este flujo.

No existe alta de usuario aún. El almacenamiento acepta JPEG ya preparado; no probar fotos reales de alta hasta planificar orientación/reescalado/límites en `save-plant`. Tarjetas y detalle preparan imágenes de presentación acotadas, no un pipeline de importación. Desinstalar elimina el almacén local real: no usarlo para demostrar reapertura.
