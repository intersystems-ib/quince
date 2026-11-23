Class Rugby.Simulation.Tactics Extends %RegisteredObject
{
Parameter VERSION = "1.2.0";
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
    set summary=..Summary(players,"all"),kicker=##class(Rugby.Simulation.Performance).Kicker(players),profile.kicking=0,profile.energy=summary.energy,profile.count=summary.count,profile.receiving=0,quality=0
    if $isobject(kicker) set profile.kicking=##class(Rugby.Simulation.Engine).Rating(kicker,"kicking")
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.status="field")&&(p.position>8) { set value=##class(Rugby.Simulation.Engine).Rating(p,"handling") if value>profile.receiving set profile.receiving=value }
    }
    for k=0:1:16 { set quality=quality+profile.all.%Get(catalog.%Get(k).id) }
    set profile.quality=quality/17
    quit profile
}
ClassMethod Decide(own As %DynamicArray, opponent As %DynamicArray, clock As %Integer = 0, gap As %Integer = 0, opponentTactic As %DynamicObject = "") As %DynamicObject
{
    set a=..Profile(own),b=..Profile(opponent)
    set attack=(a.backs.handling*.30)+(a.backs.passing*.25)+(a.backs.attacking*.20)+(a.backs.agility*.15)+(a.backs.decisions*.10),defense=(a.all.tackling*.6)+(a.all.defensiveReading*.4)
    set otherAttack=(b.backs.handling*.30)+(b.backs.passing*.25)+(b.backs.attacking*.20)+(b.backs.agility*.15)+(b.backs.decisions*.10),otherDefense=(b.all.tackling*.6)+(b.all.defensiveReading*.4)
    set pack=(a.forwards.scrum+a.forwards.lineout+a.forwards.ruck+a.forwards.maul+a.forwards.strength)/5,otherPack=(b.forwards.scrum+b.forwards.lineout+b.forwards.ruck+b.forwards.maul+b.forwards.strength)/5
    set pace=(a.backs.speed+a.backs.agility)/2,cover=(b.backs.speed+b.backs.defensiveReading)/2,otherPace=(b.backs.speed+b.backs.agility)/2
    set hands=(..Relative(attack,otherDefense)*.55)+(..Relative(pace,cover)*.30)+(..Relative(a.backs.decisions,b.backs.defensiveReading)*.15)
    set kicking=(..Relative(a.kicking,b.receiving)*.45)+(..Relative(pack,otherPack)*.35)+(..Relative(otherAttack,defense)*.20)
    set defenseEdge=..Relative(defense,otherAttack),paceEdge=..Relative(pace,otherPace),staminaEdge=..Relative(a.all.stamina,b.all.stamina),packEdge=..Relative(pack,otherPack),lineoutEdge=..Relative((a.forwards.lineout+a.forwards.maul)/2,(b.forwards.lineout+b.forwards.maul)/2)
    if $isobject(opponentTactic) {
        if opponentTactic.%Get("defense")="high" set kicking=kicking+3
        if opponentTactic.%Get("defense")="low" set hands=hands+3
    }
    set style="balanced",reason="Las ventajas relativas del juego a la mano y al pie están próximas; conviene alternarlos."
    if (hands>(kicking+3))&&(hands>1) set style="hands",reason="Nuestra movilidad y continuidad encuentran más oportunidades frente a su defensa que el juego al pie."
    if (kicking>(hands+3))&&(kicking>1) set style="kicking",reason="El duelo del pateador con sus receptores y la comparación de delanteros favorecen ganar territorio."
    set pressure="normal"
    if (a.energy<45)||(a.all.discipline<(a.quality*.75))||(defenseEdge< -10)||((..Relative(b.kicking,a.receiving)>20)&&(paceEdge< -5)) { set pressure="low" }
    elseif (a.energy>=65)&&(a.all.stamina>=(a.quality*.85))&&(a.all.discipline>=(a.quality*.9))&&(defenseEdge>=3)&&(paceEdge>=-5) { set pressure="high" }
    set tempo="normal"
    if (a.energy>=70)&&(a.all.stamina>=(a.quality*.9))&&(staminaEdge>=-5)&&(((style="hands")&&(hands>3))||((hands>=5)&&(hands>=(kicking-3)))) set tempo="fast"
    if (a.energy<50)||((clock>=3000)&&(gap>0)) set tempo="slow"

    set penalty="auto"
    if (a.energy>=70)&&(paceEdge>=10)&&(paceEdge>(packEdge+2))&&(hands>(kicking+3)) { set penalty="quick" }
    elseif (packEdge>=8)&&(lineoutEdge>=5) { set penalty="touch" }
    elseif (a.kicking>=(a.quality*1.15))&&(packEdge<5)&&(hands<=kicking) { set penalty="posts" }
    set decision={"version":(..#VERSION),"clock":(clock),"scoreGap":(gap),"tactic":{"style":(style),"tempo":(tempo),"defense":(pressure),"penaltyPriority":(penalty)},"reason":(reason),"opportunities":{"hands":(hands),"kicking":(kicking),"defense":(defenseEdge),"pace":(paceEdge),"stamina":(staminaEdge),"pack":(packEdge),"lineout":(lineoutEdge)},"ownProfile":(a),"opponentProfile":(b)}
    quit ..Context(decision,a.energy,clock,gap)
}
ClassMethod Context(base As %DynamicObject, energy As %Numeric, clock As %Integer, gap As %Integer) As %DynamicObject
{
    // Reuse the pre-match unit comparison for abbreviated matches.
    set decision={"version":(..#VERSION),"tactic":(base.tactic),"reason":(base.%Get("matchupReason",base.reason)),"matchupReason":(base.%Get("matchupReason",base.reason)),"opportunities":(base.opportunities),"ownProfile":(base.ownProfile),"opponentProfile":(base.opponentProfile)},a=decision.ownProfile,o=decision.opportunities
    set style=decision.tactic.style,tempo=decision.tactic.tempo,pressure=decision.tactic.defense,penalty=decision.tactic.%Get("penaltyPriority","auto"),reason=decision.reason
    set hands=o.hands,kicking=o.kicking,paceEdge=o.pace,packEdge=o.pack,defenseEdge=o.defense
    if (energy<65)&&(pressure="high") set pressure="normal"
    if (energy<55)&&(tempo="fast") set tempo="normal"
    set remaining=$select(clock<4800:4800-clock,1:0),objective="matchup"
    if (clock>=3600)&&(gap>0) {
        set objective="protect",tempo="slow",penalty="posts"
        if kicking>=(hands-5) set style="kicking"
        if energy<65 set pressure="low"
        set reason=reason_" Con ventaja en el último tramo, buscamos controlar el territorio y ampliar la diferencia con puntos seguros."
    }
    if (clock>=3600)&&(gap<0) {
        set objective=$select(gap>=-3:"points",1:"try")
        if energy>=55 set tempo="fast"
        if (energy>=65)&&(defenseEdge>=-5)&&(a.all.discipline>=(a.quality*.9)) set pressure="high"
        if objective="points" {
            set penalty="posts",reason=reason_" La diferencia permite empatar o remontar con un golpe a palos."
        } else {
            set penalty=$select((energy>=65)&&(hands>(kicking+3))&&(paceEdge>packEdge):"quick",1:"touch")
            if penalty="quick" set style="hands"
            set reason=reason_" El marcador exige buscar el ensayo antes de que termine el partido."
        }
    }
    if (clock>=4200)&&(gap=0) set objective="breakTie",penalty="posts"
    // Fatigue takes precedence over chasing the score.
    if energy<50 set tempo="slow"
    if energy<45 set pressure="low"
    if tempo="fast" set reason=reason_" La energía y la resistencia permiten explotar los espacios a un ritmo alto."
    if tempo="slow" set reason=reason_" Conviene dosificar el esfuerzo y controlar el tramo restante."
    if pressure="low" set reason=reason_" Reducir la presión conserva energía ante el desequilibrio defensivo o el cansancio."
    if pressure="high" set reason=reason_" La ventaja defensiva y de movilidad permite presionar con mayor intensidad."
    set decision.clock=clock,decision.scoreGap=gap,decision.energy=energy,decision.remainingSeconds=remaining,decision.objective=objective
    set decision.tactic={"style":(style),"tempo":(tempo),"defense":(pressure),"penaltyPriority":(penalty)},decision.reason=reason
    quit decision
}
ClassMethod Relative(own As %Numeric, opponent As %Numeric) As %Numeric
{
    set denominator=$select(own>opponent:own,1:opponent)
    if denominator<10 set denominator=10
    quit ##class(Rugby.Simulation.Engine).Clamp((own-opponent)*100/denominator,-100,100)
}
ClassMethod Adapt(m As %DynamicObject, side As %String, initial As %Boolean = 0)
{
    set other=$select(side="home":"away",1:"home"),clock=##class(Rugby.Simulation.PeriodEnd).Display(m),gap=m.%Get(side_"Score")-m.%Get(other_"Score"),energy=0,count=0
    set players=m.%Get(side_"Players")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.status="field" set energy=energy+p.energy,count=count+1 }
    set energy=$select(count:energy/count,1:0),band=$select(energy<45:0,energy<50:1,energy<55:2,energy<65:3,energy<70:4,1:5)
    if '$isobject(m.%Get("aiTacticalReviews")) set m.aiTacticalReviews={}
    set previous=m.aiTacticalReviews.%Get(side),review=initial||('$isobject(previous))
    if $isobject(previous) {
        set elapsed=m.clock-previous.clock,otherCount=##class(Rugby.Simulation.Discipline).Count(m.%Get(other_"Players"))
        set changed=(gap'=previous.gap)||(band'=previous.band)||(count'=previous.count)||(otherCount'=previous.otherCount)
        set urgent=(m.period'=previous.period)||(m.%Get(side_"Subs",0)'=previous.subs)
        set review=review||(elapsed>=300)||((elapsed>=60)&&changed)||(urgent&&(elapsed>0))
        if (elapsed>0)&&(m.%Get("aiNextTacticalReview",1)=0) set review=1
    }
    if 'review quit
    set decision=..Decide(players,m.%Get(other_"Players"),clock,gap,m.%Get(other_"Tactic")),current=m.%Get(side_"Tactic")
    do m.aiTacticalReviews.%Set(side,{"clock":(m.clock),"gap":(gap),"band":(band),"count":(count),"otherCount":(##class(Rugby.Simulation.Discipline).Count(m.%Get(other_"Players"))),"period":(m.period),"subs":(m.%Get(side_"Subs",0))})
    if '$isobject(m.%Get("aiTacticalAssessments")) set m.aiTacticalAssessments={}
    set decision.side=side,m.aiTacticalAssessment=decision,m.aiNextTacticalReview=m.clock+300,m.tacticalVersion=..#VERSION
    do m.aiTacticalAssessments.%Set(side,decision)
    if initial||m.%Get("aggregate",0) { do m.%Set(side_"Tactic",decision.tactic) quit }
    set chosen=decision.tactic
    if (chosen.style=current.style)&&(chosen.tempo=current.tempo)&&(chosen.defense=current.defense)&&(chosen.%Get("penaltyPriority","auto")=current.%Get("penaltyPriority","auto")) quit
    set command=##class(Rugby.Service.Matches).Command(m.id,{"type":"tactic","tactic":(chosen),"assessment":(decision)},"adaptive-"_side_"-"_m.clock,side,"ai",m)
}
ClassMethod Modifier(own As %DynamicObject, opponent As %DynamicObject) As %Numeric
{
    set score=$select(own.tactic.style="hands":own.opportunities.hands,own.tactic.style="kicking":own.opportunities.kicking,1:0)/10
    if (own.tactic.style="hands")&&(opponent.tactic.defense="high") set score=score-1.5
    if (own.tactic.style="kicking")&&(opponent.tactic.defense="high") set score=score+1
    quit ##class(Rugby.Simulation.Engine).Clamp(score,-5,5)
}
}
