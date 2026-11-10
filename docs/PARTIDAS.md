# Eliminar partidas propias

La pantalla «Mis partidas» permite eliminar una partida mediante el botón situado junto a «Cargar partida». La confirmación indica nombre, club y fecha y avisa de que el borrado es definitivo. Cancelar no envía la petición. Mientras se tramita, quedan deshabilitados los botones de cargar, eliminar y crear. Al terminar desaparece la tarjeta y se muestra la confirmación; si era la última, se muestra la invitación para crear una partida nueva.

`DELETE /api/v1/games/{gameId}` requiere una sesión JWT, `Idempotency-Key` y un cuerpo `{"confirm":true}`. El propietario se determina desde la sesión, nunca desde el cuerpo o la cabecera de partida. Las partidas ajenas e inexistentes devuelven 404; una confirmación ausente devuelve 422.

La operación conserva la entrada API → business service → business process → business operation. Dentro de la transacción y el bloqueo de escritura compartido con el trabajador elimina las entidades persistentes con claves de la partida seleccionada, su catálogo, índices y estado de simulación, así como la entrada de partidas. No borra extensiones completas de modelos, cuentas ni auditorías de interoperabilidad.

Un recibo mínimo, accesible sólo al propietario, permite repetir el borrado de forma segura. El identificador de la petición original de creación queda asociado a ese recibo: un reintento tardío de creación responde 410 y no recrea la partida. El recibo y la auditoría incluyen el identificador, la fecha y los recuentos de registros eliminados. Las demás partidas conservan sus datos, aunque compartan identificadores internos de jugadores o encuentros.

El trabajador deja de encontrar la partida eliminada. Las solicitudes posteriores para cargarla o consultar su progreso responden 404. Para crear otra partida se usa una petición nueva desde la pantalla habitual.

Las pruebas se ejecutan con cuentas y partidas nuevas en una instancia desechable. No se elimina ninguna partida existente del usuario durante la instalación de esta funcionalidad.
