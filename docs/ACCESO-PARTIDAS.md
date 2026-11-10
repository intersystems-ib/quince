# Acceso, partidas y calendario

## Uso

1. Crear una cuenta con usuario y contraseña, o iniciar sesión con una cuenta existente.
2. Elegir **Nueva partida**, indicar un nombre, seleccionar División de Honor o División Élite y elegir uno de sus diez clubes oficiales.
3. La partida empieza el **1 de septiembre de 2026**. Cada cuenta puede conservar varias partidas independientes. **Mis partidas** vuelve a la lista; **Cargar partida** recupera el progreso guardado. Los cambios se guardan automáticamente en IRIS. Al recargar una pestaña con una partida cargada se verifica de nuevo su propiedad y se recupera esa partida; en el navegador solo se conserva su identificador, nunca el JWT.
4. **Calendario** muestra el mes de la fecha del juego. Las flechas cambian de mes y **Hoy** vuelve a la fecha de la partida. Al seleccionar un día se ven sus partidos de competición y amistosos.
5. En un día libre, **Concertar amistoso** ofrece tres clubes distintos, elegidos al azar entre ambas divisiones, con al menos uno de cada división cuando hay disponibilidad. Se elige rival y casa/fuera; **Añadir al calendario** confirma el encuentro. Los rivales se conservan para esa fecha y se comprueba de nuevo su disponibilidad al confirmar. No se puede jugar contra uno mismo ni concertar dos partidos el mismo día. Se reservan también las fechas previstas de semifinales y final, aunque aún no se conozcan sus participantes. Se admiten fechas entre el día actual y los siguientes 365 días.

Los amistosos usan la misma preparación, simulación, sustituciones y liquidación de ingresos que los encuentros de liga. No cuentan para la clasificación. La recaudación total de cada amistoso es de 25.000 € y se reparte al 50 %: 12.500 € por club, con un movimiento contable para cada uno. No se puede avanzar dejando sin disputar un partido del día o de una fecha anterior; sí se puede llegar al día del encuentro. Los partidos conservan su fecha. La liga y sus playoffs siguen disponibles en **Competición**.

Al volver a Mis partidas se pausa el reloj de los partidos en curso; cargar esa partida lo reanuda. No se recupera tiempo de simulación por interrupciones del servidor. Las fechas de gestión solo avanzan al pulsar Avanzar día.

## Autenticación

Se utiliza JWT **HS256**, con emisor, audiencia, usuario, sesión, fecha de emisión y caducidad de ocho horas. La firma se verifica con una clave aleatoria de 256 bits persistida en el servidor. Las sesiones son revocables; cerrar sesión invalida el JWT. No se entregan tokens al almacenamiento JavaScript: el navegador usa una cookie **HttpOnly**, **SameSite=Strict**, con ruta `/api/v1`. La cookie añade Secure al atender por HTTPS. El acceso local actual se sirve por HTTP en localhost.

Las contraseñas usan PBKDF2-HMAC-SHA256 con 600.000 iteraciones y una sal aleatoria individual. El acceso limita los intentos por dirección y minuto. Las mutaciones con Origin comprueban el mismo origen. Las primitivas criptográficas proceden de [%SYSTEM.Encryption de IRIS](https://irisdocs.intersystems.com/irislatest/csp/documatic/%25CSP.Documatic.cls?CLASSNAME=%25SYSTEM.Encryption&LIBRARY=%25SYS).

No hay cuentas ni contraseñas predeterminadas. No se implementan todavía recuperación de contraseña, verificación de correo ni segundo factor.

## Separación y persistencia

`X-Game-Id` selecciona la partida en cada petición del juego. El servidor comprueba que pertenezca al usuario del JWT y toma el club gestionado del registro de la partida. Cambiar el identificador desde el cliente no concede acceso a partidas ajenas. La plantilla, los jugadores, los entrenadores, los presupuestos, las competiciones y los partidos pertenecen a su partida.

Las claves físicas de los modelos persistentes tienen el prefijo de la partida, mientras que los identificadores de dominio conservan su forma. Los índices de club y partido, incluido el índice único de secuencias de narración, también incluyen ese prefijo. Catálogos, semillas, contadores, ofertas y claves de reintento usan `^RugbyWorld(partida,...)`. El proceso de simulación recorre las partidas activas con su contexto y conserva el bloqueo global de escrituras existente.

El arranque aplica una única migración de reinicio (versión 10), solicitada por el usuario: elimina la antigua partida local y prepara el catálogo inicial. Los reinicios posteriores conservan las cuentas y todas las partidas nuevas. El volumen Docker `iris-data` conserva estos datos.

Los endpoints se describen en [OpenAPI](openapi.json). Los scripts de integración anteriores al acceso autenticado son históricos y no deben ejecutarse contra partidas personales. La prueba actual es `python scripts/session_integration.py`, que crea cuentas y partidas desechables propias; sus identificadores quedan en `test-results/session-qa.json` para retirarlas después de la revisión.
