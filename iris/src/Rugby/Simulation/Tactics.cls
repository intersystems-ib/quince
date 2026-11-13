Class Rugby.Simulation.Tactics Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod LineupPlayers(club As %String, lineupId As %String = "") As %DynamicArray
{
    if lineupId="" set lineupId=club_"-default"
    set lineup=##class(Rugby.Service.Store).Get("Lineup",lineupId),players=[]
    for i=0:1:lineup.slots.%Size()-1 {
        set slot=lineup.slots.%Get(i),p=##class(Rugby.Service.Store).Get("Player",slot.playerId,0)
        if '$isobject(p) continue
        set s={"playerId":(p.id),"position":(slot.position),"naturalPosition":(p.position),"secondary":(p.secondary),"status":"field","attributes":(p.attributes),"energy":(p.energy),"form":(p.form),"morale":(p.morale)}
        do ##class(Rugby.Simulation.Performance).ApplyMorale(s),players.%Push(s)
    }
    quit players
}
ClassMethod Summary(players As %DynamicArray, group As %String) As %DynamicObject
{
    set unit=##class(Rugby.Simulation.Performance).Unit(players,group),attrs={},energy=0,morale=0,total=0,catalog=##class(Rugby.Service.Development).Catalog(),count=unit.%Size(),divisor=$select(count:count,1:1)
    for k=0:1:16 {
        set key=catalog.%Get(k).id,sum=0
        for i=0:1:count-1 { set sum=sum+unit.%Get(i).attributes.%Get(key) }
        do attrs.%Set(key,sum/divisor)
        set total=total+(sum/divisor)
    }
    for i=0:1:count-1 { set p=unit.%Get(i),energy=energy+p.energy,morale=morale+p.morale }
    quit {"count":(count),"attributes":(attrs),"average":(total/17),"energy":(energy/divisor),"morale":(morale/divisor)}
}
ClassMethod Comparison(m As %DynamicObject) As %DynamicObject
{
    set result={"matchId":(m.id),"attributes":[],"ready":true},catalog=##class(Rugby.Service.Development).Catalog()
    for k=0:1:16 { set t=catalog.%Get(k) do result.attributes.%Push({"id":(t.id),"name":(t.name)}) }
    for side="home","away" {
        set club=m.%Get(side_"Id"),lineupId=$select(club=##class(Rugby.Service.Store).ManagedClub():m.lineupId,1:club_"-default"),lineup=##class(Rugby.Service.Store).Get("Lineup",lineupId),groups={}
        if m.status="scheduled" {
            set players=..LineupPlayers(club,lineupId),valid=##class(Rugby.Service.Management).Validate(lineup)
            if 'valid.valid do result.%Set("ready",0,"boolean")
        } else { set players=m.%Get(side_"Players") }
        for group="all","forwards","backs" { do groups.%Set(group,..Summary(players,group)) }
        do result.%Set(side,{"clubId":(club),"name":(m.%Get(side_"Name")),"lineupId":(lineupId),"groups":(groups)})
    }
    quit result
}
ClassMethod Profile(players As %DynamicArray) As %DynamicObject
{
    set catalog=##class(Rugby.Service.Development).Catalog(),profile={},units={}
    for group="all","forwards","backs" {
        set unit=##class(Rugby.Simulation.Performance).Unit(players,group),expected=$select(group="all":15,group="forwards":8,1:7),attrs={}
        for k=0:1:16 { set key=catalog.%Get(k).id do attrs.%Set(key,##class(Rugby.Simulation.Performance).Score(unit,key,expected)) }
        do profile.%Set(group,attrs)
    }
    set summary=..Summary(players,"all"),kicker=##class(Rugby.Simulation.Performance).Kicker(players),profile.kicking=0,profile.energy=summary.energy,profile.count=summary.count
    if $isobject(kicker) set profile.kicking=##class(Rugby.Simulation.Engine).Rating(kicker,"kicking")
    quit profile
}
ClassMethod Decide(own As %DynamicArray, opponent As %DynamicArray, clock As %Integer = 0, gap As %Integer = 0, opponentTactic As %DynamicObject = "") As %DynamicObject
{
    set a=..Profile(own),b=..Profile(opponent)
    set attack=(a.backs.handling*.30)+(a.backs.passing*.25)+(a.backs.attacking*.20)+(a.backs.agility*.15)+(a.backs.decisions*.10),defense=(a.all.tackling*.6)+(a.all.defensiveReading*.4)
    set otherAttack=(b.backs.handling*.30)+(b.backs.passing*.25)+(b.backs.attacking*.20)+(b.backs.agility*.15)+(b.backs.decisions*.10),otherDefense=(b.all.tackling*.6)+(b.all.defensiveReading*.4)
    set pack=(a.forwards.scrum+a.forwards.lineout+a.forwards.ruck+a.forwards.maul+a.forwards.strength)/5,otherPack=(b.forwards.scrum+b.forwards.lineout+b.forwards.ruck+b.forwards.maul+b.forwards.strength)/5
    set hands=((attack-otherDefense)*.65)+((((a.backs.speed+a.backs.agility)/2)-((b.backs.speed+b.backs.defensiveReading)/2))*.35)
    set kicking=((a.kicking-b.backs.handling)*.55)+((pack-otherPack)*.25)+((otherAttack-defense)*.20)
    if $isobject(opponentTactic) {
        if opponentTactic.%Get("defense")="high" set kicking=kicking+3
        if opponentTactic.%Get("defense")="low" set hands=hands+3
    }
    set style="balanced",reason="Equilibrio entre las líneas de ambos equipos."
    if (hands>(kicking+3))&&(hands>2) set style="hands",reason="Ventaja del pase y la movilidad frente a la defensa rival."
    if (kicking>(hands+3))&&(kicking>2) set style="kicking",reason="Ventaja territorial del pie y los delanteros frente al rival."
    set pressure="normal"
    if (a.energy<45)||(a.all.discipline<40)||(b.kicking>(a.all.defensiveReading+12)) { set pressure="low" }
    elseif (a.energy>=60)&&(a.all.stamina>=55)&&(a.all.discipline>=55)&&(defense>=(otherAttack-5))&&(a.backs.speed>=(b.backs.speed-10)) { set pressure="high" }
    set tempo="normal"
    if (a.energy>=70)&&(a.all.stamina>=60)&&((style="hands")||(hands>6)) set tempo="fast"
    if (a.energy<50)||((clock>=3000)&&(gap>0)) set tempo="slow"
    if (clock>=3000)&&(gap<0)&&(a.energy>=45) set tempo="fast"
    set penalty="auto"
    if (pack>(otherPack+5)) { set penalty="touch" }
    elseif (a.kicking>=55)&&(a.kicking>=(a.all.kicking+3)) { set penalty="posts" }
    elseif (a.energy>=70)&&(a.backs.speed>(b.all.tackling+8)) { set penalty="quick" }
    if clock>=3600 set penalty="auto"
    quit {"version":(..#VERSION),"clock":(clock),"scoreGap":(gap),"tactic":{"style":(style),"tempo":(tempo),"defense":(pressure),"penaltyPriority":(penalty)},"reason":(reason),"opportunities":{"hands":(hands),"kicking":(kicking)},"ownProfile":(a),"opponentProfile":(b)}
}
ClassMethod Adapt(m As %DynamicObject, side As %String, initial As %Boolean = 0)
{
    if 'initial&&(m.clock<m.%Get("aiNextTacticalReview",0)) quit
    set other=$select(side="home":"away",1:"home"),decision=..Decide(m.%Get(side_"Players"),m.%Get(other_"Players"),m.clock,m.%Get(side_"Score")-m.%Get(other_"Score"),m.%Get(other_"Tactic")),current=m.%Get(side_"Tactic")
    set decision.side=side,m.aiTacticalAssessment=decision,m.aiNextTacticalReview=m.clock+600,m.tacticalVersion=..#VERSION
    if initial { do m.%Set(side_"Tactic",decision.tactic) quit }
    set chosen=decision.tactic
    if (chosen.style=current.style)&&(chosen.tempo=current.tempo)&&(chosen.defense=current.defense)&&(chosen.%Get("penaltyPriority","auto")=current.%Get("penaltyPriority","auto")) quit
    set command=##class(Rugby.Service.Matches).Command(m.id,{"type":"tactic","tactic":(chosen),"assessment":(decision)},"adaptive-"_m.clock,side,"ai",m)
}
ClassMethod Modifier(own As %DynamicObject, opponent As %DynamicObject) As %Numeric
{
    set score=$select(own.tactic.style="hands":own.opportunities.hands,own.tactic.style="kicking":own.opportunities.kicking,1:0)/10
    if (own.tactic.style="hands")&&(opponent.tactic.defense="high") set score=score-1.5
    if (own.tactic.style="kicking")&&(opponent.tactic.defense="high") set score=score+1
    quit ##class(Rugby.Simulation.Engine).Clamp(score,-5,5)
}
}
