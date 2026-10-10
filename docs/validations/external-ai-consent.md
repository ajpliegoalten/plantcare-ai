# Validación independiente — external-ai-consent

2026-10-10 · validator `openai/gpt-6.1-sol` · skills `feature-validator` e `ios-clean-mvvm`.

## Veredicto: accept

Sin hallazgos bloqueantes de comportamiento, arquitectura, seguridad, alcance o documentación. No se requiere repair brief. Este es un veredicto independiente, **no una transición persistida a accepted**: `feature_list.json` permanece `passing`; corresponde al orquestador registrar la aceptación y realizar la entrega local autorizada.

## Objetivo y contrato

- Worktree exclusivo `/Users/antonio.pliego/Proyectos/plantcare-ai-worktrees/external-ai-consent`.
- Rama comprobada `feature/external-ai-consent`; HEAD/base `a68a09f6899c407362dfa5413dec51f34570e7d3`.
- Contrato aprobado: `docs/specs/external-ai-consent.md`, SHA256 **4bea3b28709fe8adc1a46635edc9893e6bb2312b33391f880d990c0ae6c89cb3**, comprobado e intacto. Su redacción histórica de propuesta no sustituye la aprobación explícita recibida del usuario.
- Revisados diff rastreado, fuentes/tests nuevos no rastreados, proyecto/localización, handoff, PROGRESS/feature_list, arquitectura, restricciones, diseño, brief, dominio, riesgos y ADR 003. Dependencia `choose-identification-photo` aceptada.

## Comprobaciones independientes ejecutadas

1. Confirmación inicial de ausencia de procesos de pruebas activos. Una sola ejecución de `caffeinate -dius ./init.sh`, sin editar el arnés ni iniciar pruebas simultáneas. Al continuar esta sesión se esperó la salida del proceso original mediante notificación de proceso del sistema, **sin lanzar gate duplicado**.
2. **BUILD SUCCEEDED / TEST SUCCEEDED: 70/70 (54 unitarias + 16 UI), cero fallos, cero omitidas**. Xcode 26.2, iPhone 17 Pro iOS 26.2, UDID `B52F5194-6A81-4FAA-B094-B0D248084877`, apariencia clara/texto normal. Pruebas 15:24–15:39 (+0200).
   - `DerivedData/evidence/consent-validator-gate.log`
   - `DerivedData/evidence/consent-validator-gate-summary.json`
   - `DerivedData/Logs/Test/Test-PlantCareAI-2026.10.10_15-24-15-+0200.xcresult`
3. Build **Release genérico Simulator** independiente, directorio separado `DerivedData/ConsentValidatorRelease`, sin usar el simulador de pruebas: **BUILD SUCCEEDED**. Auditoría `strings`/`nm`: ausentes flags de consentimiento/foto, tipos de fixture y `testInvocationCount`.
   - `DerivedData/evidence/consent-validator-release.log`
   - `DerivedData/evidence/consent-validator-release-audit.log`
4. **ANALYZE SUCCEEDED**, Release Simulator: `DerivedData/evidence/consent-validator-analyze.log`.
5. `plutil -lint` del proyecto, JSON de catálogo/feature_list, `bash -n init.sh`, `git diff --check` y typecheck Foundation-only de Domain + repositorio Data correctos: `DerivedData/evidence/consent-validator-static.log`.
6. Exportación e inspección visual de capturas de la ejecución independiente en `DerivedData/evidence/consent-validator-gate-attachments/` (manifest conserva nombres):
   - Aviso completo y acciones: `2B5FBFBB-8D64-4AC9-816F-0EA5594F7786.png`.
   - Error con A conservada y contador 0: `EC4ACE94-BE6C-4039-B975-D44166E56DFA.png`.
   - Indisponibilidad de continuación de producción, sin spy: `A86CAB97-CD9F-4E1E-8A63-63FEEF260813.png`.
   - Consentimiento recordado tras relanzamiento/nueva intención, contador 1: `49B38629-D72A-4AE9-B80A-D43B777715E0.png`.
   Texto legible, alcance completo, aclaración de ausencia de envío actual, acciones inequívocas y sin claves crudas; tokens y barras nativas acordes a DESIGN. También se inspeccionaron las capturas equivalentes finales del implementer antes de disponer de las propias.

Baseline 58/58 y focalizada 15/15 del implementer inspeccionadas, **no repetidas como ejecuciones separadas**: el gate independiente incluye todas sus clases y los tres E2E nuevos. No se atribuye al validator la apertura manual aislada del implementer; startup y recorrido propio se ejercitaron mediante XCUITest.

## Cobertura del contrato y calidad

| Escenarios de spec | Resultado y evidencia |
| --- | --- |
| 1–2: intención explícita y primer aviso | UI comprueba botón deshabilitado sin foto, ausencia de aviso al preparar A, contador 0 y texto/acciones del aviso. |
| 3: cancelar, gesto, abandono | E2E cancela y descarta por gesto conservando A/contador 0; termina esperando y vuelve a pedir aviso. VM invalida intención y respuestas tardías al cerrar. |
| 4–5: aceptar una vez y recordar | Domain y VM comprueban registro antes de invocar y duplicados; E2E contadores por intención, reapertura sin envío, relanzamiento con misma suite y suite nueva. Producción devuelve indisponibilidad, no candidatas ni red. |
| 6: alcance inválido y fallos | Domain prueba destinatario/versión distintos y errores de lectura/escritura; Data valida estructura estricta, Boolean y versión fraccionaria, reparación Boolean→Int y nueva instancia. VM conserva A/reintenta; UI comprueba error de lectura con cero. |
| 7: cancelación y duplicados | Checks antes/entre lectura, registro e invocación; pruebas de cancelación previa/inmediata y durante suspensión, cierre durante lectura/registro y publicación tardía. Una aceptación explícita ya registrada puede permanecer, conforme spec. |
| 8: barrera común y aislamiento | Continuaciones instrumentadas de foto/texto bloqueadas sin consentimiento. E2E sin spy conserva dos modelos/JPEG completos mediante `--storage-verify` tras relanzar sin reseed/desinstalar. |

Clean Architecture + MVVM respetada: Presentation→Domain←Data; App comparte repositorio/caso de uso e inyecta continuación. Vista sin IO/repositorio, Domain sin UI/persistencia/proveedor; actor Data maneja solo preferencia mínima. No cambios a PlantStore, alta ni cliente IA ficticio. Regresiones anteriores/picker real permanecen, sin eliminar tests ni debilitar asserts; cambios de expectativas de Identificar corresponden al contrato aprobado. `init.sh` ejecuta build/test y propaga errores, termina sin servicios, y quedó intacto.

## Seguridad y notas no bloqueantes

Checklist de seguridad aplicado al diff y soporte directo: **sin problemas relevantes bloqueantes**. Fuente→control→sink revisado: selección efímera→barrera con aceptación exacta→continuación indisponible; no existe sink HTTP. No credenciales, endpoint, dependencias nuevas ni logs de fotos/contexto. Registro limitado a destinatario/versión; fixtures UUID opt-in Debug Simulator, sin borrar dominio estándar; exclusión Release verificada independientemente. Contador mide invocaciones, no solicitudes reales. Permisos/auth de servidor, SSRF y abuso de API no aplican al alcance sin red.

Notas/límites reales:
- `prototype-external-ai` es provisional: antes de conectar transporte se debe fijar destinatario real, actualizar texto y renovar alcance. Cada futura operación, también textual, debe cruzar la barrera y probar su transporte; no basta una bandera UI.
- UserDefaults no garantiza transacción durable ni apagado abrupto. Registro perdido/malformado exige confirmar otra vez; no se verificó fallo físico de disco ni apagado abrupto.
- No proveedor/API real, retención externa, cumplimiento legal, cámara física o dispositivo físico verificados en esta entrega.
- SE, texto aumentado/máximo, VoiceOver/Accessibility Inspector y matrices de apariencia: fuera de verificación habitual; no ejecutados ni bloqueos automáticos.

## Documentación y siguiente paso

ARCHITECTURE, CONSTRAINTS, dominio/riesgos, ADR 003 y guía de pruebas reflejan comportamiento y límites reales, sin modificar docs históricas ni spec aprobada. Handoff permite continuar y distingue passing de aceptación.

El orquestador puede persistir `accepted` con este informe y evidencia y efectuar el commit local autorizado, incluyendo la spec preexistente no rastreada **sin editarla**. No hace falta reparación. Este validator solo añadió este informe y evidencia a PROGRESS: no producto/spec, stage, commit, push, PR, merge ni GitHub. Logs/xcresult permanecen en DerivedData ignorado. Antes de red, aplicar la renovación descrita en ADR 003; no se inició otra feature.
