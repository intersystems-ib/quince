# Verificación del MVP

Fecha: 10 de noviembre de 2026. Entorno Windows y Docker Desktop. La versión anterior de este informe y las capturas históricas se conservan fuera del proyecto junto con el manifiesto del archivo.

## Ajustes financieros

La compilación de IRIS/ObjectScript y del frontend TypeScript/Vite ha terminado correctamente. Los 35 grupos de pruebas de IRIS han pasado, incluido el grupo específico de revisión financiera.

La integración HTTP en una instancia desechable comprobó la contratación del financiero, los reintentos sin duplicados, los permisos de propiedad, la automatización de septiembre, los ingresos de los rivales, la contabilidad exacta y la validación del precio de entradas. La comprobación de los veinte clubes confirmó seis patrocinadores y una concesión por club: 140 empresas contratadas distintas, importes dentro de los rangos, mensualidades de concesión y ausencia de ventas o costes de bar en las nuevas previsiones de partido.

Las pruebas de IRIS cubren las diez mensualidades, su suma exacta, contratos plurianuales, efecto de la calidad del financiero y el éxito deportivo, y migración de acuerdos con pagos ya recibidos. Un partido pendiente conserva su estado: la integración no lo disputó. La revisión visual del navegador comprobó la concesión del bar y la previsión de entradas antes del partido; no se ejecutó un partido desde el navegador ni la suite automatizada de Playwright.

## Actualización de partidas existentes

Se actualizaron los contenedores de la aplicación manteniendo el volumen de datos. La producción de interoperabilidad está iniciada y la API responde correctamente. La migración figura en la auditoría nativa.

La comparación antes/después de las dos partidas conservó los 5.826 registros originales. Se mantienen exactamente los 40 clubes y sus saldos, los 1.077 movimientos financieros, los nueve partidos terminados, 406 encuentros del calendario, 40 alineaciones, 1.777 registros contractuales previos, 69 contratos técnicos y la negociación existente. Se añadieron 1.754 registros de ajuste salarial sin coste; no se borraron contratos anteriores.

Los cambios de jugadores se limitan a remuneraciones, versión salarial y referencias económicas de promoción. La identidad, las características, la edad, la energía y la moral permanecen intactas. Los cambios de entrenador se limitan al salario. Las asignaciones de entrenamiento se conservan. Se ajustaron oficinas, acuerdos y referencias presupuestarias según el nuevo modelo, sin alterar cobros históricos ni plazos contractuales. Los 40 clubes de las partidas mantienen un margen previsto superior al 15 %; el mínimo observado fue 25,87 %.

## Limpieza y archivos de comprobación

Se archivaron fuera del proyecto 50 capturas de documentación y los directorios de resultados, extracción temporal de actas, caché Python y compilación frontend. El archivo incluye un manifiesto de procedencia y destino. Se conservan las imágenes necesarias de la aplicación: icono y veinte escudos.

Los scripts de integración y Playwright escriben sus resultados en la carpeta temporal del sistema, o en la ruta externa indicada por `RUGBY_TEST_ARTIFACTS`. Las reglas de exclusión evitan incorporar cachés, resultados y compilaciones al contexto de las imágenes Docker. Se revisaron las referencias de documentación a las capturas archivadas.

Los informes detallados, instantáneas, registros de compilación, captura de la concesión y manifiesto están en el directorio externo `rugby-finance-v2` de las evidencias de esta sesión. No contienen credenciales de partidas reales.

## Alineaciones flexibles y lesiones

Actualización del 10 de noviembre: los 36 grupos IRIS pasan, incluido `Injuries`. La integración HTTP y la revisión visual verificaron los intercambios de primera línea, la penalización de moral, las bajas de primer equipo y cantera, el bloqueo de alineación y de mejoras por entrenamiento, y las fechas de recuperación. El grupo de lesiones también cubre sustitución única, checkpoints, historial, alta exacta y aplicación a rivales. Véase [LESIONES.md](LESIONES.md).

Tras publicar la versión, los 7.580 registros de las dos partidas existentes son idénticos a los de antes: no se han aplicado lesiones retroactivas ni cambiado fechas, saldos, plantillas o resultados. La producción de interoperabilidad y la API están operativas. La instancia desechable de pruebas fue retirada. Los registros y capturas permanecen fuera del proyecto, en `rugby-injuries` dentro de las evidencias de la sesión.

## Eliminación de partidas propias

Actualización del 10 de noviembre: los 37 grupos IRIS pasan, incluido `GameDeletion`. La integración HTTP en una base desechable comprobó propietario, confirmación explícita, reintentos de borrado, bloqueo de solicitudes antiguas de creación y conservación exacta de datos de otra partida propia y de otra cuenta. Las peticiones conservaron correlación con la auditoría de interoperabilidad.

La revisión visual confirmó el botón junto a «Cargar partida», el diálogo con nombre, club, fecha y aviso de borrado definitivo, y que «Cancelar» cierra el aviso manteniendo la partida y sus botones disponibles. Las capturas, datos y registros de verificación se guardan fuera del proyecto, en el directorio de evidencias `rugby-game-deletion`. Véase [PARTIDAS.md](PARTIDAS.md).

La publicación conservó exactamente los 7.580 registros de las dos partidas existentes. No se borró ninguna partida del usuario. Producción de interoperabilidad iniciada y servicios de la aplicación operativos.

## Situación y separación de no disponibles

Actualización del 10 de noviembre: pasan los 38 grupos IRIS, incluido `Availability`, la compilación de TypeScript/Vite y las comprobaciones de selección del cliente. Las pruebas cubren limpieza del banquillo, capitán de baja, sustitución de titular lesionado sin trasladarlo a suplentes, conservación de intercambios entre jugadores sanos, rechazo de jugadores ajenos y retorno de recuperados sin alineación automática.

La integración HTTP, en una partida desechable, comprobó suplentes retirados por lesión y por otra causa, titular bloqueado hasta ser sustituido y guardado correcto incluso cuando el cliente enviaba la lista antigua de suplentes no disponibles. La lectura posterior conservó titulares, banquillo, capitán y versión. Las operaciones mantienen su correlación con la auditoría nativa.

La revisión visual confirmó la columna «Situación» con cruces rojas, una celda vacía para una baja de otra causa y la sección «No disponibles». Desde la pantalla se sustituyó al titular lesionado por un suplente disponible, se guardó la alineación y la validación respondió «La alineación guardada es válida». Las evidencias, capturas y datos de prueba se guardan fuera del proyecto en `rugby-availability`. Véase [LESIONES.md](LESIONES.md).

La actualización conservó exactamente los 2.395 registros de la partida que existía al publicarla. Los servicios quedaron operativos y se retiró la instancia desechable de comprobación.

## Salarios mensuales por nivel del club

Actualización del 10 de noviembre: pasan los 39 grupos IRIS, incluido `MonthlyPayroll`, la compilación TypeScript/Vite y las comprobaciones de conversión del cliente. La integración HTTP verificó los veinte clubes, bandas de primer equipo y cantera, salarios individuales distintos, reserva sobre presupuesto y concordancia exacta de los movimientos con el saldo. También verificó el rechazo de ofertas ambiguas o de tipo incorrecto, la conversión de 2.000 €/mes a 46.154 céntimos semanales, los reintentos y una renovación sin duplicar cargos.

La revisión visual confirmó la columna «Salario mensual» en la plantilla de un club de media tabla y cantidades distintas, incluyendo 802, 806, 1.075, 1.235 y 2.000 euros. Los formularios, fichas y promociones usan importes mensuales; la liquidación semanal y la reserva de 53 pagos anuales se conservan. Véase [SALARIOS-PRESUPUESTO.md](SALARIOS-PRESUPUESTO.md).

La publicación conservó los 4.311 registros originales de la partida existente y añadió 874 ajustes salariales 3.0.0, sin borrar ni sobrescribir contratos anteriores. Las modificaciones de jugadores se limitaron a salarios, referencia económica de promoción y versión salarial. Permanecen exactamente iguales los 20 clubes y sus saldos, 538 movimientos, 120 acuerdos financieros, técnicos, oficinas, 202 encuentros del calendario, dos partidos finalizados, sus eventos y comandos, alineaciones, tácticas, entrenamientos y contratos anteriores.

Se verificaron los salarios resultantes de los veinte clubes de la partida y su reserva: el margen mínimo observado sobre el presupuesto fue del 21,84 %. Esto no supone que los ingresos estén asegurados; Finanzas distingue presupuesto y cobertura con ingresos previstos o firmados. La auditoría nativa registra 860 ajustes del catálogo base y 874 de la partida. Las evidencias se guardan fuera del proyecto en `rugby-monthly-payroll`.

## Nóminas mensuales de jugadores y empleados

Actualización del 10 de noviembre: sustituye la cadencia semanal descrita en la verificación anterior. Pasan los 40 grupos IRIS, incluidas las pruebas de días reales por mes y febrero bisiesto, prorrateo de incorporaciones, pendientes históricos, idempotencia, límite presupuestario y liquidación de los veinte clubes al avanzar de noviembre a diciembre. La integración HTTP comprueba importes mensuales de entrenadores y financiero, sustituciones, reintentos, previsión de doce nóminas, ocho días sin débitos semanales y conciliación exacta de saldo y libro; todas las peticiones tienen correlación de interoperabilidad. TypeScript/Vite compilan y pasan las comprobaciones del cliente de salarios y alineación.

Se revisaron visualmente Cuerpo técnico y Financiero, con sus importes por mes. La migración conserva los 5.185 registros previos, sus 538 movimientos y todos los saldos. Añade 874 registros de cambio de período para jugadores y 160 ajustes de contrato técnico. Las modificaciones se limitan al salario mensual y metadatos, nóminas técnicas nuevas y traslado de devengos antiguos: quedan pendientes 5.891,14 € de jugadores, 1.202,99 € de técnicos y 341,29 € de financieros, sin generar cargos al actualizar. Los veinte clubes mantienen al menos el 15,69 % de reserva sobre su presupuesto.

La respuesta nativa de arranque 40538, sesión 81234, registra los ajustes de jugadores, técnicos y financieros del catálogo y la partida. Los servicios publicados quedaron saludables, se retiró la instancia temporal y las evidencias se guardaron fuera del proyecto en `rugby-employee-monthly-payroll`.

## Entrenamiento sin costes diarios

Eliminados los cargos de entrenamiento de todos los clubes y su reserva presupuestaria. Los planes y propuestas nuevas devuelven coste cero; una ejecución ignora costes de planes antiguos. Las pantallas de entrenamiento y finanzas omiten esas partidas. La adopción de planes existentes registra el coste anterior y el nuevo en la respuesta de arranque de interoperabilidad, conservando grupos, salarios, saldos e historial.

Pasan TrainingCosts, Development, Payroll, MonthlyPayroll, EmployeePayroll y Rivals, la compilación TypeScript/Vite y la integración HTTP de contrataciones y ocho días de gestión sin cargos de entrenamiento. La comparación previa y posterior a publicar conserva todos los registros; sólo cambia los campos de coste y versión de los veinte planes. Evidencias externas: `rugby-training-no-cost`.

## Pausas, referencia histórica, ascensos y campos

Actualización del 10 de noviembre: pasan los 43 grupos IRIS y la compilación TypeScript/Vite. MatchPauses verifica pausa manual, ausencia de crédito acumulado durante la pausa, reloj y jugadores detenidos, lesión propia local y visitante, lesión rival sin pausa, sustitución con el reloj detenido y descanso sin avance accidental a la segunda parte. La integración HTTP confirma las mismas operaciones con correlación nativa de interoperabilidad.

Seasons completa dos temporadas con ascenso del campeón de playoffs de Élite, distinto del ganador de la regular, y descenso del décimo de Honor. Verifica diez equipos por división, calendarios de noventa partidos, conservación de resultados y ausencia de dobles intercambios. El presupuesto nominal anterior y los contratos se conservan al intercambiar categoría. Quality verifica ponderación histórica, sustitución del ajuste anterior, entrenamiento acumulado e idempotencia; la integración HTTP comprueba las medias de los veinte clubes y la diferencia entre divisiones.

Venues comprueba campos y aforos publicados para los veinte clubes, el campo del local en encuentros visitantes, la instantánea del partido y la asistencia limitada al aforo. Se revisaron visualmente la información del club y un partido pausado por lesión con el campo y su aforo junto al marcador. Los datos proceden de las dos páginas de Wikipedia 2026/27 aportadas por el usuario; véase [Campos](CAMPOS.md).

La publicación conserva los 7.243 registros previos, los 642 movimientos financieros y los cuatro partidos terminados. Cambia referencias de calidad de clubes y jugadores originales, incorpora los campos y completa sus metadatos en partidos y calendario. Se verificó el nuevo cálculo de las 473 fichas cuyos atributos cambian, conservando el entrenamiento; las demás fichas originales sólo actualizan su versión de calibración. Nóminas, saldos, contratos, propiedad, energía, moral, lesiones y resultados permanecen iguales. Evidencias externas: `rugby-pauses-promotion`.

## Reducción de lesiones de partido

Modelo de lesiones 1.1.0: probabilidad base de partido reducida un 75 %, de 0,00018 a 0,000045 por jugador y veinte segundos, compartida por directo y simulación de rivales. Se mantienen edad, cansancio, frecuencia de entrenamiento, catálogo, gravedad, recuperación y bajas existentes. InjuryFrequency recorre MatchTick en 200 exposiciones controladas de ochenta minutos y treinta jugadores sanos, a energía completa: 68 lesiones, 0,34 por partido. Verifica que el riesgo siga creciendo con edad y fatiga y que cero tiempo no produzca exposición.

Pasan InjuryFrequency, Injuries, MatchPauses, Discipline y Speed. La comprobación del rival busca una semilla con lesión infrecuente, confirma reproducción exacta y persistencia de la baja. La imagen IRIS compila y se publica conservando el volumen. Evidencias externas: `rugby-injury-frequency`.

## Mercado compartido, salarios técnicos y financiación ajustada

Pasan los 48 grupos de pruebas, incluidos TransferPool, TransferAuction, StaffPay y FinancialPlanning. Se comprueban veinte candidatos como máximo, cobertura y calidad variadas, contratación médica en ambas divisiones, imposibilidad de doble fichaje, prioridad salarial y desempate por clasificación, oferta humana aceptada sin firma automática, reserva médica limitada al 90 % de gasto y actualización salarial sin repetir aumentos ni alterar devengos previos.

La integración HTTP avanza septiembre con un financiero contratado, verifica los acuerdos y el libro de movimientos, y comprueba previsiones cercanas al equilibrio en los veinte clubes. Todas las peticiones incluyen correlación con la auditoría nativa. Se revisó visualmente el presupuesto y la fila de campo, posesión y velocidad en un partido pausado. Evidencias externas: `rugby-shared-market`.

La publicación conserva los 8.501 registros anteriores y añade 160 ajustes salariales de técnicos y 11 acuerdos públicos complementarios futuros. No modifica saldos, movimientos anteriores, contratos de jugadores, negociaciones, partidos ni jugadores contratados. Mejora 45 agentes generados sin equipo y sin historial de contratación. Las ayudas ya pagadas permanecen intactas: nueve clubes conservan un excedente legado esta temporada, que no se elimina mediante cargos retroactivos. El arranque queda registrado en el mensaje nativo 56532, con los resultados de mercado, salarios y planificación financiera.
