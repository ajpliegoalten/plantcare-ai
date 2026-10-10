# ADR 005 — Identidad confirmada del borrador

Fecha: 2026-10-10. Decisión aprobada en la spec confirm-species.

## Contexto y decisión

La propuesta de IA no es una identidad aceptada ni una planta. El usuario selecciona una posición de una revisión de resultado y confirma en una acción distinta, sin preselección.

`ConfirmedDraftIdentity` contiene UUID de foto y revisión, nombres exactos opcionales y procedencia `primary`/`alternative(index:)`. `ConfirmSpecies` valida resultado y pertenencia de forma pura. El VM existente es dueño de foto, resultado, selección e identidad; no hay repositorio, segunda copia de JPEG ni Data nueva.

Una nueva identificación invalida desde el inicio; una nueva foto invalida solo al publicarse con éxito. Fallo/cancelación de sustitución conserva A. Cerrar descarta todo. Cada resultado publicado tiene revisión nueva; acciones obsoletas se ignoran. Cambiar especie elimina la confirmación, conserva la selección y exige reconfirmar.

## Consecuencias

La confirmación es humana, no certificación botánica ni alta. El resumen no solicita cuidados ni guarda. La futura generación de cuidados consumirá foto e identidad del mismo borrador comprobando `photoID`; su intención externa mantendrá la barrera de consentimiento. Manual-species acordará su procedencia propia; save-plant será responsable del mapeo y persistencia. Esas capacidades no se implementan aquí.
