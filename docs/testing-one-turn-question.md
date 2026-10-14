# Pruebas de pregunta contextual

- `BuildPlantQuestionContextTests`: aislamiento previo a límites, hoy/90 días/creación y aceptación futuras,
  fecha origen, orden, Unicode/nota500, presupuesto/omisiones y base intacta.
- `AskPlantQuestionTests`: relectura por intención, dos UUID, cero IO de fotos/writers, readers fail-closed,
  stale/missing antes y después del provider, cancelación/lease drenado; cuatro entidades/JPEG reales exactos
  antes/después y al reabrir disco con definitivos de ambas plantas.
- `PlantQuestionViewModelTests`: dedupe, consentimiento vigente sin aviso, rechazo/read/write failure cero HTTP,
  cancelación preparación/preferencias/provider no cooperativo, configuración cambiada, retry explícito,
  edición sin envío/pregunta origen/reemplazo/contexto releído/cierre limpio.
- `OpenAICompatiblePlantQuestionRepositoryTests`: URLProtocol textual, dos mensajes sin fotos/conversación,
  auth opcional, strict JSON/envelope/finish/límites, status/network/timeout seguros y cancelación session.
- `OneTurnQuestionUITests`: mismo campo/sustitución/no aviso sucesivo/reapertura, A/B, rechazo/cancelación,
  offline/retry/texto largo y relaunch sin reseed mediante verificadores reales existentes de cuatro entidades/JPEG.

Seams solo Debug Simulator con UUIDs de almacenamiento/consentimiento opt-in. No API real. Comandos,
fuentes, resultados/fallos y capturas efectivamente inspeccionadas en `docs/handoffs/one-turn-question.md`.
Implementer ejecuta selección por impacto; gate final `./init.sh` reservado a validator independiente.
