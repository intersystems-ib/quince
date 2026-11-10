# Competición · modelo 1.0.0

## Formato

Dos competiciones independientes: División de Honor y División de Honor Élite, diez clubes oficiales en cada una. Cada temporada tiene 18 jornadas regulares de cinco encuentros: 90 partidos, todos contra todos a dos vueltas, con nueve localías y nueve visitas por club. Un sorteo persistente baraja los clubes y fija las fechas una sola vez. Se conserva la semilla y nunca se repite el sorteo al recargar o reiniciar.

La alternancia estricta para todos los clubes resulta incompatible con todos contra todos: dos equipos con la misma secuencia alterna nunca podrían enfrentarse. Se usa el límite aceptado de **dos partidos seguidos** como local o visitante, con un calendario circular equilibrado y la vuelta desplazada.

El calendario comienza el sábado más cercano al 27 de septiembre y termina el domingo más cercano al 7 de junio siguiente. Las 18 jornadas se espacian en los fines de semana del intervalo; cada partido regular se sortea entre sábado y domingo. Se reserva el penúltimo fin de semana para semifinales y el último domingo para la final. Para 2026/27: inicio 26 de septiembre de 2026; semifinales 29/30 de mayo de 2027; final 6 de junio de 2027. Los números de jornada son idénticos para todos los clubes de una misma división.

Al finalizar los 90 partidos regulares se congela el orden de clasificación. Se crean las semifinales 1.º–4.º y 2.º–3.º, a partido único en campo del mejor clasificado. Solo al terminar ambas se crea la final, en campo del ganador con mejor puesto regular. El vencedor queda guardado como campeón. Hasta entonces la vista muestra espacios vacíos con sus fechas reservadas.

El formato de diez clubes y playoff de cuatro también figura en la [circular FER de División de Honor 2026/27](https://ferugby.es/Descargar/1793/circulares-26-27/91014/circular-5-normativa-division-honor-masculina-2026-27-2.pdf). El juego utiliza **el intervalo de fechas y la misma estructura para Élite solicitados por el usuario**, sin afirmar que reproduce todas las disposiciones ni las fechas exactas de esa circular.

## Resultados y clasificación

Los encuentros del club gestionado usan el motor completo y sus estadísticas de ensayos. Al finalizar, resultado, ensayos y puntos de clasificación se confirman en la misma transacción. Los partidos entre rivales se resuelven automáticamente al avanzar el día, con una simulación agregada determinista que utiliza la calidad de los XV y una pequeña ventaja local. No utiliza resultados deportivos reales ni modifica el presupuesto o la energía del club gestionado.

Reglas del juego para la tabla: victoria 4 puntos, empate 2, derrota 0, bonus ofensivo de un punto por ganar con al menos tres ensayos más que el rival y defensivo por perder por siete puntos o menos. Se ordena por puntos, diferencia de puntos, victorias, ensayos a favor y orden del sorteo. Son desempates simplificados del MVP. Una eliminatoria empatada se resuelve por un desempate a palos, mostrado aparte del marcador; no hay empate ni se modifica artificialmente la puntuación de los 80 minutos. No se implementa prórroga reglamentaria en este modelo.

El avance de fase exige resultados confirmados, no solo fechas vencidas. Reintentar la liquidación o el avance no duplica puntos, partidos, cruces ni ingresos. La tabla solo cuenta la regular; los playoffs no alteran el orden que determina sus localías.

## Partida existente y temporadas nuevas

La migración 8 archiva los amistosos anteriores sin borrar partidos, resúmenes, jugadores, presupuesto o fecha. Los encuentros ya vencidos del club gestionado permanecen pendientes con la fecha original, disponibles para jugar. No se fuerzan ni se inventan sus resultados. Los resultados de otros clubes anteriores a la fecha de la partida se resuelven automáticamente; por ello pueden aparecer partidos aplazados y distinto número de encuentros jugados.

Una instalación nueva empieza el 25 de septiembre de 2026, antes de la primera jornada. El día de gestión conserva su referencia interna de noviembre para mantener compatibilidad; no es un número de jornada. A partir del 1 de julio se crea el sorteo de la siguiente temporada, conservando el historial de competiciones y los mismos clubes por división. No se implementan ascensos ni descensos en esta ampliación.

La previsión de potencial toma la fecha de la final de la competición actual, en lugar del cierre genérico del 30 de junio. Los límites de desarrollo por edad siguen calibrados por año de entrenamiento.

## Interfaz y API

La navegación muestra **Competición**; `/calendario` redirige a `/competicion`. El selector permite cambiar de división y temporada. **Liga regular** contiene clasificación y partidos filtrables por jornada y club. **Fase final** contiene semifinales, final y campeón cuando corresponda. Solo se ofrecen controles de juego en encuentros del club gestionado.

- `GET /api/v1/competitions`: competiciones y metadatos del sorteo.
- `GET /api/v1/competitions/{id}`: tabla, 90 encuentros regulares, semifinales asignadas y final.
- `GET /api/v1/clubs/{id}/fixtures`: encuentros del club en su temporada actual, como local o visitante.

## Verificación

`Rugby.Test.Competition` comprueba emparejamientos únicos, 18 encuentros por club, una participación por jornada, 9/9 localías, rachas máximas de dos, fechas de fin de semana, persistencia del sorteo, apertura con 90 resultados, puntos y bonus, semifinales, final tras dos sorpresas con localía correcta, campeón idempotente, resolución automática de Élite, resultado real del motor y desempate a palos. Las pruebas revierten todos sus cambios.


El cálculo de puntos usa una única regla para la tabla, los partidos del usuario y los simulados: 4 por victoria, 2 por empate y 0 por derrota; +1 BO al ganador con diferencia de al menos tres ensayos; +1 BD al perdedor por siete tantos o menos. No basta con marcar cuatro ensayos. Un empate no otorga esos bonus y un mismo equipo no recibe simultáneamente BO y BD bajo esta regla. La referencia es el artículo 29 del [Reglamento de Partidos y Competiciones FER](https://ferugby.es/wp-content/uploads/2023/02/Reglamento-de-Partidos-y-Competiciones-FERugby.pdf); la [crónica oficial de la primera jornada de Élite 2026/27](https://ferugby.es/division-de-honor-elite-y-la-competicion-nacional-m23-levantan-el-telon-de-la-temporada-2026-27/) corrobora la asignación de cinco puntos a los ganadores con bonus.

La API devuelve `classification` con `basePoints`, `bonusOffensive`, `bonusDefensive` y `total` para local y visitante. El resumen del partido y los resultados de Competición muestran ese desglose; BO y BD se incluyen en PTS de la tabla. Amistosos, semifinales, finales y encuentros sin terminar no otorgan puntos de liga. Las clasificaciones de resultados existentes se recalculan al consultar, usando sus tantos y ensayos guardados; no se repiten partidos ni se duplican puntos, y se conservan el calendario y los cruces históricos.
