# Estadísticas

[Español](ESTADISTICAS.md) · [English](en/ESTADISTICAS.md) · [Français](fr/ESTADISTICAS.md) · [Índice](README.md)

La ficha del jugador incluye historial paginado por partido, totales y detalle de acciones. El resumen del encuentro permite consultar a ambos equipos. Los partidos en directo atribuyen las acciones a sus protagonistas; los automáticos guardan estadísticas del modelo resumido, ponderadas por atributos y minutos. Se conserva el club representado y los reintentos no duplican registros.

`GET /players/{playerId}/match-stats` consulta el historial; `GET /competitions/{competitionId}/statistics`, los Top 10. Ambas consultas están restringidas a la partida privada y pasan por interoperabilidad.

Competición separa Clasificación, Calendario y Estadísticas en Liga y Copa. Los Top 10 acumulan partidos terminados de la competición y temporada seleccionadas, incluidas fases finales. Cada jugador aparece una vez aunque cambie de club; se muestra el último club representado en esa competición.

Las métricas se consultan por ataque, defensa, juego al pie, formaciones, disciplina y participación. Se ordenan de mayor a menor, sin incluir totales cero ni suplentes que no jugaron. Disciplina muestra los mayores recuentos de infracciones y tarjetas. Los registros históricos incompletos se señalan.

`Rugby.Analytics.PlayerMatch` almacena las métricas y sus claves en columnas, con clave única por registro original. No duplica los documentos JSON. Las consultas SQL agrupan por partida, competición y jugador. La migración inicial es automática e idempotente; los partidos nuevos actualizan su proyección en la misma transacción. Al eliminar una partida se elimina también su proyección analítica.

[Almacenamiento columnar de IRIS](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_storageglobals#GOBJ_storageglobals_columnar).

La liga y los clubes participantes se verifican contra el partido y la competición de origen; los amistosos no entran en los rankings de liga. La pertenencia histórica no cambia al ascender, descender o traspasar jugadores.
