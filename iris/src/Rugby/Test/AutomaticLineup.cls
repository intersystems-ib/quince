Class Rugby.Test.AutomaticLineup Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Player(pos As %Integer, id As %String, average As %Numeric) As %DynamicObject
{
    set attrs={},catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:16 { do attrs.%Set(catalog.%Get(i).id,average) }
    quit {"id":(id),"clubId":"c1","name":(id),"position":(pos),"secondary":[],"category":"senior","available":true,"energy":100,"morale":100,"attributes":(attrs)}
}
ClassMethod Run() As %DynamicObject
{
    set players=[],lineup={"id":"test-default","clubId":"c1","name":"Test","version":1,"slots":[],"bench":[],"captainId":"p9","tactic":{"style":"hands","tempo":"slow","defense":"low"}}
    for pos=1:1:15 { do players.%Push(..Player(pos,"p"_pos,60)) }
    set high=..Player(10,"best10",80),high.energy=1,high.morale=1,low=..Player(10,"lower10",79),high.ferReference={"participationScore":0},low.ferReference={"participationScore":1}
    do players.%Push(high),players.%Push(low)
    set result=##class(Rugby.Service.AutomaticLineup).Build(lineup,players)
    do ..Assert(result.slots.%Get(9).playerId="best10","Highest average wins regardless of energy, morale or reference bonus")
    do ..Assert((result.tactic.%ToJSON()=lineup.tactic.%ToJSON())&&(lineup.slots.%Size()=0),"Draft construction preserves tactics and the input lineup")
    set tied=..Player(10,"tied10",80)
    do players.%Push(tied)
    set result=##class(Rugby.Service.AutomaticLineup).Build(lineup,players)
    do ..Assert(result.slots.%Get(9).playerId="tied10","Energy breaks an average tie")
    set players=[],lookup={}
    for pos=1:1:15 { set p=..Player(pos,"starter"_pos,100) do players.%Push(p),lookup.%Set(p.id,p) }
    set roles=[1,2,3,4,8,9,10,15,1,6,5,14]
    for i=0:1:roles.%Size()-1 { set p=..Player(roles.%Get(i),"reserve"_i,90-i) do players.%Push(p),lookup.%Set(p.id,p) }
    set injured=..Player(9,"injured",99),injured.available=0
    do players.%Push(injured)
    set result=##class(Rugby.Service.AutomaticLineup).Build(lineup,players),forwards=0,backs=0,seen={}
    for i=0:1:14 { do ..Assert(result.slots.%Get(i).playerId=("starter"_(i+1)),"Best natural starter selected in each position") do seen.%Set(result.slots.%Get(i).playerId,1) }
    do ..Assert(result.bench.%Size()=8,"Eight reserves when the front row is covered")
    for i=0:1:result.bench.%Size()-1 {
        set id=result.bench.%Get(i),p=lookup.%Get(id)
        do ..Assert(('seen.%IsDefined(id))&&(id'="injured"),"No duplicate or unavailable players")
        do seen.%Set(id,1)
        if p.position<=8 { set forwards=forwards+1 } else { set backs=backs+1 }
    }
    do ..Assert((forwards=5)&&(backs=3),"Bench is balanced five forwards and three backs")
    for i=0:1:7 { do ..Assert(result.bench.%Get(i)=("reserve"_i),"Best average for each reserve role") }
    set %RugbyGame="template",%RugbyManagedClub="c1"
    tstart
    try {
        set clubs=##class(Rugby.Service.Store).All("Club"),tested=0,own=##class(Rugby.Service.Store).Get("Lineup","c1-default").%ToJSON()
        for i=0:1:clubs.%Size()-1 {
            set c=clubs.%Get(i),before=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),after=##class(Rugby.Service.AutomaticLineup).Build(before,roster)
            do ..Assert(##class(Rugby.Service.Management).Validate(after).valid,"Valid automatic selection in every club")
            set tested=tested+1
        }
        set c=##class(Rugby.Service.Store).Get("Club","c2"),day=##class(Rugby.Service.SeasonCalendar).Day("2026-09-07")
        do ##class(Rugby.Service.Rivals).Lineup(c,day)
        set l=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),version=l.version,review=##class(Rugby.Service.Rivals).EnsureLineup(c,day)
        do ..Assert(('review.updated)&&(##class(Rugby.Service.Store).Get("Lineup",l.id).version=version),"No repeated selection or writes on a quiet day")
        do ##class(Rugby.Service.Store).Put("Match",{"id":"test-active-selection","homeId":"c2","awayId":"c3","status":"running"})
        set busy=##class(Rugby.Service.Store).Get("Lineup","c2-default").%ToJSON()
        kill ^RugbyWorld("template","automaticLineupVersion")
        set applied=##class(Rugby.Service.AutomaticLineup).Initialize()
        do ..Assert(##class(Rugby.Service.Store).Get("Lineup","c1-default").%ToJSON()=own,"Managed club lineup is preserved")
        do ..Assert(##class(Rugby.Service.Store).Get("Lineup","c2-default").%ToJSON()=busy,"A match in progress protects its lineup")
        do ..Assert(##class(Rugby.Service.AutomaticLineup).Initialize().clubs=0,"One-time migration is idempotent")
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit {"clubs":(tested),"syntheticCases":true,"balancedBench":true,"managedLineupProtected":true}
}
}
