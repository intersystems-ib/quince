# Alineación flexible y lesiones

Los titulares y las sustituciones admiten intercambios de puestos, incluidos talonadores y pilares. Se mantienen las comprobaciones de pertenencia al primer equipo, disponibilidad, duplicados y límite de ocho cambios. El banquillo no exige un especialista distinto para cada puesto de primera línea.

La moral al entrar al campo pierde 3 puntos si se ocupa una posición secundaria, 8 en otro puesto de la misma línea y 15 al pasar entre delanteros y tres cuartos. No se modifican las características permanentes. La penalización se aplica una vez y la pantalla de alineación la anticipa.

## Catálogo

Duraciones de la simulación, expresadas en semanas completas. Cada baja recibe un plazo concreto dentro de su intervalo; el grado distingue variantes de una misma lesión.

| Lesión | Grado | Semanas |
| --- | --- | --- |
| Contusión | 1 / 2 | 1 / 1–2 |
| Sobrecarga muscular | 1 | 1–2 |
| Contractura muscular | 1 | 1–2 |
| Esguince de tobillo | 1 / 2 / 3 | 1–2 / 3–5 / 8–12 |
| Lesión de fibras musculares | 1 / 2 | 1–2 / 3–6 |
| Rotura muscular | 3 | 10–16 |
| Lesión de aductores | 2 | 2–4 |
| Lesión de isquiotibiales | 2 | 3–6 |
| Esguince de hombro | 2 | 2–4 |
| Luxación de hombro | 3 | 6–10 |
| Conmoción cerebral | 2 | 2–4 |
| Lesión de menisco | 3 | 6–10 |
| Fractura de clavícula | 3 | 8–12 |
| Fractura de tobillo | 3 | 12–18 |
| Rotura de ligamento cruzado | 3 | 28–40 |
| Rotura del tendón de Aquiles | 3 | 24–36 |

La plantilla incluye una lista desplegable con las veinte variantes. La ficha, el entrenamiento y el selector de alineación muestran la lesión y la fecha de alta. La ficha conserva también el historial de lesiones curadas.

## Aplicación y recuperación

Las lesiones pueden ocurrir en partidos y sesiones de entrenamiento, tanto en el primer equipo como en cantera y en los clubes automáticos. Las leves son más frecuentes. La edad y la fatiga elevan el riesgo; la intensidad del entrenamiento lo aumenta y la calidad del preparador físico o entrenador de cantera lo reduce. El descanso y los jugadores que ya están de baja no generan lesiones de entrenamiento.

El modelo de partido 1.1.0 reduce un 75 % la probabilidad base: de 0,00018 a 0,000045 por jugador y paso de veinte segundos. El riesgo sigue ponderado por edad y cansancio y es compartido por el directo y los encuentros automáticos. Con treinta jugadores sanos a energía completa, la referencia teórica pasa de unas 1,30 a 0,32 lesiones por partido; el cansancio puede elevarla. Es un ajuste de equilibrio del juego, no una estimación clínica. Las sesiones de entrenamiento, tipos de lesión, gravedad, duración, bajas ya existentes y pausas se conservan.

Una lesión de partido retira al jugador de las acciones y del campo inmediatamente, deja narración del incidente y permite sustituirlo con balón muerto, consumiendo un cambio. El rival utiliza sus suplentes disponibles; una expulsión o exclusión temporal sigue sus propias reglas. El lesionado no puede volver al encuentro ni ser sustituido dos veces. Los encuentros automáticos aplican el mismo catálogo, bajas y sustituciones.

Durante la baja el jugador recupera energía y no mejora atributos por entrenamiento. Su evolución por edad continúa. Al alcanzar el día de alta vuelve a estar disponible y la lesión pasa al historial una sola vez. Recuperar energía no adelanta el alta. Las fechas son absolutas y continúan entre temporadas. Los agentes libres también completan su recuperación al avanzar los días. Los retirados nunca vuelven a estar disponibles por esta regla.

La selección es determinista con la semilla de la partida y el estado del partido o día de entrenamiento. Los reintentos no repiten lesiones ni días de recuperación. La previsión de potencial no genera lesiones futuras ni modifica al jugador real.

Se almacenan dentro de los datos del jugador y de los encuentros. Las operaciones siguen la entrada API y la producción de interoperabilidad existente; los resultados de entrenamientos y mensajes del trabajador contienen los cambios. El catálogo está disponible mediante `GET /api/v1/injury-types`.

## Verificación

Los 36 grupos IRIS han pasado, incluido el grupo de lesiones. Se comprobaron selección flexible, moral sin acumulación, duración, exclusión del campo, sustitución única, persistencia de checkpoints, descanso durante la baja, alta exacta, historial, retirados y rivales. La integración HTTP verificó bajas de primer equipo y cantera, bloqueo de alineación, elección de sustituto, seis días restantes tras avanzar uno, ausencia de mejoras durante la baja y reintento del avance sin duplicados. La revisión visual confirmó las bajas en plantilla y ficha y un talonador en el puesto de pilar con penalización de moral. Las pruebas se ejecutaron en una instancia desechable; las evidencias se guardan fuera del proyecto.


## Situación y jugadores no disponibles

La columna «Situación» muestra una cruz roja para un jugador lesionado y permanece vacía en los demás casos. Está disponible en plantilla, entrenamiento y alineación; el icono identifica al jugador y muestra los detalles de la lesión al pasar el cursor.

En alineación, los jugadores no disponibles quedan separados de las opciones de selección. Los suplentes que dejan de estar disponibles salen automáticamente del banquillo y pasan a «No disponibles». Un titular de baja permanece en su puesto marcado con la cruz hasta que el usuario elige un sustituto; entonces pasa a esa sección sin ocupar una plaza de suplente. Los no disponibles por otras causas se muestran con su motivo, sin la cruz de lesión. La sección se obtiene del estado de los jugadores y no crea una nueva categoría deportiva.

El servidor limpia también el banquillo al guardar y validar, al actualizar la disponibilidad tras entrenamientos y lesiones, y al consultar alineaciones antiguas. La lectura de una alineación antigua devuelve una copia normalizada sin escribir cambios. No se omiten los errores de jugadores ajenos o desconocidos. Un titular no disponible sigue impidiendo jugar hasta ser reemplazado. Si la baja afecta a un capitán del banquillo, se elige un convocado disponible; al reemplazar un capitán titular lesionado, la selección propone a su sustituto. Un jugador recuperado vuelve a estar elegible pero no se alinea automáticamente.
