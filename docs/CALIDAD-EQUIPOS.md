# Calidad inicial por club

Referencia consultada el 10 de noviembre de 2026: clasificaciones oficiales disponibles de primera fase, con cinco encuentros por equipo salvo Valencia y Sant Cugat (cuatro). Se conserva la clasificación publicada, incluidos desempates; no se ordena por puntos sin considerar su posición oficial.

[División de Honor](https://resultadosrugby.isquad.es/clasificacion.php?seleccion=0&id=1296&id_ambito=1&id_territorial=9999&id_superficie=1&iframe=0&id_categoria=0&id_competicion=416) · [División Élite](https://resultadosrugby.isquad.es/clasificacion.php?seleccion=0&id=1297&id_ambito=1&id_territorial=9999&id_superficie=1&iframe=0&id_categoria=0&id_competicion=417)

Las valoraciones son simuladas, no calificaciones oficiales. La referencia combina un 65 % del resultado de 2025–26 y un 35 % de la clasificación actual para los clubes presentes en la [temporada anterior](https://es.wikipedia.org/wiki/Divisi%C3%B3n_de_Honor_de_rugby_2025-26). Se ordenan campeón, finalista, semifinalistas y cuartofinalistas; los empates de ronda se resuelven por su puesto de liga regular. El resto conserva su puesto de liga regular. La escala de referencia de Honor es 68–80 y la de Élite 52–64, por lo que Honor mantiene un nivel superior. Los dos descendidos reales de Honor reciben la primera y segunda referencia histórica de Élite. Los clubes sin referencia histórica de Honor conservan su valor actual, sin inventar resultados. La cantera queda 18 puntos por debajo del objetivo del club.

| División | Club | Puesto actual | Puesto histórico Honor | Media primer equipo | Media cantera |
|---|---|---:|---:|---:|---:|
| Honor | Recoletas Salud Caja Rural Burgos Aparejadores | 1 | 2 | 79.13 | 61.13 |
| Honor | VRAC Quesos Entrepinares | 3 | 1 | 79.07 | 61.07 |
| Honor | Silicius Alcobendas Rugby | 5 | 3 | 76.40 | 58.40 |
| Honor | Inversus Liceo Frances | 7 | 4 | 74.60 | 56.60 |
| Honor | AMPO Ordizia | 2 | 7 | 74.33 | 56.33 |
| Honor | Complutense Cisneros | 8 | 5 | 73.27 | 55.27 |
| Honor | Vulcanizados Alvarez El Salvador | 4 | 8 | 72.53 | 54.53 |
| Honor | Huesitos La Vila Rugby Club | 9 | 6 | 71.93 | 53.93 |
| Honor | Unio Esportiva Santboiana | 6 | 9 | 70.73 | 52.73 |
| Honor | CRC Pozuelo Rugby | 10 | — | 68.00 | 50.00 |
| Élite | Torrealday Gernika Rugby Taldea | 1 | — | 64.00 | 46.00 |
| Élite | Cajasol Real Ciencias Sevilla | 2 | 10 | 63.53 | 45.53 |
| Élite | Steelphalt Getxo Rugby | 3 | — | 61.33 | 43.33 |
| Élite | Barça Rugbi | 6 | 11 | 60.80 | 42.80 |
| Élite | Recoletas Salud Fenix | 4 | — | 60.00 | 42.00 |
| Élite | Hernani CRE | 5 | — | 58.67 | 40.67 |
| Élite | A.D. Ingenieros Industriales Las Rozas Rugby | 7 | — | 56.00 | 38.00 |
| Élite | Valencia RC | 8 | — | 54.67 | 36.67 |
| Élite | Club de Rugby Sant Cugat | 9 | — | 53.33 | 35.33 |
| Élite | C.P. Les Abelles | 10 | — | 52.00 | 34.00 |

La versión v2 sustituye el desplazamiento anterior por la nueva referencia, conservando entrenamiento acumulado, edad y declive, en vez de forzar su media actual al objetivo. Los jugadores originalmente generados que cambiaron de equipo conservan el nivel de su club de origen; los agentes libres de mercado no se recalifican por fichar. Los jóvenes generados en el futuro reciben el nivel de cantera del club. No se vuelve a imponer la clasificación de referencia al avanzar o iniciar temporadas futuras.

La migración tiene un marcador por partida y por jugador; reiniciar no suma dos veces el desplazamiento. Se conserva por jugador el cambio efectivo de cada característica, incluido cualquier límite de 1 o 100. Se recalculan el promedio y su proyección con las reglas existentes. Los partidos ya iniciados conservan sus instantáneas y los resultados previos no se recalculan. Salarios, contratos, energía, moral, fechas y saldos se conservan.

La inicialización entra por System.In y su operación existente: qualityCalibration registra versión, clubes, puestos, objetivos, desplazamientos y número de jugadores afectados en la auditoría nativa.

Validación: medias iniciales, fórmula ponderada, migración sin duplicar ajustes y entrenamiento acumulado; API con los veinte clubes, ambos tipos de plantilla, límites, variación individual e idempotencia al cargar. La prueba de migración incluye un jugador transferido con entrenamiento acumulado. Evidencias: test-results/quality-core-validation.log, quality-http-validation.log y quality-http-means.json.
