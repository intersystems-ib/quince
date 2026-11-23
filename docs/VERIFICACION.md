# Verificación

[Español](VERIFICACION.md) · [English](en/VERIFICACION.md) · [Français](fr/VERIFICACION.md) · [Índice](README.md)

`./scripts/test.ps1` ejecuta los grupos de `Rugby.Test.Suite` y compila el frontend. Los casos de IRIS se ejecutan con reversión de datos al terminar. Las integraciones que crean o avanzan partidas requieren una instancia desechable.

La suite cubre competición, temporadas, alineación, entrenamiento, moral, lesiones, tarjetas, partidos, salarios, finanzas, mercado, seguridad e idempotencia. Entre sus comprobaciones se incluyen:

- Alineación: intercambios, disponibilidad, capitán, validación y penalizaciones de moral.
- Contratos: duración, preferencias por edad, contraofertas, vencimientos iniciales, promociones, renovaciones y reintentos.
- Competición: grupos de Copa, fechas, localías, bonus, eliminatorias, clasificación y generación de calendarios.
- Entrenamiento y estadísticas: planes semanales, evolución por edad, acumulados por temporada y conciliación de acciones con el marcador.
- Mercado: hasta veinte agentes generados, jugadores de clubes a la venta, reposición semanal de extranjeros, salidas por media, negociación y competencia entre clubes.
- Personal: tres candidatos por especialidad, contratación, reposición de vacantes e historial de contratos.
- Partidos: comandos individuales y múltiples, pausas, lesiones, tarjetas, estadísticas y persistencia del estado.

Las integraciones HTTP utilizan `RUGBY_API_BASE` y guardan resultados en `RUGBY_TEST_ARTIFACTS`. Las capturas y archivos temporales se almacenan fuera del proyecto. La auditoría de operaciones se consulta en el visor de mensajes de IRIS.

Las comprobaciones visuales abarcan alineación, entrenamiento, contratos, calendario, finanzas y controles del partido en escritorio y móvil.

`cd rugby-frontend; npx playwright test advanceUntilEvent.spec.ts` verifica paradas en reuniones y partidos, cancelación, actualización del calendario, errores y límite de días.

`Rugby.Test.AdaptiveTactics` comprueba ventajas, remontadas, cansancio, revisiones independientes y marcador reproducible en simulación abreviada. `Rugby.Test.AISubstitutions` cubre relevos compatibles, exclusiones, límites y energía final. Las pruebas de Resultado y estadísticas verifican su integración.
