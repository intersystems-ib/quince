Class Rugby.Test.EmployeePayroll Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set game=##class(Rugby.Service.Store).Game(),c=##class(Rugby.Service.Store).Get("Club","c1"),start=$zdateh("2026-09-01",3)-$zdateh("2026-11-07",3),balance=c.balance
    do ..Assert(##class(Rugby.Service.MonthlyPayroll).Active(),"Monthly payroll adopted")
    do ..Assert((##class(Rugby.Service.MonthlyPayroll).Days("2028-02-01")=29)&&(##class(Rugby.Service.MonthlyPayroll).Days("2027-02-01")=28),"Actual month length includes leap years")
    set totals=##class(Rugby.Service.MonthlyPayroll).Totals(c.id),o=##class(Rugby.Service.Finance).Office(c.id),o.director=o.candidates.%Get(0),o.director.monthlyWage=90000,o.director.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(90000),o.director.payrollStartDay=start+15
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    set ^RugbyWorld(game,"monthlyPayroll",c.id)={"lastDay":(start-1),"adoptedDay":(start-1),"wages":0,"staffWages":0,"financeWages":0,"version":"1.0.0"}.%ToJSON()
    kill ^RugbyWorld(game,"monthlyPaid",c.id,"2026-09")
    set paid=##class(Rugby.Service.MonthlyPayroll).Tick(c.id,start+28)
    do ..Assert((paid.%Size()=0)&&(##class(Rugby.Service.Store).Get("Club",c.id).balance=balance),"No salary debit before the month end")
    set paid=##class(Rugby.Service.MonthlyPayroll).Tick(c.id,start+29),after=##class(Rugby.Service.Store).Get("Club",c.id),player=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-monthly-payroll-2026-09-wages"),staff=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-monthly-payroll-2026-09-staffWages"),finance=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-monthly-payroll-2026-09-financeWages")
    do ..Assert((player.amount=-totals.players)&&(staff.amount=-totals.staff)&&(finance.amount=-45000),"Full month players/staff and half-month financial director paid exactly")
    do ..Assert((player.date="2026-09-30")&&(after.date=c.date)&&(after.day=c.day),"Month-end ledger date preserves current game date")
    do ..Assert(after.balance=balance-totals.players-totals.staff-45000,"Cash reconciles to monthly ledger")
    set retry=##class(Rugby.Service.MonthlyPayroll).Tick(c.id,start+29)
    do ..Assert((retry.%Size()=0)&&(##class(Rugby.Service.Store).Get("Club",c.id).balance=after.balance),"Replaying a month close never pays twice")
    set before=##class(Rugby.Service.Store).All("PlayerContract").%Size(),again=##class(Rugby.Service.MonthlyPayroll).Initialize()
    do ..Assert((again.players=0)&&(##class(Rugby.Service.Store).All("PlayerContract").%Size()=before),"Monthly migration is idempotent")
    do ..Assert(##class(Rugby.Service.MonthlyPayroll).StaffMonthly("head",90,"c1")>##class(Rugby.Service.MonthlyPayroll).StaffMonthly("head",35,"c1"),"Employee salary grows with quality")
    do ..Assert('##class(Rugby.Service.MonthlyPayroll).CanHire("c1","head",99999999),"Unaffordable employees are rejected")
    // Accrual keeps the old employee's earned amount after replacement or departure.
    set state=##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"monthlyPayroll",c.id)),state.wages=12345,state.staffWages=6789,state.financeWages=3456,state.lastDay=start+59,state.adoptedDay=start+59
    set ^RugbyWorld(game,"monthlyPayroll",c.id)=state.%ToJSON(),paid=##class(Rugby.Service.MonthlyPayroll).Tick(c.id,start+60)
    set m=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-monthly-payroll-2026-10-wages")
    do ..Assert(m.amount=-+$justify(12345+(totals.players/31),0,0),"Unpaid carry survives until the next month end")
    do ..Migration(),..Advance()
}
ClassMethod Migration()
{
    tstart
    set game=##class(Rugby.Service.Store).Game(),c=##class(Rugby.Service.Store).Get("Club","c2"),c.date="2026-09-10",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3),c.staffPayrollAccrued=12345,o=##class(Rugby.Service.Finance).Office(c.id),o.salaryAccrued=2345
    do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Store).Put("FinancialOffice",o)
    set day=c.day,c.day=day-2,c.date="2026-09-08"
    do ##class(Rugby.Service.Management).Money(c,-1000,"wages","Legacy wage payment","test-legacy-pay")
    set c.day=day,c.date="2026-09-10"
    do ##class(Rugby.Service.Store).Put("Club",c)
    set balance=c.balance,count=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%Size(),expected=##class(Rugby.Service.MonthlyPayroll).PlayerTotal(c.id)*12/52/7*2
    kill ^RugbyWorld(game,"monthlyPayroll",c.id)
    do ##class(Rugby.Service.MonthlyPayroll).Adopt(c)
    set state=##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"monthlyPayroll",c.id))
    do ..Assert(($zabs(state.wages-expected)<.001)&&(state.staffWages=12345)&&(state.financeWages=2345),"Migration carries unpaid players and employees after the last legacy payment")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=balance)&&(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%Size()=count),"Adoption changes no cash or historical ledger")
    trollback 1
}
ClassMethod Advance()
{
    tstart
    set game=##class(Rugby.Service.Store).Game(),date="2026-11-30",day=$zdateh(date,3)-$zdateh("2026-11-07",3),clubs=##class(Rugby.Service.Store).All("Club"),fixtures=##class(Rugby.Service.Store).All("Fixture")
    // Keep the test independent from pending managed matches.
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if ((f.homeId="c1")||(f.awayId="c1"))&&(f.status'="finished") { set f.day=day+90 do ##class(Rugby.Service.Store).Put("Fixture",f) } }
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),c.day=day,c.date=date,c.aiLastDay=day
        do ##class(Rugby.Service.Store).Put("Club",c)
        set ^RugbyWorld(game,"monthlyPayroll",c.id)={"lastDay":(day-1),"adoptedDay":(day-1),"wages":10000,"staffWages":2000,"financeWages":500,"version":"1.0.0"}.%ToJSON()
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),result=##class(Rugby.Service.Management).Advance(c.id,{"version":(c.version)},"test-month-end-advance"),audit=##class(Rugby.Service.Store).Get("RivalExecution","rivals-day-"_(day+1))
    do ..Assert((result.date="2026-12-01")&&(audit.monthlyPayroll.%Size()>0),"Advance closes the previous month and audits its payroll")
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i),m=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-monthly-payroll-2026-11-wages") do ..Assert(m.date="2026-11-30","All twenty clubs pay on the same month end") }
    set balance=result.balance,retry=##class(Rugby.Service.Management).Advance("c1",{},"test-month-end-advance")
    do ..Assert(retry.balance=balance,"Advance retry keeps the paid balance")
    trollback 1
}
}
