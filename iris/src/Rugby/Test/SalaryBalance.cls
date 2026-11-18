Class Rugby.Test.SalaryBalance Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),f=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
        do ..Assert((f.projectedMargin>=0)&&(f.projectedMargin<=(f.projectedIncome*.025)),"All clubs start within 2.5 percent of break-even: "_c.id)
        set payroll=##class(Rugby.Service.Payroll).Summary(c.id,0),cap=##class(Rugby.Service.Payroll).BaseAnnualCap(c.id)
        do ..Assert(cap+payroll.annualStaff+payroll.annualDirector+payroll.annualRegistrations+payroll.annualTravelReserve<=(f.projectedIncome*.99501),"Player salary limit uses projected income: "_c.id)
    }
    set c=##class(Rugby.Service.Store).Get("Club","c2"),c.day=c.day+10,c.date=##class(Rugby.Service.Injuries).Date(c.day)
    do c.%Remove("salaryBalanceVersion"),##class(Rugby.Service.Store).Put("Club",c)
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id)
    for i=0:1:players.%Size()-1 { set p=players.%Get(i),p.monthlyWage=p.monthlyWage*2,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage) do p.%Remove("salaryEffectiveDay"),##class(Rugby.Service.Store).Put("Player",p) }
    set before=##class(Rugby.Service.MonthlyPayroll).DailyTotals(c.id,c.day-1),cash=c.balance,ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),playerContracts=##class(Rugby.Service.Store).All("PlayerContract").%Size(),staffContracts=##class(Rugby.Service.Store).All("StaffContract").%Size(),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
    set result=##class(Rugby.Service.SalaryBalance).Club(c),after=##class(Rugby.Service.MonthlyPayroll).DailyTotals(c.id,c.day-1),today=##class(Rugby.Service.MonthlyPayroll).DailyTotals(c.id,c.day),updated=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,##class(Rugby.Service.Finance).Office(c.id))
    do ..Assert((result.factor<1)&&(today.wages<before.wages)&&(today.staffWages<before.staffWages),"Players and employees are reduced proportionately")
    do ..Assert((after.wages=before.wages)&&(after.staffWages=before.staffWages)&&(after.financeWages=before.financeWages),"Accrued days retain the previous player and employee rates")
    do ..Assert((forecast.publicGrants=updated.publicGrants)&&(forecast.projectedIncome=updated.projectedIncome),"Lower wages cannot remove or inflate forecast income or grants")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=cash)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=ledger),"No already paid salary or cash movement is rewritten")
    do ..Assert((##class(Rugby.Service.Store).All("PlayerContract").%Size()=playerContracts)&&(##class(Rugby.Service.Store).All("StaffContract").%Size()=staffContracts),"Calibration does not duplicate contract history")
    set snapshot=##class(Rugby.Service.Store).All("Player").%ToJSON(),again=##class(Rugby.Service.SalaryBalance).Club(##class(Rugby.Service.Store).Get("Club",c.id))
    do ..Assert(('again.adjusted)&&(snapshot=##class(Rugby.Service.Store).All("Player").%ToJSON()),"Restarting cannot reduce salaries twice")
    do ..Assert(##class(Rugby.Service.MonthlyPayroll).StaffMonthly("head",90,c.id)>##class(Rugby.Service.MonthlyPayroll).StaffMonthly("head",35,c.id),"New staff wages still reflect quality")
    do ..Treasury()
}
ClassMethod Treasury()
{
    set c=##class(Rugby.Service.Store).Get("Club","c3"),c.initialBalance=25000000,c.balance=25000000
    do c.%Remove("openingTreasuryVersion"),##class(Rugby.Service.Store).Put("Club",c)
    set advanced=##class(Rugby.Service.Store).Get("Club","c2"),cash=advanced.balance,opening=advanced.initialBalance
    do advanced.%Remove("openingTreasuryVersion"),##class(Rugby.Service.Store).Put("Club",advanced)
    set ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),result=##class(Rugby.Service.OpeningTreasury).Initialize(),updated=##class(Rugby.Service.Store).Get("Club","c3"),kept=##class(Rugby.Service.Store).Get("Club","c2"),t=##class(Rugby.Service.MonthlyPayroll).Totals("c3")
    do ..Assert((updated.balance=##class(Rugby.Service.OpeningTreasury).Funds("c3"))&&(updated.balance<25000000)&&(updated.balance>=(t.players+t.staff+t.director)*2),"Opening liquidity is reduced but covers two payrolls and initial operating costs")
    do ..Assert((kept.balance=cash)&&(kept.initialBalance=opening)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=ledger),"Advanced games retain all earned/spent cash and historical movements")
    set result=##class(Rugby.Service.OpeningTreasury).Initialize()
    do ..Assert(result.%Size()=0,"Opening cash cannot be reset on restart")
}
}
