# Comprobación de fotos adicionales

Contrato/spec: `docs/specs/add-plant-photo.md` (aprobada, byte-intacta). Decisión ADR011; evidencia ejecutada y comandos completos en `docs/handoffs/add-plant-photo.md`. No atribuir el gate histórico de otras features a este código.

## Selectores y fixtures

- Entrada `detailAddPhoto-UUID`; modal `addPlantPhotoForm`; placeholder/preview `additionalPhotoPlaceholder`/`additionalPhotoPreview` (value dimensiones preparadas). Fecha `additionalPhotoDate`, fuentes `additionalPhotoGallery/Camera`, progreso/error/saving, Guardar/retry/cancelar `saveAdditionalPhoto/retryAdditionalPhoto/cancelAdditionalPhoto`; confirmación `additionalPhotoConfirmation-UUID`.
- Paginador `plantPhotoPager-UUID`, fecha `plantPhotoDate-UUID`, botones `plantPhotoPrevious/Next-UUID`, metadata error/retry `plantPhotoMetadataError/Retry-UUID`. Inicial conserva `detailPhoto-UUID`, value exacto histórico, `detailPhotoError-UUID/retryDetailPhoto-UUID`. Adicional imagen/error/retry usa `plantPhotoImage/Error/Retry-additional-photoUUID`; image loaded añade dimensiones del thumbnail, para probar imagen seleccionada independientemente de fecha.
- Solo Debug Simulator y namespace UUID StorageTests. `--additional-photo-fixture success|errorOnce|busy` habilita A/B/failure del pipeline existente; errorOnce falla la primera seam antes de save y busy espera8s síncronos en el actor para observar doble tap/gesto/controles, no en MainActor. `--additional-photo-delay` demora transferencia2s únicamente donde se observa cancelación. No sidecar nuevo ni seed fotográfico adicional que sustituya lecturas reales.
- `--additional-photo-read-fixture metadataErrorOnce|imageErrorOnce` falla la primera lectura pertinente y después delega al mismo repositorio real; no otro store/container.
- `--photo-verify 'A:0,B:-1;A:0'` exige cantidades por planta, fecha relativa a createdAt en origen, metadata/dimensiones y JPEG preparados **exactos** frente a assets independientes, más cero eventos en fixtures sembrados. `--storage-verify` sigue comprobando ambos modelos/portadas completos. Assets `gallery-A/B` reproducen pixels del seed público para comparar JPEG real del picker. No usar sidecar del writer como expectativa.

## Cobertura mantenida

Refinamiento posterior en `docs/specs/add-plant-photo-refinement.md`/`docs/handoffs/add-plant-photo-refinement.md`: createdAt ascendente frente a occurredAt inverso y empates, TabView page interactivo, nueva identidad visible tras cerrar sheet, cabecera snapshot y botones verticales/placeholder compartido con identificación. Placeholder es ahora contenedor accesible con hoja decorativa/texto, no Image aislada; preview mantiene ID/dimensiones. Tests de orden/dirección actualizados conservando persistencia/aislamiento/swipe/calendario/futuros y byte-verification, sin suprimir aserciones funcionales. Una nueva prueba de empates añade1unit al descubrimiento, no interpretar la predicción histórica siguiente como gate actual.

Unitarias: validación temporal/DST/día omitido/futuro/zonas/dimensiones; unión/identidades/orden; upgrade V2/V1 real, cinco kinds/modelos/JPEG exactos, duplicados/conflictos/rollback/tres seams/recuperación/archivo existente/referencias corruptas/aislamiento; snapshots/retry/zona-medianoche/cierre/prevalidación/commit bloqueado/callback; paginador/cache3/inicial retenida/metadata y bytes atrasados/lifecycle/cero writes. Detail prueba fábricas loaded-only y snapshots editor/cuidado iniciales mientras se selecciona adicional.

`AddPlantPhotoUITests` tiene6 escenarios. `SystemGalleryUITests` conserva identificación y añade integración real adicional (seleccionar/reemplazar/cancelar/reseleccionar/guardar/relaunch/JPEG exacto). **Clase Fotos completa serial**, sembrada en el destino acordado; init.sh intacto ya selecciona la clase entera. Predicción actual para el validator, no resultado: 173unit+58UI paralelas y2Fotos serial =233 escenarios.

Calendar DatePicker de iOS26 puede publicar botón habilitado/visible sin AX hit point: el test comprueba existencia, enabled y frame completamente visible antes de tap al centro nativo; exige calendario real, futuro deshabilitado y fecha/persistencia exactas. No editar estado por fixture ni eliminar assertions para pasar. Helpers de selección/reemplazo heredados no se modifican.

## Selección futura

Aplicar AGENTS por impacto; no ejecutar todo antes/después por rutina. Sources Data/schema/recuperación justifican LocalPlantRepositoryTests+LocalCareEventRepositoryTests, fábricas/detail justifican tests VM/callers y UI relacionados. Para Fotos: bootstatus del **UDID acordado** antes de addmedia, sin borrar media ajena; XCTest paralelo puede dejar el root apagado. Un fallo de preparación no es test aprobado. Capturas solo en nuevos escenarios/pantallas afectados; configurar0 para regresiones si sus helpers generan capturas por fila.

Hardware/cámara física/iCloud, SE/Dynamic Type aumentado/VoiceOver/matrices no ejecutados por defecto. Validator ejecuta único gate final con ambas fases; implementer entrega evidencia focalizada/reuse, nunca accepted.
