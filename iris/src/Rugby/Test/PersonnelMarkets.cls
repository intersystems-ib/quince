Class Rugby.Test.PersonnelMarkets Extends %RegisteredObject
{
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",report={"countries":2,"candidatesPerRole":3,"nameMigration":false}
    tstart
    try {
        for country="ES","FR" {
            set %RugbyManagedClub=$select(country="ES":"c1",1:"fr-clermont"),roles=##class(Rugby.Service.Staff).Roles(),names={}
            for i=0:1:roles.%Size()-1 {
                set role=roles.%Get(i).id,market=##class(Rugby.Service.Payroll).Market(role)
                do ##class(Rugby.Test.FrenchLeagues).Assert(market.%Size()=3,"Three candidates for each country and role")
                for j=0:1:market.%Size()-1 {
                    set p=market.%Get(j)
                    do ##class(Rugby.Test.FrenchLeagues).Assert(p.marketCountry=country,"Candidate belongs to the correct country")
                    do ##class(Rugby.Test.FrenchLeagues).Assert('names.%IsDefined(p.name),"Unique market identities")
                    do names.%Set(p.name,1)
                }
            }
            set office=##class(Rugby.Service.Finance).Office(%RugbyManagedClub)
            do ##class(Rugby.Test.FrenchLeagues).Assert(office.marketCountry=country,"Financial office country")
            for j=0:1:office.candidates.%Size()-1 { do ##class(Rugby.Test.FrenchLeagues).Assert(office.candidates.%Get(j).marketCountry=country,"Financial candidates belong to their country") }
        }
        set %RugbyManagedClub="c1",spanish=##class(Rugby.Service.Payroll).Market("academy"),candidate=spanish.%Get(0),%RugbyManagedClub="fr-clermont",before=##class(Rugby.Service.Staff).View(%RugbyManagedClub),blocked=0
        try { set rejected=##class(Rugby.Service.Staff).Assign(%RugbyManagedClub,candidate.id,"test-cross-country") } catch ex { set blocked=1 }
        do ##class(Rugby.Test.FrenchLeagues).Assert(blocked,"Cross-country coach recruitment rejected")
        do ##class(Rugby.Test.FrenchLeagues).Assert(##class(Rugby.Service.Staff).View(%RugbyManagedClub).version=before.version,"Rejected coach leaves staff unchanged")
        set french=##class(Rugby.Service.Payroll).Market("academy"),hired=##class(Rugby.Service.Staff).Assign(%RugbyManagedClub,french.%Get(0).id,"test-french-hire")
        do ##class(Rugby.Test.FrenchLeagues).Assert(##class(Rugby.Service.Payroll).Market("academy").%Size()=3,"French market replenished after hiring")
        set %RugbyManagedClub="c1",after=##class(Rugby.Service.Payroll).Market("academy")
        do ##class(Rugby.Test.FrenchLeagues).Assert(after.%Get(0).id=candidate.id,"French hire does not consume Spanish candidates")
        set office=##class(Rugby.Service.Finance).Office("c1"),foreign=office.candidates.%Get(0),foreign.marketCountry="FR"
        do ##class(Rugby.Service.Store).Put("FinancialOffice",office)
        set blocked=0
        try { set rejected=##class(Rugby.Service.Finance).Hire("c1",{"candidateId":(foreign.id),"version":(office.version)},"test-foreign-financier") } catch ex { set blocked=1 }
        do ##class(Rugby.Test.FrenchLeagues).Assert(blocked,"Cross-country financial director recruitment rejected")
        set players=##class(Rugby.Service.Store).All("Player","clubId","fr-clermont")
        for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.%Get("identitySource")="LNR" quit }
        set pid=p.id
        set p.name="A. TEST",p.identityNameVersion="",wage=p.weeklyWage,contract=p.contractEndDate,attributes=p.attributes.%ToJSON()
        do ##class(Rugby.Service.Store).Put("Player",p)
        kill ^RugbyWorld("template","frenchNamesVersion")
        set changed=##class(Rugby.Seed.FrenchNames).Apply(),p=##class(Rugby.Service.Store).Get("Player",pid)
        do ##class(Rugby.Test.FrenchLeagues).Assert((p.name'="A. TEST")&&(p.identityNameVersion'=""),"Official full name restored")
        do ##class(Rugby.Test.FrenchLeagues).Assert((p.weeklyWage=wage)&&(p.contractEndDate=contract)&&(p.attributes.%ToJSON()=attributes),"Name migration preserves wages, contracts and attributes")
        set report.nameMigration=1
        trollback
    } catch ex {
        if $tlevel trollback
        set %RugbyManagedClub="c1"
        throw ex
    }
    set %RugbyManagedClub="c1"
    quit report
}
}
