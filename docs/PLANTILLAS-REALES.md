# Jugadores reales de ambas divisiones

El catálogo incorpora **460 jugadores: 230 de División de Honor y 230 de División de Honor Élite**, correspondientes a los quince titulares y ocho suplentes de cada uno de los veinte clubes en las diez actas de la primera jornada aportadas por el usuario. Son convocatorias de esa jornada, no plantillas completas de toda la temporada.

| Acta | Competición | Club local | Club visitante |
|---|---|---|---|
| 17643 | Honor | VRAC Quesos Entrepinares | Huesitos La Vila |
| 17644 | Honor | Silicius Alcobendas | Complutense Cisneros |
| 17645 | Honor | CRC Pozuelo | Burgos Aparejadores |
| 17646 | Honor | Inversus Liceo Francés | AMPO Ordizia |
| 17647 | Honor | UE Santboiana | El Salvador |
| 17733 | Élite | Barça Rugbi | CR Sant Cugat |
| 17734 | Élite | Steelphalt Getxo | Hernani CRE |
| 17735 | Élite | Torrealday Gernika | Real Ciencias Sevilla |
| 17736 | Élite | Fénix Zaragoza | C.P. Les Abelles |
| 17737 | Élite | Valencia RC | Industriales Las Rozas |

Los originales se leyeron desde `C:/Users/lperezra/Downloads/acta_rugby_{id}.pdf`. El catálogo versionado [real-rosters.json](../iris/data/real-rosters.json) conserva el nombre original, el nombre de presentación, club, fecha y código del encuentro, página, categoría de inscripción, primera línea y procedencia de la posición. Cada PDF tiene una huella SHA-256 para identificar exactamente la fuente utilizada. No se importaron médicos, árbitros, delegados ni entrenadores como jugadores.

## Datos reales y simulados

Los nombres se muestran como nombre y apellidos, conservando las letras del original sin añadir acentos no documentados. Se comprobaron visualmente las primeras páginas de las diez actas, incluidos nombres que ocupaban dos líneas. Los jugadores reales se identifican en su ficha junto con el documento de procedencia.

Las actas no acreditan fecha de nacimiento, nacionalidad, salario ni los diecisiete atributos del juego. Las edades, salarios, atributos, energía y progresión existentes se conservan como datos de simulación. La nacionalidad de estas identidades se indica como **No verificada**: la clasificación federativa A/B/C no se interpreta como país. Los filtros del mercado distinguen la nacionalidad sin verificar de los extranjeros acreditados en los datos del juego.

Los titulares reciben la posición que ocuparon en el encuentro. Para suplentes se utilizan las habilitaciones de primera línea y se infiere la posición a partir del jugador sustituido, siguiendo también cadenas de cambios. Cuando esa información falta o es incoherente se marca `simulation-estimate`. El dorsal del acta queda únicamente en el catálogo de procedencia; no se asigna un dorsal permanente al jugador. Entre primeras líneas con varias habilitaciones se eligen posiciones principales compatibles para cubrir los tres puestos con jugadores distintos.

El acta de Les Abelles no permite certificar un tercer suplente especialista de primera línea. Se conservan sus 23 jugadores en plantilla y el banquillo inicial del juego utiliza siete, conforme a la validación del motor, en lugar de inventar una habilitación. Los equipos automáticos siguen eligiendo sus alineaciones mediante sus reglas habituales.

## Partidas existentes y nuevas

`Rugby.Seed.RealPlayers` aplica el catálogo una sola vez por partida y versión. Los identificadores de los 460 jugadores iniciales se conservan: cambian nombre, posiciones y metadatos de identidad, manteniendo club actual, fichajes, rescisiones, salarios, atributos, energía, fecha y saldo. No se devuelven a su club original jugadores que ya hubieran salido de él. Las canteras y los agentes libres generados conservan sus identidades ficticias. Los resultados y las instantáneas históricas de partidos no se reescriben.

Las nuevas partidas incorporan el catálogo después de crear los datos base. Las existentes se actualizan desde **System.In → API.Process → System.Operation** durante el arranque; el mensaje nativo de respuesta contiene `realRosterImports`, con versión y recuentos por partida. No se añade una pantalla de auditoría.

## Reproducción y pruebas

La extracción se reproduce con `scripts/extract_match_rosters.py --source-dir <carpeta de las diez actas>`, utilizando `pdfplumber`. El script valida diez documentos, veinte clubes, 23 jugadores ordenados por convocatoria y 460 nombres únicos.

`Rugby.Test.RealPlayers` comprueba las identidades de las dos divisiones, procedencia, nombres de varias líneas, ausencia de dorsales permanentes, alineaciones jugables, migración sin pérdida de progreso y ejecución idempotente. `scripts/real_rosters_integration.py` exige la instancia desechable del puerto 52776 y comprueba ambas divisiones mediante la API, incluidas fichas y nombres de los partidos.

Ficha de un jugador real de División Élite
