Class Rugby.Test.PeriodEnd Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Setup(seed As %Integer = 593, period As %Integer = 1, phase As %String = "open") As %DynamicObject
{
    set m=##class(Rugby.Test.Suite).Build(seed),m.period=period,m.status=$select(period=1:"first",1:"second"),m.clock=$select(period=1:2400,1:4800),m.phase=phase,m.possession="home",m.homeScore=10,m.awayScore=12,m.x=40,m.y=35,m.aiNextTacticalReview=999999,m.homeTactic.style="kicking"
    quit m
}
ClassMethod Run()
{
    set m=..Setup(),continued=0
    for seed=1:1:30 {
        set m=..Setup(seed),before=m.homeStats.kicks
        do ##class(Rugby.Simulation.Engine).Step(m)
        if (m.status="first")&&(m.phase'="penalty") { set continued=1 quit }
    }
    do ..Assert(continued&&(m.clock>2400)&&(m.homeStats.kicks=before),"A trailing team keeps playing beyond forty without a clearance kick")
    set m=..Setup(594),m.homeScore=13,m.awayScore=12,seconds=m.homePlayers.%Get(0).playedSeconds
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.status="halftime")&&(m.clock=2420)&&(m.firstHalfAddedSeconds=20)&&(m.speed=0),"A leading possessor kicks out and halftime pauses after added time")
    do ..Assert(m.homePlayers.%Get(0).playedSeconds=(seconds+20),"Participation includes the extra twenty seconds")
    set event=##class(Rugby.Service.Store).Get("MatchEvent",m.id_"-"_$translate($justify(m.sequence-1,6)," ","0"))
    do ..Assert((event.type="endKick")&&(event.side="home")&&(event.to.y=0),"The final clearance is an actual narrated kick to touch")
    set clock=m.clock,m.speed=20
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.period=2)&&(m.clock=clock)&&(##class(Rugby.Simulation.PeriodEnd).Display(m)=2400),"Second half starts at display forty while the internal clock stays monotonic")
    set m=..Setup(595,2),m.firstHalfAddedSeconds=80,m.clock=4880,m.homeScore=13,m.awayScore=12
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.status="finished")&&(m.clock=4900)&&(m.secondHalfAddedSeconds=20)&&(##class(Rugby.Simulation.PeriodEnd).Display(m)=4820),"Full time waits for touch after eighty minutes of the displayed clock")
    set m=..Setup(596,1,"conversion")
    do ..Assert('##class(Rugby.Simulation.PeriodEnd).Dead(m,"try"),"A try at the time limit retains the conversion")
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.status="halftime")&&(m.clock=2420),"A conversion can be completed after time before halftime")
    set m=..Setup(597,1,"penalty"),m.homeTactic.penaltyPriority="touch",m.homeScore=13,m.awayScore=12
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.status="first")&&(m.phase="lineout")&&(m.possession="home"),"A penalty kicked directly to touch retains its lineout after time")
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.status="first")&&(m.phase="open"),"A pending lineout is played before checking a new dead ball")
    set m=..Setup(598),m.phase="ruck"
    do ..Assert(('##class(Rugby.Simulation.PeriodEnd).Dead(m,"turnover"))&&('##class(Rugby.Simulation.PeriodEnd).Dead(m,"tackle"))&&##class(Rugby.Simulation.PeriodEnd).Dead(m,"knockOn"),"Turnovers and tackles keep the ball live; a new knock-on makes it dead")
    set m=..Setup(599,2),p=m.homePlayers.%Get(0),p.status="sinBin",p.sinBinUntil=4820,m.clock=4820
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    do ..Assert(p.status="field","A suspension can expire during added time")
    set m=..Setup(600),m.engineVersion="1.2.0",m.homeScore=13
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.engineVersion=##class(Rugby.Simulation.Engine).#VERSION)&&(m.previousEngineVersion="1.2.0"),"Existing active matches upgrade without losing state")
}
}
