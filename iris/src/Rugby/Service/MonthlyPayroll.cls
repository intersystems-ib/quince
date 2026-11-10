Class Rugby.Service.MonthlyPayroll Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Active() As %Boolean { quit $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"monthlyPayrollVersion"))=..#VERSION }
ClassMethod Value(p As %DynamicObject) As %Integer { quit p.%Get("monthlyWage",##class(Rugby.Service.Payroll).Monthly(p.%Get("weeklyWage",0))) }
ClassMethod Weekly(monthly As %Numeric) As %Integer { quit +$justify(monthly*12/52,0,0) }
ClassMethod Days(date As %String) As %Integer
{
    set year=+$piece(date,"-",1),month=+$piece(date,"-",2),next=$select(month=12:(year+1)_"-01-01",1:year_"-"_$select(month+1<10:"0",1:"")_(month+1)_"-01")
    quit $zdateh(next,3)-$zdateh($extract(date,1,7)_"-01",3)
}
ClassMethod BaseStaff(role As %String, quality As %Numeric, club As %String) As %Numeric
{
    set c=##class(Rugby.Service.Store).Get("Club",club),roles=##class(Rugby.Service.Staff).Roles(),weight=80000,total=0
    for i=0:1:roles.%Size()-1 { set r=roles.%Get(i),total=total+r.baseWeeklyWage if r.id=role set weight=r.baseWeeklyWage }
    quit ##class(Rugby.Service.Finance).Budget(c)*.225/12*weight/total*##class(Rugby.Service.Staff).Multiplier(quality)
}
ClassMethod BaseDirector(quality As %Numeric, club As %String) As %Numeric
{
    quit ##class(Rugby.Service.Finance).Budget(##class(Rugby.Service.Store).Get("Club",club))*.03/12*(20000+(quality*500))/70000
}
ClassMethod PlayerTotal(club As %String) As %Integer
{
    set all=##class(Rugby.Service.Store).All("Player","clubId",club),total=0
    for i=0:1:all.%Size()-1 { set total=total+..Value(all.%Get(i)) }
    quit total
}
ClassMethod Factor(club As %String) As %Numeric
{
    set c=##class(Rugby.Service.Store).Get("Club",club),b=##class(Rugby.Service.Finance).Budget(c),staff=##class(Rugby.Service.Store).Get("TechnicalStaff",club),base=0
    for i=0:1:staff.coachIds.%Size()-1 { set p=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(i)),base=base+..BaseStaff(p.role,p.quality,club) }
    set office=##class(Rugby.Service.Finance).Office(club),base=base+..BaseDirector(office.director.%Get("quality",35),club),room=(b*.85)-(..PlayerTotal(club)*12)-(b*.03)-1650000
    quit $select(base>0:##class(Rugby.Simulation.Engine).Clamp(room/(12*base),.25,1),1:1)
}
ClassMethod StaffMonthly(role As %String, quality As %Numeric, club As %String) As %Integer { quit +$justify(..BaseStaff(role,quality,club)*..Factor(club)/100,0,0)*100 }
ClassMethod DirectorMonthly(quality As %Numeric, club As %String) As %Integer { quit +$justify(..BaseDirector(quality,club)*..Factor(club)/100,0,0)*100 }
ClassMethod Totals(club As %String) As %DynamicObject
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),senior=0,academy=0,staff=0,t=##class(Rugby.Service.Store).Get("TechnicalStaff",club)
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.category="academy" { set academy=academy+..Value(p) } else { set senior=senior+..Value(p) } }
    for i=0:1:t.coachIds.%Size()-1 { set staff=staff+..Value(##class(Rugby.Service.Store).Get("Coach",t.coachIds.%Get(i))) }
    set o=##class(Rugby.Service.Finance).Office(club),director=$select(o.director.%Get("id")'="":..Value(o.director),1:0)
    quit {"senior":(senior),"academy":(academy),"players":(senior+academy),"staff":(staff),"director":(director)}
}
ClassMethod CanHire(club As %String, role As %String, monthly As %Integer) As %Boolean
{
    set c=##class(Rugby.Service.Store).Get("Club",club),totals=..Totals(club),old=0,t=##class(Rugby.Service.Store).Get("TechnicalStaff",club)
    if role="finance" { set old=totals.director }
    else { for i=0:1:t.coachIds.%Size()-1 { set p=##class(Rugby.Service.Store).Get("Coach",t.coachIds.%Get(i)) if p.role=role set old=..Value(p) } }
    set reserve=$select((role'="finance")&&(totals.director=0):..DirectorMonthly(35,club),1:0)
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan",club),cost=((totals.players+totals.staff+totals.director-old+monthly+reserve)*12)+(##class(Rugby.Service.Finance).Budget(c)*.03)+1650000
    quit cost<=(##class(Rugby.Service.Finance).Budget(c)*.85)
}
ClassMethod Sync(kind As %String, d As %DynamicObject, previous As %DynamicObject)
{
    if '$listfind($listbuild("Player","Coach"),kind) quit
    if '..Active() quit
    if 'd.%IsDefined("monthlyWage") { set d.monthlyWage=##class(Rugby.Service.Payroll).Monthly(d.weeklyWage) }
    elseif $isobject(previous)&&(d.weeklyWage'=previous.%Get("weeklyWage"))&&(d.monthlyWage=previous.%Get("monthlyWage")) { set d.monthlyWage=##class(Rugby.Service.Payroll).Monthly(d.weeklyWage) }
    if $isobject(previous) { if (d.%Get("clubId")'=previous.%Get("clubId"))&&(d.%Get("clubId")'="") do d.%Remove("payrollStartDay") }
    if 'd.%IsDefined("payrollStartDay") {
        set club=d.%Get("clubId"),c=##class(Rugby.Service.Store).Get("Club",$select(club'="":club,1:##class(Rugby.Service.Store).ManagedClub()))
        set d.payrollStartDay=d.%Get("signedDay",c.day)
    }
    set d.monthlyPayrollVersion=..#VERSION
}
ClassMethod Adopt(c As %DynamicObject)
{
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"monthlyPayroll",c.id)) quit
    set o=##class(Rugby.Service.Finance).Office(c.id),last=c.%Get("startDay",c.day),movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id),players=0
    for i=0:1:movements.%Size()-1 { set m=movements.%Get(i) if (m.type="wages")&&(m.day>last) set last=m.day }
    for day=last+1:1:c.day {
        set execution=##class(Rugby.Service.Store).Get("TrainingExecution",c.id_"-day"_day,0)
        if $isobject(execution) { set players=players+(execution.playerWeeklyWages/7) }
        else { set players=players+(..PlayerTotal(c.id)*12/52/7) }
    }
    set fresh=(c.day=c.%Get("startDay",c.day)),state={"lastDay":(c.day-$select(fresh:1,1:0)),"adoptedDay":(c.day),"wages":(players),"staffWages":(c.%Get("staffPayrollAccrued",0)),"financeWages":(o.%Get("salaryAccrued",0)),"version":(..#VERSION)}
    set ^RugbyWorld(game,"monthlyPayroll",c.id)=state.%ToJSON()
    if c.%Get("staffPayrollAccrued",0)'=0 { set c.staffPayrollAccrued=0 do ##class(Rugby.Service.Store).Put("Club",c) }
    if o.%Get("salaryAccrued",0)'=0 { set o.salaryAccrued=0 do ##class(Rugby.Service.Store).Put("FinancialOffice",o) }
}
ClassMethod DailyTotals(club As %String, day As %Integer) As %DynamicObject
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),wages=0,staff=0,t=##class(Rugby.Service.Store).Get("TechnicalStaff",club),date=##class(Rugby.Service.Injuries).Date(day)
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if (p.%Get("payrollStartDay",p.%Get("signedDay",day))<=day)&&((p.%Get("contractEndDate")="")||(p.contractEndDate'<date)) set wages=wages+..Value(p) }
    for i=0:1:t.coachIds.%Size()-1 { set p=##class(Rugby.Service.Store).Get("Coach",t.coachIds.%Get(i)) if p.%Get("payrollStartDay",day)<=day set staff=staff+$select(day<p.%Get("salaryEffectiveDay",day):p.%Get("salaryBeforeAdjustment",..Value(p)),1:..Value(p)) }
    set o=##class(Rugby.Service.Finance).Office(club),director=0
    if (o.director.%Get("id")'="")&&(o.director.%Get("payrollStartDay",day)<=day) set director=..Value(o.director)
    quit {"wages":(wages),"staffWages":(staff),"financeWages":(director)}
}
ClassMethod Pay(club As %String, day As %Integer, state As %DynamicObject, report As %DynamicArray)
{
    set game=##class(Rugby.Service.Store).Game(),date=##class(Rugby.Service.Injuries).Date(day),month=$extract(date,1,7)
    if +$piece(date,"-",3)'=..Days(date) quit
    if $data(^RugbyWorld(game,"monthlyPaid",club,month)) quit
    set c=##class(Rugby.Service.Store).Get("Club",club),originalDay=c.day,originalDate=c.date,c.day=day,c.date=date
    for type="wages","staffWages","financeWages" {
        set amount=+$justify(state.%Get(type),0,0),concept=$select(type="wages":"Nómina mensual de jugadores",type="staffWages":"Nómina mensual del cuerpo técnico",1:"Nómina mensual del financiero"),key="monthly-payroll-"_month_"-"_type
        if amount>0 { do ##class(Rugby.Service.Management).Money(c,-amount,type,concept_" "_month,key),report.%Push({"clubId":(club),"date":(date),"type":(type),"amount":(amount),"source":(key)}) }
        do state.%Set(type,state.%Get(type)-amount)
    }
    set c.day=originalDay,c.date=originalDate
    do ##class(Rugby.Service.Store).Put("Club",c)
    set ^RugbyWorld(game,"monthlyPaid",club,month)=1
}
ClassMethod Tick(club As %String, through As %Integer) As %DynamicArray
{
    set report=[]
    if '..Active() quit report
    set c=##class(Rugby.Service.Store).Get("Club",club),game=##class(Rugby.Service.Store).Game()
    do ..Adopt(c)
    set state=##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"monthlyPayroll",club))
    for day=state.lastDay+1:1:through {
        set date=##class(Rugby.Service.Injuries).Date(day),days=..Days(date),totals=..DailyTotals(club,day)
        for type="wages","staffWages","financeWages" { do state.%Set(type,state.%Get(type)+(totals.%Get(type)/days)) }
        set state.lastDay=day
        do ..Pay(club,day,state,report)
    }
    // Adoption on a month end may carry an unpaid portion of the old weekly cycle.
    if (through=state.lastDay)&&(through=state.adoptedDay) do ..Pay(club,through,state,report)
    set ^RugbyWorld(game,"monthlyPayroll",club)=state.%ToJSON()
    quit report
}
ClassMethod Initialize() As %DynamicObject
{
    set report={"gameId":(##class(Rugby.Service.Store).Game()),"version":(..#VERSION),"staff":[],"directors":[],"players":0}
    if ..Active() quit report
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        do ..Adopt(c)
        set all=##class(Rugby.Service.Store).All("Player","clubId",c.id)
        for j=0:1:all.%Size()-1 {
            set p=all.%Get(j),p.monthlyWage=..Value(p),p.payrollStartDay=p.%Get("signedDay",c.%Get("startDay",c.day)),p.monthlyPayrollVersion=..#VERSION
            do ##class(Rugby.Service.Store).Put("Player",p)
            do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":("monthly-"_..#VERSION_"-"_p.id),"clubId":(c.id),"playerId":(p.id),"kind":"payPeriodChange","monthlyWage":(p.monthlyWage),"weeklyWage":(p.weeklyWage),"payPeriod":"monthly","day":(c.day),"date":(c.date),"contractEndDate":(p.contractEndDate),"fee":0})
            set report.players=report.players+1
        }
        set t=##class(Rugby.Service.Store).Get("TechnicalStaff",c.id)
        for j=0:1:t.coachIds.%Size()-1 {
            set p=##class(Rugby.Service.Store).Get("Coach",t.coachIds.%Get(j)),old=..Value(p),p.monthlyWage=..StaffMonthly(p.role,p.quality,c.id),p.weeklyWage=..Weekly(p.monthlyWage),p.payrollStartDay=c.%Get("startDay",c.day),p.monthlyPayrollVersion=..#VERSION,p.staffPayVersion=##class(Rugby.Service.StaffPay).#VERSION
            do ##class(Rugby.Service.Store).Put("Coach",p)
            set contract={"id":("monthly-staff-"_..#VERSION_"-"_p.id),"clubId":(c.id),"coachId":(p.id),"role":(p.role),"quality":(p.quality),"kind":"salaryAdjustment","previousMonthlyWage":(old),"monthlyWage":(p.monthlyWage),"weeklyWage":(p.weeklyWage),"payPeriod":"monthly","day":(c.day),"fee":0}
            do ##class(Rugby.Service.Store).Put("StaffContract",contract),report.staff.%Push(contract)
        }
        set o=##class(Rugby.Service.Finance).Office(c.id)
        for j=0:1:o.candidates.%Size()-1 { set p=o.candidates.%Get(j),p.monthlyWage=..DirectorMonthly(p.quality,c.id),p.weeklyWage=..Weekly(p.monthlyWage) }
        if o.director.%Get("id")'="" {
            set old=..Value(o.director),o.director.monthlyWage=..DirectorMonthly(o.director.quality,c.id),o.director.weeklyWage=..Weekly(o.director.monthlyWage),o.director.payrollStartDay=c.%Get("startDay",c.day)
            do report.directors.%Push({"clubId":(c.id),"directorId":(o.director.id),"previousMonthlyWage":(old),"monthlyWage":(o.director.monthlyWage)})
        }
        set o.payPeriod="monthly"
        do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    }
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"monthlyPayrollVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando las nóminas mensuales.")
    try {
        tstart
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
