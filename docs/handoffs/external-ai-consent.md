# Handoff — external-ai-consent

Rol implementer, feature única en worktree `external-ai-consent`. No stage/commit/push/GitHub. Spec aprobada preservada sin modificar, preexistente no rastreada: `docs/specs/external-ai-consent.md`, SHA256 `4bea3b28709fe8adc1a46635edc9893e6bb2312b33391f880d990c0ae6c89cb3`. Debe incluirse en entrega del orquestador; redacción histórica de propuesta no altera aprobación explícita del usuario.

## Código y alcance

`ExternalAIConsent` separa Domain (alcance, contrato, barrera), Data (actor UserDefaults/fixture Debug Simulator) y Presentation (aviso). App comparte barrera e inyecta continuación que devuelve indisponibilidad; VM de foto guarda intención/estado/generación y cancela gestos/cierre/tareas. No cliente real, endpoint, clave, identificación ficticia, alta ni modificación de PlantStore.

El destinatario provisional debe sustituirse y renovarse al conectar red en identify-candidates. ADR 003, ARCHITECTURE, CONSTRAINTS y docs de dominio/riesgos detallan reglas. Pasos locales/limpieza en `docs/testing-external-ai-consent.md`.

## Verificación y siguiente paso

**passing, lista para validator independiente; no accepted.** Gate final `caffeinate -dius ./init.sh` BUILD/TEST SUCCEEDED, 70/70 (54 unit + 16 UI), cero fallos/omitidas; `DerivedData/evidence/consent-gate-final.log`, summary y xcresult `DerivedData/Logs/Test/Test-PlantCareAI-2026.10.10_15-04-20-+0200.xcresult`. Focalizada 15/15 en `consent-focused-first.log`/summary, xcresult 14-42-44; baseline 58/58 en consent-baseline. Único iPhone 17 Pro iOS 26.2 B52F5194-6A81-4FAA-B094-B0D248084877, light/normal; Xcode 26.2. Runs seriales, `init.sh` intacto. Gate previo al texto final también pasó, pero no se usa como prueba final; historial en PROGRESS.

Release genérico Simulator BUILD SUCCEEDED; `consent-release.log` y `consent-release-audit.log` prueban seams ausentes en strings/nm. Static/JSON/proyecto/bash/diff/Domain typecheck pasaron; `consent-static.log`. Capturas finales exportadas/inspeccionadas bajo consent-gate-final-attachments y aliases final-consent-*.png. Apertura manual aislada/limpieza propias en consent-manual.log/empty/cleaned.png. Fallo host inicial Boolean true vs NSNumber(1) y corrección/regresión iOS preservados; no fallo iOS ocultado ni assertion retirada.

Validator independiente debe revisar aislamiento de suite, orden registro→invocación, cero rechazos, duplicados/late responses, relanzamiento, regresiones completas, capturas reales y exclusión de fixtures en Release. `passing` no equivale a accepted; aceptación solo por orquestador tras verdict independiente. Issue #16 y stage/commit/entrega corresponden al orquestador tras accept. No otra feature iniciada.

## Archivos de entrega

- Nuevos Domain: `PlantCareAI/Features/ExternalAIConsent/Domain/{ExternalAIConsent,ExternalAIConsentRepository,AuthorizeExternalAIOperationUseCase}.swift`.
- Nuevos Data: `.../ExternalAIConsent/Data/{UserDefaultsExternalAIConsentRepository,ExternalAIConsentTestFixture}.swift`; nueva Presentation `.../ExternalAIConsent/Presentation/ExternalAIConsentView.swift`.
- Modificados: `PlantCareAI/Features/IdentificationPhoto/Presentation/{IdentificationPhotoView,IdentificationPhotoViewModel}.swift`, `PlantCareAI/PlantCareAIApp.swift`, `PlantCareAI/Localizable.xcstrings`, `PlantCareAI.xcodeproj/project.pbxproj`.
- Nuevas unitarias: `PlantCareAITests/{ExternalAIConsentTests,UserDefaultsExternalAIConsentRepositoryTests,IdentificationConsentViewModelTests}.swift`. Extendidas `PlantCareAITests/IdentificationPhotoViewModelTests.swift` y `PlantCareAIUITests/PlantCareAIUITests.swift`; las 13 UI previas siguen, más 3 de consentimiento.
- Docs/harness: `ARCHITECTURE.md`, `CONSTRAINTS.md`, `PROGRESS.md`, `feature_list.json`, `docs/domain-model.md`, `docs/risks-and-open-questions.md`; nuevos `docs/adr/003-external-ai-consent.md`, `docs/testing-external-ai-consent.md` y este handoff.
- **Incluir la spec preexistente no rastreada** `docs/specs/external-ai-consent.md`, intacta con hash indicado arriba. Artefactos/logs en DerivedData ignorado no son fuentes a versionar.

Fuera de comprobación habitual: SE/texto aumentado/VoiceOver/matrices. Sin API real ni cámara física verificados en esta entrega; UserDefaults no garantiza apagado abrupto. No lanzar pruebas simultáneas sobre el simulador estándar.
