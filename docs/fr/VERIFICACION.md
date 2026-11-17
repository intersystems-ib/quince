# Vérification

[Español](../VERIFICACION.md) · [English](../en/VERIFICACION.md) · [Français](VERIFICACION.md) · [Index](README.md)

Depuis la racine du dépôt, `./scripts/test.ps1` exécute les groupes de `Rugby.Test.Suite` et compile l'interface. Les cas IRIS annulent leurs données après exécution. Les intégrations qui créent ou font avancer des parties nécessitent une instance jetable.

La couverture comprend compétitions, saisons, compositions, entraînement, moral, blessures, cartons, matchs, salaires, finances, marché, sécurité et idempotence :

- Composition : échanges, disponibilité, capitaine, validation et pénalités de moral.
- Contrats : durée, préférences d'âge, contre-offres, échéances initiales, promotions, prolongations et réessais, y compris les prolongations sans hausse au-delà du plafond.
- Compétition : poules de coupe, dates, terrains, bonus, élimination directe, classement et génération du calendrier.
- Entraînement et statistiques : programmes hebdomadaires, évolution selon l'âge, cumuls de saison et rapprochement avec le score.
- Marché : jusqu'à vingt joueurs générés, mises en vente de clubs, arrivées hebdomadaires d'étrangers, sorties par moyenne, négociation et concurrence entre clubs.
- Personnel : trois candidats par spécialité, recrutement, remplacement des postes vacants et historique contractuel.
- Matchs : commandes individuelles et multiples, pauses, blessures, cartons, statistiques et persistance des états.

Les intégrations HTTP utilisent `RUGBY_API_BASE` et enregistrent leurs résultats dans `RUGBY_TEST_ARTIFACTS`. Captures et fichiers temporaires restent hors du projet. Les opérations sont auditées dans le visualiseur de messages IRIS.

Les vérifications visuelles couvrent compositions, entraînements, contrats, calendrier, finances, commandes de match et langues sur ordinateur et mobile.

Depuis `rugby-frontend`, `npx playwright test advanceUntilEvent.spec.ts` vérifie réunions, matchs, arrêt, actualisation du calendrier, erreurs et limite de jours. `npx playwright test i18n.spec.ts` vérifie catalogues, paramètres, terminologie et erreurs d'API.
