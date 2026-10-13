# Brief de producto: PlantCare AI

## Delta aprobado: keep-analysis (2026-10-13, ADR014)

Guardar análisis conserva explícitamente el resultado útil junto a la foto local seleccionada, sin duplicarla ni registrar cuidados. Un definitivo por identidad; insuficiencia no guardable y definitivo impide reanálisis. Commit local cierra modal, retry conserva intención sin IA. Texto íntegro orientativo debajo de foto en el mismo hito, disponible al relanzar/sin red/configuración. Delete adicional elimina su análisis en la misma transacción metadata y lo advierte; inicial protegida. Descarta pendiente: cierre sin guardar libera provisional. Contexto futuro usa textos propios anteriores por fecha de foto, nunca JPEG previos/fecha de aceptación. Sucede menciones históricas de guardar una foto nueva con análisis para este flujo sobre fotos ya locales.

## Delta aprobado: analyze-current-photo (2026-10-13, ADR013)

Cualquier foto local seleccionada (inicial/adicional/retroactiva) desde pager/timeline abre mismo modal por identidad exacta. Foto única con especie/ficha/ubicación actuales y solo cuidados de días anteriores al de foto en zona gregoriana fija, máximo20/90días/notas500. Futuro contexto hasta5análisis definitivos TEXTUALES de fotos anteriores por fecha origen, nunca imágenes anteriores/provisionales; hoy no existe lector/persistencia y no se fabrica. JSON16KiB/omisiones explícitas/base excesiva falla local. Aviso v5 destino/modelo/finalidad/contexto, no hereda v4; rechazo/fallo registro ceroHTTP. Un envío por intención, cancelación/retry explícitos. Resultado prudente completo/insuficiencia válida, provisional solo modal; cierre libera sin escribir/borrar. Aceptar/Descartar visibles inactivos hasta sus features, solo definitivo futuro bloquea reanalizar. keep-analysis guardará/renderizará texto bajo foto sin duplicación/aportará lector real. Sin API real de agentes sin autorización específica.

## Problema y usuario

Una persona con plantas en casa puede buscar una identificación o consejos generales, pero esos consejos no tienen memoria de los cuidados y cambios de **su** planta. PlantCare AI es un asistente iOS personal que convierte una identificación orientativa en una ficha con historial, para contextualizar observaciones posteriores. Usuario del MVP: una sola persona no experta que gestiona sus propias plantas en un iPhone; no hay cuentas, colaboración ni especialistas.

## Propuesta de valor y recorrido central

Fotografiar o elegir imagen → obtener propuestas → seleccionar especie propuesta o manual y completar texto → Confirmar especie → generar cuidados autorizados y guardar directamente si son completos → volver a «Mis plantas» actualizada → consultar cuidados en detalle, registrar cuidados/fotos y analizar una nueva foto con contexto de **ese ejemplar** → decidir si se guarda foto junto al análisis. No hay resumen, review, formulario previo ni segunda confirmación de alta. Nombre inicial de especie y ubicación nil; edición posterior disponible. La intención humana Confirmar especie autoriza este recorrido, no la selección sola. La IA nunca confirma automáticamente la especie ni guarda diagnósticos por sí sola. La foto actual es la única imagen enviada para análisis; el historial aporta texto, no comparación visual de fotos antiguas.

## MVP obligatorio

Eliminación de historial implementada por acción confirmada: cuidados y fotografías adicionales propios, nunca foto inicial/portada. Una adicional seleccionada en el carrusel sigue eliminable; Cancelar/× abandonan retry y no hay toast de éxito. Eliminar planta completa sigue siendo una capacidad posterior distinta.

- Colección local y ficha por ejemplar con foto, nombre personalizado, especie confirmada, ubicación opcional, fecha de alta y ficha de cuidados propia. Estados vacíos y edición de nombre/ubicación.
- Identificación desde cámara o galería con candidato, alternativas cuando existan, incertidumbre visible, repetir foto o introducir especie conocida; confirmación humana antes de crear la planta. Cuidados breves sobre luz, riego, humedad, temperatura, sustrato y abonado, más poda/trasplante/problemas comunes si aportan valor.
- Registro de riego en aproximadamente 2–3 interacciones; registro breve de abonado, poda, trasplante y «otro» con fecha y nota opcional; añadir fotos y ver cronología por planta. Eliminación de eventos y de plantas con confirmación; al borrar una planta se elimina también su memoria local.
- Análisis de foto actual con contexto de especie, cuidados, eventos recientes, notas y análisis anteriores guardados cuando sean útiles. Mostrar observaciones, posibles causas y acciones de comprobación sin preguntas de seguimiento ni afirmaciones diagnósticas. Guardar foto y análisis juntos solo por acción explícita; descartar no altera el historial.
- Pregunta contextual de un turno por planta, como última capacidad del MVP: se espera la respuesta o se cancela la solicitud; pregunta y respuesta no se guardan ni hay chat de varios turnos.
- En el detalle, mostrar fecha del último riego y, si procede, una sugerencia de comprobar humedad; nunca indicar automáticamente «debes regar hoy». Sin pantalla de actividad ni notificaciones.
- Fallos de conexión/IA recuperables mediante reintento; colección e historial ya guardados consultables sin conexión. Primer aviso antes de enviar fotos/contexto a la API externa.

## Fuente de conocimiento y límites de IA

Refinamiento autorizado vigente 2026-10-11: en identificación se muestran opciones, sin texto libre del análisis/incertidumbre ni indicadores/avisos de propuesta IA. Se conserva el estado explícito de evidencia insuficiente y la confirmación humana; selección reversible y manual dentro de su tarjeta solo tras éxito con cero o más candidatas, no antes del intento ni ante error (`docs/specs/manual-species-selection.md`). Esta decisión de presentación prevalece sobre las menciones anteriores de incertidumbre visible o manual antes de identificar.

La API externa compatible con OpenAI genera cuidados usando conocimiento del modelo, sin RAG ni fuentes verificadas. Confirmar especie inicia generación textual autorizada y alta directa tras validación de los seis campos (ADR 007); los cuidados se consultan después en detalle. El aviso v4 conserva foto para identificación y nombres/procedencia para cuidados, sin reenviar JPEG ni colección/historial. El usuario confirma especie/alta mediante el botón común, y por separado registros y persistencia de análisis. Manual no salta generación ni certifica botánica. Error remoto conserva foto/identidad y permite retry explícito o cambio de especie; error local conserva snapshot y permite retry sin IA, sin alta parcial.

## Fuera del MVP

Backend propio, login, sincronización, Android/web, multiusuario, compartición, comunidad, ecommerce, sensores, meteorología, geolocalización avanzada, widgets/Watch, gamificación, modelo Core ML propio, diagnóstico científico, RAG, comparación de imágenes anteriores, conversación persistente, recordatorios/notificaciones y diseño de infraestructura a escala comercial. El prototipo académico usa una credencial configurada por quien prepara la demostración fuera del repositorio; no es un esquema seguro para distribución pública.

## Validación y criterio de éxito

Demostrar en un iPhone el recorrido completo con **dos plantas reales**: identificar, confirmar, crear, registrar cuidados y foto, cerrar/reabrir la app para comprobar persistencia, analizar una nueva foto con historiales distintos y decidir guardar o descartar. Completar también una pregunta contextual de un turno; comprobar que usa datos de la planta correcta. Probar una identificación incierta (alternativa, nueva foto o nombre manual), un fallo de conexión recuperable y que los datos locales siguen accesibles. Verificar que un riego se registra en 2–3 interacciones, que un análisis descartado no modifica la cronología y que las respuestas no atribuyen certeza a causas no observables. Son criterios de comportamiento comprobables, no una promesa de precisión botánica.
