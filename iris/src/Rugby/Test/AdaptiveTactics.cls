Class Rugby.Test.AdaptiveTactics Extends %RegisteredObject
{
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(593)
    do ##class(Rugby.Test.Tactics).Uniform(m.homePlayers,60),##class(Rugby.Test.Tactics).Uniform(m.awayPlayers,60)
    set rng=m.rng,early=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers,600,-10)
    set winning=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers,4200,4)
    set narrow=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers,4200,-3)
    set chasing=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers,4200,-8)
    do ##class(Rugby.Test.Suite).Assert((early.objective="matchup")&&(winning.objective="protect")&&(winning.tactic.tempo="slow"),"Time and score distinguish a late lead from an early deficit")
    do ##class(Rugby.Test.Suite).Assert((narrow.tactic.penaltyPriority="posts")&&(chasing.tactic.penaltyPriority="touch")&&(chasing.tactic.tempo="fast"),"Late deficit chooses points or a try according to the required score")
    for i=0:1:m.awayPlayers.%Size()-1 { set m.awayPlayers.%Get(i).energy=47 }
    set tired=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers,4900,-8)
    do ##class(Rugby.Test.Suite).Assert((tired.tactic.tempo="slow")&&(tired.remainingSeconds=0),"Exhaustion overrides chasing pace, including added time")
    for i=0:1:m.awayPlayers.%Size()-1 { set m.awayPlayers.%Get(i).energy=20 }
    set tired=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers,4500,-8)
    do ##class(Rugby.Test.Suite).Assert((tired.tactic.defense="low")&&(m.rng=rng),"Exhausted teams conserve pressure and tactical choices consume no randomness")
    do ##class(Rugby.Test.Tactics).Uniform(m.awayPlayers,60)
    set m.aggregate=1,m.period=2,m.clock=4200,m.homeScore=10,m.awayScore=9
    do m.%Remove("aiTacticalReviews")
    do ##class(Rugby.Simulation.Tactics).Adapt(m,"home"),##class(Rugby.Simulation.Tactics).Adapt(m,"away")
    do ##class(Rugby.Test.Suite).Assert((m.aiTacticalAssessments.home.objective="protect")&&(m.aiTacticalAssessments.away.objective="points"),"Both AI sides have independent reviews")
    set m.clock=4220,m.homeScore=17
    do ##class(Rugby.Simulation.Tactics).Adapt(m,"away")
    do ##class(Rugby.Test.Suite).Assert(m.aiTacticalReviews.away.clock=4200,"Score changes have a cooldown")
    set m.clock=4260
    do ##class(Rugby.Simulation.Tactics).Adapt(m,"away")
    do ##class(Rugby.Test.Suite).Assert((m.aiTacticalAssessments.away.objective="try")&&(m.aiTacticalReviews.away.clock=4260),"A score change triggers review before the regular interval")
    set m.clock=4280,m.awaySubs=m.awaySubs+1
    do ##class(Rugby.Simulation.Tactics).Adapt(m,"away")
    do ##class(Rugby.Test.Suite).Assert(m.aiTacticalReviews.away.clock=4280,"Substitution triggers an immediate reassessment")
    set c=##class(Rugby.Service.Store).Get("Club","c2"),f={"id":"adaptive-aggregate","homeId":"c2","awayId":"c3","date":(c.date),"day":(c.day)},rng={"rng":593}
    set original=##class(%DynamicObject).%FromJSON(f.%ToJSON()),unused=##class(Rugby.Simulation.Discipline).Aggregate(f,rng)
    do ##class(Rugby.Test.Suite).Assert((f.homeScore=((f.homeTries*5)+(f.homeConversions*2)+(f.homePenaltyGoals*3)))&&(f.awayScore=((f.awayTries*5)+(f.awayConversions*2)+(f.awayPenaltyGoals*3))),"Aggregate scoring reconciles with tries and kicks")
    do ##class(Rugby.Test.Suite).Assert((f.tacticalAssessments.home.clock>=4200)&&(f.tacticalAssessments.home.scoreGap=(f.homeScore-f.awayScore)),"Automatic matches assess the running score late in the match")
    set rng={"rng":593},unused=##class(Rugby.Simulation.Discipline).Aggregate(original,rng)
    do ##class(Rugby.Test.Suite).Assert(original.%ToJSON()=f.%ToJSON(),"Automatic score, tactics, substitutions and fatigue reproduce from the seed")
}
}
