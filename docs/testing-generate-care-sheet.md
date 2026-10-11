# Comprobación de generate-care-sheet

Spec aprobada intacta: `docs/specs/generate-care-sheet.md`, SHA256 `86a52855ea0788238bda08e142c2ec13b3bf3e6f9c7e0cabc9a10ae08c974eee`. Evidencia y comandos ejecutados: `docs/handoffs/generate-care-sheet.md`.

## Entorno seguro y selección por impacto

No ejecutar builds sobre config privada ni copiarla. Sandbox público bajo `DerivedData/care-public`: copiar únicamente fuentes/resources versionados de PlantCareAI, tests, scripts, `project.pbxproj`, scheme compartido, plist puente público e `init.sh`, más los nuevos Swift de esta feature. No copiar xcuserdata ni artefactos anteriores. Crear ahí Config/IdentificationSecrets.xcconfig desde `.example` con clave vacía; conservar manifiestos SHA256 de entradas. Un único iPhone17Pro/iOS26.2, normal/light, serial y host despierto. La raíz privada no se compiló.

Domain/Data → six-field validity/privacy/status/timeout → GenerateCareSheetTests + OpenAICompatibleCareSheetGenerationRepositoryTests. VM y confirmación → duplicados/operación pendiente/cancelación/stale/edición → GenerateCareSheetViewModelTests + ConfirmSpeciesViewModelTests + ManualSpeciesViewModelTests + IdentificationPhotoViewModelTests + IdentificationConsentViewModelTests. Aviso/config compartidos → migración v3→v4/regresión identificación → ExternalAIConsentTests + OpenAICompatibleSpeciesIdentificationRepositoryTests. No suites de persistencia por rutina: no contratos/esquema/IO modificados; E2E conserva verificación real de dos modelos/fichas/JPEG al relanzar sin seed.

Forma de comando (ejecutar en sandbox, bundle nuevo por selección; no retries):

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
 -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
 -derivedDataPath Build -resultBundlePath <seleccion>.xcresult \
 -parallel-testing-enabled NO -only-testing:PlantCareAITests/<clase> test
```

E2E existentes adaptados conservan selección, nombres, cancelación, invalidación y aislamiento; resumen temporal sustituido por ficha completa. Cuatro nuevos escenarios: direct alternative/manual review; error/incomplete/retry/renewed consent cancelled; waiting/cancellation/late response/close/storage; long six fields/Abonado/edit cancel/photo failure/B/reidentify. Inspeccionar capturas reales espera/error/alternativa/manual/Abonado largo, sin ampliar dispositivos/texto/apariencia.

## Prueba de API real — solo usuario autorizado

Configurar privadamente el mismo destino/modelo; identificar foto, aceptar aviso v4 (v3 debe renovarse), elegir alternativa o manual, confirmar y revisar seis campos. Repetir nombre conocido humano; comprobar error/reintento y ausencia de alta. No publicar productos Debug con credencial, logs crudos ni clave. Dobles no prueban compatibilidad, JSON/presupuesto, coste, calidad botánica ni retención. El 2026-10-11 se recibió confirmación explícita del usuario a los seis puntos, con chat de inference.devexpert.io (modelo no comunicado) y gpt-4.1-mini de api.openai.com; relato completo y limitaciones en `docs/handoffs/generate-care-sheet-repair.md`. B1 pendiente de corroboración independiente, no de repetir la petición al usuario ni de envíos por agente.

## Gate final

Validator independiente es dueño de una única ejecución `caffeinate -dius ./init.sh` sobre fuentes finales en sandbox seguro. El implementer no lo ejecuta por rutina; sus resultados focalizados no son aceptación. Matrices ampliadas y cámara física fuera de verificación habitual, no ejecutadas ni bloqueos automáticos.

Gate anterior independiente FAILED145/146 preservado en `docs/validations/generate-care-sheet.md`. Reparación H1 del harness y corrección documental D1 en `docs/handoffs/generate-care-sheet-repair.md`; nuevo gate requerido después de focalizadas sobre tests reparados, no reutilizar agregado fallido como passing.
