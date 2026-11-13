Class Rugby.Service.SalaryBudget Extends %RegisteredObject
{
Parameter MAXPERCENT = 90;
ClassMethod Percent(club As %String) As %Integer
{
    set c=##class(Rugby.Service.Store).Get("Club",club),o=##class(Rugby.Service.Store).Get("FinancialOffice",club,0)
    if '$isobject(o) quit 0
    set setting=o.%Get("salaryBudget",{})
    if setting.%Get("year",0)'=##class(Rugby.Service.Competition).Year(c.date) quit 0
    quit ##class(Rugby.Simulation.Engine).Clamp(setting.%Get("percent",0),0,..#MAXPERCENT)
}
ClassMethod Calculate(club As %String, signingFee As %Integer = 0) As %DynamicObject
{
    set c=##class(Rugby.Service.Store).Get("Club",club),o=##class(Rugby.Service.Finance).Office(club),year=##class(Rugby.Service.Competition).Year(c.date),s=##class(Rugby.Service.Store).Get("FinancialSeason",club_"-finance-"_year,0)
    if '$isobject(s) set s={"year":(year),"grants":[],"grantsComplete":false}
    set payroll=##class(Rugby.Service.Payroll).Summary(club,0),forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),grants=0
    for i=0:1:s.grants.%Size()-1 { set grants=grants+s.grants.%Get(i).amount }
    // A grant forecast based on costs must not finance an increase in those same costs.
    set income=forecast.projectedIncome-forecast.publicGrants+grants,fees=signingFee,movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId",club)
    for i=0:1:movements.%Size()-1 {
        set m=movements.%Get(i)
        if (m.type="transfer")&&(m.amount<0)&&(##class(Rugby.Service.Competition).Year(m.date)=year) set fees=fees-m.amount
    }
    set base=##class(Rugby.Service.Payroll).BaseAnnualCap(club),other=payroll.annualProjectedCosts-payroll.annualPlayers+fees,pool=+$justify(income-other-base,0,0),pool=$select(pool>0:pool,1:0),percent=..Percent(club),extra=(pool*percent/100)\1,maxExtra=(pool*..#MAXPERCENT/100)\1
    quit {"year":(year),"version":(o.version),"percent":(percent),"maxPercent":(..#MAXPERCENT),"baseAnnualLimit":(base),"surplusAtBaseLimit":(pool),"maxAdditionalAnnual":(maxExtra),"additionalAnnual":(extra),"annualLimit":(base+extra),"projectedIncome":(income),"otherAnnualCosts":(other),"currentAnnualPlayers":(payroll.annualPlayers),"currentSurplus":(income-other-payroll.annualPlayers),"surplusAtLimit":(income-other-base-extra),"minimumReserve":(pool-maxExtra),"provisional":(forecast.provisional)}
}
ClassMethod Affordable(club As %String, pid As %String, wage As %Integer, fee As %Integer = 0) As %Boolean
{
    set current=##class(Rugby.Service.Payroll).Used(club),proposed=##class(Rugby.Service.Payroll).Used(club,pid)+wage
    if (proposed<=current)&&(fee=0) quit 1
    set plan=..Calculate(club,fee),reserve=..Calculate(club).minimumReserve,weeks=$select(##class(Rugby.Service.MonthlyPayroll).Active():52,1:53)
    quit ((proposed*weeks)+plan.otherAnnualCosts)<=(plan.projectedIncome-reserve)
}
ClassMethod Save(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club),##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"retry","salaryBudget",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","salaryBudget",club,key))
    set o=##class(Rugby.Service.Finance).Office(club)
    do ##class(Rugby.Service.Store).CheckVersion(o,b)
    if (b.%GetTypeOf("percent")'="number")||('##class(Rugby.Service.Store).Integer(b.%Get("percent"),0,..#MAXPERCENT)) do ##class(Rugby.Service.Store).Fail(422,"SALARY_PERCENT","Elige un porcentaje entero entre 0 y 90.")
    set plan=..Calculate(club)
    if (b.percent>0)&&(plan.surplusAtBaseLimit<=0) do ##class(Rugby.Service.Store).Fail(409,"SALARY_SURPLUS","No hay superávit adicional para ampliar el límite salarial.")
    set o.salaryBudget={"year":(plan.year),"percent":(b.percent)}
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    set result=##class(Rugby.Service.Finance).View(club),^RugbyWorld(game,"retry","salaryBudget",club,key)=result.%ToJSON()
    quit result
}
}
