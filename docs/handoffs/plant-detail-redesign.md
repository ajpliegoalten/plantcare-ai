# Handoff: plant-detail-redesign

## Entrega y alcance

Rama `design/plant-detail`, worktree `../plantcare-ai-plant-detail-redesign`, base main9908cd7. Usuario aprobó implementación/documentación en español, **riego solo visual** y cuidados completos sin nuevos resúmenes. Spec `docs/specs/plant-detail-redesign.md`; aceptación histórica intacta. Sin stage/commit/push/PR/merge, API real ni siguiente feature.

Archivos de producto: `PlantDetailView.swift` (Presentation), cinco colores CareMint/Honey/Peach/Ochre/Terracotta y cinco textos `detail.watering.*`. VM, Domain, Data, esquema, composición, edición y flujo de alta no cambiados. Un test nuevo en StoredCollectionUITests; todas las assertions previas conservadas. DESIGN, guía UI y estado de ronda documentados.

## Impacto → comprobaciones

- Identidad/fecha/ficha por UUID y no writes → StoredCollection canónico + LoadPlantDetail (3 unit) y DetailVM (9 unit).
- Dos columnas/filas iguales y placeholder no funcional → nuevo escenario StoredCollection, inspección de tres capturas focalizadas.
- Ubicación y editor nativo → ambas EditPlant UI.
- Navegación/foto fallida/retry/texto largo → tres PlantCards UI.
- Seis textos1000 conservados tras relaunch → CareSheetThousandCharacterTextScrollsAndPersists.
- Recursos/fallback → Localization UI, JSON y comprobación de traducciones previas sin cambios.

## Evidencia ejecutada

`DerivedData/evidence/plant-detail-redesign` conserva comandos exactos `.command.txt`, logs, exit codes, manifests públicos, summaries y attachments. Bundles en `DerivedData/DetailRedesign`.

1. `python3 DerivedData/evidence/plant-detail-redesign/run-focused.py visual`: build-for-testing **exit0**, nuevo escenario **1/1 PASS, exit0**, cero skips/expected failures. `visual.xcresult`; tres capturas exportadas/abiertas. Geometría/placeholder correctos, pero inspección detectó icono vacío en identidad (`pottedplant.fill` no renderizado). No se considera aprobación visual final.
2. `python3 DerivedData/evidence/plant-detail-redesign/run-focused.py regressions`: test-without-building **20/20 PASS, exit0 =12unit +8UI**, cero failed/skipped/expected failures. `regressions.xcresult`; selección exacta en command y runner. Capturas0. Sin gate completo.
3. Reparación explícita: único cambio de producto `pottedplant.fill → leaf.fill`, símbolo ya usado/renderizado en ficha. `python3 DerivedData/evidence/plant-detail-redesign/run-focused.py visual-repair`: build-for-testing incremental **exit0**, nuevo escenario **1/1 PASS, exit0**, cero failed/skipped/expected failures. `visual-repair.xcresult`; tres capturas finales exportadas/abiertas muestran icono visible, identidad/calendario, riego deshabilitado y seis tarjetas iguales por fila con aviso final. No repetir la suite por un icono decorativo; regresiones20 reutilizadas por impacto, sin presentarlas como gate final.

Resultado **passing: 21 escenarios distintos =12unit +9UI**, no22 al repetir explícitamente el escenario visual para verificar una reparación. No cambio de producto posterior a esta comprobación.101 inputs públicos finales idénticos antes/después del build+visual-repair y checkout comprobado; todas las traducciones anteriores y cinco claves nuevas verificados semánticamente. JSON/Swift parse/plutil/diff finales correctos. La comprobación intermedia de igualdad byte del catálogo durante regresiones detectó la reserialización descrita debajo; no es fallo de tests ni una igualdad atribuida indebidamente.

Xcode26.2/17C52, macOS26.5.1, iPhone17Pro iOS26.2/23C54 base00BBB7EC-8DF7-400C-A08A-9D3C8818D886, texto normal/claro. 5workers configurados, clones gestionados por XCTest; ninguna prueba competidora. Capturas1 únicamente en el nuevo escenario. Skill XcodeBuildMCP cargada, tools no expuestos en esta sesión; fallback CLI. Config ignorada creada solo de example público vacío, sin acceso al real del checkout principal.

101 inputs públicos iguales antes/después de build+visual inicial. Durante regresiones, catálogo fue reserializado/reordenado y `detail.care.title` marcado stale por extracción; sus traducciones se preservan. No atribuir igualdad byte a byte a ese catálogo. Comparar semántica y bundle; scripts/manifests no leen config real/xcuserdata. El símbolo decorativo posterior es el único cambio ejecutable y exige nueva captura, no nuevas reglas de Domain.

Estáticos iniciales ejecutados: JSON catálogo/features/13 colores, plutil proyecto, Swift parse vista/UI, git diff--check. Cinco claves nuevas usadas, traducciones existentes intactas; contraste calculado de tokens: Primary/Mint7.34, Ochre/Honey7.41, Terracotta/Peach4.98, Terracotta/Surface6.43, TextSecondary/Surface9.40. El tratamiento nativo de deshabilitado atenúa el botón, sin simular disponibilidad.

## Pendiente y límites

Inspección de icono cerrada y ronda passing. Validator independiente ejecutará **un gate estándar** sobre fuentes finales; 125unit +38UI paralelas +1Fotos serial =164 tests previstos. No accepted ni gate aprobado nuevo. Sin UI completa de historial/registro/fecha; `quick-watering` reemplazará el placeholder. Sin pruebas de SE/texto aumentado/VoiceOver/matrices ampliadas (fuera de verificación habitual, no bloqueos). No nueva API/Release necesaria para esta ronda visual local. No pruebas activas al cierre; solo docs/estado se actualizan después de fuentes comprobadas.
