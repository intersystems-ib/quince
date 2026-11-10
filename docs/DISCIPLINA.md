# Tarjetas y exclusiones durante los partidos

La amarilla retira al jugador durante **600 segundos de tiempo de juego**, sin sustituto. Al cumplirlos vuelve al mismo puesto y conserva la amarilla en su historial del encuentro. El descanso y las pausas de la partida no consumen tiempo de exclusión. Una segunda amarilla provoca roja y expulsión definitiva. La roja directa también es definitiva y no permite sustitución.

El motor utiliza la regla de **roja permanente**, identificada como `redCardRule: permanent`. Las rojas directas generadas se describen como juego intencionado y altamente peligroso. No se activa la variante de rugby de élite que permite reemplazo a los veinte minutos en determinados casos. Referencias: [World Rugby, ley 9.29–9.30](https://passport.world.rugby/laws-of-the-game/laws-by-number/9-foul-play/?overridelang=1) y [definición de suspensión por diez minutos de juego, reglamento 17.2.2](https://www.world.rugby/organisation/governance/regulations/reg-17).

## Efectos deportivos y visuales

El jugador excluido no participa en acciones, deja de moverse y desaparece del campo. Su energía no se reduce como si continuara jugando. La fuerza del equipo utiliza la suma de aportaciones sobre quince puestos, de modo que tener catorce o trece jugadores reduce el rendimiento. Ni el usuario ni el rival automático pueden utilizar una sustitución para cubrir la baja disciplinaria; también se vuelven a comprobar los cambios que estaban pendientes.

El marcador muestra jugadores en campo y tarjetas de ambos equipos. La sección **Exclusiones** identifica jugador, club, puesto, expulsión o tiempo de exclusión restante. El minuto a minuto distingue amarilla, roja y regreso al campo. La plantilla del encuentro conserva las tarjetas incluso después del regreso o de una sustitución. Las estadísticas incluyen amarillas y rojas, contando ambas amarillas cuando hay doble amonestación.

Las probabilidades son de simulación: la disciplina individual influye en quién infringe y en la probabilidad de tarjeta; la reiteración individual aumenta el riesgo. Las decisiones dependen exclusivamente de la semilla y del estado deportivo, no de la velocidad de reproducción. No se reproducen tarjetas de las actas importadas: pertenecen a encuentros reales distintos de los partidos de la partida.

Los partidos agregados entre rivales automáticos generan también tarjetas y regresos deterministas. Acumulan segundos jugados por cada titular y reducen la fuerza según la inferioridad durante el encuentro; el cansancio se ajusta al tiempo jugado. Los eventos y la participación se conservan en el encuentro de calendario. Esta función trata las exclusiones del partido; no añade sanciones federativas posteriores ni acumulación de tarjetas entre jornadas.

## Persistencia y auditoría

`Rugby.Simulation.Discipline` guarda en cada instantánea los estados `sinBin` y `sentOff`, amarillas, rojas, historial y `sinBinUntil`. El trabajador confirma juntos partido, jugadores, eventos y comandos bajo el bloqueo y transacción existentes. La narrativa nueva se incorpora a `DetailsJSON` de Simulation.Operation mediante el flujo de interoperabilidad existente. Los encuentros anteriores que no contienen los nuevos campos los interpretan como cero; no se reescriben resultados históricos ni se reinicia la partida.

No existe una ruta HTTP para que el usuario asigne tarjetas. Las infracciones las decide el motor. `Card()` es una operación interna que rechaza duplicados sobre un jugador ya excluido o retirado.

## Pruebas

`Rugby.Test.Discipline` cubre exclusión, inferioridad real, selección de participantes, bloqueo de sustituciones, regreso exacto, doble amarilla, roja directa, ausencia de duplicados, descanso, amarilla cerca del final, persistencia del trabajador y reproducibilidad de los encuentros automáticos. Las pruebas de velocidad y recuperación existentes verifican que se conservan las secuencias deterministas y el resultado al reanudar.

`scripts/discipline_integration.py setup|check` exige una instancia desechable en el puerto 52776. Prepara una partida de prueba y genera un guion de comprobación interna con una amarilla y una roja; comprueba por API estados, duración, inferioridad, estadísticas, rechazo de sustitución y eventos narrados. Ese guion nunca se ejecuta sobre la partida del usuario.

Marcador de la partida de prueba con inferioridad y tarjetas
