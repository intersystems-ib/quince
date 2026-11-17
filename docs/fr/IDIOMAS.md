# Langues

[Español](../IDIOMAS.md) · [English](../en/IDIOMAS.md) · [Français](IDIOMAS.md) · [Index](README.md)

L'interface est disponible en espagnol, anglais et français. Le sélecteur apparaît à la connexion, dans Mes parties, l'administration et la barre supérieure du jeu. Le navigateur mémorise le choix ; le changement s'applique sans rechargement ni perte des valeurs des formulaires ouverts.

Dates, nombres et montants suivent la langue choisie. Les noms de personnes, clubs, stades, sponsors, parties et devises officielles conservent leur forme originale. Identifiants, tactiques et données enregistrées ne changent pas de langue.

Les catalogues de `rugby-frontend/src/i18n` couvrent interface, messages variables, blessures, commentaires et erreurs d'API. Les messages historiques sont traduits à l'affichage, sans duplication dans IRIS. Les paramètres contenant des noms sont conservés ; les valeurs descriptives sont traduites explicitement.

Depuis la racine du dépôt, exécutez `npm run test:e2e --prefix rugby-frontend -- i18n.spec.ts` pour vérifier les deux catalogues, paramètres, termes du rugby et erreurs.
