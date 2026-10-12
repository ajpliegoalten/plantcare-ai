# add-plant-photo — refinamiento solicitado después de la aceptación

Base local: `cdea7b1`; misma rama/worktree `feature/add-plant-photo`. Petición directa del usuario, sin nueva feature ni autorización de commit/publicación. Spec original y aceptación histórica se conservan intactas.

## Contrato vigente de esta ronda

- Añadir foto comparte placeholder (hoja, texto centrado, fondo blanco, 4:3/radio22), cápsulas verticales y superficie inset con Identificar: galería verde prominente, cámara bordered y Guardar foto inferior.
- Cabecera reutiliza PlantFormHeader con thumbnail inicial snapshot56, nombre y descripción de pertenencia, como Editar/Registrar cuidado. Si la portada falla, placeholder; sin IO adicional ni copiar portada al borrador.
- Entrada Añadir foto verde activa, sin apariencia gris de deshabilitado.
- Orden del paginador **createdAt ascendente**, antigua primero, reciente última, empate por identidad discriminada estable. occurredAt sigue mostrándose sin determinar posición. Sin migración ni modificar registros existentes; orden interno de loadPhotos no se cambia para otras proyecciones.
- Cierre tras commit selecciona identidad nueva, incluso con fecha humana antigua. Una sheet/cámara sobre el detalle no equivale a abandonarlo: no invalidar su sesión/callback ni restaurar inicial al cerrarla. Salir realmente al listado sí cancela/restablece.
- TabView nativo `.page`, tags por identidad, selección común con botones animados ‹ › y swipe con desplazamiento interactivo. Sin wrap; extremos y single-photo intactos.
- Páginas vecinas renderizan thumbnails existentes de cache acotada o placeholder, sin tareas/precarga por página. Solo selección solicita bytes; cache≤3, foto inicial preservada para formularios. Errores/retry/cancel/generaciones conservados.
- Dirección Presentation→Domain←Data/composición existente: layout compartido en Shared/Presentation, orden en Domain, almacenamiento intacto.

## Verificación por impacto propuesta

- Domain/orden: LoadPlantPhotosTests, AddPlantPhotoTests; tests de createdAt ascendente con fechas humanas inversas, empate/input inverso/UUID discriminados.
- Pager/retorno sheet: PlantPhotoPagerViewModelTests y PlantDetailViewModelTests; nuevas seleccionadas, reaparecer sin reset, cache vecinos/0writes/late reads.
- AddPlantPhotoViewModelTests/regresiones de composición, sin repetir toda persistencia/migración sin cambios Data.
- AddPlantPhotoUITests: seis escenarios existentes reforzados con cabecera/botones verticales/guardar retroactiva→última/swipe real/extremos/relaunch inicial/aislamiento/errores/cancel/busy.
- IdentificationPhotoUITests y callers de preview/acciones compartidas, editor/cuidado y fallback directamente relacionados; PhotosPicker real serial con ambas pruebas existentes.
- Un iPhone estándar normal/claro; capturas focalizadas modal vacío/preview y paginador; verificar desplazamiento con video si disponible. Sin matrices ampliadas, gate/baseline completos ni retries para verde. Validator independiente posee gate final si se solicita aceptación de ronda.
- Registrar comandos/resultados/fallos/manifests y estado de ronda, sin atribuir gate histórico233/233 a estas fuentes nuevas.
