# ADR016 — Consultas textuales independientes

Fecha: 2026-10-14. Decisión aprobada mediante spec one-turn-question byte-inmutable
`e2d724163e0875effed312dc55f9a6823c908b2453c3a2ce31e6f0a5e137f75a` y autorización posterior registrada en PROGRESS.

## Contexto y decisión

El análisis fotográfico corta historia antes del día de una foto y requiere JPEG; una pregunta contextual
necesita contexto actual sin imagen. Nuevo módulo Clean/MVVM read-only, readers reales obligatorios y contrato
remoto exacto `{"answer":"…"}`. Campo reutilizable, una respuesta sustituible identificada con su pregunta
origen; ningún turno previo en payload/persistencia. Contexto propio actual y límites establecidos en la spec.

Cada intención relee, revalida Plant y cruza autorización existente para destino/modelo canónicos vigentes;
no v6/notice-6 ni renovaciones por esta capacidad. Sin aceptación, notice vigente con explicación textual
opt-in de operación. Ningún copy/payload previo cambia. Lease por plantID/requestID y generaciones evitan
dobles/tardíos; cierre no revoca aceptación ni envío remoto ya iniciado.

## Consecuencias y migración

No schema/writer/cache/restauración de consultas. Compartir tipos de contexto textuales Domain no reutiliza
cutoff/análisis visual. Historia secuencial no atómica y respuesta no certificada por fixtures. Validación
independiente y cualquier prueba remota autorizada son evidencias separadas de la implementación offline.
