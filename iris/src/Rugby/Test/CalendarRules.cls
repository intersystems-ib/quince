Class Rugby.Test.CalendarRules Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Blocked(club As %DynamicObject, key As %String)
{
    set caught=0,before=club.%ToJSON(),executions=##class(Rugby.Service.Store).All("TrainingExecution").%Size(),movements=##class(Rugby.Service.Store).All("FinancialMovement").%Size()
    try { set next=##class(Rugby.Service.Management).Advance(club.id,{"version":(club.version)},key) } catch ex { set caught=ex.Location="MATCH_PENDING" }
    do ..Assert(caught,"Pending match blocks advancing the management date")
    do ..Assert(##class(Rugby.Service.Store).Get("Club",club.id).%ToJSON()=before,"Blocked day preserves date, version and balance")
    do ..Assert((##class(Rugby.Service.Store).All("TrainingExecution").%Size()=executions)&&(##class(Rugby.Service.Store).All("FinancialMovement").%Size()=movements),"Blocked day does not train or charge wages")
}
ClassMethod Run()
{
    set c=##class(Rugby.Service.Store).Get("Club","c1"),f={"id":"calendar-pending","clubId":"c1","homeId":"c2","awayId":"c1","day":(c.day),"date":(c.date),"stage":"friendly","status":"scheduled","matchId":""}
    do ##class(Rugby.Service.Store).Put("Fixture",f),..Blocked(c,"blocked-today")
    // An archived fixture is ignored, and reaching the next match date remains allowed.
    do f.%Set("archived",1,"boolean"),##class(Rugby.Service.Store).Put("Fixture",f)
    set c=##class(Rugby.Service.Management).Advance("c1",{"version":(c.version)},"allowed-archived"),f={"id":"calendar-future","clubId":"c1","homeId":"c1","awayId":"c2","day":(c.day+1),"date":($zdate($zdateh(c.date,3)+1,3)),"stage":"regular","status":"scheduled","matchId":""}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set c=##class(Rugby.Service.Management).Advance("c1",{"version":(c.version)},"arrive-match-day")
    do ..Assert(c.day=f.day,"Can advance up to the day of a future league match"),..Blocked(c,"blocked-league")
    set retry=##class(Rugby.Service.Management).Advance("c1",{},"arrive-match-day")
    do ..Assert(retry.day=c.day,"Successful day retry stays idempotent on match day")
    set f.status="finished"
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set c=##class(Rugby.Service.Management).Advance("c1",{"version":(c.version)},"allowed-finished")
    set f.id="calendar-overdue",f.status="scheduled",f.day=c.day-2
    do ##class(Rugby.Service.Store).Put("Fixture",f),..Blocked(c,"blocked-overdue")
    // Full simulations verify variable receipts and the friendly equal split.
    for venue="home","away","league" {
        do ##class(Rugby.Test.Suite).Healthy()
        set f={"id":("income-"_venue),"clubId":"c1","homeId":($select(venue="away":"c2",1:"c1")),"awayId":($select(venue="away":"c1",1:"c2")),"day":(c.day),"date":(c.date),"stage":($select(venue="league":"regular",1:"friendly")),"status":"scheduled","matchId":""}
        do ##class(Rugby.Service.Store).Put("Fixture",f)
        set home=##class(Rugby.Service.Store).Get("Club",f.homeId),away=##class(Rugby.Service.Store).Get("Club",f.awayId),homeBefore=home.balance,awayBefore=away.balance
        set m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id),"seed":293},f.id),m=##class(Rugby.Service.Matches).Start(m.id)
        for n=1:1:300 { quit:m.status="finished"  if m.speed=0 set m.speed=20
            do ##class(Rugby.Simulation.Engine).Step(m) }
        do ..Assert(m.status="finished","Friendly and league simulation finish")
        do ##class(Rugby.Service.Store).Put("Match",m)
        set home=##class(Rugby.Service.Store).Get("Club",f.homeId),away=##class(Rugby.Service.Store).Get("Club",f.awayId),expectedHome=m.economy.homeShare,expectedAway=m.economy.awayShare-$select(venue="league":80000+(##class(Rugby.Service.Finance).Hash("travel-"_f.id)#70001),1:0)
        do ..Assert(((home.balance-homeBefore)=expectedHome)&&((away.balance-awayBefore)=expectedAway),"Both clubs receive the correct share for "_venue)
        do ##class(Rugby.Service.Matches).Settle(m)
        do ..Assert((##class(Rugby.Service.Store).Get("Club",f.homeId).balance=home.balance)&&(##class(Rugby.Service.Store).Get("Club",f.awayId).balance=away.balance),"Neither participant is paid twice")
        set movements=##class(Rugby.Service.Store).All("FinancialMovement","source","economy-"_f.id_"-ticketRevenue")
        do ..Assert(movements.%Size()=$select(venue="league":1,1:2),"Ledger has one movement per paid club")
    }
}
}
