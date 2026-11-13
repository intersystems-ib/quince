Class Rugby.Simulation.Discipline Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Count(players As %DynamicArray) As %Integer
{
    set count=0
    for i=0:1:players.%Size()-1 { if players.%Get(i).status="field" set count=count+1 }
    quit count
}
ClassMethod Event(m As %DynamicObject, type As %String, side As %String, p As %DynamicObject, text As %String)
{
    if m.%Get("aggregate",0) {
        do m.disciplineEvents.%Push({"type":(type),"side":(side),"playerId":(p.playerId),"clock":(m.clock),"text":(text)})
    } else {
        do ##class(Rugby.Simulation.Engine).Event(m,type,side,text,0,m.x,m.y,p.playerId)
    }
}
ClassMethod Card(m As %DynamicObject, side As %String, pid As %String, color As %String) As %Boolean
{
    if (m.status="finished")||('$listfind($listbuild("yellow","red"),color)) quit 0
    set players=m.%Get(side_"Players"),p=""
    for i=0:1:players.%Size()-1 { set candidate=players.%Get(i) if candidate.playerId=pid set p=candidate }
    if '$isobject(p) quit 0
    if p.status'="field" quit 0
    set stats=m.%Get(side_"Stats"),second=0,m.disciplineVersion=..#VERSION,m.redCardRule="permanent"
    if 'p.%IsDefined("cards") set p.cards=[]
    if color="yellow" {
        set p.yellowCards=p.%Get("yellowCards",0)+1,stats.yellowCards=stats.%Get("yellowCards",0)+1,second=p.yellowCards>=2
        do p.cards.%Push({"color":"yellow","clock":(m.clock)})
        if 'second set p.status="sinBin",p.sinBinUntil=m.clock+600
        do ..Event(m,"yellowCard",side,p,"Tarjeta amarilla para "_p.name_$select(second:". Segunda amarilla en el encuentro.",1:". Exclusión temporal de diez minutos de juego."))
    }
    if (color="red")||second {
        set p.status="sentOff",p.sinBinUntil=0,p.redCards=1,p.redCardReason=$select(second:"secondYellow",1:"dangerousPlay"),stats.redCards=stats.%Get("redCards",0)+1
        do p.cards.%Push({"color":"red","clock":(m.clock),"reason":(p.redCardReason)})
        do ..Event(m,"redCard",side,p,"Tarjeta roja para "_p.name_$select(second:" por doble amarilla.",1:" por juego intencionado y altamente peligroso.")_" Expulsión definitiva, sin sustitución.")
    }
    quit 1
}
ClassMethod Returns(m As %DynamicObject)
{
    if m.status="finished" quit
    for side="home","away" {
        set players=m.%Get(side_"Players")
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if (p.status="sinBin")&&(m.clock>=p.%Get("sinBinUntil",999999)) {
                set p.status="field",p.sinBinUntil=0
                do ..Event(m,"sinBinReturn",side,p,p.name_" vuelve al campo tras cumplir los diez minutos de exclusión.")
            }
        }
    }
}
ClassMethod Foul(m As %DynamicObject, side As %String, participants As %DynamicArray = "")
{
    set players=$select($isobject(participants):participants,1:m.%Get(side_"Players")),total=0,stats=m.%Get(side_"Stats")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.status="field" set total=total+101-p.attributes.discipline }
    if total<=0 quit
    set target=##class(Rugby.Simulation.Engine).Random(m)*total,p=""
    for i=0:1:players.%Size()-1 {
        set q=players.%Get(i)
        if q.status'="field" continue
        set target=target-(101-q.attributes.discipline)
        if target<0 { set p=q quit }
    }
    if '$isobject(p) quit
    set stats.infringements=stats.%Get("infringements",0)+1,p.infringements=p.%Get("infringements",0)+1,r=##class(Rugby.Simulation.Engine).Random(m)
    set red=.008+((100-p.attributes.discipline)/25000),yellow=.10+((100-p.attributes.discipline)/1200)+$select(p.infringements>=3:.08,1:0)
    if r<red { set applied=..Card(m,side,p.playerId,"red") }
    elseif r<(red+yellow) { set applied=..Card(m,side,p.playerId,"yellow") }
}
ClassMethod Aggregate(f As %DynamicObject, rng As %DynamicObject) As %DynamicObject
{
    set m={"clock":0,"status":"first","fixtureId":(f.id),"date":(f.%Get("date")),"rng":(rng.rng),"aggregate":true,"disciplineEvents":[],"injuryEvents":[],"homeSubs":0,"awaySubs":0,"homeStats":{},"awayStats":{}},seconds={"home":0,"away":0},participants=[],injuries=[]
    for side="home","away" {
        set l=##class(Rugby.Service.Store).Get("Lineup",f.%Get(side_"Id")_"-default"),players=[]
        for i=0:1:14+l.bench.%Size() {
            set starter=i<15,pid=$select(starter:l.slots.%Get(i).playerId,1:l.bench.%Get(i-15)),p=##class(Rugby.Service.Store).Get("Player",pid)
            set s={"playerId":(p.id),"name":(p.name),"status":($select(starter:"field",1:"bench")),"attributes":(p.attributes),"playedSeconds":0,"position":($select(starter:i+1,1:p.position)),"naturalPosition":(p.position),"secondary":(p.secondary),"energy":(p.energy),"age":(p.age),"morale":(p.morale)}
            do ##class(Rugby.Simulation.Performance).ApplyMorale(s),players.%Push(s)
        }
        do m.%Set(side_"Players",players)
    }
    for step=1:1:240 {
        set m.clock=step*20
        for side="home","away" {
            set players=m.%Get(side_"Players")
            for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.status="field" { set p.playedSeconds=p.playedSeconds+20 do seconds.%Set(side,seconds.%Get(side)+20) } }
            if ##class(Rugby.Simulation.Engine).Random(m)<.055 do ..Foul(m,side)
        }
        do ##class(Rugby.Service.Injuries).MatchTick(m,20)
        for side="home","away" { do ##class(Rugby.Service.Injuries).Replace(m,side) }
        do ..Returns(m)
    }
    for side="home","away" {
        do f.%Set(side_"YellowCards",m.%Get(side_"Stats").%Get("yellowCards",0)),f.%Set(side_"RedCards",m.%Get(side_"Stats").%Get("redCards",0))
        set players=m.%Get(side_"Players")
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if (i<15)||(p.playedSeconds>0) do participants.%Push({"side":(side),"playerId":(p.playerId),"playedSeconds":(p.playedSeconds),"morale":(p.morale),"positionMoralePenalty":(p.%Get("positionMoralePenalty",0)),"positionMoraleApplied":(p.%Get("positionMoraleApplied",0))})
            if $isobject(p.%Get("injury")) do injuries.%Push({"playerId":(p.playerId),"injury":(p.injury)})
        }
    }
    set rng.rng=m.rng,f.disciplineVersion=..#VERSION,f.redCardRule="permanent",f.disciplineEvents=m.disciplineEvents,f.disciplineParticipants=participants,f.injuryEvents=m.injuryEvents,f.matchInjuries=injuries
    set f.statisticsPlayers={"home":(m.homePlayers),"away":(m.awayPlayers)}
    quit {"home":(seconds.home/72000),"away":(seconds.away/72000)}
}
}
