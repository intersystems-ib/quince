Class Rugby.Test.FrenchLeagues Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String)
{
    if 'ok throw ##class(%Exception.General).%New(message)
}
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",leagues=##class(Rugby.Service.Leagues).Ids(),report={"leagues":[],"players":0}
    do ..Assert(##class(Rugby.Service.Store).All("Club").%Size()=50,"Fifty clubs available")
    do ..Assert(##class(Rugby.Service.Store).Get("Competition","cup-2026").teamIds.%Size()=20,"Copa del Rey remains Spanish only")
    do ..Assert(##class(Rugby.Service.Competition).Points(20,26,1,1,1401).bonusDefensive=0,"French defensive bonus excludes six-point defeats")
    do ..Assert(##class(Rugby.Service.Competition).Points(20,25,1,1,1402).bonusDefensive=1,"Pro D2 defensive bonus includes five-point defeats")
    do ..Assert(##class(Rugby.Service.Competition).Points(20,27,1,1,416).bonusDefensive=1,"Spanish bonus remains seven points")
    for di=0:1:leagues.%Size()-1 {
        kill pair,round,venue
        set division=leagues.%Get(di),config=##class(Rugby.Service.Leagues).Config(division),comp=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-2026"),fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id)
        do ..Assert(fixtures.%Size()=config.regularMatches,"Correct fixture count "_division)
        for i=0:1:fixtures.%Size()-1 {
            set f=fixtures.%Get(i)
            do ..Assert('$data(pair(f.homeId,f.awayId)),"Ordered pair occurs only once")
            set pair(f.homeId,f.awayId)=1
            for side="home","away" { set cid=f.%Get(side_"Id") do ..Assert('$data(round(f.round,cid)),"One fixture per club and round") set round(f.round,cid)=1,venue(cid,f.round)=$select(side="home":"H",1:"A") }
            if '##class(Rugby.Service.Leagues).French(division) do ..Assert('##class(Rugby.Service.Cup).Reserved(2026,f.date),"Spanish cup has no league overlap")
        }
        for i=0:1:comp.teamIds.%Size()-1 { set cid=comp.teamIds.%Get(i),sequence="" for r=1:1:config.rounds { set sequence=sequence_venue(cid,r) } do ..Assert((sequence'["HHH")&&(sequence'["AAA"),"Maximum two consecutive home or away games") }
        do report.leagues.%Push({"id":(division),"teams":(comp.teamIds.%Size()),"fixtures":(fixtures.%Size())})
    }
    set clubs=##class(Rugby.Service.Store).All("Club"),fr=0,es=0,fn=0,en=0
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),players=##class(Rugby.Service.Store).All("Player","clubId",c.id),academy=0,salary=0
        for j=0:1:players.%Size()-1 { set p=players.%Get(j) if p.category="academy" { set academy=academy+1 continue } set average=##class(Rugby.Service.Development).Average(p),salary=salary+(##class(Rugby.Service.MonthlyPayroll).Value(p)*12) if c.competitionId=1401 { set fr=fr+average,fn=fn+1 } if c.competitionId=416 { set es=es+average,en=en+1 } }
        if ##class(Rugby.Service.Leagues).French(c.competitionId) { do ..Assert(academy>=20,"French academies are populated") if c.competitionId=1401 do ..Assert(salary<=c.regulatorySalaryCap,"Top 14 player payroll respects its cap") }
    }
    do ..Assert(fr/fn>(es/en)+20,"Top 14 is clearly above the Spanish league")
    set report.players=##class(Rugby.Service.Store).All("Player").%Size(),report.topAverage=fr/fn,report.honorAverage=es/en
    // Exercise the new six-team bracket without simulating or persisting historical games.
    tstart
    try {
        set comp=##class(Rugby.Service.Store).Get("Competition","league-1401-2026"),fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id)
        for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i),f.status="finished",f.homeScore=10,f.awayScore=0,f.homeTries=2,f.awayTries=0,f.winnerId=f.homeId do ##class(Rugby.Service.Store).Put("Fixture",f) }
        do ##class(Rugby.Service.Competition).Progress(comp.id)
        set comp=##class(Rugby.Service.Store).Get("Competition",comp.id),q1=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-quarterfinal-1"),q2=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-quarterfinal-2")
        do ..Assert((q1.homeId=comp.regularOrder.%Get(2))&&(q1.awayId=comp.regularOrder.%Get(5)),"Third hosts sixth")
        do ..Assert((q2.homeId=comp.regularOrder.%Get(3))&&(q2.awayId=comp.regularOrder.%Get(4)),"Fourth hosts fifth")
        do ..Assert('$isobject(##class(Rugby.Service.Store).Get("Fixture",comp.id_"-semifinal-1",0)),"Semifinals wait for qualifying winners")
        for q=q1,q2 { set q.status="finished",q.winnerId=q.homeId do ##class(Rugby.Service.Store).Put("Fixture",q) }
        do ##class(Rugby.Service.Competition).Progress(comp.id)
        set sf=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-semifinal-1")
        do ..Assert((sf.homeId=comp.regularOrder.%Get(0))&&(sf.awayId=q2.winnerId),"First seed faces fourth-fifth winner")
        set sf2=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-semifinal-2")
        for tie=sf,sf2 { set tie.status="finished",tie.winnerId=tie.homeId do ##class(Rugby.Service.Store).Put("Fixture",tie) }
        do ##class(Rugby.Service.Competition).Progress(comp.id)
        set final=##class(Rugby.Service.Store).Get("Fixture",comp.id_"-final-1"),final.status="finished",final.winnerId=final.homeId
        do ##class(Rugby.Service.Store).Put("Fixture",final),##class(Rugby.Service.Competition).Progress(comp.id)
        do ..Assert(##class(Rugby.Service.Store).Get("Competition",comp.id).championId=final.homeId,"Final determines the champion")
        set pro=##class(Rugby.Service.Store).Get("Competition","league-1402-2026"),pro.championId=pro.teamIds.%Get(0),pro.runnerUpId=pro.teamIds.%Get(1),old=pro.championId
        do ##class(Rugby.Service.Store).Put("Competition",pro)
        set access=##class(Rugby.Service.AccessMatch).Ensure(2026)
        do ..Assert((access.homeId=pro.runnerUpId)&&(access.awayId=comp.regularOrder.%Get(12)),"Pro D2 runner-up hosts thirteenth in Top 14")
        do ..Assert($zdateh(access.date,3)>$zdateh(comp.finalDate,3),"Access Match follows the finals")
        do ..Assert($zdateh(access.date,3)<$zdateh("2027-06-30",3),"Access Match precedes season closure")
        do ..Assert(##class(Rugby.Service.AccessMatch).Ensure(2026).id=access.id,"Access Match creation is idempotent")
        set %RugbyManagedClub=access.homeId
        set calendar=##class(Rugby.Service.Competition).ClubFixtures(access.homeId),found=0
        for ai=0:1:calendar.%Size()-1 { if calendar.%Get(ai).id=access.id set found=1 }
        do ..Assert(found,"Pro D2 participant sees the Access Match")
        set %RugbyManagedClub="c1",blocked=0
        try { set impossible=##class(Rugby.Service.Seasons).ExchangeFrance(2026,"2027-06-30") } catch pending { set blocked=1 }
        do ..Assert(blocked,"An unfinished Access Match blocks division exchange")
        tstart
        do ##class(Rugby.Service.AccessMatch).Sync(access.day)
        set simulated=##class(Rugby.Service.AccessMatch).Find(2026)
        do ..Assert((simulated.status="finished")&&(simulated.winnerId'=""),"Automatic Access Match runs even after Top 14 has finished")
        trollback 1
        tstart
        set access.status="finished",access.winnerId=access.awayId
        do ##class(Rugby.Service.Store).Put("Fixture",access)
        set retained=##class(Rugby.Service.Seasons).ExchangeFrance(2026,"2027-06-30")
        do ..Assert((retained.promotedClubIds.%Size()=1)&&(##class(Rugby.Service.Store).Get("Club",access.awayId).competitionId=1401),"Top 14 winner retains its place")
        trollback 1
        set access=##class(Rugby.Service.AccessMatch).Find(2026),access.status="finished",access.winnerId=access.homeId
        do ##class(Rugby.Service.Store).Put("Fixture",access)
        set exchange=##class(Rugby.Service.Seasons).ExchangeFrance(2026,"2027-06-30")
        do ..Assert(##class(Rugby.Service.Store).Get("Club",old).competitionId=1401,"Pro D2 champion moves to Top 14")
        do ..Assert(##class(Rugby.Service.Store).Get("Club",access.homeId).competitionId=1401,"Access home winner is promoted")
        do ..Assert(##class(Rugby.Service.Store).Get("Club",access.awayId).competitionId=1402,"Access away loser is relegated")
        do ##class(Rugby.Service.Competition).Ensure(2027)
        do ..Assert(##class(Rugby.Service.Store).Get("Competition","league-1401-2027").teamIds.%Size()=14,"Next Top 14 retains fourteen clubs")
        do ..Assert(##class(Rugby.Service.Store).Get("Competition","league-1402-2027").teamIds.%Size()=16,"Next Pro D2 retains sixteen clubs")
        do ..Assert(##class(Rugby.Service.Store).Get("Competition","cup-2027").teamIds.%Size()=20,"Next Spanish cup excludes French clubs")
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit report
}
}
