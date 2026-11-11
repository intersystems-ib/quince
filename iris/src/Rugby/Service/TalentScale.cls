Class Rugby.Service.TalentScale Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
Parameter FACTOR = .75;
ClassMethod Factor() As %Numeric { quit $select($get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"talentScaleVersion"))=..#VERSION:..#FACTOR,1:1) }
ClassMethod Player(p As %DynamicObject)
{
    if p.%Get("talentScaleVersion")=..#VERSION quit
    set catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:16 { set key=catalog.%Get(i).id do p.attributes.%Set(key,+$justify(##class(Rugby.Simulation.Engine).Clamp(p.attributes.%Get(key)*..#FACTOR,1,100),0,6)) }
    if $isobject(p.%Get("qualityChanges")) { set it=p.qualityChanges.%GetIterator() while it.%GetNext(.key,.value) { do p.qualityChanges.%Set(key,value*..#FACTOR) } }
    set p.talentScaleVersion=..#VERSION,p.talentScaleFactor=..#FACTOR
    if p.%IsDefined("qualityOffset") set p.qualityOffset=p.qualityOffset*..#FACTOR
    if p.%IsDefined("potential") set p.potential=p.potential*..#FACTOR
    if p.%IsDefined("developmentCeiling") set p.developmentCeiling=p.developmentCeiling*..#FACTOR
}
ClassMethod Apply() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"factor":(..#FACTOR),"version":(..#VERSION),"players":0,"matchPlayers":0}
    if $get(^RugbyWorld(game,"talentScaleVersion"))=..#VERSION quit report
    set players=##class(Rugby.Service.Store).All("Player"),versions={}
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.%Get("talentScaleVersion")'=..#VERSION { do versions.%Set(p.id,p.version),..Player(p),##class(Rugby.Service.Store).Put("Player",p) set report.players=report.players+1 } }
    set negotiations=##class(Rugby.Service.Store).All("Negotiation")
    for i=0:1:negotiations.%Size()-1 { set n=negotiations.%Get(i) if versions.%IsDefined(n.playerId)&&(n.%Get("playerVersion",-1)=versions.%Get(n.playerId)) { set n.playerVersion=##class(Rugby.Service.Store).Get("Player",n.playerId).version do ##class(Rugby.Service.Store).Put("Negotiation",n) } }
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if c.%Get("talentScaleVersion")=..#VERSION continue
        for key="qualitySeniorTarget","qualityAcademyTarget" { if c.%IsDefined(key) do c.%Set(key,c.%Get(key)*..#FACTOR) }
        set c.talentScaleVersion=..#VERSION
        do ##class(Rugby.Service.Store).Put("Club",c)
    }
    // Live snapshots must use the same scale; completed matches retain their history.
    set matches=##class(Rugby.Service.Store).All("Match")
    for i=0:1:matches.%Size()-1 { set m=matches.%Get(i) if m.status'="finished" { for side="home","away" { set rows=m.%Get(side_"Players",[]) for j=0:1:rows.%Size()-1 { set s=rows.%Get(j) do ..Player(s) set s.form=##class(Rugby.Service.Development).Average(s) do ##class(Rugby.Service.Store).Put("MatchPlayer",s) set report.matchPlayers=report.matchPlayers+1 } } do ##class(Rugby.Service.Store).Put("Match",m) } }
    set ^RugbyWorld(game,"talentScaleVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Ajustando nivel de las ligas.")
    try {
        tstart
        set games=["template"],gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do games.%Push(gid) }
        for i=0:1:games.%Size()-1 { set %RugbyGame=games.%Get(i),%RugbyManagedClub="c1" if %RugbyGame'="template" { set g=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)),%RugbyManagedClub=g.clubId } do reports.%Push(..Apply()) }
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
