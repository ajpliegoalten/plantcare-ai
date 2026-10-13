# ADR 013 — análisis provisional por fotografía y contexto anterior

Fecha: 2026-10-13. Spec `docs/specs/analyze-current-photo.md` aprobada íntegramente (SHA256 `ece71925e678d699862274852aa0becc2ebf70fc07d6eb40b9861fda965d047e`); notas históricas de borrador sucedidas por aprobación. Spec byte-intacta.

## Decisión

Intención explícita desde pager/historial por `(plantID, PlantPhotoIdentity)`, nunca índice. Domain relee pertenencia/elegibilidad al despachar y existencia al publicar. Gate compartido impide dos operaciones simultáneas de esa identidad; gate Presentation conserva solo referencia débil al modal activo. Provisional vive exclusivamente en modal: cerrar cancela/invalida/libera bytes/resultado; reabrir permite consulta nueva. Sin entidad, schema, escritura ni cache de resultados.

`AnalyzePlantPhoto` compone lectores reales Plant/CareEvents/fotos y carga únicamente JPEG elegido. `acceptedReader == nil` expresa capacidad `keep-analysis` aún inexistente, NO lectura persistente exitosa vacía. Futuro contrato devuelve solo textos definitivos propios con identidad/fecha de foto origen; fallo aborta. Definitivo bloquea preparación/despacho. No fabricar análisis ni procedencia botánica persistida inexistente.

Contexto puro: especie confirmada, seis cuidados actuales, ubicación humana opcional, día de foto/consulta y zona gregoriana capturada al abrir, constantes en retry. Ficha/ubicación actuales no se afirman históricas. Solo días estrictamente anteriores (date-only no prueba orden dentro del mismo día). Inicial usa alta proyectada, nunca EXIF. Hasta20cuidados en90días anteriores, occurredAt DESC/createdAt DESC/UUID ASC; nota prefix500 explícito. Hasta5bloques aceptados anteriores por photoDate DESC/identidad ASC, sin horizonte90días ni selección por aceptación. Filtrar antes de limitar. JSON UTF8≤16KiB; quitar bloques IA más antiguos antes de cuidados antiguos, contabilizar omisiones; base excesiva falla localmente. No mutar textos locales ni enviar nombre personalizado/UUID/JPEG históricos.

Un POST Chat Completions a snapshot HTTPS/modelo, imagen≤5MiB, max_tokens2000, salida≤1MiB, timeout10–120s; no streaming/redirect/cache/cookies/credential storage/retry/auth fallback. JSON exacto: outcome analysis|insufficientEvidence + observations/possibleCauses/checks, arrays≤5, textos no blancos≤1000. analysis requiere observations/checks; insuficiencia solo observations. Orientación, no diagnóstico/comparación visual.

Aviso v5/notice-5 renueva v4 y añade foto/contexto anterior, declarando ausencia de imágenes anteriores. Destino/modelo/revisión determinan fingerprint; clave/timeout no. Transporte dentro de AuthorizeExternalAIOperation, configuración revalidada antes de HTTP/publicación. Identificación/cuidados mantienen payloads mínimos anteriores. Release sin config indisponible; fixtures solo Debug Simulator opt-in/UUID, proveedor sintético explícito, no almacén ficticio.

## Consecuencias y handoff

Cancelar/×/gesto incluso durante espera. Aceptar/Descartar visibles deshabilitados y explicados: no guardar/cerrar/borrar por ellos. `keep-analysis` implementará aceptación/persistencia/lector y texto definitivo **debajo de su foto asociada** en timeline sin duplicarla. `discard-analysis` rechazo sin borrar foto origen local. Fecha de foto, generación y aceptación separadas. Sin garantía de snapshot transaccional/multiproceso/calidad botánica/retención remota. No inferencia real de agentes sin autorización específica.
