Class Rugby.Service.MatchResultMode Extends %RegisteredObject
{
ClassMethod Play(m As %DynamicObject, target As %String)
{
    // The same actions, RNG, added time and settlement as the visual match.
    do ##class(Rugby.Service.Matches).Commands(m)
    for step=1:1:1000 {
        quit:(m.status="finished")||((target="halftime")&&(m.status="halftime"))
        set m.speed=1,m.credit=0,m.pauseReason="",m.pauseMessage="",m.pausedPlayerId=""
        do ##class(Rugby.Simulation.Engine).Step(m)
    }
    if (m.status'="finished")&&((target'="halftime")||(m.status'="halftime")) do ##class(Rugby.Service.Store).Fail(409,"MATCH_RESULT_LIMIT","No se ha podido completar la parte del partido. Inténtalo de nuevo.")
    set m.speed=0,m.credit=0
    for side="home","away" {
        set players=m.%Get(side_"Players")
        for i=0:1:players.%Size()-1 { do ##class(Rugby.Service.Store).Put("MatchPlayer",players.%Get(i)) }
    }
    do ##class(Rugby.Service.Store).Put("Match",m)
}
ClassMethod Advance(id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set m=##class(Rugby.Service.Store).Get("Match",id)
    do ##class(Rugby.Service.Store).Managed(m.clubId)
    if m.%Get("viewMode","visualize")'="result" do ##class(Rugby.Service.Store).Fail(409,"MATCH_VIEW_MODE","Este partido utiliza el modo Visualizar.")
    set target=b.%Get("target"),game=##class(Rugby.Service.Store).Game()
    if '$listfind($listbuild("halftime","fulltime"),target) do ##class(Rugby.Service.Store).Fail(422,"MATCH_RESULT_TARGET","Selecciona descanso o final del partido.")
    if $data(^RugbyWorld(game,"resultAdvances",id,key)) quit m
    if m.status="scheduled" do ##class(Rugby.Service.Store).Fail(409,"MATCH_NOT_STARTED","Inicia el partido desde la previa.")
    if (m.status="finished")||((target="halftime")&&((m.status="halftime")||(m.period=2))) quit m
    if (target="fulltime")&&(m.status'="halftime") do ##class(Rugby.Service.Store).Fail(409,"MATCH_HALFTIME_REQUIRED","Debes llegar al descanso antes de ir al final.")
    do ..Play(m,target)
    set ^RugbyWorld(game,"resultAdvances",id,key)=target
    quit m
}
}
