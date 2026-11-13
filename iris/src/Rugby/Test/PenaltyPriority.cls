Class Rugby.Test.PenaltyPriority Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Setup(seed As %Integer = 721) As %DynamicObject
{
    set m=##class(Rugby.Test.Suite).Build(seed),m.possession="home",m.phase="penalty",m.x=75,m.y=35,m.clock=100,m.aiNextTacticalReview=99999,m.homeTactic={"style":"balanced","tempo":"normal","defense":"normal","penaltyPriority":"auto"}
    for i=0:1:m.homePlayers.%Size()-1 { set p=m.homePlayers.%Get(i),p.attributes.kicking=70,p.energy=100 }
    quit m
}
ClassMethod Run()
{
    set m=..Setup(),p=##class(Rugby.Simulation.Performance).Kicker(m.homePlayers),m.homeTactic.penaltyPriority="posts",rng=m.rng,decision=##class(Rugby.Simulation.Penalties).Decide(m,p),again=##class(Rugby.Simulation.Penalties).Decide(m,p)
    do ..Assert((decision.choice="posts")&&(m.rng=rng)&&(decision.%ToJSON()=again.%ToJSON()),"Priority is deterministic and does not consume simulation RNG")
    set near=##class(Rugby.Simulation.Penalties).Shot(m,p),m.y=0,wide=##class(Rugby.Simulation.Penalties).Shot(m,p)
    do ..Assert(wide.successChance<near.successChance,"Angle and distance affect a shot")
    set m.x=5,m.y=35,far=##class(Rugby.Simulation.Penalties).Decide(m,p)
    do ..Assert(far.choice="touch","Posts preference does not attempt unreachable kicks")
    set m.x=75,m.homeTactic.penaltyPriority="touch",touch=##class(Rugby.Simulation.Penalties).Decide(m,p)
    do ..Assert(touch.choice="touch","Try preference chooses touch even with a viable shot")
    set m.homeTactic.penaltyPriority="quick",quick=##class(Rugby.Simulation.Penalties).Decide(m,p)
    do ..Assert(quick.choice="quick","Quick preference uses an available attacking runner")
    set m.homeTactic.penaltyPriority="auto",m.clock=4500,m.homeScore=10,m.awayScore=12,close=##class(Rugby.Simulation.Penalties).Decide(m,p),m.awayScore=14,needTry=##class(Rugby.Simulation.Penalties).Decide(m,p)
    do ..Assert((close.choice="posts")&&(needTry.choice'="posts"),"Late score gap distinguishes a three-point opportunity from a needed try")
    set m=..Setup(),m.period=2,m.x=25,p=##class(Rugby.Simulation.Performance).Kicker(m.homePlayers),home=##class(Rugby.Simulation.Penalties).Shot(m,p),m.period=1,m.possession="away",away=##class(Rugby.Simulation.Penalties).Shot(m,p)
    do ..Assert($zabs(home.distance-away.distance)<.000001,"Shot geometry respects ends and away possession")
    set originalEnergy=p.energy,p.energy=20,tired=##class(Rugby.Simulation.Penalties).Shot(m,p),p.energy=originalEnergy,rested=##class(Rugby.Simulation.Penalties).Shot(m,p)
    do ..Assert(tired.successChance<rested.successChance,"Kicker fatigue reduces the probability of scoring")
    set legacy={"style":"hands","tempo":"normal","defense":"normal"}
    do ##class(Rugby.Service.Management).Tactic(legacy)
    set legacy.penaltyPriority="invalid",caught=0
    try { do ##class(Rugby.Service.Management).Tactic(legacy) } catch ex { set caught=ex.Location="TACTIC" }
    do ..Assert(caught,"Unknown penalty preferences are rejected, while legacy tactics remain valid")
    set m=..Setup(722),m.homeTactic.penaltyPriority="touch",m.x=90,seed=m.rng
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.phase="lineout")&&(m.possession="home")&&(m.x<=95),"Touch preserves the throw and respects the five-metre limit")
    set e=##class(Rugby.Service.Store).Get("MatchEvent",m.id_"-"_$translate($justify(m.sequence,6)," ","0"))
    do ..Assert(e.result.contest.penaltyDecision.choice="touch","Penalty choices are recorded in event audit")
    set m=..Setup(723),m.homeTactic.penaltyPriority="posts",before=m.homeStats.penaltyGoals
    do ##class(Rugby.Simulation.Engine).Step(m)
    set attempts=0
    for i=0:1:m.homePlayers.%Size()-1 { set attempts=attempts+m.homePlayers.%Get(i).stats.penaltyAttempts }
    do ..Assert((attempts=1)&&(m.phase="restart"),"Shots reach the engine and the kicker's statistics")
    set missed=0
    for seed=100000:100000:2000000 {
        set m=..Setup(seed),m.homeTactic.penaltyPriority="posts"
        do ##class(Rugby.Simulation.Engine).Step(m)
        if m.%Get("restartKind")="drop22" { set missed=1 quit }
    }
    do ..Assert(missed,"Missed shots can go dead for a 22-metre restart")
    set m.aiNextTacticalReview=99999
    do ##class(Rugby.Simulation.Engine).Step(m)
    set e=##class(Rugby.Service.Store).Get("MatchEvent",m.id_"-"_$translate($justify(m.sequence,6)," ","0"))
    do ..Assert((e.type="dropOut22")&&(m.x>45)&&(m.x<70),"Restart is taken from the defending 22 rather than halfway")
    set m=..Setup(724),m.homeTactic.penaltyPriority="quick",before=m.homeStats.metres
    do ##class(Rugby.Simulation.Engine).Step(m)
    set e=##class(Rugby.Service.Store).Get("MatchEvent",m.id_"-"_$translate($justify(m.sequence,6)," ","0")),carries=0
    for i=0:1:m.homePlayers.%Size()-1 { set carries=carries+m.homePlayers.%Get(i).stats.carries }
    do ..Assert((carries=1)&&(e.result.contest.penaltyDecision.choice="quick"),"A quick tap uses a carrier and records its contested outcome")
    set m=..Setup(727),m.x=95,m.homeTactic.penaltyPriority="quick"
    do ##class(Rugby.Simulation.Engine).Step(m)
    set tries=0,points=0
    for i=0:1:m.homePlayers.%Size()-1 { set tries=tries+m.homePlayers.%Get(i).stats.tries,points=points+m.homePlayers.%Get(i).stats.points }
    do ..Assert((m.homeScore=5)&&(tries=1)&&(points=5)&&(m.phase="conversion"),"A quick-tap try credits exactly one scorer and five points")
    set m=..Setup(725),command=##class(Rugby.Service.Matches).Command(m.id,{"type":"tactic","tactic":{"style":"hands","tempo":"normal","defense":"normal","penaltyPriority":"touch"}},"penalty-command","home","user",m)
    do ##class(Rugby.Service.Matches).Commands(m)
    do ..Assert(m.homeTactic.penaltyPriority="touch","In-match tactical commands carry the penalty preference")
    set m=..Setup(726),m.engineVersion="1.1.0"
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.engineVersion=##class(Rugby.Simulation.Engine).#VERSION)&&(m.previousEngineVersion="1.1.0"),"Existing live matches adopt the compatible engine version")
}
}
