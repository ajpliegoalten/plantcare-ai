# Modelo de dominio

## Conceptos y relaciones

- **Planta**: ejemplar local con identificador propio, nombre personalizado, foto principal, especie confirmada (nombre común/científico cuando estén disponibles), ubicación opcional y fecha de alta. Pertenece al único usuario local del dispositivo.
- **Ficha de cuidados**: copia asociada a una planta; guarda consejos breves de la especie generados por IA. No existe catálogo global ni identidad «Species» compartida obligatoria entre plantas.
- **Evento de cuidado**: pertenece a una planta; tipo `riego | abonado | poda | trasplante | otro`, fecha y nota opcional. El riego puede registrarse con valores por defecto para acelerar la interacción.
- **Fotografía**: pertenece a una planta, con imagen local y fecha; puede ser la inicial, una añadida expresamente o la foto vinculada a un análisis guardado.
- **Análisis guardado**: pertenece a una planta y referencia su foto; conserva fecha, observaciones, posibles causas y recomendaciones expresadas con cautela. Solo existe tras confirmación explícita.
- **Pregunta contextual**: operación efímera de un turno; no es entidad persistente ni se incorpora al contexto futuro.

El historial es una vista cronológica de eventos, fotos y análisis, **no** una segunda copia de los datos. Una fotografía de análisis guardado puede mostrarse en el mismo hito del historial para no contarla dos veces.

## Ciclo de vida de una planta

1. **Borrador no persistido**: foto capturada/seleccionada; la IA identifica y propone candidatas con incertidumbre visible. Se puede repetir la foto o elegir/introducir especie conocida.
2. **Identidad confirmada**: el usuario confirma nombre común o científico; la IA genera la ficha orientativa y el usuario la revisa. Sin ficha generada por fallo de IA, no hay alta; se conserva la colección existente y se ofrece reintento.
3. **Planta guardada**: nombre personalizado (sugerencia inicial basada en especie), foto inicial, fecha y ubicación opcional. Historial inicial con foto; desde aquí se pueden registrar cuidados, añadir fotos, analizar y consultar a la IA.
4. **Mantenimiento**: se agregan eventos, fotos y análisis confirmados; se permite corregir nombre/ubicación y eliminar eventos incorrectos. El historial puede carecer todavía de cuidados.
5. **Eliminación**: acción del usuario confirmada; se eliminan ficha, eventos, fotos y análisis locales de esa planta. Sin archivado, acceso compartido ni caducidad de cuenta.

## Ciclo de vida del análisis

Foto actual elegida → solicitud a IA con identidad/ficha y selección pertinente de historial textual reciente, sin fotos previas → resultado provisional con observaciones, posibilidades y comprobaciones prácticas → **guardar** foto y análisis juntos o **descartar** ambos. Si se cancela o falla la petición, no se guarda nada y se puede reintentar. Los análisis guardados pueden aportar contexto a otros futuros; el texto de IA nunca se transforma automáticamente en un evento de cuidado. No hacer preguntas de seguimiento dentro del análisis ni afirmar evolución visual comparativa sin comparar imágenes.

## Reglas y casos límite

- Refinamiento autorizado de identificación (2026-10-11, `docs/specs/manual-species-selection.md`): tap en la opción activa la deselecciona, otra opción sustituye exclusivamente la anterior. Deseleccionar manual descarta texto pendiente y no restaura candidata anterior; libera acciones de foto/consulta. El texto libre de incertidumbre continúa en el contrato de resultado pero no se presenta; tampoco indicadores/avisos de propuesta IA. Manual solo tras identificación exitosa de foto actual con cero o más candidatas, no antes del intento ni ante error/cancelación/configuración indisponible. Ninguna selección/deselección confirma, guarda ni envía datos. Esta decisión prevalece sobre la disponibilidad manual histórica descrita debajo.

- `manual-species` permite confirmar localmente un nombre conocido con foto preparada aunque no haya configuración/resultados IA. Identidad discriminada por procedencia: manual tiene solo su nombre humano, sin nombres común/científico inferidos ni revisión/propuesta falsa. Solo trim de extremos, vacío rechazado, interior y Unicode intactos, sin límite ni comprobación botánica. La opción manual inline en «Otras posibilidades» es exclusiva con selección IA y siempre disponible con foto; seleccionar no confirma. Campo/confirmación comparten selector, sin nueva sheet. No solicita cuidados ni guarda el ejemplar. Cancelar edición explícito conserva identidad/resultado/selección; reabrir solo precarga el nombre manual confirmado. Pasar a candidata descarta texto pendiente sin borrar identidad anterior; Confirmar sustituye la única identidad activa. Volver expresamente a propuestas conservadas desde resumen exige reconfirmar sin consultar. Nueva foto exitosa, reidentificación desde el inicio y cierre invalidan según las reglas del borrador; reemplazo fallido conserva A. Texto humano también es dato no confiable para futuros prompts.

- `confirm-species` implementa solo identidad del borrador en memoria: elección explícita de principal/alternativa y después Confirmar especie, sin preselección ni alta/cuidados/IA adicional. Conserva nombres exactos, procedencia y UUID de foto/revisión, no certeza botánica. Cambiar especie exige reconfirmar. Reidentificar invalida inmediatamente, incluso ante cancelación/error/configuración ausente; nueva foto invalida al prepararse con éxito, fallo/cancelación conserva A. Cada resultado nuevo empieza sin selección; cierre/gesto/relanzamiento descarta foto e identidad. El consentimiento registrado sigue su propio contrato.

- Consentimiento externo por instalación, no por ejemplar: aceptación explícita de destinatario/versión recordada localmente; rechazos no persistidos. Preparar foto no autoriza ni envía. Cancelar aviso abandona solo la intención, conserva foto y no ejecuta operación; cerrar borrador libera foto. Aceptar habilita futuras intenciones explícitas, nunca envíos automáticos. Identificación Debug configura una API OpenAI-compatible con base HTTPS/modelo arbitrarios bien formados, clave opcional. Aviso v3 ligado al destino real/modelo muestra ambos y advierte operador/subprocesadores/retención desconocidos; ni DevExpert v2 ni provisional v1 autorizan el nuevo alcance. Cambiar destino/modelo pide aceptación antes de HTTP. Configurar/sin clave no demuestra soporte de visión ni exención de auth del servicio. Propuestas o evidencia insuficiente son resultados efímeros; errores de servicio/parseo no significan evidencia insuficiente. Cancelar no retira bytes ya enviados.

- Identificación poco fiable: indicar incertidumbre, ofrecer alternativas u otra foto; permitir introducir especie conocida y generar cuidados antes de guardar. Ninguna propuesta se acepta automáticamente.
- Sin red/API: leer y editar información local; no completar identificación, cuidados, análisis o pregunta contextual hasta poder reintentar. No se crean plantas nuevas sin ficha.
- Primer uso de IA: avisar que foto y datos pertinentes de la planta salen hacia un proveedor externo; no enviar todo el almacenamiento por defecto. La foto inicial y las añadidas se conservan localmente; una foto descartada del análisis no entra en memoria.
- Un evento de cuidado representa lo que **registró el usuario**, no una inferencia de IA. Fechas del historial no constituyen una pauta de riego.
- Solo un usuario local: no hay roles, invitaciones, acceso remoto ni revocación entre personas; desinstalación o eliminación de planta suprime la copia local, sin garantía de recuperación o sincronización.
