Class Rugby.Service.FinancialPlanning Extends %RegisteredObject
{
Parameter VERSION = "2.0.0";
ClassMethod Forecast(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject) As %DynamicObject
{
    set payroll=##class(Rugby.Service.Payroll).Summary(c.id,0),managed=o.director.%Get("id")'="",quality=o.director.%Get("quality",35),success=##class(Rugby.Service.Finance).Success(c),agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id),slots={},private=0,bar=0
    for i=0:1:agreements.%Size()-1 { set a=agreements.%Get(i) if (a.startYear<=s.year)&&(a.endYear>=s.year)&&(a.slot>=1)&&(a.slot<=7) do slots.%Set(a.slot,a.annualAmount) }
    for slot=1:1:7 {
        set amount=slots.%Get(slot,0)
        if (amount=0)&&managed {
            set best=-1
            for option=1:1:2 { set terms=##class(Rugby.Service.Finance).OfferTerms(c,s,o,slot,option,success),score=terms.annualAmount*(1+((terms.years-1)*.015)) if score>best set best=score,amount=terms.annualAmount }
        }
        if slot=7 { set bar=amount } else { set private=private+amount }
    }
    set price=s.%Get("seasonTicketPrice",15000),members=s.%Get("members",0),campaign=s.%Get("campaignIncome",0)
    if ('s.%Get("campaignComplete",0))&&managed { set members=+$justify(##class(Rugby.Service.Finance).Budget(c)*.125*(.8+(quality*.004))/price,0,0),campaign=members*price }
    set tickets=0,movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id)
    for i=0:1:movements.%Size()-1 { set m=movements.%Get(i) if (m.type="tickets")&&(##class(Rugby.Service.Competition).Year(m.date)=s.year) set tickets=tickets+m.amount }
    set comp=##class(Rugby.Service.Store).Get("Competition","league-"_c.competitionId_"-"_s.year,0)
    if $isobject(comp) {
        set fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id),campaignForecast={"members":(members)}
        for i=0:1:fixtures.%Size()-1 {
            set f=fixtures.%Get(i)
            if (f.homeId'=c.id)||(f.stage'="regular")||(f.status="finished") continue
            set ticketPrice=1200
            if f.matchId'="" { set match=##class(Rugby.Service.Store).Get("Match",f.matchId,0) if $isobject(match) set ticketPrice=match.%Get("ticketPrice",1200) }
            set forecast=##class(Rugby.Service.Finance).Forecast(f,ticketPrice,campaignForecast),tickets=tickets+forecast.ticketRevenue
        }
    }
    set costs=payroll.annualProjectedCosts,targetFactor=.98+(quality*.0005),other=private+bar+campaign+tickets,needed=+$justify((costs*targetFactor)-other,0,0),unsubsidizedGap=$select(needed>0:needed,1:0),needed=unsubsidizedGap\2,grants=0
    for i=0:1:s.grants.%Size()-1 { set grants=grants+s.grants.%Get(i).amount }
    if ('s.%Get("grantsComplete",0))&&managed set grants=needed
    set income=other+grants
    quit {"modelVersion":(..#VERSION),"projectedCosts":(costs),"projectedIncome":(income),"projectedMargin":(income-costs),"marginPercent":($select(costs>0:(income-costs)*100/costs,1:0)),"targetMarginPercent":((targetFactor-1)*100),"privateSponsors":(private),"barConcession":(bar),"memberships":(campaign),"tickets":(tickets),"publicGrants":(grants),"requiredGrants":(needed),"unsubsidizedGap":(unsubsidizedGap),"grantFactor":0.5,"directorQuality":(quality),"provisional":('s.%Get("grantsComplete",0))}
}
ClassMethod Adopt(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject) As %DynamicObject
{
    set result={"clubId":(c.id),"adjusted":false,"additionalGrant":0}
    if (s.%Get("financingModelVersion")=..#VERSION)||('s.%Get("grantsComplete",0))||(o.director.%Get("id")="") quit result
    if c.%Get("seasonYear",s.year)>s.year quit result
    // Granted funding is fixed; a forecast deficit does not create a new award.
    set s.financingModelVersion=..#VERSION,s.financingPlan=..Forecast(c,s,o),result.plan=s.financingPlan
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
    quit result
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Revisando financiación de temporada.")
    try {
        tstart
        set games=["template"],gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do games.%Push(gid) }
        for g=0:1:games.%Size()-1 {
            set %RugbyGame=games.%Get(g)
            set %RugbyManagedClub="c1"
            if %RugbyGame'="template" { set game=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)),%RugbyManagedClub=game.clubId }
            set clubs=##class(Rugby.Service.Store).All("Club")
            for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i),s=##class(Rugby.Service.Store).Get("FinancialSeason",c.id_"-finance-"_##class(Rugby.Service.Competition).Year(c.date),0) if $isobject(s) do reports.%Push(..Adopt(c,s,##class(Rugby.Service.Finance).Office(c.id))) }
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
