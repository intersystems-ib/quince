Class Rugby.Test.MatchPauses Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(593),m.speed=60,m.credit=150
    do ##class(Rugby.Service.Store).Put("Match",m)
    set cmd=##class(Rugby.Service.Matches).Command(m.id,{"type":"speed","speed":0},"pause"),again=##class(Rugby.Service.Matches).Command(m.id,{"type":"speed","speed":0},"pause"),ok=##class(Rugby.Job.Worker).Cycle(m.id,5),m=##class(Rugby.Service.Store).Get("Match",m.id),rng=m.rng,clock=m.clock
    for i=0:1:m.homePlayers.%Size()-1 { do m.homePlayers.%Get(i).%Remove("version") }
    set players=m.homePlayers.%ToJSON()
    do ..Assert((cmd.id=again.id)&&(m.speed=0)&&(m.credit=0)&&(m.pauseReason="manual")&&(clock=0),"Manual pause discards queued simulation credit and is idempotent")
    set ok=##class(Rugby.Job.Worker).Cycle(m.id,300),m=##class(Rugby.Service.Store).Get("Match",m.id)
    for i=0:1:m.homePlayers.%Size()-1 { do m.homePlayers.%Get(i).%Remove("version") }
    do ..Assert((m.clock=clock)&&(m.rng=rng)&&(m.homePlayers.%ToJSON()=players),"Paused clock, RNG and players remain frozen")
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert(m.clock=clock,"The engine itself respects a pause")
    set cmd=##class(Rugby.Service.Matches).Command(m.id,{"type":"speed","speed":20},"resume"),ok=##class(Rugby.Job.Worker).Cycle(m.id,300),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.speed=20)&&(m.clock=clock)&&(m.credit=0),"Selecting a speed resumes without accumulating the paused time")
    set hit=##class(Rugby.Service.Injuries).Hit(m,"home",m.homePlayers.%Get(0)),clock=m.clock
    do ..Assert(hit&&(m.speed=0)&&(m.pauseReason="injury")&&(m.pausedPlayerId=m.homePlayers.%Get(0).playerId),"Managed player injury automatically pauses and identifies the player")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set incoming=m.homePlayers.%Get(15),cmd=##class(Rugby.Service.Matches).Command(m.id,{"type":"substitution","outId":(m.homePlayers.%Get(0).playerId),"inId":(incoming.playerId)},"injury-sub"),ok=##class(Rugby.Job.Worker).Cycle(m.id,10),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.speed=0)&&(m.clock=clock)&&(m.homeSubs=1),"Injury substitutions can be confirmed while paused")
    set m.speed=60,m.pauseReason="",m.credit=150,m.clock=2380,m.phase="stoppage"
    do ##class(Rugby.Service.Store).Put("Match",m)
    set ok=##class(Rugby.Job.Worker).Cycle(m.id,2),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.status="halftime")&&(m.clock=2400)&&(m.speed=0)&&(m.credit=0),"Halftime stops a fast cycle before any second-half action")
    set cmd=##class(Rugby.Service.Matches).Command(m.id,{"type":"speed","speed":5},"second-half"),ok=##class(Rugby.Job.Worker).Cycle(m.id,100),ok=##class(Rugby.Job.Worker).Cycle(m.id,4),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.status="second")&&(m.period=2)&&(m.clock=2400),"A new speed starts the second half explicitly")
    set hit=##class(Rugby.Service.Injuries).Hit(m,"away",m.awayPlayers.%Get(0))
    do ..Assert(hit&&(m.speed=5),"An opponent injury does not pause the managed game")
    set own=##class(Rugby.Service.Store).ManagedClub(),%RugbyManagedClub=m.awayId,hit=##class(Rugby.Service.Injuries).Hit(m,"away",m.awayPlayers.%Get(1)),%RugbyManagedClub=own
    do ..Assert(hit&&(m.speed=0)&&(m.pauseReason="injury"),"Automatic injury pause also works for an away managed team")
}
}
