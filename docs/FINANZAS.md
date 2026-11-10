# Gestión financiera

El usuario contrata al financiero; éste tramita automáticamente los acuerdos de septiembre. Todos los nombres de empresas y los importes son simulados con la semilla de la partida.

## Presupuestos y financiación

Las referencias anuales están entre 250.000 y 800.000 euros. Los aspirantes al título tienen 650.000–800.000; los consolidados de Honor 400.000–600.000; los restantes clubes de Honor 300.000–375.000; Élite 250.000–350.000, con Real Ciencias en 400.000–500.000. La referencia es un techo de planificación, no un ingreso automático.

El 7 de septiembre se negocian un patrocinador principal (30.000–80.000 euros anuales) y cinco secundarios (5.000–10.000 cada uno). Hay dos ofertas por espacio; el financiero elige según importe y estabilidad. Los acuerdos duran una a tres temporadas.

El 14 se conceden dos subvenciones de organismos públicos genéricos, formados por institución y localidad. El 21 termina la campaña de abonados, a 150 euros por abono. Las subvenciones cubren la diferencia entre los gastos previstos y los demás ingresos esperados. El financiero pondera el objetivo de margen: aproximadamente −0,25 % con calidad 35, +1,25 % con 65 y hasta +3 % con 100. Los presupuestos resultan ajustados; contratar después más personal o jugadores puede producir déficit, pues no se amplía automáticamente una ayuda ya concedida.

El 28 se negocia la concesión del bar: un operador paga al club 25.000–45.000 euros por temporada, durante una a tres temporadas. El concesionario asume las ventas, personal y costes del bar. El club recibe únicamente el canon financiero.

Una mayor calidad del financiero incrementa las ofertas dentro de los rangos. El éxito deportivo usa la posición de liga cuando hay al menos tres partidos jugados; a falta de ella usa la temporada anterior o la clasificación de referencia. Puede aumentar o reducir las propuestas al negociar o renovar. Un acuerdo plurianual conserva el importe durante su vigencia.

El catálogo combina 40 sectores comerciales y 8 hosteleros con 100 marcas y la localidad. Las identidades se reservan por partida para evitar duplicados entre ofertas diferentes; la misma oferta mantiene su empresa al reintentar. Los contratos firmados corresponden a la oferta elegida.

## Cobros y partidos

Patrocinios y concesión se cobran en mensualidades entre septiembre y junio. El importe restante se divide entre los vencimientos pendientes; el último recoge el redondeo. Las claves de movimiento impiden duplicados. Los contratos siguen vigentes al cambiar de temporada hasta su vencimiento.

Los partidos nuevos generan sólo taquilla. Se conserva el precio de entrada elegido antes de empezar y la asistencia simulada; los abonados de liga regular no pagan otra vez. Los amistosos reparten la taquilla al 50 %, conservando los céntimos. El visitante de liga paga su desplazamiento. Los partidos ya liquidados conservan sus ingresos y costes anteriores de bar como historial.

## Sostenibilidad y partidas existentes

Los salarios de jugadores y empleados se presupuestan y pagan por mes. Los entrenamientos no tienen coste adicional. La previsión económica suma patrocinios, concesión, abonos, taquilla y subvenciones y la compara con las nóminas, fichas y viajes previstos. El presupuesto nominal es un límite de compromisos, separado del margen económico esperado. Véase [SALARIOS-PRESUPUESTO.md](SALARIOS-PRESUPUESTO.md).

La adopción en partidas existentes conserva la tesorería, contratos y cobros anteriores. Cuando una temporada con ayudas ya concedidas necesita financiación adicional, crea un acuerdo público complementario que se abona en los vencimientos futuros hasta junio. No ingresa dinero durante la actualización ni repite mensualidades anteriores. Los acuerdos plurianuales y las ayudas ya pagadas conservan sus compromisos históricos.

Fuera de septiembre se mantienen los contratos vigentes y la siguiente campaña se negocia en septiembre. La contratación tardía dentro de septiembre tramita los hitos vencidos. El financiero no cobra ingresos históricos por incorporarse al club.

Finanzas muestra referencia presupuestaria, acuerdos, concesión, abonados, previsión salarial, cobros reales y flujo mensual. Las operaciones mantienen la ruta API → business service → business process → business operation; la migración y los acuerdos constan en la auditoría nativa.
