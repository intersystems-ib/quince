# Estadísticas por jugador

La ficha incluye historial paginado por partido y totales: minutos, metros, placajes, ensayos, transformaciones y puntos. «Ver detalle» amplía pases, patadas, recuperaciones, avants, intentos a palos, formaciones, infracciones y tarjetas. El resumen del encuentro también muestra ambos equipos por jugador.

Los partidos en directo atribuyen acciones a sus protagonistas; los automáticos guardan estadísticas del modelo resumido, ponderadas por atributos y minutos. Los puntos individuales cuadran con el marcador. Se conserva el club representado aunque el jugador cambie de equipo y los reintentos no duplican registros.

Las estadísticas muestran los contadores registrados en cada encuentro; «—» indica un dato no disponible. La consulta es `GET /players/{playerId}/match-stats`, dentro de la partida privada y su auditoría de interoperabilidad.
