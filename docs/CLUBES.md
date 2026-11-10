# Catálogo de equipos oficiales · temporada 2026/2027

Fuente solicitada por el usuario y comprobada el **7 de noviembre de 2026**:

- [División de Honor masculina · competición 416](https://resultadosrugby.isquad.es/competicion.php?id_superficie=1&seleccion=0&id_competicion=416&id_temp=2627&id_ambito=1&id_territorial=9999).
- [División de Honor Élite · competición 417](https://resultadosrugby.isquad.es/competicion.php?id_superficie=1&seleccion=0&id_competicion=417&id_temp=2627&id_ambito=1&id_territorial=9999).

La segunda página identifica expresamente la competición como **División de Honor Élite**, segunda categoría en estas fuentes. No se ha confundido con los grupos de División de Honor B.

Se importan los **20 equipos** mostrados en los listados de las dos competiciones, diez por categoría. `iris/data/clubs.json` conserva nombre oficial, nombre legible, abreviatura, identificador de equipo de iSquad, competición y fecha de verificación. La API añade el enlace de procedencia por club. No se importan clasificación, resultados ni calendarios oficiales. Las identidades de jugadores se extraen de las diez actas aportadas por el usuario.

Al crear una partida se elige uno de los veinte clubes. Cada equipo empieza con 23 jugadores sénior reales de la convocatoria de la primera jornada, una cantera generada de al menos veinte juveniles, una alineación válida y presupuesto de juego. Los colores de interfaz son tonos asignados para distinguir equipos; no se presentan como colores corporativos verificados. Los escudos son las imágenes originales descargadas de los listados de la Federación; ver [procedencia de los escudos](ESCUDOS.md). Ciudades y nombres cortos son metadatos de presentación, editables en el catálogo.

Los amistosos se generan cada tres días contra los otros 19 equipos; no reproducen el calendario oficial. En una instalación que ya tuviera la primera demostración, la migración 4 actualiza los datos de los cuatro clubes existentes, añade los demás sin duplicados y conserva jugadores, ascensos, planes, saldos y resultados. En los partidos ya creados solo actualiza nombres y colores de equipo, no sus instantáneas deportivas. Las seis fechas anteriores se conservan para no romper encuentros iniciados; se completan las restantes. Una partida nueva genera los 19 rivales desde el principio.

Para actualizar el catálogo en el futuro, editar el JSON y añadir una nueva migración de seed; no sobrescribir partidas en cada arranque. El juego no depende de que la web de FER esté disponible después de inicializar.


Actualización: las identidades del primer equipo de los veinte clubes proceden ahora de las diez actas de la primera jornada facilitadas por el usuario: 460 convocados. Las edades, salarios y atributos siguen siendo simulados. Ver [plantillas reales y procedencia](PLANTILLAS-REALES.md).

Cada club dispone de dos paletas de equipación para la simulación. El partido selecciona una combinación diferenciable, dando prioridad al cambio de camiseta del visitante. Ver [equipaciones y contraste](EQUIPACIONES.md).
