# ADR010 — Proyección compartida de último riego

Fecha: 2026-10-12. Estado: implementado tras aprobación integral de last-watering-hint; aceptación independiente pendiente.

## Contexto

Mis plantas y detalle necesitan la misma fecha veraz por ejemplar sin duplicar eventos, interpretar frecuencia ni mezclar ausencia y errores. CareEvents ya guarda cinco tipos en V2.

## Decisión

LoadLastWatering (Domain/Foundation) filtra UUID+watering y toma máximo occurredAt sobre CareEventRepository. Reutilizar LocalPlantRepository y componer el actor existente desde App. Presentation mantiene estado/cancelación/generaciones independiente por consumidor y no renderiza resumen salvo loaded(Date?). Callback confirmado watering invalida/relee solo detalle y card retenida del UUID; no recarga metadata/fotos. Otros kinds no invalidan. Recuperación normal al reaparecer/foreground, sin retry UI/loop; tiempo/zona/frontera gregoriana de día solo reformatean. Consejo estático solo detalle.

## Consecuencias

Sin migración/backfill/schema/campo nuevo ni writes al leer. Se conserva fecha absoluta incluso tras retroceso del reloj. El fetch Data actual obtiene eventos completos y filtra por planta, y tarjetas visibles hacen consultas separadas: coste aceptado del prototipo, batch/escala no prometidos. Persistencia no se vuelve infalible; error interno oculta la proyección sin retirar confirmación de un commit real. Historial visible/eliminación/alertas fuera de alcance.
