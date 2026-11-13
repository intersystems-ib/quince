Class Rugby.Test.FundingReduction Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set c=##class(Rugby.Service.Store).Get("Club","c1"),o=##class(Rugby.Service.Finance).Office(c.id),s=##class(Rugby.Service.Finance).Season(c),o.director=o.candidates.%Get(2),success=##class(Rugby.Service.Finance).Success(c)
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    for slot=2:1:6 {
        for quality=0,35,90,100 { set o.director.quality=quality,terms=##class(Rugby.Service.Finance).OfferTerms(c,s,o,slot,1,success) do ..Assert((terms.annualAmount>=100000)&&(terms.annualAmount<=500000),"Secondary offers stay between 1,000 and 5,000 euros") }
    }
    set forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
    do ..Assert(forecast.requiredGrants=(forecast.unsubsidizedGap\2),"New public funding is exactly half the former calculation")
    set secondary={"id":"reduction-secondary","clubId":"c1","slot":2,"category":"secondary","kind":"sponsorship","name":"Sponsor legacy","annualAmount":750000,"startYear":2026,"endYear":2028,"years":3},grantAgreement={"id":"reduction-grant-instalments","clubId":"c1","slot":0,"kind":"grant","annualAmount":1000000,"startYear":2026,"endYear":2026,"years":1}
    do ##class(Rugby.Service.Store).Put("FinancialAgreement",secondary),##class(Rugby.Service.Store).Put("FinancialAgreement",grantAgreement)
    set s.offers=[{"id":"old-offer","slot":2,"annualAmount":750000}],s.grants=[{"id":"old-paid-grant","name":"Organismo A","amount":2000000,"status":"paid"},{"id":"reduction-grant-instalments","name":"Organismo B","amount":1000000,"status":"instalments"}],s.grantsComplete=1
    do s.%Remove("fundingReductionVersion"),##class(Rugby.Service.Store).Put("FinancialSeason",s),##class(Rugby.Service.Management).Money(c,2000000,"grant","Already received","old-paid-grant")
    set balance=c.balance,ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),wages=##class(Rugby.Service.MonthlyPayroll).PlayerTotal(c.id),result=##class(Rugby.Service.FundingReduction).Apply(),s=##class(Rugby.Service.Finance).Season(c),a=##class(Rugby.Service.Store).Get("FinancialAgreement",secondary.id),g=##class(Rugby.Service.Store).Get("FinancialAgreement",grantAgreement.id)
    do ..Assert((s.grants.%Get(0).amount=1000000)&&(s.grants.%Get(1).amount=500000)&&(g.annualAmount=500000),"Existing direct grants and grant instalment agreements are halved")
    do ..Assert((a.annualAmount=300000)&&(a.endYear=2028)&&(a.name=secondary.name)&&(s.offers.%Get(0).annualAmount=300000),"Existing secondary agreements and offers are repriced without changing name or term")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=balance)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=ledger)&&(##class(Rugby.Service.MonthlyPayroll).PlayerTotal(c.id)=wages),"Already received cash, its ledger and player wages are preserved")
    set snapshot=##class(Rugby.Service.Store).All("FinancialSeason").%ToJSON(),agreements=##class(Rugby.Service.Store).All("FinancialAgreement").%ToJSON(),again=##class(Rugby.Service.FundingReduction).Apply()
    do ..Assert((again.grants=0)&&(again.agreements=0)&&(snapshot=##class(Rugby.Service.Store).All("FinancialSeason").%ToJSON())&&(agreements=##class(Rugby.Service.Store).All("FinancialAgreement").%ToJSON()),"Repeated startup cannot halve funding twice")
    set count=##class(Rugby.Service.Store).All("FinancialAgreement").%Size()
    do s.%Remove("financingModelVersion")
    set adopted=##class(Rugby.Service.FinancialPlanning).Adopt(c,s,o)
    do ..Assert(('adopted.adjusted)&&(##class(Rugby.Service.Store).All("FinancialAgreement").%Size()=count),"Forecast adoption cannot undo the cut with another public award")
}
}
