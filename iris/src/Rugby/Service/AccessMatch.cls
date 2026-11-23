Class Rugby.Service.AccessMatch Extends %RegisteredObject
{
ClassMethod Date(year As %Integer) As %String
{
    set latest=0
    for division=1401,1402 {
        set comp=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-"_year,0)
        if $isobject(comp) { set day=$zdateh(comp.finalDate,3) if day>latest set latest=day }
    }
    if latest=0 quit ""
    set target=latest+7,close=$zdateh((year+1)_"-06-30",3)
    // Keep legacy schedules that placed the league final late in June playable before closure.
    if target>=close set target=close-1
    quit $zdate(target,3)
}
ClassMethod Find(year As %Integer) As %DynamicObject
{
    quit ##class(Rugby.Service.Store).Get("Fixture","league-1401-"_year_"-access-1",0)
}
ClassMethod Ensure(year As %Integer) As %DynamicObject
{
    set old=..Find(year)
    if $isobject(old) quit old
    if $data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seasonClosures",year)) quit ""
    set top=##class(Rugby.Service.Store).Get("Competition","league-1401-"_year,0),pro=##class(Rugby.Service.Store).Get("Competition","league-1402-"_year,0)
    if ('$isobject(top))||('$isobject(pro)) quit ""
    if (pro.%Get("runnerUpId")="")||(top.regularOrder.%Size()'=14) quit ""
    set home=pro.runnerUpId,away=top.regularOrder.%Get(12),date=..Date(year),own=##class(Rugby.Service.Store).ManagedClub(),id=top.id_"-access-1"
    set f={"id":(id),"clubId":($select((own=home)||(own=away):own,1:home)),"competitionKey":(top.id),"competitionType":"access","divisionId":1401,"season":(top.season),"stage":"access","round":(top.%Get("regularRounds",26)+4),"slot":1,"homeId":(home),"awayId":(away),"date":(date),"day":(##class(Rugby.Service.SeasonCalendar).Day(date)),"status":"scheduled","matchId":"","seed":(1+(##class(Rugby.Service.Rivals).Hash(id,top.drawSeed)#2147483646))}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set top.accessMatchId=id,top.accessDate=date,pro.accessMatchId=id,pro.accessDate=date
    do ##class(Rugby.Service.Store).Put("Competition",top),##class(Rugby.Service.Store).Put("Competition",pro)
    quit f
}
ClassMethod Sync(day As %Integer)
{
    set year=##class(Rugby.Service.Seasons).Year(),f=..Ensure(year)
    if '$isobject(f) quit
    if (f.status="scheduled")&&(f.day<=day)&&(f.homeId'=##class(Rugby.Service.Store).ManagedClub())&&(f.awayId'=##class(Rugby.Service.Store).ManagedClub()) do ##class(Rugby.Service.Competition).Simulate(f)
}
ClassMethod View(comp As %DynamicObject)
{
    if '##class(Rugby.Service.Leagues).French(comp.divisionId) quit
    set f=..Find(comp.year),comp.accessDate=..Date(comp.year),comp.accessEnabled=('$data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seasonClosures",comp.year)))||$isobject(f)
    if $isobject(f) set f.scorers=##class(Rugby.Service.MatchStatistics).Scorers(f.id)
    do comp.%Set("accessMatch",$select($isobject(f):f,1:""))
}
}
