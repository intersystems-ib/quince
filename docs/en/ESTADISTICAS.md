# Statistics

[Español](../ESTADISTICAS.md) · [English](ESTADISTICAS.md) · [Français](../fr/ESTADISTICAS.md) · [Index](README.md)

Player profiles include paginated match history, totals and action details. Match summaries show both teams. Live matches credit actions to participants; automatic fixtures store summary-model statistics weighted by attributes and minutes. The represented club is retained and retries create no duplicate records.

`GET /players/{playerId}/match-stats` retrieves history; `GET /competitions/{competitionId}/statistics` retrieves Top 10 lists. Both are private-game scoped and pass through interoperability.

Competition separates Standings, Calendar and Statistics for leagues and the cup. Top 10 lists accumulate finished matches in the selected competition and season, including finals. A transferred player appears once, showing the last club represented in that competition.

Categories cover attack, defence, kicking, set pieces, discipline and participation. Totals sort descending, excluding zeros and unused substitutes. Discipline shows the largest infringement and card counts. Incomplete historical records are identified.

`Rugby.Analytics.PlayerMatch` stores metrics and keys in columns, uniquely keyed by the original record, without duplicating JSON documents. SQL aggregates by game, competition and player. Initial migration is automatic and idempotent; new match projections update in the same transaction. Deleting a game also deletes its analytical projection.

[IRIS columnar storage](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GOBJ_storageglobals#GOBJ_storageglobals_columnar).
