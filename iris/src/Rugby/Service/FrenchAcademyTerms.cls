Class Rugby.Service.FrenchAcademyTerms Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Weight(c As %DynamicObject, p As %DynamicObject) As %Numeric
{
    set age=(c.day-p.birthDay)\365,h=##class(Rugby.Service.Rivals).Hash("academy-terms-"_p.id,17341)
    quit ##class(Rugby.Simulation.Engine).Clamp(70+((age-16)*6)+((##class(Rugby.Service.Development).Average(p)-c.%Get("qualityAcademyTarget",55))*2)+(h#31),40,160)
}
ClassMethod Duration(p As %DynamicObject, day As %Integer) As %Integer
{
    set age=(day-p.birthDay)\365,h=##class(Rugby.Service.Rivals).Hash("academy-duration-"_p.id,17341)
    quit $select(age<=18:2+(h#2),age>=21:1+(h#2),1:1+(h#3))
}
ClassMethod Arrival(c As %DynamicObject, p As %DynamicObject, year As %Integer)
{
    set base=$select(c.competitionId=1401:120000,1:70000),p.monthlyWage=+$justify(base*..Weight(c,p)/100/1000,0,0)*1000,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),p.contractYears=..Duration(p,p.signedDay),p.academyTermsVersion=..#VERSION
    do ##class(Rugby.Service.Seasons).Contract(p,year+p.contractYears-1)
}
ClassMethod Club(c As %DynamicObject) As %Integer
{
    if c.%Get("academyTermsVersion")=..#VERSION quit 0
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),contracts=##class(Rugby.Service.Store).All("PlayerContract","clubId",c.id),negotiations=##class(Rugby.Service.Store).All("Negotiation"),protected={},eligible=[],total=0,weight=0,assigned=0
    for i=0:1:contracts.%Size()-1 { set a=contracts.%Get(i) if $listfind($listbuild("renewal","promotion","signing"),a.%Get("kind")) do protected.%Set(a.playerId,1) }
    for i=0:1:negotiations.%Size()-1 { set n=negotiations.%Get(i) if $listfind($listbuild("open","counteroffer","agreed"),n.status) do protected.%Set(n.playerId,1) }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.category'="academy")||protected.%IsDefined(p.id)||(p.%Get("renewedDay",0)'=0)||(p.%Get("academyTermsVersion")=..#VERSION) continue
        if $zdateh(p.contractEndDate,3)<$zdateh(c.date,3) continue
        set p.academyWeight=..Weight(c,p),weight=weight+p.academyWeight,total=total+##class(Rugby.Service.MonthlyPayroll).Value(p)
        do eligible.%Push(p)
    }
    for i=0:1:eligible.%Size()-1 { set p=eligible.%Get(i),p.newAcademyMonthly=(total*p.academyWeight/weight)\1000*1000,assigned=assigned+p.newAcademyMonthly }
    set remainder=total-assigned,year=##class(Rugby.Service.Seasons).Year(c.id)
    for i=0:1:eligible.%Size()-1 {
        set p=eligible.%Get(i),extra=$select(remainder>1000:1000,1:remainder),remainder=remainder-extra,before=##class(Rugby.Service.MonthlyPayroll).Value(p),oldWeekly=p.weeklyWage,p.monthlyWage=p.newAcademyMonthly+extra,p.weeklyWage=$select(p.monthlyWage=before:oldWeekly,1:##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage)),p.salaryEffectiveDay=c.day,p.salaryBeforeAdjustment=before,p.academyTermsVersion=..#VERSION,p.contractYears=..Duration(p,c.day)
        do p.%Remove("academyWeight"),p.%Remove("newAcademyMonthly"),##class(Rugby.Service.Seasons).Contract(p,year+p.contractYears-1),##class(Rugby.Service.Store).Put("Player",p)
    }
    set c.academyTermsVersion=..#VERSION
    do ##class(Rugby.Service.Store).Put("Club",c)
    quit eligible.%Size()
}
ClassMethod InitializeAll() As %DynamicObject
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),result={"players":0},ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando contratos de cantera.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 {
            set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1"
            if %RugbyGame'="template" set %RugbyManagedClub=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)).clubId
            set clubs=##class(Rugby.Service.Store).All("Club")
            for j=0:1:clubs.%Size()-1 { set c=clubs.%Get(j) if ##class(Rugby.Service.Leagues).French(c.competitionId) set result.players=result.players+..Club(c) }
        }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit result
}
}
