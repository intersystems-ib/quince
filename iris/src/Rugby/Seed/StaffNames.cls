Class Rugby.Seed.StaffNames Extends %RegisteredObject
{
Parameter VERSION = "1.1.0";
ClassMethod Generate(id As %String, force As %Boolean = 0) As %String
{
    set game=##class(Rugby.Service.Store).Game(),existing=##class(Rugby.Service.Store).Get("Coach",id,0)
    if ('force)&&$isobject(existing)&&(existing.%Get("generatedNameVersion")'="") quit existing.name
    set role=$select($isobject(existing):existing.role,$piece(id,"-",1)="market":$piece(id,"-",2),1:""),free=##class(Rugby.Service.Store).All("Coach","clubId",""),given={}
    for i=0:1:free.%Size()-1 { set p=free.%Get(i) if (p.id'=id)&&(p.role=role) do given.%Set($piece(p.name," ",1),1) }
    set attempt=0
    for {
        set seed=##class(Rugby.Service.Rivals).Hash("staff-"_id_"-"_attempt,17341),name=##class(Rugby.Service.PlayerNames).Spanish(seed),owner=$get(^RugbyWorld(game,"staffNameOwner",name))
        quit:((owner="")||(owner=id))&&((given.%Size()>=32)||('given.%IsDefined($piece(name," ",1))))
        set attempt=attempt+1
    }
    set ^RugbyWorld(game,"staffNameOwner",name)=id
    quit name
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"changes":[]}
    if $get(^RugbyWorld(game,"staffNamesVersion"))=..#VERSION quit report
    set all=##class(Rugby.Service.Store).All("Coach"),seen={},given={}
    // Reserve current identities before repairing available candidates.
    for i=0:1:all.%Size()-1 { set p=all.%Get(i) set ^RugbyWorld(game,"staffNameOwner",p.name)=p.id }
    for i=0:1:all.%Size()-1 {
        set p=all.%Get(i),available=(p.clubId=""),first=$piece(p.name," ",1),repair=0
        if available {
            set repair=(p.%Get("generatedNameVersion")="")||seen.%IsDefined(p.name)||$data(given(p.role,first))
        }
        if repair {
            set before=p.name,p.name=..Generate(p.id,1),p.generatedNameVersion=..#VERSION
            do ##class(Rugby.Service.Store).Put("Coach",p),report.changes.%Push({"coachId":(p.id),"previousName":(before),"name":(p.name)})
        }
        if available { do seen.%Set(p.name,1) set given(p.role,$piece(p.name," ",1))=1 }
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
