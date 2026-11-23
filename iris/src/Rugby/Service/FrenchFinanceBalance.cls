Class Rugby.Service.FrenchFinanceBalance Extends %RegisteredObject
{
Parameter VERSION = "1.2.0";
ClassMethod TargetMargin(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject) As %Numeric
{
    set quality=$select(o.director.%Get("id")="":65,1:o.director.%Get("quality",65)),quality=##class(Rugby.Simulation.Engine).Clamp(quality,0,100),h=##class(Rugby.Service.Rivals).Hash("operating-margin-"_c.id_"-"_s.year,##class(Rugby.Service.Rivals).Seed()),variation=((h#301)-150)/100000
    quit ##class(Rugby.Simulation.Engine).Clamp(.007+(quality*.0002)+variation,.005,.03)
}
ClassMethod FundingWindow(c As %DynamicObject, s As %DynamicObject) As %Boolean
{
    quit +$piece(c.date,"-",2)=9
}
ClassMethod Wages(c As %DynamicObject, totals As %DynamicObject) As %DynamicObject
{
    set year=##class(Rugby.Service.Competition).Year(c.date),start=year_"-09-01",end=(year+1)_"-09-01",startH=$zdateh(start,3),endH=$zdateh(end,3),paid={"wages":0,"staffWages":0,"financeWages":0,"registration":0,"travel":0},rows=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id)
    for i=0:1:rows.%Size()-1 { set m=rows.%Get(i),dateH=$zdateh(m.date,3) if (dateH>=startH)&&(dateH<endH)&&paid.%IsDefined(m.type)&&(m.amount<0) do paid.%Set(m.type,paid.%Get(m.type)-m.amount) }
    set state=##class(%DynamicObject).%FromJSON($get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"monthlyPayroll",c.id),"{}")),first=$select(c.%Get("startDay",c.day)>##class(Rugby.Service.SeasonCalendar).Day(start):c.%Get("startDay",c.day),1:##class(Rugby.Service.SeasonCalendar).Day(start)),next=state.%Get("lastDay",first-1)+1,months=0,activeMonths=0,last=##class(Rugby.Service.SeasonCalendar).Day(end)-1
    if next<first set next=first
    set day=first
    for {
        quit:day>last
        set date=##class(Rugby.Service.Injuries).Date(day),days=##class(Rugby.Service.MonthlyPayroll).Days(date),monthEnd=day+days-(+$piece(date,"-",3)),monthEnd=$select(monthEnd>last:last,1:monthEnd),activeMonths=activeMonths+((monthEnd-day+1)/days),future=$select(next>day:next,1:day)
        if future<=monthEnd set months=months+((monthEnd-future+1)/days)
        set day=monthEnd+1
    }
    set players=paid.wages+state.%Get("wages",0)+(totals.players*months),staff=paid.staffWages+state.%Get("staffWages",0)+(totals.staff*months),director=paid.financeWages+state.%Get("financeWages",0)+(totals.director*months),registration=$select(first>##class(Rugby.Service.SeasonCalendar).Day(year_"-09-30"):paid.registration,1:##class(Rugby.Service.Finance).Budget(c)*.03),travel=1650000*activeMonths/12
    if travel<paid.travel set travel=paid.travel
    if registration<paid.registration set registration=paid.registration
    quit {"players":(+$justify(players,0,0)),"staff":(+$justify(staff,0,0)),"director":(+$justify(director,0,0)),"registration":(+$justify(registration,0,0)),"travel":(+$justify(travel,0,0)),"remainingMonths":(months),"activeMonths":(activeMonths)}
}
ClassMethod Plan(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject, p As %DynamicObject, coreCosts As %Numeric, coreIncome As %Numeric) As %DynamicObject
{
    if p.%Get("frenchBalanceVersion")=..#VERSION quit p
    if o.director.%Get("id")="" {
        set office=##class(%DynamicObject).%FromJSON(o.%ToJSON()),office.director={"id":"planning-reference","quality":65},standard=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,office,0),coreIncome=standard.projectedIncome,wages=..Wages(c,##class(Rugby.Service.MonthlyPayroll).Totals(c.id)),coreCosts=standard.projectedCosts+(##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(65,c.id)*wages.remainingMonths)
    }
    set paid={"socialMembers":0,"otherIncome":0,"communityCosts":0},rows=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id),prefix=s.id_"-community-"
    for i=0:1:rows.%Size()-1 { set m=rows.%Get(i) if ($extract(m.source,1,$length(prefix))=prefix)&&paid.%IsDefined(m.type) do paid.%Set(m.type,paid.%Get(m.type)+$select(m.amount<0:-m.amount,1:m.amount)) }
    set month=+$piece(c.date,"-",2),first=$select(month>=9:month-9,month<=6:month+3,1:10),day=+$piece(c.date,"-",3)
    if day>21 set first=first+1
    if day=21 { set any=0 for type="socialMembers","otherIncome","communityCosts" { if $isobject(##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-"_s.id_"-community-"_type_"-"_month,0)) set any=1 } if any set first=first+1 }
    if first<p.firstInstalment set first=p.firstInstalment
    if first>10 set first=10
    set margin=..TargetMargin(c,s,o),count=10-first,members=paid.socialMembers+(p.annualMembersIncome*count/10),costs=paid.communityCosts+(p.annualCosts*count/10),target=(coreCosts+costs)/(1-margin),budget=##class(Rugby.Service.Finance).Budget(c)
    if c.%Get("startDay",c.day)>##class(Rugby.Service.SeasonCalendar).Day(s.year_"-09-01") set period=..Wages(c,##class(Rugby.Service.MonthlyPayroll).Totals(c.id)),budget=budget*period.activeMonths/12
    if target>budget set target=budget
    set remaining=+$justify(target-coreIncome-members-paid.otherIncome,0,0)
    if (remaining<0)||(count=0) set remaining=0
    set share=$select(p.annualOtherIncome>0:p.annualYouthFees/p.annualOtherIncome,1:.65),p.frenchBalanceVersion=..#VERSION,p.balanceAdoptedOn=c.date,p.balanceFirstIndex=first,p.balanceInstalments=count,p.remainingOtherIncome=remaining,p.plannedMembersIncome=+$justify(members,0,0),p.plannedOtherIncome=paid.otherIncome+remaining,p.plannedCosts=+$justify(costs,0,0),p.annualOtherIncome=$select(count>0:+$justify(remaining*10/count,0,0),1:paid.otherIncome),p.annualYouthFees=+$justify(p.annualOtherIncome*share,0,0),p.annualActivitiesIncome=p.annualOtherIncome-p.annualYouthFees,p.targetOperatingMarginPercent=margin*100
    quit p
}
ClassMethod Payment(p As %DynamicObject, index As %Integer) As %Integer
{
    set offset=index-p.balanceFirstIndex,count=p.balanceInstalments
    if (count<=0)||(offset<0)||(offset>=count) quit 0
    quit ((p.remainingOtherIncome*(offset+1)/count)\1)-((p.remainingOtherIncome*offset/count)\1)
}
ClassMethod Adopt(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject) As %Boolean
{
    if '##class(Rugby.Service.Leagues).French(c.competitionId) quit 0
    if '$isobject(s.%Get("community")) quit 0
    if s.community.%Get("frenchBalanceVersion")=..#VERSION quit 0
    set forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),s.community=forecast.community,s.financingPlan=forecast
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
    quit 1
}
ClassMethod InitializeAll() As %DynamicObject
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),result={"seasons":0},ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Revisando presupuestos franceses.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 {
            set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1"
            if %RugbyGame'="template" set %RugbyManagedClub=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)).clubId
            set clubs=##class(Rugby.Service.Store).All("Club")
            for j=0:1:clubs.%Size()-1 { set c=clubs.%Get(j) if ##class(Rugby.Service.Leagues).French(c.competitionId) { set s=##class(Rugby.Service.Finance).Season(c) if ..Adopt(c,s,##class(Rugby.Service.Finance).Office(c.id)) set result.seasons=result.seasons+1 } }
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
    quit result
}
}
