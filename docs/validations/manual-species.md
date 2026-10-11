# Validación independiente — manual-species

Fecha: 2026-10-11. Rol validator (`feature-validator` + guía local `ios-clean-mvvm`). **Veredicto final: accept.** Sin hallazgos bloqueantes ni reparación requerida. El estado accepted corresponde al orquestador, no a este rol.

## Contrato y fuentes

- Spec `docs/specs/manual-species.md` aprobada íntegra por el usuario en conversación; sus notas históricas no anulan esa aprobación. SHA256 intacto `4127089b20d658278d270676e1191ac73ec78620e2736d5267169558a7717710`.
- Worktree único `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/manual-species`, rama `feature/manual-species`, HEAD/base `3910d2c47f50944ad291dafc724f7c9a7a84af12`.
- Revisados diff rastreado y archivos nuevos no rastreados, handoff, PROGRESS, feature_list (passing), arquitectura, restricciones, diseño, contexto/brief/dominio/riesgos y ADR 005. Los manifiestos final/delivery/current coinciden en 73 archivos públicos ejecutables/proyecto/recursos/harness/plantilla; snapshot propio `DerivedData/evidence/manual-validator-source-manifest.json`.
- Config requerida ya preparada por implementer desde plantilla pública vacía e ignorada; validator no leyó/copió/sobrescribió config privada, ni empleó API real. No cambios de producto/tests/spec, stage/commit/push/PR/merge/GitHub ni otra feature.

## Revisión de escenarios 1–8

1. Entrada con foto sin configuración/resultados y tras insuficiencia/error; VM no requiere disponibilidad IA para manual, UI y contador cubiertos.
2. Caso Domain puro recorta exclusivamente extremos, rechaza blancos y conserva interior/Unicode/texto largo sin límite. Source manual no fabrica nombres/revisión/posición IA. Confirmación explícita, sin alta/cuidados.
3. Cancelar editor conserva foto/identidad/resultado/selección; nueva sesión vacía salvo identidad manual vigente. Botón y gesto cubiertos.
4. Edición precargada y sustitución de única identidad tras éxito; fallo local conserva identidad/texto con error separado. Tokens obsoletos y doble callback ignorados.
5. Resultado IA retenido inactivo, vuelta solo con propuestas vigentes de la foto, conserva selección pero requiere reconfirmar. Sin nueva invocación.
6. Reidentificar invalida antes de configuración/aviso. Reemplazo exitoso incluso mismos bytes/UUID nuevo limpia; fallo/cancelación/permiso denegado mantiene A.
7. Guards VM excluyen intenciones del padre durante edición y apertura durante busy/cámara/aviso. photoID/sessionID y generaciones descartan callbacks/continuación cancelada no cooperativa incluso con misma A.
8. Cierre/reapertura/terminate durante edición descartan borrador. UI verifica dos modelos/fichas/JPEG exactos tras relaunch sin reseed/desinstalar mediante --storage-verify y ambas fichas.

Arquitectura correcta: View → VM foto existente → caso Domain puro inyectado desde App; sin Data/repositorio ficticio ni segundo dueño/JPEG. Caller IA migrado manteniendo validación/pertenencia/copia exacta. EditPlant, transporte, persistencia, ContentView, Assets e init intactos. Nuevas fuentes/tests registrados en targets. No aserciones históricas eliminadas/debilitadas.

Seguridad scoped (checklist aplicada): texto humano → trim/rechazo vacío → identidad efímera/Text nativo, sin sink externo/disco/log. No nuevos secretos, dependencias, permisos, red o escritura/consentimiento. No hallazgos bloqueantes. Riesgo futuro: nombre humano no es certeza botánica y debe tratarse como dato no confiable en prompts de generate-care-sheet; no es un fallo explotable de esta slice.

Docs durables coherentes: arquitectura, ADR 005, dominio y diseño registran contrato/transiciones/procedencia y límites; handoff conserva cronología/fallos. No nuevas restricciones/AGENTS necesarias. El resumen provisional seguirá hasta generate-care-sheet y save-plant mantiene su responsabilidad futura.

## Evidencia reutilizada (no reejecutada separadamente)

Bundles `.xcresult` corroborados directamente con `xcrun xcresulttool get test-results summary --path DerivedData/evidence/<nombre>.xcresult`; summaries originales y propios coinciden exactamente:

- `manual-unit`: 33/33 unit, 0 fallos/omitidas.
- `manual-ui-first`: **fallido**, 2/5 verdes, 3 fallidas (6 assertions/errors en log); dos regresiones IA verdes. Helper TextView-only incorrecto para campo vacío TextField; fallo conservado, no convertido en gate aprobado.
- `manual-ui-field-repair`: 3/3 UI reparadas, 0 fallos/omitidas.
- `manual-ui-final`: 4/4 UI manuales tras reparación de contraste/escenario adicional, 0 fallos/omitidas.

33 unit + 2 regresiones IA + 4 manuales = 39 escenarios distintos focalizados, **no suite completa**. Cambios initial/final corroborados: únicamente vista manual/color, catálogo/metadata y UI harness; ningún valor localizado preexistente cambió. Domain/VM/callers IA intactos justifican reutilización. Fallo de comando typecheck incompleto anterior permanece registrado; selección corregida no es retry de tests.

Inspección visual básica independiente de PNG reales finales reutilizados: `final-manual-{empty,filled,long-editor,summary,return-to-ai}.png` y teclado largo `manual-ui-final-attachments/36EBD089-F639-4596-B075-937DBD782BBD.png`. Form nativo coherente con EditPlant, texto/procedencia/no alta legibles, blanco sobre verde activo, teclado real/Listo y scroll. Interacción por XCUITest, no recorrido manual extra declarado. Miniatura sintética procede de foto preparada del fixture, no imagen de ejemplo insertada en UI.

## Evidencia nueva

- Antes de gate: `pwd`, git status/diff/hash, HEAD/branch, procesos (ningún xcodebuild/init/xctest activo), Xcode/version, lista booted y apariencia. Un único destino usado B52F5194-6A81-4FAA-B094-B0D248084877, iPhone 17 Pro iOS 26.2/23C54 (Edit Plant Recovery), light/texto normal; Xcode 26.2 (17C52), macOS 26.5.1. Otro simulador preexistente booted no utilizado.
- Estáticos nuevos: `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON feature_list/catalog, `git diff --check` y Foundation-only `xcrun swiftc -typecheck PlantCareAI/Features/IdentificationPhoto/Domain/IdentificationPhoto.swift PlantCareAI/Features/IdentifyCandidates/Domain/*.swift PlantCareAI/Features/ConfirmSpecies/Domain/*.swift PlantCareAI/Features/ManualSpecies/Domain/*.swift` correctos.
- **Gate único final terminado:** `caffeinate -dius ./init.sh > DerivedData/evidence/manual-validator-gate.log 2>&1` → **BUILD SUCCEEDED / TEST SUCCEEDED, exit 0, 123/123 = 95 unit + 28 UI, cero fallos/omitidas/expected failures**. Selección completa final (build + todas unit/UI y siembra picker sintética), no baseline extra ni focalizadas duplicadas. Espera de la ejecución original mediante kqueue NOTE_EXIT del PID 22712 (status 0), más notificación de salida de la herramienta; no polling repetitivo/sleeps/retries/reruns.
- Test run 2026-10-11 **01:32:10–02:03:03 +0200**. Bundle original `DerivedData/Logs/Test/Test-PlantCareAI-2026.10.11_01-32-10-+0200.xcresult`; copia archivada `DerivedData/evidence/manual-validator-gate.xcresult`, summary `manual-validator-gate-summary.json`, árbol `manual-validator-gate-tests.json`, PNG/manifest en `manual-validator-gate-attachments/`. Todos los cuatro métodos UI manuales y nueve VM/two Domain, las regresiones IA, picker/consentimiento/almacén/detalle/edición quedan incluidos en el gate.
- Inspección propia adicional de cuatro PNG del gate: aliases `manual-{filled,summary,long-editor,new-photo-cleared}.png` bajo attachments. Confirman label reparado/ayuda/procedencia, resumen sin alta y B sin identidad/counter 0. Las capturas reutilizadas ya cubren vacío/teclado/vuelta IA; sin una segunda ejecución interactiva.
- Comprobación posterior: 73 hashes públicos iguales al snapshot previo/final/delivery, hash spec intacto, ningún proceso de tests/gate restante. No cambió ningún ejecutable/config/harness al documentar el cierre. Warnings Swift 5/Sendable heredados y errores deliberados de fixtures corruptos no son tests fallidos.

## Cómo probar localmente

Con Xcode/runtime disponibles y plantilla pública vacía solo si falta config requerida (nunca sobrescribir un real), ejecutar `caffeinate -dius ./init.sh`. Abrir app en simulador estándar, Añadir → foto → Introducir especie conocida → escribir/Confirmar. Comprobar resumen/no alta, Cambiar especie/Cancelar y vuelta a propuestas con reconfirmación si existen. No necesita configurar ni invocar API real para la vía manual.

Fuera de habitual/impacto y no ejecutados: SE/pantallas pequeñas, texto aumentado, VoiceOver/Inspector/matrices, API real, cámara/dispositivo físico y recertificación Release. Accesibilidad preservada en código. Estado sigue passing; orquestador puede persistir accepted con este verdict accept final. Ninguna comprobación obligatoria pendiente para esta slice.
