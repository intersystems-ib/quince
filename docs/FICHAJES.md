# Fichajes de agentes libres

En **Fichajes → Agentes libres**, filtra por nombre, nacionalidad o posición y consulta edad, promedio, energía, salario mensual solicitado y prima de incorporación. El mercado comparte jugadores con los clubes rivales y muestra únicamente jugadores sin equipo. Los jugadores son ficticios.

**Negociar** abre una conversación que dura siete días de juego, incluido el último día indicado. Presenta un salario mensual en euros enteros: el jugador puede aceptarlo, pedir más o rechazar la negociación. Hay un máximo de cinco ofertas. Una negociación rechazada puede retomarse siete días después de la última oferta. Puedes retirarte y consultar el historial desde **Mis negociaciones**.

Aceptar un salario no incorpora automáticamente al jugador. **Firmar contrato** muestra una confirmación con el salario y la prima; al confirmar, el jugador entra en el primer equipo y se paga la prima una sola vez. La nómina mensual utilizará el salario pactado. No se altera la alineación ni la planificación de entrenamiento: el mánager puede asignarlo después. No hay pago a otro club por tratarse de jugadores libres.

El acuerdo no reserva al jugador frente a los rivales. Al firmar se comprueban de nuevo su disponibilidad, las condiciones, la fecha, el saldo y que no haya un partido activo. El historial de negociación, el contrato y el movimiento económico se conservan en la partida. Los jugadores rescindidos vuelven al mercado, también los procedentes de cantera; al contratarlos se incorporan al primer equipo con salario de sénior.

## Backend y auditoría

La API existente invoca **HTTP.In → API.Process → Transfers.Operation**. No existe una entrada directa alternativa: se mantienen autenticación JWT, autorización por partida y club, versiones, bloqueo y transacción única para contrato, jugador y prima. Las respuestas públicas nunca incluyen el umbral salarial privado del jugador. La firma devuelve los detalles de contrato y movimiento en el mensaje nativo de interoperabilidad, sin añadir una pantalla de auditoría.

Rutas: `GET /transfer-market`, `POST /players/{id}/negotiate`, `GET /negotiations`, `GET /negotiations/{id}` y `POST /negotiations/{id}/offer|sign|withdraw`. Las escrituras requieren `Idempotency-Key` y `version`. Importes de API en céntimos; ofertas entre 100 y 5.000.000 céntimos y múltiplos de 100. Las negociaciones pertenecen al club gestionado de la partida seleccionada mediante `X-Game-Id`.

El mercado compartido muestra un máximo de veinte agentes disponibles entre ambas divisiones, con cobertura de posiciones y niveles variados, incluidos algunos refuerzos de mayor promedio. Se generan veinte candidatos por temporada, diez españoles y diez extranjeros. Los excedentes conservan su historial y pueden volver a entrar en la selección; no se borran jugadores. La mejora inicial de calidad afecta exclusivamente a agentes generados que nunca han pertenecido a un club y no tienen negociaciones vigentes.

Los rivales presentan propuestas deterministas: gana el mayor salario mensual y, en caso de empate, el club mejor clasificado (Honor precede a Élite). Una oferta aceptada por el usuario participa con esos mismos criterios, pero sigue requiriendo su firma explícita. Los clubes pueden buscar alternativas si pierden al candidato. Para lesiones largas se revisa el mercado diariamente y se permite una reserva salarial acotada, conservando al menos un 10 % del presupuesto; el usuario dispone de la misma excepción para un recambio del mismo grupo de posiciones.

## Verificación aislada

`scripts/transfers_integration.py` exige la instancia de prueba en el puerto 52776. Crea cuentas y partidas desechables y comprueba negociación, contraofertas, rechazo, firma explícita, salario, prima única, reintentos, validaciones y aislamiento entre cuentas y partidas. `Rugby.Test.Transfers` cubre privacidad, caducidad, contratación rival, fondos insuficientes y bloqueo durante un partido dentro de una transacción que se revierte.

Negociación completada en una partida de prueba

Las promociones de cantera utilizan también la negociación salarial, con `kind: promotion`, sin prima y sin cambio de categoría hasta confirmar. Ver [promoción y contrato](CANTERA.md).
