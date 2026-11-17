# Accès et parties

[Español](../ACCESO-PARTIDAS.md) · [English](../en/ACCESO-PARTIDAS.md) · [Français](ACCESO-PARTIDAS.md) · [Index](README.md)

Créez un compte ou connectez-vous. **Mes parties** permet de créer, charger et supprimer vos propres parties. Chacune commence le 1er septembre après le choix de la division et du club.

La session utilise un JWT dans un cookie HttpOnly. Les parties et leurs données sont isolées par utilisateur ; la déconnexion met ses matchs en pause. Charger une autre partie conserve la précédente.

La barre supérieure contient les commandes d'avance et la date qui ouvre Calendrier. Des modifications non enregistrées de composition ou d'entraînement bloquent l'avance.

Calendrier affiche les mois, résultats et amicaux. Choisissez parmi trois adversaires proposés ou répondez à une invitation automatique. Les autres clubs proposent au maximum un amical par mois, sur un week-end libre ; l'acceptation l'ajoute au calendrier.

Impossible d'avancer avec un match en attente ou en cours. Le volume `iris-data` conserve la progression au redémarrage des conteneurs.

Les données du club s'actualisent après un match. Si l'avance détecte une ancienne version, elle recharge les données et réessaie une fois, sans avancer deux fois.
