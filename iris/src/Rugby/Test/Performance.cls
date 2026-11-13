Class Rugby.Test.Performance Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set low={"position":1,"naturalPosition":10,"secondary":[],"status":"field","morale":5}
    do ##class(Rugby.Simulation.Performance).ApplyMorale(low)
    do ..Assert((low.morale=0)&&(low.positionMoraleApplied=5),"Low morale records only the actual position deduction")
    set low.position=10
    do ##class(Rugby.Simulation.Performance).ApplyMorale(low)
    do ..Assert(low.morale=5,"Returning to natural position restores the exact previous morale")
    set low.position=1
    do ##class(Rugby.Simulation.Performance).ApplyMorale(low)
    set low.status="replaced"
    do ##class(Rugby.Simulation.Performance).ApplyMorale(low)
    do ..Assert((low.morale=5)&&(low.positionMoraleApplied=0),"Leaving the XV restores the position deduction")

    set m=##class(Rugby.Test.Suite).Build(593)
    // Uniform controlled attributes isolate the effect of role, unit and absences.
    for side="home","away" {
        set players=m.%Get(side_"Players")
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i),p.naturalPosition=p.position,p.secondary=[],p.energy=100,p.form=70,p.morale=70,attrs=p.attributes.%GetIterator()
            while attrs.%GetNext(.key,.value) { do p.attributes.%Set(key,70) }
        }
    }
    set p=m.homePlayers.%Get(3),original=p.attributes.%ToJSON(),natural=##class(Rugby.Simulation.Engine).Rating(p,"tackling"),p.naturalPosition=5
    do ..Assert(##class(Rugby.Simulation.Engine).Rating(p,"tackling")=natural,"Position does not directly alter effective skills")
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    do ..Assert((p.morale=62)&&(p.attributes.%ToJSON()=original),"Wrong slot lowers morale, preserving every raw attribute")
    set morale=p.morale
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    do ..Assert(p.morale=morale,"Morale penalty is not repeated each tick")
    set p.naturalPosition=12
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    do ..Assert(p.morale=55,"Cross-unit mismatch has a larger morale penalty")
    set p.secondary=[4]
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    do ..Assert(p.morale=67,"Secondary role has only a small morale cost")
    set p.naturalPosition=4,p.secondary=[],c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"scrum",p),baseline=c.attack
    do ..Assert((c.attackers.%Size()=8)&&(c.defenders.%Size()=8),"Scrum uses exactly eight occupied forward slots on each side")
    for i=8:1:14 { set q=m.homePlayers.%Get(i),q.attributes.scrum=1,q.attributes.strength=1,q.attributes.stamina=1 }
    set c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"scrum",p)
    do ..Assert(c.attack=baseline,"Backs cannot improve or weaken the scrum")
    set p.naturalPosition=12
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    set c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"scrum",p)
    do ..Assert(c.attack<baseline,"A back occupying a forward slot weakens the pack")
    set p.naturalPosition=4,p.status="sinBin",c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"scrum",m.homePlayers.%Get(0))
    do ..Assert((c.attackers.%Size()=7)&&(c.attack<baseline),"Exclusion leaves a missing eighth rather than improving an average")
    set p.status="field",c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"lineout",p),baseline=c.attack
    set q=m.homePlayers.%Get(9),q.attributes.lineout=1
    set c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"lineout",p)
    do ..Assert(c.attack=baseline,"Lineout excludes the backs too")
    set c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"ruck",p)
    do ..Assert((c.attackers.%Size()=3)&&(c.defenders.%Size()=3),"Ruck uses the nearest three forwards on either side")
    set c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"open",p),baseline=c.defense
    do ..Assert((c.attackers.%Size()=3)&&(c.defenders.%Size()=3),"Open play uses carrier, two supports and three local defenders")
    set target=c.defenders.%Get(0)
    for i=0:1:m.awayPlayers.%Size()-1 { set q=m.awayPlayers.%Get(i) if q.playerId=target set q.naturalPosition=$select(q.position<=8:12,1:4),q.secondary=[] }
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.awayPlayers)
    set c=##class(Rugby.Simulation.Performance).Contest(m.homePlayers,m.awayPlayers,"open",p)
    do ..Assert(c.defense<baseline,"A local defender playing out of position weakens this actual tackle contest")
    set old=##class(Rugby.Simulation.Performance).Skill(p,"carry"),p.attributes.agility=1,p.attributes.strength=1
    do ..Assert(##class(Rugby.Simulation.Performance).Skill(p,"carry")<old,"Strength and agility now influence ball carrying")
    set kicker=##class(Rugby.Simulation.Performance).Kicker(m.homePlayers),oldId=kicker.playerId,kicker.status="sentOff",next=##class(Rugby.Simulation.Performance).Kicker(m.homePlayers)
    do ..Assert(next.playerId'=oldId,"An excluded kicker cannot take a kick")
    // Settlement applies results to base morale, preserving skills.
    set m=##class(Rugby.Test.Suite).Build(852),p=m.homePlayers.%Get(3),pid=p.playerId,p.naturalPosition=12,p.secondary=[],raw=p.attributes.%ToJSON(),baseMorale=p.morale
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    set penalized=p.morale,m=##class(Rugby.Test.Suite).Finish(m),saved=##class(Rugby.Service.Store).Get("Player",pid),expected=$select(m.homeScore>m.awayScore:100,m.homeScore=m.awayScore:baseMorale,1:##class(Rugby.Simulation.Engine).Clamp(baseMorale-5,0,100))
    do ..Assert((saved.morale=expected)&&(saved.attributes.%ToJSON()=raw),"Results apply to base morale without retaining positional loss or changing attributes")
    set m=##class(Rugby.Test.Suite).Build(593),m.phase="scrum",m.possession="home",m.engineVersion="1.0.0"
    do ##class(Rugby.Simulation.Engine).Step(m)
    set e=##class(Rugby.Service.Store).Get("MatchEvent",m.id_"-"_$translate($justify(m.sequence,6)," ","0"))
    do ..Assert((m.engineVersion=##class(Rugby.Simulation.Engine).#VERSION)&&(e.result.contest.profile="scrum")&&(e.result.contest.attackers.%Size()=8),"Existing checkpoints continue and audit the actual units and values")
}
}
