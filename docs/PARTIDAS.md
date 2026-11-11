# Eliminar partidas propias

La pantalla «Mis partidas» permite eliminar una partida mediante el botón situado junto a «Cargar partida». La confirmación indica nombre, club y fecha y avisa de que el borrado es definitivo. Cancelar no envía la petición. Mientras se tramita, quedan deshabilitados los botones de cargar, eliminar y crear. Al terminar desaparece la tarjeta y se muestra la confirmación; si era la última, se muestra la invitación para crear una partida nueva.

`DELETE /api/v1/games/{gameId}` requiere una sesión JWT, `Idempotency-Key` y un cuerpo `{"confirm":true}`. El propietario se determina desde la sesión, nunca desde el cuerpo o la cabecera de partida. Las partidas ajenas e inexistentes devuelven 404; una confirmación ausente devuelve 422.
