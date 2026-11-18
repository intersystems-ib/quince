Class Rugby.Service.SalaryBalance Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"version":(..#VERSION),"gameId":(game),"clubs":[]}
    if $get(^RugbyWorld(game,"salaryBalanceVersion"))=..#VERSION { set report.treasury=##class(Rugby.Service.OpeningTreasury).Initialize() quit report }
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 { do report.clubs.%Push(..Club(clubs.%Get(i))) }
    set free=##class(Rugby.Service.Store).All("Player","clubId","")
    for i=0:1:free.%Size()-1 {
        set p=free.%Get(i)
        if p.%Get("contractStatus")="retired" continue
        set p.weeklyWage=##class(Rugby.Service.Payroll).Reference(p,##class(Rugby.Service.Store).ManagedClub()),p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage)
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    set ^RugbyWorld(game,"salaryBalanceVersion")=..#VERSION,report.treasury=##class(Rugby.Service.OpeningTreasury).Initialize()
    quit report
}
ClassMethod Club(c As %DynamicObject) As %DynamicObject
{
    if c.%Get("salaryBalanceVersion")=..#VERSION quit {"clubId":(c.id),"adjusted":false}
    set s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),payroll=##class(Rugby.Service.Payroll).Summary(c.id,0),totals=##class(Rugby.Service.MonthlyPayroll).Totals(c.id),wages=totals.players+totals.staff+totals.director
    set operating=payroll.annualRegistrations+payroll.annualTravelReserve,target=$select(forecast.projectedIncome*.98>operating:((forecast.projectedIncome*.98)-operating)/12,1:0),factor=$select(wages>0:##class(Rugby.Simulation.Engine).Clamp(target/wages,0,1),1:1)
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),staff=##class(Rugby.Service.Store).Get("TechnicalStaff",c.id),baseStaff=0,newStaff=0
    for j=0:1:players.%Size()-1 {
        set p=players.%Get(j),old=##class(Rugby.Service.MonthlyPayroll).Value(p),p.salaryBeforeAdjustment=old,p.salaryEffectiveDay=c.day,p.monthlyWage=(old*factor)\100*100,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage)
        if p.%IsDefined("seniorWeeklyWage") set p.seniorWeeklyWage=((p.seniorWeeklyWage*factor)\100)*100
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    for j=0:1:staff.coachIds.%Size()-1 {
        set p=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(j)),old=##class(Rugby.Service.MonthlyPayroll).Value(p),baseStaff=baseStaff+##class(Rugby.Service.MonthlyPayroll).BaseStaff(p.role,p.quality,c.id),p.salaryBeforeAdjustment=old,p.salaryEffectiveDay=c.day,p.monthlyWage=(old*factor)\100*100,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),newStaff=newStaff+p.monthlyWage
        do ##class(Rugby.Service.Store).Put("Coach",p)
    }
    set directorQuality=o.director.%Get("quality",35),directorBase=##class(Rugby.Service.MonthlyPayroll).BaseDirector(directorQuality,c.id),directorWage=##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(directorQuality,c.id)*factor
    if o.director.%Get("id")'="" {
        set old=##class(Rugby.Service.MonthlyPayroll).Value(o.director),o.director.salaryBeforeAdjustment=old,o.director.salaryEffectiveDay=c.day,o.director.monthlyWage=(old*factor)\100*100,o.director.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(o.director.monthlyWage),directorWage=o.director.monthlyWage
    }
    set c.salaryPlayerFactor=c.%Get("salaryPlayerFactor",1)*factor,c.salaryStaffFactor=$select(baseStaff>0:newStaff/baseStaff,1:factor),c.salaryDirectorFactor=$select(directorBase>0:directorWage/directorBase,1:factor),c.salaryAnnualIncome=forecast.projectedIncome,c.salaryBalanceVersion=..#VERSION,c.salaryBalanceDate=c.date
    do ##class(Rugby.Service.Store).Put("Club",c)
    for j=0:1:o.candidates.%Size()-1 { set candidate=o.candidates.%Get(j),candidate.monthlyWage=##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(candidate.quality,c.id),candidate.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(candidate.monthlyWage) }
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    set updated=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)
    quit {"clubId":(c.id),"adjusted":true,"factor":(factor),"annualIncome":(updated.projectedIncome),"previousAnnualCosts":(forecast.projectedCosts),"annualCosts":(updated.projectedCosts),"annualMargin":(updated.projectedMargin)}
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Ajustando los salarios a los ingresos previstos.")
    try {
        tstart
        set %RugbyGame="template",%RugbyManagedClub="c1"
        do reports.%Push(..Initialize())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Initialize()) }
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
