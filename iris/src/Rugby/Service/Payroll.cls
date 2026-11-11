Class Rugby.Service.Payroll Extends %RegisteredObject
{
Parameter VERSION = "3.0.0";
Parameter MARKETLIMIT = 3;
ClassMethod Active() As %Boolean { quit $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"payrollVersion"))=..#VERSION }
ClassMethod Budget(club As %String) As %Integer { quit ##class(Rugby.Service.Finance).Funding(##class(Rugby.Service.Store).Get("Club",club)) }
ClassMethod AnnualCap(club As %String) As %Integer
{
    set funding=..Budget(club),reference=##class(Rugby.Service.Finance).Budget(##class(Rugby.Service.Store).Get("Club",club)),room=+$justify((reference*.85)-(funding*.18)-(reference*.03)-1650000,0,0),limit=+$justify(reference*.65,0,0)
    if ##class(Rugby.Service.MonthlyPayroll).Active() { set t=##class(Rugby.Service.MonthlyPayroll).Totals(club),director=$select(t.director>0:t.director,1:##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(35,club)),room=+$justify((reference*.85)-((t.staff+director)*12)-(reference*.03)-1650000,0,0) }
    quit $select(room<limit:room,1:limit)
}
ClassMethod WeeklyCap(club As %String) As %Integer { quit (..AnnualCap(club)\$select(##class(Rugby.Service.MonthlyPayroll).Active():5200,1:5300))*100 }
ClassMethod StaffWage(role As %String, quality As %Numeric, club As %String) As %Integer
{
    quit ##class(Rugby.Service.MonthlyPayroll).Weekly(##class(Rugby.Service.MonthlyPayroll).StaffMonthly(role,quality,club))
}
ClassMethod DirectorWage(quality As %Numeric, club As %String) As %Integer
{
    quit ##class(Rugby.Service.MonthlyPayroll).Weekly(##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(quality,club))
}
ClassMethod TrainingCost(raw As %Numeric, club As %String) As %Integer
{
    quit 0
}
ClassMethod Weight(p As %DynamicObject) As %Numeric
{
    set avg=##class(Rugby.Service.Development).Average(p)
    quit avg*avg
}
ClassMethod Monthly(weekly As %Numeric) As %Integer { quit +$justify(weekly*52/12,0,0) }
ClassMethod Band(c As %DynamicObject, category As %String = "senior") As %DynamicObject
{
    set rank=c.%Get("qualityReferenceRank",5),tier="elite",low=30000,high=110000
    if category="academy" { set tier="academy",low=3000,high=10000 }
    elseif c.competitionId=416 {
        if rank<=3 { set tier="honor-high",low=85000,high=240000 }
        elseif rank<=7 { set tier="honor-middle",low=80000,high=200000 }
        else { set tier="honor-low",low=45000,high=140000 }
    }
    // Whole-euro weekly wages stay inside the monthly band after conversion.
    quit {"tier":(tier),"monthlyMin":(low),"monthlyMax":(high),"weeklyMin":(((low*12+5199)\5200)*100),"weeklyMax":(((high*12)\5200)*100)}
}
ClassMethod Reference(p As %DynamicObject, club As %String, category As %String = "senior") As %Integer
{
    set c=##class(Rugby.Service.Store).Get("Club",club),band=..Band(c,category),avg=c.%Get($select(category="academy":"qualityAcademyTarget",1:"qualitySeniorTarget"),60),score=##class(Rugby.Simulation.Engine).Clamp((##class(Rugby.Service.Development).Average(p)-avg+10)/20,0,1)
    quit (band.weeklyMin+((band.weeklyMax-band.weeklyMin)*(score**1.35)))\100*100
}
ClassMethod Used(club As %String, excluding As %String = "") As %Integer
{
    set all=##class(Rugby.Service.Store).All("Player","clubId",club),total=0
    for i=0:1:all.%Size()-1 { set p=all.%Get(i) if p.id'=excluding set total=total+p.weeklyWage }
    quit total
}
ClassMethod CanPay(club As %String, pid As %String, wage As %Integer) As %Boolean
{
    quit (..Used(club,pid)+wage)<=..WeeklyCap(club)
}
ClassMethod MedicalWeeklyCap(club As %String) As %Integer
{
    set c=##class(Rugby.Service.Store).Get("Club",club),budget=##class(Rugby.Service.Finance).Budget(c),t=##class(Rugby.Service.MonthlyPayroll).Totals(club),director=$select(t.director>0:t.director,1:##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(35,club)),room=(budget*.9)-((t.staff+director)*12)-(budget*.03)-1650000,limit=budget*.7,annual=$select(room<limit:room,1:limit)
    quit (annual\5200)*100
}
ClassMethod CanPayMedical(club As %String, pid As %String, wage As %Integer) As %Boolean
{
    quit (..Used(club,pid)+wage)<=..MedicalWeeklyCap(club)
}
ClassMethod Check(club As %String, pid As %String, wage As %Integer)
{
    if ..Active()&&('..CanPay(club,pid,wage)) do ##class(Rugby.Service.Store).Fail(409,"PAYROLL_LIMIT","El salario supera el margen mensual disponible de "_$justify(..Monthly(..WeeklyCap(club)-..Used(club,pid))/100,0,0)_" €. Reduce la oferta o libera masa salarial.")
}
ClassMethod Market(role As %String = "") As %DynamicArray
{
    set all=##class(Rugby.Service.Store).All("Coach","clubId",""),club=##class(Rugby.Service.Store).ManagedClub(),items=[],roles=##class(Rugby.Service.Staff).Roles(),valid=role=""
    for i=0:1:roles.%Size()-1 { if roles.%Get(i).id=role set valid=1 }
    if 'valid do ##class(Rugby.Service.Store).Fail(422,"STAFF_ROLE","Especialidad de entrenador desconocida.")
    for i=0:1:all.%Size()-1 {
        set p=all.%Get(i)
        if (role'="")&&(p.role'=role) continue
        if ..Active() set p.weeklyWage=..StaffWage(p.role,p.quality,club)
        set p.monthlyWage=##class(Rugby.Service.MonthlyPayroll).StaffMonthly(p.role,p.quality,club)
        set ordered(-p.quality,p.name,p.id)=p
    }
    set quality=""
    for { set quality=$order(ordered(quality)) quit:quality=""  set name="" for { set name=$order(ordered(quality,name)) quit:name=""  set id="" for { set id=$order(ordered(quality,name,id)) quit:id=""  do items.%Push(ordered(quality,name,id)) } } }
    quit ..Shortlist(items)
}
ClassMethod Shortlist(all As %DynamicArray) As %DynamicArray
{
    set selected={},tiers={},counts={},result=[]
    // Keep one candidate per quality band before filling any remaining places.
    for i=0:1:all.%Size()-1 {
        set p=all.%Get(i),tier=p.role_"-"_$select(p.quality<55:1,p.quality<75:2,1:3)
        if selected.%IsDefined(p.id)||(tiers.%Get(tier,0)>=1) continue
        do selected.%Set(p.id,1),tiers.%Set(tier,tiers.%Get(tier,0)+1),counts.%Set(p.role,counts.%Get(p.role,0)+1)
    }
    for i=0:1:all.%Size()-1 {
        set p=all.%Get(i)
        if selected.%IsDefined(p.id)||(counts.%Get(p.role,0)>=..#MARKETLIMIT) continue
        do selected.%Set(p.id,1),counts.%Set(p.role,counts.%Get(p.role,0)+1)
    }
    for i=0:1:all.%Size()-1 { set p=all.%Get(i) if selected.%IsDefined(p.id) { do result.%Push(p),selected.%Remove(p.id) } }
    quit result
}
ClassMethod Summary(club As %String) As %DynamicObject
{
    set all=##class(Rugby.Service.Store).All("Player","clubId",club),senior=0,academy=0
    for i=0:1:all.%Size()-1 { set p=all.%Get(i) if p.category="academy" { set academy=academy+p.weeklyWage } else { set senior=senior+p.weeklyWage } }
    set b=##class(Rugby.Service.Finance).Budget(##class(Rugby.Service.Store).Get("Club",club)),weekly=senior+academy,coaches=##class(Rugby.Service.Staff).View(club),o=##class(Rugby.Service.Finance).Office(club),plan=##class(Rugby.Service.Store).Get("TrainingPlan",club),annual=weekly*53,reference=b,other=(coaches.weeklyWage+o.director.%Get("weeklyWage",0))*53+(reference*.03)+1650000
    if ##class(Rugby.Service.MonthlyPayroll).Active() {
        set t=##class(Rugby.Service.MonthlyPayroll).Totals(club),annual=t.players*12,other=((t.staff+t.director)*12)+(reference*.03)+1650000
        quit {"budget":(b),"budgetReference":(reference),"weeklyLimit":(..WeeklyCap(club)),"weeklyPlayers":(weekly),"weeklyAvailable":(..WeeklyCap(club)-weekly),"monthlyLimit":(..AnnualCap(club)/12),"monthlyPlayers":(t.players),"monthlyStaff":(t.staff),"monthlyDirector":(t.director),"monthlyAvailable":((..AnnualCap(club)/12)-t.players),"annualPlayers":(annual),"annualSenior":(t.senior*12),"annualAcademy":(t.academy*12),"annualStaff":(t.staff*12),"annualDirector":(t.director*12),"annualTraining":0,"annualRegistrations":(+$justify(reference*.03,0,0)),"annualTravelReserve":1650000,"annualSafetyReserve":(+$justify(b*.15,0,0)),"annualProjectedCosts":(annual+other),"annualMargin":(b-annual-other),"weeks":52,"paymentsPerYear":12,"payPeriod":"monthly","modelVersion":(..#VERSION)}
    }
    quit {"budget":(b),"budgetReference":(reference),"weeklyLimit":(..WeeklyCap(club)),"weeklyPlayers":(weekly),"weeklyAvailable":(..WeeklyCap(club)-weekly),"annualPlayers":(annual),"annualSenior":(senior*53),"annualAcademy":(academy*53),"annualStaff":(coaches.weeklyWage*53),"annualDirector":(o.director.%Get("weeklyWage",0)*53),"annualTraining":0,"annualRegistrations":(+$justify(reference*.03,0,0)),"annualTravelReserve":1650000,"annualSafetyReserve":(+$justify(b*.15,0,0)),"annualProjectedCosts":(annual+other),"annualMargin":(b-annual-other),"weeks":53,"modelVersion":(..#VERSION)}
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"clubs":[],"players":0}
    set report.trainingCostAdjustments=..RemoveTrainingCosts()
    if ..Active() quit report
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),all=##class(Rugby.Service.Store).All("Player","clubId",c.id),changes=[],target=(..WeeklyCap(c.id)*.95)\100,minimum=0,preferred=0,entries={},ranges={}
        for j=0:1:all.%Size()-1 {
            set p=all.%Get(j),quality=##class(Rugby.Service.Development).Average(p),r=ranges.%Get(p.category)
            if '$isobject(r) { set r={"min":(quality),"max":(quality)} do ranges.%Set(p.category,r) }
            if quality<r.min set r.min=quality
            if quality>r.max set r.max=quality
        }
        for j=0:1:all.%Size()-1 {
            set p=all.%Get(j),band=..Band(c,p.category),r=ranges.%Get(p.category),score=$select(r.max>r.min:(##class(Rugby.Service.Development).Average(p)-r.min)/(r.max-r.min),1:(.15+(##class(Rugby.Service.Rivals).Hash(p.id,17341)#71)/100)),lo=band.weeklyMin\100,hi=band.weeklyMax\100,desired=lo+(((hi-lo)*(score**1.35))\1)
            do entries.%Set(p.id,{"floor":(lo),"increment":(desired-lo)})
            set minimum=minimum+lo,preferred=preferred+desired
        }
        // Keep the band floors; compress only quality premiums when the roster needs it.
        if (minimum>target)&&(minimum<(..WeeklyCap(c.id)\100)) set target=(..WeeklyCap(c.id)*.995)\100
        set total=$select(preferred<target:preferred,1:target),total=$select(total<minimum:minimum,1:total),pool=total-minimum,weight=preferred-minimum,cumulative=0,assigned=0
        for j=0:1:all.%Size()-1 {
            set p=all.%Get(j),entry=entries.%Get(p.id),cumulative=cumulative+entry.increment,units=$select(weight>0:(pool*cumulative/weight)\1,1:0),wage=(entry.floor+units-assigned)*100,assigned=units,old=p.weeklyWage,p.weeklyWage=wage,p.payrollVersion=..#VERSION
            if p.category="academy" set p.seniorWeeklyWage=..Reference(p,c.id,"senior")
            do ##class(Rugby.Service.Store).Put("Player",p)
            set contract={"id":("payroll-"_..#VERSION_"-"_p.id),"clubId":(c.id),"playerId":(p.id),"kind":"salaryAdjustment","day":(c.day),"date":(c.date),"previousWeeklyWage":(old),"weeklyWage":(wage),"contractEndDate":(p.contractEndDate),"fee":0,"modelVersion":(..#VERSION)}
            do ##class(Rugby.Service.Store).Put("PlayerContract",contract),changes.%Push(contract)
            set report.players=report.players+1
        }
        set staff=##class(Rugby.Service.Staff).View(c.id),staffChanges=[]
        for j=0:1:staff.coaches.%Size()-1 { set coach=staff.coaches.%Get(j),old=coach.weeklyWage,expected=..StaffWage(coach.role,coach.quality,c.id) if old'=expected { set coach.weeklyWage=expected do ##class(Rugby.Service.Store).Put("Coach",coach),staffChanges.%Push({"coachId":(coach.id),"previousWeeklyWage":(old),"weeklyWage":(coach.weeklyWage)}) } }
        set o=##class(Rugby.Service.Finance).Office(c.id),changed=0
        for j=0:1:o.candidates.%Size()-1 { set candidate=o.candidates.%Get(j),expected=..DirectorWage(candidate.quality,c.id) if candidate.weeklyWage'=expected set candidate.weeklyWage=expected,changed=1 }
        if o.director.%Get("id")'="" { set expected=..DirectorWage(o.director.quality,c.id) if o.director.weeklyWage'=expected set o.director.weeklyWage=expected,changed=1 }
        if changed do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
        set plan=##class(Rugby.Service.Store).Get("TrainingPlan",c.id),raw=0
        // Training is covered by employee salaries; no per-session charge.
        set expected=..TrainingCost(raw,c.id)
        if (plan.%Get("rawDailyCost",-1)'=raw)||(plan.dailyCost'=expected) { set plan.rawDailyCost=raw,plan.dailyCost=expected,plan.payrollVersion=..#VERSION do ##class(Rugby.Service.Store).Put("TrainingPlan",plan) }
        do report.clubs.%Push({"clubId":(c.id),"playerAdjustments":(changes),"staffAdjustments":(staffChanges),"financialOffice":(o),"trainingPlan":(plan),"summary":(..Summary(c.id))})
    }
    set free=##class(Rugby.Service.Store).All("Player","clubId","")
    for i=0:1:free.%Size()-1 {
        set p=free.%Get(i)
        if p.%Get("contractStatus")="retired" continue
        if p.weeklyWage>0 set p.weeklyWage=..Reference(p,"c1")
        set p.payrollVersion=..#VERSION
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    set ^RugbyWorld(game,"payrollVersion")=..#VERSION
    quit report
}
ClassMethod RemoveTrainingCosts() As %DynamicArray
{
    set plans=##class(Rugby.Service.Store).All("TrainingPlan"),changes=[]
    for i=0:1:plans.%Size()-1 {
        set plan=plans.%Get(i)
        if (plan.%Get("dailyCost",0)=0)&&(plan.%Get("rawDailyCost",0)=0) continue
        do changes.%Push({"clubId":(plan.clubId),"previousDailyCost":(plan.%Get("dailyCost",0)),"previousRawDailyCost":(plan.%Get("rawDailyCost",0)),"dailyCost":0})
        set plan.dailyCost=0,plan.rawDailyCost=0
        do ##class(Rugby.Service.Store).Put("TrainingPlan",plan)
    }
    quit changes
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Ajustando salarios.")
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
