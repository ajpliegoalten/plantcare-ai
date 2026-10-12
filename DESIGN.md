---
name: PlantCare AI
description: iPhone nativo, cálido, fotográfico y sereno; la IA es una capacidad integrada.
designAssets:
  reference: "Pantalla HTML «Mis plantas» de Stitch compartida en la conversación; referencia visual, no código ni especificación funcional"
  authority: "Dirección escrita aquí y brief del MVP; propuesta de Stitch para composición de «Mis plantas»"
colors:
  background: "#F8FAF2"
  surface: "#FFFFFF"
  surfaceMuted: "#F2F4ED"
  primary: "#264D3C"
  primaryAction: "#3E6553"
  text: "#191C18"
  secondaryText: "#414844"
  outline: "#C1C8C2"
typography:
  family: "tipografía de sistema de iOS"
  collectionTitle: "aprox. 32 pt, negrita; adaptable a Dynamic Type"
  cardTitle: "aprox. 22 pt, seminegrita; adaptable a Dynamic Type"
  body: "aprox. 15–17 pt; metadatos sin tamaños fijos diminutos"
shapes:
  cards: "radio visual aprox. 22 pt"
  imagery: "fotografía a ancho completo en tarjeta, relación 4:3 aproximada"
spacing:
  outerMargin: "aprox. 20 pt en iPhone"
  cardInnerPadding: "aprox. 16 pt"
  betweenCards: "aprox. 24 pt"
---

# Dirección visual

## Fuentes y autoridad

El HTML de «Mis plantas» y su bloque «Brand & Style» de Stitch fueron compartidos en la conversación y el usuario aceptó **la pantalla HTML como referencia visual principal de esa pantalla**. No hay archivo ni captura incorporados al repositorio: este documento conserva las decisiones extraídas para futuros agentes. El texto «Brand & Style» sirve solo de inspiración donde no contradiga la pantalla, el brief o el enfoque iOS nativo. No copiar Tailwind, Material Symbols, enlaces de imágenes, logo generado ni componentes web; fotografías y logotipo del prototipo no tienen aquí una fuente de recursos aprobada. No convertir otras pantallas de Stitch en referencia sin revisarlas.

## Sensación y principios

Aplicación SwiftUI para iPhone, minimalista, elegante, natural, cálida, visual y fácil de entender sin instrucciones. Inspiración en salud, fotografía, journaling y hábitos iOS. Mucho espacio en blanco; fotografía real de cada planta como protagonista; verdes apagados en acentos, base crema clara y tarjetas blancas. Aplicar los tokens anteriores como **punto de partida**, no como impedimento para contraste o accesibilidad. Tipografía de sistema iOS con jerarquía equivalente a la muestra de Stitch: la familia Plus Jakarta Sans del HTML es una referencia de tono, no una dependencia obligatoria. SF Symbols en lugar de Material Symbols; navegación y barras nativas en lugar de imitar barras web o dibujar una barra de estado.

## «Mis plantas»: referencia aceptada

Composición de **una columna vertical** y desplazable: título grande «Mis plantas», acción «Añadir» visible junto al encabezado y tarjetas fotográficas amplias separadas por espacio generoso. Cada tarjeta muestra foto 4:3, nombre personalizado predominante, especie secundaria y último cuidado en una línea breve; ubicación opcional si cabe sin saturar. La foto y la tarjeta llevan al detalle; una acción de riego discreta puede facilitar el registro en 2–3 interacciones, con etiqueta accesible «Registrar riego» y confirmación real del resultado, no solo un toast decorativo. Sin riego previo, no inventar una fecha. La foto principal puede llevar una insignia discreta de luz **solo si la ficha guarda ese dato**; no se deduce de la foto ni se considera consejo urgente.

La cabecera con «Mis plantas» y «Añadir» permanece fija fuera del contenido desplazable, tanto con plantas como sin ellas. El estado vacío se centra horizontal y verticalmente en el espacio disponible bajo la cabecera, respetando las áreas seguras; si su contenido supera ese espacio, sigue siendo desplazable sin mover la cabecera.

Fondo `#F8FAF2`, tarjetas blancas, superficies secundarias `#F2F4ED`, texto `#191C18`/`#414844` y verde de acción `#3E6553` con verde oscuro `#264D3C`. Márgenes visuales de unos 20 pt, interior de tarjeta de unos 16 pt, separación entre tarjetas de unos 24 pt y radio aproximado de 22 pt. Elevación muy suave o separación tonal, sin sombras pesadas; fotografía sin degradado decorativo salvo que la legibilidad de un elemento superpuesto lo requiera. Estos valores se adaptan a tamaños de pantalla, Dynamic Type y convenciones de iOS; no son medidas web obligatorias.

La muestra de Stitch incluye elementos **no aceptados**: avatar de perfil sin cuentas, cabecera duplicada, píldora «en perfecto reposo», etiqueta de estación, cita poética, iconos Material, pestaña «Actividad» y toast que simula guardar un riego. Su bloque «Brand & Style» propone además otros colores de fondo (`#FBFBF9`), dos columnas en móvil, calendarios/anillos de riego, alertas de deshidratación, controles de humedad y vistas para tablet/escritorio. En esas discrepancias prevalecen la composición de una columna y paleta de la pantalla HTML y el alcance del brief. No afirmar el estado de salud ni que un riego está atrasado solo por la fecha.

## Pantallas y prioridades

- **Mis plantas**: seguir la composición aceptada arriba; si no hay plantas, estado vacío amable con acción clara de alta. No añadir pestaña «Actividad»; navegación de colección e identificación acorde a patrones nativos.
- **Identificación**: cámara o galería, foto dominante, espera con foto visible; resultado con candidata y alternativas, sin texto libre de análisis/incertidumbre. Tras resultado exitoso, con cero o más candidatas, permitir nombre manual; antes del intento o ante error no mostrarlo.
  - Separar propuestas/confirmación de las acciones de foto y nueva consulta. Tras un resultado, un divisor y bloque secundario «Volver a identificar» agrupan galería, cámara e Identificar; la elección de especie permanece en el bloque de resultado, sin confundirse con volver a consultar la IA.
  - Refinamiento autorizado vigente: título «Podría ser…» destacado, check a la derecha y distintivo «Seleccionada» solo tras elección explícita. No mostrar texto libre de análisis/incertidumbre, badge «Propuesta de IA» ni aviso fijo de propuesta no confirmada. Separador «O bien»; icono de nueva consulta en el bloque secundario y aviso de privacidad separado de sus botones. Confirmar/galería/cámara/Identificar usan cápsulas nativas; los tres botones de foto/consulta mantienen igual tamaño. Selección no equivale a confirmación; sin flechas de navegación en alternativas, nombres inventados, nueva fuente ni gris de deshabilitado cuando Identificar está disponible.
- **Cuidados y alta directa** (ADR 007): Confirmar especie (IA o manual) inicia cuidados autorizados y guarda si los seis textos son válidos. Ayuda junto al botón: «Al confirmar, generaremos los cuidados y añadiremos tu planta si la ficha está completa». Foto visible, espera «Generando cuidados…»/«Guardando planta…», errores y retries diferenciados, sin resumen, review, formulario o segundo CTA. Error local ofrece «No pudimos guardar tu planta»/«Reintentar guardado» sin IA. Cierre/cambios bloqueados solo durante commit; antes se permite cancelar. Éxito vuelve a Mis plantas actualizada y desplazada a la nueva tarjeta, sin abrir detalle. Nombre de especie y ubicación vacía; personalización posterior. Los seis cuidados y aviso orientativo se consultan en detalle; no aparecen antes del alta. Edición ante fallo conserva snapshot oculto y Cancelar edición lo restaura sin envío/escritura.
   - **Especie conocida (delta inline autorizado, 2026-10-11)**: opción humana en «Otras posibilidades», con mismo borde/check/badge y selección exclusiva que candidatas IA. Disponible solo tras identificación exitosa actual con cero o más candidatas; nunca antes de identificar ni ante error. Campo vertical nativo inline, etiqueta Especie y mínimo 44 pt; nombre humano, sin comprobación botánica ni límite de edición. Autocorrección/autocapitalización desactivadas; Listo solo quita foco. Único Confirmar especie compartido: texto válido confirma e inicia cuidados directamente. El límite defensivo de envío 2000 produce error local sin truncar. Cancelar edición conserva identidad/selección/ficha; Cambiar especie precarga inline. Elegir candidata abandona texto pendiente sin confirmar ni borrar identidad anterior; volver a propuestas desde revisión requiere reconfirmar. Procedencia manual explícita. Specs históricas intactas; deltas vigentes manual-species-selection y generate-care-sheet.
  - Refinamiento de selección autorizado (2026-10-11): campo manual dentro del borde/fondo de «Aportado por ti», debajo de «Seleccionada», con input independiente del botón (sin anidar controles interactivos). Tap en cualquier opción activa la deselecciona; tap en otra cambia exclusivamente de selección. Deseleccionar manual borra borrador pendiente y libera botones de foto/consulta, sin restaurar otra selección. Elegir IA borra texto manual pendiente. Editar identidad confirmada conserva la precarga y Cancelar edición no destructivo. Ver `docs/specs/manual-species-selection.md`; aprobación visual explícita del usuario recibida, autoverificación focalizada y aceptación independiente documentadas por separado en PROGRESS.md.
  - Feedback visual vigente: sin avisos/indicadores de propuesta IA. Títulos de opciones IA/manual en headline; categoría/procedencia callout; mismo padding, borde, check y badge de selección.
- **Detalle de planta**: foto, identidad, cuidados y cronología resumida. Riego de acceso inmediato; otras acciones reconocibles sin una interfaz recargada. Historial completo como extensión natural del detalle.
- **Análisis**: foto actual, espera no conversacional, resultado estructurado en observaciones, posibles causas y pasos prudentes; guardar o descartar con efectos evidentes sobre la memoria.
- **Pregunta contextual**: acceso desde la planta; una pregunta y una respuesta, espera hasta finalización o cancelación, sin aparentar chat genérico ni conversación persistente.

No crear pantalla independiente de actividad en el MVP. El detalle puede mostrar tiempo desde último riego y sugerir revisar sustrato, no imponer fechas de riego.

## Componentes, estados y accesibilidad

### Fotos locales: delta autorizado (2026-10-12, ADR011)

Detalle loaded añade «Añadir foto» bajo identidad, separado de Registrar cuidado. Paginador superior conserva foto4:3/radio22: fecha visible («Foto inicial · fecha de alta» o día humano), swipe horizontal y ‹ › de44pt, sin wrap; una sola foto oculta controles. Nueva foto seleccionada después de commit incluso retroactiva; reentrada inicia en inicial, portadas de Mis plantas intactas. Metadata incompleta/error y bytes loading/error/retry son estados independientes; fecha y demás acciones siguen disponibles, sin contador parcial presentado como total.

Modal nativo «Añadir foto», Cancelar/grabber/scroll, cabecera PlantFormHeader con portada snapshot56/nombre multilínea/descripción de pertenencia como Editar/Registrar cuidado. Placeholder compartido con Identificar: hoja y texto centrados sobre blanco,4:3/radio22. Fecha compacta editable y cápsulas verticales del mismo tamaño: galería verde prominente, cámara bordered y «Guardar foto» inferior sobre superficie inset compartida. Sin identificación/propuestas/manual/IA/nota. Reemplazo fallido o cancelado conserva preview/fecha; error local ofrece retry explícito; validación/commit bloquean cambios y commit impide cerrar. «Foto guardada» complementa la imagen realmente seleccionada, no sustituye persistencia. Error/retry de cada imagen y botones paginadores conservan objetivos ≥44pt y etiquetas españolas/fallback. La cache no monta originales de todas las páginas.

Refinamiento posterior autorizado: orden **createdAt ascendente** (incorporación antigua→reciente), no fecha humana elegida. TabView con estilo page muestra desplazamiento horizontal interactivo real, botones ‹ › animados sobre la misma selección; sin wrap. Guardado vuelve a nueva identidad seleccionada y una sheet no resetea el detalle. Reentrada real inicia inicial. Añadir foto usa verde activo, no gris neutro. Spec original/evidencias históricas no se reescriben; delta en docs/specs/add-plant-photo-refinement.md.

### Último riego: delta autorizado (2026-10-12)

Mis plantas muestra debajo de especie y antes de ubicación una gota decorativa y caption medium: «Último riego: hoy» o fecha breve española sin punto («8 oct 2026»); loaded(nil) muestra «Sin riegos registrados» en tono secundario. No acción rápida nueva ni consejo en tarjetas. En el box Cuidados del detalle, encima de Registrar cuidado, fila SurfaceMuted/radio12 y círculo CareMint con gota; etiqueta «Último riego» y fecha («Hoy, 12 oct 2026» solo si es hoy real). Ausencia real lleva gota outline y etiqueta/valor en dos líneas.

Idle/loading/failed no montan resumen, icono, ID, accessibilityValue residual ni separación propia: no spinner/placeholder/error/retry. Box, CTA, confirmación real y recordatorio de comprobar humedad permanecen en detalle. Iconos decorativos ocultos y texto adaptable completo; calendario gregoriano/zona actual, nunca urgencia, días transcurridos ni hechos inferidos de la fecha. Solo commit watering invalida/relee; abrir/cancelar/fallar/registrar otro cuidado no cambia el resumen. Foto4:3, navegación, cabecera y ficha preservadas. Esta implementación sustituye la expectativa anterior sin última-fecha, sin reescribir evidencias históricas.

### Detalle: rediseño autorizado (2026-10-11)

El HTML «Plant Detail» aportado por el usuario es referencia de composición de esta pantalla, adaptada a SwiftUI y a los datos reales. Foto propia 4:3 con esquinas suaves; tarjeta blanca con nombre predominante, especie secundaria en cursiva, icono SF Symbols de planta en círculo y fecha persistida en franja crema con calendario. Mantener ubicación opcional y Editar nativo funcional. No añadir colección «Interior», avatar/cuentas, menú sin acciones, estado de salud ni ampliación de foto no implementada.

Ficha con encabezado e icono sparkles, aviso de orientación IA y seis tarjetas blancas en dos columnas: Luz/Riego, Humedad/Temperatura, Sustrato/Abonado. Título e icono circular arriba; texto guardado íntegro debajo, sin truncar ni generar resúmenes nuevos. Columnas iguales, altura compartida por fila, radios 16 pt y separación 8 pt. Mantener soporte adaptable, una columna en tamaños de accesibilidad, sin ejecutar matrices ampliadas salvo petición. Acentos del HTML: menta `#C1ECD5`, miel `#FFDDB7`, melocotón `#FFDBCF`, ocre `#633D00` y terracota `#904C33`, centralizados en Assets. Tipografía de sistema y sombras muy suaves; aviso final centrado, sin consejo diario inventado.

Entre identidad y ficha: Registrar cuidado funcional (delta other-care-events sobre quick-watering), sin Próximamente ni última-fecha inventada. Tres taps para riego desde detalle loaded: abrir sheet → elegir Riego → Guardar cuidado; confirmar «Cuidado registrado» solo después del commit real. El consejo estático de comprobar sustrato no deriva del tipo ni añade humedad observada, ciclo o recomendación «regar hoy». Sin Deshacer ni barra inferior fija.

RegisterCare/EditPlant comparten sheet blanca, grabber nativo, toolbar Cancelar/título, radio superior24, scroll/margen20/spacing16 y cabecera SurfaceMuted/radio12 o placeholder. Cuidado usa foto snapshot56; editor conserva48. Nombre persistido de apertura multilínea; cuidado explica pertenencia al ejemplar, editor muestra especie literal. Grupo inset16/inputs blancos12. Registrar cuidado abre sin tipo: grid de dos columnas iguales Riego–Abonado/Poda–Trasplante/Otro a izquierda, SF Symbols nativos, borde/check/fondo menta y trait selected exclusivos; tap activo deselecciona sin borrar fecha/nota. CTA cápsula52 «Guardar cuidado» neutra/deshabilitada sin tipo, verde tras selección. DatePicker compacto solo fecha, Ayer/Hoy min44/check (Hoy activo al abrir), TextEditor nativo opcional vacío/min90/desplazable sin límite, error local/retry y spinner; sin footer de procedencia. Editor conserva solo nombre/ubicación y mismo comando Guardar inferior. Done solo quita teclado; scroll mantiene errores/CTA/textos largos alcanzables. UI convierte fecha a zona actual sin cambiar payload; ningún selector de hora/zona. Este delta sustituye los dos taps y el formulario de riego históricos; specs y evidencias anteriores no se reescriben.

El soporte de accesibilidad y diseño adaptable descrito aquí se conserva. Su verificación habitual sigue `AGENTS.md`: un único iPhone Simulator estándar, texto normal, una apariencia e inspección visual básica. Pruebas específicas de pantallas pequeñas/iPhone SE, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia solo se ejecutan por petición expresa del usuario; fuera de esa petición no se declaran superadas ni se exigen para aceptar una feature.

Botones primarios claramente distinguibles, tarjetas suaves, fotografías con recorte predecible y cronología legible. Estados vacío, sin historial, analizando, baja confianza, error recuperable y sin conexión deben explicar la siguiente acción. Evitar que el color sea la única señal de confianza o estado; dar texto claro, contraste comprobado (también para texto sobre verde), soporte para Dynamic Type y VoiceOver, objetivos táctiles de al menos 44 × 44 pt y permisos de cámara/galería comprensibles. Las microetiquetas de 11 px y los botones de 36 px del HTML no son objetivos de accesibilidad. Confirmar eliminaciones y avisar del envío externo de datos antes del primer uso de IA.

Evitar degradados llamativos, estética futurista de IA, exceso de verde, aspecto infantil, dashboards empresariales, densidad excesiva o apariencia de web adaptada. No usar porcentajes de confianza sin base calibrada ni estética de diagnóstico médico.
