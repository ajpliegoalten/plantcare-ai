# Pruebas de selección de foto inicial

Feature `choose-identification-photo`; spec aprobada intacta en `docs/specs/choose-identification-photo.md`. Esta pantalla no identifica ni guarda plantas: Identificar está deshabilitado deliberadamente.

## Gate y simulador

Coordinar primero: una sola ejecución y un iPhone estándar, texto normal/una apariencia, tapa abierta. Ejecutar `caffeinate -dius ./init.sh`. El gate genera `DerivedData/IdentificationPhotoMedia/picker-A.png` (verde, 160×80) y `picker-B.png` (naranja, 80×160), con esquina blanca superior izquierda, e importa ambas con `simctl addmedia` antes de UI tests. Son imágenes sintéticas locales, sin datos privados ni descarga. Cada ejecución añade dos recursos a Fotos del simulador; no modifica el almacenamiento de plantas. Para limpiar, eliminarlos desde Fotos (no borrar fotos ajenas ni resetear simulador compartido).

Seed independiente, antes de pruebas focalizadas del picker:

```sh
UDID=B52F5194-6A81-4FAA-B094-B0D248084877
xcrun swift scripts/seed-identification-photos.swift "$PWD/DerivedData/IdentificationPhotoMedia"
xcrun simctl addmedia "$UDID" "$PWD/DerivedData/IdentificationPhotoMedia/picker-A.png" "$PWD/DerivedData/IdentificationPhotoMedia/picker-B.png"
xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$PWD/DerivedData" \
  -parallel-testing-enabled NO \
  -only-testing:PlantCareAITests/IdentificationPhotoPreparationTests \
  -only-testing:PlantCareAITests/IdentificationPhotoViewModelTests \
  -only-testing:PlantCareAITests/CameraAccessTests \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests test
```

## Flujo real y seam determinista

Instalar app Debug y lanzar sin seam para galería real. Desde Añadir o Añadir mi primera planta: abrir Elegir de galería, elegir una imagen sintética reciente, comprobar imagen completa/orientación y dimensiones. Repetir con la otra; cancelar el picker mantiene A y no produce error; volver a elegir el mismo recurso es posible. Cerrar con Cancelar/gesto, reabrir y relanzar no restaura foto. Tomar foto en simulador muestra indisponibilidad, no captura ficticia. Ninguno de estos pasos debe alterar colección vacía/ejemplares.

`--identification-photo-fixture` habilita controles Test A/B/failure **solo Debug Simulator**: imágenes verde horizontal 120×80/naranja vertical 80×120 y bytes inválidos, con 2 s de transferencia para observar progreso/cancelación. Usa el preparador real, no el picker. No sirve como evidencia de cámara ni de integración Photos. La suite mantiene además selección real en PhotosPicker y cancelación nativa.

Para fixture de dos ejemplares, seguir `docs/testing-local-plant-storage.md`: `--storage-test-id <UUID> --storage-seed`, después relanzar sin seed con `--storage-verify` (comprueba modelos/bytes completos). Seleccionar/cambiar/cancelar foto no llama a repositorio; no crea JPEG de borrador en PlantStore. Cleanup del fixture según esa guía; no desinstalar entre seed y verify.

## Cierre por gesto y diagnóstico H1

En simulador estándar, preparar A y **sin cerrar el proceso** arrastrar la sheet desde la zona libre derecha de su barra superior hasta la zona baja de la pantalla y soltar. Debe desaparecer el modal, poder pulsarse Añadir en el listado original y abrirse un modal sin foto/progreso/error. No basta ver el texto del listado detrás de la sheet, ni terminar/reabrir el proceso para demostrar descarte inmediato.

El E2E usa `dismissPhotoByDrag`: origen visible comprobado en barra, destino 90% de altura de ventana y drag nativo; conserva timeout de ausencia de 5 s. El anterior `navigationBar.swipeDown()` produjo un desplazamiento corto de la sheet sin completar dismiss en el validator (57/58, repetición 0/1). La reparación conserva el gesto desde modal vacío y añade foto A + reapertura limpia en mismo proceso. Dos focalizadas y gate posterior pasaron; ver PROGRESS/handoff para evidencia, sin convertir la autoverificación en aceptación independiente.

## Cámara física (si hay iPhone conectado/firma local)

Configurar firma fuera de Git. Con permiso sin decidir: abrir Añadir no debe pedir cámara; Tomar foto sí. Aceptar → captura real → confirmar → preview; repetir y cancelar conserva A. Permiso autorizado no vuelve a preguntar. Denegar → explicación y galería/Ajustes; regresar de Ajustes y reintentar vuelve a consultar estado. Restricted explica restricción sin prometer solución en Ajustes. No guarda captura en Fotos. Registrar dispositivo/OS/estado/pasos realmente ejecutados; simulador/dobles no sustituyen hardware.

## Límites de evidencia

No hay cliente IA ni red propia; Photos puede descargar un recurso iCloud por cuenta del sistema. No es evidencia de selección offline. Input Data/UIImage completa existe antes de sus límites: no afirmar memoria constante ni pipeline final de alta. SE/Dynamic Type aumentado/VoiceOver/matrices adicionales quedan fuera de rutina salvo petición expresa. Resultados, fallos y artefactos concretos se registran en PROGRESS.md.
