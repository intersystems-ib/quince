Class Rugby.Test.ContractTerms Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    do ..Assert((##class(Rugby.Service.ContractTerms).Preferred(24,"a")>=2)&&(##class(Rugby.Service.ContractTerms).Preferred(24,"a")<=3),"Young players prefer two or three years")
    do ..Assert((##class(Rugby.Service.ContractTerms).Preferred(25)=5)&&(##class(Rugby.Service.ContractTerms).Preferred(32)=5)&&(##class(Rugby.Service.ContractTerms).Preferred(33)=1),"Preference boundaries follow age")
    for age=22,28,35 {
        tstart
        set c=##class(Rugby.Service.Store).Get("Club","c1"),pool=##class(Rugby.Service.Transfers).Market(),p=##class(Rugby.Service.Store).Get("Player",pool.%Get(0).id),p.birthDay=c.day-(age*365),p.age=age
        do ##class(Rugby.Service.Store).Put("Player",p)
        set n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"term-age-"_age),raw=##class(Rugby.Service.Store).Get("Negotiation",n.id),raw.reservationWage=10000,raw.askingWeeklyWage=15000,bad=$select(age=22:5,age=28:1,1:5)
        do ##class(Rugby.Service.Store).Put("Negotiation",raw)
        set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"weeklyWage":10000,"contractYears":(bad)},"term-unwanted-"_age)
        do ..Assert((n.status="counteroffer")&&(n.counterContractYears=##class(Rugby.Service.ContractTerms).Preferred(age,p.id)),"Same salary is insufficient for an unwanted term; counteroffer includes preferred years")
        set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":10000,"contractYears":(n.counterContractYears)},"term-preferred-"_age)
        do ..Assert(n.status="agreed","Changing duration alone can make the same salary acceptable")
        trollback 1
    }
    for kind="signing","renewal","promotion" {
        tstart
        set c=##class(Rugby.Service.Store).Get("Club","c1"),pool=##class(Rugby.Service.Transfers).Market(),p=##class(Rugby.Service.Store).Get("Player",$select(kind="signing":pool.%Get(0).id,kind="promotion":"c1-p24",1:"c1-p1")),p.signingFee=0
        do ##class(Rugby.Service.Store).Put("Player",p)
        set n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"counter-start-"_kind,kind),raw=##class(Rugby.Service.Store).Get("Negotiation",n.id),raw.reservationWage=10000,raw.askingWeeklyWage=10000
        do ##class(Rugby.Service.Store).Put("Negotiation",raw)
        set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"monthlyWage":500},"counter-low-"_kind),wage=n.counterWeeklyWage,years=n.counterContractYears,body={"version":(n.version),"acceptCounteroffer":true}
        do ..Assert(n.status="counteroffer","A low monthly offer yields a counteroffer for each negotiation kind")
        set accepted=##class(Rugby.Service.Transfers).Offer(n.id,body,"counter-accept-"_kind),retry=##class(Rugby.Service.Transfers).Offer(n.id,body,"counter-accept-"_kind)
        do ..Assert((accepted.status="agreed")&&(accepted.agreedWeeklyWage=wage)&&(accepted.agreedContractYears=years)&&(retry.%ToJSON()=accepted.%ToJSON()),"Accepting a counteroffer preserves exact salary and duration without monthly rounding, and is idempotent")
        set error=""
        try { set ignored=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(accepted.version),"acceptCounteroffer":true},"counter-twice-"_kind) } catch ex { set error=ex.Location }
        do ..Assert(error="NEGOTIATION_STATE","An already accepted counteroffer cannot be accepted again with a different request")
        set signed=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(accepted.version)},"counter-sign-"_kind),p=##class(Rugby.Service.Store).Get("Player",p.id)
        do ..Assert((signed.status="signed")&&(p.weeklyWage=wage)&&(p.contractYears=years),"Signing honours the accepted counteroffer for renewals, promotions and signings")
        trollback 1
    }
    for years=1:1:5 {
        tstart
        set pool=##class(Rugby.Service.Transfers).Market(),p=##class(Rugby.Service.Store).Get("Player",pool.%Get(0).id),p.signingFee=0
        do ##class(Rugby.Service.Store).Put("Player",p)
        set n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"term-sign-"_years),raw=##class(Rugby.Service.Store).Get("Negotiation",n.id),raw.reservationWage=100
        do ##class(Rugby.Service.Store).Put("Negotiation",raw)
        for bad=0,6,1.5,"3","" {
            set error=""
            try { set ignored=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"weeklyWage":1000,"contractYears":(bad)},"term-invalid-"_years_"-"_bad) } catch ex { set error=ex.Location }
            do ..Assert(error="CONTRACT_YEARS","Invalid terms are rejected without consuming an offer")
        }
        set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"weeklyWage":1000,"contractYears":(years)},"term-agree-"_years),again=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"weeklyWage":1000,"contractYears":(6-years)},"term-agree-"_years)
        do ..Assert((n.status="agreed")&&(n.agreedContractYears=years)&&(n.offers.%Get(0).offeredContractYears=years)&&(again.%ToJSON()=n.%ToJSON()),"Salary can compensate term preferences; history and retries preserve the original offer")
        set expected=n.contractEndDate,n=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version),"contractYears":(6-years)},"term-confirm-"_years),p=##class(Rugby.Service.Store).Get("Player",p.id),contract=##class(Rugby.Service.Store).Get("PlayerContract",n.contractId)
        do ..Assert((p.contractEndDate=expected)&&(p.contractYears=years)&&(contract.contractYears=years),"Signature persists agreed duration and expiry, ignoring changes in the confirmation body")
        trollback 1
    }
}
}
