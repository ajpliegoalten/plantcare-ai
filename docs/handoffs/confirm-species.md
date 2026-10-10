# Handoff — confirm-species

Spec aprobada `docs/specs/confirm-species.md`, conservada exacta SHA256 `8d6bd4ab4cf73673a39592b5af0acba6d9ad60eed3925f1d9f6ffcb85e947d3f`. Base `a22879e20fdb012314412bcd73ad20d08822c692`; rama feature/confirm-species. Sin operaciones de entrega por implementer.

## Contrato implementado

- Domain ConfirmSpecies: caso de uso síncrono inyectado, identidad efímera con foto/revisión/nombres/procedencia. Sin repositorio/Data/persistencia/IA adicional.
- VM existente: no preselección, selección única, confirmar idempotente; tokens foto/revisión y guards busy/cámara/closed. Resultado nuevo revisiona aunque nombres iguales. Reidentificar limpia antes de validar config/aviso; B limpia al publicar éxito, fallo/cancelación conserva A. Cerrar libera todo.
- Selector científico primero y común si distinto, badges/check/trait selected; CTA separado, resumen humano honesto y Cambiar especie. No cuidados, manual, guardar ni alta. Recursos semánticos y español, scroll normal.
- App compone ConfirmSpecies(); proyecto registra todas las fuentes nuevas. ADR 005, arquitectura y dominio actualizados.

## Probar localmente

En la raíz, `caffeinate -dius ./init.sh` (host despierto/tapa abierta), un iPhone estándar normal/light. Config Debug obligatoria: si no existe copiar exclusivamente `.example` con key vacía; jamás leer/copiar/sobrescribir real existente. Este worktree no tenía real y se preparó plantilla pública vacía. No enviar inferencia real para probar esta feature.

Focalizadas: `xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -destination 'platform=iOS Simulator,id=B52F5194-6A81-4FAA-B094-B0D248084877' -derivedDataPath "$PWD/DerivedData" -parallel-testing-enabled NO -only-testing:PlantCareAITests/ConfirmSpeciesTests -only-testing:PlantCareAITests/ConfirmSpeciesViewModelTests -only-testing:PlantCareAIUITests/PlantCareAIUITests/testConfirmSpeciesAlternativeAndDraftInvalidation test`.

UI determinista: launch con UUID aislado `--storage-test-id <UUID> --consent-test-id <UUID> --identification-photo-fixture --identification-candidates-fixture proposals`; `--storage-seed` solo primera vez. Abrir Añadir, Test A, Identificar, aceptar aviso fixture; seleccionar Filodendro, confirmar y cambiar; reemplazo fallido conserva, Test B invalida. Fixtures solo Debug Simulator, no inferencia botánica. `--storage-verify` después de relanzar sin reseed compara dos modelos y JPEG completos. Cleanup conforme guía local existente; no desinstalar ni borrar otros IDs.

## Evidencia final — ready for validator

- Gate definitivo `caffeinate -dius ./init.sh`: BUILD/TEST SUCCEEDED 105/105 (84 unit + 21 UI), cero fallos/omitidas. `DerivedData/evidence/confirm-gate-verified.log/-summary.json`; xcresult `DerivedData/Logs/Test/Test-PlantCareAI-2026.10.10_22-07-53-+0200.xcresult`.
- Focalizadas finales 12/12 (10 unit + 2 UI), cero fallos/omitidas, `confirm-focused-scroll-repair.log/-summary.json`, xcresult 22-03-08. Focalizada previa 13/13 (10 unit + 3 UI) también verde; gate final incluye tercera regresión y todas las demás.
- Baseline 94/94, Release Simulator BUILD SUCCEEDED y audit sin config/seams, static correcto. Artefactos `confirm-baseline*`, `confirm-release*`, `confirm-static.log`. No API real; build Debug solo con plantilla pública vacía creada al faltar config.
- Capturas definitivas `confirm-gate-verified-attachments` y `final-confirm-*.png` inspeccionadas: sin selección/CTA deshabilitado, alternativa seleccionada/confirmada, B sin identidad, largos/acciones. Unit/VM incluyen casos de invalidación/obsolescencia; UI nativa verifica contador, gesto/reapertura/relaunch y dos modelos/JPEG completos sin reseed.
- Fallos anteriores y reparación de helper scroll (gestos globales excesivos cerraban modal) conservados en PROGRESS y logs; assertions/cobertura intactas. Fuentes finales no cambiaron después de gate. Estado passing solo autoverificación, **no accepted**; procesos terminados. Orquestador gestiona validator y entrega; implementer no hace Git de escritura/GitHub.

## Límites y siguiente paso

Confirmación humana no garantiza especie; identidad solo en memoria. generate-care-sheet deberá comprobar photoID vigente y autorizar su propia intención; manual-species acordará procedencia nueva, save-plant hará alta/pipeline. No invocados ahora. API/cámara física no repetidas: no cambian en esta feature. SE/texto aumentado/VoiceOver/Inspector/matrices fuera de habitual, no ejecutadas. Aceptación solo por validator independiente/orquestador.
