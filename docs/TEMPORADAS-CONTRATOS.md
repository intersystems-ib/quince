# Temporadas, contratos y retiradas

Una temporada se cierra siete días después del último encuentro de las dos competiciones, incluidos los playoffs. Se exige que todas las jornadas, semifinales y finales hayan terminado. Un encuentro pendiente o activo impide el cierre. El cierre ocurre durante el avance diario, con el resto de operaciones dentro de la misma transacción.

Se generan ambas divisiones para el año siguiente: diez equipos, noventa partidos regulares y dieciocho jornadas, con un nuevo sorteo reproducible y rachas de local/visitante limitadas a dos. La temporada comienza el 1 de septiembre; los primeros partidos siguen el fin de semana más próximo al 27 de septiembre. El reloj del club permanece en la fecha del cierre: se puede gestionar la pretemporada sin saltar automáticamente al 1 de septiembre. El histórico permanece disponible en el selector de competición, con campeones, clasificaciones, resultados y eliminatorias. Antes del sorteo, el décimo de la liga regular de Honor desciende y el campeón de los playoffs de Élite asciende. Se intercambian las dos plazas, manteniendo diez clubes por división. Se actualiza también la división de la partida si afecta al club del usuario. Las plantillas, nóminas y resultados históricos se conservan; el cierre audita ambos movimientos y no los repite.

## Contratos

Los jugadores que ya tienen club reciben, al adoptar esta versión, una fecha de contrato hasta el día anterior al cierre previsto de su temporada actual. No se modifican salario, atributos, energía, moral, identidad ni fecha de la partida. La inicialización ocurre una vez. Los nuevos fichajes y altas reciben una fecha de fin de temporada.

En Plantilla, Cantera y la ficha del jugador se muestra la fecha de vencimiento y se puede abrir una renovación. Utiliza ofertas y contraofertas salariales y exige confirmación; renueva por una temporada adicional, sin prima. Renovar a un canterano mantiene su categoría y su escala salarial. No se puede convertir una negociación de renovación pendiente en una promoción. Una promoción conserva el plazo que ya tuviera contratado si fuese más largo.

Los rivales revisan contratos durante los tres meses finales. Las revisiones se reparten de forma determinista y tienen en cuenta edad, nivel y cobertura de plantilla. Los salarios renovados cambian al confirmar la renovación. Las renovaciones se registran como contratos y quedan en el informe de interoperabilidad del día.

Al cerrar se liberan todos los contratos que ya no estén en vigor, tanto en primer equipo como en cantera. Se retiran de alineaciones, capitanía y grupos de entrenamiento, conservando sus datos deportivos e historial. Se convierten en agentes libres sin prima de salida. Los rivales reponen sus bajas con agentes disponibles y aseguran una alineación válida, incluida la primera línea. Las bajas de ese mismo cierre permanecen libres al menos ese día, sin ser absorbidas inmediatamente por esa reposición. El club gestionado por el usuario no renueva ni ficha automáticamente.

## Retiradas

Tres meses naturales antes de la fecha de la final se anuncian las retiradas. La edad se calcula al finalizar la competición. La probabilidad por temporada es 0 % hasta los 32 años; 10 % a los 33; 20 % a los 34; 35 % a los 35; 50 % a los 36; 70 % a los 37; 85 % a los 38; 95 % a los 39; y 100 % desde los 40. La decisión es reproducible por jugador y temporada y no cambia al recargar. Son decisiones simuladas de la partida, no anuncios reales de los jugadores cuyas identidades se utilizan.

Una retirada anunciada bloquea renovaciones, también las que ya estaban acordadas sin firmar. El jugador puede terminar la temporada y se retira al cierre aunque tuviese contrato para años posteriores. Su historial se conserva, queda no disponible y no aparece en el mercado de agentes libres. Los anuncios se ven en Competición, Plantilla y la ficha. Los agentes sin club también pueden retirarse.

## Entrenamiento y presentación

Entrenamiento separa Primer equipo y Cantera en dos pestañas. Selección, filtros, grupos, propuestas automáticas y resultados corresponden a la pestaña activa; guardar conserva el plan de ambas. Cambiar de pestaña no descarta los grupos pendientes. Automatizar una categoría conserva los grupos de la otra.

El primer equipo utiliza el especialista del entrenamiento, con los apoyos existentes del entrenador principal y del segundo especialista. La cantera utiliza exclusivamente la calidad del entrenador de cantera para la característica elegida. Solo esa característica crece ese día; no se distribuye la mejora por todas las características. Se mantienen las reglas de edad, energía y recuperación. La moral de la alineación y su comparador se representa con la misma barra y porcentaje que la energía.

## Auditoría

La API sigue entrando por el business service y los procesos y operaciones existentes. Los informes diarios incluyen renovaciones, anuncios, cierre, bajas y reposiciones. Las negociaciones se envían a Transfers.Operation. Las marcas de cierre, contratos e idempotencia evitan calendarios, bajas o firmas duplicadas. Una excepción revierte el avance diario completo. No se recalculan temporadas anteriores ni se añade una pantalla técnica de auditoría.
