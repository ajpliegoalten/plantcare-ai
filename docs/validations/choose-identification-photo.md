# Validación independiente: choose-identification-photo

## Revalidación independiente de H1 — 2026-10-10: **accept** (alcance acotado)

Esta es la conclusión vigente. El **revise** anterior y sus fallos permanecen íntegros más abajo como evidencia histórica; no se reinterpretan como aprobados. `feature_list.json` permanece passing: solo el orquestador registra accepted.

### Evidencia nueva ejecutada por validator

- Sin xcodebuild/init activos antes de comenzar; focalizada y gate seriales, un único iPhone 17 Pro iOS 26.2 `B52F5194-6A81-4FAA-B094-B0D248084877`, apariencia light y texto large normal comprobados. Sin matrices ampliadas.
- Focalizada independiente del escenario reparado: **1/1**, 0 fallos/omitidas, TEST SUCCEEDED, exit 0. `DerivedData/evidence/photo-validator-repair-focused.log/.xcresult`, `photo-validator-repair-focused-summary.json`; original `Test-PlantCareAI-2026.10.10_13-10-39-+0200.xcresult`.
- Gate independiente posterior `caffeinate -dius ./init.sh`: **BUILD SUCCEEDED / TEST SUCCEEDED, 58/58 = 45 unit + 13 UI**, 0 fallos/omitidas, exit 0. `DerivedData/evidence/photo-validator-repair-gate.log/.xcresult`, `photo-validator-repair-gate-summary.json`; original `Test-PlantCareAI-2026.10.10_13-11-49-+0200.xcresult`. Incluye galería real/reselección, conservación de A/cancelación/error, colección y dos modelos/JPEG intactos tras relanzado, y todas las regresiones.
- Capturas **independientes** exportadas e inspeccionadas en `photo-validator-repair-focused-attachments`: `9248EFA6-08A7-4807-8D35-745C46451D29.png` (A preparada), `13B40118-5B01-4E2E-A5E3-81ADD859AECB.png` (sheet ausente/colección), `E06F2295-9784-42DA-95F7-BAA56A755F96.png` (reapertura vacía). Confirman foto → dismiss completo → nuevo modal sin foto. En log del gate: screenshot de reapertura vacía t48.74 y primer terminate después a t48.74, sin reinicio previo; descarte comprobado **en el mismo proceso**.
- plutil de proyecto, JSON feature/catalog, bash -n, git diff --check y SHA256 de spec nuevamente correctos. Spec intacta `c58b639da749a3ab5e5e11e6128fd4dc9487e46f4cc2ae76f9352ea4a1715c33`. Sin tests activos al cierre.
- Se reutilizan los Release Simulator/iOS y ANALYZE independientes de la revisión anterior: reparación limitada al test UI, no se presentan como builds recién ejecutados. El xcresult del nuevo gate implementer también fue contrastado: 58/58; no sustituye a las ejecuciones independientes nuevas.

### Cierre de H1 y revisión de reparación

**H1 resuelto.** El nuevo helper conserva waitForNonExistence(5), usa drag nativo desde zona visible de barra hacia 90% de pantalla, comprueba origen/destino y exige ambos botones del listado hittable. No reemplaza gesto por Cancelar, no hay retry, no aumenta timeout, no altera producto/binding ni elimina assertions. Conserva caso vacío y añade A preparada → gesto → colección interactuable → reapertura vacía antes de terminate, con ausencia de preview/loading/error e Identificar deshabilitado. Focalizada y gate independientes confirman que el drag suficiente completa el dismiss sobre el producto revisado; diagnóstico de recorrido insuficiente del helper anterior coherente con evidencia. No quedan findings bloqueantes ni repair brief activo.

Arquitectura, seguridad, docs y arnés conservan la evaluación favorable anterior: Domain Foundation-only, dependencias inyectadas, sin alta/IO PlantStore/IA/red propia ni secretos; fixtures solo Debug Simulator. Seed de dos PNG sintéticos por gate es un efecto conocido/documentado, sin borrar medios ajenos. Suite no debilitada.

### Alcance de aceptación y seguimiento manual

**accept del flujo implementado y verificable en simulador, no certificación de cámara física.** La spec permite pendiente físico explícito con veredicto acotado cuando no hay dispositivo compatible disponible. Cámara real, diálogos de permiso, vuelta de Ajustes y descarga iCloud **no ejecutados**; dobles/compilación iOS no equivalen a hardware. Modo avión tampoco probado. SE, texto aumentado, VoiceOver/Accessibility Inspector y matrices fuera de rutina, no ejecutados ni bloqueos automáticos.

Antes de afirmar cámara comprobada o de una demo física: en iPhone firmado localmente ejecutar los pasos de `docs/testing-identification-photo.md` (permiso solo al tocar cámara; aceptar/capturar/confirmar/repetir/cancelar; denegar/galería; Ajustes/conceder/reintentar; ninguna exportación a Fotos ni alta), registrar dispositivo/OS/resultados. Galería/gesto/reapertura quedan ahora comprobados en estándar. Sigue el riesgo explícito de materializar Data/UIImage original antes de límites; no garantía de memoria constante ni pipeline definitivo de save-plant.

Validator no modificó implementación, spec, feature_list, workspace ni estado accepted; sin stage/commit/push/PR/merge/GitHub. Siguiente acción: orquestador puede persistir accepted conservando estos límites y los resultados históricos.

---

2026-10-10 · validator openai/gpt-6.1-sol · skills feature-validator + ios-clean-mvvm.

## Veredicto: revise

Target: rama `feature/choose-identification-photo`, base/HEAD `a81e97d77cf986f758ef823c4317e3b2c6527e81`. Spec `docs/specs/choose-identification-photo.md` **intacta**, SHA256 `c58b639da749a3ab5e5e11e6128fd4dc9487e46f4cc2ae76f9352ea4a1715c33`. No implementación, modificación de spec, stage/commit/push/PR/merge ni GitHub. `feature_list.json` permanece passing; no accepted. Workspace preexistente preservado.

## Comprobaciones realmente ejecutadas

- Coordinación: handoff sin tests activos, comprobación de procesos antes de gate, ejecución serial en un solo iPhone 17 Pro iOS 26.2 `B52F5194-6A81-4FAA-B094-B0D248084877`, light/large normal. Sin matrices ampliadas.
- Gate independiente `caffeinate -dius ./init.sh`: BUILD SUCCEEDED, **TEST FAILED, exit 65**; **57/58 = 45/45 unit + 12/13 UI**, 1 fallo, 0 omitidas. Resultado original `Test-PlantCareAI-2026.10.10_12-00-51-+0200.xcresult`. Copias duraderas ignoradas: `DerivedData/evidence/photo-validator-gate.log`, `photo-validator-gate.xcresult`, `photo-validator-gate-summary.json`.
- Repetición focalizada sin editar fuentes: `xcodebuild ... -parallel-testing-enabled NO -only-testing:PlantCareAIUITests/PlantCareAIUITests/testIdentificationPhotoReplacementFailureCancellationAndEphemeralDraft test`: **0/1**, mismo fallo en línea 416, exit 65. `photo-validator-focused-gesture.log/.xcresult` y `photo-validator-focused-gesture-summary.json`; original `Test-PlantCareAI-2026.10.10_12-13-02-+0200.xcresult`.
- Release independiente genérico Simulator: BUILD SUCCEEDED; genérico iOS sin firma: BUILD SUCCEEDED y ANALYZE SUCCEEDED. Ambos binarios strings/nm sin símbolos/argumentos de fixtures y propósito de cámara correcto. Logs `photo-validator-release.log`, `photo-validator-device-release-analyze.log`, `photo-validator-device-audit.log`. Compilar iOS no prueba hardware.
- Proyecto plutil, JSON feature/catalog, bash -n, git diff --check, Domain Foundation-only swiftc typecheck y hash correctos (`photo-validator-static.log`). Sin procesos de prueba activos al cierre.
- Evidencia implementer contrastada con xcresult real: 58/58, 0 omitidas, no reinterpretada como resultado independiente. Capturas existentes inspeccionadas: final-photo-empty, progress, error-preserves-A, real-first, real-replacement, manual-empty-collection. Layout, textos y contraste adecuados; preview aspectFit y esquina blanca visibles. Attachments del gate independiente exportados en `photo-validator-all-attachments` para diagnóstico.
- En el gate independiente pasan picker **real** A/B/reselección, cancelación nativa conservando A, error/reemplazo con seam, ausencia de alta, persistencia de dos modelos/fotos tras relanzado y regresiones anteriores. No se afirma aprobado el escenario completo de cierre por gesto.

## Hallazgo bloqueante

### H1 — Gate y cierre por gesto no reproducibles

- **Severidad: High (verificación/escenario 3).**
- Evidencia: `PlantCareAIUITests/PlantCareAIUITests.swift:415–416`: swipeDown sobre NavigationBar seguido de waitForNonExistence(5) falla tanto en gate como aislado. Logs: `photo-validator-gate.log:4298`, `photo-validator-focused-gesture.log:417`. La jerarquía al fallo (`photo-validator-all-attachments/1025D805-BA73-4A37-BFC2-B20519BEC943.txt:28–67`) todavía incluye modal, barra, Cancelar y controles de foto.
- Por qué importa: no hay gate independiente verde y no queda demostrado el cierre/descartado por gesto exigido por spec. Que emptyCollectionTitle exista después no demuestra cierre: el listado subyacente también aparece en la jerarquía del modal. No atribuir definitivamente el problema a app o arnés sin diagnóstico del gesto.
- Cambio requerido: determinar si el gesto sintetizado completa el dismiss; reparar el helper E2E si el gesto no llega a completarse, o el ciclo de cierre/binding si un gesto válido no descarta. Mantener comprobaciones de desaparición real del modal, colección original y borrador vacío al reabrir **en el mismo proceso**. No sustituir gesto por Cancelar, quitar aserciones, aumentar tiempo arbitrariamente ni ignorar el fallo.
- Pasos sugeridos: capturar antes/después del drag y revisar grabación; usar drag nativo con origen visible comprobado en barra/zona superior del sheet y recorrido suficiente; comprobar modal ausente y colección interactuable; repetir con foto A preparada y reapertura inmediata sin foto. Si persiste con gesto válido, revisar binding sheet(item:) y close antes de tocar código.
- Verificación: focalizada repetida serialmente sobre fuentes reparadas; después `caffeinate -dius ./init.sh` íntegro, todas las 58 pruebas actuales sin fallos/omitidas (o más si se añade cobertura), capturas de dismiss/reapertura. Conservar estos resultados fallidos y documentar causa/cambio.

## Arquitectura, seguridad, alcance y arnés

Sin otros hallazgos bloqueantes. View → VM → casos de uso Domain ← adaptadores Data, composición en app; ContentView permanece delgado. Domain Foundation-only; ninguna dependencia de guardado/repositorio, IO PlantStore o cliente IA en la feature. Preparación ImageIO fuera de MainActor, límites de entrada/píxeles/salida, orientación/alfa y eliminación EXIF/GPS. Permisos solo por intención, estado reevaluado; Fotos sin autorización global. Fixtures Debug Simulator opt-in, ausentes en Release. Sin secretos ni nuevas dependencias; checklist de seguridad scoped sin problemas relevantes.

`init.sh` sigue ejecutando build + todas las pruebas y propaga fallos (exit 65 observado). Seed genera/importa dos PNG sintéticos locales; no suplanta cámara ni toca almacenamiento de plantas. Efecto conocido documentado: añade dos assets a Fotos del simulador por ejecución; limpiar solo estos desde Fotos, nunca resetear/eliminar datos ajenos. Cambios de expectativas antiguas de Añadir son coherentes con spec; escenarios anteriores preservados. ARCHITECTURE, riesgos, guía y handoff alineados; CONSTRAINTS documenta incidencia real del arnés vivo.

## Límites de aceptación y manual para usuario

La **cámara física NO fue ejecutada**, tampoco sus diálogos reales ni vuelta de Ajustes. Los dobles unitarios no equivalen a captura; dispositivos offline según handoff. La spec permite pendiente explícita y veredicto acotado si no hay hardware: esto no es el motivo de revise, pero una futura aceptación no debe afirmar verificados esos pasos. En iPhone compatible firmado localmente: Añadir sin prompt → Tomar foto solicita permiso → aceptar/capturar/confirmar/repetir/cancelar con A conservada; denegar y usar galería; Ajustes → conceder → reintentar; no guardar captura en Fotos ni planta. Registrar dispositivo/OS y resultados. Véase `docs/testing-identification-photo.md`.

Manual de galería: Añadir → elegir A → otra B → cancelar picker conserva B → cerrar/gesto → reabrir vacío; colección intacta, Identificar deshabilitado. El gesto queda pendiente de reparación/revalidación, no aprobado.

No iCloud ni modo avión probados. SE, texto aumentado, VoiceOver/Accessibility Inspector y apariencias adicionales fuera de rutina; no ejecutados ni bloqueos automáticos. Data/UIImage pueden materializar originales antes de aplicar límites; riesgo explícito aceptado por spec, no garantía de memoria constante ni pipeline de save-plant.

## Implementation Repair Brief

1. Reproducir H1 con focalizada en el mismo simulador estándar; revisar jerarquía/grabación y completar un gesto real, sin cambios simultáneos al arnés activo.
2. Corregir solo helper/gesto E2E si procede; si falla el dismiss real, corregir únicamente el ciclo de cierre del borrador. Conservar y reforzar assertions de modal ausente/reapertura limpia en mismo proceso con foto A. No tocar spec, hardware ficticio ni features siguientes.
3. Repetir focalizada serialmente y gate completo; inspeccionar capturas y actualizar PROGRESS/feature_list/handoff con causa y resultados reales. Preservar 57/58 y 0/1 históricos. Solicitar nueva validación independiente; orquestador decide accepted, no implementer.
