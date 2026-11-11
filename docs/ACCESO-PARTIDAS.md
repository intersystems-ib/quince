# Acceso y partidas

Crea una cuenta o inicia sesión. En **Mis partidas** puedes crear, cargar o eliminar tus propias partidas. Cada una comienza el 1 de septiembre, tras elegir división y club.

La sesión utiliza JWT en cookie HttpOnly. Las partidas y sus datos están separados por usuario; cerrar sesión pausa sus encuentros. Cargar otra partida conserva la anterior.

«Avanzar día» está en la barra superior, junto a la fecha que abre Calendario. Los cambios de entrenamiento o alineación pendientes bloquean el avance.

Calendario muestra los meses, resultados y amistosos. Puedes elegir uno de tres rivales ofrecidos o responder a una invitación automática. Los rivales solicitan como máximo un amistoso al mes, en un fin de semana libre; aceptar lo incorpora al calendario.

No se puede avanzar con encuentros pendientes ni con un partido en curso. El volumen `iris-data` conserva el progreso al reiniciar los contenedores.

El club se actualiza al terminar el partido. Si avanzar detecta una versión anterior, recarga los datos y reintenta una vez, sin duplicar días.
