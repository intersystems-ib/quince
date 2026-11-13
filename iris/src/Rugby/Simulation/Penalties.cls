Class Rugby.Simulation.Penalties Extends %RegisteredObject
{
ClassMethod Shot(m As %DynamicObject, p As %DynamicObject) As %DynamicObject
{
    set direction=$select((m.possession="home")=(m.period=1):1,1:-1),progress=$select(direction=1:m.x,1:100-m.x),lateral=$zabs(m.y-35),distance=(((100-progress)**2)+(lateral**2))**.5,skill=##class(Rugby.Simulation.Engine).Rating(p,"kicking"),range=24+(skill*.5),chance=##class(Rugby.Simulation.Engine).Clamp(.20+(skill*.009)-(distance*.0045)-(lateral/200),.05,.95)
    set result={"progress":(progress),"distance":(distance),"lateral":(lateral),"successChance":(chance),"range":(range)}
    do result.%Set("reachable",(distance<=range)&&(chance>=.30),"boolean")
    quit result
}
ClassMethod Runner(players As %DynamicArray) As %DynamicObject
{
    set unit=##class(Rugby.Simulation.Performance).Unit(players,"backs")
    if unit.%Size()=0 set unit=##class(Rugby.Simulation.Performance).Unit(players)
    set best="",score=-1
    for i=0:1:unit.%Size()-1 {
        set p=unit.%Get(i),value=(##class(Rugby.Simulation.Performance).Skill(p,"carry")*.7)+(##class(Rugby.Simulation.Engine).Rating(p,"decisions")*.3)
        if value>score set score=value,best=p
    }
    quit best
}
ClassMethod Decide(m As %DynamicObject, kicker As %DynamicObject) As %DynamicObject
{
    set side=m.possession,other=$select(side="home":"away",1:"home"),t=m.%Get(side_"Tactic"),priority=t.%Get("penaltyPriority","auto"),shot=..Shot(m,kicker),choice="touch",reason="Ganar territorio y conservar el saque de lateral.",gap=m.%Get(side_"Score")-m.%Get(other_"Score"),remaining=4800+m.%Get("firstHalfAddedSeconds",0)-m.clock
    if priority="posts" {
        if shot.reachable { set choice="posts",reason="Prioridad de asegurar puntos con un tiro alcanzable." }
        else { set reason="El tiro queda fuera del alcance razonable; se busca la touche." }
    } elseif priority="touch" { set reason="Prioridad de buscar el ensayo mediante territorio y posesión." }
    elseif priority="quick" {
        set runner=..Runner(m.%Get(side_"Players"))
        if $isobject(runner)&&(runner.energy>=35)&&(shot.progress>=35) { set choice="quick",reason="Prioridad de jugar rápido y atacar con continuidad." }
        else { set reason="Se asegura territorio al no haber condiciones para jugar rápido." }
    } else {
        set a=##class(Rugby.Simulation.Tactics).Profile(m.%Get(side_"Players")),b=##class(Rugby.Simulation.Tactics).Profile(m.%Get(other_"Players")),pack=(a.forwards.lineout+a.forwards.maul+a.forwards.strength)/3,otherPack=(b.forwards.lineout+b.forwards.maul+b.forwards.strength)/3,fast=(a.backs.speed+a.backs.agility)/2,defense=(b.all.tackling+b.all.defensiveReading)/2
        if (remaining<=600)&&(gap<0)&&(gap>=-3)&&shot.reachable { set choice="posts",reason="Tres puntos permiten empatar o ponerse por delante en el tramo final." }
        elseif (remaining<=600)&&(gap< -3)&&(shot.progress>=45) { set choice=$select((remaining<=120)&&(a.energy>=35):"quick",1:"touch"),reason="Se necesita un ensayo; tres puntos no bastan para remontar." }
        elseif (gap>7)&&(m.clock>=3000)&&(shot.progress>=65)&&((m.%Get(side_"Stats").tries-m.%Get(other_"Stats").tries)<3) { set reason="Buscar otro ensayo puede acercar el bonus ofensivo." }
        elseif (shot.progress>=78)&&(pack>(otherPack+5)) { set reason="La ventaja de delanteros favorece atacar desde la touche." }
        elseif shot.reachable&&(shot.successChance>=.55) { set choice="posts",reason="El pateador dispone de una oportunidad favorable de sumar tres puntos." }
        elseif (shot.progress>=55)&&(a.energy>=60)&&(fast>(defense+5)) { set choice="quick",reason="La velocidad y la energía favorecen sorprender jugando rápido." }
        elseif shot.reachable&&(gap>=0) { set choice="posts",reason="Sumar puntos permite consolidar el marcador." }
    }
    quit {"priority":(priority),"choice":(choice),"reason":(reason),"distance":(shot.distance),"successChance":(shot.successChance),"scoreGap":(gap),"remainingSeconds":(remaining)}
}
}
