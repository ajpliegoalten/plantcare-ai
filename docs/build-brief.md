# Brief de producto: PlantCare AI

## Problema y usuario

Una persona con plantas en casa puede buscar una identificación o consejos generales, pero esos consejos no tienen memoria de los cuidados y cambios de **su** planta. PlantCare AI es un asistente iOS personal que convierte una identificación orientativa en una ficha con historial, para contextualizar observaciones posteriores. Usuario del MVP: una sola persona no experta que gestiona sus propias plantas en un iPhone; no hay cuentas, colaboración ni especialistas.

## Propuesta de valor y recorrido central

Fotografiar o elegir imagen → obtener especie candidata, alternativas y confianza expresada en lenguaje comprensible → confirmar una especie (o indicar una conocida) → revisar cuidados orientativos generados por IA → añadir ejemplar a «Mis plantas» → registrar riegos y otros cuidados y añadir fotos → analizar una nueva foto con la especie, ficha e historial de **ese ejemplar** → decidir si se guarda la foto junto al análisis. La foto actual es la única imagen enviada para ese análisis: el historial aporta texto y fechas, no comparación visual de fotos antiguas. La IA no crea plantas ni guarda diagnósticos por sí sola.

## MVP obligatorio

- Colección local y ficha por ejemplar con foto, nombre personalizado, especie confirmada, ubicación opcional, fecha de alta y ficha de cuidados propia. Estados vacíos y edición de nombre/ubicación.
- Identificación desde cámara o galería con candidato, alternativas cuando existan, incertidumbre visible, repetir foto o introducir especie conocida; confirmación humana antes de crear la planta. Cuidados breves sobre luz, riego, humedad, temperatura, sustrato y abonado, más poda/trasplante/problemas comunes si aportan valor.
- Registro de riego en aproximadamente 2–3 interacciones; registro breve de abonado, poda, trasplante y «otro» con fecha y nota opcional; añadir fotos y ver cronología por planta. Eliminación de eventos y de plantas con confirmación; al borrar una planta se elimina también su memoria local.
- Análisis de foto actual con contexto de especie, cuidados, eventos recientes, notas y análisis anteriores guardados cuando sean útiles. Mostrar observaciones, posibles causas y acciones de comprobación sin preguntas de seguimiento ni afirmaciones diagnósticas. Guardar foto y análisis juntos solo por acción explícita; descartar no altera el historial.
- Pregunta contextual de un turno por planta, como última capacidad del MVP: se espera la respuesta o se cancela la solicitud; pregunta y respuesta no se guardan ni hay chat de varios turnos.
- En el detalle, mostrar fecha del último riego y, si procede, una sugerencia de comprobar humedad; nunca indicar automáticamente «debes regar hoy». Sin pantalla de actividad ni notificaciones.
- Fallos de conexión/IA recuperables mediante reintento; colección e historial ya guardados consultables sin conexión. Primer aviso antes de enviar fotos/contexto a la API externa.

## Fuente de conocimiento y límites de IA

La API externa compatible con OpenAI genera cuidados usando conocimiento del modelo. La ficha se guarda localmente al confirmar la especie, como información orientativa, sin RAG ni fuentes verificadas en este MVP. La IA propone identificaciones, cuidados, observaciones y respuestas; el usuario confirma especie, alta, registros y persistencia de análisis. Ante evidencia insuficiente, no se presenta certeza ficticia: ofrecer alternativas u otra foto. El nombre manual de una especie conocida permite solicitar cuidados a la IA, no saltarse la generación de ficha. Si identificación o generación de cuidados falla, reintentar; no dar de alta una planta incompleta mientras la API no responda.

## Fuera del MVP

Backend propio, login, sincronización, Android/web, multiusuario, compartición, comunidad, ecommerce, sensores, meteorología, geolocalización avanzada, widgets/Watch, gamificación, modelo Core ML propio, diagnóstico científico, RAG, comparación de imágenes anteriores, conversación persistente, recordatorios/notificaciones y diseño de infraestructura a escala comercial. El prototipo académico usa una credencial configurada por quien prepara la demostración fuera del repositorio; no es un esquema seguro para distribución pública.

## Validación y criterio de éxito

Demostrar en un iPhone el recorrido completo con **dos plantas reales**: identificar, confirmar, crear, registrar cuidados y foto, cerrar/reabrir la app para comprobar persistencia, analizar una nueva foto con historiales distintos y decidir guardar o descartar. Completar también una pregunta contextual de un turno; comprobar que usa datos de la planta correcta. Probar una identificación incierta (alternativa, nueva foto o nombre manual), un fallo de conexión recuperable y que los datos locales siguen accesibles. Verificar que un riego se registra en 2–3 interacciones, que un análisis descartado no modifica la cronología y que las respuestas no atribuyen certeza a causas no observables. Son criterios de comportamiento comprobables, no una promesa de precisión botánica.
