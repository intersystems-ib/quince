Class Rugby.Service.FundingReduction Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Sponsor(a As %DynamicObject) As %Boolean
{
    if (a.%Get("fundingReductionVersion")=..#VERSION)||('$listfind($listbuild(2,3,4,5,6),a.%Get("slot",0))) quit 0
    set a.previousAnnualAmountBeforeReduction=a.annualAmount,a.annualAmount=+($justify(100000+((a.annualAmount-500000)*.8),0,0)),a.annualAmount=##class(Rugby.Simulation.Engine).Clamp(a.annualAmount,100000,500000),a.fundingReductionVersion=..#VERSION
    quit 1
}
ClassMethod Apply() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),agreements=##class(Rugby.Service.Store).All("FinancialAgreement"),seasons=##class(Rugby.Service.Store).All("FinancialSeason"),result={"gameId":(game),"agreements":0,"grants":0,"seasons":0}
    for i=0:1:agreements.%Size()-1 {
        set a=agreements.%Get(i),c=##class(Rugby.Service.Store).Get("Club",a.clubId),year=##class(Rugby.Service.Competition).Year(c.date)
        if a.endYear<year continue
        set changed=..Sponsor(a)
        if (a.%Get("kind")="grant")&&(a.%Get("fundingReductionVersion")'=..#VERSION) {
            set a.previousAnnualAmountBeforeReduction=a.annualAmount,a.annualAmount=a.annualAmount\2,a.fundingReductionVersion=..#VERSION,changed=1
        }
        if changed { do ##class(Rugby.Service.Store).Put("FinancialAgreement",a) set result.agreements=result.agreements+1 }
    }
    for i=0:1:seasons.%Size()-1 {
        set s=seasons.%Get(i),c=##class(Rugby.Service.Store).Get("Club",s.clubId),year=##class(Rugby.Service.Competition).Year(c.date)
        if s.year<year continue
        if s.%Get("fundingReductionVersion")=..#VERSION continue
        for j=0:1:s.offers.%Size()-1 { set changed=..Sponsor(s.offers.%Get(j)) }
        for j=0:1:s.grants.%Size()-1 {
            set grant=s.grants.%Get(j)
            if grant.%Get("fundingReductionVersion")=..#VERSION continue
            set grant.previousAmountBeforeReduction=grant.amount,grant.amount=grant.amount\2,grant.fundingReductionVersion=..#VERSION
            if grant.status="paid" set grant.paidAmount=grant.previousAmountBeforeReduction
            set result.grants=result.grants+1
        }
        set s.fundingReductionVersion=..#VERSION,s.financingModelVersion=##class(Rugby.Service.FinancialPlanning).#VERSION,s.financingPlan=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,##class(Rugby.Service.Finance).Office(c.id))
        do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
        set result.seasons=result.seasons+1
    }
    quit result
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Ajustando subvenciones y patrocinios.")
    try {
        tstart
        set games=["template"],gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do games.%Push(gid) }
        for g=0:1:games.%Size()-1 {
            set %RugbyGame=games.%Get(g),%RugbyManagedClub="c1"
            if %RugbyGame'="template" set %RugbyManagedClub=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)).clubId
            do reports.%Push(..Apply())
        }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
