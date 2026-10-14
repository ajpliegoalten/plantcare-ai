# PlantCare AI

PlantCare AI es un prototipo personal para iPhone (iOS 17 o posterior) que ayuda a identificar plantas y conservar sus cuidados e historial. La IA aporta orientación, mientras que cada ejemplar tiene su propia ficha y memoria local: dos plantas de la misma especie se gestionan por separado.

## Qué puedes hacer

- **Añadir una planta:** elegir una foto de la galería o tomarla con la cámara, solicitar propuestas de especie y confirmar una opción. Tras una identificación completada también puedes introducir una especie conocida. Confirmar genera la ficha de cuidados y guarda el ejemplar si la información está completa.
- **Consultar Mis plantas:** ver tarjetas con foto y especie, abrir el detalle y personalizar el nombre y la ubicación. La ficha incluye luz, riego, humedad, temperatura, sustrato y abonado.
- **Registrar cuidados:** anotar riegos, abonados, podas, trasplantes u otros cuidados con fecha y nota opcional. Consultar el último riego y una sugerencia prudente de comprobar la humedad, sin alertas automáticas.
- **Guardar fotografías y consultar el historial:** añadir fotos fechadas y recorrer la cronología de cada planta con sus cuidados y análisis guardados.
- **Analizar una foto con IA:** seleccionar una foto local y recibir observaciones, posibles causas y comprobaciones con el contexto de ese ejemplar. Puedes guardar el análisis junto a esa foto, sin duplicarla, o descartarlo sin borrar la imagen ni modificar el historial.
- **Hacer preguntas contextuales:** consultar a la IA sobre un ejemplar usando su contexto textual, sin enviar fotos. Puedes esperar o cancelar la solicitud y hacer nuevas preguntas independientes; cada respuesta sustituye a la anterior, sin guardar preguntas, respuestas ni una conversación.
- **Eliminar registros o plantas:** borrar cuidados y fotos adicionales con confirmación; la foto inicial solo se elimina al borrar la planta completa junto a su memoria local.
- **Consultar datos sin conexión:** las fichas y el historial ya guardados permanecen disponibles al reabrir la app. Las solicitudes de IA necesitan conexión y permiten reintentos explícitos ante fallos.

## Privacidad y límites

Antes del primer envío externo se solicita consentimiento indicando destino, modelo y finalidad; se renueva cuando cambia el alcance. Para analizar una foto se envía esa imagen y contexto textual pertinente, no las fotografías anteriores para comparar su evolución.

La identificación requiere confirmación humana. Los cuidados y análisis son orientativos, no diagnósticos ni garantías de precisión botánica. La app no incluye cuentas, backend propio, sincronización ni notificaciones. Los datos se conservan localmente, sin recuperación garantizada al eliminar la app o perder el dispositivo.

## Abrir el proyecto

Necesitas macOS, Xcode y un iPhone Simulator disponible. El proyecto se ha verificado con Xcode 26.2; la versión mínima de la app es iOS 17.

1. Prepara el fichero de configuración descrito a continuación.
2. Abre `PlantCareAI.xcodeproj` y selecciona el scheme `PlantCareAI`.
3. Selecciona un iPhone Simulator y ejecuta en **Debug**. La cámara requiere un iPhone compatible; para dispositivo físico hay que configurar además la firma y el aprovisionamiento en Xcode.

## Configurar el fichero `.xcconfig`

La configuración local de IA vive en `Config/IdentificationSecrets.xcconfig`. Es obligatoria para compilar en **Debug**, está ignorada por Git y nunca debe versionarse ni compartirse. La plantilla pública es [Config/IdentificationSecrets.xcconfig.example](Config/IdentificationSecrets.xcconfig.example).

Desde la raíz del repositorio, copia la plantilla **solo si el fichero local no existe**:

```sh
if [ ! -e Config/IdentificationSecrets.xcconfig ]; then
  cp Config/IdentificationSecrets.xcconfig.example Config/IdentificationSecrets.xcconfig
fi
```

Edita el fichero local con los valores de tu proveedor compatible con **OpenAI Chat Completions**, con soporte de visión y generación de texto. Ejemplo sin credenciales y sin servicio real:

```xcconfig
API_SCHEME = https
API_HOST_PATH = api.example.invalid/v1
API_MODEL = vision-model
API_KEY =
API_TIMEOUT_SECONDS = 60
```

| Campo | Configuración |
| --- | --- |
| `API_SCHEME` | Debe ser `https`. |
| `API_HOST_PATH` | Host y ruta base, sin `https://` ni `/chat/completions`. Por ejemplo, para OpenAI: `api.openai.com/v1`. |
| `API_MODEL` | Identificador del modelo con visión y texto disponible en tu proveedor. |
| `API_KEY` | Credencial del proveedor. Puede quedar vacía: se omite `Authorization`, aunque el servicio puede exigir autenticación. |
| `API_TIMEOUT_SECONDS` | Tiempo máximo de la operación, entre 10 y 120 segundos; por defecto, 60. |

La app añade `/chat/completions` a la base: el ejemplo construye `https://api.example.invalid/v1/chat/completions`. El dominio `.invalid` es intencionadamente ficticio: la plantilla permite compilar y ejecutar tests, pero no realizar consultas reales. La compatibilidad del modelo con imágenes y las respuestas esperadas debe comprobarse con el proveedor.

Después de editar el `.xcconfig`, **vuelve a compilar Debug**: los valores se incorporan al bundle durante el build, no se leen del fichero al ejecutar la app. **Release no usa esta configuración ni incluye su clave**, por lo que no habilita las consultas de IA mediante este mecanismo.

### Seguridad de la credencial

- No pegues la clave en código, chat, argumentos de comandos, schemes ni logs. No sobrescribas una configuración local existente con la plantilla.
- `xcconfig` interpreta `//` como comentario incluso entre comillas y expande `$(...)`. Si una credencial contiene sintaxis especial, comprueba que se incorpora exactamente antes de enviar solicitudes.
- Tras una compilación Debug privada, puedes verificar los valores con:

  ```sh
  python3 scripts/verify-identification-config.py DerivedData/Build/Products/Debug-iphonesimulator/PlantCareAI.app
  ```

  Ajusta la ruta si Xcode usa otra carpeta de build. El script pide la URL base, el modelo y la clave de forma interactiva (clave oculta), sin imprimirla ni realizar solicitudes de red.
- La clave incluida en Debug es **extraíble**. No distribuyas esa `.app`, `.ipa` ni sus artefactos de build o pruebas. Este mecanismo es para el prototipo privado, no para distribución pública; revoca o rota la credencial al terminar la demostración si corresponde.

Más detalles: [guía de configuración y pruebas de identificación](docs/testing-identify-candidates.md).

## Verificación y documentación

El gate completo de compilación y tests unitarios/UI es `./init.sh`; compila una vez y ejecuta las pruebas en un único modelo de iPhone Simulator, con PhotosPicker real en una fase serial. No requiere inferencia real: las pruebas usan fixtures y dobles. Consulta [docs/testing-ui.md](docs/testing-ui.md) para las selecciones focalizadas y [AGENTS.md](AGENTS.md) para la política de verificación.

- [Brief del producto](docs/build-brief.md) y [modelo de dominio](docs/domain-model.md).
- [Diseño](DESIGN.md) y [arquitectura Clean Architecture + MVVM](ARCHITECTURE.md).
- [Funcionalidades y estado](feature_list.json), [progreso y evidencias](PROGRESS.md) y [riesgos](docs/risks-and-open-questions.md).
