# Joueurs réels

[Español](../PLANTILLAS-REALES.md) · [English](../en/PLANTILLAS-REALES.md) · [Français](PLANTILLAS-REALES.md) · [Index](README.md)

Les effectifs comprennent les joueurs convoqués lors des différentes journées disponibles d’Honor et d’Élite. Les 460 identités de la première journée conservent leurs identifiants ; les nouveaux joueurs utilisent leur inscription FER, sans doublons entre clubs. Âges, caractéristiques et contrats sont simulés. Jeunes et nouveaux agents libres sont générés.

Les références individuelles d’Honor et d’Élite combinent convocations, titularisations, minutes reconstituées à partir des remplacements et des cartons, et points vérifiés dans les feuilles officielles. Les minutes ambiguës et les totaux de points incompatibles avec le score sont exclus. Aucun placage ni mètre gagné n’est inventé.

Les notes conservent le niveau global de chaque club tout en différenciant les joueurs au sein de leur division et de leur famille de postes. L’IA combine ces références avec les caractéristiques, l’énergie, la disponibilité et les postes observés. Les fiches séparent les références FER des statistiques de la partie.

Le résumé compact s’actualise avec `python scripts/refresh_spanish_match_evidence.py` (`pdfplumber` requis). Les PDF ne sont pas stockés dans le projet.

| Feuille | Compétition | Club recevant | Club visiteur |
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

Les effectifs élargis se partagent la masse salariale mensuelle initiale selon leur niveau et leur participation. Les recrutements et renouvellements négociés conservent leurs conditions.

**Composition automatique** choisit la meilleure moyenne à chaque poste, puis complète un banc équilibré de cinq avants et trois trois-quarts, couvrant piliers, talonneur, deuxième et troisième ligne, demi de mêlée, ouvreur et ligne extérieure. Il choisit les meilleures moyennes compatibles avec cette couverture et s’adapte aux disponibilités. Énergie et moral départagent uniquement les moyennes égales. Les tactiques sont conservées ; la proposition reste modifiable avant l’enregistrement. Les clubs gérés par l’IA utilisent les mêmes critères, avec une révision avant les matchs et lors des changements de disponibilité.

Pendant les matchs, l’IA remplace en priorité les blessés puis les joueurs les plus fatigués, avec le meilleur remplaçant sain compatible avec le poste. Les changements pour fatigue exigent un joueur nettement plus frais. La limite de huit changements, les exclusions et l’absence de retour en jeu s’appliquent en direct, en mode Résultat et en simulation ; minutes et énergie finales reflètent la participation.
