# Interopérabilité

[Español](../INTEROPERABILIDAD.md) · [English](../en/INTEROPERABILIDAD.md) · [Français](INTEROPERABILIDAD.md) · [Index](README.md)

Les opérations de l'API suivent `Rugby.API.REST → HTTP.In → API.Process → Business Operation`. `API.Process` choisit l'opération métier. L'avance quotidienne passe par `Rivals.Process` et `Rivals.Operation`.

Chaque action est validée dans une transaction. L'avance quotidienne comprend le club géré, les adversaires, entraînements, finances et invitations aux amicaux. La simulation utilise un service de production et enregistre ses transitions.

L'audit est accessible dans le visualiseur natif des messages IRIS. Les réponses incluent `X-Request-Id` et `X-Interop-Session-Id` ; les messages persistés conservent résumés et identifiants, avec les identifiants de connexion masqués. La rétention est de deux jours, en respectant les sessions actives.

Le démarrage initialise les données et audite ses opérations. Les invitations aux amicaux suivent le même circuit, avec vérification de propriété et clés de réessai. Voir [Stockage](almacenamiento.md).
