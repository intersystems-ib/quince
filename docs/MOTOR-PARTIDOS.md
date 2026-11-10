# Acciones y moral en el motor de partidos

El motor de encuentros en directo 1.1.0 calcula cada acción con participantes concretos. Las características guardadas del jugador nunca bajan por alinearlo fuera de posición. La posición ocupada determina en qué unidad participa; su posición natural y las secundarias determinan el coste de moral.

## Participantes

- Melé y touche: jugadores en campo que ocupan los puestos de delantero, del 1 al 8. El divisor continúa siendo ocho cuando falta un jugador por tarjeta. Los tres cuartos no intervienen en estos valores.
- Ruck: los tres delanteros más cercanos al actor de cada equipo. La protección del portador también influye en el ataque.
- Juego abierto: portador y sus dos apoyos próximos frente a los tres defensores próximos. Se utilizan las coordenadas simuladas, con desempates estables por posición.
- Transformación y golpe a palos: el jugador en campo con mejor capacidad efectiva de patada. Las patadas y drops en juego abierto utilizan la capacidad del actor que toma esa acción.
- Infracciones en juego abierto: disciplina de los defensores próximos; la tarjeta, si procede, se asigna a uno de esos participantes.

Los suplentes, jugadores sustituidos y excluidos no participan. Una expulsión no mejora la media de la melé por eliminar un jugador débil. Los conjuntos esperados conservan los huecos que no pueden cubrirse.

## Características utilizadas

Los perfiles combinan características individuales: melé (60 % técnica, 30 % fuerza, 10 % resistencia); touche (65 % técnica, 20 % manejo, 15 % fuerza); contacto (50 % ruck, 30 % fuerza, 20 % maul); apoyo ofensivo (manejo, pase, estructura de ataque, agilidad y decisiones); portador (velocidad, agilidad, fuerza, manejo y decisiones); defensa (55 % placaje, 25 % lectura defensiva, 10 % fuerza, 10 % agilidad).

La energía, el promedio de forma guardado y la moral modifican el rendimiento efectivo, sin reescribir las características. Las indicaciones de estilo, ritmo y presión siguen vigentes; la presión defensiva no añade fuerza a la melé o a la touche. Los entrenamientos de fuerza, agilidad, pase, ruck, maul y lectura defensiva tienen ahora efecto en sus acciones correspondientes.

## Moral por posición

- Puesto natural: sin pérdida.
- Puesto secundario declarado: tres puntos de moral.
- Otro puesto dentro del mismo grupo (delanteros o tres cuartos): ocho puntos.
- Puesto del otro grupo: quince puntos.

Se aplica al iniciar el encuentro y al entrar un suplente, con límite inferior cero. El motor guarda la penalización aplicada y solo ajusta la diferencia si cambia la posición: no se acumula cada veinte segundos, al descanso, al volver de una amarilla o al recuperar una sesión. El suplente sin entrar no pierde moral por su mera convocatoria. Al finalizar, una victoria recupera la moral de toda la plantilla al 100 %, una derrota resta cinco puntos y el empate conserva la moral del encuentro. Se aplican las [reglas comunes de moral e inactividad](MORAL.md). No hay multiplicador adicional de características por posición. Se mantienen las restricciones de seguridad existentes para especialistas de primera línea.

## Persistencia y auditoría

Cada evento de acción guarda en `result.contest` el actor, los identificadores de los participantes, perfil, valor de ataque y defensa y probabilidad utilizada en el duelo. Los eventos de control y cambio de periodo no representan duelos. El flujo continúa por la interoperabilidad existente; no se añade una pantalla de auditoría.

Los partidos terminados no se recalculan. Los encuentros guardados con motor 1.0.0 continúan desde su siguiente paso con 1.1.0, manteniendo reloj, marcador, tarjetas y jugadores, y registran `previousEngineVersion`. Los partidos agregados de otros clubes mantienen su simulación resumida; estas unidades describen las acciones del encuentro jugado en directo.
