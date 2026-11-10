# Escudos de los clubes

Se guardan los veinte archivos originales JPEG que muestra FERugby/iSquad en los listados de División de Honor y División de Honor Élite, temporada 2026/2027. Descargados el 7 de noviembre de 2026 mediante los recursos observados en las páginas de competición.

- [División de Honor · competición 416](https://resultadosrugby.isquad.es/competicion.php?id_superficie=1&seleccion=0&id_competicion=416&id_temp=2627&id_ambito=1&id_territorial=9999).
- [División de Honor Élite · competición 417](https://resultadosrugby.isquad.es/competicion.php?id_superficie=1&seleccion=0&id_competicion=417&id_temp=2627&id_ambito=1&id_territorial=9999).

Archivos: `rugby-frontend/public/crests/c1.jpg` hasta `c20.jpg`. La correspondencia se verifica por el identificador `id_equipo` del enlace que contiene cada imagen, no por su orden de aparición. Los originales se conservaron sin recortar, redibujar o cambiar sus colores.

El manifiesto `rugby-frontend/public/crests/manifest.json` registra para cada escudo el club, identificador federativo, URL de origen, página de competición, fecha de descarga, dimensiones y SHA-256. Las veinte imágenes fueron abiertas y verificadas como JPEG, con resolución de al menos 800 × 800. Peso total: 4.981.833 bytes.

Los escudos se sirven desde el propio frontend: no se solicitan imágenes a la Federación durante el uso de la aplicación. `ClubCrest.tsx` los presenta manteniendo la proporción y utiliza un monograma únicamente si falta un archivo o no se puede cargar.

Se muestran en el catálogo, lateral del club, portada, preparación de encuentros, calendario, marcador en directo y resumen. No cambia el estado deportivo ni económico de la partida.

Para repetir la importación a partir de una exportación de recursos del navegador se incluye `scripts/import_crests.py` (Python 3 y Pillow). Recibe el JSON de recursos exportados y su correspondencia con los enlaces de equipo; valida las imágenes y genera los archivos locales y el manifiesto.

Verificado: compilación TypeScript/Vite y contenedor frontend correctos; las veinte rutas locales responden con los mismos hashes de los originales. En el catálogo se comprobaron 21 imágenes cargadas sin fallos: veinte equipos y el escudo del club en el lateral. Se revisó visualmente su proporción y presentación en las tarjetas.
