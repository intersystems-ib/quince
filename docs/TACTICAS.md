# Comparativa y tácticas del partido

La previa compara las 17 características del XV elegido y permite consultar delanteros (8) y tres cuartos (7). Conserva los escudos y muestra promedio, energía y moral. Los valores son medias aritméticas de los titulares del grupo, sin suplentes ni redondeos internos. La interfaz muestra enteros. Consultar la previa no inicia el encuentro.

El rival compara sus unidades con las contrarias para elegir juego a la mano, equilibrado o al pie. Valora pase, manejo, ataque, velocidad, agilidad, placaje, lectura defensiva, formaciones y su mejor pateador. Usa valores efectivos que incluyen energía, moral y forma; una exclusión reduce la fuerza de la unidad. El cansancio, la resistencia y la disciplina condicionan ritmo y presión. No modifica los atributos guardados ni las decisiones del usuario.

Se evalúa al comenzar y de nuevo con balón parado cuando han transcurrido al menos diez minutos de juego desde la última revisión. El marcador y la táctica contraria también influyen. Los cambios se tramitan por la cola habitual y quedan explicados en la narración. Las decisiones no consumen azar y se guardan para recuperar el partido. Los encuentros automáticos también comparan ambos XV, con una influencia acotada sobre su cálculo; no se recalculan resultados anteriores.

La API expone GET /matches/{matchId}/comparison mediante el business service, proceso y operación existentes. Las evaluaciones iniciales y periódicas constan en los mensajes de interoperabilidad; los cambios efectivos incluyen tacticalDecision en el evento. No se añade otra pantalla de auditoría.

El icono de la aplicación, navegador e instalación utiliza el PNG original aportado por el usuario, también visible junto a la marca Quince.

Validación: 29 grupos de pruebas IRIS, comprobación HTTP de las medias de ambos equipos y los tres grupos, revisión visual e inicio en una partida desechable.
