# Real players

[Español](../PLANTILLAS-REALES.md) · [English](PLANTILLAS-REALES.md) · [Français](../fr/PLANTILLAS-REALES.md) · [Index](README.md)

Squads include players selected across the available Honor and Élite rounds. The 460 first-round identities retain their IDs; additional players use their FER registration, without duplicates across clubs. Ages, attributes and contracts are simulated. Academy players and new agents are generated.

Honor and Élite player references combine selections, starts, minutes reconstructed from substitutions and cards, and verified scoring from official match sheets. Ambiguous minutes and scoring totals that conflict with the final score are excluded. Tackles and metres are not invented.

Ratings retain each club’s overall level while differentiating players within their division and positional family. AI selection combines these references with skills, energy, availability and observed positions. Player profiles show FER reference data separately from saved-game statistics.

Refresh the compact summary with `python scripts/refresh_spanish_match_evidence.py` (requires `pdfplumber`). PDFs are not stored in the project.

| Report | Competition | Home club | Away club |
|---|---|---|---|
| 17643 | Honor | VRAC Quesos Entrepinares | Huesitos La Vila |
| 17644 | Honor | Silicius Alcobendas | Complutense Cisneros |
| 17645 | Honor | CRC Pozuelo | Burgos Aparejadores |
| 17646 | Honor | Inversus Liceo Francés | AMPO Ordizia |
| 17647 | Honor | UE Santboiana | El Salvador |
| 17733 | Élite | Barça Rugbi | CR Sant Cugat |
| 17734 | Élite | Steelphalt Getxo | Hernani CRE |
| 17735 | Élite | Torrealday Gernika | Real Ciencias Sevilla |
| 17736 | Élite | Fénix Zaragoza | C.P. Les Abelles |
| 17737 | Élite | Valencia RC | Industriales Las Rozas |

Expanded squads share the original monthly payroll according to ability and participation. Negotiated signings and renewals retain their terms.

**Automatic line-up** selects the highest average in each position, then fills a balanced bench of five forwards and three backs, covering props, hooker, lock, back row, scrum-half, fly-half and the outside backs. It selects the highest averages compatible with that coverage and adapts to availability. Energy and morale only break ties between equal averages. Tactics remain unchanged; review the draft before saving. AI clubs use the same criteria, reviewing selections before matches and after availability changes.

During matches, AI prioritises injuries, then the most fatigued players, choosing the best healthy reserve compatible with the position. Fatigue changes require a meaningfully fresher replacement. The eight-change limit, no re-entry and disciplinary exclusions apply in live, Result and simulated matches; minutes and final energy reflect participation.

Generated French academy players, coaches and financial directors combine 134 given names and 288 surnames through independent, reproducible selections. Existing saves update old generated identities while preserving attributes, wages and contracts; real identities and administrator name overrides remain unchanged.

The Spanish seed combines 166 player given names and 380 surnames; staff and financial directors have 103 additional given names. All three parts are selected independently, always retaining two surnames. Existing generated identities are repaired once without changing real names, custom names, sporting data or financial terms.
