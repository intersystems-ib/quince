Class Rugby.Test.MatchStatistics Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(593)
    for n=1:1:400 { quit:m.status="finished"  if m.speed=0 { set m.speed=60 } do ##class(Rugby.Simulation.Engine).Step(m) }
    do ..Assert(m.status="finished","Full match completes with individual statistics")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId),count=##class(Rugby.Service.Store).All("PlayerMatchStats").%Size()
    for side="home","away" {
        set players=m.%Get(side_"Players"),team=m.%Get(side_"Stats"),sums={},score=0
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i),r=##class(Rugby.Service.Store).Get("PlayerMatchStats",f.id_"-"_p.playerId)
            do ..Assert(r.complete&&(r.playedSeconds=p.playedSeconds)&&(r.stats.%ToJSON()=##class(Rugby.Service.MatchStatistics).Entry(p,f,m.id).stats.%ToJSON()),"Final player snapshot is persisted exactly")
            for key="metres","tackles","tries","conversions","penaltyGoals","drops","passes","kicks","turnovers" { do sums.%Set(key,sums.%Get(key,0)+p.stats.%Get(key,0)) }
            set score=score+p.stats.points
            do ..Assert((p.playedSeconds>=0)&&(p.playedSeconds<=m.clock)&&(p.stats.conversions<=p.stats.conversionAttempts),"Minutes and kick counters are bounded")
            do ##class(Rugby.Service.Store).Put("MatchPlayer",p)
        }
        for key="metres","tackles","tries","conversions","penaltyGoals","drops","passes","kicks","turnovers" { do ..Assert($zabs(sums.%Get(key)-team.%Get(key))<.000001,"Individual counters reconcile to team total: "_side_" "_key) }
        do ..Assert(score=m.%Get(side_"Score"),"Individual points reconcile to final score")
    }
    do ##class(Rugby.Service.MatchStatistics).Live(m,f),##class(Rugby.Service.Matches).Settle(m)
    do ..Assert(##class(Rugby.Service.Store).All("PlayerMatchStats").%Size()=count,"Settlement retries do not duplicate statistics")
    set pid=m.homePlayers.%Get(0).playerId,%RugbyQuery={"limit":1},history=##class(Rugby.Service.MatchStatistics).History(pid)
    do ..Assert((history.total=1)&&(history.items.%Size()=1)&&(history.summary.appearances=1),"History is paginated without duplicating snapshots")
    set p=##class(Rugby.Service.Store).Get("Player",pid),p.clubId="c3"
    do ##class(Rugby.Service.Store).Put("Player",p)
    set history=##class(Rugby.Service.MatchStatistics).History(pid)
    do ..Assert(history.items.%Get(0).clubId=m.homeId,"History retains the club represented after a transfer")
    set legacy=##class(%DynamicObject).%FromJSON(m.homePlayers.%Get(0).%ToJSON()),legacy.id="legacy-player",legacy.matchId="legacy-match",legacy.stats={"tries":1,"points":5}
    do legacy.%Remove("statsVersion")
    set old=##class(%DynamicObject).%FromJSON(m.%ToJSON()),old.id="legacy-match",old.fixtureId="legacy-fixture",lf=##class(%DynamicObject).%FromJSON(f.%ToJSON()),lf.id="legacy-fixture"
    do ##class(Rugby.Service.Store).Put("Match",old),##class(Rugby.Service.Store).Put("Fixture",lf),##class(Rugby.Service.Store).Put("MatchPlayer",legacy)
    set history=##class(Rugby.Service.MatchStatistics).History(pid),partial=0
    for i=0:1:history.items.%Size()-1 { set r=history.items.%Get(i) if r.source="legacy" { set partial=1 do ..Assert(('r.complete)&&('r.stats.%IsDefined("metres"))&&(r.stats.tries=1),"Legacy records retain known data without inventing metrics") } }
    // Read the second page as both fixtures have the same date.
    set %RugbyQuery={"offset":1,"limit":1},history=##class(Rugby.Service.MatchStatistics).History(pid),r=history.items.%Get(0)
    if r.source="legacy" set partial=1
    do ..Assert(partial&&(history.total=2)&&(history.summary.partialMatches=1),"History supports old matches and pagination")
    set c=##class(Rugby.Service.Store).Get("Club","c2"),af={"id":"statistics-ai","homeId":"c2","awayId":"c3","clubId":"c2","matchId":"","stage":"friendly","day":(c.day),"date":(c.date),"seed":593,"status":"scheduled"}
    do ##class(Rugby.Service.Competition).Simulate(af)
    set rows=##class(Rugby.Service.Store).All("PlayerMatchStats"),sums={"home":0,"away":0},found=0
    for i=0:1:rows.%Size()-1 { set r=rows.%Get(i) if r.fixtureId=af.id { set found=found+1 do sums.%Set(r.side,sums.%Get(r.side)+r.stats.points) do ..Assert(r.complete&&(r.source="aggregate"),"Automatic teams persist individual statistics") } }
    do ..Assert((found>0)&&(sums.home=af.homeScore)&&(sums.away=af.awayScore),"Automatic player scores reconcile with the fixture")
    do ..Assert('af.%IsDefined("statisticsPlayers"),"Temporary simulation attributes are not stored in fixtures")
}
}
