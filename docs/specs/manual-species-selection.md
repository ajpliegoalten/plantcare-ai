# manual-species — refinamiento de selección autorizado (2026-10-11)

Delta solicitada por el usuario sobre `ab008dd`. Specs y aceptaciones anteriores
se conservan como historia, no aceptan estos cambios nuevos.

- El editor está dentro del borde/fondo de «Aportado por ti», debajo del badge
  «Seleccionada». Campo nativo vertical coherente con EditPlant; controles del
  editor independientes del botón de selección (sin botones anidados).
- Tap en opción no seleccionada selecciona y desmarca la anterior. Tap en la
  seleccionada la deselecciona: ninguna opción activa y confirmación deshabilitada.
- Deseleccionar manual descarta texto pendiente y libera cámara/galería/Identificar.
  Elegir IA también descarta el texto manual. Reabrir un borrador no confirmado
  está vacío. Editar identidad ya confirmada sigue precargando esa identidad;
  cancelación explícita conserva identidad/selección anteriores.
- Ocultar el texto libre `uncertainty` y los indicadores/avisos de propuesta IA.
  Conservar candidatas, estado insuficiente/error y acciones seguras. Seleccionar
  sigue siendo distinto de confirmar. Contrato Domain/API sin cambios.
- Última decisión del usuario: manual solo disponible tras identificación exitosa
  de la foto actual, con cero o más candidatas (insufficientEvidence también es éxito).
  Antes de identificar, durante espera/consentimiento, ante cancelación/configuración
  indisponible/error o respuesta inválida no aparece ni permite abrir editor por VM.
  Foto nueva o reidentificación invalidan resultado y vuelven a ocultarla hasta éxito.
- Presentación/VM solamente; no persistencia, cuidados, nuevos envíos ni alta.
- Refinamiento tras prueba manual: títulos de todas las opciones con `.headline`,
  procedencia/categoría `.callout`, mismo padding/borde/check/badge; manual mantiene
  campo dentro de su tarjeta. Nombre común sin científico usa también título headline.

Verificación por impacto: transiciones de selección, borrado, sesión antigua,
identidad/cancelación y disponibilidad tras éxito con/sin candidatas; actualizar UI tests para el contrato
visible nuevo sin eliminar escenarios. No ejecutar XCUITest ni gate completo antes
de aprobación visual manual explícita del usuario. Hasta entonces estado in_progress;
después focalizadas pertinentes y validator independiente según AGENTS.md.
