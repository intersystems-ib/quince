Class Rugby.Service.PlayerNames Extends %RegisteredObject
{
ClassMethod Spanish(seed As %Integer) As %String
{
    set given=$listbuild("Álvaro","Diego","Javier","Pablo","Sergio","Hugo","Mario","Daniel","Adrián","Iván","Marcos","Lucas","Rodrigo","Nicolás","Jaime","Miguel","Andrés","Gonzalo","Raúl","Manuel","Óscar","Bruno","Martín","Samuel","Rubén","Gabriel","Víctor","Iker","Unai","Ander","Pau","Pol")
    set surnames=$listbuild("García","Fernández","Martínez","López","Sánchez","Romero","Alonso","Ruiz","Navarro","Ortega","Molina","Serrano","Castro","Delgado","Vega","Iglesias","Moreno","Gil","Ramos","Santos","Torres","Vidal","Herrera","Pascual","Soler","Blanco","Prieto","Cruz","Medina","Sanz","Rivas","Fuentes","Méndez","Campos","Luna","Díaz","Gómez","Pérez","González","Hernández","Domínguez","Álvarez","Muñoz","Gutiérrez","Jiménez","Morales","Burgos","Cortés")
    set first=1+(##class(Rugby.Service.Rivals).Hash("given",seed)#$listlength(given)),surname1=1+(##class(Rugby.Service.Rivals).Hash("surname1",seed)#$listlength(surnames)),surname2=1+(##class(Rugby.Service.Rivals).Hash("surname2",seed)#($listlength(surnames)-1))
    if surname2>=surname1 set surname2=surname2+1
    quit $list(given,first)_" "_$list(surnames,surname1)_" "_$list(surnames,surname2)
}
ClassMethod French(seed As %Integer) As %String
{
    set given="Louis,Antoine,Hugo,Mathieu,Thomas,Maxime,Lucas,Pierre,Jules,Arthur,Clément,Paul,Théo,Alexandre,Émile,Baptiste,Nicolas,Julien,François,Gabriel,Romain,Valentin,Adrien,Simon,Victor,Étienne,Florian,Camille,Bastien,Quentin,Thibault,Félix"
    set last="Martin,Moreau,Bernard,Petit,Dubois,Laurent,Durand,Lefèvre,Garcia,Roux,Faure,André,Mercier,Blanc,Guérin,Boyer,Chevalier,François,Legrand,Gauthier,Garnier,Bonnet,Girard,Lefebvre,Rousseau,Vincent,Muller,Lambert,Fontaine,Henry,Roussel,Masson,Leroy,Morin,Fournier,Robin,Clément,Nicolas,Dupont,Marchand"
    quit $piece(given,",",1+(seed#32))_" "_$piece(last,",",1+((seed\32)#40))
}
ClassMethod ForClub(club As %DynamicObject, seed As %Integer) As %String
{
    if ##class(Rugby.Service.Leagues).French(club.competitionId) quit ..French(seed)
    quit ..Spanish(seed)
}
}
