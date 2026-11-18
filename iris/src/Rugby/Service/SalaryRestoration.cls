Class Rugby.Service.SalaryRestoration Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Restore(kind As %String, p As %DynamicObject, day As %Integer, cutDay As %Integer) As %Boolean
{
    if (p.%Get("salaryEffectiveDay",-999999)'=cutDay)||(p.%Get("salaryBeforeAdjustment",0)<=0) quit 0
    if (p.%Get("signedDay",cutDay)>cutDay)||(p.%Get("renewedDay",cutDay)>cutDay) quit 0
    set old=##class(Rugby.Service.MonthlyPayroll).Value(p),amount=p.salaryBeforeAdjustment
    if amount<=old quit 0
    set p.monthlyWage=amount,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(amount),p.salaryBeforeAdjustment=old,p.salaryEffectiveDay=day
    if kind'="" do ##class(Rugby.Service.Store).Put(kind,p)
    quit 1
}
ClassMethod Initialize() As %DynamicObject
{
    set clubs=##class(Rugby.Service.Store).All("Club"),result={"players":0,"employees":0}
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if c.%Get("salaryBalanceVersion")'="1.0.0" continue
        set cutDay=##class(Rugby.Service.SeasonCalendar).Day(c.salaryBalanceDate)
        for field="salaryPlayerFactor","salaryStaffFactor","salaryDirectorFactor","salaryAnnualIncome","salaryBalanceVersion","salaryBalanceDate" { do c.%Remove(field) }
        do ##class(Rugby.Service.Store).Put("Club",c)
        set players=##class(Rugby.Service.Store).All("Player","clubId",c.id)
        for j=0:1:players.%Size()-1 {
            set p=players.%Get(j)
            if ..Restore("Player",p,c.day,cutDay) {
                set result.players=result.players+1
                if p.category="academy" { set p.seniorWeeklyWage=##class(Rugby.Service.Payroll).Reference(p,c.id,"senior") do ##class(Rugby.Service.Store).Put("Player",p) }
            }
        }
        set staff=##class(Rugby.Service.Store).Get("TechnicalStaff",c.id)
        for j=0:1:staff.coachIds.%Size()-1 { set p=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(j)) if ..Restore("Coach",p,c.day,cutDay) set result.employees=result.employees+1 }
        set office=##class(Rugby.Service.Finance).Office(c.id)
        if office.director.%Get("id")'="" { if ..Restore("",office.director,c.day,cutDay) set result.employees=result.employees+1 }
        for j=0:1:office.candidates.%Size()-1 { set p=office.candidates.%Get(j),p.monthlyWage=##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(p.quality,c.id),p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage) }
        do ##class(Rugby.Service.Store).Put("FinancialOffice",office)
    }
    if result.players>0 {
        set free=##class(Rugby.Service.Store).All("Player","clubId","")
        for i=0:1:free.%Size()-1 { set p=free.%Get(i) if p.%Get("contractStatus")'="retired" { set p.weeklyWage=##class(Rugby.Service.Payroll).Reference(p,##class(Rugby.Service.Store).ManagedClub()),p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage) do ##class(Rugby.Service.Store).Put("Player",p) } }
    }
    quit result
}
}
