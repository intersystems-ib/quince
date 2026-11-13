Class Rugby.Simulation.PeriodEnd Extends %RegisteredObject
{
ClassMethod Limit(m As %DynamicObject) As %Integer { quit $select(m.period=1:2400,1:4800+m.%Get("firstHalfAddedSeconds",0)) }
ClassMethod Display(m As %DynamicObject, clock As %Integer = -1, period As %Integer = 0) As %Integer
{
    if clock<0 set clock=m.clock
    if period=0 set period=m.period
    quit clock-$select(period=2:m.%Get("firstHalfAddedSeconds",0),1:0)
}
ClassMethod Dead(m As %DynamicObject, type As %String) As %Boolean
{
    if m.clock<..Limit(m) quit 0
    // Penalties and their touch kicks continue; tries retain their conversion.
    if $listfind($listbuild("try","penalty","penaltyQuick"),type) quit 0
    if $listfind($listbuild("endKick","conversion","drop","penaltyGoal","knockOn"),type) quit 1
    quit (type="kick")&&(m.phase="lineout")
}
ClassMethod Close(m As %DynamicObject)
{
    do m.%Remove("periodEndPending")
    if m.period=1 {
        set m.firstHalfAddedSeconds=$select(m.clock>2400:m.clock-2400,1:0),m.status="halftime",m.phase="stoppage"
        for team="home","away" { set a=m.%Get(team_"Players") for i=0:1:a.%Size()-1 { set q=a.%Get(i) if q.status="field" set q.energy=##class(Rugby.Simulation.Engine).Clamp(q.energy+7,0,100) } }
        do ##class(Rugby.Simulation.Engine).Event(m,"halftime","","Descanso. El balón ha quedado fuera de juego con el tiempo cumplido.",0,m.x,m.y,"")
        do ##class(Rugby.Service.Matches).Pause(m,"halftime","Descanso. Revisa los cambios y la táctica. Selecciona una velocidad para comenzar la segunda parte.")
    } else {
        set m.status="finished",m.phase="stoppage",m.secondHalfAddedSeconds=m.clock-..Limit(m)
        do ##class(Rugby.Service.Matches).PlayoffWinner(m)
        do ##class(Rugby.Simulation.Engine).Event(m,"fulltime","","Final del encuentro. Balón fuera de juego con el tiempo cumplido.",0,m.x,m.y,"")
        do ##class(Rugby.Service.Matches).Settle(m)
    }
}
}
