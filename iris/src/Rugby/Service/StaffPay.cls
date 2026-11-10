Class Rugby.Service.StaffPay Extends %RegisteredObject
{
Parameter VERSION = "2.0.0";
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"adjustments":[]}
    if $get(^RugbyWorld(game,"staffPayVersion"))=..#VERSION quit report
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),totals=##class(Rugby.Service.MonthlyPayroll).Totals(c.id),budget=##class(Rugby.Service.Finance).Budget(c),director=$select(totals.director>0:totals.director,1:##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(35,c.id)),room=((budget*.85)-(budget*.03)-1650000)/12-totals.players-director-totals.staff,scale=$select(totals.staff>0:##class(Rugby.Simulation.Engine).Clamp(room/(totals.staff*.25),0,1),1:0),staff=##class(Rugby.Service.Store).Get("TechnicalStaff",c.id)
        for j=0:1:staff.coachIds.%Size()-1 {
            set p=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(j))
            if p.%Get("staffPayVersion")=..#VERSION continue
            set old=##class(Rugby.Service.MonthlyPayroll).Value(p),p.monthlyWage=old+((old*.25*scale)\100*100),p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),p.salaryBeforeAdjustment=old,p.salaryEffectiveDay=c.day,p.staffPayVersion=..#VERSION
            do ##class(Rugby.Service.Store).Put("Coach",p)
            if p.monthlyWage>old {
                set contract={"id":("staff-pay-"_..#VERSION_"-"_p.id),"clubId":(c.id),"coachId":(p.id),"role":(p.role),"quality":(p.quality),"kind":"salaryAdjustment","previousMonthlyWage":(old),"monthlyWage":(p.monthlyWage),"weeklyWage":(p.weeklyWage),"payPeriod":"monthly","day":(c.day),"date":(c.date),"fee":0}
                do ##class(Rugby.Service.Store).Put("StaffContract",contract),report.adjustments.%Push(contract)
            }
        }
    }
    set ^RugbyWorld(game,"staffPayVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando salarios técnicos.")
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
