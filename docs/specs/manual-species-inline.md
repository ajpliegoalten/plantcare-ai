# manual-species — delta inline autorizado (2026-10-11)

Ronda sobre `3cdbc15`, autorizada explícitamente por el usuario. La spec histórica
`manual-species.md` se conserva con SHA256
`4127089b20d658278d270676e1191ac73ec78620e2736d5267169558a7717710`.
No se hereda su aceptación para esta ronda.

## Alcance y decisiones
- Sin nuevo modal: manual es opción humana en «Otras posibilidades», con el mismo
  borde, check, selección exclusiva y aspecto de las candidatas, sin atribuirla a IA.
- Disponible siempre con foto preparada, antes de IA o después de error,
  insuficiencia o resultado sin alternativas. Cero consulta necesaria.
- Seleccionar manual activa campo inline nativo vertical coherente con EditPlant.
  Nombre común o científico, solo trim de extremos, sin límites/autocomplete/taxonomía.
- Un único «Confirmar especie» confirma la opción activa y lleva al resumen actual;
  no genera cuidados ni da de alta. Elegir candidata no confirma ni consulta.
- Cambiar identidad manual precarga inline sin borrar identidad previa. Cancelar
  edición explícito sustituye el gesto del antiguo editor y restaura selección previa.
  Pasar a candidata descarta texto no confirmado, conserva identidad hasta confirmar.
  Volver expresamente a IA desde resumen conserva el contrato de reconfirmación.
- Foto/revisión/sesión/closed/busy/cámara y generaciones siguen protegiendo acciones
  y respuestas antiguas; B limpia al publicarse, reemplazo fallido conserva A.

## Arquitectura y escenarios
Presentation: VM de foto posee sesión manual y selección exclusiva; selector y campo
inline comparten confirmación. Domain/caso puro/source y composición App intactos;
sin Data nueva ni IO. Alcance excluye generate-care-sheet/save-plant y rediseño global.

Comprobar exclusión IA↔manual sin confirmar, vacío/blancos/trim, sin IA/error/
insuficiencia/sin alternativas, teclado/texto largo/scroll, resumen/procedencia,
edición/precarga/cancelación no destructiva, vuelta IA/reconfirmación, foto/cierre/
relaunch/late callbacks y aislamiento de dos plantas persistidas. Adaptar las pruebas
de modalidad conservando garantías; inspección visual real inline y contraste con IA.
Implementer: focalizadas por impacto; validator: gate final independiente pendiente.
