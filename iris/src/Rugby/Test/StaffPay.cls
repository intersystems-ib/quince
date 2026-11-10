Class Rugby.Test.StaffPay Extends %RegisteredObject
{
ClassMethod Run()
{
    set game=##class(Rugby.Service.Store).Game(),c=##class(Rugby.Service.Store).Get("Club","c2"),c.day=c.day+10,c.date=##class(Rugby.Service.Injuries).Date(c.day),staff=##class(Rugby.Service.Staff).View(c.id),old=0,balance=c.balance,movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()
    do ##class(Rugby.Service.Store).Put("Club",c)
    for i=0:1:staff.coaches.%Size()-1 {
        set p=staff.coaches.%Get(i),p.monthlyWage=(p.monthlyWage*.8)\100*100,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),old=old+p.monthlyWage
        do p.%Remove("staffPayVersion"),##class(Rugby.Service.Store).Put("Coach",p)
    }
    kill ^RugbyWorld(game,"staffPayVersion")
    set report=##class(Rugby.Service.StaffPay).Initialize(),after=##class(Rugby.Service.Staff).View(c.id),beforeDay=##class(Rugby.Service.MonthlyPayroll).DailyTotals(c.id,c.day-1),today=##class(Rugby.Service.MonthlyPayroll).DailyTotals(c.id,c.day),summary=##class(Rugby.Service.Payroll).Summary(c.id)
    do ##class(Rugby.Test.Suite).Assert((after.monthlyWage>(old*1.24))&&(after.monthlyWage<=(old*1.25)),"Existing staff salaries rise by roughly twenty-five percent: old="_old_" new="_after.monthlyWage_" margin="_summary.annualMargin_" reserve="_summary.annualSafetyReserve)
    do ##class(Rugby.Test.Suite).Assert((beforeDay.staffWages=old)&&(today.staffWages=after.monthlyWage),"Unpaid earlier days retain the old salary and current days use the increase")
    do ##class(Rugby.Test.Suite).Assert((summary.annualMargin>=summary.annualSafetyReserve)&&(##class(Rugby.Service.Store).Get("Club",c.id).balance=balance)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=movements),"Salary adoption preserves cash and budget safety")
    set count=##class(Rugby.Service.Store).All("StaffContract").%Size(),again=##class(Rugby.Service.StaffPay).Initialize()
    do ##class(Rugby.Test.Suite).Assert((again.adjustments.%Size()=0)&&(##class(Rugby.Service.Store).All("StaffContract").%Size()=count),"A restart does not apply the increase twice")
}
}
