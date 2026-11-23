# Statistiques

[Español](../ESTADISTICAS.md) · [English](../en/ESTADISTICAS.md) · [Français](ESTADISTICAS.md) · [Index](README.md)

Les fiches des joueurs comprennent historique paginé, totaux et détail des actions. Le résumé du match présente les deux équipes. Les matchs en direct attribuent les actions aux participants ; les automatiques stockent les statistiques du modèle résumé, pondérées par attributs et minutes. Le club représenté est conservé et les réessais ne créent pas de doublons.

`GET /players/{playerId}/match-stats` consulte l'historique ; `GET /competitions/{competitionId}/statistics`, les Top 10. Les deux requêtes sont limitées à la partie privée et passent par l'interopérabilité.

Compétition sépare Classement, Calendrier et Statistiques pour championnat et coupe. Les Top 10 cumulent les matchs terminés de la compétition et de la saison choisies, finales incluses. Un joueur transféré apparaît une seule fois, avec le dernier club représenté dans cette compétition.

Catégories : attaque, défense, jeu au pied, phases statiques, discipline et participation. Les totaux sont décroissants, sans valeurs nulles ni remplaçants inutilisés. Discipline affiche les plus grands nombres de fautes et cartons. Les historiques incomplets sont signalés.

`Rugby.Analytics.PlayerMatch` stocke métriques et clés en colonnes, avec une clé unique par enregistrement d'origine, sans dupliquer les documents JSON. SQL agrège par partie, compétition et joueur. La migration initiale est automatique et idempotente ; les nouveaux matchs actualisent leur projection dans la même transaction. La suppression d'une partie supprime aussi sa projection analytique.

[Stockage en colonnes IRIS](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_storageglobals#GOBJ_storageglobals_columnar).

La ligue et les clubs participants sont vérifiés selon le match et la compétition d’origine ; les amicaux ne figurent pas dans les classements de ligue. L’appartenance historique est conservée après promotion, relégation ou transfert.
