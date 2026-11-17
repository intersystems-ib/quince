# Supprimer ses parties

[Español](../PARTIDAS.md) · [English](../en/PARTIDAS.md) · [Français](PARTIDAS.md) · [Index](README.md)

**Mes parties** propose Supprimer à côté de Charger une partie. La confirmation affiche nom, club et date et précise que la suppression est définitive. Annuler n'envoie aucune requête. Les boutons charger, supprimer et créer sont désactivés pendant l'opération. La carte disparaît après suppression ; s'il ne reste aucune partie, l'invitation à en créer une s'affiche.

`DELETE /api/v1/games/{gameId}` nécessite une session JWT, `Idempotency-Key` et `{"confirm":true}`. Le propriétaire est déterminé par la session, jamais par le corps ou l'en-tête de partie. Une partie inexistante ou appartenant à autrui renvoie 404 ; une confirmation absente renvoie 422.
