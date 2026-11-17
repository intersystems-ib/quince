# Deleting your games

[Español](../PARTIDAS.md) · [English](PARTIDAS.md) · [Français](../fr/PARTIDAS.md) · [Index](README.md)

**My games** provides a Delete button next to Load game. Confirmation shows the game name, club and date and warns that deletion is permanent. Cancelling sends no request. Load, delete and create buttons are disabled during deletion. The card disappears on success; deleting the last game shows the invitation to create a new one.

`DELETE /api/v1/games/{gameId}` requires a JWT session, `Idempotency-Key` and `{"confirm":true}`. Ownership comes from the session, never the body or game header. Other users' and nonexistent games return 404; missing confirmation returns 422.
