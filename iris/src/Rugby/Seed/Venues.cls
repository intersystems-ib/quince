Class Rugby.Seed.Venues Extends %RegisteredObject
{
ClassMethod Apply() As %DynamicObject
{
    set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8",sc=stream.LinkToFile("/opt/rugby/data/venues.json")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set data=##class(%DynamicObject).%FromJSON(stream),report={"gameId":(##class(Rugby.Service.Store).Game()),"version":(data.version),"clubs":[]}
    for i=0:1:data.clubs.%Size()-1 {
        set row=data.clubs.%Get(i),club=##class(Rugby.Service.Store).Get("Club",row.clubId)
        if club.%Get("venueVersion")=data.version continue
        set club.stadium=row.stadium,club.venueVersion=data.version
        do ##class(Rugby.Service.Store).Put("Club",club),report.clubs.%Push(row)
    }
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando los campos.")
    try {
        tstart
        do reports.%Push(..Apply())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Apply()) }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
