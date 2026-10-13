# Verificación keep-analysis

Spec aprobada intacta. Autoverificación por impacto; gate final independiente reservado al validator. Comandos/estado/evidencia en `docs/handoffs/keep-analysis.md` y `DerivedData/evidence/keep-analysis/`.

## Cambios → riesgos → selección

- Domain/entidad/actor V4 → duplicados/huérfanos/pérdida → KeepPlantPhotoAnalysisTests/LocalPlantPhotoAnalysisRepositoryTests: contenido, fechas, Unicode literal, idempotencia/conflicto, origen obsoleto, disco/reopen/aislamiento/JPEG, upgrade V1/V2/V3, corrupción antes de cleanup, delete rollback/cleanup.
- ModelContainer compartido → regresión → LocalPlantRepositoryTests/LocalPlantPhotoRepositoryTests/LocalCareEventRepositoryTests/DeletePlantPhotoTests.
- Reader/contexto/snapshot → reenvío/unión parcial → AnalyzePlantPhotoTests/BuildPlantAnalysisContextTests/LoadPlantTimelineTests e integración lector real; temporalidad/presupuestos existentes intactos.
- Modal/consumidores → doble despacho/cancelación/retry con red → PlantPhotoAnalysisViewModelTests/PlantTimelineViewModelTests/PlantPhotoPagerViewModelTests.
- UI/composición → selección/texto/copy → KeepAnalysisUITests/AnalyzeCurrentPhotoUITests: inicial/adicional/relaunch/texto largo/error/retry/busy/cierre/gesto/delete/retained pager/provisional/insuficiencia.

Opt-in Debug Simulator `--keep-analysis-fixture failOnce|busy` actúa en seam precommit del actor REAL, almacén UUID, sin HTTP/sidecar. Destino único estándar/texto normal/una apariencia. Capturas focales, matrices ampliadas fuera de rutina/no ejecutadas/no blockers. Harness/PhotosPicker intactos; gate no rutinario implementer.

## Correspondencia con escenarios de la spec

1/3: disco/reopen/igual JPEG dos plantas/identidades y proyección de dos hitos, modelos/cuidados/bytes exactos; UI inicial y adicional.
2: VM cierre libera provisional y UI AnalyzeCurrentPhoto sin escrituras, Descarta deshabilitado; cierre local sin guardar adicional.
4/5: seam real precommit/rollback; VM retry literal/callsHTTP1/doble despacho/busy/callback; UI error y busy12s/gesto/relaunch.
6: lector real bloquea prepare y execute sin provider, mock error fail-closed; pager unknown/failure/token tardío no habilita definitivo.
7: lector real con origen anterior y aceptación posterior/otra planta/JPEG histórico ausente; constructor existente strict-day/5bloques/16KiB/omisiones mantiene sus siete regresiones.
8: descriptor cambiado/identidad ausente/idempotencia/conflictos en actor y VM requiere nueva intención.
9: delete real foto+texto rollback/conservación de JPEG/cleanup fallido y recuperación; UI alerta solo asociada/cancel/confirm/retained pager; inicial protegida por regresiones DeletePlantPhotoTests.
10: texto largo UI bajo miniatura, texto completo adicional y caso JPEG faltante bajo placeholder; corrupción/duplicados/vínculos erróneos fallan globalmente antes de cleanup. Sin comparación de fotos, diagnóstico botánico ni confianza remota acreditada.

Esta matriz describe cobertura, no resultados: resultados reales/pendientes/fallos/reparaciones y reuso aparecen en el handoff y xcresult originales. No sumar runs repetidos ni resultados parciales de un método fallido como Passed.
