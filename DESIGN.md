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
- **Identificación**: cámara o galería, foto dominante, espera con foto visible; resultado con candidata, alternativas e incertidumbre legible. Si la evidencia es insuficiente, otra foto o nombre de especie manual.
  - Separar propuestas/confirmación de las acciones de foto y nueva consulta. Tras un resultado, un divisor y bloque secundario «Volver a identificar» agrupan galería, cámara e Identificar; la elección de especie permanece en el bloque de resultado, sin confundirse con volver a consultar la IA.
  - Refinamiento Stitch autorizado: etiqueta discreta «Propuesta de IA», título «Podría ser…» destacado, check a la derecha y distintivo «Seleccionada» solo tras elección explícita. Explicación/incertidumbre agrupadas antes de confirmar; separador «O bien»; icono de nueva consulta en el bloque secundario y aviso de privacidad separado de sus botones. Confirmar/galería/cámara/Identificar usan cápsulas nativas; los tres botones de foto/consulta mantienen igual tamaño. Sin flechas de navegación en alternativas, nombres inventados, nueva fuente ni gris de deshabilitado cuando Identificar está disponible.
- **Ficha de cuidados y alta**: consejos breves y escaneables; formulario mínimo de nombre, ubicación opcional y foto existente antes de añadir.
  - **Especie conocida (delta inline autorizado, 2026-10-11)**: sustituye la sheet histórica por una opción humana en «Otras posibilidades», con el mismo borde/check/badge y selección exclusiva que las candidatas IA. Siempre disponible con foto preparada, sin necesidad de identificación. Seleccionarla muestra campo vertical nativo inline como EditPlant (sin modificar ese editor), etiqueta Especie y mínimo 44 pt; nombre común o científico, sin autocompletado/comprobación botánica/contador/límite. Autocorrección y autocapitalización desactivadas; teclado real y Listo solo quita foco. Único Confirmar especie compartido, habilitado para manual solo con texto válido; lleva al resumen actual sin cuidados/alta. Cancelar edición explícito conserva identidad y selección anteriores; Cambiar especie precarga inline. Elegir candidata abandona texto no confirmado, sin confirmar ni borrar identidad anterior; Elegir propuesta de IA desde resumen sigue exigiendo reconfirmar. Procedencia manual explícita, nunca candidata generada por IA. Spec histórica intacta; delta en docs/specs/manual-species-inline.md.
- **Detalle de planta**: foto, identidad, cuidados y cronología resumida. Riego de acceso inmediato; otras acciones reconocibles sin una interfaz recargada. Historial completo como extensión natural del detalle.
- **Análisis**: foto actual, espera no conversacional, resultado estructurado en observaciones, posibles causas y pasos prudentes; guardar o descartar con efectos evidentes sobre la memoria.
- **Pregunta contextual**: acceso desde la planta; una pregunta y una respuesta, espera hasta finalización o cancelación, sin aparentar chat genérico ni conversación persistente.

No crear pantalla independiente de actividad en el MVP. El detalle puede mostrar tiempo desde último riego y sugerir revisar sustrato, no imponer fechas de riego.

## Componentes, estados y accesibilidad

El soporte de accesibilidad y diseño adaptable descrito aquí se conserva. Su verificación habitual sigue `AGENTS.md`: un único iPhone Simulator estándar, texto normal, una apariencia e inspección visual básica. Pruebas específicas de pantallas pequeñas/iPhone SE, Dynamic Type aumentado/máximo, VoiceOver/Accessibility Inspector y matrices adicionales de apariencia solo se ejecutan por petición expresa del usuario; fuera de esa petición no se declaran superadas ni se exigen para aceptar una feature.

Botones primarios claramente distinguibles, tarjetas suaves, fotografías con recorte predecible y cronología legible. Estados vacío, sin historial, analizando, baja confianza, error recuperable y sin conexión deben explicar la siguiente acción. Evitar que el color sea la única señal de confianza o estado; dar texto claro, contraste comprobado (también para texto sobre verde), soporte para Dynamic Type y VoiceOver, objetivos táctiles de al menos 44 × 44 pt y permisos de cámara/galería comprensibles. Las microetiquetas de 11 px y los botones de 36 px del HTML no son objetivos de accesibilidad. Confirmar eliminaciones y avisar del envío externo de datos antes del primer uso de IA.

Evitar degradados llamativos, estética futurista de IA, exceso de verde, aspecto infantil, dashboards empresariales, densidad excesiva o apariencia de web adaptada. No usar porcentajes de confianza sin base calibrada ni estética de diagnóstico médico.
