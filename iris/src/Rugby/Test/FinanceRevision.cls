Class Rugby.Test.FinanceRevision Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club"),names={},offers={},agreements=0
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),budget=##class(Rugby.Service.Finance).Budget(c)
        do ..Assert((budget>=25000000)&&(budget<=80000000),"Every club reference budget is 250,000–800,000 euros")
        set c.date="2026-09-28",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3),o=##class(Rugby.Service.Finance).Office(c.id),o.director=o.candidates.%Get(1)
        do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Store).Put("FinancialOffice",o),##class(Rugby.Service.Finance).Tick(c.id)
        set s=##class(Rugby.Service.Finance).Season(c),all=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id),principal=0,secondary=0,bar=0
        do ..Assert((s.offers.%Size()=14)&&s.barComplete,"All six sponsorships and bar concession have two offers")
        for j=0:1:all.%Size()-1 {
            set a=all.%Get(j)
            do ..Assert('names.%IsDefined(a.name),"Signed company names are unique across the league")
            do names.%Set(a.name,1)
            if a.category="principal" { set principal=principal+1 do ..Assert((a.annualAmount>=3000000)&&(a.annualAmount<=8000000),"Main sponsor stays in range") }
            elseif a.category="secondary" { set secondary=secondary+1 do ..Assert((a.annualAmount>=500000)&&(a.annualAmount<=1000000),"Secondary sponsor stays in range") }
            else { set bar=bar+1 do ..Assert((a.kind="barConcession")&&(a.annualAmount>=2500000)&&(a.annualAmount<=4500000),"Bar annual fee stays in range") }
            do ..Assert((a.years>=1)&&(a.years<=3),"One to three season agreement term")
        }
        for j=0:1:s.offers.%Size()-1 { set a=s.offers.%Get(j) do ..Assert('offers.%IsDefined(a.name),"Competing offers also use distinct company names") do offers.%Set(a.name,1) }
        do ..Assert((principal=1)&&(secondary=5)&&(bar=1),"One main sponsor, five secondary sponsors and one bar operator")
        set agreements=agreements+all.%Size()
    }
    do ..Assert(agreements=140,"All twenty clubs use the same financing rules")
    set c=##class(Rugby.Service.Store).Get("Club","c1"),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),o.director.quality=35,low=##class(Rugby.Service.Finance).Offer(c,s,o,1,1,.5),o.director.quality=90,high=##class(Rugby.Service.Finance).Offer(c,s,o,1,1,.5)
    do ..Assert((high.annualAmount>low.annualAmount)&&(high.name=low.name),"Director quality changes money without rerolling company identity")
    set weak=##class(Rugby.Service.Finance).Offer(c,s,o,7,1,0),strong=##class(Rugby.Service.Finance).Offer(c,s,o,7,1,1)
    do ..Assert(strong.annualAmount>weak.annualAmount,"Club success increases the bar concession value")
    set all=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id),bar=""
    for i=0:1:all.%Size()-1 { set a=all.%Get(i) if a.kind="barConcession" set bar=a }
    set before=##class(Rugby.Service.Store).All("FinancialMovement").%Size()
    do ##class(Rugby.Service.Finance).Tick(c.id)
    do ..Assert(##class(Rugby.Service.Store).All("FinancialMovement").%Size()=before,"Replaying a day never pays twice")
    for month=10,11,12,1,2,3,4,5,6 {
        set c.date=$select(month>=10:"2026",1:"2027")_"-"_$select(month<10:"0",1:"")_month_"-01",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
        do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Finance).Tick(c.id)
    }
    do ..Assert($get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"agreementPaid",bar.id,2026))=bar.annualAmount,"Ten instalments sum to the exact annual concession amount")
    set f={"id":"concession-match","homeId":"c1","awayId":"c2","date":(c.date),"stage":"friendly"},forecast=##class(Rugby.Service.Finance).Forecast(f)
    do ..Assert((forecast.barRevenue=0)&&(forecast.barCosts=0)&&(forecast.netRevenue=forecast.ticketRevenue),"Matches earn only tickets; bar is handled by concession")
    set forecast.barRevenue=999999,forecast.barCosts=123456,result=##class(Rugby.Service.Finance).Settle(f,forecast)
    do ..Assert((result.barRevenue=0)&&(result.barCosts=0)&&((result.homeShare+result.awayShare)=result.ticketRevenue),"Legacy live snapshots cannot reintroduce bar revenue or costs")
    set legacy={"id":"legacy-finance-test","clubId":"c1","slot":1,"name":"Old sponsor","annualAmount":50000000,"years":3,"startYear":2026,"endYear":2028,"status":"signed"}
    do ##class(Rugby.Service.Store).Put("FinancialAgreement",legacy),##class(Rugby.Service.Management).Money(c,8000000,"sponsorship","Already received",legacy.id_"-payment-2026-9")
    set balance=c.balance,ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),o=##class(Rugby.Service.Finance).Office(c.id),report=##class(Rugby.Service.Finance).Rebase(c,o),amended=##class(Rugby.Service.Store).Get("FinancialAgreement",legacy.id)
    do ..Assert((amended.annualAmount<=8000000)&&(amended.endYear=2028)&&(amended.previousAnnualAmount=50000000),"Migration reprices future obligations while preserving term and old amount")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=balance)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=ledger),"Migration never rewrites or reverses money already received")
}
}
