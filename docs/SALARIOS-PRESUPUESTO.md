# Salarios y nóminas mensuales

Jugadores, técnicos y financiero tienen un salario mensual en céntimos. Se devenga cada día con el divisor real del mes (28, 29, 30 o 31). El cierre del último día, al avanzar al mes siguiente, carga una nómina por colectivo con fecha del último día del mes. Incorporaciones, sustituciones y bajas cobran sólo la parte devengada. Los contratos vigentes continúan devengando durante el verano. Los reintentos no duplican cargos.

El campo semanal se conserva por compatibilidad con operaciones existentes; no determina la cadencia de pago. Una oferta de 2.000 €/mes se conserva y paga exactamente por ese importe, sin reconvertirla para su presentación.

## Referencias del primer equipo

| Grupo | Referencia mensual |
| --- | --- |
| Honor, puestos de referencia 1–3 | 850–2.400 € |
| Honor, puestos 4–7 | 800–2.000 € |
| Honor, puestos 8–10 | 450–1.400 € |
| División Élite | 300–1.100 € |
| Cantera de ambas divisiones | 30–100 € |

Se usa la clasificación de referencia que calibra la calidad del club, no el resultado de cada jornada. El reparto inicial refleja la calidad de cada jugador respecto de su plantilla; los mejores reciben una prima mayor. Las bandas son referencias de inicialización y futuras peticiones salariales, no una imposición sobre las negociaciones manuales. Se mantienen diferencias individuales y las referencias de promoción dependen del primer equipo del club de destino. La cantera sigue siendo mucho más económica.

El importe semanal inicial se redondea a euros enteros sin salir de los límites mensuales, por lo que, por ejemplo, el mínimo central resulta aproximadamente 802 €/mes y el máximo 1.998 €/mes. Las ofertas mensuales manuales admiten conversión a céntimos semanales para representar cantidades como 800 o 2.000 €/mes sin redondearlas a euros semanales.

## Límite presupuestario

La referencia anual de cada club continúa en 250.000–800.000 €. El límite de jugadores usa ahora ese presupuesto, en lugar del antiguo mínimo de financiación que dejaba salarios demasiado bajos. Es el menor entre el 65 % del presupuesto y el resto disponible tras reservar el 15 %, fichas del 3 %, viajes de 16.500 € y los máximos actuales de técnicos y financiero. Los ocho técnicos parten de un máximo conjunto del 22,5 % del presupuesto nominal, ponderado por especialidad y calidad. El financiero parte de hasta el 3 %. Un factor de capacidad del club adapta esas referencias a la plantilla existente. El entrenamiento no genera costes diarios adicionales ni reserva presupuestaria: queda cubierto por las nóminas de los empleados.

Se presupuestan doce nóminas mensuales. El límite de jugadores descuenta las nóminas reales de técnicos y financiero. Las contrataciones de empleados también comprueban la reserva del 15 %. Si el puesto de financiero está vacante, se reserva su salario básico al calcular el margen de otros contratos. El reparto intenta ocupar como máximo el 95 % del límite; cuando hay poco margen, se reducen las primas por calidad conservando el mínimo de cada categoría. Si los mínimos requieren algo más del 95 %, se permite hasta el 99,5 % del límite. Las peticiones de nuevos contratos y las renovaciones siguen comprobando el margen disponible.

Un club que hubiera contratado una plantilla excepcionalmente grande podría superar el límite incluso pagando los mínimos. En ese caso no se despiden jugadores ni se oculta el exceso: el margen de contratación queda negativo y se impiden compromisos adicionales que lo superen. Los veinte clubes iniciales se verifican contra el límite y su reserva del 15 %.

El presupuesto no se ingresa automáticamente. Finanzas muestra los ingresos previstos y su margen frente al gasto. El financiero adapta las ayudas de septiembre a los gastos y los otros ingresos, con un objetivo de margen reducido. La taquilla se cobra al acabar cada encuentro. Las ayudas ya concedidas no aumentan por cada fichaje posterior.

Los recambios por lesión pueden utilizar hasta cinco puntos adicionales del presupuesto reservado: límite global del 90 % y salarial de jugadores del 70 %, en vez de 85 % y 65 %. Se conserva al menos un 10 % de reserva y se exige necesidad real de cobertura del mismo grupo de posiciones, tanto para el usuario como para los rivales.

La referencia salarial de técnicos aumenta un 25 %. Para contratos existentes el incremento se limita al margen del club sin recortar salarios anteriores ni tocar pagos ya realizados. Se conserva el salario previo para devengos anteriores a la fecha de actualización.

## Actualización de partidas

La recalibración 3.0.0 se aplica una sola vez por partida a jugadores contratados y referencias de agentes libres. Crea nuevos registros de ajuste de contrato con importe anterior y nuevo; conserva contratos anteriores, vencimientos, saldos, movimientos históricos y salarios técnicos ya devengados. Conserva los anteriores salarios históricos de los agentes libres. No modifica calidad, edad, energía, moral, lesiones, club, posiciones, alineaciones ni resultados.

La migración mensual 1.0.0 eleva una sola vez los salarios de técnicos y financiero y registra los ajustes en la auditoría. Conserva los salarios mensuales de jugadores, saldos y movimientos ya pagados. Traslada los importes pendientes del antiguo ciclo semanal a la primera nómina mensual; no los perdona ni los vuelve a cobrar. La fecha de adopción separa el devengo histórico del nuevo cálculo diario.
