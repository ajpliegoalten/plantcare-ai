# PlantTimeline scroll fix — validación independiente

## Veredicto: ACCEPT

Ronda `plant-timeline-scroll-fix`, una feature `plant-timeline`; validator `openai/gpt-6.1-sol`. Sin hallazgos bloqueantes ni repair brief vigente. `active_round` permanece passing hasta persistencia del orquestador. Esta aceptación es nueva: no reutiliza el gate254 histórico ni reescribe su informe.

## Contrato, fuentes y revisión

- Spec `docs/specs/plant-timeline.md` byte-intacta SHA256 `4a3ff9e8bfeb87a94bc079939d4c9d8eb0e5997d71e304c8c1b289d6f2c021b4`. Rama feature/plant-timeline, HEAD `66d0d99bdc97fa54bb1d3798bda04ba51df948a9`; base main `52958d28ec907f0f7f4fbb0e6b298bd371f0fb28`.
-152 inputs públicos exactos antes/después del gate: `DerivedData/evidence/plant-timeline-scroll-fix/validator/inputs-{before,after}.json`, SHA256 `7aa2e8e5c2cdc95abb9ec6db1672e788f2e5003417b80d1bb7244c9236f99b33`, igual al manifest refresh-final. Config privada solo comprobada existente, sin leer/hash/copiar/sobrescribir.
- Revisados diff de ronda y contexto frente base, capas/composición/callers/spec/docs: frames de fotografía y viewport comparten coordenadas ScrollView; PreferenceKey reduce por identidad discriminada. Demanda por intersección positiva/área, máximo3; montaje LazyVStack no equivale a visibilidad. Último payload coalescido fuera de layout, conjunto visible idempotente y loading no republicado.
- Cache única≤3 thumbnails, no JPEG/UIImage en estado publicado; expulsa ocultas antes de visibles, retorno geométrico solicita cache miss sin onAppear. Cola≤2 cuenta tareas canceladas drenando: reset conserva tasks hasta completion, generaciones/tokens/allowed y plantID impiden tardíos cruzados. Hide diferido permite reparenting/reversión; salida cancela preferencias/owners y borra geometría/cache.
- Refresh limpia imágenes y conserva exclusivamente geometría, replay contra entradas propias nuevas; no cache vieja ni unión incompleta. Orden/días/fechas únicas/pie, push/selección/back, Domain/Data productivo/schema/carrusel/portadas intactos. Fixture8JPEG alternos Debug Simulator/almacén UUID real y UI exige valor Foto cargada, no mera existencia. No assertions heredadas debilitadas ni timeout ampliado/retries para verde.

## Verificación nueva y reutilizada

ÚNICO original `caffeinate -dius ./init.sh`, **exit0**, TEST BUILD SUCCEEDED y ambas TEST EXECUTE SUCCEEDED. Global 2026-10-12 23:43:53–23:59:12 +0200. **260/260 distintos:194unit+64UI paralelas+2PhotosPicker seriales**, cero failed/skipped/expected failures. Árboles originales/summary/log corroborados, IDs únicos/disjuntos entre fases; sin marcadores de error runner encontrados.

Bundles:
- `DerivedData/TestResults/20261012-234353-37669/parallel.xcresult` (258).
- `DerivedData/TestResults/20261012-234353-37669/gallery.xcresult` (2).

Evidencia local: `DerivedData/evidence/plant-timeline-scroll-fix/validator/` contiene log, exit, tiempos, preflight, manifests, summaries/trees y corroboración. Espera proceso original PID37673 mediante kqueue NOTE_EXIT, sin polling/relaunch/segundo gate. Primer selector propio de PID por comm completo no encontró caffeinate; corregido a PID observado, sin afectar ejecución original.

Preflight fail-closed corroboró algoritmo REAL init y root Booted `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`; ambos bundles/log confirman iPhone17Pro iOS26.2/23C54, Xcode26.2/17C52 macOS26.5.1/25F80,5workers/capturas0/light. Texto normal/default reportado en handoff; preferencia global específica ausente en consulta independiente, no medición large inventada ni cambio de settings. Sin competidores antes ni procesos de tests activos al cierre. ProMax ajeno no usado/manipulado, sin resets/borrados/matrices extra.

Corroboración independiente **23 focalizados distintos17unit+6UI**, sin rerun:19 refresh-final y4UI layout-final por impacto documentado. Originales conservados; reproducción Failed, focused14/16Failed y regressions4/5Failed nunca reinterpretados aprobados. Scheduling/refresh nuevos probados, sin afirmación universal sobre causa profunda del incidente mainrunloop.

Inspección visual básica reutilizada: abiertas realmente PNG `84B10741-54D2-4344-A1E9-12CD8F456278` extremo inferior y `3DC3B99A-BEBF-4A24-916C-D9118F2B7035` retorno superior en focused-attachments: imágenes alternas/inicial reales, tarjetas/fechas/pie conformes. Renderer/diseño equivalentes; estado definitivo además ejercitado por gate/UI. Frames Mixed solo diagnóstico, no visual aprobado. ManualOK usuario anterior a scheduling/refresh se conserva como reportado, no smoke nuevo del agente.

Static `git diff --check`, `plutil -lint` proyecto, JSON/manifests y semántica catálogo pasan. Sin focales redundantes/Release nuevo/tests ampliados; matrices SE/DynamicType aumentado/VoiceOver fuera habitual, no ejecutadas ni bloqueos automáticos.

## Seguridad, documentación y entrega

Checklist seguridad diff-focused sin issues relevantes bloqueantes: no nuevos secretos/dependencias/red/IO productivo/escrituras/path de usuario; loaders continúan pertenencia UUID y guardas propias. Fixture únicamente Debug Simulator opt-in y datos sintéticos; cancelación/caché limitan demanda sin prometer memoria constante de originales. Auth remota no aplica a consulta local.

ARCHITECTURE/testing/handoff describen comportamiento vigente; históricos/spec/informe original intactos. Límite snapshot secuencial y cancelación no instantánea de IO conservado. Sin nueva deuda contractual transversal.

**Recurso ajeno:** Localizable.xcstrings previo preservado sin escrituras del validator; claves y traducciones/estructura semántica exactamente HEAD, diferencias solo formato/orden y extractionState. Gate cubre bytes actuales del manifest; excluir catálogo ajeno del commit mantiene recursos funcionalmente equivalentes para nuevas accessibilityValue (claves existentes), no afirmar byte-identidad del catálogo HEAD con el probado. No requiere gate duplicado por exclusión semánticamente neutra.

Siguiente exclusivo orquestador: persistir active_round accepted y evidencia/verdict, luego commit LOCAL autorizado excluyendo catálogo ajeno; no stage/commit/push/PR/merge/GitHub por validator. No repetir gate por cambios documentales/status/rol. Smoke humano sugerido (no ejecutado aquí): recorrer fotos ida/vuelta e invertir dirección, refrescar/reabrir y volver al detalle manteniendo selección.
