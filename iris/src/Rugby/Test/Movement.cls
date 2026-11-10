Class Rugby.Test.Movement Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String)
{
    do ##class(Rugby.Test.Suite).Assert(ok,message)
}
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(),m.phase="open",m.possession="home",m.x=25,m.y=15,rng=m.rng,sequence=m.sequence,actor=m.homePlayers.%Get(8).playerId
    do ##class(Rugby.Simulation.Movement).Update(m,actor)
    set before=##class(%DynamicObject).%FromJSON(m.%ToJSON()),m.x=75,m.y=55,m.clock=20,moved=0
    do ##class(Rugby.Simulation.Movement).Update(m,actor)
    for side="home","away" {
        set players=m.%Get(side_"Players"),old=before.%Get(side_"Players"),count=0
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if p.status'="field" continue
            set count=count+1
            do ..Assert((p.x>=2.5)&&(p.x<=97.5)&&(p.y>=3)&&(p.y<=67),"Moving players remain inside the field")
            if (p.x'=old.%Get(i).x)||(p.y'=old.%Get(i).y) set moved=moved+1
            if p.playerId=actor do ..Assert((p.x=m.x)&&(p.y=m.y),"Carrier follows the ball")
        }
        do ..Assert(count=15,"Exactly fifteen active players per team")
    }
    do ..Assert(moved>=20,"Players reposition when the ball moves")
    do ..Assert((m.rng=rng)&&(m.sequence=sequence),"Movement does not consume gameplay RNG or create events")
    set m.phase="restart",m.x=50,m.y=35,m.status="first",m.period=1
    do ##class(Rugby.Simulation.Movement).Update(m)
    set firstX=m.homePlayers.%Get(0).x,firstY=m.homePlayers.%Get(0).y,m.status="halftime"
    do ##class(Rugby.Simulation.Movement).Update(m)
    do ..Assert((firstX<50)&&(m.homePlayers.%Get(0).x>50)&&(firstY<35)&&(m.homePlayers.%Get(0).y>35),"Formation changes ends at halftime")
    set out=m.homePlayers.%Get(0),replacement=m.homePlayers.%Get(15),out.status="replaced",replacement.status="field",replacement.position=out.position,oldX=out.x
    do ##class(Rugby.Simulation.Movement).Update(m)
    do ..Assert(replacement.%IsDefined("x")&&replacement.%IsDefined("y"),"Substitute receives the occupied position's coordinates")
    do ..Assert(out.x=oldX,"Replaced player stops moving")
    do ##class(Rugby.Service.Store).Put("Match",m)
    do ##class(Rugby.Job.Worker).Cycle(m.id,1)
    set saved=##class(Rugby.Service.Store).Get("MatchPlayer",replacement.id)
    do ..Assert(saved.%IsDefined("x")&&saved.%IsDefined("y"),"Worker persists player coordinates with the match checkpoint")
}
ClassMethod Export(path As %String)
{
    lock +^RugbyWrite:10
    if '$test quit
    try {
        tstart
        set m=##class(Rugby.Test.Suite).Build(17341),frames=[]
        for i=0:1:11 {
            do frames.%Push(##class(%DynamicObject).%FromJSON(m.%ToJSON()))
            for step=1:1:3 { do ##class(Rugby.Simulation.Engine).Step(m) }
        }
        set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8"
        set sc=stream.LinkToFile(path)
        if $SYSTEM.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        do stream.Write(frames.%ToJSON())
        set sc=stream.%Save()
        if $SYSTEM.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        trollback
        write "MOVEMENT FRAMES EXPORTED",!
    } catch ex {
        if $tlevel trollback
        lock -^RugbyWrite
        throw ex
    }
    lock -^RugbyWrite
}
}
