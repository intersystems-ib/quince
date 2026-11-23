Class Rugby.Service.FrenchFunding Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod GrantName(c As %DynamicObject, year As %Integer, slot As %Integer) As %String
{
    set h=##class(Rugby.Service.Finance).Hash(c.id_"-grant-"_year_"-"_slot)
    if ##class(Rugby.Service.Leagues).French(c.competitionId) quit $select(slot=1:"Ville de ",1:$piece("Fonds public du sport de ,Agence territoriale du sport de ,Collectivité territoriale de ",",",1+(h#3)))_c.city
    quit $select(slot=1:"Ayuntamiento",1:$piece("Instituto público de deporte,Agencia pública de actividad física,Fundación pública deportiva",",",1+(h#3)))_" de "_c.city
}
ClassMethod GrantTotal(c As %DynamicObject, year As %Integer, quality As %Numeric, success As %Numeric) As %Integer
{
    set h=##class(Rugby.Service.Finance).Hash(c.id_"-institutional-"_year),score=##class(Rugby.Simulation.Engine).Clamp((quality*.0055)+(success*.35)+((h#101)*.001),0,1),low=$select(c.competitionId=1401:.03,1:.06),high=$select(c.competitionId=1401:.06,1:.10)
    quit (##class(Rugby.Service.Finance).Budget(c)*(low+((high-low)*score))\1000)*1000
}
ClassMethod Apply() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"agreements":0,"seasons":0}
    if $get(^RugbyWorld(game,"frenchFundingVersion"))=..#VERSION quit report
    set clubs=##class(Rugby.Service.Store).All("Club")
    for ci=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(ci)
        if '##class(Rugby.Service.Leagues).French(c.competitionId) continue
        set year=##class(Rugby.Service.Competition).Year(c.date),o=##class(Rugby.Service.Finance).Office(c.id),success=##class(Rugby.Service.Finance).Success(c),agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id)
        for i=0:1:agreements.%Size()-1 {
            set a=agreements.%Get(i)
            if (a.endYear<year)||(a.%Get("frenchFundingVersion")=..#VERSION) continue
            if a.%Get("kind")="grant" { set a.name=..GrantName(c,a.startYear,1) }
            else {
                set season={"year":(a.startYear)},office={"director":{"quality":(a.%Get("quality",o.director.%Get("quality",35)))}},terms=##class(Rugby.Service.Finance).OfferTerms(c,season,office,a.slot,1,success)
                set a.name=##class(Rugby.Service.Finance).Company(c,a.startYear,a.slot,1),a.annualAmount=terms.annualAmount
            }
            set a.frenchFundingVersion=..#VERSION,a.fundingReductionVersion=##class(Rugby.Service.FundingReduction).#VERSION
            do ##class(Rugby.Service.Store).Put("FinancialAgreement",a)
            set report.agreements=report.agreements+1
        }
        set seasons=##class(Rugby.Service.Store).All("FinancialSeason","clubId",c.id)
        for i=0:1:seasons.%Size()-1 {
            set s=seasons.%Get(i)
            if (s.year<year)||(s.%Get("frenchFundingVersion")=..#VERSION) continue
            for j=0:1:s.offers.%Size()-1 {
                set offer=s.offers.%Get(j),signed=##class(Rugby.Service.Store).Get("FinancialAgreement",offer.id,0)
                if $isobject(signed) { set offer.name=signed.name,offer.annualAmount=signed.annualAmount }
                else {
                    set option=+$piece(offer.id,"-",$length(offer.id,"-"))
                    if option<1 set option=1
                    set terms=##class(Rugby.Service.Finance).OfferTerms(c,s,o,offer.slot,option,success),offer.name=##class(Rugby.Service.Finance).Company(c,s.year,offer.slot,option),offer.annualAmount=terms.annualAmount
                }
                set offer.frenchFundingVersion=..#VERSION
            }
            set total=..GrantTotal(c,s.year,o.director.%Get("quality",35),success),paid=0,pending=0
            for j=0:1:s.grants.%Size()-1 { set g=s.grants.%Get(j) if g.status="paid" { set paid=paid+g.amount } else { set pending=pending+1 } }
            set remaining=$select(total>paid:total-paid,1:0)
            for j=0:1:s.grants.%Size()-1 {
                set g=s.grants.%Get(j),g.name=..GrantName(c,s.year,j+1)
                // Settled awards and their ledger entries retain their original amounts.
                if g.status'="paid" { set g.amount=$select(pending=1:remaining,1:##class(Rugby.Service.PublicGrants).Split(c.id,s.year,remaining)),remaining=remaining-g.amount,pending=pending-1 }
                set g.frenchFundingVersion=..#VERSION,g.fundingReductionVersion=##class(Rugby.Service.FundingReduction).#VERSION
            }
            set s.frenchFundingVersion=..#VERSION,s.financingPlan=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
            do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
            set report.seasons=report.seasons+1
        }
    }
    set ^RugbyWorld(game,"frenchFundingVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando patrocinios institucionales.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 {
            set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1"
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
