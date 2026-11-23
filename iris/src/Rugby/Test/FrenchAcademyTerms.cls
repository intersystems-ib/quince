Class Rugby.Test.FrenchAcademyTerms Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",report={"clubs":0,"players":0,"protectedContracts":false}
    tstart
    try {
        set clubs=##class(Rugby.Service.Store).All("Club"),spanish=##class(Rugby.Service.Store).All("Player","clubId","c4").%ToJSON()
        for i=0:1:clubs.%Size()-1 {
            set c=clubs.%Get(i)
            if '##class(Rugby.Service.Leagues).French(c.competitionId) continue
            set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),wages={},ends={},count=0
            for j=0:1:players.%Size()-1 { set p=players.%Get(j) if p.category="academy" { do wages.%Set(p.monthlyWage,1),ends.%Set(p.contractEndDate,1) set count=count+1 do ..Assert((p.contractYears>=1)&&(p.contractYears<=3)&&($extract(p.contractEndDate,6,10)="06-30"),"Academy contracts span one to three seasons ending in June") } }
            do ..Assert((wages.%Size()>5)&&(ends.%Size()>1),"Each French academy has varied salaries and expiry seasons")
            set report.clubs=report.clubs+1,report.players=report.players+count
        }
        set c=##class(Rugby.Service.Store).Get("Club","fr-clermont"),all=##class(Rugby.Service.Store).All("Player","clubId",c.id),before=0,protected=""
        for i=0:1:all.%Size()-1 {
            set p=all.%Get(i)
            if p.category'="academy" continue
            do p.%Remove("academyTermsVersion"),##class(Rugby.Service.Store).Put("Player",p)
            set before=before+p.monthlyWage
            if protected="" set protected=p.id
        }
        do c.%Remove("academyTermsVersion"),##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Store).Put("PlayerContract",{"id":"test-academy-renewal","clubId":(c.id),"playerId":(protected),"kind":"renewal"})
        set original=##class(Rugby.Service.Store).Get("Player",protected).%ToJSON(),ledger=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON(),changed=##class(Rugby.Service.FrenchAcademyTerms).Club(c),all=##class(Rugby.Service.Store).All("Player","clubId",c.id),after=0
        for i=0:1:all.%Size()-1 { set p=all.%Get(i) if p.category="academy" set after=after+p.monthlyWage }
        do ..Assert(before=after,"Salary variation preserves the academy's exact total monthly cost")
        do ..Assert(##class(Rugby.Service.Store).Get("Player",protected).%ToJSON()=original,"Negotiated contracts are unchanged")
        do ..Assert(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()=ledger,"No retroactive salary payments")
        do ..Assert(##class(Rugby.Service.FrenchAcademyTerms).Club(c)=0,"Salary and term variation is idempotent")
        set a=##class(Rugby.Service.YouthIntake).Build(c,2027,c.day,80,1,6,1),b=##class(Rugby.Service.YouthIntake).Build(c,2027,c.day,80,2,6,9)
        do ..Assert((a.academyTermsVersion'="")&&(b.academyTermsVersion'="")&&(a.monthlyWage'=b.monthlyWage),"Future youth intakes also have individual wages and terms")
        do ..Assert(##class(Rugby.Service.Store).All("Player","clubId","c4").%ToJSON()=spanish,"Spanish academy terms are unchanged")
        set report.protectedContracts=1
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit report
}
}
