# Initial-data administration

[Español](../ADMINISTRACION.md) · [English](ADMINISTRACION.md) · [Français](../fr/ADMINISTRACION.md) · [Index](README.md)

The single **Sign in** form recognises active IRIS credentials and opens administration. Game accounts open their games. IRIS users do not register in Quince; their usernames are reserved for administration. Native IRIS authentication rejects disabled, expired or password-change-required accounts. Administrative sessions cannot list, create or load games; game accounts cannot use the administration API.

**Clubs** edits names, city, colours, ground, capacity and crest. PNG, JPEG and WebP crests up to 5 MB are resized to 128 pixels and stored with the data. **Original crest** restores the deployed image. **Other data** edits additional fields. Identifiers, simulation dates and division remain fixed to preserve the competition structure.

**Players** supports name search, club filtering, and editing identity, age, category, positions, nationality, monthly wage, energy, morale and all seventeen attributes. **Add player** assigns a new player to an existing club. The average is calculated from attributes, which are validated between 1 and 100 and retain internal decimals. The interface uses euros; the API uses cents.

**Save initial data** applies changes to new games. Existing games retain their own data and progress. Changes and crests survive restarts and rebuilds in the IRIS persistent volume. Saving checks the record version; **Reload record** retrieves the current state after concurrent edits.

The API uses `/auth/login`, `/admin/clubs` and `/admin/players`. Reads and writes follow `HTTP.In → API.Process → Admin.Operation`, with native interoperability audit. Passwords and binary crest contents are hidden in the input message.
