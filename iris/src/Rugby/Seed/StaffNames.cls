Class Rugby.Seed.StaffNames Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Generate(id As %String) As %String
{
    set game=##class(Rugby.Service.Store).Game(),existing=##class(Rugby.Service.Store).Get("Coach",id,0)
    if $isobject(existing)&&(existing.%Get("generatedNameVersion")=..#VERSION) quit existing.name
    set attempt=0
    for {
        set seed=##class(Rugby.Service.Rivals).Hash("staff-"_id_"-"_attempt,17341),name=##class(Rugby.Service.PlayerNames).Spanish(seed),owner=$get(^RugbyWorld(game,"staffNameOwner",name))
        quit:(owner="")||(owner=id)
        set attempt=attempt+1
    }
    set ^RugbyWorld(game,"staffNameOwner",name)=id
    quit name
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"changes":[]}
    if $get(^RugbyWorld(game,"staffNamesVersion"))=..#VERSION quit report
    set all=##class(Rugby.Service.Store).All("Coach"),managed=##class(Rugby.Service.Store).ManagedClub()
    for i=0:1:all.%Size()-1 { set p=all.%Get(i) if (p.clubId=managed)||(p.%Get("generatedNameVersion")=..#VERSION)||(($piece(p.id,"-",2)'="coach")&&($extract(p.id,1,9)'="ai-coach-")) set ^RugbyWorld(game,"staffNameOwner",p.name)=p.id }
    for i=0:1:all.%Size()-1 {
        set p=all.%Get(i)
        if (p.clubId=managed)||(p.%Get("generatedNameVersion")=..#VERSION) continue
        if ($piece(p.id,"-",2)'="coach")&&($extract(p.id,1,9)'="ai-coach-") continue
        set before=p.name,p.name=..Generate(p.id),p.generatedNameVersion=..#VERSION
        do ##class(Rugby.Service.Store).Put("Coach",p),report.changes.%Push({"coachId":(p.id),"previousName":(before),"name":(p.name)})
    }
    set ^RugbyWorld(game,"staffNamesVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando identidades del cuerpo técnico.")
    try {
        tstart
        do reports.%Push(..Initialize())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Initialize()) }
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
