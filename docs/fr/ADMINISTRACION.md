# Administration des données initiales

[Español](../ADMINISTRACION.md) · [English](../en/ADMINISTRACION.md) · [Français](ADMINISTRACION.md) · [Index](README.md)

Le formulaire unique **Se connecter** reconnaît les identifiants IRIS actifs et ouvre l'administration. Les comptes du jeu accèdent à leurs parties. Les utilisateurs IRIS ne s'inscrivent pas dans Quince ; leurs identifiants sont réservés à l'administration. L'authentification native IRIS refuse les comptes désactivés, expirés ou nécessitant un changement de mot de passe. Une session administrative ne peut ni lister, ni créer, ni charger des parties ; les comptes du jeu ne peuvent pas utiliser l'API administrative.

**Clubs** permet de modifier noms, localité, couleurs, stade, capacité et écusson. Les images PNG, JPEG et WebP de 5 Mo maximum sont adaptées à 128 pixels et stockées avec les données. **Écusson d'origine** restaure l'image déployée. **Autres données** modifie les champs supplémentaires. Identifiant, dates de simulation et division restent fixes pour conserver la structure des compétitions.

**Joueurs** permet la recherche par nom, le filtrage par club et la modification d'identité, âge, catégorie, postes, nationalité, salaire mensuel, énergie, moral et des dix-sept attributs. **Ajouter un joueur** affecte un nouveau joueur à un club existant. La moyenne est calculée à partir des attributs, validés entre 1 et 100 avec décimales internes. L'interface utilise les euros ; l'API, les centimes.

**Enregistrer les données initiales** applique les changements aux nouvelles parties. Les parties existantes conservent leurs données et leur progression. Modifications et écussons persistent dans le volume IRIS après redémarrage ou reconstruction. L'enregistrement vérifie la version ; **Recharger la fiche** récupère l'état actuel après une modification concurrente.

L'API utilise `/auth/login`, `/admin/clubs` et `/admin/players`. Lectures et écritures suivent `HTTP.In → API.Process → Admin.Operation`, avec audit natif d'interopérabilité. Les mots de passe et les données binaires des écussons sont masqués dans le message d'entrée.
