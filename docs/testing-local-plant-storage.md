# Verificación local de almacenamiento, tarjetas, detalle y edición

Desde la raíz del worktree, Xcode 26.2 / iPhone Simulator instalado:

Verificación habitual: un único iPhone Simulator estándar, tamaño de texto normal y una sola apariencia. Mantener `./init.sh`, pruebas unitarias y UI funcionales, escenarios de persistencia/aislamiento/reapertura e inspección visual básica. No lanzar ejecuciones duplicadas con la sesión activa. SE/pantallas pequeñas, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia quedan fuera de esta rutina y **solo se ejecutan si el usuario las solicita expresamente**. Conservar soporte y aserciones funcionales; no declarar aprobadas comprobaciones no ejecutadas.

En portátil, mantener la tapa abierta durante toda la prueba. Puede ejecutarse `caffeinate -dius ./init.sh` para impedir suspensión por inactividad; no evita necesariamente el cierre de tapa en batería. Una sola sesión de xcodebuild, con clones aislados gestionados por XCTest (5 workers por defecto), no procesos competidores. Ante pausas de ~900 s en eventos/capturas, cotejar `pmset -g log` antes de atribuirlas a la app. No apagar/reiniciar el simulador en uso. Selección/cobertura vigente: `docs/testing-ui.md`. Los siguientes comandos son alternativas por impacto, no pasos que deban repetirse después del gate.

```sh
./init.sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886 # sustituir por uno disponible: xcrun simctl list devices available
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO '-only-testing:PlantCareAITests/LocalPlantRepositoryTests' test
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 '-only-testing:PlantCareAIUITests/StoredCollectionUITests/testStoredCollectionSurvivesProcessRelaunch' test
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 '-only-testing:PlantCareAITests/PlantCardViewModelTests' \
  '-only-testing:PlantCareAITests/PlantListViewModelTests' \
  '-only-testing:PlantCareAITests/LoadPlantDetailTests' \
  '-only-testing:PlantCareAITests/PlantDetailViewModelTests' \
  '-only-testing:PlantCareAIUITests/PlantCardsUITests' \
  '-only-testing:PlantCareAIUITests/StoredCollectionUITests' test
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

En el simulador estándar con texto normal, recorrer ambos detalles hasta Abonado y el aviso orientativo; tocar foto/contenido debe abrir la ficha del UUID correcto. Mantener las comprobaciones funcionales locales sin API/red. Solo bajo petición expresa: pruebas de Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector, pantallas pequeñas o apariencias adicionales; los identificadores XCTest no prueban lectura auditiva real. No ejecutar esas variantes por defecto ni declararlas superadas sin evidencia.

No existe alta de usuario aún. El almacenamiento acepta JPEG ya preparado; no probar fotos reales de alta hasta planificar orientación/reescalado/límites en `save-plant`. Tarjetas y detalle preparan imágenes de presentación acotadas, no un pipeline de importación. Desinstalar elimina el almacén local real: no usarlo para demostrar reapertura.

## Probar edición mientras no existe alta (Debug Simulator)

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886 # elegir disponible
xcrun simctl install "$UDID" DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app
FIXTURE=$(uuidgen)
xcrun simctl launch "$UDID" org.plantcareai.prototype --storage-test-id "$FIXTURE" --storage-seed -AppleLanguages '(es)'
# Abrir Fixture 1 → Editar: solo nombre y ubicación. Cambiar a Mi monstera / Salón.
# Guardar: detalle y tarjeta nuevos; Fixture 2 intacta. Cancelar/gesto no guardan.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype --storage-test-id "$FIXTURE" --storage-verify-edited -AppleLanguages '(es)'
# Verifica Plant completo (A Mi monstera / Salón, B original) y ambos JPEG exactos.
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype --storage-test-id "$FIXTURE" --storage-cleanup
xcrun simctl terminate "$UDID" org.plantcareai.prototype
```

No usar `--storage-verify` original tras editar: sigue exigiendo valores originales. Para otros nombres/ubicaciones, relanzar solo con `--storage-test-id "$FIXTURE"` (sin seed/verify) y comprobar manualmente. Nunca resembrar para demostrar persistencia. Todos los flags están compilados solo en Debug Simulator; sin flags se usa PlantStore real.

Pruebas focalizadas: `xcodebuild` con destino anterior y `-parallel-testing-enabled YES -parallel-testing-worker-count 5 '-only-testing:PlantCareAITests/UpdatePlantTests' '-only-testing:PlantCareAITests/EditPlantViewModelTests' '-only-testing:PlantCareAITests/LocalPlantRepositoryTests' '-only-testing:PlantCareAIUITests/EditPlantUITests' test`.

Comprobar manualmente teclado, nombre blanco (Guardar deshabilitado/exposición del error), quitar/añadir ubicación, nombres largos/emoji, Cancelar/descarte y nueva precarga en el único simulador estándar con texto normal. Durante guardar no se puede cancelar ni editar; fallo mantiene textos y permite reintento. El fallo de escritura se inyecta en pruebas unitarias/integración, no con corrupción en producción. Repeticiones en pantallas pequeñas, texto aumentado/máximo, VoiceOver/Accessibility Inspector y otras apariencias solo bajo petición expresa; fuera de la verificación habitual, no se declaran superadas.
