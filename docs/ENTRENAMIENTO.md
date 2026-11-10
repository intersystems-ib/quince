# Entrenamiento por grupos y cuerpo técnico · versión 3.0.0

## Uso

En **Entrenamiento**, seleccionar jugadores, elegir especialidad e intensidad y pulsar **Asignar al grupo**. La asignación mueve esos jugadores desde otros grupos. Se pueden editar o eliminar grupos y guardar la planificación completa. Cada jugador tiene un único entrenamiento diario; los no asignados recuperan energía. El plan guardado se aplica una vez al **Avanzar día** y se repite hasta modificarlo. Un borrador o selección pendiente impide avanzar desde esa pantalla.

En **Cuerpo técnico**, seleccionar uno de los ocho puestos, comparar calidad, eficacia y salario de los candidatos y contratar. Hay una persona por puesto. La contratación sustituye al titular, que vuelve a estar disponible. No hay prima de fichaje ni indemnización en este MVP. Los jugadores y entrenadores son ficticios.

**Automático** propone grupos para toda la plantilla, incluida la cantera. Cada pulsación reemplaza el borrador con una alternativa editable; solo **Guardar planificación** la aplica al plan. Con energía inferior a 60 o indisponibilidad se recomienda recuperación; entre 60 y 74, sesiones suaves; desde 75, normales. Los delanteros favorecen fuerza y especialidades de primera línea, segunda línea o tercera línea. Los tres cuartos favorecen velocidad y agilidad, con pase, decisiones y patada para los medios y trabajos técnicos para centros, alas y zaguero. Ocho variantes rotan las prioridades; la recuperación no cambia mientras sea necesaria. Los filtros de la lista no limitan la propuesta. No contrata técnicos, cobra ni avanza el día.

## Características y edad

Cada jugador tiene **17 características entre 1 y 100**: velocidad, fuerza, resistencia, agilidad, pase, manejo/recepción, placaje, patada, melé, touche, ruck, maul, disciplina, decisiones, liderazgo, estructura de ataque y lectura defensiva. Se almacenan hasta seis decimales; fichas y comparaciones muestran enteros redondeados. Ruck, maul, estructura de ataque y lectura defensiva amplían la ficha de desarrollo; el motor agregado conserva sus ponderaciones anteriores.

**Descanso y recuperación** recupera energía, no es una característica permanente. Ninguna modificación de plantilla altera la instantánea de un partido iniciado.

La progresión se calibra sobre el **promedio global de las 17 características**, por temporada completa de julio a junio. Para un programa normal de cinco sesiones semanales:

| Edad | Cambio del promedio por temporada | Incremento medio por sesión normal (temporada de 365 días) |
| --- | ---: | ---: |
| Hasta 24 inclusive | +6 a +8 | +0,02301 a +0,03068 |
| 25–28 | +2 a +5 | +0,00767 a +0,01918 |
| 29–32 | 0 a +2 | 0 a +0,00767 |
| 33–35 | −4 a −2 | Declive diario: −0,01096 a −0,00548 |
| Desde 36 | −7 a −5 | Declive diario: −0,01918 a −0,01370 |

El declive se aplica todos los días naturales, incluido el descanso. La edad se deriva del nacimiento de gestión y se recalcula cada día. Al cruzar un tramo, los días restantes usan el nuevo ritmo. Las temporadas bisiestas usan 366 días.

## Entrenadores y progresión

El responsable y el apoyo dependen de la especialidad elegida. La calidad efectiva se calcula así:

```
q = (0,15 × principal + 0,65 × responsable + 0,20 × apoyo) / 100
En cantera: q = calidad del entrenador de cantera / 100
hasta 24: objetivo = 6 + 2q
25–28: objetivo = 2 + 3q
29–32: objetivo = 2q
33–35: objetivo = −4 + 2q
desde 36: objetivo = −7 + 2q
sesiones previstas = días de la temporada × 5 / 7
mejora de la característica elegida por sesión = objetivo × 17 / sesiones previstas
pérdida total diaria de atributos = abs(objetivo) × 17 / días de la temporada
```

Una mejora de promedio de 7 puntos requiere acumular **119 puntos entre las 17 características**. **Cada sesión mejora exclusivamente la característica elegida**: con un objetivo de +7, el incremento de promedio de aproximadamente 0,0268 equivale a unos 0,4556 puntos del atributo entrenado por sesión normal. Se conserva toda la precisión interna. Para completar el objetivo anual hay que alternar especialidades; si el atributo elegido llega a 100, se detiene su progreso sin transferirlo a otros. En el declive, las físicas pesan 2, las mentales 0,6 y las demás 1. El mínimo es 1. Estos límites pueden impedir alcanzar el objetivo en jugadores ya próximos a 1 o 100.

La intensidad normal usa factor 1; suave 0,85 y alta 1,10. La ganancia acumulada de promedio nunca supera el objetivo vigente de la temporada: entrenar más días, cambiar de grupo o contratar otro técnico no reinicia el presupuesto. Un técnico mejor puede ampliar el objetivo restante. Las cifras de la tabla describen una temporada completa con continuidad normal, no una garantía ante lesiones, descanso prolongado o intensidad reducida. El cierre actual del 30 de junio proyecta solo los días restantes, sin regalar una temporada completa a mitad de curso.

Entrenar suma 12 de energía y consume 7 × intensidad (1, 2 o 3). Descansar suma 18 hasta 100. Si no está disponible o tiene menos de 25, recupera energía en lugar de entrenar. El mejor staff acelera la mejora o reduce la pérdida dentro del tramo correspondiente; los mayores no reciben crecimiento que compense artificialmente el declive.

El modelo **3.0.0** se aplica desde la siguiente sesión, sin recalcular días anteriores ni borrar atributos. El contador nuevo se inicia por jugador y temporada; los límites antiguos por característica quedan retirados. El antiguo techo de potencial vitalicio no limita esta progresión: Potencial sigue siendo una previsión del promedio al final de temporada. Las ejecuciones mantienen instantánea de técnicos, cambios por característica y promedio antes/después.

## Economía

Entrenamiento: 10/20/30 € por participante suave/normal/alto; recuperación sin coste. No se permiten participantes duplicados.

Salario semanal = eficacia individual (`0,35 + 0,65 × calidad/100`) × tarifa base: principal 1.200 €, delanteros 900 €, backs 900 €, defensa 850 €, ataque 850 €, destrezas 800 €, físico 950 €. Se guarda en céntimos. La eficacia mostrada no es el porcentaje directo de mejora de un atributo.

Los salarios se **devengan diariamente** a 1/7 de la tarifa y se pagan cada siete días de gestión, ponderando los cambios durante una semana. El pago se redondea al céntimo y se conserva la fracción residual. No se cobran días previos a la migración. Saldo, nóminas y entrenamiento se confirman juntos. No hay salarios retroactivos, prima de fichaje ni indemnización.

## Persistencia y API

La migración 6 añade características y técnicos sin reiniciar la partida. El plan anterior se convierte en un grupo con sus participantes. Se conservan las sesiones antiguas; las nuevas guardan grupos, cambios e instantáneas de los entrenadores con versión del modelo aplicado. Nuevas clases persistentes: `Coach`, `TechnicalStaff`, `StaffContract`.

- `GET /api/v1/training-types`: tipos, responsables y apoyos.
- `GET /api/v1/staff-market`: candidatos paginados.
- `GET /api/v1/clubs/{id}/staff`: contratados, roles y gasto semanal.
- `POST /api/v1/clubs/{id}/staff`: `{coachId, version}` con `Idempotency-Key`.
- `GET/PUT /api/v1/clubs/{id}/training-plan`: `{version, groups:[{id,name,focus,intensity,playerIds}]}`.
- `GET /api/v1/clubs/{id}/training-executions`: historial paginado, más reciente primero.

Se mantiene la identidad local `c1`, transacciones, bloqueo y control de versión. Se validan tipos, intensidad, pertenencia, duplicados y disponibilidad del técnico. El controlador interpreta JSON UTF-8, incluidas las tildes de nombres personalizados.

## Verificación

`Rugby.Test.Development` simula un año en cinco perfiles (adultos con staff alto/bajo, joven, veterano y jugador mayor), y comprueba límites, decimales, edad, calidad, fatiga, característica objetivo, presupuesto anual, grupos inválidos, sesión y contrato únicos y nómina proporcional. La suite completa conserva las pruebas del motor.

`python scripts/development_integration.py` comprueba la API real, nombres UTF-8, grupos persistentes, conflictos de versión, duplicados, jugadores ajenos, contratación y salarios. Restaura plan y entrenador, sin avanzar día o alterar saldo; quedan las entradas de auditoría de los contratos de prueba.

## Promedio y potencial de temporada

**Promedio** es la media aritmética de las 17 características permanentes; excluye energía, moral y el antiguo indicador de forma. Cada jugador conserva sus atributos propios, sin igualar promedios ni regenerar su progreso. El valor se recalcula al guardar y al consultar la ficha.

**Potencial** es el promedio previsto al cierre de la competición de la temporada, en la fecha reservada para su final (6 de junio en 2026/27; se usa el 30 de junio solo si no existe todavía una competición). Se proyecta sobre una copia con el plan guardado, la calidad actual de los técnicos, el calendario de edad, la recuperación y los límites de desarrollo reales. No anticipa partidos, lesiones ni cambios futuros del plan. No altera datos, energía, saldo ni fecha. El antiguo techo de desarrollo se conserva internamente separado de esta previsión. Desde los 33 años se aplica declive gradual, también en descanso; por eso el potencial de un veterano puede ser inferior a su promedio actual. Las flechas señalan mejora en verde, estabilidad en azul o declive en rojo aunque el redondeo entero oculte pequeñas diferencias. En una ventana estrecha la lista admite desplazamiento horizontal para consultar todas las columnas.

En la ficha del jugador, Promedio y Potencial tienen indicadores propios. En Plantilla y Cantera la columna junto a Promedio muestra Salario semanal; la previsión se consulta en la ficha y en Entrenamiento.
