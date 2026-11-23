"""Canonical country labels for LNR imports (UI translations use Spanish keys)."""
COUNTRIES = {'France': ('FR', 'Francia'), 'Fidji': ('FJ', 'Fiyi'), 'Nouvelle Zélande': ('NZ', 'Nueva Zelanda'), 'Géorgie': ('GE', 'Georgia'), 'Australie': ('AU', 'Australia'), 'Afrique du Sud': ('ZA', 'Sudáfrica'), 'Argentine': ('AR', 'Argentina'), 'Italie': ('IT', 'Italia'), 'Angleterre': ('ENG', 'Inglaterra'), 'Grande-Bretagne': ('GB', 'Gran Bretaña'), 'Irlande': ('IE', 'Irlanda'), 'Tonga': ('TO', 'Tonga'), 'Espagne': ('ES', 'España'), 'Pays-Bas': ('NL', 'Países Bajos'), 'Ecosse': ('SCO', 'Escocia'), 'Belgique': ('BE', 'Bélgica'), 'Portugal': ('PT', 'Portugal'), 'Allemagne': ('DE', 'Alemania'), 'Canada': ('CA', 'Canadá'), 'Samoa occidental': ('WS', 'Samoa'), 'République Démocratique du Congo': ('CD', 'República Democrática del Congo'), 'Etats-Unis': ('US', 'Estados Unidos'), 'Chili': ('CL', 'Chile'), 'Zimbabwe': ('ZW', 'Zimbabue'), 'Pologne': ('PL', 'Polonia'), 'Samoa': ('WS', 'Samoa'), 'Autriche': ('AT', 'Austria'), 'Cameroun': ('CM', 'Camerún'), 'Russie': ('RU', 'Rusia'), 'Roumanie': ('RO', 'Rumanía'), 'Pays de Galles': ('WAL', 'Gales'), 'Namibie': ('NA', 'Namibia'), 'Suisse': ('CH', 'Suiza')}

COUNTRIES.update({'Moldavie': ('MD', 'Moldavia'), 'Finlande': ('FI', 'Finlandia'), 'Hongrie': ('HU', 'Hungría')})

def normalize_player(player):
    code, label = COUNTRIES.get(player.get("nationality", ""), (player.get("nationalityCode", ""), player.get("nationality", "No verificada")))
    player.update(nationalityCode=code, nationality=label)
