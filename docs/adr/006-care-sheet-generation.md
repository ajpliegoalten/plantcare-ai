# ADR 006 — Confirmación y cuidados efímeros textuales

Fecha: 2026-10-11. Decisión aprobada por usuario en `docs/specs/generate-care-sheet.md` (spec íntegra).

## Contexto y decisión

Las dos entradas existentes (propuesta IA y nombre humano) confirman mediante casos puros Domain. El botón común ahora inicia inmediatamente una intención de cuidados en el mismo VM/borrador, sin `ConfirmedSpeciesView` ni otro botón Generar. La ficha reutiliza `CareSheet`, exige seis campos completos y no se persiste: el alta posterior es dueña de esa escritura.

`GenerateCareSheet` valida photoID y nombres antes de IO; adaptador Chat Completions usa el snapshot de identificación, pero envía exclusivamente nombres/procedencia serializados como datos no confiables separados del prompt fijo. No JPEG/UUID/alternativas/almacenamiento. Máximo 2000 caracteres por nombre, sin truncar ni limitar edición; seis textos ≤1000 tras trim, max_tokens 2000, respuesta ≤1 MiB, timeout total 10–120 s. Sin redirects, retries, fallback ni logs externos crudos.

## Consentimiento y migración

Aviso combinado **v4 / notice-4**, destino canónico/modelo/revisión en fingerprint; aceptación v3/v2/v1 no heredada. Foto para identificar, texto para cuidados y límites remotos desconocidos explícitos. Ambas intenciones cruzan la misma barrera Domain; aceptar al identificar evita repetir aviso, no evita autorización de cuidados. Registro fallido/configuración cambiada bloquea HTTP.

## Consecuencias

Token nuevo por intención + foto/identidad y cancelación local excluyen respuestas atrasadas incluso con nombres iguales. Busy bloquea mutaciones; cancelación mantiene foto/identidad para reintentar. Edición oculta elegibilidad y conserva ficha solo para cancelación no destructiva; reconfirmación descarta ficha e inicia nueva solicitud. `unavailable`, refusal, truncamiento o campos incompletos son errores recuperables sin alta. Sin nuevo esquema/catálogo/IO local ni otro VM. Tests sintéticos no acreditan calidad/compatibilidad/coste reales; evidencia de proveedor corresponde a usuario autorizado.
