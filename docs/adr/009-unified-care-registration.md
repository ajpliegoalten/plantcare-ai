# ADR 009: registro unificado de cuidados

Fecha: 2026-10-12. Feature other-care-events; spec aprobada íntegra, autoverificación y aceptación se registran por separado.

## Decisión

Generalizar QuickWatering a `Features/CareEvents`, sin wrapper ni reglas duplicadas: `RegisterCareView → RegisterCareViewModel → RegisterCareEvent → CareEventRepository ← LocalPlantRepository`. App compone el mismo actor tras overrides Debug; detalle/lista actualizan sus callers. Un único popup Registrar cuidado, cinco raws estables `watering`, `fertilizing`, `pruning`, `repotting`, `other`, en ese orden visual. Apertura sin tipo; selección exclusiva con toggle nil. Guardar requiere selección tanto en vista como en VM; riego rápido pasa de dos a tres taps autorizados (abrir/elegir/guardar).

## Persistencia y transacciones

Conservar íntegro el contrato de ADR008: siete campos, tiempo gregoriano/origen IANA, nota UTF8/trim, actor sin suspensión durante commit, rollback y reconciliación antes del reloj. PersistedCareEvent mantiene nombre/@Model/propiedades; kind sigue String y se amplían únicamente valores admitidos. No schema V3, backfill, reset ni cambios Plant/JPEG. Watering V2 antiguo debe conservar siete campos tras agregar nuevos tipos/reabrir; V1→V2 sigue probado. Unknown raw falla antes de cleanup. No garantía de downgrade: una versión antigua puede rechazar nuevos raws.

El snapshot incluye kind y se conserva al reintentar sin editar, incluso tras cambio de zona/medianoche. Cambiar/deseleccionar tipo invalida snapshot/error conservando fecha/nota; nueva escritura tiene UUID nuevo. Durante commit tipos/campos/cancelación/gesto bloqueados; callback y confirmación genérica solo tras resultado canónico real, sin ignorar éxito por cancelación técnica tardía.

## Presentación y consecuencias

Grid dos columnas de cinco opciones (Otro izquierda), iconos/localización solo Presentation, check/borde/trait selected. TextEditor nativo sin límite de dominio. Cabecera foto56 para cuidado/default48 editor sin IO adicional. Banner efímero Cuidado registrado. Sin cronología/última-fecha/recomendaciones/IA/Deshacer/footer. Los textos orientativos de la ficha no cambian. Fixtures opt-in Debug Simulator comparan payload7 capturado y expectativas independientes kind/nota/día; no historial ficticio. Specs/ADR008/evidencias históricas conservados; el delta actual no reinterpreta las pruebas anteriores.
