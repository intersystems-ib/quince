Class Rugby.Test.Tactics Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Uniform(players As %DynamicArray, value As %Numeric)
{
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),p.energy=100,p.morale=100,p.form=70,p.naturalPosition=p.position,p.secondary=[],iter=p.attributes.%GetIterator()
        while iter.%GetNext(.key,.old) { do p.attributes.%Set(key,value) }
    }
}
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(593)
    do ..Uniform(m.homePlayers,100)
    for i=0:1:14 { set p=m.homePlayers.%Get(i),iter=p.attributes.%GetIterator(),value=$select(p.position<=8:20,1:80) while iter.%GetNext(.key,.old) { do p.attributes.%Set(key,value) } }
    set before=m.%ToJSON(),comparison=##class(Rugby.Simulation.Tactics).Comparison(m)
    do ..Assert((comparison.home.groups.all.count=15)&&(comparison.home.groups.forwards.count=8)&&(comparison.home.groups.backs.count=7),"Comparison separates fifteen starters, eight forwards and seven backs")
    do ..Assert((comparison.home.groups.all.attributes.strength=48)&&(comparison.home.groups.forwards.attributes.strength=20)&&(comparison.home.groups.backs.attributes.strength=80),"Arithmetic means use selected field players and ignore the bench")
    do ..Assert((comparison.attributes.%Size()=17)&&(before=m.%ToJSON()),"Comparison exposes seventeen characteristics and never mutates the match")
    set profile=##class(Rugby.Simulation.Tactics).Profile(m.homePlayers),m.homePlayers.%Get(0).status="sinBin",depleted=##class(Rugby.Simulation.Tactics).Profile(m.homePlayers)
    do ..Assert((depleted.count=14)&&(depleted.forwards.strength<profile.forwards.strength),"An excluded forward does not contribute to the tactical pack")
    set m=##class(Rugby.Test.Suite).Build(593)
    do ..Uniform(m.awayPlayers,60),..Uniform(m.homePlayers,40)
    set rng=m.rng,hands=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers)
    do ..Assert(hands.tactic.style="hands","Backline advantage against weaker defence favours running and passing")
    do ..Uniform(m.homePlayers,60)
    for i=0:1:m.homePlayers.%Size()-1 { set p=m.homePlayers.%Get(i),p.attributes.tackling=90,p.attributes.defensiveReading=90,p.attributes.speed=80,p.attributes.handling=20,p.attributes.agility=80 }
    set kicking=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers),again=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers)
    do ..Assert((kicking.tactic.style="kicking")&&(kicking.%ToJSON()=again.%ToJSON())&&(m.rng=rng),"Changing opponent characteristics changes the plan deterministically without consuming RNG")
    for i=0:1:m.awayPlayers.%Size()-1 { set m.awayPlayers.%Get(i).energy=20 }
    set tired=##class(Rugby.Simulation.Tactics).Decide(m.awayPlayers,m.homePlayers)
    do ..Assert((tired.tactic.tempo="slow")&&(tired.tactic.defense="low"),"Fatigue prevents unsustainable high pressure and pace")
    do ..Uniform(m.awayPlayers,60),..Uniform(m.homePlayers,40)
    set own=m.homeTactic.%ToJSON(),m.awayTactic={"style":"balanced","tempo":"normal","defense":"normal"},m.aiNextTacticalReview=0,m.clock=620,m.phase="stoppage"
    do ##class(Rugby.Service.Matches).AI(m),##class(Rugby.Service.Matches).Commands(m)
    do ..Assert((m.awayTactic.style="hands")&&(m.homeTactic.%ToJSON()=own),"Only the rival adapts, applying its command at a dead ball")
    set seq=m.commandSequence
    do ##class(Rugby.Service.Matches).AI(m)
    do ..Assert(m.commandSequence=seq,"Same-clock review cannot enqueue duplicate changes")
    for i=0:1:m.awayPlayers.%Size()-1 { set m.awayPlayers.%Get(i).energy=20 }
    set m.clock=1240
    do ##class(Rugby.Service.Matches).AI(m),##class(Rugby.Service.Matches).Commands(m)
    do ..Assert(m.awayTactic.tempo="slow","A later dead ball adapts to changed energy without requiring an exact minute")
    set event=##class(Rugby.Service.Store).Get("MatchEvent",m.id_"-"_$translate($justify(m.sequence,6)," ","0"))
    do ..Assert(event.result.%IsDefined("tacticalDecision"),"Applied tactical changes include their assessment in native event audit")
    set template=##class(Rugby.Test.Suite).Build(593),template.phase="open",template.possession="away",template.clock=20,template.homeTactic.tempo="normal",energies={},defenses={}
    for pressure="low","normal","high" {
        set sample=##class(%DynamicObject).%FromJSON(template.%ToJSON()),sample.homeTactic.defense=pressure,sample.engineVersion="1.3.0"
        do ##class(Rugby.Simulation.Engine).Step(sample)
        do energies.%Set(pressure,sample.homePlayers.%Get(0).energy),defenses.%Set(pressure,sample.actionContext.defense)
        do ..Assert((sample.engineVersion=##class(Rugby.Simulation.Engine).#VERSION)&&(sample.previousEngineVersion="1.3.0")&&(sample.clock=40),"Existing matches adopt energy savings without resetting the clock")
    }
    do ..Assert((energies.low>energies.normal)&&(energies.normal>energies.high),"Low defensive pressure saves real match energy; high pressure costs more")
    do ..Assert((defenses.low<defenses.normal)&&(defenses.normal<defenses.high),"Conserving energy retains the defensive strength trade-off")
    set own=##class(Rugby.Simulation.Tactics).LineupPlayers("c1"),clubs=##class(Rugby.Service.Store).All("Club"),plans={},styles={}
    for i=0:1:clubs.%Size()-1 {
        set club=clubs.%Get(i)
        if (club.id="c1")||(club.competitionId'=416) continue
        set decision=##class(Rugby.Simulation.Tactics).Decide(own,##class(Rugby.Simulation.Tactics).LineupPlayers(club.id))
        do plans.%Set(decision.tactic.%ToJSON(),1),styles.%Set(decision.tactic.style,1)
    }
    do ..Assert((plans.%Size()>=3)&&(styles.%Size()>=2),"Cisneros receives distinct matchup-based plans against actual Honor opponents")
    do ..Uniform(template.homePlayers,60),..Uniform(template.awayPlayers,40)
    set original=##class(Rugby.Simulation.Tactics).Decide(template.homePlayers,template.awayPlayers)
    for side="home","away" { set players=template.%Get(side_"Players") for i=0:1:players.%Size()-1 { set player=players.%Get(i),iter=player.attributes.%GetIterator() while iter.%GetNext(.key,.value) { do player.attributes.%Set(key,value*.75) } } }
    set scaled=##class(Rugby.Simulation.Tactics).Decide(template.homePlayers,template.awayPlayers)
    do ..Assert((original.tactic.%ToJSON()=scaled.tactic.%ToJSON()),"Proportional attribute scaling preserves the same relative tactical matchup")
    // Scheduled comparison must respect a selected custom lineup, not the default.
    set p=##class(Rugby.Service.Store).Get("Player","c1-p16"),iter=p.attributes.%GetIterator()
    while iter.%GetNext(.key,.old) { do p.attributes.%Set(key,99) }
    do ##class(Rugby.Service.Store).Put("Player",p)
    set l=##class(Rugby.Service.Store).Get("Lineup","c1-default"),old=l.slots.%Get(1).playerId,l.id="tactical-custom",l.slots.%Get(1).playerId="c1-p16"
    do l.bench.%Set(0,old),##class(Rugby.Service.Store).Put("Lineup",l)
    set m.status="scheduled",m.lineupId="c1-default",standard=##class(Rugby.Simulation.Tactics).Comparison(m),m.lineupId=l.id,custom=##class(Rugby.Simulation.Tactics).Comparison(m)
    do ..Assert(custom.home.groups.all.attributes.speed>standard.home.groups.all.attributes.speed,"Preview comparison follows the chosen lineup")
}
}
