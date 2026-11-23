Class Rugby.Seed.FrenchNames Extends %RegisteredObject
{
ClassMethod Apply() As %DynamicObject
{
    set catalog=##class(Rugby.Seed.France).File("french-leagues"),version=catalog.%Get("identityVersion"),game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(version),"players":0}
    if (version="")||($get(^RugbyWorld(game,"frenchNamesVersion"))=version) quit report
    set names={},versions={},players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:catalog.clubs.%Size()-1 { set team=catalog.clubs.%Get(i) for j=0:1:team.players.%Size()-1 { set row=team.players.%Get(j) do names.%Set(row.lnrId,row) } }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),id=p.%Get("identitySourceId")
        if (p.%Get("identitySource")'="LNR")||('names.%IsDefined(id))||(p.%Get("identityNameVersion")=version) continue
        set row=names.%Get(id),old=p.version,p.name=row.name,p.identityRawName=row.%Get("rawName",row.name),p.identityNameVersion=version,p.identityRosterUrl=row.%Get("rosterUrl",row.sourceUrl)
        if $isobject(p.%Get("lnrReference")) set p.lnrReference.name=row.name
        do ##class(Rugby.Service.Store).Put("Player",p),versions.%Set(p.id,{"before":(old),"after":(p.version),"name":(p.name)})
        set report.players=report.players+1
    }
    if versions.%Size()>0 {
        set negotiations=##class(Rugby.Service.Store).All("Negotiation")
        for i=0:1:negotiations.%Size()-1 { set n=negotiations.%Get(i) if versions.%IsDefined(n.playerId) { set v=versions.%Get(n.playerId) if n.%Get("playerVersion",-1)=v.before { set n.playerVersion=v.after do ##class(Rugby.Service.Store).Put("Negotiation",n) } } }
        set matches=##class(Rugby.Service.Store).All("Match")
        for i=0:1:matches.%Size()-1 {
            set m=matches.%Get(i),changed=0
            if m.status="finished" continue
            for side="home","away" { set rows=m.%Get(side_"Players",[]) for j=0:1:rows.%Size()-1 { set p=rows.%Get(j) if versions.%IsDefined(p.playerId) { set p.name=versions.%Get(p.playerId).name do ##class(Rugby.Service.Store).Put("MatchPlayer",p) set changed=1 } } }
            if changed do ##class(Rugby.Service.Store).Put("Match",m)
        }
    }
    set ^RugbyWorld(game,"frenchNamesVersion")=version
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando nombres franceses.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 { set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1" if %RugbyGame'="template" { set g=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)),%RugbyManagedClub=g.clubId } do reports.%Push(..Apply()) }
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
