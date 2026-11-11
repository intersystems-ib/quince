# Verificación

`./scripts/test.ps1` ejecuta los grupos de IRIS y compila el frontend. Los casos se revierten al terminar; las integraciones que avanzan partidas requieren una instancia desechable.

Verificados 53 grupos, integración HTTP y revisión visual. La actualización de la partida existente ajusta 920 jugadores y conserva sus datos deportivos y económicos.

La suite cubre competición, temporadas, alineación, entrenamiento, moral, lesiones, tarjetas, partidos, salarios, finanzas, mercado, seguridad e idempotencia. TalentScale verifica reducción proporcional, conservación de datos y futuras generaciones. FriendlyRequests verifica fines de semana, límite mensual, aceptación, rechazo, caducidad y reintentos.

Las integraciones usan `RUGBY_API_BASE` y guardan resultados en `RUGBY_TEST_ARTIFACTS`. Las capturas y archivos temporales se mantienen fuera del proyecto. La auditoría de acciones se consulta en IRIS.

El plan semanal se verificó durante catorce avances diarios: repetición, ejercicios por línea, cantera independiente, recuperación y guardados sin duplicados. La revisión visual cubrió edición, guardado y próximas sesiones.

Alineación: intercambios por dos clics, sustitución segura de lesionados, capitán, validación automática al guardar y moral reversible sin acumulaciones ni cambios de atributos.

Contratos: duración de 1–5 temporadas, preferencias por edad, contraofertas, reintentos y conservación de la fecha acordada al firmar. Verificados también por API y en pantalla.

Copa: grupos y fechas FER, localías, bonus, eliminatorias, doblete, plazas de la siguiente temporada y adopción sin modificar resultados previos. Comprobados el calendario, un partido completo por API y la generación de Copa antes de Liga al cerrar la temporada.
