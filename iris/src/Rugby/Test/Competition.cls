Class Rugby.Test.Competition Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String)
{
    do ##class(Rugby.Test.Suite).Assert(ok,message)
}
ClassMethod Schedule(comp As %DynamicObject)
{
    set fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id)
    do ..Assert(fixtures.%Size()=90,"Ten teams produce ninety regular fixtures")
    do ..Assert($isobject(##class(Rugby.Service.Store).Get("Competition","cup-"_comp.year,0)),"Cup is generated before a league draw")
    kill pair,round,venue,home,away
    set last=0
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i),h=$zdateh(f.date,3),dow=(h+4)#7
        do ..Assert((dow=0)||(dow=6),"All fixtures fall on Saturday or Sunday")
        do ..Assert((h>=$zdateh(comp.startDate,3))&&(h<=$zdateh(comp.endDate,3)),"Dates are within the requested season window")
        do ..Assert('##class(Rugby.Service.Cup).Reserved(comp.year,f.date),"A league draw excludes all Cup weekends immediately")
        do ..Assert(f.homeId'=f.awayId,"Teams never play themselves")
        do ..Assert('$data(pair(f.homeId,f.awayId)),"Each ordered home-away pairing occurs once")
        set pair(f.homeId,f.awayId)=1,home(f.homeId)=$get(home(f.homeId))+1,away(f.awayId)=$get(away(f.awayId))+1
        for side="home","away" {
            set cid=f.%Get(side_"Id")
            do ..Assert('$data(round(f.round,cid)),"One game per team per round")
            set round(f.round,cid)=1,venue(cid,f.round)=$select(side="home":"H",1:"A")
        }
        if h>last set last=h
    }
    for i=0:1:9 {
        set cid=comp.teamIds.%Get(i),sequence=""
        do ..Assert((home(cid)=9)&&(away(cid)=9),"Nine home and nine away games per team")
        for r=1:1:18 { set sequence=sequence_venue(cid,r) }
        do ..Assert((sequence'["HHH")&&(sequence'["AAA"),"Maximum venue streak is two")
        for j=0:1:9 { if i'=j do ..Assert($data(pair(cid,comp.teamIds.%Get(j)))>0,"Every rival visited exactly once") }
    }
    do ..Assert(last<$zdateh(comp.semifinalDates.%Get(0),3),"Regular season ends before semifinals")
    do ..Assert($zdateh(comp.semifinalDates.%Get(1),3)<$zdateh(comp.finalDate,3),"Final is after both semifinals")
    set again=##class(Rugby.Service.Competition).Draw(comp.divisionId,comp.year,999)
    do ..Assert(again.drawSeed=comp.drawSeed,"Existing draw survives retries with a new seed")
}
ClassMethod Result(f As %DynamicObject, winner As %String)
{
    set f.status="finished",f.winnerId=winner
    set f.homeScore=$select(winner=f.homeId:28,1:7),f.awayScore=$select(winner=f.awayId:28,1:7)
    set f.homeTries=$select(winner=f.homeId:4,1:1),f.awayTries=$select(winner=f.awayId:4,1:1)
    do ##class(Rugby.Service.Store).Put("Fixture",f)
}
ClassMethod Run()
{
    for division=416,417 {
        set comp=##class(Rugby.Service.Competition).Draw(division,2032,17341+division)
        do ..Schedule(comp)
    }
    set comp=##class(Rugby.Service.Competition).Draw(416,2033,76543),fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id),ranks={}
    for i=0:1:9 { do ranks.%Set(comp.teamIds.%Get(i),i+1) }
    do ..Assert(##class(Rugby.Service.Competition).View(comp.id).semifinals.%Size()=0,"No teams in bracket before regular season ends")
    for i=0:1:88 {
        set f=fixtures.%Get(i),winner=$select(ranks.%Get(f.homeId)<ranks.%Get(f.awayId):f.homeId,1:f.awayId)
        do ..Result(f,winner)
    }
    do ##class(Rugby.Service.Competition).Progress(comp.id)
    do ..Assert(##class(Rugby.Service.Store).Get("Competition",comp.id).phase="regular","Eighty-nine games cannot open playoffs")
    set f=fixtures.%Get(89)
    do ..Result(f,$select(ranks.%Get(f.homeId)<ranks.%Get(f.awayId):f.homeId,1:f.awayId))
    do ##class(Rugby.Service.Competition).Progress(comp.id)
    set table=##class(Rugby.Service.Competition).Table(comp)
    do ..Assert((table.%Get(0).clubId=comp.teamIds.%Get(0))&&(table.%Get(0).points=90),"Standings include wins and offensive bonus")
    for i=0:1:9 { do ..Assert(table.%Get(i).played=18,"Every club has eighteen recorded results") }
    set sf1=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-semifinal-1"),sf2=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-semifinal-2")
    do ..Assert((sf1.homeRank=1)&&(sf1.awayRank=4)&&(sf2.homeRank=2)&&(sf2.awayRank=3),"Semifinals are one versus four and two versus three")
    do ..Result(sf1,sf1.awayId),..Result(sf2,sf2.awayId)
    do ##class(Rugby.Service.Competition).Progress(comp.id)
    set final=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-final-1")
    do ..Assert((final.homeId=sf2.awayId)&&(final.homeRank=3)&&(final.awayRank=4),"Final hosted by better regular qualifier after two upsets")
    do ..Result(final,final.awayId)
    do ##class(Rugby.Service.Competition).Progress(comp.id)
    set ended=##class(Rugby.Service.Store).Get("Competition",comp.id)
    do ..Assert((ended.phase="finished")&&(ended.championId=final.awayId),"Final winner becomes persistent champion")
    set frozen=ended.%ToJSON()
    do ##class(Rugby.Service.Competition).Progress(comp.id)
    do ..Assert(##class(Rugby.Service.Store).Get("Competition",comp.id).%ToJSON()=frozen,"Playoff advancement is idempotent")
    // AI-only division can complete all rounds and playoffs as the management date advances.
    set c=##class(Rugby.Service.Store).Get("Club","c1"),year=##class(Rugby.Service.Competition).Year(c.date),elite=##class(Rugby.Service.Store).Get("Competition","league-417-"_year)
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),league=##class(Rugby.Service.Store).Get("Competition","league-416-"_year)
    set profile=##class(Rugby.Service.Development).Profile(p,c,##class(Rugby.Service.Store).Get("TrainingPlan","c1"),##class(Rugby.Service.Staff).Qualities("c1"))
    do ..Assert(profile.potentialDate=league.endDate,"Development forecast ends on the competition final date")
    // This fast-forward scenario must not carry future medical states into the next test.
    tstart
    do ##class(Rugby.Service.Competition).Sync($zdateh(elite.finalDate,3)-$zdateh("2026-11-07",3))
    set elite=##class(Rugby.Service.Store).Get("Competition",elite.id)
    do ..Assert((elite.phase="finished")&&(elite.championId'=""),"Elite AI fixtures progress through the final")
    trollback 1
    // The managed club's regular result comes from the full match engine.
    set fixtures=##class(Rugby.Service.Competition).ClubFixtures("c1"),own=""
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if (f.status="scheduled")&&(f.%Get("stage")="regular") { set own=f quit } }
    do ..Assert($isobject(own),"AI never consumes managed club's fixtures")
    set c.day=own.day,c.date=own.date
    do ##class(Rugby.Service.Store).Put("Club",c)
    set m=##class(Rugby.Service.Matches).Create({"fixtureId":(own.id)},"test-league-match"),m=##class(Rugby.Service.Matches).Start(m.id)
    set m=##class(Rugby.Test.Suite).Finish(m),f=##class(Rugby.Service.Store).Get("Fixture",own.id)
    do ..Assert((f.status="finished")&&(f.homeTries=m.homeStats.tries)&&(f.awayTries=m.awayStats.tries),"Live match result and tries feed standings")
    set m.stage="final",m.homeScore=20,m.awayScore=20
    do ##class(Rugby.Service.Matches).PlayoffWinner(m)
    do ..Assert((m.homeShootout'=m.awayShootout)&&(m.winnerId'=""),"Tied playoff has a deterministic winner without changing match score")
}
}
