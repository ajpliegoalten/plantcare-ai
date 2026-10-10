# Probar consentimiento de IA externa

## Alcance actual

No hay transporte/red, API, clave ni candidatas. Producción continúa con «La identificación todavía no está disponible. No se ha enviado ninguna foto.». El spy es solo un contador sin payload/red, compilado Debug Simulator; no simula éxito botánico. ADR 003 y ARCHITECTURE describen la barrera reutilizable para futuras operaciones de foto y texto.

## Gate y pruebas

Coordinar con sesión activa; una sola ejecución sobre el iPhone estándar, texto normal y una apariencia. Mantener tapa abierta:

```sh
caffeinate -dius ./init.sh
```

Unitarias `ExternalAIConsentTests`, `UserDefaultsExternalAIConsentRepositoryTests` e `IdentificationConsentViewModelTests` prueban orden registro→invocación, foto/texto bloqueados, errores, alcance, malformación, cancelación y duplicados. UI añade tres escenarios `testExternalConsent…`: cancelar/gesto/terminar, aceptar/reabrir/relanzar, nueva suite, indisponibilidad sin spy, modelos/JPEG de dos plantas íntegros tras `--storage-verify` y error recuperable. Mantiene picker real y regresiones anteriores.

## Apertura manual aislada

Después del gate, con el mismo UDID e instalación:

```sh
UDID=B52F5194-6A81-4FAA-B094-B0D248084877 # ajustar al destino del gate
ID=$(uuidgen)
xcrun simctl install "$UDID" DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app
xcrun simctl launch "$UDID" org.plantcareai.prototype --storage-test-id "$ID" --consent-test-id "$ID" --identification-photo-fixture --consent-spy -AppleLanguages '(es)'
```

Añadir → Test A (desplazar si hace falta) → Identificar. No aviso ni invocación al elegir foto. Cancelar/gesto deben conservar A y contador 0; reintento vuelve a avisar. Aceptar continúa una vez; cada nuevo toque explícito añade una invocación sin aviso. Cerrar/reabrir no invoca. Terminar y lanzar con los mismos argumentos conserva aceptación (contador en memoria empieza en 0), no foto. Otro ID vuelve a pedir aviso. Sin `--consent-spy` se usa la continuación real indisponible, sin contador. `--consent-fail-read` muestra error con cero invocaciones y A intacta.

La suite `ExternalAIConsentTests.<UUID>` no es el dominio estándar. El fixture no borra preferencias estándar ni toca PlantStore. Limpiar solo los IDs propios:

```sh
xcrun simctl terminate "$UDID" org.plantcareai.prototype
xcrun simctl launch "$UDID" org.plantcareai.prototype --storage-test-id "$ID" --storage-cleanup --consent-test-id "$ID" --consent-cleanup
```

XCUITest realiza limpieza de sus propios IDs al terminar. No usar cleanup antes de relanzamientos que prueban persistencia.

## Límites

Autoverificación 2026-10-10: baseline 58/58, focalizada 15/15 y gate final 70/70, todos sin fallos/omitidas. Release Simulator y auditoría de fixtures correctos. Capturas reales inspeccionadas y apertura manual aislada/limpieza ejecutadas. Evidencia exacta y fallo host inicial corregido en PROGRESS y `docs/handoffs/external-ai-consent.md`; no equivalen a aceptación independiente.

Contadores demuestran invocaciones del boundary, no solicitudes HTTP reales. Proveedor pendiente y alcance provisional deberán renovarse antes de conectar red. UserDefaults no demuestra escritura durable ante apagado brusco. Sin cámara física, red/API, retención externa ni garantías legales verificadas en esta entrega. SE, texto aumentado, VoiceOver y matrices no forman parte de comprobación habitual y no se ejecutan sin petición expresa. Consultar PROGRESS/feature_list para evidencia realmente ejecutada, incluidos fallos intermedios.
