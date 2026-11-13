Class Rugby.Test.SeasonCalendar Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set year=##class(Rugby.Service.Seasons).Year(),close=##class(Rugby.Service.SeasonCalendar).CloseDay(year),open=##class(Rugby.Service.SeasonCalendar).Day((year+1)_"-09-01"),game=##class(Rugby.Service.Store).Game(),events=##class(Rugby.Service.SeasonCalendar).Events("c1"),seen={}
    for i=0:1:events.items.%Size()-1 { set e=events.items.%Get(i) do seen.%Set(e.id,e.date) }
    do ..Assert((seen.%Get("closure-"_year)=((year+1)_"-06-30"))&&(seen.%Get("opening-"_year)=(year_"-09-01")),"Separate opening and closure events use fixed season dates")
    set blocked=0
    try { set other=##class(Rugby.Service.SeasonCalendar).Events("c2") } catch ex { set blocked=ex.Location="CLUB_FORBIDDEN" }
    do ..Assert(blocked,"Season events respect managed club ownership")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+1),p.birthDay=close-(21*365)
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Test.Seasons).Complete(year)
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),c.day=close-1,c.date=##class(Rugby.Service.Injuries).Date(c.day)
        do ##class(Rugby.Service.Store).Put("Club",c)
        set state=##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"monthlyPayroll",c.id)),state.lastDay=close-2,state.wages=0,state.staffWages=0,state.financeWages=0,^RugbyWorld(game,"monthlyPayroll",c.id)=state.%ToJSON()
    }
    set early=##class(Rugby.Service.Seasons).Tick(close-1)
    do ..Assert('early.closed,"Completed competitions remain open through June twenty-ninth")
    set c=##class(Rugby.Service.Store).Get("Club","c1"),c=##class(Rugby.Service.Management).Advance("c1",{"version":(c.version)},"season-calendar-close")
    do ..Assert((c.date=((year+1)_"-06-30"))&&$data(^RugbyWorld(game,"seasonClosures",year)),"Daily advancement stops on June thirtieth and closes the season")
    set next=##class(Rugby.Service.Store).Get("Competition","league-416-"_(year+1))
    do ..Assert(next.seasonStartDate=((year+1)_"-09-01"),"Closure creates the following season before its opening")
    set blocked=0
    try { set ignored=##class(Rugby.Service.Calendar).Date("c1",(year+1)_"-07-15") } catch ex { set blocked=ex.Location="SUMMER_BREAK" }
    do ..Assert(blocked&&('##class(Rugby.Service.FriendlyRequests).FreeWeekend("c1",(year+1)_"-08-07")),"Summer friendlies and invitations are unavailable")
    do ##class(Rugby.Service.Store).Put("Fixture",{"id":"legacy-summer","homeId":"c1","awayId":"c2","day":(close+10),"date":(##class(Rugby.Service.Injuries).Date(close+10)),"stage":"friendly","status":"scheduled","matchId":""})
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.energy=20,p.morale=80,p.moraleLastDay=close,raw=p.attributes.%ToJSON()
    do ##class(Rugby.Service.Store).Put("Player",p)
    set version=c.version,c=##class(Rugby.Service.Management).Advance("c1",{"version":(version)},"season-calendar-open"),again=##class(Rugby.Service.Management).Advance("c1",{"version":(version)},"season-calendar-open")
    do ..Assert((c.date=((year+1)_"-09-01"))&&(again.%ToJSON()=c.%ToJSON()),"One idempotent advance skips both summer months and stops at opening")
    do ..Assert($data(^RugbyWorld(game,"seasonOpenings",year+1)),"Opening is recorded once")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1")
    do ..Assert((p.energy=100)&&(p.morale>=79)&&(p.attributes.%ToJSON()=raw),"Summer restores energy without training gains or two months of inactivity morale loss")
    do ..Assert('$isobject(##class(Rugby.Service.Store).Get("TrainingExecution","c1-day"_(close+10),0)),"Skipped dates create no training executions")
    set f=##class(Rugby.Service.Store).Get("Fixture","legacy-summer")
    do ..Assert(f.archived&&(f.status="cancelled"),"Legacy summer friendlies are cancelled without fabricated results")
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set team=clubs.%Get(i)
        do ..Assert(team.day=open,"All clubs reach the same opening date")
        for month="07","08" { do ..Assert($data(^RugbyWorld(game,"monthlyPaid",team.id,(year+1)_"-"_month)),"Both skipped months settle payroll for every club") }
    }
    set audit=##class(Rugby.Service.Store).Get("RivalExecution","rivals-day-"_open)
    do ..Assert((audit.summerBreak.skippedDays=62)&&audit.seasonOpening.opened,"Summer and opening details are retained in the daily interoperability audit")
}
}
