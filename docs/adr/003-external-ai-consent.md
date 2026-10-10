# ADR 003: consentimiento externo por instalación y barrera común

2026-10-10. Decisión implementada conforme spec aprobada por usuario (conservada sin cambios).

## Decisión

Aceptación explícita versionada por destinatario lógico en una preferencia UserDefaults, fuera de PlantStore. Domain define `AuthorizeExternalAIOperation`: lectura fail-closed, confirmación requerida sin invocar, registro antes de continuación y comprobaciones de cancelación entre etapas. No retiene payloads ni inicia tareas. Presentation conserva una intención efímera por foto y evita duplicados; composición inyecta repositorio y continuación.

`identify-candidates`, `generate-care-sheet`, `analyze-current-photo` y `one-turn-question` deberán invocar sus transportes dentro de esta barrera, también para texto sin foto. No basta una bandera UI. No se autoriza envío automático al abrir ni se exporta la colección.

## Consecuencias y transición

Esta entrega solo muestra indisponibilidad: no existe cliente IA/red. El destinatario provisional `prototype-external-ai`, aviso 1, no identifica una empresa. Antes de conectar red se debe fijar destinatario real, actualizar aviso y renovar alcance/consentimiento; cambios materiales de datos/finalidades también lo renuevan. No hay nueva dependencia ni migración SwiftData.

UserDefaults recuerda una preferencia real, no garantiza escritura durable ante apagado abrupto. Ausencia/malformación obliga a confirmar; errores operativos bloquean. Rechazos no se guardan. Cancelar tras registro no revoca aceptación ni bytes enviados por futuras funciones. No se añade pantalla de revocación.

Data valida estrictamente estructura y tipo de versión (Boolean no es versión). Registrar elimina primero la clave y vuelve a escribir sin suspensión para evitar que igualdad NSNumber(true)==NSNumber(1) conserve una representación inválida. No es una transacción durable; pérdida del registro exige confirmar otra vez. La regresión se prueba con suite aislada.
