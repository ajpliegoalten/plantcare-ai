# Riesgos y preguntas abiertas

## Bloqueantes para la siguiente fase

Ninguno identificado para definir las funcionalidades y comenzar una fase posterior, tras aprobar este brief. La credencial y el acceso efectivo a una API con visión sí serán necesarios antes de verificar las funciones de IA en un dispositivo.

## Decisiones durante implementación

- Adaptador único OpenAI-compatible Chat Completions con imagen/JSON pedido en prompt; URL HTTPS/modelo arbitrarios y API_KEY opcional, por autorización posterior (ADR 004). Config split obligatoria Debug→Info.plist, real ignorado. Visión/contrato/JSON/presupuesto/límites y exigencia de auth de cada destino/modelo requieren prueba real autorizada, no se deducen de compatibilidad anunciada. No incluir credencial en fuentes ni distribuirla.
- Persistencia fijada en `local-plant-storage`: SwiftData para metadatos/ficha por ejemplar y archivos JPEG independientes (ADR 001). Sigue pendiente el pipeline de fotos reales: orientación, reescalado, dimensiones/bytes máximos, compresión y memoria antes de `save-plant`; reutilizar en `add-plant-photo`. Los fixtures pequeños no resuelven ese riesgo. También quedan abiertos los límites prácticos del contexto reciente para latencia, coste y privacidad. La versión mínima sigue iOS 17.0 (Xcode 26.2).
- Representación legible de confianza cuando el proveedor no entregue probabilidades calibradas: evitar porcentajes inventados. Diseño de reintentos/cancelación y comprobaciones automáticas de persistencia y errores.
- Stitch: la pantalla HTML «Mis plantas» compartida en la conversación ya se ha traducido a `DESIGN.md` como referencia visual aceptada, no como código fuente; si se dispone después de capturas/archivo, incorporarlos para preservar la referencia original. Inspeccionar contraste y legibilidad con texto normal en el simulador estándar; mantener soporte Dynamic Type, pero comprobar tamaños aumentados solo por petición expresa del usuario según `AGENTS.md`.

## Posterior / fuera del MVP

Fuentes botánicas verificadas y recuperación/RAG; comparación visual de imágenes históricas; alertas y notificaciones; chat persistente; backend para custodiar credenciales, cuentas/sincronización y distribución pública.

## Riesgos y mitigación mínima

- **identify-candidates**: spec original intacta; adaptación genérica autorizada después, sin whitelist/vendor mappings. Aviso v3 muestra destino real/modelo y advierte identidad/retención/procesadores desconocidos. El real xcconfig existe, no se ha leído ni verificado su clave; no hay autorización/escenario real nuevo. Prueba sigue blocked por recursos/autorización/validación real pendientes; URLProtocol/fixtures no equivalen a API. Clave ausente omite header y puede recibir 401/403, no retry automático con/sin auth. Límites locales defensivos, no acreditados del servicio; base64/JSON varias copias. Sin garantías remotas de visión/coste/retención. Release excluye secretos/seams, Debug extraíble y privado. Print temporal de respuesta cruda retirado; logs previos no inspeccionados pueden ser sensibles.

- **Consentimiento externo** (ADR 003/004): alcance genérico v3 ligado a destino canónico/modelo/revisión de aviso; no hereda DevExpert v2/provisional v1. Aviso/HTTP mismo snapshot, sin empresa/retención atribuida. Cambios remotos ocultos de mapping/subprocesador no se detectan automáticamente; aviso no promete conocerlos. UserDefaults no garantiza durabilidad abrupta; perder registro vuelve a pedir confirmación. Tests/URLProtocol prueban barrera/control, no visión/retención/cumplimiento legal. Futuros callers deben usar y verificar boundary del destino/modelo real.

- **Importación efímera** (`choose-identification-photo`): ImageIO normaliza orientación, alfa y metadata para preview con entrada ≤30 MiB/80 MP y JPEG ≤2048 px/5 MiB, sin guardar. PhotosPicker puede materializar los bytes antes del límite y cámara entrega UIImage completa; no es una garantía de memoria constante. El pipeline definitivo de alta sigue pendiente de `save-plant`. Cámara física, permisos en dispositivo y descargas iCloud requieren evidencia separada del simulador; no confundir dobles con captura real.

- **Alucinación o exceso de confianza**: exigir confirmación humana de especie y persistencia, cuidados etiquetados como orientación y análisis con causas posibles y comprobaciones; probar casos inciertos.
- **Privacidad y credencial de demo**: aviso previo al envío externo; enviar solo foto actual y contexto pertinente; clave fuera del repositorio. Sin backend no hay seguridad apropiada para distribución comercial.
- **Latencia, coste y dependencia de la API**: respuestas con espera/cancelación o reintento; lectura local disponible sin red; limitar contexto y llamadas innecesarias.
- **Pérdida de datos locales**: sin cuenta ni sincronización no hay recuperación garantizada tras borrar app/dispositivo; presentar el carácter local del prototipo con claridad.
- **Demostración engañosa de evolución**: la IA no compara fotografías previas; puede razonar sobre eventos/fechas y foto actual, pero no asegurar cambios visuales entre fotos.

## Operación y comprobación

Quien prepara la demo configura la API y prueba conexión/permisos antes de presentarla. Para diagnosticar fallos, distinguir localmente error de red/API y error de persistencia sin registrar imágenes, claves ni contenido sensible en logs; mostrar al usuario un error recuperable. La validación funcional y los escenarios de fallo están fijados en `docs/build-brief.md`.
