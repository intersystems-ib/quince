Class Rugby.Job.Worker Extends %RegisteredObject
{
ClassMethod Now() As %Numeric
{
    set h=$ztimestamp
    quit ($piece(h,",",1)*86400)+$piece(h,",",2)
}
ClassMethod Cycle(id As %String, elapsed As %Numeric) As %Boolean
{
    lock +^RugbyWrite:0
    if '$test quit 0
    if $data(^RugbyGames(##class(Rugby.Service.Store).Game())) { set game=##class(%DynamicObject).%FromJSON(^RugbyGames(##class(Rugby.Service.Store).Game())) if 'game.%Get("active",0) { lock -^RugbyWrite quit 0 } }
    lock +^RugbyMatch(id):0
    if '$test { lock -^RugbyWrite quit 0 }
    try {
        tstart
        set m=##class(Rugby.Service.Store).Get("Match",id),version=m.version
        if (m.status'="finished")&&(m.status'="scheduled") {
            // Charge elapsed time using the old speed before applying a speed command.
            set m.credit=m.credit+(elapsed*m.speed)
            do ##class(Rugby.Service.Matches).Commands(m,1)
            // A paused dead-ball window still accepts substitutions and tactics.
            if (m.speed=0)||(m.status="halftime") { if $listfind($listbuild("restart","scrum","lineout","penalty","stoppage","conversion"),m.phase) do ##class(Rugby.Service.Matches).Commands(m) }
            for n=1:1:8 {
                quit:(m.credit<20)||(m.status="finished")||(m.speed=0)
                set m.credit=m.credit-20
                do ##class(Rugby.Simulation.Engine).Step(m)
            }
            // All writers hold RugbyWrite. Version prevents accidental stale writes.
            set check=##class(Rugby.Service.Store).Get("Match",id)
            if check.version'=version do ##class(Rugby.Service.Store).Fail(409,"STALE_MATCH","Versión de partido obsoleta.")
            for team="home","away" { set a=m.%Get(team_"Players") for j=0:1:a.%Size()-1 { do ##class(Rugby.Service.Store).Put("MatchPlayer",a.%Get(j)) } }
            do ##class(Rugby.Service.Store).Put("Match",m)
        }
        tcommit
    } catch ex {
        if $tlevel trollback
        lock -^RugbyMatch(id)
        lock -^RugbyWrite
        throw ex
    }
    lock -^RugbyMatch(id)
    lock -^RugbyWrite
    quit 1
}
}
