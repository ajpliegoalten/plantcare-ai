# Riesgos y preguntas abiertas

## Bloqueantes para la siguiente fase

Ninguno identificado para definir las funcionalidades y comenzar una fase posterior, tras aprobar este brief. La credencial y el acceso efectivo a una API con visión sí serán necesarios antes de verificar las funciones de IA en un dispositivo.

## Decisiones durante implementación

- Modelo/API compatible con OpenAI con soporte real de imágenes, formato de salida y límites de coste; mecanismo concreto de configuración local de credencial fuera del repositorio. No incluir la credencial en código fuente ni publicar el prototipo con ella expuesta.
- Persistencia fijada en `local-plant-storage`: SwiftData para metadatos/ficha por ejemplar y archivos JPEG independientes (ADR 001). Sigue pendiente el pipeline de fotos reales: orientación, reescalado, dimensiones/bytes máximos, compresión y memoria antes de `save-plant`; reutilizar en `add-plant-photo`. Los fixtures pequeños no resuelven ese riesgo. También quedan abiertos los límites prácticos del contexto reciente para latencia, coste y privacidad. La versión mínima sigue iOS 17.0 (Xcode 26.2).
- Representación legible de confianza cuando el proveedor no entregue probabilidades calibradas: evitar porcentajes inventados. Diseño de reintentos/cancelación y comprobaciones automáticas de persistencia y errores.
- Stitch: la pantalla HTML «Mis plantas» compartida en la conversación ya se ha traducido a `DESIGN.md` como referencia visual aceptada, no como código fuente; si se dispone después de capturas/archivo, incorporarlos para preservar la referencia original. Inspeccionar contraste y legibilidad con texto normal en el simulador estándar; mantener soporte Dynamic Type, pero comprobar tamaños aumentados solo por petición expresa del usuario según `AGENTS.md`.

## Posterior / fuera del MVP

Fuentes botánicas verificadas y recuperación/RAG; comparación visual de imágenes históricas; alertas y notificaciones; chat persistente; backend para custodiar credenciales, cuentas/sincronización y distribución pública.

## Riesgos y mitigación mínima

- **Alucinación o exceso de confianza**: exigir confirmación humana de especie y persistencia, cuidados etiquetados como orientación y análisis con causas posibles y comprobaciones; probar casos inciertos.
- **Privacidad y credencial de demo**: aviso previo al envío externo; enviar solo foto actual y contexto pertinente; clave fuera del repositorio. Sin backend no hay seguridad apropiada para distribución comercial.
- **Latencia, coste y dependencia de la API**: respuestas con espera/cancelación o reintento; lectura local disponible sin red; limitar contexto y llamadas innecesarias.
- **Pérdida de datos locales**: sin cuenta ni sincronización no hay recuperación garantizada tras borrar app/dispositivo; presentar el carácter local del prototipo con claridad.
- **Demostración engañosa de evolución**: la IA no compara fotografías previas; puede razonar sobre eventos/fechas y foto actual, pero no asegurar cambios visuales entre fotos.

## Operación y comprobación

Quien prepara la demo configura la API y prueba conexión/permisos antes de presentarla. Para diagnosticar fallos, distinguir localmente error de red/API y error de persistencia sin registrar imágenes, claves ni contenido sensible en logs; mostrar al usuario un error recuperable. La validación funcional y los escenarios de fallo están fijados en `docs/build-brief.md`.
