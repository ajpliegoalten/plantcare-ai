# Probar eliminación de planta

Spec aprobada intacta: `docs/specs/delete-plant.md`. Contrato ADR015.
No API real ni permisos nuevos. Un iPhone estándar, texto normal/apariencia única; gate final del validator.

## Manual (propuesto, no sustituye evidencia XCTest)

Con dos ejemplares, abrir A, elegir adicional en pager, desplazar al pie después de leyenda.
Eliminar planta → alerta → Cancelar: conserva selección y datos. Volver a pulsar → Eliminar:
vuelve a Mis plantas sin A, B intacta. Relanzar y revisar B/historial. Borrar B muestra vacío real/Añadir.
JPEG fallido no bloquea pie/cascada. Durante commit no funcionan otras acciones/back/gesto; scroll sí.
Storage muestra error/Reintentar; ×/Cancelar abandonan intención y siguiente intento pide nueva alerta.
Conflicto/lectura/ausencia muestran Releer sin retry destructivo.

Fixture sintético SOLO Debug Simulator y almacén UUID:

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
ID=$(uuidgen)
xcrun simctl install "$UDID" DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app
xcrun simctl launch "$UDID" org.plantcareai.prototype --storage-test-id "$ID" --storage-seed --delete-plant-fixture normal -AppleLanguages '(es)'
# Para error/busy, usar failOnce/failAlways/busy en lugar de normal.
# Relanzar SIN --storage-seed y con --delete-plant-verify deleted (o intact/empty).
# El verifier lanza error global si cualquier modelo, byte de B o ausencia completa de A falla.
```

No combinar este verifier con `--storage-verify` antiguo que exige dos plantas. La semilla incluye cinco cuidados,
dos adicionales y dos definitivos por planta, colisiones UUID ENTRE tipos y JPEG idénticos entre ejemplares.
Verifier real revisa modelos completos/bytes, counts de las cuatro entidades y ausencia de JPEG eliminados después de recovery.
No inspeccionar/configurar secretos, no usar rutas de PlantStore/Fotos usuario ni sembrar sin UUID aislado.

## Focales

Build una vez `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" SWIFT_EMIT_LOC_STRINGS=NO build-for-testing`.
`scripts/configure-ui-test-environment.py "$PWD/DerivedData/Build/Products" 0` devuelve el xctestrun.
Seleccionar unitarias DeletePlant y consumidores/escritores según diff, luego UI DeletePlant y regresiones directas.
Capturas valor1 solo DeletePlant (pie/alerta/error/busy); valor0 en regresiones. Nunca ejecutar tests manualmente en paralelo.
Comandos/errores/resultados realmente ejecutados en `docs/handoffs/delete-plant.md`.

Release build y auditoría de símbolo/strings/plist verifican ausencia de DeletePlantTestFixture/DeletePlantFixtureLoad
y `--delete-plant-fixture`/`--delete-plant-verify`. No implica API real, borrado seguro ni matrices adicionales.
