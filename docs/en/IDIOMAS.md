# Languages

[Español](../IDIOMAS.md) · [English](IDIOMAS.md) · [Français](../fr/IDIOMAS.md) · [Index](README.md)

The interface supports Spanish, English and French. The language selector appears on sign-in, My games, administration and the game top bar. The browser remembers the choice; changes apply without reloading or losing open form values.

Dates, numbers and amounts follow the selected locale. People, clubs, grounds, sponsors, saved-game names and official mottos keep their original names. Identifiers, tactics and stored game data do not change language.

Catalogues in `rugby-frontend/src/i18n` cover interface text, variable messages, injuries, commentary and API errors. Historical messages are translated when displayed, without duplicating data in IRIS. Name parameters are preserved; descriptive values are translated explicitly.

From the repository root, run `npm run test:e2e --prefix rugby-frontend -- i18n.spec.ts` to check both catalogues, placeholders, rugby terminology and errors.
