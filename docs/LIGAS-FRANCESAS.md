# Top 14 y Pro D2

Las cuatro ligas están disponibles al crear partida, en Competición y en Clubes y divisiones. La incorporación es automática en partidas existentes y conserva sus resultados y contratos españoles.

| Liga | Equipos | Jornadas | Partidos regulares | Fase final |
| --- | ---: | ---: | ---: | --- |
| Honor / Élite | 10 | 18 | 90 | Semifinales y final |
| Top 14 | 14 | 26 | 182 | 3.º–6.º y 4.º–5.º; semifinales y final |
| Pro D2 | 16 | 30 | 240 | 3.º–6.º y 4.º–5.º; semifinales y final |

En Francia los dos primeros pasan directamente a semifinales. El primero recibe al ganador de 4.º–5.º; el segundo, al de 3.º–6.º. Las eliminatorias son a partido único. El calendario simulado empieza en septiembre y termina en junio; limita a dos las jornadas seguidas en casa o fuera. El bonus defensivo francés corresponde a derrotas de cinco puntos o menos.

El campeón de Pro D2 asciende y el último de Top 14 desciende. El subcampeón de Pro D2 recibe al penúltimo de Top 14 en el Access Match, después de las finales y antes del cierre de junio. El ganador jugará en Top 14 y el perdedor en Pro D2. No se simula Nationale. La Copa del Rey mantiene exclusivamente los veinte clubes españoles.

## Datos y nivel

- 30 clubes y un catálogo de identidades únicas, con escudos LNR. Las plantillas incluyen los convocados de todas las jornadas consultadas y los jugadores publicados en los efectivos oficiales LNR, aunque todavía no hayan participado. Las fichas identifican las características estimadas de quienes no tienen actas de referencia.
- Referencias de los partidos oficiales disponibles de 2026/27: minutos, puntos, ensayos, placajes y rupturas.
- Los puestos principales y secundarios proceden de las titularidades observadas en varias actas; los roles genéricos de jugadores sin titularidades se identifican como estimaciones. Las medias ponderan minutos, convocatorias, titularidades y producción por 80 minutos dentro de la misma liga y familia de puestos, moderando las muestras pequeñas. La IA combina estas referencias con atributos, energía y disponibilidad para elegir el XV y el banquillo.
- Las edades, características y salarios son simulados. Top 14 tiene un nivel superior a Pro D2 y a las ligas españolas. La especialidad del puesto y las referencias individuales introducen diferencias entre jugadores.
- Los datos LNR aparecen en la ficha del jugador, separados de las estadísticas de su partida. Los puntos sin autor no se asignan artificialmente; los registros de anotación contradictorios quedan excluidos de la calibración.

Los archivos `iris/data/french-leagues.json` y `iris/data/french-match-validation.json` contienen el catálogo y las comprobaciones de marcador. Se actualizan con:

```bash
python scripts/import_french_leagues.py
python scripts/update_lnr_names.py
python scripts/refresh_french_match_evidence.py
```

## Economía y mercado

Los presupuestos de referencia se definen en `iris/data/french-club-settings.json`. Top 14 utiliza cifras de 2025/26 como referencia; los importes estimados de los demás clubes y los aforos aproximados se identifican en los datos. Montauban participa en Pro D2 y Vannes en Top 14 según la clasificación consultada de 2026/27.

Las referencias salariales por puesto son anuales y se convierten a pagos mensuales. La masa salarial inicial se ajusta al presupuesto; Top 14 respeta su techo salarial, incluso al ampliar el margen para fichajes. Toulouse, Bordeaux-Bègles, Toulon y La Rochelle tienen techos específicos; el resto utiliza una referencia de simulación. Todos los clubes tienen cuerpo técnico y cantera automática con nombres franceses para los juveniles generados.

El mercado filtra por liga desde el servidor y abre en la liga del usuario. Mantiene veinte jugadores por página; el límite de veinte agentes generados es global, sin limitar los jugadores puestos a la venta por clubes.

Los mercados de cuerpo técnico y financieros son independientes para España y Francia. Cada país dispone de tres candidatos por especialidad técnica; contratar o despedir repone únicamente su mercado. Los jugadores pueden cambiar de liga y país. Los nombres reales se contrastan con las plantillas LNR y se actualizan sin alterar atributos, salarios ni contratos de partidas existentes.

Los patrocinadores franceses son empresas ficticias generadas con nombres franceses y la localidad del club. Los importes anuales simulados representan el 12–20 % del presupuesto para el principal y el 1,8–3 % para cada uno de los cinco secundarios. Los patrocinios institucionales suman el 3–6 % en Top 14 o el 6–10 % en Pro D2, repartidos entre dos entidades locales genéricas. La semilla, el rendimiento y la calidad del financiero determinan las variaciones. La actualización de partidas conserva los cobros contabilizados y la duración de los contratos.

La planificación financiera se calibra una vez por temporada con un margen operativo objetivo entre el 0,5 % y el 3 %. La calidad del financiero mejora ese objetivo, con una variación estable de hasta ±0,15 puntos porcentuales por club y temporada. Ajusta los ingresos variables pendientes dentro del presupuesto de referencia, sin aumentar gastos ni modificar cobros o patrocinios firmados. La previsión salarial suma lo pagado, lo devengado y los meses restantes; las incorporaciones a mitad de temporada no incluyen doce nóminas ni acuerdos de septiembre sin firmar. Los partidos anteriores a la incorporación del club no generan previsiones ni cobros retroactivos de taquilla. Las decisiones posteriores de contratación conservan su efecto sobre el balance.

Los salarios de cantera varían con la edad, el nivel y una semilla estable. La redistribución inicial conserva el coste mensual total de cada cantera y protege las renovaciones negociadas. Los contratos terminan el 30 de junio de distintas temporadas, con duraciones de uno a tres años; las nuevas promociones también reciben condiciones individuales.

## Fuentes

- [Clasificación Top 14](https://top14.lnr.fr/classement) y [Pro D2](https://prod2.lnr.fr/classement).
- [Actas y calendario Top 14](https://top14.lnr.fr/calendrier-et-resultats/2026-2027/j1).
- [Salary cap LNR](https://top14.lnr.fr/actualite/salary-cap-la-lnr-publie-pour-la-premiere-fois-le-plafond-applicable-a-chaque-club-de-top-14).

Las ampliaciones reparten el coste mensual inicial entre los jugadores de referencia, manteniendo la masa salarial del club y las condiciones de los fichajes y renovaciones negociados.
