# Comparaison des équipes et tactiques

[Español](../TACTICAS.md) · [English](../en/TACTICAS.md) · [Français](TACTICAS.md) · [Index](README.md)

L'avant-match compare les 17 attributs du XV choisi et propose des vues avants (8) et trois-quarts (7). Il affiche écussons, moyennes, énergie et moral. Les valeurs sont les moyennes arithmétiques des titulaires du groupe, sans remplaçants ni arrondi interne ; l'interface affiche des entiers. Consulter l'avant-match ne lance pas la rencontre.

L'adversaire compare ses unités aux autres pour choisir jeu à la main, équilibré ou au pied. Il évalue passe, manipulation, attaque, vitesse, agilité, plaquage, lecture défensive, phases statiques et meilleur buteur. Les valeurs effectives comprennent énergie, moral et forme ; une exclusion affaiblit l'unité. Les avantages sont proportionnels, notamment entre réceptionneurs spécialistes et buteur, pour rester pertinents avec différentes échelles d'attributs. Fatigue, endurance, discipline et avantages relatifs déterminent rythme, pression et priorité sur pénalités. Une pression faible réduit fatigue et efficacité défensive ; une pression élevée augmente les deux. À rythme normal, une pression faible consomme environ 18 % d'énergie de moins que la normale. Elle ne modifie ni les attributs enregistrés ni les décisions de l'utilisateur.

L’IA réévalue ses consignes au coup d’envoi et aux arrêts de jeu, normalement toutes les cinq minutes. Un changement de score, une exclusion ou un seuil de fatigue peut avancer la révision après un délai d’une minute ; la pause et les remplacements permettent une réévaluation plus rapide. Chaque équipe conserve sa propre analyse. Les changements en direct passent par la file de commandes et les commentaires habituels, sans modifier les décisions de l’utilisateur ni consommer de tirage aléatoire.

Dans les vingt dernières minutes, l’équipe qui mène ralentit et recherche le contrôle territorial. Avec au plus trois points de retard, elle privilégie les poteaux ; au-delà, elle cherche l’essai par la touche ou le jeu rapide selon ses forces. Une énergie suffisante permet d’accélérer et de presser davantage ; sous 50, le rythme baisse, et sous 45, la pression aussi, même avec un retard au score.

Les rencontres entre clubs automatiques conservent leur simulation abrégée : les révisions se limitent à quelques occasions de marquer et au début de chaque période. Elles réutilisent la comparaison initiale et ajustent rythme, pression et priorité selon le score et l’énergie des joueurs présents, sans recalculer les 17 attributs. Elles n’exécutent pas le moteur visuel et ne stockent pas l’historique des analyses : seule la dernière de chaque équipe est conservée.

La **priorité sur pénalités** se choisit dans la composition, le rapport du staff ou les consignes pendant le match :

- **Selon le contexte :** évalue score, temps, portée du buteur et forces des deux équipes.
- **Assurer les points :** privilégie les pénalités à portée ; sinon, cherche la touche.
- **Chercher l'essai :** gagne du terrain en touche et conserve le lancer.
- **Jouer rapidement :** recherche la continuité avec un porteur disponible. Attributs, énergie et défenseurs participants influencent le résultat : mètres, essai ou perte de possession.

La réussite au but dépend de la distance, de l'angle et du niveau effectif du buteur. Les décisions figurent dans les commentaires et l'audit. Un tir manqué sortant par l'en-but entraîne un renvoi aux 22 mètres. Une tactique sans priorité explicite utilise le contexte. Les matchs automatiques pondèrent occasions d'essai et tirs au but selon la priorité adverse.

Références : [pénalités, World Rugby](https://passport.world.rugby/laws-of-the-game/laws-by-number/20-penalty-and-free-kick/) et [renvois](https://passport.world.rugby/laws-of-the-game/laws-by-number/12-kick-off-and-restart-kicks/).

Chaque période continue après le temps réglementaire jusqu'au ballon mort, en respectant transformations et pénalités en attente. Dans le jeu courant, l'équipe qui mène cherche la touche pour terminer ; celle qui perd évite les dégagements qui rendent la possession. Le temps additionnel apparaît en rouge. Exclusions, fatigue et minutes jouées continuent de s'accumuler. La deuxième mi-temps commence à la minute 40 de l'affichage. [Règle 5 de World Rugby](https://passport.world.rugby/laws-of-the-game/laws-by-number/5-time/).
