# Quick-watering — handoff implementer

**Estado vigente H3: passing tras reparación/autoverificación3/3.** Ver «Cierre H3 por selección nativa de párrafo» en `docs/handoffs/quick-watering-h3.md`: fuente nueva/gesto native triple-tap, capturas completas y3tests verdes. Blocked/FAILED anteriores permanecen históricos. Nuevo gate completo/aceptación independiente siguen pendientes del mismo validator.

**Estado vigente tras REVISE: reparación H1/H2 autoverificada, passing para volver al mismo validator; gate completo aún pendiente.** Ver `docs/handoffs/quick-watering-repair.md` para diagnóstico, fallos conservados,7 callers, destino y nuevo manifiesto final. Las evidencias/hashes iniciales siguientes son históricos/reutilizados por impacto, no sustituyen el gate independiente fallido.

Estado: passing; autoverificación cerrada, listo para validator, no aceptación independiente. Spec aprobada intacta `docs/specs/quick-watering.md`, SHA256 `cc23a2f0d9ab89e4b2dd4e1e7eb7707da5507a56f30f7eb94eb103e1608230e6`. Rama feature/quick-watering, base e9a18b053e9668c9a5508552e1e75ce6651e7fc0. Autorización actual integral recibida vía parent; pendientes/prohibiciones de planificación son históricos. No delegar/stage/commit/push/PR/merge/GitHub. Validator posterior dueño del único gate completo.

## Producto y fronteras

- QuickWatering/Domain: CareEvent siete campos, CareEventRepository y RegisterWatering; IANA/inicio de día/futuras/nota. QuickWatering/Data: PersistedCareEvent y fixture Debug; actor compartido LocalPlantRepository dueño del schema/escrituras/rollback/migración aditiva, sin Plant/PlantRepository/PersistedPlant nuevos campos.
- QuickWatering/Presentation: VM de sesión nueva, snapshot inmutable de primer despacho, retry humano, bloqueo previo a await, callback una vez; sheet fecha/nota/chips/CTA/error local. Detail VM/View crean solo loaded, imagen snapshot acotada, banner efímero confirmado sin releer metadata/foto ni cambiar último-riego/lista. App→ListVM→DetailVM inyecta mismo repositorio tras override.
- Shared/Presentation/PlantFormHeader; EditPlant View/VM cambian solo metadata de cabecera y layout inset/CTA inferior, no UpdatePlant/reglas/persistencia/refresco. IDs conservados.
- Fixture solo Debug Simulator y UUID aislado; payload7 esperado de despacho en sidecar de tests, verify real al relanzar y B sin eventos. No cronología simulada ni contador constante.

## Impacto → riesgo → selección

| Cambio/callers | Riesgo | Verificación |
| --- | --- | --- |
| Domain temporal/nota | DST, día omitido, reloj, offsets, Unicode/longitud | RegisterWateringTests |
| Schema/actor compartido | upgrade V1, rollback, duplicado/conflicto, aislamiento Plant/JPEG, corrupción | LocalCareEventRepositoryTests + LocalPlantRepositoryTests |
| Watering VM | double tap/busy/retry7/cambio zona/intención/callback/cancelación tardía | QuickWateringViewModelTests |
| App/List/Detail/foto/editor | UUID, snapshot sin IO, metadata error/foto fallida, cache/refresco | DetailVM/ListVM/EditVM; StoredCollection/SavePlant/photoFailure |
| Sheet/editor/teclado | dos taps, error/cancel/gesto, CTA scroll, largos, coherencia visual | QuickWateringUITests + ambos EditPlantUITests y capturas focalizadas |

## Entorno y comandos realmente ejecutados

Xcode26.2/17C52, macOS26.5.1, iPhone17Pro iOS26.2/23C54 `00BBB7EC-8DF7-400C-A08A-9D3C8818D886`, texto normal/claro. Una sesión xcodebuild cada vez, caffeinate; XCTest5workers para paralelo, clones aislados del mismo destino. ProMax ajeno intacto. Config inicialmente inexistente: copiada solo `.example` público vacío al fichero ignorado; ningún config real/base privado leído o sobrescrito, ni API real.

Artefactos ignorados: `DerivedData/evidence/quick-watering/`; productos `DerivedData/quick-watering`.

```sh
UDID=00BBB7EC-8DF7-400C-A08A-9D3C8818D886
DD=DerivedData/quick-watering
caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DD" build-for-testing
TEST_RUN=$(python3 scripts/configure-ui-test-environment.py "$DD/Build/Products" 0) # 1 para selección visual
caffeinate -dius xcodebuild -xctestrun "$TEST_RUN" -destination "platform=iOS Simulator,id=$UDID" \
  -parallel-testing-enabled YES -parallel-testing-worker-count 5 \
  -maximum-concurrent-test-simulator-destinations 5 \
  <selecciones descritas abajo> -resultBundlePath <bundle abajo> test-without-building
```

- `build.log` y `build-ui.log`: TEST BUILD SUCCEEDED exit0. `unit.log`/unit.xcresult: TEST EXECUTE SUCCEEDED exit0 **33/33**, cero skips; siete clases Domain/WateringVM/CareRepository/PlantRepository/DetailVM/ListVM/EditVM, `-parallel-testing-enabled NO`. Nueva evidencia, no baseline/gate164 reutilizado. Dos caller tests y posteriores endurecimientos aún no estaban en ese build.
- `visual-ui.log`/visual-ui.xcresult: **FAILED18/20 exit65**, cero skips. Selección QuickWateringUITests/EditPlantUITests/DetailVM/LocalCareEventRepository con capturas1.14unit+4UI individualmente verdes (ambos editor/default/retry). Dos Quick UI fallidos conservados, nunca aggregate aprobado.
- Diagnóstico busy: hierarchy `618BD845…txt` muestra ActivityIndicator wateringSaving y controls disabled, test consultaba ProgressIndicator. Selector corregido sin quitar assertions; fixture12s solo tests. Fecha/nota: error al verificar tras commit/relaunch; hipótesis teclado doble-espacio→punto, cambiada entrada blanca multilínea y añadida igualdad EXACTA del borrador antes de guardar. Inspección detectó Cancelar recortado en riego, frame movido al label (como editor).
- `build-repair.log` exit0, fuente `repair-source-hashes.json`; `repair.log`/repair.xcresult original pendiente al escribir esta nota: solo busy/date fallidos + RegisterWatering/WateringVM/CareRepository/PlantRepository/DetailVM afectados por validación/cleanup/nuevos tests. No retries ni gate completo.
- `static.log`: plutil proyecto, JSON catálogo/feature_list, Foundation-only todos Domain typecheck, diff-check, config ignorado/spec hash correctos.
- `repair.xcresult` terminó FAILED30/31 exit65,29 unitarias y busy UI verdes, fecha/nota sigue fallando al verificar después del relaunch; equality exacta del borrador PASÓ, por lo que la hipótesis de doble-espacio no explica el fallo pendiente. Resultado y capturas conservados. Nueva hipótesis concreta: transportar nota multilínea literal en launchArguments no conserva la expectativa. Test usa Base64 UTF8 y fixture decodifica/compara String exacto (no se debilita payload7/trim). Se añadió integración de fixture con nota multilinea/día esperado/reapertura reales; `note-repair.xcresult` original en curso solo escenario fallido + integración nueva.
- `note-repair.xcresult` terminó TEST EXECUTE SUCCEEDED exit0,2/2 (integración1+UI1), cero skips;01:14:32–01:15:47+0200. Mantiene texto multilinea/día/payload7/Plant/JPEG exactos; solo cambió transporte de expectativa a Base64. Primera hipótesis teclado descartada, no product fix de nota ni aserciones debilitadas. Busy/placeholder reparados inspeccionados (`repair-attachments/013E3AC8…png`), Cancelar completo y estado bloqueado.
- `build-final.log` exit0; `final-visual.xcresult` original en curso con UI largos nueva/default/error (captura final Cancelar/header) + unidad nueva ListVM real/fecha gregoriana explícita. Manifest `final-source-hashes.json` corresponde a este build. Posterior revisión de bounds: DatePicker compara instantes, no días; su límite ahora conserva representabilidad del instante seleccionado tras zona/retroceso de reloj (`max(now, occurredAt)`), sin editar payload; Domain sigue rechazando inserción futura. Se añadieron assertions VM y queda build/prueba focalizada de ese delta junto a regresiones directas. No atribuir esa propiedad nueva al build final-visual previo.

## Cierre de ejecuciones posteriores y reuso

Los párrafos anteriores registran el estado al lanzar cada ejecución; los resultados cerrados siguientes los sustituyen como estado actual sin borrar fallos ni evidencia histórica.

- `final-visual.xcresult`: SUCCEEDED5/5 exit0,2unit+3UI, cero skips. Capturas finales normal/error/confirmación/largo/teclado/editor largo abiertas e inspeccionadas, además busy/placeholder reparados: Cancelar completo, fotografía/cabecera/CTA/scroll coherentes. `regressions.xcresult`: SUCCEEDED8/8 exit0,1unit+7UI, cero skips; StoredCollection2/SavePlant3/photoFailure1/DateNote1/VMbounds1. Capturas0,01:21:22–01:26:10+0200; límites DatePicker probados.
- `literal.xcresult`: SUCCEEDED16/16 exit0,15unit+1UI, cero skips; RegisterWatering3/CareRepository6/WateringVM4/Detailcallback1/Listcomposition1/DateNote1. Nueva igualdad UTF8 evita aceptar nota Unicode equivalente pero con payload literal distinto. Prueba de conflicto sin overwrite, trim conserva bytes interiores; V1→V2 real volvió a pasar por impacto de igualdad/schema validation, no gate.
- Delta final: recibir notificación de zona por RunLoop.main (UI/MainActor) y excluir explícitamente abreviaturas/offsets aunque Foundation catalogue GMT. `build-notification.log` y `build-zone.log` exit0. `zone.xcresult` en curso al redactar este párrafo, selección RegisterWatering/CareRepository/WateringVM/DateNote, capturas0; solo cambios temporales/Domain/recepción afectados. Sin iteraciones/retries ni suite completa.
- Release inicial `release.log` BUILD SUCCEEDED exit0 y `release-audit.log`: símbolos/strings sin WateringTestFixture, flags nuevos ni WateringExpected.json; Info.plist sin puente/config API Debug. Esa build precede último guard de zona: recompilar Release final antes de cierre, no atribuirle fuentes nuevas.
- Evidencia seleccionada agregada: **54 escenarios distintos** =41unit+13UI, todos con último resultado Passed; `selected-evidence.json` conserva bundle y escenario. No sumar ejecuciones repetidas como cobertura nueva ni presentar aggregate como gate. Editor2/EditVM3/ListVM5/LocalPlant8/DetailVM restantes reutilizados por rutas pertinentes intactas; layout compartido final también ejercitado por UI larga. Las dos ejecuciones FAILED permanecen, con diagnóstico y reparación ligados a builds/manifiestos. `init.sh` no ejecutado.
- Rutas cambiadas completas: `DerivedData/evidence/quick-watering/changed-paths.txt` (incluye spec nueva/no versionada del planner pero no modificada por implementer). No nuevos MUST globales: decisiones persistencia/Unicode/tiempo pertenecen al ADR008, arquitectura y docs de dominio.

Validator independiente revisa arquitectura/escenarios/migración/payload7/diff/spec y ejecuta **un** `caffeinate -dius ./init.sh` en fuentes finales (o reutiliza gate válido idéntico, aquí no existe). No duplicar focalizadas que ya cubra ese gate. Matrices ampliadas/VoiceOver/SE/cámara física/API real no solicitadas, fuera de verificación habitual, no aprobadas ni bloqueos automáticos. Sin restauración de banner/retry entre procesos ni garantía contra daño físico/escritores multiproceso/downgrade. Evidencia y fallos históricos intactos.

## Resultado final y handoff efectivo

- La ejecución **original** `zone.xcresult` terminó SUCCEEDED **14/14** (13unit+1UI), exit0, cero fallos/skips. Cubre RegisterWatering3/CareRepository6/WateringVM4/DateNote1 en fuentes finales, incluidos guard de abreviaturas y recepción MainActor de cambio de zona. No se lanzó ejecución duplicada; se esperó la original.
- Release **final** `release-final.log`/`.exit`: BUILD SUCCEEDED exit0 con `caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData/quick-watering-release build`. `release-final-audit.log` corrobora símbolos/strings sin WateringTestFixture/flags/sidecar y plist sin claves puente API Debug. Auditoría con `xcrun nm -j`, `strings` y plistlib/assertions; no configuración privada leída.
- Manifiesto final de **96 inputs ejecutables**, `ready-source-hashes.json`, SHA256 **406a39c148fd45338ff8e49d03fda7fb147333e50272a9d1b7d27f0ae9c1426e**, contrastado sin drift después de tests/Release. Manifiestos anteriores se conservan para no atribuir evidencia antigua a fuentes nuevas. Las ejecuciones `zone.log`, `literal.log`, `regressions.log` y demás contienen las líneas de comando exactas con `-only-testing`; los prefijos/bundles anteriores permiten reproducir la selección, no ejecutar todo de nuevo por rutina.
- **54 escenarios distintos=41unit+13UI** con último resultado Passed. Evidencia por escenario/bundle en `selected-evidence.json`; reuso explicado arriba. Cero tests pendientes del implementer, sin procesos de tests propios activos al cerrar. Static final pasa plist/JSON/Domain typecheck/diff-check/spec hash, y capturas focalizadas inspeccionadas.
- `feature_list.json` actualizado exclusivamente en quick-watering a **passing**, `PROGRESS.md` registra cierre. No accepted. Fuentes/tests/harness ejecutable congelados para validator; cambios posteriores relevantes invalidan el gate que este obtenga. Único pendiente habitual: aceptación independiente y su gate completo. No se ejecutó init.sh ni baseline completa. No staging/commits/publicación/delegación.
