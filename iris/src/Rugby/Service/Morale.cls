Class Rugby.Service.Morale Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
Parameter GRACE = 14;
Parameter DEFEAT = 5;
ClassMethod Prepare(p As %DynamicObject, day As %Integer)
{
    if p.%Get("moraleVersion")=..#VERSION quit
    set p.morale=100,p.moraleVersion=..#VERSION,p.moraleStartedDay=day,p.moraleLastDay=day
}
ClassMethod Daily(p As %DynamicObject, day As %Integer) As %DynamicObject
{
    do ..Prepare(p,day)
    set before=p.morale,last=p.%Get("moraleLastDay",day),reference=p.%Get("lastAppearanceDay",p.moraleStartedDay)
    set reference=$select(reference>p.moraleStartedDay:reference,1:p.moraleStartedDay)
    if p.%Get("signedDay",reference)>reference set reference=p.signedDay
    set threshold=reference+..#GRACE,start=$select(last>threshold:last,1:threshold),days=$select(day>start:day-start,1:0)
    if day>last set p.morale=##class(Rugby.Simulation.Engine).Clamp(p.morale-days,0,100),p.moraleLastDay=day
    quit {"before":(before),"after":(p.morale),"idleDaysCharged":(days)}
}
ClassMethod Result(club As %String, day As %Integer, key As %String, outcome As %String, participants As %DynamicArray) As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"moraleResults",day,club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"moraleResults",day,club,key))
    set indexed={},players=##class(Rugby.Service.Store).All("Player","clubId",club),changes=[]
    for i=0:1:participants.%Size()-1 { set s=participants.%Get(i) do indexed.%Set(s.playerId,s) }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        do ..Prepare(p,day)
        set before=p.morale,s=indexed.%Get(p.id),seconds=0
        if $isobject(s) {
            set seconds=s.%Get("playedSeconds",0)
            if s.%IsDefined("morale") set p.morale=s.morale
        }
        if seconds>0 set p.lastAppearanceDay=day,p.matchAppearances=p.%Get("matchAppearances",0)+1
        if outcome="win" set p.morale=100
        if outcome="loss" set p.morale=##class(Rugby.Simulation.Engine).Clamp(p.morale-..#DEFEAT,0,100)
        if p.moraleLastDay<day set p.moraleLastDay=day
        do ##class(Rugby.Service.Store).Put("Player",p)
        do changes.%Push({"playerId":(p.id),"before":(before),"after":(p.morale),"playedSeconds":(seconds)})
    }
    set report={"clubId":(club),"day":(day),"source":(key),"outcome":(outcome),"changes":(changes)},^RugbyWorld(game,"moraleResults",day,club,key)=report.%ToJSON()
    quit report
}
ClassMethod Reports(club As %String, day As %Integer) As %DynamicArray
{
    set reports=[],key=""
    for { set key=$order(^RugbyWorld(##class(Rugby.Service.Store).Game(),"moraleResults",day,club,key)) quit:key=""  do reports.%Push(##class(%DynamicObject).%FromJSON(^RugbyWorld(##class(Rugby.Service.Store).Game(),"moraleResults",day,club,key))) }
    quit reports
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"players":0,"version":(..#VERSION)}
    if $get(^RugbyWorld(game,"moraleVersion"))=..#VERSION quit report
    set players=##class(Rugby.Service.Store).All("Player"),base=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()).day
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),day=base
        if p.clubId'="" set day=##class(Rugby.Service.Store).Get("Club",p.clubId).day
        do ..Prepare(p,day),##class(Rugby.Service.Store).Put("Player",p)
        set report.players=report.players+1
    }
    // An ongoing match adopts the baseline without rewinding its sporting state.
    set matches=##class(Rugby.Service.Store).All("Match")
    for i=0:1:matches.%Size()-1 {
        set m=matches.%Get(i)
        if (m.status="scheduled")||(m.status="finished") continue
        for side="home","away" {
            set snapshots=m.%Get(side_"Players")
            for j=0:1:snapshots.%Size()-1 { set s=snapshots.%Get(j),s.morale=100,s.positionMoralePenalty=0 do ##class(Rugby.Simulation.Performance).ApplyMorale(s),##class(Rugby.Service.Store).Put("MatchPlayer",s) }
        }
        do ##class(Rugby.Service.Store).Put("Match",m)
    }
    set ^RugbyWorld(game,"moraleVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando moral.")
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
