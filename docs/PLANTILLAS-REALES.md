# Jugadores reales

[Español](PLANTILLAS-REALES.md) · [English](en/PLANTILLAS-REALES.md) · [Français](fr/PLANTILLAS-REALES.md) · [Índice](README.md)

Las plantillas incluyen a los jugadores convocados en las distintas jornadas disponibles de Honor y Élite. Las 460 identidades de la primera jornada conservan sus identificadores; las incorporaciones se identifican por su registro FER, sin duplicar jugadores que aparecen en varios clubes. Edad, atributos y contratos son simulados. La cantera y los nuevos agentes son generados.

Las referencias individuales de Honor y Élite combinan convocatorias, titularidades, minutos reconstruidos de sustituciones y tarjetas, y anotaciones verificadas de las actas oficiales. Se excluyen los minutos ambiguos y las anotaciones cuyo total no coincide con el marcador. No se inventan placajes ni metros ganados.

Las medias conservan el nivel global de cada club y distinguen jugadores dentro de la misma división y familia de puestos. La IA combina estas referencias con atributos, energía, disponibilidad y posiciones observadas para elegir titulares y suplentes. La ficha del jugador separa la referencia FER de las estadísticas de su partida.

El resumen compacto se actualiza con `python scripts/refresh_spanish_match_evidence.py` (requiere `pdfplumber`). No se guardan los PDF en el proyecto.

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

La ampliación redistribuye la masa salarial inicial de cada club entre los jugadores de referencia, según nivel y participación, manteniendo su coste mensual. Los fichajes y renovaciones negociados conservan sus condiciones.

En Alineación, **Alineación automática** elige la mayor media en cada posición y completa un banquillo de cinco delanteros y tres tres cuartos, cubriendo pilares, talonador, segunda y tercera línea, medio melé, apertura y línea exterior. Selecciona las mejores medias compatibles con esa cobertura y se adapta a las bajas y a los efectivos disponibles. La energía y la moral sólo desempatan entre jugadores con la misma media. Conserva las tácticas y permite revisar los cambios antes de **Guardar alineación**. Los clubes gestionados por la IA utilizan el mismo criterio, con revisión antes de los partidos y cuando cambia la disponibilidad.

Durante los partidos la IA prioriza los lesionados y después a los más cansados. Elige al mejor suplente sano compatible con el puesto, sin reingresos ni cambios por jugadores expulsados. Los cambios por fatiga requieren un relevo claramente más fresco; se mantiene el límite de ocho sustituciones. Se aplica también en modo Resultado y en los encuentros simulados, con minutos y energía finales por jugador.
