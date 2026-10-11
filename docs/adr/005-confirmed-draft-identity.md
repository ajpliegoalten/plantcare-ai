# ADR 005 — Identidad confirmada del borrador

Fecha: 2026-10-10. Decisión aprobada en la spec confirm-species.

## Contexto y decisión

La propuesta de IA no es una identidad aceptada ni una planta. El usuario selecciona una posición de una revisión de resultado y confirma en una acción distinta, sin preselección.

El contrato original de `ConfirmedDraftIdentity` contenía UUID de foto y revisión, nombres exactos opcionales y procedencia `primary`/`alternative(index:)`; la ampliación ratificada abajo discrimina ahora IA/manual. `ConfirmSpecies` valida resultado y pertenencia de forma pura. El VM existente es dueño de foto, resultado, selección e identidad; no hay repositorio, segunda copia de JPEG ni Data nueva.

Una nueva identificación invalida desde el inicio; una nueva foto invalida solo al publicarse con éxito. Fallo/cancelación de sustitución conserva A. Cerrar descarta todo. Cada resultado publicado tiene revisión nueva; acciones obsoletas se ignoran. Cambiar especie elimina la confirmación, conserva la selección y exige reconfirmar.

## Consecuencias

### Ampliación manual aprobada — 2026-10-11

La spec manual-species fue aprobada íntegramente en conversación, incluidas las reglas de transición. El contrato ahora tiene `photoID` y `Source`: `.aiProposal(resultID:selection:commonName:scientificName:)` o `.manual(name:)`. Se migró el constructor IA conservando copia exacta/pertenencia; accesores opcionales derivados permiten a sus callers consultar solo los datos que existen. Manual no fabrica resultID, selección ni nombre común/científico.

`ConfirmManualSpecies` elimina solo extremos `.whitespacesAndNewlines`, rechaza vacío y conserva interior/Unicode sin límite ni validación botánica. El VM foto mantiene una sesión nueva por apertura y un error manual local. Cancelar conserva exactamente la identidad, resultado y selección previos; editar manual precarga nombre y no cambia identidad hasta confirmar. Volver a propuestas conservadas exige reconfirmación explícita, sin nueva consulta. Las intenciones del padre quedan excluidas durante edición; tokens de sesión/foto y generaciones existentes descartan acciones y respuestas obsoletas. No hay persistencia ni consentimiento nuevo para una acción puramente local.

La confirmación es humana, no certificación botánica ni alta. El resumen no solicita cuidados ni guarda. La futura generación de cuidados consumirá foto e identidad del mismo borrador comprobando `photoID`; su intención externa mantendrá la barrera de consentimiento. Manual-species aporta ahora su procedencia propia; save-plant será responsable del mapeo y persistencia. Cuidados/alta no se implementan aquí.

### Delta inline autorizado — 2026-10-11

La autorización concreta posterior sustituye el editor modal por opción manual exclusiva
en «Otras posibilidades» y campo inline, sin modificar el contrato Domain. El VM
retiene identidad anterior mientras se selecciona/edita y conserva aparte la selección
IA para cancelación/vuelta. Cambiar de manual a candidata descarta sesión/texto y no
confirma; Cancelar edición restaura estado anterior. El botón común confirma la vía
activa y usa el mismo resumen. Foto/cámara/identificar siguen excluidos durante texto
manual; selección IA ya no está excluida. Los tokens y generaciones se conservan.
La spec original y aceptación histórica no se reescriben ni aceptan esta nueva ronda.
