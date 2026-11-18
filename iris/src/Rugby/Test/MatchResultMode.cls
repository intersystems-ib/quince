Class Rugby.Test.MatchResultMode Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Create(seed As %Integer, mode As %String = "visualize", away As %Boolean = 0, start As %Boolean = 1) As %DynamicObject
{
    set all=##class(Rugby.Service.Store).All("Match")
    for i=0:1:all.%Size()-1 { set old=all.%Get(i),old.status="finished" do ##class(Rugby.Service.Store).Put("Match",old) }
    do ##class(Rugby.Test.Suite).Healthy()
    set c=##class(Rugby.Service.Store).Get("Club","c1"),f={"id":("result-test-"_$increment(^RugbyTestId)),"clubId":"c1","homeId":($select(away:"c2",1:"c1")),"awayId":($select(away:"c1",1:"c2")),"date":(c.date),"day":(c.day),"stage":"friendly","status":"scheduled","matchId":""}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id),"seed":(seed)},f.id)
    if start quit ##class(Rugby.Service.Matches).Start(m.id,{"viewMode":(mode)})
    quit m
}
ClassMethod Run()
{
    set m=..Create(593,"result"),halfClock=m.clock,halfSequence=m.sequence
    do ..Assert((m.status="halftime")&&(m.period=1)&&(m.speed=0)&&(m.clock>=2400)&&('m.settled),"Result mode starts directly at halftime, including first-half added time")
    set again=##class(Rugby.Service.Matches).Start(m.id,{"viewMode":"visualize"})
    do ..Assert((again.viewMode="result")&&(again.clock=halfClock)&&(again.sequence=halfSequence),"Retrying start cannot change mode or play the second half")
    set idle=##class(Rugby.Job.Worker).Cycle(m.id,9999),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.status="halftime")&&(m.clock=halfClock),"Result halftime remains frozen until the user continues")
    set out=m.homePlayers.%Get(0),in=m.homePlayers.%Get(15),tactic={"style":"kicking","tempo":"slow","defense":"low","penaltyPriority":"posts"}
    set sub=##class(Rugby.Service.Matches).Command(m.id,{"type":"substitution","outId":(out.playerId),"inId":(in.playerId)},"result-sub"),change=##class(Rugby.Service.Matches).Command(m.id,{"type":"tactic","tactic":(tactic)},"result-tactic"),blocked=0
    try { set ignored=##class(Rugby.Service.Matches).Command(m.id,{"type":"speed","speed":60},"result-no-speed") } catch ex { set blocked=ex.Location="INVALID_COMMAND" }
    do ..Assert(blocked,"A result match cannot be started by a visual speed command")
    set m=##class(Rugby.Service.MatchResultMode).Advance(m.id,{"target":"fulltime"},"result-finish"),sub=##class(Rugby.Service.Store).Get("MatchCommand",sub.id),change=##class(Rugby.Service.Store).Get("MatchCommand",change.id)
    do ..Assert((m.status="finished")&&m.settled&&(m.period=2)&&(m.homeSubs=1),"Go to fulltime finishes and settles after the requested substitution")
    do ..Assert((sub.status="applied")&&(sub.appliedClock=halfClock)&&(sub.appliedPeriod=1)&&(change.status="applied")&&(m.homeTactic.style="kicking"),"Queued halftime decisions apply before the second-half kickoff")
    set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId),stats=##class(Rugby.Service.Store).All("PlayerMatchStats","matchId",m.id)
    do ..Assert((f.status="finished")&&(f.homeScore=m.homeScore)&&(stats.%Size()>0)&&$isobject(m.economy),"Result mode saves calendar result, player statistics and gate receipts")
    set movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),again=##class(Rugby.Service.MatchResultMode).Advance(m.id,{"target":"fulltime"},"result-finish"),again=##class(Rugby.Service.MatchResultMode).Advance(m.id,{"target":"fulltime"},"result-finish-retry")
    do ..Assert((again.sequence=m.sequence)&&(movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()),"Retries never simulate or settle the final result twice")
    set m=..Create(594,"result",1)
    do ..Assert((m.awayId="c1")&&(m.status="halftime"),"Result mode supports an away managed team")
    set m=..Create(595,"visualize"),blocked=0
    do ..Assert((m.status="first")&&(m.clock=0)&&(m.speed=20),"Visualize retains the original live kickoff")
    try { set ignored=##class(Rugby.Service.MatchResultMode).Advance(m.id,{"target":"halftime"},"visual-no-result") } catch ex { set blocked=ex.Location="MATCH_VIEW_MODE" }
    do ..Assert(blocked,"Visualize matches cannot use result-only progression")
    set m=..Create(596,"visualize",0,0),blocked=0
    try { set ignored=##class(Rugby.Service.Matches).Start(m.id,{"viewMode":"invalid"}) } catch ex { set blocked=ex.Location="MATCH_VIEW_MODE" }
    do ..Assert(blocked&&(##class(Rugby.Service.Store).Get("Match",m.id).status="scheduled"),"Invalid modes do not start or modify a match")
    set m.viewMode="result",m.status="first"
    do ##class(Rugby.Service.Store).Put("Match",m)
    set blocked=0
    try { set ignored=##class(Rugby.Service.MatchResultMode).Advance(m.id,{"target":"fulltime"},"no-skip-halftime") } catch ex { set blocked=ex.Location="MATCH_HALFTIME_REQUIRED" }
    do ..Assert(blocked,"The API cannot skip the halftime decision point")
    do ..Equivalent()
}
ClassMethod Equivalent()
{
    set fingerprint=""
    for mode="visualize","result" {
        tstart
        set m=..Create(38476,mode)
        if mode="result" { set m=##class(Rugby.Service.MatchResultMode).Advance(m.id,{"target":"fulltime"},"equivalent-finish") }
        else {
            for step=1:1:1000 { quit:m.status="finished"  set m.speed=1 do ##class(Rugby.Simulation.Engine).Step(m) }
        }
        set value={"homeScore":(m.homeScore),"awayScore":(m.awayScore),"clock":(m.clock),"rng":(m.rng),"homeStats":(m.homeStats),"awayStats":(m.awayStats),"players":[]}
        for side="home","away" {
            set players=m.%Get(side_"Players")
            for i=0:1:players.%Size()-1 { set p=players.%Get(i) do value.players.%Push({"playerId":(p.playerId),"status":(p.status),"energy":(p.energy),"morale":(p.morale),"playedSeconds":(p.playedSeconds),"stats":(p.stats)}) }
        }
        if mode="visualize" { set fingerprint=value.%ToJSON() }
        else { do ..Assert(value.%ToJSON()=fingerprint,"The same seed produces identical scores, actions, participation and fatigue in both modes") }
        trollback 1
    }
}
}
