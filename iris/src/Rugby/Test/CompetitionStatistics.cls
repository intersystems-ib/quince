Class Rugby.Test.CompetitionStatistics Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set %RugbyGame="template",%RugbyManagedClub="c1",comp="league-416-2026",base=##class(Rugby.Service.Competition).Fixtures(comp).%Get(0),f=##class(%DynamicObject).%FromJSON(base.%ToJSON()),f.id="leaderboard-regular",f.status="finished",f.day=100
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    for n=1:1:12 {
        set p=##class(Rugby.Service.Store).Get("Player",f.homeId_"-p"_n),snapshot={"playerId":(p.id),"name":(p.name),"side":"home","position":(p.position),"playedSeconds":4800,"stats":{"metres":(n*10),"tries":(n),"tackles":(n),"points":(n*5)},"statsVersion":"1.0.0"},e=##class(Rugby.Service.MatchStatistics).Entry(snapshot,f)
        do ##class(Rugby.Service.Store).Put("PlayerMatchStats",e)
    }
    set top=##class(Rugby.Service.CompetitionStatistics).Top(comp),tries=top.metrics.%Get(1),first=tries.leaders.%Get(0),pid=first.playerId
    do ..Assert((top.players=12)&&(tries.leaders.%Size()=10)&&(first.value=12)&&(first.rank=1),"Each metric returns at most ten players sorted by cumulative total")
    set before=top.%ToJSON(),e=##class(Rugby.Service.Store).Get("PlayerMatchStats",f.id_"-"_pid)
    do ##class(Rugby.Service.Store).Put("PlayerMatchStats",e)
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).%ToJSON()=before,"Saving a statistics record twice never duplicates the analytical projection")
    set final=##class(%DynamicObject).%FromJSON(f.%ToJSON()),final.id="leaderboard-final",final.stage="final",final.day=110,final.homeId=f.awayId
    do ##class(Rugby.Service.Store).Put("Fixture",final)
    set snapshot.playerId=pid,snapshot.name=first.name,snapshot.stats={"tries":3,"points":15},snapshot.playedSeconds=1200,e=##class(Rugby.Service.MatchStatistics).Entry(snapshot,final)
    do ##class(Rugby.Service.Store).Put("PlayerMatchStats",e)
    set top=##class(Rugby.Service.CompetitionStatistics).Top(comp),leader=top.metrics.%Get(1).leaders.%Get(0)
    do ..Assert((leader.value=15)&&(leader.appearances=2)&&(leader.clubId=final.homeId),"Finals count and transferred players remain a single entry with their latest participating club")
    set cup=##class(%DynamicObject).%FromJSON(final.%ToJSON()),cup.id="leaderboard-cup",cup.competitionKey="cup-2026"
    do ##class(Rugby.Service.Store).Put("Fixture",cup)
    set snapshot.stats.tries=100,e=##class(Rugby.Service.MatchStatistics).Entry(snapshot,cup)
    do ##class(Rugby.Service.Store).Put("PlayerMatchStats",e)
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).metrics.%Get(1).leaders.%Get(0).value=15,"Cup performances never leak into league leaderboards")
    set snapshot.playedSeconds=0,snapshot.playerId=f.awayId_"-p2",snapshot.stats.tries=999,e=##class(Rugby.Service.MatchStatistics).Entry(snapshot,final)
    do ##class(Rugby.Service.Store).Put("PlayerMatchStats",e)
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).players=12,"Unused substitutes are not ranked as match participants")
    // Incorrect denormalized keys must never leak between any of the four leagues.
    for division=417,1401,1402 {
        set otherComp="league-"_division_"-2026",opponents=##class(Rugby.Service.Competition).Fixtures(otherComp),foreign=##class(%DynamicObject).%FromJSON(opponents.%Get(0).%ToJSON())
        set foreign.id="leaderboard-isolation-"_division,foreign.status="finished"
        do ##class(Rugby.Service.Store).Put("Fixture",foreign)
        set lineup=##class(Rugby.Service.Store).Get("Lineup",foreign.homeId_"-default"),p=##class(Rugby.Service.Store).Get("Player",lineup.slots.%Get(0).playerId)
        set player={"playerId":(p.id),"name":(p.name),"side":"home","position":(p.position),"playedSeconds":4800,"stats":{"tries":500,"points":2500},"statsVersion":"1.0.0"},entry=##class(Rugby.Service.MatchStatistics).Entry(player,foreign),entry.competitionKey=comp
        do ##class(Rugby.Service.Store).Put("PlayerMatchStats",entry)
        do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).metrics.%Get(1).leaders.%Get(0).value=15,"A wrong record key cannot move foreign league statistics into Honor")
        set isolated=##class(Rugby.Service.CompetitionStatistics).Top(otherComp)
        do ..Assert((isolated.players=1)&&(isolated.metrics.%Get(1).leaders.%Get(0).playerId=p.id),"Statistics follow their source fixture in each league")
    }
    set friendly=##class(%DynamicObject).%FromJSON(foreign.%ToJSON()),friendly.id="leaderboard-friendly",friendly.competitionKey="",friendly.stage="friendly"
    do ##class(Rugby.Service.Store).Put("Fixture",friendly)
    set entry=##class(Rugby.Service.MatchStatistics).Entry(player,friendly),entry.competitionKey=comp
    do ##class(Rugby.Service.Store).Put("PlayerMatchStats",entry)
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).metrics.%Get(1).leaders.%Get(0).value=15,"A friendly never enters a league through a stale statistics key")
    // Simulate a stale analytical row already deployed with the wrong competition.
    set row=##class(Rugby.Analytics.PlayerMatch).RecordKeyIndexOpen("template|leaderboard-isolation-1402-"_p.id),row.CompetitionId=comp,sc=row.%Save()
    do ..Assert('$system.Status.IsError(sc),"Corrupted projection test row saved")
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).metrics.%Get(1).leaders.%Get(0).value=15,"Foreign participating clubs are excluded even before projection repair")
    set before=##class(Rugby.Service.CompetitionStatistics).Top(comp).%ToJSON()
    do ##class(Rugby.Service.CompetitionStatistics).RemoveGame("template")
    kill ^RugbySchema("competitionStatisticsVersion")
    do ##class(Rugby.Service.CompetitionStatistics).Initialize()
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).%ToJSON()=before,"Migration rebuilds existing statistics without modifying match history")
    set repaired=##class(Rugby.Service.CompetitionStatistics).Top("league-1402-2026")
    do ..Assert((repaired.players=1)&&(repaired.metrics.%Get(1).leaders.%Get(0).value=500),"Migration restores a mislabelled French performance to its original league")
    set %RugbyGame="statistics-other"
    do ##class(Rugby.Service.Store).Put("Competition",{"id":"league-416-2026","season":"2026/2027","teamIds":["c1","c2"]})
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).players=0,"A different save never sees another save's statistics")
    set %RugbyGame="template"
    do ##class(Rugby.Service.CompetitionStatistics).RemoveGame("template")
    do ..Assert(##class(Rugby.Service.CompetitionStatistics).Top(comp).players=0,"Deleting a game's analytical data removes all its leaderboards")
}
}
