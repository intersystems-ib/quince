Class Rugby.Test.FinancialPlanning Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id)
        if o.director.%Get("id")="" set o.director=o.candidates.%Get(1)
        set forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
        do ..Assert((forecast.requiredGrants=(forecast.unsubsidizedGap\2))&&(forecast.publicGrants=forecast.requiredGrants),"Forecast grants cover half of the former calculated funding gap for "_c.id)
        do ..Assert(forecast.publicGrants>=0,"Public support is never negative")
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),o=##class(Rugby.Service.Finance).Office(c.id),o.director=o.candidates.%Get(2),s=##class(Rugby.Service.Finance).Season(c),s.grants=[{"id":"legacy-paid","name":"Organismo público local","amount":1000000,"status":"paid"}],s.grantsComplete=1,c.date="2026-10-01",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do s.%Remove("financingModelVersion"),##class(Rugby.Service.Store).Put("FinancialOffice",o),##class(Rugby.Service.Store).Put("FinancialSeason",s),##class(Rugby.Service.Store).Put("Club",c)
    do ##class(Rugby.Service.Management).Money(c,1000000,"grant","Legacy grant","legacy-paid")
    set balance=c.balance,movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),result=##class(Rugby.Service.FinancialPlanning).Adopt(c,s,o)
    do ..Assert(('result.adjusted)&&(result.additionalGrant=0),"A legacy deficit does not create compensating public aid")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=balance)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=movements)&&(s.grants.%Get(0).status="paid"),"Adoption creates a future award without changing paid history")
    set count=##class(Rugby.Service.Store).All("FinancialAgreement").%Size(),again=##class(Rugby.Service.FinancialPlanning).Adopt(c,s,o)
    do ..Assert(('again.adjusted)&&(##class(Rugby.Service.Store).All("FinancialAgreement").%Size()=count),"Financing correction is idempotent")
    do ##class(Rugby.Service.Finance).Tick(c.id)
    set paid=##class(Rugby.Service.Store).Get("Club",c.id).balance
    do ##class(Rugby.Service.Finance).Tick(c.id)
    do ..Assert((paid=balance)&&(##class(Rugby.Service.Store).Get("Club",c.id).balance=paid),"No compensating grant is paid on repeated ticks")
    do ..Tickets()
}
ClassMethod Tickets()
{
    set c=##class(Rugby.Service.Store).Get("Club","c1"),c.date="2096-10-01",c.stadium={"capacity":200},s={"year":2096},f={"id":"forecast-gate-league","homeId":"c1","awayId":"c2","date":"2096-10-10","day":25500,"stage":"regular","status":"scheduled","ticketPrice":1200}
    do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Store).Put("Fixture",f)
    set estimate=##class(Rugby.Service.Finance).Forecast(f,-1,{"members":50}),plan=##class(Rugby.Service.FinancialPlanning).TicketForecast(c,s,50)
    do ..Assert((plan.remainingMatches=1)&&(plan.pending=estimate.ticketRevenue)&&(plan.averagePayingAttendees=estimate.attendance-50)&&(estimate.attendance<=200)&&(plan.averageTicketPrice=1200),"Gate forecast excludes season ticket holders, respects capacity and exposes mean price and attendance")
    set empty=##class(Rugby.Service.FinancialPlanning).TicketForecast(c,s,0)
    do ..Assert(empty.pending=plan.pending+(50*1200),"Season ticket holders are not counted twice as paying spectators")
    set f.id="forecast-gate-cup",f.stage="cup-group"
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set cup=##class(Rugby.Service.Finance).Forecast(f),f.id="forecast-gate-away",f.homeId="c2",f.awayId="c1",f.stage="regular"
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set f.id="forecast-gate-friendly",f.stage="friendly"
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set friendly=##class(Rugby.Service.Finance).Forecast(f),expected=plan.pending+cup.ticketRevenue+friendly.ticketRevenue-(friendly.ticketRevenue\2),plan=##class(Rugby.Service.FinancialPlanning).TicketForecast(c,s,50)
    do ..Assert((plan.remainingMatches=3)&&(plan.pending=expected),"Cup gates and the away friendly half-share count, ordinary away matches do not")
    set f=##class(Rugby.Service.Store).Get("Fixture","forecast-gate-league"),f.status="finished"
    do ##class(Rugby.Service.Store).Put("Fixture",f),##class(Rugby.Service.Management).Money(c,estimate.ticketRevenue,"tickets","Gate forecast test","forecast-gate-test")
    set settled=##class(Rugby.Service.FinancialPlanning).TicketForecast(c,s,50)
    do ..Assert((settled.received=estimate.ticketRevenue)&&(settled.total=plan.total)&&(settled.remainingMatches=2),"Finished match receipts replace their estimate without double counting")
    set f.id="forecast-gate-unassigned",f.status="scheduled",f.stage="final",f.awayId=""
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set f.id="forecast-gate-other-season",f.awayId="c2",f.date="2097-10-10"
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    do ..Assert(##class(Rugby.Service.FinancialPlanning).TicketForecast(c,s,50).%ToJSON()=settled.%ToJSON(),"Unassigned knockout ties and other seasons generate no forecast income")
}
}
