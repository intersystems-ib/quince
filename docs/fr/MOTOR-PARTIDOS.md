# Moteur des matchs

[Español](../MOTOR-PARTIDOS.md) · [English](../en/MOTOR-PARTIDOS.md) · [Français](MOTOR-PARTIDOS.md) · [Index](README.md)

Les actions utilisent les participants adaptés : avants en mêlée, maul et ruck ; réceptionneurs, passeurs, buteurs et défenseurs dans le jeu courant. Attributs, énergie, moral et tactique interviennent. Changer de poste dans la même ligne ne réduit ni le moral ni les attributs ; passer entre avants et trois-quarts peut réduire temporairement le moral.

Le match conserve graine, chronomètre, ballon, coordonnées, statistiques et commandes. Les joueurs bougent selon la phase et la possession ; l'animation interpole les états reçus.

Toutes les vitesses suivent les mêmes règles sportives. La pause est manuelle ou automatique à la mi-temps et lors d'une blessure dans votre équipe ; choisir une vitesse relance le jeu. Les remplacements ont lieu ballon mort et sont revérifiés avant exécution.

Voir [Règles](REGLAS.md), [Tactiques](TACTICAS.md), [Cartons](DISCIPLINA.md) et [Blessures](LESIONES.md).

Avant le coup d’envoi, choisissez **Visualiser** pour le direct avec réglage de vitesse ou **Résultat**. Résultat simule la première mi-temps au lancement, s’arrête à la pause pour les remplacements et la tactique, puis termine la seconde avec **Aller au résultat final**. Les deux modes utilisent le même moteur : blessures, cartons, temps additionnel, statistiques et bilan financier. Résultat ne présente pas de pauses intermédiaires. Le mode est fixé au lancement et conservé après rechargement.

La sélection privilégie la meilleure moyenne par poste et un banc équilibré de cinq avants et trois trois-quarts, couvrant les postes selon les disponibilités. Pendant les matchs, l’IA remplace en priorité blessés et joueurs fatigués par les meilleurs remplaçants compatibles, dans la limite de huit changements. Les [tactiques](TACTICAS.md) s’adaptent au score, au temps et à l’énergie, en direct, en mode Résultat et en simulation abrégée.
