# Verificación local de `local-plant-storage`

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
```

Los tests de repositorio usan disco temporal y lo limpian. Los UI tests usan `Application Support/StorageTests/<UUID>` y limpian al terminar. El relanzamiento verifica exactamente los dos modelos completos y los bytes JPEG propios antes de mostrar el mensaje de colección guardada; no basta con contar plantas. No se desinstala entre lanzamientos.

## Inspección manual de los estados (solo Debug Simulator)

No ejecutar mientras XCTest está usando el simulador. Estos argumentos no existen en Release ni en dispositivo físico:

```sh
xcrun simctl install "$UDID" DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app
FIXTURE=$(uuidgen)
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-seed -AppleLanguages '(es)'
# Ver mensaje de ejemplares guardados, sin tarjeta ni estado vacío.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype \
  --storage-test-id "$FIXTURE" --storage-verify -AppleLanguages '(es)'
# Debe conservar el mensaje: se verifican modelos y fotos al cargar.
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

Para Dynamic Type: `xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large`; repetir los estados y desplazarse si hace falta. Restaurar `content_size large`. Para VoiceOver, comprobar con Accessibility Inspector/VoiceOver la lectura del mensaje y cabecera y los controles deshabilitados; los identificadores XCTest no prueban la lectura auditiva real.

No existe alta de usuario aún. El almacenamiento acepta JPEG ya preparado; no probar fotos reales de alta hasta planificar orientación/reescalado/límites en `save-plant`. No hay tarjetas ni detalle hasta las features respectivas. Desinstalar elimina el almacén local real: no usarlo para demostrar reapertura.
