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
    set game=##class(Rugby.Service.Store).Game(),year=e.%Get("seasonYear",..Year(e.day)),ready=$get(^RugbyWorld(game,"attributeTotalsReady")),scale=e.%Get("attributeScale",0)
    if ready&&$data(^RugbyWorld(game,"attributeRecorded",e.id)) quit
    for i=0:1:e.results.%Size()-1 {
        set r=e.results.%Get(i),changes=r.%Get("changes",[])
        if changes.%Size()=0 continue
        if ('ready)||(scale<=0)||($data(^RugbyWorld(game,"attributeHistory",r.playerId))&&('$get(^RugbyWorld(game,"attributeTotalsPlayer",r.playerId)))) {
            set item={"seasonYear":(year),"changes":(changes),"scale":(scale)},^RugbyWorld(game,"attributeHistory",r.playerId,e.day,e.id)=item.%ToJSON()
        } else {
            set total=##class(%DynamicObject).%FromJSON($get(^RugbyWorld(game,"attributeTotals",r.playerId,year),"{}"))
            if 'total.%IsDefined("values") set total.scale=scale,total.values={}
            for j=0:1:changes.%Size()-1 {
                set change=changes.%Get(j),factor=total.scale/scale,delta=##class(Rugby.Simulation.Engine).Clamp(change.after*factor,1,100)-##class(Rugby.Simulation.Engine).Clamp(change.before*factor,1,100)
                do total.values.%Set(change.attribute,total.values.%Get(change.attribute,0)+delta)
            }
            set ^RugbyWorld(game,"attributeTotals",r.playerId,year)=total.%ToJSON(),^RugbyWorld(game,"attributeTotalsPlayer",r.playerId)=1
        }
    }
    if ready set ^RugbyWorld(game,"attributeRecorded",e.id)=1
}
ClassMethod View(p As %DynamicObject, year As %Integer)
{
    set game=##class(Rugby.Service.Store).Game()
    if ('$get(^RugbyWorld(game,"attributeTotalsReady")))||('$get(^RugbyWorld(game,"attributeTotalsPlayer",p.id))) { do ..LegacyView(p,year) }
    else { set p.attributeSeasonChanges={},p.attributeSeasonYear=year }
    if $get(^RugbyWorld(game,"attributeTotalsReady")) {
        set total=##class(%DynamicObject).%FromJSON($get(^RugbyWorld(game,"attributeTotals",p.id,year),"{}")),values=total.%Get("values",{}),factor=p.%Get("talentScaleFactor",1)/total.%Get("scale",1),it=values.%GetIterator()
        while it.%GetNext(.attr,.value) { do p.attributeSeasonChanges.%Set(attr,p.attributeSeasonChanges.%Get(attr,0)+(value*factor)) }
    }
    set catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:16 { set attr=catalog.%Get(i).id do p.attributeSeasonChanges.%Set(attr,+$justify(p.attributeSeasonChanges.%Get(attr,0),0,6)) }
}
ClassMethod LegacyView(p As %DynamicObject, year As %Integer)
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
    for i=0:1:16 { set attr=catalog.%Get(i).id do totals.%Set(attr,+$justify(totals.%Get(attr,0),0,6)) }
    set p.attributeSeasonChanges=totals,p.attributeSeasonYear=year
}
ClassMethod Compact()
{
    set game=##class(Rugby.Service.Store).Game()
    if $get(^RugbyWorld(game,"attributeTotalsReady")) quit
    set players=##class(Rugby.Service.Store).All("Player")
    for n=0:1:players.%Size()-1 {
        set p=players.%Get(n),states={},scale=p.%Get("talentScaleFactor",1),day=""
        for {
            set day=$order(^RugbyWorld(game,"attributeHistory",p.id,day),-1)
            quit:day=""
            set id=""
            for {
                set id=$order(^RugbyWorld(game,"attributeHistory",p.id,day,id),-1)
                quit:id=""
                set item=##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"attributeHistory",p.id,day,id)),year=item.seasonYear
                if 'states.%IsDefined(year) do states.%Set(year,{"values":{},"factors":{},"expected":(##class(%DynamicObject).%FromJSON(p.attributes.%ToJSON()))})
                set state=states.%Get(year)
                for i=0:1:item.changes.%Size()-1 {
                    set change=item.changes.%Get(i),attr=change.attribute,factor=state.factors.%Get(attr,1)
                    if item.scale>0 { set factor=scale/item.scale }
                    elseif (scale<1)&&(factor=1) { set value=##class(Rugby.Simulation.Engine).Clamp(change.after*scale,1,100)-state.expected.%Get(attr) if (value<.00001)&&(value>(-.00001)) set factor=scale }
                    set delta=##class(Rugby.Simulation.Engine).Clamp(change.after*factor,1,100)-##class(Rugby.Simulation.Engine).Clamp(change.before*factor,1,100)
                    do state.values.%Set(attr,state.values.%Get(attr,0)+delta),state.expected.%Set(attr,change.before),state.factors.%Set(attr,factor)
                }
            }
        }
        set it=states.%GetIterator()
        while it.%GetNext(.year,.state) { set total={"scale":(scale),"values":(state.values)},^RugbyWorld(game,"attributeTotals",p.id,year)=total.%ToJSON() }
        set ^RugbyWorld(game,"attributeTotalsPlayer",p.id)=1
    }
    set ^RugbyWorld(game,"attributeTotalsReady")=1
    kill ^RugbyWorld(game,"attributeHistory")
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"sessions":0}
    if $get(^RugbyWorld(game,"attributeHistoryVersion"))=..#VERSION quit report
    set rows=##class(Rugby.Service.Store).All("TrainingExecution")
    for i=0:1:rows.%Size()-1 { do ..Record(rows.%Get(i)) set report.sessions=report.sessions+1 }
    do ..Compact()
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
