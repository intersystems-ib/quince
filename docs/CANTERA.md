# Cantera y contratos de jugadores

La cantera se amplía una sola vez a un mínimo de veinte jugadores por club, cubriendo las quince posiciones. Los nuevos juveniles tienen entre 16 y 20 años y atributos variados. Los existentes conservan edad, características y progreso. La migración no rellena posteriormente las plazas que queden por promociones o rescisiones.

Los salarios de cantera pasan a ser de **25 a 60 € por semana**. La tabla muestra únicamente el salario actual; no hay una columna con salario preasignado al promocionar. **Promocionar** abre una negociación con ofertas y contraofertas de sueldo semanal. El jugador sigue en cantera con su salario actual hasta acordar y confirmar la promoción; entonces pasa al primer equipo con el salario negociado, sin prima de incorporación. Los salarios de los jugadores que ya pertenecían al primer equipo se mantienen.

El **entrenador de cantera** es la octava especialidad del cuerpo técnico. Hay un titular inicial y tres candidatos de distintas calidades y salarios. Su calidad determina el progreso de los canteranos dentro del tramo correspondiente a su edad: para los jóvenes, el objetivo del promedio se sitúa entre +6 y +8 por temporada completa. Se mantiene el entrenamiento exclusivo de la característica seleccionada y el resto de límites del [modelo de desarrollo](ENTRENAMIENTO.md). Los especialistas del primer equipo no sustituyen al entrenador de cantera; este tampoco modifica la progresión de los séniores.

La ampliación conserva los grupos de entrenamiento guardados. Los jugadores nuevos descansan hasta que se les asigne un grupo o se guarde una propuesta de entrenamiento automático.

## Rescindir contrato

La plantilla, la cantera y la ficha del jugador ofrecen **Rescindir contrato**, con confirmación previa. En este MVP la salida es inmediata y **sin indemnización**.

El jugador queda libre, deja de aparecer en las listas del club y de contar en las nóminas futuras. Se conserva su registro, sus características, las instantáneas de partidos y un registro de la rescisión. Se retira de los grupos de entrenamiento, del banquillo y de las posiciones o capitanías de las alineaciones guardadas. Las plazas vacantes deben cubrirse antes de iniciar otro partido.

No se permite rescindir durante un encuentro en curso ni contratos de otros clubes. La operación comprueba la versión del jugador y admite reintentos sin duplicar la salida. Endpoint: `POST /api/v1/players/{id}/release`, cuerpo con `version` y cabecera `Idempotency-Key`.


## Negociar una promoción

La negociación utiliza el mismo sistema de los agentes libres: cinco ofertas, siete días de juego de vigencia, contraofertas y posibilidad de retirarse. El salario de sénior guardado en los datos iniciales sirve como referencia para la petición inicial, no como sueldo obligatorio del contrato. El acuerdo todavía no promociona; **Confirmar promoción** solicita una confirmación y aplica el salario pactado una sola vez. La futura nómina sustituye el salario anterior del canterano por el acordado, sin duplicarlo.

`POST /clubs/{clubId}/academy/{playerId}/promote` requiere `version` del jugador y `Idempotency-Key`, y devuelve una negociación con `kind: promotion`. Las rutas `/negotiations/{id}/offer|sign|withdraw` continúan el proceso. La firma guarda un contrato `promotion`, sin movimiento económico de prima. El flujo público pasa por HTTP.In → API.Process → Transfers.Operation; no existe una ruta pública de promoción instantánea que omita la negociación. Se mantienen autorización por club, comprobaciones de versión, caducidad y bloqueo de la incorporación durante un partido activo.

El mismo jugador conserva identificador, atributos, energía y grupos de entrenamiento. Cerrar el diálogo no confirma la promoción; se puede reabrir mientras la negociación siga vigente. Las negociaciones de promoción también quedan en el historial de Fichajes.
