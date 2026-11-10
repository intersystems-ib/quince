# Reglas y simplificaciones · motor 1.0.0

Este MVP es una simulación de gestión, no una reproducción completa del reglamento.

## Fuentes oficiales consultadas

Consultadas el 7 de noviembre de 2026, antes de fijar la implementación:

- [World Rugby, ley 3: equipo](https://passport.world.rugby/laws-of-the-game/laws-by-number/3-team/): quince jugadores, hasta ocho suplentes, cambios con balón muerto y cobertura de primera línea.
- [World Rugby, ley 5: tiempo](https://passport.world.rugby/laws-of-the-game/laws-by-number/5-time/): dos mitades de cuarenta minutos y cierre de periodo cuando el balón queda muerto, con excepciones reglamentarias.
- [World Rugby, ley 8: puntuación](https://passport.world.rugby/laws-of-the-game/laws-by-number/8-scoring/): ensayo 5, transformación 2, golpe a palos y drop 3.

## Modelo temporal

Cada acción representa 20 segundos de juego. Primera parte → descanso → segunda parte → final. Al alcanzar 40 o 80 minutos el árbitro declara muerto el balón al terminar la acción; si hay una transformación pendiente, se resuelve antes del cierre, con el reloj en 40:00/80:00. No se implementan las excepciones completas de la ley 5, tiempo perdido ni prórroga. El descanso pausa el partido con velocidad cero y recupera 7 puntos de energía a quienes estén en el campo. La segunda parte espera a que el usuario seleccione una velocidad.

El motor representa reinicio, juego abierto, ruck, melé, touche, golpe de castigo, transformación y balón muerto. Una interrupción arbitral simplificada, al menos cada 120 segundos si la fase es ruck, limita la espera para sustituciones y tácticas. Las fases fijas también son puntos seguros. No se aplican cambios en un ruck en curso. La velocidad se aplica en el siguiente ciclo, antes de resolver nuevas acciones y después de acumular el tiempo transcurrido a la velocidad anterior. Pausa (0) elimina el crédito pendiente y congela reloj, energía, posiciones y aleatoriedad. No se acumula tiempo mientras está pausado. Una lesión del equipo gestionado provoca pausa automática y un aviso, tanto si juega en casa como fuera; la lesión rival no pausa. En balón muerto se pueden confirmar sustituciones y tácticas durante la pausa. Se reanuda seleccionando x1, x5, x20 o x60.

## Geometría y reinicios

El esquema de alineación sigue la imagen de referencia aportada: primera línea 1–2–3; segundas líneas 4–5; alas de la melé 7 a la izquierda y 6 a la derecha en esta vista; 8 cerrando. Detrás se sitúan 9, 10, centros 12 y 13, alas 11 y 14 y el zaguero 15. La referencia ve al equipo desde atrás, atacando hacia arriba. En el campo horizontal de la aplicación se conserva esa distribución rotada 90 grados en sentido antihorario, atacando hacia la izquierda, con el césped, las líneas y los marcadores circulares del diseño original. Se usan las denominaciones convencionales 6 lado ciego, 7 lado abierto, 12 centro interior y 13 centro exterior, contrastadas con la [guía de posiciones de World Rugby](https://www.world.rugby/the-game/beginners-guide/positions). La disposición es una referencia de formación, no una obligación de ocupar coordenadas fijas durante un partido. El directo continúa mostrando las coordenadas autoritativas del balón.

Campo longitudinal x=0…100 y transversal y=0…70. Las zonas de marca se dibujan fuera de x=0 y x=100; un ensayo se registra en la línea y con `result.inGoal=true`. El local ataca hacia x=100 en la primera parte y hacia x=0 en la segunda. El visitante hace lo contrario. En el inicio saca el local; en la segunda parte, el visitante. Después de anotar saca quien ha recibido los puntos; el siguiente evento de reinicio entrega el balón al receptor. Los tiros fallados también se simplifican mediante un reinicio desde el centro. La touche se resuelve como una sola acción, sin formación individual.

## Resolución y parámetros

Todos los valores son del servidor. Atributos permanentes 1…100; energía, moral y forma son estados temporales. No se persiste un nivel general redundante.

Parámetros centralizados en `Rugby.Simulation.Engine`:

```
ajustePosición = 1 principal | 0,94 secundaria | 0,82 fuera de puesto
rating = atributo × (0,55 + 0,45 × energía/100)
         × ajustePosición × (0,9 + forma/1000 + moral/2000)
fuerzaEquipo = media de ratings de los 15 jugadores en campo
éxitoAbierto = clamp(0,59 + (manejoAtaque - placajeDefensa)/180
                    + (decisionesActor - 55)/350 + ajusteRitmo)
éxitoFaseFija = clamp(0,58 + (fuerzaAtaque - fuerzaRival)/160)
metros = 3 + aleatorio × 10 + (velocidadActor - 50)/12 + ajusteRitmo
```

Las probabilidades se limitan a 0,08…0,92. La posición determina la distancia al objetivo y las opciones de golpe a palos y drop. La patada, melé, touche, disciplina y decisiones utilizan sus atributos correspondientes. La presión alta añade 5 al placaje agregado; baja resta 4. El estilo modifica la probabilidad de patada: 0,30 al pie, 0,15 equilibrado y 0,06 a la mano. El ritmo alto suma 0,025 al éxito y 2 metros, pero aumenta desgaste; lento resta 0,015. No hay garantía de victoria por superioridad.

Desgaste por paso: `(0,22 + ritmo + defensa) × (1,3 - resistencia/150)`. Ritmo alto +0,10; lento −0,04; presión alta +0,06. Se limita la energía a 0…100. La fatiga afecta al rating de las siguientes jugadas. No hay lesiones durante el partido ni sanciones complejas, HIA, expulsiones, cambios temporales, melés sin oposición o reentrada. La representación 2D sigue el balón, no la física individual de treinta jugadores.

## Alineación y cambios

Quince titulares ordenados por puesto 1…15; hasta ocho suplentes; sin duplicados, jugadores ajenos al club, juveniles sin promocionar o jugadores no disponibles. El capitán debe estar convocado. Los puestos 1, 2 y 3 requieren la posición principal exacta. Con ocho suplentes deben existir relevos especialistas para los tres puestos. Es una aproximación a la capacitación de primera línea, no una certificación médica o reglamentaria.

Máximo ocho cambios permanentes por equipo; no reentrada. Se valida convocatoria, estado y especialidad al recibir y al aplicar el comando. Los comandos pendientes se ordenan por secuencia de recepción, independiente de la clave de idempotencia. La IA usa el mismo servicio: sustituye jugadores con energía ≤66 a partir del minuto 50, conserva especialistas y grupos de delanteros/tres cuartos, y adapta el juego al marcador desde el minuto 60 en un punto seguro.

## Entrenamiento y economía

El entrenamiento se aplica por grupos de jugadores con una especialidad e intensidad. Los 17 atributos permanentes usan escala 1…100 y precisión de seis decimales, que no se muestran en las fichas. Cada sesión mejora solo la característica elegida, con un incremento de 17 veces la mejora prevista del promedio; pondera edad, intensidad y calidad del cuerpo técnico. El objetivo de cambio del promedio por temporada es +6…8 hasta 24 años, +2…5 entre 25 y 28, 0…2 entre 29 y 32, −4…−2 entre 33 y 35 y −7…−5 desde 36. Ver [modelo completo y tabla de edades](ENTRENAMIENTO.md).

Cada club tiene ocho puestos técnicos, incluido el entrenador de cantera. Se contratan candidatos y se paga un salario proporcional a su eficacia. Las nóminas del staff se devengan diariamente y se liquidan semanalmente; las sesiones cuestan por participante. Saldo y movimientos permanecen atómicos e idempotentes. En competición, ambos clubes reciben 18.500 € como local y 6.500 € como visitante. En amistosos, ambos clubes reciben 12.500 € cada uno del total de 25.000 €, con asientos independientes y sin pagos duplicados. Se permite saldo negativo y no se permite avanzar con partidos pendientes del día o anteriores.

## Persistencia y reproducción

Park–Miller (`estado × 16807 mod 2147483647`) con semilla y estado persistidos en cada transición. La velocidad nunca entra en el RNG. Misma semilla, instantáneas y decisiones en el mismo reloj de juego producen las mismas acciones. Las decisiones manuales enviadas en el mismo instante real a velocidades distintas pueden caer en relojes de juego diferentes.

Un único trabajador por namespace, protegido por bloqueo de proceso. Cada ciclo toma bloqueo global de escritura y de partido, comprueba versión y confirma en una transacción el estado, snapshots, eventos, comandos y liquidación. Trabajo máximo de ocho pasos por ciclo de 250 ms; no existe un proceso por partido. El crédito acumulado y la velocidad persisten. El reloj real de referencia es volátil: al reiniciar se establece de nuevo, se conserva el crédito confirmado y no se recupera el tiempo apagado. El exceso de una pausa de proceso mayor de dos segundos se descarta para evitar avalanchas.

La lectura HTTP usa el mismo bloqueo breve para no observar escrituras parciales. Esta serialización deliberada es adecuada para un MVP local; no es una arquitectura de alta concurrencia.


## Posición del jugador y numeración del XV

En los partidos en directo, el motor calcula y guarda coordenadas de los jugadores según balón, posesión y fase (juego abierto, ruck, melé o touche). Se mantiene el número del puesto y los sustitutos ocupan su lugar; los jugadores retirados dejan de moverse. La pantalla interpola entre los estados recibidos, con duración adaptada a la velocidad del partido, y respeta la preferencia de movimiento reducido. Esta geometría visual no modifica las probabilidades ni consume números aleatorios del motor deportivo. Los encuentros antiguos sin coordenadas conservan la representación de formación como alternativa compatible.

Los jugadores tienen una posición natural y posiciones secundarias, sin dorsal permanente. En Plantilla y Cantera los nombres se muestran sin número; los filtros Delanteros/Tres cuartos usan el grupo explícito de la posición natural. Pilares, talonadores, segundas y terceras líneas pertenecen a delanteros; medios, centros, alas y zaguero pertenecen a backs. El orden de la plantilla, el identificador del jugador y su inclusión en el banquillo no determinan ese grupo.

La numeración 1–15 identifica los puestos del XV en alineación y partido. El campo interno `position` conserva la clave de esa posición por compatibilidad; no representa un dorsal del jugador. La API también entrega `positionRole`, `positionName` y `positionGroup` para distinguir expresamente estos conceptos.


Los clubes rivales gestionan sus grupos, cantera, técnicos, agentes libres, alineaciones y gastos de forma determinista al avanzar el día; las energías se conservan también para los oponentes. Ver [gestión automática de rivales](RIVALES.md).

El motor incluye amarillas con diez minutos de exclusión de juego, doble amarilla, roja permanente, inferioridad numérica y retorno persistente. La variante activa y sus límites se documentan en [tarjetas y exclusiones](DISCIPLINA.md).
