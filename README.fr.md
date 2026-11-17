# Quince · Rugby Club Manager

[Español](README.md) · [English](README.en.md) · [Français](README.fr.md)

Jeu de gestion de rugby en espagnol, anglais et français, développé avec React, TypeScript et InterSystems IRIS. Il comprend vingt clubs de Honor et Élite, 460 identités réelles de joueurs et des parties privées avec authentification JWT. Les attributs, contrats et finances sont simulés.

## Démarrage

Docker Engine ou Docker Desktop avec conteneurs Linux et Compose v2 sont nécessaires. Depuis la racine du projet :

```powershell
Copy-Item .env.example .env
docker compose up -d --build
```

Sous Linux, utilisez `cp .env.example .env` pour la première commande.

Application : [localhost:5175](http://localhost:5175). [État de l'API](http://localhost:8085/api/v1/health). Vous pouvez aussi utiliser `./scripts/start.ps1`. L'image IRIS se configure dans `.env` ; la valeur par défaut est `latest-preview`.

Pour AWS, définissez `APP_PORT` dans `.env` (par exemple `80`) et autorisez ce port dans le groupe de sécurité de l'instance. Compose écoute sur toutes les interfaces : utilisez le domaine ou l'adresse IP publique. L'application relaie les requêtes API par `/api/v1` ; il n'est pas nécessaire d'exposer `API_PORT` (par défaut `8085`) dans le groupe de sécurité. `VITE_API_TARGET` sert uniquement au développement.

## Jouer

Créez un compte et une partie, puis choisissez une division et un club. La saison commence le 1er septembre. Gérez l'équipe première, le centre de formation, la composition, les entraînements, le personnel et les transferts. Avancez les jours et disputez les matchs en attente. Le calendrier permet d'organiser des amicaux et de répondre aux invitations des autres clubs.

Les matchs en direct proposent pause, vitesses, remplacements et changements tactiques. Ils s'arrêtent automatiquement à la mi-temps et lors d'une blessure dans votre équipe. Compétition sépare classement, calendrier et statistiques des joueurs en onglets. Les salaires sont versés en fin de mois ; le directeur financier négocie les recettes de septembre.

Votre club présente les blessures, recrutements de joueurs et de personnel et annonces de retraite de tous les clubs sur les sept derniers jours de jeu. Le sélecteur de langue mémorise votre choix sans recharger la partie.

## Développement et tests

```powershell
docker compose up -d iris webgateway
cd rugby-frontend
npm ci
npm run dev
```

Développement : [localhost:5176](http://localhost:5176). `VITE_API_TARGET` modifie l'API cible.

```powershell
./scripts/test.ps1
```

Les tests d'intégration qui font avancer des parties doivent utiliser une instance jetable. Voir [Vérification](docs/fr/VERIFICACION.md).

## Données et documentation

Le volume `iris-data` conserve les parties lors de l'arrêt ou de la recréation des conteneurs. `./scripts/reset.ps1 -ConfirmDeleteAllRugbyData` supprime définitivement toutes les données du projet.

- [Architecture](docs/fr/ARQUITECTURA.md) et [audit d'interopérabilité](docs/fr/INTEROPERABILIDAD.md).
- [Accès et parties](docs/fr/ACCESO-PARTIDAS.md) et [administration des données initiales](docs/fr/ADMINISTRACION.md).
- [Règles](docs/fr/REGLAS.md), [compétitions](docs/fr/COMPETICION.md) et [saisons](docs/fr/TEMPORADAS-CONTRATOS.md).
- [Joueurs](docs/fr/PLANTILLAS-REALES.md), [niveau](docs/fr/CALIDAD-EQUIPOS.md) et [centre de formation](docs/fr/CANTERA.md).
- [Préparation de l'adversaire et avance automatique](docs/fr/PREPARACION-RIVAL.md).
- [Entraînement](docs/fr/ENTRENAMIENTO.md), [blessures](docs/fr/LESIONES.md), [statistiques](docs/fr/ESTADISTICAS.md) et [moral](docs/fr/MORAL.md).
- [Transferts](docs/fr/FICHAJES.md), [finances](docs/fr/FINANZAS.md) et [salaires](docs/fr/SALARIOS-PRESUPUESTO.md).
- [Langues](docs/fr/IDIOMAS.md) et [stockage](docs/fr/almacenamiento.md).
- [Spécification de l'API](docs/openapi.json) : régénération avec `python scripts/generate_openapi.py`.

[Index complet de la documentation](docs/fr/README.md).
