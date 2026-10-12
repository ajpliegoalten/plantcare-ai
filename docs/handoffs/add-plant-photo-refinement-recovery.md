# Recuperación dirigida B1 — add-plant-photo-refinement

Usuario autoriza diagnóstico/arranque del simulador acordado sin borrar datos y retorno a validator/gate completo; commit local solo tras accept. Se preservan informe BLOCK/log/bundle fallidos originales. Sin cambios de producto/tests/harness/specs ni reinicio de otros dispositivos/servicios compartidos.

## Hipótesis y diagnóstico

- Error original observado: installApplication Invalid device state/Mach−308 (server died), pérdida de testmanagerd antes de bootstrap funcional; no assertion de producto ni causa profunda probada.
- Diagnóstico actual 2026-10-12 18:04:59: UDID00BBB7EC-8DF7-400C-A08A-9D3C8818D886 iPhone17Pro/iOS26.2 aparece **Shutdown**, sin xcodebuild/xctest competidor según basename exacto de ps. Probes de appearance/content_size en ese estado devuelven unknown, no medida de tamaño/tema.
- Log de host acotado17:57:45–18:00 registra a17:58:51.050 CoreSimulator SimError405/NSMach−308 para postDarwinNotification; coincide con gate install/bootstrap, pero no demuestra origen último ni quién detuvo dispositivos.
- Hipótesis diagnóstica explícita: sesión runtime/testmanager interrumpida o inválida durante bootstrap; nuevo arranque de la instancia acordada recuperará instalación/conexión de ambos runners. No se modifica producto para un fallo de infraestructura; no repetir gate sin primero comprobar esta recuperación.

## Cambio de entorno realizado

- Root ya Shutdown: solo `simctl boot <UDID>` + `bootstatus -b`, sin erase/uninstall/delete/shutdown all/killall ni manipular clones/servicios globales.
- `simctl ui <UDID> appearance light`, `content_size large`; probes posteriores devuelven **light/large**, ahora sí medición independiente del contexto normal. bootstatus completó3s.
- Snapshots devices-before.json/devices-recovered.json: solo root cambió Shutdown→Booted; todos los demás dispositivos conservaron estado. No borrar media ni almacenamiento local.
- Logs/snapshots en DerivedData/evidence/add-plant-photo-refinement/recovery/; host-runtime-errors.log es diagnóstico local ignorado, no publicado en GitHub ni commiteado.

## Siguiente comprobación mínima

- Reutilizar build-for-testing válido del gate fallido, fuentes140inputs exactos. Selección 1unit LoadPlantPhotos/testInitialProjectedOnceDiscriminatedCollisionStableAbsoluteOrder +1UI Localization/testEnglishPreferenceFallsBackToSpanishInsteadOfKeys con5workers XCTest/parallel YES sobre mismoUDID, screenshots0. Comprueba runner de unidad y de UI/instalación/testmanager, no rerun funcional amplio ni retry automático.
- Si arranca y pasa, devolver al mismo validator independiente para nuevo gate completo explícitamente justificado por recuperación de entorno y ausencia de evidencia válida de ambas fases. No sustituir gate por esta selección mínima ni sumar2 a41 como cobertura nueva.
- Diagnóstico ejecutado una vez: `bootstrap-check.xcresult`, log/exit/summary en recovery: **2/2 Passed exit0**, cero fallos/skips/expected failures. Ambos runners arrancan/ejecutan con modo paralelo5workers;140inputs públicos siguen idénticos al manifest final. Sin xcodebuild/xctest activos al cierre. No convertir el gate fallido anterior en aprobado ni sumar esta selección diagnóstica como cobertura nueva.
- Retorno al mismo validator para nuevo gate completo sobre fuentes intactas; preservar informe BLOCK y registrar nueva revisión V2 separada. Gate nuevo justificado porque entorno fue recuperado y la ejecución fallida no acreditó ningún escenario funcional/Photos serial; no rerun ciego de fuentes unchanged para ocultar assertions.
