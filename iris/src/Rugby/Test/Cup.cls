Class Rugby.Test.Cup Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Complete(year As %Integer)
{
    do ##class(Rugby.Service.Cup).Ensure(year)
    for pass=1:1:4 {
        set fixtures=##class(Rugby.Service.Competition).Fixtures("cup-"_year)
        for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if f.status'="finished" do ##class(Rugby.Test.Competition).Result(f,f.homeId) }
        do ##class(Rugby.Service.Cup).Progress("cup-"_year)
    }
}
ClassMethod Run()
{
    set c=##class(Rugby.Service.Cup).View("cup-2026"),fixtures=c.regularFixtures,expected=["c19-c3","c13-c6","c1-c14","c18-c5","c11-c10","c8-c4","c16-c19","c6-c20","c9-c1","c5-c17","c10-c12","c4-c15","c3-c16","c20-c13","c14-c9","c17-c18","c12-c11","c15-c8"]
    do ..Assert((c.groups.%Size()=6)&&(fixtures.%Size()=18)&&(c.exemptTeamIds.%Get(0)="c7")&&(c.exemptTeamIds.%Get(1)="c2"),"Official six groups and two exempt champions")
    do ..Assert((c.groupDates.%ToJSON()=["2026-11-22","2026-11-29","2026-12-06"].%ToJSON())&&(c.quarterfinalDate="2027-01-10")&&(c.semifinalDates.%Get(0)="2027-02-07")&&(c.finalDate="2027-05-02"),"All first-edition dates match FER")
    kill home,away,seen
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i),index=((f.round-1)*6)+($ascii(f.groupId)-65)
        do ..Assert((f.homeId_"-"_f.awayId)=expected.%Get(index),"Official home-away pairings in every group and round")
        do ..Assert(f.date=c.groupDates.%Get(f.round-1),"Group rounds use official dates")
        set home(f.homeId)=$get(home(f.homeId))+1,away(f.awayId)=$get(away(f.awayId))+1,seen(f.homeId)=1,seen(f.awayId)=1
    }
    for i=0:1:c.groups.%Size()-1 { set group=c.groups.%Get(i) for j=0:1:2 { set cid=group.teamIds.%Get(j) do ..Assert((home(cid)=1)&&(away(cid)=1),"Each group participant plays once at home and once away") } }
    do ..Assert((c.quarterfinals.%Size()=0)&&(c.semifinals.%Size()=0)&&(c.final=""),"Knockout placeholders remain empty before qualification")
    for division=416,417 {
        set league=##class(Rugby.Service.Competition).Fixtures("league-"_division_"-2026")
        for i=0:1:league.%Size()-1 { do ..Assert('##class(Rugby.Service.Cup).Reserved(2026,league.%Get(i).date),"League weekends avoid all Cup rounds") }
    }
    set f=fixtures.%Get(0)
    do ##class(Rugby.Test.Competition).Result(f,f.homeId)
    set table=##class(Rugby.Service.Cup).Table(c,c.groups.%Get($ascii(f.groupId)-65)),points=##class(Rugby.Service.Competition).Classification(f)
    do ..Assert((table.%Get(0).played=1)&&(table.%Get(0).points=5)&&points.eligible,"Cup group tables apply rugby bonus points")
    set m={"stage":"cup-group","homeScore":10,"awayScore":10}
    do ##class(Rugby.Service.Matches).PlayoffWinner(m)
    do ..Assert('m.%IsDefined("winnerId"),"Group draws do not trigger a shootout")
    do ..Complete(2026)
    set c=##class(Rugby.Service.Cup).View(c.id)
    do ..Assert((c.phase="finished")&&(c.quarterfinals.%Size()=4)&&(c.semifinals.%Size()=2)&&$isobject(c.final)&&(c.championId'=""),"Group winners progress through all single-match rounds")
    do ..Assert(c.qualifiedTeamIds.%Size()=8,"Six group winners plus two exempt teams reach quarters")
    set frozen=##class(Rugby.Service.Competition).Fixtures(c.id).%ToJSON()
    do ##class(Rugby.Service.Cup).Ensure(2026),##class(Rugby.Service.Cup).Progress(c.id)
    do ..Assert(##class(Rugby.Service.Competition).Fixtures(c.id).%ToJSON()=frozen,"Re-running the draw and progression never duplicates or changes results")
    set league=##class(Rugby.Service.Store).Get("Competition","league-416-2026"),league.championId=c.championId
    do ##class(Rugby.Service.Store).Put("Competition",league)
    set next=##class(Rugby.Service.Cup).Exemptions(2027)
    do ..Assert((next.%Get(0)=c.championId)&&(next.%Get(1)=c.runnerUpId),"A double winner gives the second bye to the Cup runner-up")
    set league.championId=$select(c.championId="c3":"c4",1:"c3")
    do ##class(Rugby.Service.Store).Put("Competition",league)
    set next=##class(Rugby.Service.Cup).Exemptions(2027)
    do ..Assert((next.%Get(0)=c.championId)&&(next.%Get(1)=league.championId),"Next edition byes go to the actual previous Cup and Honor champions")
    tstart
    set club=##class(Rugby.Service.Store).Get("Club","c1"),club.date="2030-10-15",club.day=$zdateh(club.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",club)
    for division=416,417 { set league=##class(Rugby.Service.Competition).Draw(division,2030,17341+division) }
    set first=##class(Rugby.Service.Competition).Fixtures("league-416-2030").%Get(0)
    do ##class(Rugby.Test.Competition).Result(first,first.homeId)
    set first=##class(Rugby.Service.Store).Get("Fixture",first.id),saved=first.%ToJSON()
    set cup2030=##class(Rugby.Service.Store).Get("Competition","cup-2030"),fixtures2030=##class(Rugby.Service.Competition).Fixtures("league-416-2030"),partial=""
    for i=0:1:fixtures2030.%Size()-1 { set f=fixtures2030.%Get(i) if f.day>club.day { set partial=f quit } }
    do ##class(Rugby.Test.Competition).Result(partial,partial.homeId)
    set partial=##class(Rugby.Service.Store).Get("Fixture",partial.id),partialBefore=partial.%ToJSON(),changed=""
    for i=0:1:fixtures2030.%Size()-1 { set f=fixtures2030.%Get(i) if (f.round=partial.round)&&(f.id'=partial.id) { set changed=f quit } }
    set changed.date=cup2030.startDate,changed.day=$zdateh(changed.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Fixture",changed),##class(Rugby.Service.Cup).Recalendar(cup2030)
    do ..Assert(##class(Rugby.Service.Store).Get("Fixture",partial.id).%ToJSON()=partialBefore,"Recalculating a partially played round preserves its finished match")
    do ..Assert('##class(Rugby.Service.Cup).Reserved(2030,##class(Rugby.Service.Store).Get("Fixture",changed.id).date),"Pending games in a partially played round are moved off Cup weekends")
    set recalculated=##class(Rugby.Service.Competition).Fixtures("league-416-2030").%ToJSON()
    do ##class(Rugby.Service.Cup).Recalendar(cup2030)
    do ..Assert(##class(Rugby.Service.Competition).Fixtures("league-416-2030").%ToJSON()=recalculated,"Recalculating an already valid calendar is idempotent")
    do ..Assert(##class(Rugby.Service.Store).Get("Fixture",first.id).%ToJSON()=saved,"Adding Cup to an existing season preserves completed fixtures exactly")
    for division=416,417 {
        set league=##class(Rugby.Service.Competition).Fixtures("league-"_division_"-2030")
        for i=0:1:league.%Size()-1 { set f=league.%Get(i) if f.day>club.day do ..Assert('##class(Rugby.Service.Cup).Reserved(2030,f.date),"Future league fixtures are moved off reserved Cup weekends") }
    }
    trollback 1
    for year=2027:1:2035 {
        set dates=##class(Rugby.Service.Cup).Dates(year),h=$zdateh(dates.final,3)
        do ..Assert((((h+4)#7)=0)||(((h+4)#7)=6),"Future finals remain on weekends")
        do ..Assert($select(h>$zdateh((year+1)_"-05-02",3):h-$zdateh((year+1)_"-05-02",3),1:$zdateh((year+1)_"-05-02",3)-h)<=3,"Future editions stay near the original dates")
    }
    set m=##class(Rugby.Test.Suite).Build(433),m.stage="quarterfinal",m.homeScore=20,m.awayScore=20
    do ##class(Rugby.Service.Matches).PlayoffWinner(m)
    do ..Assert((m.homeShootout'=m.awayShootout)&&(m.winnerId'=""),"Live Cup quarterfinals resolve draws with a winner")
}
}
