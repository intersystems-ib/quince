# Verificación

`./scripts/test.ps1` ejecuta los 62 grupos de `Rugby.Test.Suite` y compila el frontend. Los casos de IRIS se ejecutan con reversión de datos al terminar. Las integraciones que crean o avanzan partidas requieren una instancia desechable.

La suite cubre competición, temporadas, alineación, entrenamiento, moral, lesiones, tarjetas, partidos, salarios, finanzas, mercado, seguridad e idempotencia. Entre sus comprobaciones se incluyen:

- Alineación: intercambios, disponibilidad, capitán, validación y penalizaciones de moral.
- Contratos: duración, preferencias por edad, contraofertas, vencimientos iniciales, promociones, renovaciones y reintentos.
- Competición: grupos de Copa, fechas, localías, bonus, eliminatorias, clasificación y generación de calendarios.
- Entrenamiento y estadísticas: planes semanales, evolución por edad, acumulados por temporada y conciliación de acciones con el marcador.
- Mercado: veinte agentes libres, reposición semanal de extranjeros, salidas por media, negociación y competencia entre clubes.
- Personal: tres candidatos por especialidad, contratación, reposición de vacantes e historial de contratos.
- Partidos: comandos individuales y múltiples, pausas, lesiones, tarjetas, estadísticas y persistencia del estado.

Las integraciones HTTP utilizan `RUGBY_API_BASE` y guardan resultados en `RUGBY_TEST_ARTIFACTS`. Las capturas y archivos temporales se almacenan fuera del proyecto. La auditoría de operaciones se consulta en el visor de mensajes de IRIS.

Las comprobaciones visuales abarcan alineación, entrenamiento, contratos, calendario, finanzas y controles del partido en escritorio y móvil. Las mediciones de rendimiento y su metodología se encuentran en [RENDIMIENTO-ARTICULO.json](RENDIMIENTO-ARTICULO.json).
