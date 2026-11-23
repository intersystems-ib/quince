Class Rugby.Test.FrenchFinanceBalance Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Balanced(f As %DynamicObject)
{
    do ..Assert((f.targetMarginPercent>=.5)&&(f.targetMarginPercent<=3),"Target margin stays within a small operating range")
    set delta=(f.projectedMargin*100/f.projectedIncome)-f.targetMarginPercent
    do ..Assert((delta>(-.001))&&(delta<.001),"Projected margin matches the individual target")
}
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",report={"clubs":0,"partialSeason":false,"payments":false}
    tstart
    try {
        set clubs=##class(Rugby.Service.Store).All("Club"),spanish=##class(Rugby.Service.Finance).Season(##class(Rugby.Service.Store).Get("Club","c1")).%ToJSON(),targets={}
        for i=0:1:clubs.%Size()-1 {
            set c=clubs.%Get(i)
            if '##class(Rugby.Service.Leagues).French(c.competitionId) continue
            set s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),f=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
            do ..Balanced(f)
            do targets.%Set(f.targetMarginPercent,1)
            set weak={"director":{"id":"test","quality":35}},strong={"director":{"id":"test","quality":90}},low=##class(Rugby.Service.FrenchFinanceBalance).TargetMargin(c,s,weak),high=##class(Rugby.Service.FrenchFinanceBalance).TargetMargin(c,s,strong)
            do ..Assert(high>low,"Better financial directors improve the same club's margin")
            do ..Assert(high=##class(Rugby.Service.FrenchFinanceBalance).TargetMargin(c,s,strong),"Margin variation is deterministic")
            set report.clubs=report.clubs+1
        }
        do ..Assert(targets.%Size()>10,"Clubs have distinct operating margin targets")
        set c=##class(Rugby.Service.Store).Get("Club","fr-clermont"),c.date="2026-09-28",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date)
        do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Finance).Tick(c.id)
        set c=##class(Rugby.Service.Store).Get("Club",c.id),c.date="2026-10-15",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date)
        do ##class(Rugby.Service.Store).Put("Club",c)
        set s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),ledger=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON(),cash=c.balance,roster=##class(Rugby.Service.Store).All("Player","clubId",c.id).%ToJSON(),contracts=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id).%ToJSON(),costs=s.community.annualCosts
        set s.community.plannedOtherIncome=s.community.plannedOtherIncome*3
        do s.community.%Remove("frenchBalanceVersion"),##class(Rugby.Service.Store).Put("FinancialSeason",s)
        set adopted=##class(Rugby.Service.FrenchFinanceBalance).Adopt(c,s,o),s=##class(Rugby.Service.Finance).Season(c),f=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
        do ..Balanced(f)
        do ..Assert((s.community.annualCosts=costs)&&(c.balance=cash),"Balancing does not inflate expenses or alter cash")
        do ..Assert(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()=ledger,"Settled movements remain unchanged")
        do ..Assert(##class(Rugby.Service.Store).All("Player","clubId",c.id).%ToJSON()=roster,"Player salaries and contracts remain unchanged")
        do ..Assert(##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id).%ToJSON()=contracts,"Signed sponsorships remain unchanged")
        do ..Assert('##class(Rugby.Service.FrenchFinanceBalance).Adopt(c,s,o),"Rebalancing is idempotent within the season")
        // A club first introduced in April must not forecast twelve payrolls or unsigned September deals.
        set c=##class(Rugby.Service.Store).Get("Club","fr-agen"),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),c.date="2027-04-15",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date),c.startDay=c.day
        do ##class(Rugby.Service.Store).Put("Club",c)
        set ^RugbyWorld("template","monthlyPayroll",c.id)={"lastDay":(c.day-1),"wages":0,"staffWages":0,"financeWages":0}.%ToJSON()
        set s.introducedOn=c.date,s.community.firstInstalment=7
        do s.community.%Remove("frenchBalanceVersion"),##class(Rugby.Service.Store).Put("FinancialSeason",s)
        set adopted=##class(Rugby.Service.FrenchFinanceBalance).Adopt(c,s,o),s=##class(Rugby.Service.Finance).Season(c),f=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),payroll=##class(Rugby.Service.Payroll).Summary(c.id,0),totals=##class(Rugby.Service.MonthlyPayroll).Totals(c.id)
        do ..Balanced(f)
        do ..Assert((payroll.annualPlayers>(totals.players*4))&&(payroll.annualPlayers<(totals.players*5)),"Late introduction projects the remaining payroll months only")
        do ..Assert((f.privateSponsors=0)&&(f.publicGrants=0)&&(f.memberships=0),"Unsigned September income is not invented in April")
        set fixtures=##class(Rugby.Service.Store).All("Fixture","homeId",c.id),expected=0,past=""
        for j=0:1:fixtures.%Size()-1 { set fixture=fixtures.%Get(j) if fixture.day<c.startDay { set past=fixture } else { if fixture.status'="finished" set expected=expected+1 } }
        do ..Assert(f.ticketForecast.remainingMatches=expected,"Ticket forecasts exclude fixtures before club adoption")
        if $isobject(past) {
            set beforeLedger=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON(),settled=##class(Rugby.Service.Finance).Settle(past)
            do ..Assert(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()=beforeLedger,"Historical fixtures do not create retroactive club receipts")
        }
        set target=s.community.plannedOtherIncome,received=0
        for month=4:1:6 {
            set c.date="2027-0"_month_"-21",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date),before=c.balance
            do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.ClubRevenue).Tick(c,s,o)
            set rows=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id),received=0
            for j=0:1:rows.%Size()-1 { set m=rows.%Get(j) if m.type="otherIncome" set received=received+m.amount }
            set once=c.balance
            do ##class(Rugby.Service.ClubRevenue).Tick(c,s,o)
            do ..Assert(c.balance=once,"A monthly income instalment cannot be paid twice")
        }
        do ..Assert(received=target,"Remaining monthly payments reconcile with the income forecast")
        set c.date="2027-06-25",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date),probe=##class(%DynamicObject).%FromJSON(s.community.%ToJSON())
        do probe.%Remove("frenchBalanceVersion")
        set closed=##class(Rugby.Service.FrenchFinanceBalance).Plan(c,s,o,probe,9999999999,0)
        do ..Assert((closed.balanceInstalments=0)&&(closed.remainingOtherIncome=0),"No new receipts are forecast after the last collection date")
        do ..Assert(##class(Rugby.Service.Finance).Season(##class(Rugby.Service.Store).Get("Club","c1")).%ToJSON()=spanish,"Spanish budgets remain unchanged")
        set report.partialSeason=1,report.payments=1
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit report
}
}
