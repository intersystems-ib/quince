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
        do ..Assert(($zabs(forecast.marginPercent-forecast.targetMarginPercent)<.00001)&&(forecast.marginPercent>=-.251)&&(forecast.marginPercent<=3.001),"Forecast funding stays close to actual projected costs for "_c.id)
        do ..Assert(forecast.publicGrants>=0,"Public support is never negative")
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),o=##class(Rugby.Service.Finance).Office(c.id),o.director=o.candidates.%Get(2),s=##class(Rugby.Service.Finance).Season(c),s.grants=[{"id":"legacy-paid","name":"Organismo público local","amount":1000000,"status":"paid"}],s.grantsComplete=1,c.date="2026-10-01",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do s.%Remove("financingModelVersion"),##class(Rugby.Service.Store).Put("FinancialOffice",o),##class(Rugby.Service.Store).Put("FinancialSeason",s),##class(Rugby.Service.Store).Put("Club",c)
    do ##class(Rugby.Service.Management).Money(c,1000000,"grant","Legacy grant","legacy-paid")
    set balance=c.balance,movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),result=##class(Rugby.Service.FinancialPlanning).Adopt(c,s,o)
    do ..Assert(result.adjusted&&(result.additionalGrant>0),"A legacy season can receive a planned financing correction")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=balance)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=movements)&&(s.grants.%Get(0).status="paid"),"Adoption creates a future award without changing paid history")
    set count=##class(Rugby.Service.Store).All("FinancialAgreement").%Size(),again=##class(Rugby.Service.FinancialPlanning).Adopt(c,s,o)
    do ..Assert(('again.adjusted)&&(##class(Rugby.Service.Store).All("FinancialAgreement").%Size()=count),"Financing correction is idempotent")
    do ##class(Rugby.Service.Finance).Tick(c.id)
    set paid=##class(Rugby.Service.Store).Get("Club",c.id).balance
    do ##class(Rugby.Service.Finance).Tick(c.id)
    do ..Assert((paid>balance)&&(##class(Rugby.Service.Store).Get("Club",c.id).balance=paid),"Correction instalments are paid in future ticks once per month")
}
}
