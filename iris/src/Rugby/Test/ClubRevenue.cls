Class Rugby.Test.ClubRevenue Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    do ..Restoration()
    set players=##class(Rugby.Service.Store).All("Player").%ToJSON()
    do ##class(Rugby.Service.ClubRevenue).Initialize()
    do ..Assert(players=##class(Rugby.Service.Store).All("Player").%ToJSON(),"The revenue model never reduces player salaries")
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),o=##class(Rugby.Service.Finance).Office(c.id),s=##class(Rugby.Service.Finance).Season(c),p=s.community
        if c.id="c1" {
            set o.director=o.candidates.%Get(1),o.director.monthlyWage=##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(65,c.id)
            do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
        }
        set f=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
        do ..Assert((p.annualMembersIncome=(p.memberCount*p.memberFee))&&(p.annualYouthFees+p.annualActivitiesIncome=p.annualOtherIncome),"Membership and youth/activity receipts reconcile: "_c.id)
        do ..Assert((p.annualCoachingCosts+p.annualFederationTravelCosts+p.annualFacilitiesCosts=p.annualCosts)&&(p.firstInstalment=0),"Associated costs are itemised for the full opening season: "_c.id)
        do ..Assert((f.projectedMargin>=0)&&(f.projectedMargin<=(f.projectedIncome*.03)),"Fully staffed clubs start close to break-even without wage cuts: "_c.id)
        if $listfind($listbuild("c1","c7"),c.id) do ..Assert(p.referenceBudget=60000000,"Cisneros and Alcobendas have a 600,000 euro whole-club reference")
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),opening=c.balance,c.date="2026-09-20",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date)
    do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.ClubRevenue).Tick(c,s,o)
    do ..Assert(c.balance=opening,"Social revenue is not paid before the collection date")
    for month=9,10,11,12,1,2,3,4,5,6 {
        set c.date=$select(month>=9:"2026",1:"2027")_"-"_$select(month<10:"0",1:"")_month_"-21",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date)
        do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.ClubRevenue).Tick(c,s,o)
        set balance=c.balance
        do ##class(Rugby.Service.ClubRevenue).Tick(c,s,o)
        do ..Assert(c.balance=balance,"Monthly social receipts and expenses are idempotent")
    }
    do ..Assert(c.balance=(opening+s.community.annualMembersIncome+s.community.annualOtherIncome-s.community.annualCosts),"Ten monthly receipts reconcile exactly with the annual net contribution")
    set oldCosts=s.community.annualCosts,oldIncome=s.community.annualMembersIncome+s.community.annualOtherIncome,p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.monthlyWage=p.monthlyWage*2,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage)
    do ##class(Rugby.Service.Store).Put("Player",p)
    set f=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
    do ..Assert((f.community.annualCosts=oldCosts)&&(f.community.annualMembersIncome+f.community.annualOtherIncome=oldIncome),"Extra signings cannot manufacture income or remove youth operating costs")
    set c.date="2097-04-22",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date),c.seasonYear=2096
    do ##class(Rugby.Service.Store).Put("Club",c)
    set late=##class(Rugby.Service.Finance).Season(c),cash=c.balance
    do ##class(Rugby.Service.ClubRevenue).Prepare(c,late,o),##class(Rugby.Service.ClubRevenue).Tick(c,late,o)
    do ..Assert((late.community.firstInstalment=8)&&(late.community.plannedMembersIncome=(late.community.annualMembersIncome*.2))&&(c.balance=cash),"Late adoption forecasts only future instalments and never backdates receipts")
    do ..Treasury()
}
ClassMethod Restoration()
{
    set c=##class(Rugby.Service.Store).Get("Club","c2"),p=##class(Rugby.Service.Store).Get("Player","c2-p1"),old=##class(Rugby.Service.MonthlyPayroll).Value(p),p.salaryBeforeAdjustment=old,p.salaryEffectiveDay=c.day,p.monthlyWage=old\2,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),c.salaryBalanceVersion="1.0.0",c.salaryBalanceDate=c.date,c.salaryPlayerFactor=.5,c.salaryStaffFactor=.5,c.salaryDirectorFactor=.5,c.salaryAnnualIncome=10000000
    do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Store).Put("Player",p)
    set staff=##class(Rugby.Service.Staff).View(c.id),coach=staff.coaches.%Get(0),oldCoach=coach.monthlyWage,coach.salaryBeforeAdjustment=oldCoach,coach.salaryEffectiveDay=c.day,coach.monthlyWage=oldCoach\2,coach.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(coach.monthlyWage)
    do ##class(Rugby.Service.Store).Put("Coach",coach)
    set office=##class(Rugby.Service.Finance).Office(c.id),oldDirector=office.director.monthlyWage,office.director.salaryBeforeAdjustment=oldDirector,office.director.salaryEffectiveDay=c.day,office.director.monthlyWage=oldDirector\2,office.director.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(office.director.monthlyWage)
    do ##class(Rugby.Service.Store).Put("FinancialOffice",office)
    set cash=c.balance,ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),result=##class(Rugby.Service.SalaryRestoration).Initialize()
    do ..Assert((##class(Rugby.Service.Store).Get("Player",p.id).monthlyWage=old)&&(##class(Rugby.Service.Store).Get("Coach",coach.id).monthlyWage=oldCoach)&&(##class(Rugby.Service.Finance).Office(c.id).director.monthlyWage=oldDirector),"A deployed wage cut is reversed for players, coaches and financial director")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=cash)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=ledger),"Salary restoration changes no cash or already paid wages")
    set result=##class(Rugby.Service.SalaryRestoration).Initialize()
    do ..Assert((result.players=0)&&(result.employees=0),"Restoration is not repeated at startup")
}
ClassMethod Treasury()
{
    set c=##class(Rugby.Service.Store).Get("Club","c3"),c.initialBalance=25000000,c.balance=25000000
    do c.%Remove("openingTreasuryVersion"),##class(Rugby.Service.Store).Put("Club",c)
    set result=##class(Rugby.Service.OpeningTreasury).Initialize(),updated=##class(Rugby.Service.Store).Get("Club","c3"),t=##class(Rugby.Service.MonthlyPayroll).Totals(c.id)
    do ..Assert((updated.balance=##class(Rugby.Service.OpeningTreasury).Funds(c.id))&&(updated.balance<25000000)&&(updated.balance>=(t.players+t.staff+t.director+(##class(Rugby.Service.ClubRevenue).Costs(c.id)/10))),"Opening cash covers the first month and remains below the former 250,000 euros")
}
}
