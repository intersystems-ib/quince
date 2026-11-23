Class Rugby.Test.AISubstitutions Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Player(pos As %Integer, id As %String, average As %Numeric, energy As %Numeric, status As %String) As %DynamicObject
{
    set p=##class(Rugby.Test.AutomaticLineup).Player(pos,id,average),p.playerId=id,p.naturalPosition=pos,p.status=status,p.energy=energy,p.playedSeconds=0
    quit p
}
ClassMethod Run() As %DynamicObject
{
    set tired=..Player(9,"tired",90,25,"field"),injured=..Player(10,"injured",85,80,"injured"),low=..Player(10,"low",60,100,"bench"),best=..Player(10,"best",80,95,"bench"),nine=..Player(9,"nine",75,100,"bench"),unavailable=..Player(10,"unavailable",99,100,"bench"),unavailable.injury={"id":"test"},yellow=..Player(4,"yellow",90,1,"sinBin"),red=..Player(5,"red",90,1,"sentOff")
    set m={"status":"second","clock":3600,"homeSubs":7,"homePlayers":[(tired),(injured),(low),(best),(nine),(unavailable),(yellow),(red)]},changes=##class(Rugby.Simulation.Substitutions).Plan(m,"home")
    do ..Assert((changes.%Size()=1)&&(changes.%Get(0).outId="injured")&&(changes.%Get(0).inId="best"),"Injury has priority over fatigue, with the best compatible healthy reserve")
    do ##class(Rugby.Simulation.Substitutions).Apply(m,"home",changes)
    do ..Assert((m.homeSubs=8)&&(best.status="field")&&(best.position=10)&&injured.substituted,"Change occupies the correct slot and counts towards eight")
    do ..Assert(##class(Rugby.Simulation.Substitutions).Plan(m,"home").%Size()=0,"No changes after reaching the limit")
    set a=..Player(9,"nine-out",90,30,"field"),b=..Player(10,"ten-out",90,60,"field"),aIn=..Player(9,"nine-in",70,100,"bench"),bIn=..Player(10,"ten-in",80,100,"bench"),m={"status":"second","clock":3600,"homeSubs":0,"homePlayers":[(b),(a),(aIn),(bIn)]}
    set changes=##class(Rugby.Simulation.Substitutions).Plan(m,"home")
    do ..Assert((changes.%Size()=2)&&(changes.%Get(0).outId="nine-out"),"Most exhausted player is replaced first independently of list order")
    do ..Assert((changes.%Get(0).inId="nine-in")&&(changes.%Get(1).inId="ten-in"),"Substitutes cover the occupied positions without duplicates")
    set a.energy=65,b.energy=65,aIn.energy=66,bIn.energy=66
    do ..Assert(##class(Rugby.Simulation.Substitutions).Plan(m,"home").%Size()=0,"Fatigue substitutions require a meaningful freshness improvement")
    set a.status="sinBin",b.status="sentOff",aIn.energy=100,bIn.energy=100
    do ..Assert(##class(Rugby.Simulation.Substitutions).Plan(m,"home").%Size()=0,"Yellow and red exclusions cannot be bypassed")
    set a=..Player(9,"injury9",90,50,"injured"),b=..Player(10,"injury10",90,50,"injured"),versatile=..Player(9,"dual",80,100,"bench"),versatile.secondary=[10],specialist=..Player(9,"specialist",70,100,"bench"),m={"status":"first","clock":100,"homeSubs":0,"homePlayers":[(a),(b),(versatile),(specialist)]}
    set changes=##class(Rugby.Simulation.Substitutions).Plan(m,"home")
    set paired={}
    for i=0:1:changes.%Size()-1 { set pair=changes.%Get(i) do paired.%Set(pair.outId,pair.inId) }
    do ..Assert((changes.%Size()=2)&&(paired.%Get("injury9")="specialist")&&(paired.%Get("injury10")="dual"),"Joint selection preserves scarce secondary-position cover")
    set %RugbyGame="template",%RugbyManagedClub="c1"
    tstart
    try {
        set m=##class(Rugby.Test.Suite).Build(593),m.clock=3600,m.status="second",m.phase="stoppage",out=m.awayPlayers.%Get(8),out.energy=20,own=##class(%DynamicArray).%FromJSON(m.homePlayers.%ToJSON())
        do ##class(Rugby.Service.Matches).AI(m)
        set pending=##class(Rugby.Service.Store).All("MatchCommand","matchId",m.id).%Size()
        do ##class(Rugby.Service.Matches).AI(m)
        do ..Assert(##class(Rugby.Service.Store).All("MatchCommand","matchId",m.id).%Size()=pending,"Repeated planning at one clock is idempotent")
        do ##class(Rugby.Service.Matches).Commands(m)
        do ..Assert((m.awaySubs>0)&&(out.status="replaced"),"Live opponent uses the normal audited command path")
        for i=0:1:own.%Size()-1 { set before=own.%Get(i),after=m.homePlayers.%Get(i) do ..Assert((before.playerId=after.playerId)&&(before.status=after.status)&&(before.position=after.position)&&(before.energy=after.energy),"Managed team is never substituted by AI") }
        set again=m.awaySubs
        do ##class(Rugby.Service.Matches).Commands(m)
        do ..Assert(m.awaySubs=again,"An applied substitution cannot re-enter or be counted twice")
        set c=##class(Rugby.Service.Store).Get("Club","c2"),f={"id":"test-ai-fatigue","homeId":"c2","awayId":"c3","date":(c.date),"day":(c.day),"stage":"friendly","status":"finished","homeScore":10,"awayScore":5,"winnerId":"c2","homeTactic":{"tempo":"fast","defense":"high"},"awayTactic":{"tempo":"fast","defense":"high"}},rng={"rng":593}
        set original=##class(%DynamicObject).%FromJSON(f.%ToJSON())
        set factors=##class(Rugby.Simulation.Discipline).Aggregate(f,rng),benchPlayed=0,seen={}
        for side="home","away" {
            set rows=f.statisticsPlayers.%Get(side)
            for i=0:1:rows.%Size()-1 {
                set p=rows.%Get(i)
                do ..Assert((p.playedSeconds>=0)&&(p.playedSeconds<=4800),"Participation stays inside match duration")
                if (i>=15)&&(p.playedSeconds>0) set benchPlayed=benchPlayed+1
                if p.status="field" { do ..Assert('seen.%IsDefined(p.playerId),"A player can only occupy one slot") do seen.%Set(p.playerId,1) }
            }
        }
        do ..Assert(benchPlayed>0,"Both-AI simulation actually introduces substitutes for fatigue")
        set copy=original,rng={"rng":593},discard=##class(Rugby.Simulation.Discipline).Aggregate(copy,rng)
        do ..Assert(copy.%ToJSON()=f.%ToJSON(),"AI substitutions and fatigue are deterministic")
        do ##class(Rugby.Service.Rivals).SettleFixture(f)
        for i=0:1:f.disciplineParticipants.%Size()-1 { set participant=f.disciplineParticipants.%Get(i),p=##class(Rugby.Service.Store).Get("Player",participant.playerId) do ..Assert(p.energy=participant.energy,"Simulation settles actual final energy without charging it twice") }
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit {"injuryPriority":true,"freshReserves":true,"liveCommands":true,"aggregateSubstitutes":(benchPlayed),"deterministic":true}
}
}
