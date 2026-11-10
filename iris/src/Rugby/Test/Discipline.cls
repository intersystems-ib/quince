Class Rugby.Test.Discipline Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(593),p=m.homePlayers.%Get(5),pid=p.playerId,m.clock=100,before=##class(Rugby.Simulation.Engine).Strength(m.homePlayers,"handling"),energy=p.energy
    set applied=##class(Rugby.Simulation.Discipline).Card(m,"home",pid,"yellow")
    do ..Assert(applied&&(p.status="sinBin")&&(p.sinBinUntil=700),"Yellow excludes the actual player for six hundred playing seconds")
    do ..Assert((##class(Rugby.Simulation.Discipline).Count(m.homePlayers)=14)&&(##class(Rugby.Simulation.Engine).Strength(m.homePlayers,"handling")<before),"A missing player weakens the team rather than merely changing its average")
    for i=1:1:50 { set actor=##class(Rugby.Simulation.Engine).Actor(m,m.homePlayers) do ..Assert(actor.playerId'=pid,"Excluded players cannot act") }
    set reason=##class(Rugby.Service.Matches).CheckCommand(m,{"type":"substitution","outId":(pid),"inId":(m.homePlayers.%Get(15).playerId)},"home")
    do ..Assert(reason'="","The sin bin cannot be bypassed by substitution")
    set m.clock=699
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    do ..Assert(p.status="sinBin","No early return")
    set m.clock=700
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    set sequence=m.sequence
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    do ..Assert((p.status="field")&&(p.yellowCards=1)&&(m.sequence=sequence)&&(p.energy=energy),"A single return event restores the same player without erasing the yellow or changing energy")
    set applied=##class(Rugby.Simulation.Discipline).Card(m,"home",pid,"yellow"),sequence=m.sequence,again=##class(Rugby.Simulation.Discipline).Card(m,"home",pid,"yellow")
    do ..Assert(applied&&('again)&&(p.status="sentOff")&&(p.yellowCards=2)&&(p.redCardReason="secondYellow")&&(m.sequence=sequence),"A second yellow is a permanent dismissal and cannot be applied twice")
    do ..Assert((m.homeStats.yellowCards=2)&&(m.homeStats.redCards=1),"Card statistics include both yellows and their resulting red")
    set other=m.awayPlayers.%Get(2),applied=##class(Rugby.Simulation.Discipline).Card(m,"away",other.playerId,"red"),m.clock=2000
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    do ..Assert((other.status="sentOff")&&(p.status="sentOff"),"Neither direct red nor double yellow ever returns")
    set m=##class(Rugby.Test.Suite).Build(852),p=m.homePlayers.%Get(5),m.clock=2300,applied=##class(Rugby.Simulation.Discipline).Card(m,"home",p.playerId,"yellow"),m.clock=2400,m.status="halftime"
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.clock=2400)&&(p.status="sinBin")&&(p.sinBinUntil=2900),"Half time consumes no suspension time")
    set m.clock=2880,m.phase="restart"
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.clock=2900)&&(p.status="field"),"Return occurs at expiry in the second half")
    set m=##class(Rugby.Test.Suite).Build(101),p=m.homePlayers.%Get(5),m.clock=4700,m.period=2,m.status="second",m.phase="restart",applied=##class(Rugby.Simulation.Discipline).Card(m,"home",p.playerId,"yellow")
    set m=##class(Rugby.Test.Suite).Finish(m)
    do ..Assert((p.status="sinBin")&&(m.clock=4800),"A late yellow does not fabricate a return after full time")
    set m=##class(Rugby.Test.Suite).Build(37),p=m.homePlayers.%Get(5),applied=##class(Rugby.Simulation.Discipline).Card(m,"home",p.playerId,"yellow")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set ok=##class(Rugby.Job.Worker).Cycle(m.id,1),saved=##class(Rugby.Service.Store).Get("MatchPlayer",p.id),checkpoint=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((saved.status="sinBin")&&(saved.sinBinUntil=600)&&(checkpoint.homeStats.yellowCards=1),"Worker checkpoints persist suspension, expiry, statistics and player state together")
    set f={"id":"discipline-aggregate-test","homeId":"c2","awayId":"c3"},rng={"rng":593},factors=##class(Rugby.Simulation.Discipline).Aggregate(f,rng),fingerprint=f.%ToJSON(),rng2={"rng":593},other={"id":"discipline-aggregate-test","homeId":"c2","awayId":"c3"},again=##class(Rugby.Simulation.Discipline).Aggregate(other,rng2)
    do ..Assert((fingerprint=other.%ToJSON())&&(rng.rng=rng2.rng),"Automated fixtures have deterministic card events and playing time")
    do ..Assert((factors.home<=1)&&(factors.away<=1)&&(f.disciplineParticipants.%Size()>=30),"Automated match strength reflects minutes in numerical inferiority, including injury replacements")
    set m=##class(Rugby.Test.Suite).Build(11)
    for i=1:1:100 { do ##class(Rugby.Simulation.Discipline).Foul(m,"away") set m.clock=m.clock+20 do ##class(Rugby.Simulation.Discipline).Returns(m) }
    do ..Assert(m.awayStats.%Get("yellowCards",0)>0,"The seeded foul generator actually produces cards")
}
}
