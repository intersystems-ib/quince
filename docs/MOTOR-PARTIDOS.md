# Motor de partidos

[Español](MOTOR-PARTIDOS.md) · [English](en/MOTOR-PARTIDOS.md) · [Français](fr/MOTOR-PARTIDOS.md) · [Índice](README.md)

Las acciones usan a los participantes adecuados: delanteros en melé, maul y ruck; receptores, pasadores, pateadores y defensores en juego abierto. Influyen sus atributos, energía, moral y táctica. Cambiar de puesto dentro del mismo grupo no reduce moral ni atributos; cruzar entre delanteros y tres cuartos puede reducir temporalmente la moral.

El partido conserva semilla, reloj, balón, coordenadas, estadísticas y comandos. Los jugadores se mueven según fase y posesión; la animación interpola los estados recibidos.

Las velocidades comparten las mismas reglas deportivas. Se pausa manualmente, al descanso y ante una lesión propia; continúa al elegir velocidad. Los cambios se aplican con balón muerto y se revalidan antes de ejecutarse.

Véanse [Reglas](REGLAS.md), [Tácticas](TACTICAS.md), [Tarjetas](DISCIPLINA.md) y [Lesiones](LESIONES.md).

En la previa se elige **Visualizar** (partido en directo con controles de velocidad) o **Resultado**. Resultado simula la primera parte al iniciar, se detiene en el descanso para sustituciones y tácticas y permite completar la segunda con **Ir al final**. Usa el mismo motor, incluidas lesiones, tarjetas, tiempo añadido, estadísticas y liquidación económica; no reproduce pausas intermedias. El modo queda fijado al iniciar y se conserva al recargar.

Las alineaciones usan la mayor media por puesto y un banquillo equilibrado de cinco delanteros y tres tres cuartos, con cobertura de posiciones y ajuste a los disponibles. Durante el partido priorizan sustituir lesionados y jugadores cansados por los mejores relevos compatibles, hasta ocho cambios. Las [tácticas](TACTICAS.md) se adaptan al marcador, tiempo y energía, tanto en directo y Resultado como en la simulación abreviada.
