# Comparativa y tácticas del partido

[Español](TACTICAS.md) · [English](en/TACTICAS.md) · [Français](fr/TACTICAS.md) · [Índice](README.md)

La previa compara las 17 características del XV elegido y permite consultar delanteros (8) y tres cuartos (7). Muestra los escudos, la media, la energía y la moral. Los valores son medias aritméticas de los titulares del grupo, sin suplentes ni redondeos internos. La interfaz muestra enteros. Consultar la previa no inicia el encuentro.

El rival compara sus unidades con las contrarias para elegir juego a la mano, equilibrado o al pie. Valora pase, manejo, ataque, velocidad, agilidad, placaje, lectura defensiva, formaciones y su mejor pateador. Usa valores efectivos que incluyen energía, moral y forma; una exclusión reduce la fuerza de la unidad. Las ventajas se comparan proporcionalmente, con recepción especialista frente al pateador, para conservar sentido con distintas escalas de atributos. El cansancio, la resistencia, la disciplina y las ventajas relativas frente a cada rival condicionan ritmo, presión y prioridad en golpes. La presión baja reduce el desgaste y la eficacia defensiva; la alta aumenta ambos. A ritmo normal, la baja consume aproximadamente un 18 % menos de energía que la normal. No modifica los atributos guardados ni las decisiones del usuario.

La IA revisa su plan al inicio y en paradas del juego, normalmente cada cinco minutos. Un cambio de marcador, una exclusión o un umbral de cansancio puede adelantar la revisión, con un minuto de margen; el descanso y las sustituciones permiten revisarla antes. Cada equipo conserva su propia evaluación. Los cambios pasan por la cola habitual de comandos y quedan explicados en el minuto a minuto, sin modificar las decisiones del usuario ni consumir números aleatorios.

En los últimos veinte minutos, el equipo que gana reduce el ritmo y busca controlar el territorio. Si pierde por tres puntos o menos, prioriza los palos; con una diferencia mayor busca el ensayo mediante touch o juego rápido, según sus fortalezas. Con energía suficiente puede acelerar y aumentar la presión; con energía inferior a 50 reduce el ritmo y por debajo de 45 también la presión, aunque vaya perdiendo.

Los encuentros entre equipos automáticos mantienen la simulación abreviada: las revisiones se concentran en unas pocas ventanas de anotación y el inicio de cada parte. Reutilizan la comparación previa y ajustan ritmo, presión y prioridad con el marcador acumulado y la energía de los jugadores presentes, sin volver a calcular sus 17 atributos. No ejecutan el motor visual ni guardan un historial de evaluaciones: sólo la última de cada equipo.

La **prioridad en golpes de castigo** se elige en la alineación, el informe técnico y las indicaciones durante el partido:

- **Según el contexto:** valora marcador, tiempo, alcance del pateador y fortalezas de ambos equipos.
- **Asegurar puntos:** prioriza tiros a palos alcanzables; fuera de alcance busca touche.
- **Buscar el ensayo:** gana territorio mediante una patada a touche y conserva el saque.
- **Jugar rápido:** busca continuidad con un portador disponible; influyen sus atributos, energía y los defensores que participan. Puede ganar metros, lograr un ensayo o perder la posesión.

La probabilidad del tiro contempla distancia, ángulo y rendimiento efectivo del pateador. Las elecciones quedan en la narración y la auditoría del encuentro. Un golpe fallado que sale por la zona de marca da paso a un saque de 22. Las tácticas sin prioridad explícita utilizan «Según el contexto». Los encuentros automáticos ponderan las oportunidades de ensayo y los intentos a palos según la prioridad del rival.

Referencias: [golpes de castigo, World Rugby](https://passport.world.rugby/laws-of-the-game/laws-by-number/20-penalty-and-free-kick/) y [saques de reinicio](https://passport.world.rugby/laws-of-the-game/laws-by-number/12-kick-off-and-restart-kicks/).

Cada parte continúa con el tiempo cumplido hasta que el balón queda fuera de juego, respetando conversiones y golpes pendientes. En juego abierto, el equipo que gana busca la touche para cerrar; el que pierde evita ceder el balón con patadas de despeje. El reloj muestra en rojo el tiempo añadido. Las exclusiones, el cansancio y los minutos jugados siguen contando durante ese tiempo. La segunda parte comienza en el minuto 40 de la visualización. [Regla 5, World Rugby](https://passport.world.rugby/laws-of-the-game/laws-by-number/5-time/).
