Class Rugby.Test.SalaryBudget Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run()
{
    set club=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",club),s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(club)
    set o.director=o.candidates.%Get(2),s.grantsComplete=1,s.grants=[{"id":"budget-grant","name":"Organismo público local","amount":120000000,"status":"instalments"}]
    do o.%Remove("salaryBudget"),##class(Rugby.Service.Store).Put("FinancialOffice",o),##class(Rugby.Service.Store).Put("FinancialSeason",s)
    set base=##class(Rugby.Service.Payroll).AnnualCap(club),initial=##class(Rugby.Service.SalaryBudget).Calculate(club),cash=c.balance,players=##class(Rugby.Service.Store).All("Player").%ToJSON(),ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()
    do ..Assert((initial.percent=0)&&(initial.surplusAtBaseLimit>0),"No change to existing caps until configured, with finite income-backed capacity")
    set b={"version":(o.version),"percent":90},saved=##class(Rugby.Service.SalaryBudget).Save(club,b,"salary-flex-90"),retry=##class(Rugby.Service.SalaryBudget).Save(club,b,"salary-flex-90"),plan=saved.salaryBudget
    do ..Assert((retry.office.version=saved.office.version)&&(plan.annualLimit>base),"Adjustment is persisted and idempotent")
    do ..Assert(plan.surplusAtLimit>=plan.minimumReserve,"Full use leaves ten percent of the additional surplus")
    do ..Assert(##class(Rugby.Service.Payroll).AnnualCap(club)=plan.annualLimit,"Signings use the configured annual ceiling")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",club).balance=cash)&&(##class(Rugby.Service.Store).All("Player").%ToJSON()=players)&&(##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()=ledger),"Allocating a budget neither spends cash nor changes wages or income")
    set cap=##class(Rugby.Service.Payroll).WeeklyCap(club),oldCap=(base\5200)*100,p=##class(Rugby.Service.Store).Get("Player",club_"-p1"),used=##class(Rugby.Service.Payroll).Used(club,p.id),caught=0
    do ##class(Rugby.Service.Payroll).Check(club,p.id,cap-used)
    try { do ##class(Rugby.Service.Payroll).Check(club,p.id,cap-used+100) } catch ex { set caught=ex.Location="PAYROLL_LIMIT" }
    do ..Assert(caught&&(cap>oldCap),"Expanded room is usable and offers above it are rejected")
    set caught=0
    try { do ##class(Rugby.Service.Payroll).Check(club,p.id,cap-used,10000000) } catch ex { set caught=ex.Location="PAYROLL_LIMIT" }
    do ..Assert(caught,"Signing fees cannot consume the same reserved surplus twice")
    set caught=0
    try { do ##class(Rugby.Service.Payroll).Check(club,p.id,p.weeklyWage,120000000) } catch ex { set caught=ex.Location="PAYROLL_LIMIT" }
    do ..Assert(caught,"A low salary cannot bypass financial safety with a large signing fee")
    set p.weeklyWage=p.weeklyWage+100,p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage)
    do ##class(Rugby.Service.Store).Put("Player",p)
    do ..Assert(##class(Rugby.Service.Payroll).AnnualCap(club)=plan.annualLimit,"Hiring does not raise its own limit or create new grants")
    set o=##class(Rugby.Service.Finance).Office(club),caught=0
    try { set ignored=##class(Rugby.Service.SalaryBudget).Save(club,{"version":(o.version),"percent":91},"salary-invalid") } catch ex { set caught=ex.Location="SALARY_PERCENT" }
    do ..Assert(caught,"Reserve percentage cannot be bypassed")
    set caught=0
    try { set ignored=##class(Rugby.Service.SalaryBudget).Save(club,b,"salary-stale") } catch ex { set caught=ex.Location="VERSION_CONFLICT" }
    do ..Assert(caught,"Concurrent finance updates require a current version")
    set result=##class(Rugby.Service.SalaryBudget).Save(club,{"version":(o.version),"percent":0},"salary-reset")
    do ..Assert(##class(Rugby.Service.Payroll).AnnualCap(club)=base,"Reset restores the ordinary ceiling")
    set s.grants=[],s.grantsComplete=0
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
    set current=##class(Rugby.Service.SalaryBudget).Calculate(club)
    do ..Assert(current.projectedIncome<plan.projectedIncome,"Unawarded grants are excluded from available funding")
    set o=##class(Rugby.Service.Finance).Office(club),o.salaryBudget={"year":(initial.year-1),"percent":90}
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    do ..Assert(##class(Rugby.Service.Payroll).AnnualCap(club)=base,"A new season requires its own allocation")
}
}
