Class Rugby.Service.AttributeProgress Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Year(day As %Integer) As %Integer
{
    set date=$zdate(day+$zdateh("2026-11-07",3),3),year=##class(Rugby.Service.Competition).Year(date),closure=$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seasonClosures",year))
    if closure'="" { set closed=##class(%DynamicObject).%FromJSON(closure) if date>closed.closedDate set year=year+1 }
    quit year
}
ClassMethod Record(e As %DynamicObject)
{
    set game=##class(Rugby.Service.Store).Game(),year=e.%Get("seasonYear",..Year(e.day))
    for i=0:1:e.results.%Size()-1 {
        set r=e.results.%Get(i),changes=r.%Get("changes",[])
        if changes.%Size()=0 continue
        set item={"seasonYear":(year),"changes":(changes)}
        do item.%Set("scale",e.%Get("attributeScale",0))
        set ^RugbyWorld(game,"attributeHistory",r.playerId,e.day,e.id)=item.%ToJSON()
    }
}
ClassMethod View(p As %DynamicObject, year As %Integer)
{
    set game=##class(Rugby.Service.Store).Game(),totals={},expected=##class(%DynamicObject).%FromJSON(p.attributes.%ToJSON()),factors={},scale=p.%Get("talentScaleFactor",1),day=""
    // Read only actual sessions, never forecast copies. Walk backwards across legacy scale changes.
    for {
        set day=$order(^RugbyWorld(game,"attributeHistory",p.id,day),-1)
        quit:day=""
        set id=""
        for {
            set id=$order(^RugbyWorld(game,"attributeHistory",p.id,day,id),-1)
            quit:id=""
            set item=##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"attributeHistory",p.id,day,id))
            if item.seasonYear'=year continue
            for i=0:1:item.changes.%Size()-1 {
                set change=item.changes.%Get(i),attr=change.attribute,factor=factors.%Get(attr,1)
                if item.scale>0 { set factor=scale/item.scale }
                elseif (scale<1)&&(factor=1) {
                    set value=##class(Rugby.Simulation.Engine).Clamp(change.after*scale,1,100)-expected.%Get(attr)
                    if (value<.00001)&&(value>(-.00001)) set factor=scale
                }
                set delta=##class(Rugby.Simulation.Engine).Clamp(change.after*factor,1,100)-##class(Rugby.Simulation.Engine).Clamp(change.before*factor,1,100)
                do totals.%Set(attr,totals.%Get(attr,0)+delta),expected.%Set(attr,change.before),factors.%Set(attr,factor)
            }
        }
    }
    set catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:catalog.%Size()-1 { set attr=catalog.%Get(i).id do totals.%Set(attr,+$justify(totals.%Get(attr,0),0,6)) }
    set p.attributeSeasonChanges=totals,p.attributeSeasonYear=year
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"sessions":0}
    if $get(^RugbyWorld(game,"attributeHistoryVersion"))=..#VERSION quit report
    kill ^RugbyWorld(game,"attributeHistory")
    set rows=##class(Rugby.Service.Store).All("TrainingExecution")
    for i=0:1:rows.%Size()-1 { do ..Record(rows.%Get(i)) set report.sessions=report.sessions+1 }
    set ^RugbyWorld(game,"attributeHistoryVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando el progreso de temporada.")
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
