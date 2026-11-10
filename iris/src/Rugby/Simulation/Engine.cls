Class Rugby.Simulation.Engine Extends %RegisteredObject
{
Parameter STEP = 20;
Parameter VERSION = "1.1.0";
ClassMethod Clamp(v As %Numeric, low As %Numeric = 0.08, high As %Numeric = 0.92) As %Numeric
{
    quit $select(v<low:low,v>high:high,1:v)
}
ClassMethod Random(m As %DynamicObject) As %Numeric
{
    // Park-Miller. RNG state is committed with the transition, never with wall time.
    set m.rng=(m.rng*16807)#2147483647
    quit m.rng/2147483647
}
ClassMethod Rating(p As %DynamicObject, skill As %String) As %Numeric
{
    quit p.attributes.%Get(skill)*(.55+(.45*p.energy/100))*(.9+(p.form/1000)+(p.morale/2000))
}
ClassMethod Strength(players As %DynamicArray, skill As %String) As %Numeric
{
    set sum=0,count=0
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.status="field" set sum=sum+..Rating(p,skill),count=count+1 }
    quit sum/15
}
ClassMethod Actor(m As %DynamicObject, players As %DynamicArray) As %DynamicObject
{
    if $listfind($listbuild("conversion","penalty"),m.phase) quit ##class(Rugby.Simulation.Performance).Kicker(players)
    set group=$select($listfind($listbuild("scrum","lineout","ruck"),m.phase):"forwards",1:"all"),eligible=##class(Rugby.Simulation.Performance).Unit(players,group,m,$select(group="forwards":3,1:15))
    // A depleted pack must still allow the match to progress.
    if eligible.%Size()=0 set eligible=##class(Rugby.Simulation.Performance).Unit(players)
    quit eligible.%Get(..Random(m)*eligible.%Size()\1)
}
ClassMethod Event(m As %DynamicObject, type As %String, side As %String, text As %String, points As %Integer, oldX As %Numeric, oldY As %Numeric, pid As %String, tactical As %DynamicObject = "")
{
    do ##class(Rugby.Simulation.Movement).Update(m,pid)
    set m.sequence=m.sequence+1
    set e={"id":(m.id_"-"_$translate($justify(m.sequence,6)," ","0")),"matchId":(m.id),"sequence":(m.sequence),"period":(m.period),"clock":(m.clock),"type":(type),"side":(side),"playerId":(pid),"from":{"x":(oldX),"y":(oldY)},"to":{"x":(m.x),"y":(m.y)},"points":(points),"homeScore":(m.homeScore),"awayScore":(m.awayScore),"result":{"phase":(m.phase),"possession":(m.possession),"inGoal":(type="try")},"text":(text)}
    if $isobject(tactical) do e.result.%Set("tacticalDecision",tactical)
    if $isobject(m.%Get("actionContext")) do e.result.%Set("contest",m.actionContext)
    do ##class(Rugby.Service.Store).Put("MatchEvent",e)
}
ClassMethod Step(m As %DynamicObject)
{
    if (m.status="finished")||(m.status="scheduled")||(m.%Get("speed",1)=0) quit
    if m.engineVersion="1.0.0" set m.previousEngineVersion=m.engineVersion,m.engineVersion=..#VERSION
    if m.engineVersion'=..#VERSION do ##class(Rugby.Service.Store).Fail(409,"ENGINE_VERSION","La partida requiere una versión distinta del motor.")
    do m.%Remove("actionContext")
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    if m.status="halftime" {
        set m.status="second",m.period=2,m.phase="restart",m.x=50,m.y=35,m.possession="away"
        do ..Event(m,"secondHalf","away","Comienza la segunda parte. Se cambia el sentido de ataque.",0,50,35,"")
        quit
    }
    set safe=$listfind($listbuild("restart","scrum","lineout","penalty","stoppage","conversion"),m.phase)>0
    if safe {
        do ##class(Rugby.Service.Matches).AI(m)
        do ##class(Rugby.Service.Matches).Commands(m)
    }
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers),##class(Rugby.Simulation.Performance).AlignmentMorale(m.awayPlayers)
    set side=m.possession,other=$select(side="home":"away",1:"home"),players=m.%Get(side_"Players"),defenders=m.%Get(other_"Players"),t=m.%Get(side_"Tactic"),dt=m.%Get(other_"Tactic"),stats=m.%Get(side_"Stats"),ds=m.%Get(other_"Stats"),p=..Actor(m,players),oldX=m.x,oldY=m.y,points=0
    set direction=$select((side="home")=(m.period=1):1,1:-1),progress=$select(direction=1:m.x,1:100-m.x)
    set phase=m.phase,type="run",text="",pid=p.playerId
    set end=$select(m.period=1:2400,1:4800)
    set elapsed=..Clamp(m.clock+..#STEP,0,end)-m.clock,m.clock=m.clock+elapsed,stats.actions=stats.actions+1,stats.possessionSeconds=stats.possessionSeconds+..#STEP,p.stats.actions=p.stats.actions+1
    for team="home","away" { set participants=m.%Get(team_"Players") for i=0:1:participants.%Size()-1 { set q=participants.%Get(i) if q.status="field" set q.playedSeconds=q.%Get("playedSeconds",0)+elapsed } }
    set contest=##class(Rugby.Simulation.Performance).Contest(players,defenders,phase,p),m.actionContext=contest,attack=contest.attack,defense=contest.defense
    set localDefense=##class(Rugby.Simulation.Performance).Unit(defenders,"all",p,3)
    if (phase'="scrum")&&(phase'="lineout") set defense=defense+$select(dt.defense="high":5,dt.defense="low":-4,1:0)
    set chance=..Clamp(.59+((attack-defense)/180)+((..Rating(p,"decisions")-55)/350)+$select(t.tempo="fast":.025,t.tempo="slow":-.015,1:0))
    set contest.defense=defense,contest.successChance=chance
    if phase="conversion" {
        set type="conversion",contest.successChance=..Clamp(.52+(..Rating(p,"kicking")/250)-($zabs(m.y-35)/180)),success=..Random(m)<contest.successChance
        if success set points=2,stats.conversions=stats.conversions+1
        set text=$select(success:"Transformación entre palos. Dos puntos más.",1:"La transformación se marcha fuera."),m.possession=other,m.x=50,m.y=35,m.phase="restart"
    } elseif phase="restart" {
        set type="kickoff",m.x=..Clamp(50+(direction*(15+(..Random(m)*12))),0,100),m.y=15+(..Random(m)*40),m.phase="open",m.possession=other,text="Reinicio largo. El receptor asegura la posesión."
    } elseif (phase="scrum")||(phase="lineout") {
        set skill=$select(phase="scrum":"scrum",1:"lineout"),type=phase
        set contest.successChance=..Clamp(.58+((attack-defense)/160)),win=..Random(m)<contest.successChance
        do stats.%Set($select(phase="scrum":"scrums",1:"lineouts"),stats.%Get($select(phase="scrum":"scrums",1:"lineouts"))+1)
        if 'win set m.possession=other,ds.turnovers=ds.turnovers+1
        set text=$select(phase="scrum":"Melé",1:"Touche")_$select(win:" ganada por el equipo que introduce.",1:" robada por el rival."),m.phase="open",m.y=35
    } elseif phase="penalty" {
        set type="penalty",stats.penalties=stats.penalties+1
        if progress>55 {
            set contest.successChance=..Clamp(.35+(..Rating(p,"kicking")/170)-((100-progress)/180)),success=..Random(m)<contest.successChance,type="penaltyGoal"
            if success set points=3,stats.penaltyGoals=stats.penaltyGoals+1
            set text=$select(success:"Golpe a palos convertido. Tres puntos.",1:"El golpe a palos no encuentra su objetivo."),m.phase="restart",m.x=50,m.y=35,m.possession=other
        } else { set m.x=..Clamp(m.x+(direction*22),2,98),m.y=0,m.phase="lineout",text="Golpe de castigo. Patada a touche para ganar terreno." }
    } else {
        set r=..Random(m),kick=$select(t.style="kicking":.30,t.style="hands":.06,1:.15)
        if (progress>78)&&(r<.07) {
            set type="drop",success=..Random(m)<..Clamp(.12+(..Rating(p,"kicking")/230))
            if success set points=3,stats.drops=stats.drops+1
            set text=$select(success:"Drop certero. Tres puntos desde el juego abierto.",1:"El intento de drop se desvía."),m.phase="restart",m.x=50,m.y=35,m.possession=other
        } elseif r<kick {
            set type="kick",stats.kicks=stats.kicks+1,m.x=..Clamp(m.x+(direction*(12+(..Rating(p,"kicking")/5))),2,98)
            if ..Random(m)<.42 { set m.phase="lineout",m.y=0,text=p.name_" busca la touche con el pie." } else { set m.phase="open",text=p.name_" patea al espacio; recoge el rival." }
            set m.possession=other
        } elseif r>(.96-((100-##class(Rugby.Simulation.Performance).Score(localDefense,"discipline",3))/1500)) {
            set type="penalty",m.phase="penalty",text="Golpe de castigo por infracción de la defensa."
            do ##class(Rugby.Simulation.Discipline).Foul(m,other,localDefense)
        } elseif ..Random(m)<chance {
            set metres=3+(..Random(m)*10)+((##class(Rugby.Simulation.Performance).Skill(p,"carry")-50)/12)+$select(t.tempo="fast":2,1:0)
            set m.x=..Clamp(m.x+(direction*metres),0,100),m.y=..Clamp(m.y+((..Random(m)-.5)*20),1,69),stats.metres=stats.metres+metres
            set type=$select(r<.58:"pass",1:"run")
            if type="pass" set stats.passes=stats.passes+1
            set text=p.name_$select(type="pass":" enlaza un pase y gana ",1:" rompe la línea y avanza ")_(metres\1)_" metros.",m.phase="ruck",ds.tackles=ds.tackles+1
            set newProgress=$select(direction=1:m.x,1:100-m.x)
            if newProgress>=100 {
                set type="try",points=5,stats.tries=stats.tries+1,p.stats.tries=p.stats.tries+1,m.phase="conversion",text="¡Ensayo de "_p.name_"! Apoya el balón en la zona de marca."
            }
        } else {
            set r=..Random(m)
            if r<.3 { set type="knockOn",m.phase="scrum",m.possession=other,text="Avant de "_p.name_". Melé para el rival." } elseif r<.6 {
                set type="turnover",m.possession=other,m.phase="ruck",ds.turnovers=ds.turnovers+1,text="El rival recupera el balón en el ruck."
            } else { set type="tackle",m.phase="ruck",ds.tackles=ds.tackles+1,text="Placaje firme. "_p.name_" protege el balón en el ruck." }
        }
        // A declared dead ball at least every six actions bounds command latency.
        if (m.clock#120=0)&&(m.phase="ruck") set m.phase="stoppage",text=text_" Interrupción arbitral; balón muerto."
    }
    if points {
        do m.%Set(side_"Score",m.%Get(side_"Score")+points)
        set p.stats.points=p.stats.points+points
    }
    for team="home","away" {
        set a=m.%Get(team_"Players"),tac=m.%Get(team_"Tactic")
        for i=0:1:a.%Size()-1 {
            set q=a.%Get(i)
            if q.status="field" {
                set loss=(.22+$select(tac.tempo="fast":.10,tac.tempo="slow":-.04,1:0)+$select(tac.defense="high":.06,1:0))*(1.3-(q.attributes.stamina/150))
                set q.energy=..Clamp(q.energy-loss,0,100)
            }
        }
    }
    do ..Event(m,type,side,text,points,oldX,oldY,pid)
    do ##class(Rugby.Service.Injuries).MatchTick(m,elapsed)
    do ##class(Rugby.Simulation.Discipline).Returns(m)
    if (m.clock>=end)&&(m.phase'="conversion") {
        if m.period=1 {
            set m.status="halftime",m.phase="stoppage"
            for team="home","away" { set a=m.%Get(team_"Players") for i=0:1:a.%Size()-1 { set q=a.%Get(i) if q.status="field" set q.energy=..Clamp(q.energy+7,0,100) } }
            do ..Event(m,"halftime","","Descanso. Recuperación limitada; se completó la última fase del periodo.",0,m.x,m.y,"")
            do ##class(Rugby.Service.Matches).Pause(m,"halftime","Descanso. Revisa los cambios y la táctica. Selecciona una velocidad para comenzar la segunda parte.")
        } else {
            set m.status="finished",m.phase="stoppage"
            do ##class(Rugby.Service.Matches).PlayoffWinner(m)
            do ..Event(m,"fulltime","","Final del encuentro. Resultado confirmado.",0,m.x,m.y,"")
            do ##class(Rugby.Service.Matches).Settle(m)
        }
    }
}
}
