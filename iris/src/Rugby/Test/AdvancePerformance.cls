Class Rugby.Test.AdvancePerformance Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod ProbeLocks(a As %String, b As %String, token As %String)
{
    lock +@a:0
    set ^RugbyProbe(token,"same")=$test
    if $test lock -@a
    lock +@b:0
    set ^RugbyProbe(token,"other")=$test
    if $test lock -@b
    set ^RugbyProbe(token,"done")=1
}
ClassMethod Locks()
{
    set game=##class(Rugby.Service.Store).Game(),token="advance-lock-"_$job,%RugbyGame="qa-lock-a",a=##class(Rugby.Service.Store).LockName(),%RugbyGame="qa-lock-b",b=##class(Rugby.Service.Store).LockName(),%RugbyGame=game
    // The suite's maintenance lock is released only for the independent lock probe.
    lock -^RugbyWrite
    lock +@a:3
    try {
        kill ^RugbyProbe(token)
        job ##class(Rugby.Test.AdvancePerformance).ProbeLocks(a,b,token)
        for i=1:1:100 { quit:$get(^RugbyProbe(token,"done"))  hang .02 }
        do ..Assert($get(^RugbyProbe(token,"done"))&&('$get(^RugbyProbe(token,"same")))&&$get(^RugbyProbe(token,"other")),"One game blocks its own writers while another game can proceed")
    } catch ex {
        lock -@a
        lock +^RugbyWrite:10
        throw ex
    }
    lock -@a
    lock +^RugbyWrite:10
    if '$test do ..Assert(0,"Maintenance lock restored")
    kill ^RugbyProbe(token)
}
ClassMethod Run()
{
    do ##class(Rugby.Service.Store).BeginRequest()
    try {
        set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),energy=p.energy,p.energy=1,again=##class(Rugby.Service.Store).Get("Player",p.id)
        do ..Assert(again.energy=energy,"Cached reads return detached objects")
        set previousGame=##class(Rugby.Service.Store).Game(),%RugbyGame="qa-cache-other",alien=##class(Rugby.Service.Store).Get("Player",p.id,0),%RugbyGame=previousGame
        do ..Assert('$isobject(alien),"Request cache never returns another game's records")
        set before=##class(Rugby.Service.Store).All("Player","clubId","c1").%Size(),p=again,p.clubId="c2"
        do ##class(Rugby.Service.Store).Put("Player",p)
        do ..Assert((##class(Rugby.Service.Store).Get("Player",p.id).clubId="c2")&&(##class(Rugby.Service.Store).All("Player","clubId","c1").%Size()=(before-1)),"A transfer invalidates cached rosters immediately")
        set p.clubId="c1"
        do ##class(Rugby.Service.Store).Put("Player",p)
        set c=##class(Rugby.Service.Store).Get("Club","c1"),f={"id":"performance-fixture","clubId":"c2","homeId":"c2","awayId":"c3","day":(c.day-1),"date":(##class(Rugby.Service.Injuries).Date(c.day-1)),"stage":"friendly","status":"scheduled","matchId":""}
        do ##class(Rugby.Service.Store).Put("Fixture",f),##class(Rugby.Service.Store).EnsureFixtureDays()
        set f.day=c.day-2,f.date=##class(Rugby.Service.Injuries).Date(f.day)
        do ##class(Rugby.Service.Store).Put("Fixture",f)
        do ..Assert(('$data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"fixtureDays",c.day-1,f.id)))&&$data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"fixtureDays",c.day-2,f.id)),"Rescheduling moves the date index without leaving stale entries")
        set initial=##class(Rugby.Service.AutoAdvance).State(c.id),result=##class(Rugby.Service.AutoAdvance).Step(c.id,{"version":(c.version),"resultsRevision":(initial.resultsRevision)},"performance-auto"),retry=##class(Rugby.Service.AutoAdvance).Step(c.id,{},"performance-auto")
        do ..Assert((result.club.day=c.day+1)&&(result.%ToJSON()=retry.%ToJSON()),"Automatic steps return the schedule and are idempotent")
        set next=##class(Rugby.Service.AutoAdvance).Step(c.id,{"version":(result.club.version),"resultsRevision":(result.resultsRevision)},"performance-auto-next")
        do ..Assert('next.%IsDefined("results"),"Unchanged results are not sent again on the next day")
        set f.status="finished",f.homeScore=0,f.awayScore=0,f.homeTries=0,f.awayTries=0
        do ##class(Rugby.Service.Store).Put("Fixture",f)
        set updated=##class(Rugby.Service.AutoAdvance).State(c.id,next.resultsRevision)
        do ..Assert(updated.%IsDefined("results")&&(updated.resultsRevision'=next.resultsRevision),"Finishing a match invalidates the cached result summary")
        set journal=##class(Rugby.Service.Store).Get("RivalExecution","rivals-day-"_next.club.day)
        for i=0:1:journal.clubs.%Size()-1 {
            set report=journal.clubs.%Get(i),training=##class(Rugby.Service.Store).Get("TrainingExecution",report.trainingExecutionId)
            do ..Assert(('report.%IsDefined("results"))&&('report.%IsDefined("staffSnapshot"))&&(training.playersTrained>0)&&(training.results.%Size()=0),"Daily audit references a minimal training receipt")
        }
        set office=##class(Rugby.Service.Finance).Office(c.id),season=##class(Rugby.Service.Finance).Season(next.club)
        do ##class(Rugby.Service.Finance).Tick(c.id)
        do ..Assert((office.version=##class(Rugby.Service.Finance).Office(c.id).version)&&(season.version=##class(Rugby.Service.Finance).Season(next.club).version),"An unchanged financial day does not rewrite office and season")
        set recent=##class(Rugby.Service.MatchStatistics).Recent()
        for i=0:1:recent.items.%Size()-1 { do ..Assert('recent.items.%Get(i).%IsDefined("tacticalAssessments"),"Result summaries omit full simulation data") }
    } catch ex { do ##class(Rugby.Service.Store).EndRequest() throw ex }
    do ##class(Rugby.Service.Store).EndRequest()
    do ..Assert('$get(%RugbyCacheDepth),"Request cache is released after the operation")
}
}
