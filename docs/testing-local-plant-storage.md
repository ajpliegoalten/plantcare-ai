# Verificación local de almacenamiento, tarjetas, detalle y edición

## CareEvents: schema V2 y fixture local (delta other-care-events)

`LocalCareEventRepositoryTests` conserva upgrade V1 real y añade store V2 real con raw watering/siete campos originales, liberando contexto/container antes de abrir. Agrega cinco tipos con nil/notas, reabre y compara orden/aislamiento/Plant/JPEG exactos. Cubre rollback, retry, conflictos zona/kind/UTF8, duplicado tras retroceso de reloj, ausencia/corrupción/unknown raw antes de cleanup. Selección focalizada: RegisterCareEventTests/RegisterCareViewModelTests/LocalCareEventRepositoryTests más repositorio y callers de detalle/lista/editor.

Debug Simulator, siempre `--storage-test-id <UUID>`: `--care-fixture success|fail-first|busy` inyecta fallo únicamente antes del commit de eventos (no rompe seed). Busy retiene el actor12s para observar bloqueo; no demoras en producción. CareExpected.json conserva payloads de despacho y rechaza cambios del mismo UUID; `--care-verify <count>` compara siete campos de los confirmados contra sus despachos y exige B sin eventos. Intenciones fallidas descartadas no cuentan como confirmadas. `--care-expected-offset 0|-1` comprueba día gregoriano relativo al createdAt/origen; `--care-expected-note-base64 <UTF8-base64>` compara nota literal. Sin expectativas nuevas exige watering/nota nil. `--care-expectations-base64 <JSON-base64>` recibe array independiente `{kind,note,offset}` por evento (nota null admisible), compara uno-a-uno sin depender de selección ni payload capturado; permite notas distintas y detecta kind incorrecto. Combinar `--storage-verify` para ambos Plant/JPEG exactos, excepto foto ausente intencionada. Sin reseed/desinstalar al verificar. Cleanup UUID elimina sidecar. No equivale a cronología productiva ni constante de contador. Flags watering anteriores fueron sustituidos, no son aliases actuales; evidencia histórica conserva comandos originales.

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
## Delta ADR011 — fotos adicionales

LocalPlantRepository también implementa PlantPhotoRepository en schema documental V3 no versionado. PersistedPlant/PersistedCareEvent y sus archivos/campos permanecen intactos; `AdditionalPhotos/<photoID>.jpg` tiene referencia propia y recuperación separada. Ambas limpiezas esperan validación global de metadata/pertenencia. Metadata adicional no lee JPEG, byte-read exige photoID+plantID. Duplicado literal (siete campos+bytes) reconcilia antes del reloj; conflicto nunca overwrite. Archivo referenciado roto no borra metadata ni planta. Pruebas LocalPlantPhotoRepositoryTests crean V2/V1 reales, liberan containers, migran/reabren y verifican cinco kinds/modelos/portadas exactos, publicación/rollback/recuperación/aislamiento. Detalles y evidencia: testing-add-plant-photo y handoff. No timeline/batch/IA ni segundo actor/container.
