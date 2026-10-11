# Revalidación final — manual-species-inline — accept (2026-10-11)

**Veredicto actual: accept. V1 cerrado; no reparación pendiente.** Esta sección nueva
no sustituye ni reinterpreta el revise y gate fallido conservados íntegros abajo.
Skills feature-validator + ios-clean-mvvm; mismo HEAD `3cdbc15` y worktree/rama únicos.
Spec delta autorizada `docs/specs/manual-species-inline.md`; spec/informe/handoff
históricos manual-species intactos. No accepted persistido: corresponde al orquestador.

## Reparación corroborada

Único producto diferente desde revise: catálogo `manualSpecies.cancelEdit` pierde
solo `en: Cancel editing`, mantiene `es: Cancelar edición` (serialización final sin
impacto semántico adicional). 85/86 hashes públicos anteriores inalterados; Swift,
tests/assertions y reglas intactos. Reparación satisface V1 sin traducir globalmente.
Focalizadas implementer de `manual-inline-v1-repair/focused.xcresult` leídas directamente:
**3/3 UI, exit 0, cero fallos/omitidos**, dos casos fallidos + cancelación inline.
No rerun desde validator. Summary/tests propios de corroboración en
`manual-inline-revalidation/repair-{summary,tests}.json`. Bundle implementer fresco
DerivedDataRepair solo es.lproj/108 claves/developmentRegion es, contrastado directamente.
Tres capturas reparadas inspeccionadas: detalle español bajo preferencia en
AF721BD4, indisponibilidad española B3E79CFC y Cancelar edición/CTA inline B86DF889
(nombres completos en manifest de reparación). Evidencia funcional/arquitectura/
seguridad/documentación anterior reutilizada: fuentes relevantes sin cambios.

## Gate independiente definitivo

Catálogo reparado invalida gate anterior; único gate **nuevo de reparación**, después
de focalizadas verdes, no repetición automática ni gate anterior reclasificado.
Init no acepta override de DerivedData: fija `$PWD/DerivedData` y cambia a su directorio.
Se creó `DerivedData/manual-inline-revalidation-sandbox` inexistente, copiando solo
los **86 archivos públicos enumerados por manifiesto**, y plantilla pública vacía
como config sintética. DerivedData inicialmente inexistente: sin en.lproj residual,
sin borrados amplios ni alteración de artefactos originales. Config real raíz nunca
leída/copied/modificada; sin API real/secretos/xcuserdata.

Desde ese sandbox:

```sh
caffeinate -dius ./init.sh > ../evidence/manual-inline-revalidation/gate.log 2>&1
```

**BUILD SUCCEEDED / TEST SUCCEEDED, exit 0, 124/124 = 96 unit + 28 UI, cero fallos,
cero omitidos.** Run 2026-10-11 **03:25:17–03:56:53 +0200**. Xcode 26.2/17C52,
macOS 26.5.1, iPhone 17 Pro iOS 26.2/23C54
`B52F5194-6A81-4FAA-B094-B0D248084877`, light/texto normal. Serial, sin procesos
previos; otro simulador booted no usado. Espera del gate original por evento kqueue
NOTE_EXIT PID 37297 y notificación de completion, sin polling/sleeps/retries/segundo
gate sobre estas fuentes. Procesos terminados.

Evidencia en `DerivedData/evidence/manual-inline-revalidation/`:
- `gate.log`, `gate.exit`, `gate.xcresult` archivado, `summary.json`, `tests.json`.
- Original `DerivedData/manual-inline-revalidation-sandbox/DerivedData/Logs/Test/Test-PlantCareAI-2026.10.11_03-25-17-+0200.xcresult`;
  registrado en `original-result-path.txt`.
- `attachments/manifest.json`, capturas y `export.log`.
- `source-manifest.json`, `source-comparison-before.json`, `source-comparison-after.json`:
  **86 hashes iguales entrega/raíz/sandbox**, cero cambio durante gate.
- `bundle-localization.json`: producto final **solo es.lproj, 108 claves, developmentRegion es**,
  Mis plantas y Cancelar edición exactos. V1 cerrado por producto y tests, no solo código.
- `static.log`: proyecto/plutil, JSON catálogo/lista, bash init, diff y hash spec correctos.
- `prior-report.md`/`prior-report.sha256`: copia íntegra del revise previo, también íntegro
  abajo; gate fallido original sigue FAILED/exit 65 en manual-inline-validator.

Inspección visual propia de tres PNG finales:
`181B005B-10F6-4FD8-BC06-494DAF0AB6A4.png` detalle con español sin claves bajo en;
`E97AEBE2-4FFC-4868-8FFE-453A17F4A80F.png` IA seleccionada/manual no seleccionada,
aviso IA antes de opciones humanas y CTA común;
`F541D062-BE12-4EE8-A26A-F720EC020AAF.png` campo inline rellenado/Cancelar edición/
CTA común habilitado, sin modal. Inspección anterior de vacío/largos/teclado/resumen/
insuficiencia sigue válida y gate final ejecuta sus escenarios. No recorrido manual
interactivo adicional declarado: interacción XCUITest real.

Revisión cerrada: selección exclusiva IA/manual, siempre disponible con foto incluso
sin consulta/error/insuficiencia/sin alternativas; confirmación local explícita al
resumen existente, sin cuidados/alta. Edición/cancelación no destructiva, switch a IA
sin confirmar y vuelta expresa con reconfirmación; guards/tokens/tardías y aislamiento
de dos modelos/fichas/JPEG pasan. Clean/MVVM y seguridad scoped sin hallazgos pendientes,
sin IO/red/config nueva. Docs/harness coherentes. Nombre humano no acredita botánica
ni es dato confiable para futuros prompts. API/cámara física/dispositivo/Release y
matrices ampliadas siguen fuera de impacto/habitual, no ejecutados ni bloqueos pendientes.

Validator solo añade esta sección y PROGRESS; no producto/tests/spec/feature_list,
stage/commit/push/PR/merge/GitHub u otra feature. Orquestador puede persistir aceptación
de ronda y gestionar entrega; **no repetir tests por cambio de rol**.

---

# Historia íntegra — validación inicial (revise)

# Validación independiente — manual-species-inline

## Veredicto: revise

2026-10-11, validator `openai/gpt-6.1-sol`; skills feature-validator + ios-clean-mvvm,
rúbrica y checklist de seguridad scoped aplicados. Único repo/worktree manual-species,
rama feature/manual-species, HEAD `3cdbc1553b8cf6549666f5b76329e256a48e9f16`.
Contrato: `docs/specs/manual-species-inline.md`, autorización inline del usuario y
spec histórica `docs/specs/manual-species.md` intacta. Aceptación histórica no acredita
esta ronda. No aceptación nueva ni cambios a feature_list desde validator.

## Gate nuevo y evidencia

Única ejecución desde `DerivedData/manual-inline-sandbox`:

```sh
caffeinate -dius ./init.sh > ../evidence/manual-inline-validator/gate.log 2>&1
```

**BUILD SUCCEEDED / TEST FAILED, exit 65; 122/124 pasan: 96/96 unit y 26/28 UI;
2 casos fallidos, 57 incidencias de assertions/timeouts, 0 omitidos.**
Test run 2026-10-11 02:43:54–03:16:44 +0200. Xcode 26.2/17C52, macOS 26.5.1,
iPhone 17 Pro iOS 26.2/23C54 `B52F5194-6A81-4FAA-B094-B0D248084877`, light/texto
normal. Otro simulador ya booted no utilizado. Sin procesos de test previos; ejecución
serial, sin baseline/focalizadas nuevas/retries/segundo gate. Espera de la ejecución
original mediante evento kqueue NOTE_EXIT del PID 32145 y notificación de completion.
No polling repetitivo ni sleeps. Procesos terminados.

Evidencia ignorada en `DerivedData/evidence/manual-inline-validator/`:
- `gate.log`, `gate.exit`, bundle archivado `gate.xcresult`, `summary.json`, `tests.json`.
- Original: `DerivedData/manual-inline-sandbox/DerivedData/Logs/Test/Test-PlantCareAI-2026.10.11_02-43-54-+0200.xcresult`.
- Export completo `attachments/manifest.json` y capturas/jerarquías/eventos/vídeos.
- `source-comparison-before.json` / `source-comparison-after.json`: **86 hashes**
  de entrega = raíz = sandbox, antes/después, **cero cambios ejecutables**.
- Config del sandbox contrastada únicamente con plantilla pública vacía; config real
  raíz jamás leída/copied/sobrescrita. Sin API real ni productos con secretos.
- `historical-integrity.json`: spec, informe/handoff históricos, init y EditPlant
  byte a byte iguales a HEAD. Evidencia histórica y demás features intactas.
- `static.log`: plutil proyecto, JSON catálogo/lista, bash init, diff whitespace y hash
  spec correctos. SHA256 spec histórica `4127089b20d658278d270676e1191ac73ec78620e2736d5267169558a7717710`.
- `implementer-summary-corroboration.json` y `implementer-tests-corroboration.json`:
  lectura directa de los cinco bundles focalizados, sin rerun. Coinciden summaries
  guardados: unit 33/33; ui-first 6/7 (incluye nueva unit), ui-repair 3/3,
  ui-visual-final 4/5, ui-layout-repair 1/1. Los bundles fallidos siguen fallidos.
  Matriz del handoff justifica 42 escenarios distintos focalizados (34 unit + 8 UI),
  no suite completa; fallos/repairs anteriores preservados.

## Hallazgo V1 — Locale inglés parcial rompe fallback español

- **Severidad: High.**
- Evidencia: diff `PlantCareAI/Localizable.xcstrings`, nueva clave
  `manualSpecies.cancelEdit` incluye `en: Cancel editing`, mientras las claves existentes
  solo tienen español. Build copia explícitamente `en.lproj/Localizable.strings`
  (gate.log líneas 55–58 y 192–195). Diagnóstico estático del producto público seguro
  `localization-diagnostic.json`: en contiene **1 clave**, es **108**;
  CFBundleDevelopmentRegion sigue `es`.
- Casos fallidos:
  `testEnglishPreferenceFallsBackToSpanishInsteadOfKeys` (líneas 1246/1248/1256 y helper
  detalle 113/118/127/128/137), y
  `testExternalConsentUnavailableAndBothPlantsUnchanged` (preferencia `(en)`, línea 259
  y helpers de foto/detalle). UI muestra `collection.title`, `collection.empty.title`,
  `identifyCandidates.configurationUnavailable`, `detail.care.light`, etc.
  Foto cargada aparece realmente, pero su accessibility value tampoco se resuelve;
  los timeouts de «Foto cargada» no demuestran fallo de carga de imagen.
- Captura propia inspeccionada `attachments/AB8558EE-39F6-4702-9F3A-71D19775F53F.png`
  muestra foto real del fixture y claves crudas en título/editar/fecha/cuidados.
- Por qué importa: regresión transversal de UI/localización y contrato de fallback
  existente, causada por recurso compartido modificado en esta ronda. El gate fallido
  no puede aceptarse aunque las ocho UI focalizadas inline pasen.
- Cambio requerido: conservar fallback español íntegro también bajo preferencia inglesa.
  Reparación mínima: retirar **solo** traducción `en` de la nueva clave y conservar
  `es: Cancelar edición`; no introducir localización inglesa parcial ni traducir toda
  la app fuera de alcance. Limpiar artefactos públicos antiguos `en.lproj` en sandbox
  o usar build público fresco para evitar falsa reparación por incremental.
- Verificación posterior: primero los dos escenarios fallidos con todas las assertions
  actuales, junto a `testManualSpeciesWithoutAIAndCancelEdit` por la clave reparada.
  Cotejar bundle compilado (sin locale parcial), fallback español y cancelación inline.
  Después único gate final nuevo justificado por recurso modificado que invalida este
  gate, conservando fallo original y sin retries automáticos.

## Revisión funcional, arquitectura y seguridad

Sin otros hallazgos bloqueantes en revisión estática/diff ni en los escenarios inline
verdes del gate. Manual aparece como opción humana de «Otras posibilidades» antes de IA,
tras error/insuficiencia y sin alternativas. Mismo check/badge/borde, exclusión visual y
estado único manual↔IA. Campo vertical inline al seleccionar, no nueva sheet, único
Confirmar especie al resumen existente. Seleccionar/editar no consulta ni confirma.
Edición precarga; cancelar preserva identidad anterior; switch a IA descarta texto sin
confirmación y admite cancelar selección; vuelta expresa desde resumen exige reconfirmar.
Domain trim, tokens foto/sesión/revisión/cierre/busy/cámara/generaciones y aislamiento
persistido están conservados y cubiertos por tests. Foto B limpia, fallo conserva A;
tardías no reemplazan identidad manual. Sin alta/cuidados.

Presentation → VM → Domain puro inyectado; Domain/Data/App/ContentView/EditPlant/init
sin cambios. No repositorio ficticio, IO/persistencia/consentimiento/transporte nuevos.
Checklist de seguridad: sin hallazgos relevantes de secretos, envío nuevo o exposición;
texto humano solo se representa como texto nativo, no como ruta/SQL/prompt ejecutado.
Nota residual: nombre no certifica botánica; futuros prompts deben tratarlo como dato
no confiable. No nueva dependencia ni auth/cuentas/backend.

Inspección visual básica independiente de ocho PNG focalizados: vacío/rellenado/largo,
resumen manual, teclado, exclusión IA y manual, insuficiencia sin aviso de propuesta,
acciones separadas. Además PNG propios del gate `863DBB51-5DCD-4E77-86E3-335FB84E137C`
(rellenado/CTA) y `498A2E70-6EE6-4275-94EF-2409700F180C` (exclusión IA/manual), correctos.
Interacción ejecutada por XCUITest; no recorrido manual interactivo adicional declarado.
Problema visual adicional observado bajo `(en)` es V1, no se omite por ser otra preferencia:
son pruebas funcionales existentes del gate, no matriz ampliada nueva.

Docs delta, arquitectura, diseño, dominio, ADR 005 y handoff coherentes con autorización;
texto histórico anterior se conserva y delta explícito prevalece sobre modal antiguo.
Passing documenta autoverificación, no aceptación; PROGRESS incorpora este fallo real.
API/cámara/dispositivo físico/Release recertificación y SE/texto aumentado/VoiceOver/
Inspector/matrices no solicitadas no ejecutadas ni requisitos automáticos pendientes.

## Implementation Repair Brief

1. Modificar únicamente localización nueva `manualSpecies.cancelEdit`: conservar español,
   eliminar `en` parcial. No cambiar producto Swift, reglas de edición ni assertions.
2. Sin leer/copiar config real, sincronizar catálogo reparado al sandbox público; archivar
   manifests nuevos y garantizar build sin restos `en.lproj` (DerivedData público fresco).
3. Ejecutar serialmente en el mismo iPhone normal/light selección focalizada:

```sh
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination 'platform=iOS Simulator,id=B52F5194-6A81-4FAA-B094-B0D248084877' \
  -derivedDataPath "$PWD/DerivedDataRepair" -parallel-testing-enabled NO \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests/testExternalConsentUnavailableAndBothPlantsUnchanged \
  -only-testing:PlantCareAIUITests/PlantCareAIUITests/testManualSpeciesWithoutAIAndCancelEdit test
```

4. Registrar resultado exacto, diagnóstico de recursos compilados, fuentes/config/destino
   y capturas sin reescribir fallos anteriores. Entregar reparación a validator para nuevo
   único `./init.sh` sobre producto público limpio; no reutilizar gate fallido como pass.
5. Actualizar handoff/PROGRESS/evidencia de ronda, no accepted; orquestador decide estado.

No editar spec/informe/handoff históricos, no desinstalar/alterar PlantStore real,
no traducción global, nueva feature, secretos/API real ni stage/commit/push/PR/merge.
