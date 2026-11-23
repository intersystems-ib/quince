Class Rugby.Test.FrenchFunding Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",report={"clubs":0,"migration":false},names={}
    tstart
    try {
        set clubs=##class(Rugby.Service.Store).All("Club")
        for i=0:1:clubs.%Size()-1 {
            set c=clubs.%Get(i)
            if '##class(Rugby.Service.Leagues).French(c.competitionId) continue
            set budget=##class(Rugby.Service.Finance).Budget(c),s={"year":2026},o={"director":{"quality":65}},success=##class(Rugby.Service.Finance).Success(c)
            for slot=1:1:7 {
                set name=##class(Rugby.Service.Finance).Company(c,2026,slot,1),terms=##class(Rugby.Service.Finance).OfferTerms(c,s,o,slot,1,success),low=$select(slot=1:.12,slot=7:.01,1:.018),high=$select(slot=1:.20,slot=7:.015,1:.03)
                do ..Assert((terms.annualAmount>=((budget*low)-1))&&(terms.annualAmount<=((budget*high)+1)),"Sponsor scales with club budget")
                do ..Assert((name[c.city)&&('names.%IsDefined(name)),"Unique French sponsor with club locality")
                do ..Assert(name=##class(Rugby.Service.Finance).Company(c,2026,slot,1),"Sponsor is deterministic")
                do names.%Set(name,1)
            }
            set low=$select(c.competitionId=1401:.03,1:.06),high=$select(c.competitionId=1401:.06,1:.10),total=##class(Rugby.Service.FrenchFunding).GrantTotal(c,2026,65,success),first=##class(Rugby.Service.PublicGrants).Split(c.id,2026,total)
            do ..Assert((total>=((budget*low)-1000))&&(total<=(budget*high)),"Institutional sponsors use the division's budget range")
            do ..Assert((first'=total-first)&&((first+(total-first))=total),"Institutional sponsors have different amounts and preserve their total")
            do ..Assert(##class(Rugby.Service.FrenchFunding).GrantTotal(c,2026,90,.5)>##class(Rugby.Service.FrenchFunding).GrantTotal(c,2026,35,.5),"Financial director improves institutional funding")
            do ..Assert(##class(Rugby.Service.FrenchFunding).GrantName(c,2026,1)=("Ville de "_c.city),"French institutional name")
            set report.clubs=report.clubs+1
        }
        set c=##class(Rugby.Service.Store).Get("Club","fr-toulouse"),o=##class(Rugby.Service.Finance).Office(c.id),s=##class(Rugby.Service.Finance).Season(c),success=##class(Rugby.Service.Finance).Success(c),spanish=##class(Rugby.Service.Finance).Season(##class(Rugby.Service.Store).Get("Club","c1")).%ToJSON()
        set a=##class(Rugby.Service.Finance).Offer(c,s,o,2,1,success),a.id=s.id_"-agreement-2",a.name="Grupo Ejemplo",a.annualAmount=100000
        do ##class(Rugby.Service.Store).Put("FinancialAgreement",a)
        set start=a.startYear,finish=a.endYear
        set s.grants=[{"id":(s.id_"-grant-1"),"name":"Ayuntamiento de Toulouse","amount":1234500,"status":"paid"},{"id":(s.id_"-grant-2"),"name":"Instituto público de Toulouse","amount":1,"status":"awarded"}]
        do s.%Remove("frenchFundingVersion"),##class(Rugby.Service.Store).Put("FinancialSeason",s)
        do ##class(Rugby.Service.Management).Money(c,123400,"sponsorship","Paid sponsor",a.id_"-payment-2026-9")
        set ^RugbyWorld("template","agreementPaid",a.id,2026)=123400,cash=c.balance,ledger=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()
        kill ^RugbyWorld("template","frenchFundingVersion")
        set result=##class(Rugby.Service.FrenchFunding).Apply(),updated=##class(Rugby.Service.Store).Get("FinancialAgreement",a.id),s=##class(Rugby.Service.Finance).Season(c)
        do ..Assert((updated.name'="Grupo Ejemplo")&&(updated.annualAmount>100000),"Existing French sponsor is localized and scaled")
        do ..Assert((updated.startYear=start)&&(updated.endYear=finish),"Contract duration preserved")
        do ..Assert((s.grants.%Get(0).amount=1234500)&&(s.grants.%Get(1).amount>1),"Paid award is preserved and pending award recalculated")
        do ..Assert((s.grants.%Get(0).amount+s.grants.%Get(1).amount)=##class(Rugby.Service.FrenchFunding).GrantTotal(c,s.year,o.director.%Get("quality",35),success),"Pending institutional funding deducts amounts already collected")
        do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=cash)&&(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()=ledger),"Migration does not alter cash or settled movements")
        do ..Assert($get(^RugbyWorld("template","agreementPaid",a.id,2026))=123400,"Paid sponsor instalments are not reset")
        do ..Assert(##class(Rugby.Service.Finance).Season(##class(Rugby.Service.Store).Get("Club","c1")).%ToJSON()=spanish,"Spanish finances unchanged")
        set again=##class(Rugby.Service.FrenchFunding).Apply()
        do ..Assert((again.agreements=0)&&(again.seasons=0),"Migration is idempotent")
        set reduction=##class(Rugby.Service.FundingReduction).Apply()
        do ..Assert(##class(Rugby.Service.Store).Get("FinancialAgreement",a.id).annualAmount=updated.annualAmount,"Spanish funding reduction cannot cap French sponsors")
        set forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
        do ..Assert(forecast.requiredGrants=##class(Rugby.Service.FrenchFunding).GrantTotal(c,s.year,o.director.%Get("quality",35),success),"Forecast and institutional funding share the same rule")
        set c=##class(Rugby.Service.Store).Get("Club","fr-clermont"),c.date="2026-09-14",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date)
        do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Finance).Tick(c.id)
        set s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),total=0
        do ..Assert(s.grants.%Size()=2,"September generates two institutional sponsors")
        for i=0:1:s.grants.%Size()-1 { set g=s.grants.%Get(i),total=total+g.amount do ..Assert((g.status="paid")&&(g.name=##class(Rugby.Service.FrenchFunding).GrantName(c,s.year,i+1)),"Institutional sponsors are collected under French names") }
        do ..Assert(total=##class(Rugby.Service.FrenchFunding).GrantTotal(c,s.year,o.director.quality,##class(Rugby.Service.Finance).Success(c)),"September payment matches the forecast rule")
        set report.migration=1
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit report
}
}
