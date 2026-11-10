Class Rugby.Seed.RealPlayers Extends %RegisteredObject
{
ClassMethod Catalog() As %DynamicObject
{
    set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8",sc=stream.LinkToFile("/opt/rugby/data/real-rosters.json")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    quit ##class(%DynamicObject).%FromJSON(stream)
}
ClassMethod Apply() As %DynamicObject
{
    set catalog=..Catalog(),game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(catalog.version),"imported":0,"clubs":0}
    if $get(^RugbyWorld(game,"realRosterVersion"))=catalog.version quit report
    for i=0:1:catalog.teams.%Size()-1 {
        set team=catalog.teams.%Get(i),club=##class(Rugby.Service.Store).Get("Club",team.clubId)
        for j=0:1:team.players.%Size()-1 {
            set row=team.players.%Get(j),p=##class(Rugby.Service.Store).Get("Player",row.id)
            // Stable identifiers preserve training gains, transfers, contracts and all references.
            set p.name=row.name,p.realIdentity=1,p.identityClubId=team.clubId,p.identitySource="FER",p.identitySourceId=team.sourceId,p.identitySourceFile=team.sourceFile,p.identitySourcePage=team.sourcePage,p.identityMatchCode=team.matchCode,p.identityMatchDate=team.matchDate,p.identitySeason=catalog.season,p.identityRawName=row.rawName,p.identityCategory=row.sourceCategory
            set p.position=row.position,p.secondary=##class(%DynamicArray).%FromJSON(row.secondary.%ToJSON()),p.positionSource=row.positionBasis,p.frontRowQualifications=##class(%DynamicArray).%FromJSON(row.frontRow.%ToJSON())
            // A/B/C are registration classes, not nationality codes. Never infer a country from a name.
            set p.nationalityCode="",p.nationality="No verificada",p.nationalitySource="unknown",p.ageSource="simulation",p.attributesSource="simulation",p.wageSource="simulation"
            do ##class(Rugby.Service.Store).Put("Player",p)
            set report.imported=report.imported+1
        }
        set club.generatedRoster=0,club.rosterSource="FER · Actas de la primera jornada",club.rosterSourceFile=team.sourceFile,club.rosterSourceDate=team.matchDate,club.rosterIdentityCount=team.players.%Size()
        do ##class(Rugby.Service.Store).Put("Club",club)
        // Keep existing lineups. Where the sheet does not certify three reserve front-row roles,
        // use seven substitutes instead of inventing a specialist merely to make 23 legal.
        set lineups=##class(Rugby.Service.Store).All("Lineup","clubId",club.id)
        for k=0:1:lineups.%Size()-1 {
            set l=lineups.%Get(k)
            if l.bench.%Size()'=8 continue
            set complete=1
            for pos=1:1:3 {
                set cover=0
                for b=0:1:l.bench.%Size()-1 { set reserve=##class(Rugby.Service.Store).Get("Player",l.bench.%Get(b)) if reserve.position=pos set cover=1 }
                if 'cover set complete=0
            }
            if 'complete {
                set removed=l.bench.%Pop()
                if l.captainId=removed set l.captainId=l.slots.%Get(8).playerId
                do ##class(Rugby.Service.Store).Put("Lineup",l)
            }
        }
        set report.clubs=report.clubs+1
    }
    set ^RugbyWorld(game,"realRosterVersion")=catalog.version
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set previousGame=##class(Rugby.Service.Store).Game(),previousClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Importación de plantillas en curso.")
    try {
        tstart
        do reports.%Push(..Apply())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Apply()) }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
    lock -^RugbyWrite
    quit reports
}
}
