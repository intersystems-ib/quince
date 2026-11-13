# Administración de datos iniciales

El formulario único de **Iniciar sesión** reconoce las credenciales de una cuenta activa de IRIS y abre directamente la administración. Las cuentas del juego acceden a sus partidas. Los usuarios de IRIS no requieren registro en Quince; sus nombres están reservados para el acceso administrativo. La autenticación utiliza el mecanismo nativo de IRIS; las cuentas deshabilitadas, caducadas o pendientes de cambio de contraseña no acceden. La sesión administrativa no permite listar, crear ni cargar partidas. Las cuentas del juego no pueden utilizar la API administrativa.

**Clubes** permite editar nombres, localidad, color, campo, aforo y escudo. Los escudos admiten PNG, JPEG y WebP de hasta 5 MB; se adaptan a 128 píxeles y se guardan con los datos. «Escudo original» restaura la imagen del despliegue. **Otros datos** permite editar los campos adicionales del registro. El identificador, las fechas de simulación y la división se conservan para mantener la estructura de competición.

**Jugadores** permite buscar por nombre, filtrar por club, editar identidad, edad, categoría, posiciones, nacionalidad, salario mensual, energía, moral y las diecisiete características. **Añadir jugador** incorpora un nuevo jugador a uno de los clubes existentes. La media se calcula a partir de sus atributos; los valores se validan entre 1 y 100 y conservan decimales internos. La interfaz expresa salarios en euros y la API en céntimos.

**Guardar datos iniciales** conserva los cambios para las nuevas partidas. Las partidas existentes mantienen sus datos y su progreso. Los cambios y escudos se almacenan en el volumen persistente de IRIS y sobreviven a reinicios y reconstrucciones. Guardar comprueba la versión del registro; **Recargar registro** permite recuperar el estado vigente ante una edición concurrente.

La API utiliza `/auth/login` y `/admin/clubs` o `/admin/players`. Las lecturas y escrituras recorren `HTTP.In → API.Process → Admin.Operation`, con auditoría nativa de interoperabilidad. Las contraseñas y el contenido binario de los escudos se ocultan en el mensaje de entrada.
