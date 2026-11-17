# Architecture

[Español](../ARQUITECTURA.md) · [English](../en/ARQUITECTURA.md) · [Français](ARQUITECTURA.md) · [Index](README.md)

React et TypeScript consomment une API de même origine. Nginx et Web Gateway relient l'interface à IRIS :

`Rugby.API.REST → HTTP.In → API.Process → Business Operation → services → modèles persistants`.

Les entités stockent des documents JSON versionnés, isolés par partie. Le JWT identifie l'utilisateur et `X-Game-Id` sélectionne sa partie ; le serveur valide propriété et autorisations. Les statistiques des joueurs utilisent aussi des projections compactes en colonnes.

Les écritures utilisent verrous, transactions et clés de réessai. Le processus des matchs valide états, événements et commandes indépendamment du navigateur. La graine permet de reproduire les simulations ; la vitesse ne modifie pas les tirages sportifs.

Code : `../../iris/src`, `../../rugby-frontend/src` et `../../webgateway`. L'application ne propose ni mode multijoueur ni simulation physique complète.
