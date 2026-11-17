# Stockage

[Español](../almacenamiento.md) · [English](../en/almacenamiento.md) · [Français](almacenamiento.md) · [Index](README.md)

- Les messages et journaux d'interopérabilité sont conservés deux jours, en respectant les sessions actives.
- Les réponses complètes sont envoyées uniquement au client ; l'audit conserve résumés et identifiants.
- L'entraînement garde des reçus minimaux pour l'idempotence et la paie. Aucun détail quotidien par joueur ni copie du programme ou du staff n'est conservé.
- La fiche du joueur utilise des cumuls par attribut et par saison.
- Parties, contrats, résultats, statistiques des joueurs et mouvements financiers sont conservés.

Pour réduire une installation existante, arrêtez la production d'interopérabilité et exécutez dans `RUGBY` :

```objectscript
set report=##class(Rugby.Service.StorageMaintenance).Reduce()
do ##class(Rugby.Service.StorageMaintenance).Daily()
```

L'opération ne crée aucune copie de sauvegarde. Récupérez ensuite l'espace physique avec `SYS.Database.FileCompact` et `SYS.Database.ReturnUnusedSpace` dans `%SYS`, en utilisant le répertoire de la base concernée.
