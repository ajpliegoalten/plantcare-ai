# Comprobar alta directa

Contrato vigente: ADR 007 y spec aprobada `docs/specs/save-plant.md` (SHA256 `b1da9160d037fa26aef29aace79398e01b25bb7c1a05b28d435c78fcb31fcd4e`). Confirmar especie expresa intención de generar y guardar si ficha completa; selección sola no hace IO. No review/resumen/formulario/segundo CTA. Detalle es consulta posterior voluntaria.

## Preparación y permisos

- Para tests, sandbox público con plantilla `Config/IdentificationSecrets.xcconfig.example` y clave vacía. No copiar/inspeccionar config privada ni xcuserdata. Nunca sobrescribir config existente.
- Para comprobación real, el usuario configura en privado endpoint HTTPS/modelo compatibles con Chat Completions, visión y respuesta JSON para identificación y seis cuidados textuales. API_KEY opcional solo si el servicio permite omitirla; permiso explícito para enviar sus propias fotos/autorizadas y aceptar el aviso v4 del destino/modelo real antes de HTTP. Las pruebas previas de cuidados no demuestran esta alta nueva.
- Galería mediante PhotosPicker, sin permiso global; cámara física necesita permiso de cámara y dispositivo compatible/firma local. No micrófono ni ubicación. El alta local no pide otro consentimiento externo.
- No distribuir Debug/DerivedData con clave de demo. No imprimir fotos, payloads, headers, respuestas o claves. Release no incluye config/fixtures.

## Recorrido manual

1. Añadir → foto → Identificar → aviso vigente si corresponde. Seleccionar/deseleccionar principal/alternativa no solicita cuidados ni guarda; manual aparece solo tras éxito de identificación actual, incluso sin candidatas.
2. Elegir alternativa → Confirmar especie. Ver ayuda de intención; durante generación foto visible y cancelación disponible. Ficha incompleta/red/rechazo no crea planta y conserva foto/identidad; retry explícito genera solo texto, sin reenviar JPEG/reidentificar.
3. Éxito retorna directamente a Mis plantas, tarjeta nueva visible, nombre común/científico fallback y ubicación ausente. No resumen, review, formulario, CTA Guardar ni navegación automática al detalle. Abrir detalle voluntariamente y comprobar seis campos/aviso orientativo/fecha/foto.
4. Repetir misma especie mediante texto manual tras identificación exitosa; usar foto distinta. Debe haber otro UUID y cuidados/foto propios. Editar nombre/ubicación después mediante EditPlant.
5. Terminar/reabrir sin reseed: ambas altas, detalles y ejemplares previos intactos. Texto largo consultable por scroll estándar.
6. Con fault seam local opt-in de tests: primer commit falla realmente antes de metadata commit, sin archivos referenciados nuevos; Reintentar guardado conserva snapshot y hace cero nuevas llamadas IA. Cambiar especie oculta elegibilidad; Cancelar edición restaura error y exige retry. Reemplazo fallido conserva A; publicar B invalida snapshot.
7. Cancelar/cerrar durante generación o prevalidación = cero escrituras, continuaciones tardías descartadas. Desde despacho de commit Cancelar/gesto/cambios bloqueados hasta resolución; éxito siempre reconocido. Terminar después de commit conserva planta al reabrir. No promesa de atomicidad física/recuperación del borrador.

## Automatización y límites

Unitarias nuevas: SaveConfirmedPlantTests (mapeo/límites/rollback/bytes/relaunch/duplicado exacto y conflictivo), PreparedPlantPhotoValidationTests (tipo/completitud/dimensiones/metadata/cancelación), SavePlantViewModelTests (retry estable/no IA/callback/cancelación/commit), extensiones de lista (caches/metadata tardía). Regresiones de callers se seleccionan por impacto; no full gate del implementer.

XCUITest nuevas: `testSavePlantAutomaticAIAndManualSameSpeciesRelaunch`, `testSavePlantLocalFailureRetryWithoutNewCareRequest`, `testSavePlantCancellationCommitAndNoReview`. Escenarios históricos de identidad/edición/invalidation se ejercitan ahora con fallo de cuidados retenido (`retained-error`), ya que éxito válido cierra el borrador; comprobaciones de seis cuidados válidos se trasladan al detalle postcommit, no se elimina cobertura ni se vuelve a mostrar review para tests.

`--plant-creation-fixture error` en almacén aislado falla primer beforeCommit real; `waiting` retiene 15 s el tramo de commit para observar controles bloqueados (no test de interrupción física). Fixtures y contadores son solo Debug Simulator; no HTTP, permisos reales ni precisión botánica. Política estándar: único iPhone normal/light, serial/caffeinate/tapa abierta; matrices ampliadas, cámara física/iCloud fuera de verificación habitual y no ejecutadas por agente. Gate final `caffeinate -dius ./init.sh` del validator sobre fuentes finales.

Evidencia y comandos efectivos: `docs/handoffs/save-plant.md` y `DerivedData/evidence/save-plant/`. Ningún aggregate fallido es aprobación; resultados históricos se conservan.
