# Access and games

[Español](../ACCESO-PARTIDAS.md) · [English](ACCESO-PARTIDAS.md) · [Français](../fr/ACCESO-PARTIDAS.md) · [Index](README.md)

Create an account or sign in. **My games** lets you create, load and delete your own games. Each starts on 1 September after choosing a division and club.

Sessions use JWT in an HttpOnly cookie. Games and their data are isolated by user; signing out pauses that user's matches. Loading another game preserves the previous one.

The top bar contains the day controls and a date that opens Calendar. Unsaved training or line-up changes block progress.

Calendar displays months, results and friendlies. Choose one of three proposed opponents or respond to an automatic invitation. Other clubs request at most one friendly per month, on a free weekend; accepting adds it to the calendar.

You cannot advance past pending fixtures or while a match is in progress. The `iris-data` volume preserves progress when containers restart.

Club data refreshes after a match. If advancing detects an old version, it reloads and retries once without advancing twice.
