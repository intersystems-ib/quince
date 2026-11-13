Class Rugby.Service.SeasonCalendar Extends %RegisteredObject
{
ClassMethod Day(date As %String) As %Integer { quit $zdateh(date,3)-$zdateh("2026-11-07",3) }
ClassMethod CloseDay(year As %Integer) As %Integer { quit ..Day((year+1)_"-06-30") }
ClassMethod Summer(date As %String) As %Boolean { quit $listfind($listbuild(7,8),+$piece(date,"-",2))>0 }
ClassMethod Reserved(date As %String) As %Boolean { quit ..Summer(date)||($extract(date,6,10)="06-30")||($extract(date,6,10)="09-01") }
ClassMethod Events(club As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    set c=##class(Rugby.Service.Store).Get("Club",club),all=##class(Rugby.Service.Store).All("Competition"),years={},items=[],game=##class(Rugby.Service.Store).Game()
    for i=0:1:all.%Size()-1 { do years.%Set(all.%Get(i).year,1) }
    do years.%Set(##class(Rugby.Service.Competition).Year(c.date),1)
    set it=years.%GetIterator()
    while it.%GetNext(.year,.value) {
        for kind="opening","closure" {
            set date=$select(kind="opening":year_"-09-01",1:(year+1)_"-06-30"),done=$select(kind="opening":date<=c.date,1:$data(^RugbyWorld(game,"seasonClosures",year))>0)
            set event={"id":(kind_"-"_year),"type":(kind),"seasonYear":(+year),"date":(date),"day":(..Day(date)),"title":($select(kind="opening":"Apertura de temporada",1:"Cierre de temporada"))}
            do event.%Set("completed",done,"boolean"),items.%Push(event)
        }
    }
    quit {"items":(items)}
}
ClassMethod Open(day As %Integer) As %DynamicObject
{
    set date=##class(Rugby.Service.Injuries).Date(day),year=+$piece(date,"-",1),game=##class(Rugby.Service.Store).Game(),result={"opened":false}
    if $extract(date,6,10)'="09-01" quit result
    if $data(^RugbyWorld(game,"seasonOpenings",year)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"seasonOpenings",year))
    set result={"opened":true,"seasonYear":(year),"date":(date),"day":(day)},^RugbyWorld(game,"seasonOpenings",year)=result.%ToJSON()
    quit result
}
ClassMethod NextDay(c As %DynamicObject) As %Integer
{
    if '..Summer(c.date)&&($extract(c.date,6,10)'="06-30") quit c.day+1
    set year=+$piece(c.date,"-",1)-1,game=##class(Rugby.Service.Store).Game()
    if '$data(^RugbyWorld(game,"seasonClosures",year)) {
        set closure=##class(Rugby.Service.Seasons).Tick(c.day)
        if 'closure.closed do ##class(Rugby.Service.Store).Fail(409,"SEASON_PENDING","Hay competiciones pendientes de finalizar antes de cerrar la temporada.")
    }
    quit ..Day((year+1)_"-09-01")
}
ClassMethod Rest(from As %Integer, target As %Integer) As %DynamicObject
{
    set clubs=##class(Rugby.Service.Store).All("Club"),report={"from":(##class(Rugby.Service.Injuries).Date(from+1)),"through":(##class(Rugby.Service.Injuries).Date(target-1)),"skippedDays":(target-from-1),"monthlyPayroll":[],"cancelledFixtures":[]}
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),paid=##class(Rugby.Service.MonthlyPayroll).Tick(c.id,target-1),c=##class(Rugby.Service.Store).Get("Club",c.id),c.day=target-1,c.date=##class(Rugby.Service.Injuries).Date(c.day),c.aiLastDay=target-1
        do ##class(Rugby.Service.Store).Put("Club",c),report.monthlyPayroll.%Push({"clubId":(c.id),"payments":(paid)})
        set players=##class(Rugby.Service.Store).All("Player","clubId",c.id)
        for j=0:1:players.%Size()-1 {
            set p=players.%Get(j),p.energy=##class(Rugby.Simulation.Engine).Clamp(p.energy+((target-from-1)*4),0,100),p.age=(c.day-p.birthDay)\365,p.moraleLastDay=c.day,recovered=##class(Rugby.Service.Injuries).Recover(p,c.day)
            do ##class(Rugby.Service.Store).Put("Player",p)
            if recovered do ##class(Rugby.Service.Management).ReturnToBench(p)
        }
        do ##class(Rugby.Service.Management).RefreshAvailability(c.id)
    }
    // Legacy friendlies in the summer break are cancelled, never silently simulated.
    set fixtures=##class(Rugby.Service.Store).All("Fixture")
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i)
        if (f.day>from)&&(f.day<target)&&(f.status'="finished")&&('f.%Get("archived",0)) {
            set f.status="cancelled",f.archived=1,f.cancellationReason="summerBreak"
            do ##class(Rugby.Service.Store).Put("Fixture",f),report.cancelledFixtures.%Push(f.id)
        }
    }
    quit report
}
}
