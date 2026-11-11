Class Rugby.Service.WeeklyTraining Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Themes() As %DynamicArray
{
    quit [
        {"id":"attack","name":"Ataque y continuidad","forwards":"maul,ruck,handling,attacking,passing,decisions,handling","backs":"passing,handling,kicking,attacking,agility,decisions,speed"},
        {"id":"defense","name":"Defensa y placaje","forwards":"tackling,defensiveReading,ruck,discipline,strength,tackling,defensiveReading","backs":"defensiveReading,tackling,speed,discipline,agility,tackling,decisions"},
        {"id":"physical","name":"Preparación física","forwards":"strength,stamina,strength,agility,stamina,strength,speed","backs":"speed,agility,stamina,speed,agility,stamina,strength"},
        {"id":"technique","name":"Destrezas técnicas","forwards":"handling,passing,ruck,handling,decisions,passing,kicking","backs":"passing,handling,kicking,decisions,handling,kicking,passing"},
        {"id":"setPieces","name":"Formaciones y reinicios","forwards":"scrum,lineout,maul,scrum,lineout,maul,scrum","backs":"kicking,handling,passing,kicking,handling,passing,kicking"},
        {"id":"tactics","name":"Táctica y disciplina","forwards":"decisions,leadership,attacking,defensiveReading,discipline,decisions,leadership","backs":"decisions,attacking,defensiveReading,kicking,discipline,leadership,decisions"},
        {"id":"rest","name":"Descanso y recuperación","forwards":"recovery,recovery,recovery,recovery,recovery,recovery,recovery","backs":"recovery,recovery,recovery,recovery,recovery,recovery,recovery"}
    ]
}
ClassMethod Defaults() As %DynamicObject
{
    set result={}
    for category="senior","academy" {
        set week=[]
        for day=1:1:7 { do week.%Push({"day":(day),"theme":($piece("rest,physical,setPieces,attack,defense,technique,rest",",",day))}) }
        do result.%Set(category,week)
    }
    quit result
}
ClassMethod Weekday(day As %Integer) As %Integer { quit (($zdateh("2026-11-07",3)+day+3)#7)+1 }
ClassMethod Theme(id As %String) As %DynamicObject
{
    set themes=..Themes()
    for i=0:1:themes.%Size()-1 { set t=themes.%Get(i) if t.id=id return t }
    do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_THEME","Elige un enfoque de entrenamiento válido.")
}
ClassMethod Validate(weekly) As %DynamicObject
{
    if '$isobject(weekly) do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_PLAN","Planifica los siete días de primer equipo y cantera.")
    if 'weekly.%IsA("%Library.DynamicObject") do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_PLAN","El plan semanal debe ser un objeto.")
    set clean={}
    for category="senior","academy" {
        set week=weekly.%Get(category),seen={},days=[]
        if '$isobject(week) do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAYS","Faltan los siete días de "_category_".")
        if 'week.%IsA("%Library.DynamicArray") do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAYS","Los días deben ser una lista.")
        if week.%Size()'=7 do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAYS","Cada semana debe tener siete días.")
        for i=0:1:6 {
            set d=week.%Get(i)
            if '$isobject(d) do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAY","Día de entrenamiento inválido.")
            if 'd.%IsA("%Library.DynamicObject") do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAY","El día debe ser un objeto.")
            if '##class(Rugby.Service.Store).Integer(d.%Get("day"),1,7) do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAY","Los días van de lunes (1) a domingo (7).")
            set index=+d.day
            if seen.%IsDefined(index) do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_DAY","No repitas días de la semana.")
            set t=..Theme(d.%Get("theme"))
            set entry={"day":(index),"theme":(t.id)}
            for line="forwards","backs" {
                if d.%IsDefined(line) {
                    if d.%GetTypeOf(line)'="string" do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_FOCUS","El ejercicio debe ser un tipo de entrenamiento válido.")
                    set focus=d.%Get(line)
                    if '$listfind($listfromstring(t.%Get(line)),focus) do ##class(Rugby.Service.Store).Fail(422,"WEEKLY_FOCUS","El ejercicio debe corresponder al enfoque y grupo elegidos.")
                    do entry.%Set(line,focus)
                }
            }
            do seen.%Set(index,entry)
        }
        for day=1:1:7 { do days.%Push(seen.%Get(day)) }
        do clean.%Set(category,days)
    }
    quit clean
}
ClassMethod Context(club As %String, plan As %DynamicObject) As %DynamicObject
{
    set context={"weekly":(plan.weekly),"matchDays":{},"themes":{},"labels":{}},themes=..Themes(),catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:themes.%Size()-1 { set theme=themes.%Get(i) do context.themes.%Set(theme.id,theme) }
    for i=0:1:catalog.%Size()-1 { set type=catalog.%Get(i) do context.labels.%Set(type.id,type.name) }
    set fixtures=##class(Rugby.Service.Competition).ClubFixtures(club)
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if 'f.%Get("archived",0) { do context.matchDays.%Set(f.day,1),context.matchDays.%Set(f.day-1,1) } }
    quit context
}
ClassMethod Group(p As %DynamicObject, day As %Integer, context As %DynamicObject) As %DynamicObject
{
    set weekday=..Weekday(day),category=p.category,week=context.weekly.%Get(category),entry=week.%Get(weekday-1),theme=context.themes.%Get(entry.theme),line=$select(p.position<=8:"forwards",1:"backs"),focus=entry.%Get(line,$piece(theme.%Get(line),",",weekday)),intensity=$select((p.energy<75)||(((day-p.birthDay)\365)>=33):"low",1:"normal"),reason="scheduled"
    if ('p.available)||(p.energy<60) set focus="recovery",reason=$select('p.available:"unavailable",1:"lowEnergy")
    if (category="senior")&&context.matchDays.%IsDefined(day) set focus="recovery",reason="matchPreparation"
    if focus="recovery" set intensity="low"
    set id=category_"-"_line_"-"_focus_"-"_intensity
    quit {"id":(id),"name":(context.labels.%Get(focus)),"focus":(focus),"intensity":(intensity),"theme":(theme.id),"weekday":(weekday),"category":(category),"positionGroup":(line),"reason":(reason)}
}
ClassMethod Groups(club As %String, plan As %DynamicObject, day As %Integer) As %DynamicArray
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),context=..Context(club,plan),groups=[],buckets={}
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),g=..Group(p,day,context)
        if 'buckets.%IsDefined(g.id) { set g.playerIds=[] do groups.%Push(g),buckets.%Set(g.id,g) }
        do buckets.%Get(g.id).playerIds.%Push(p.id)
    }
    quit groups
}
ClassMethod Save(club As %String, b As %DynamicObject, key As %String = "") As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game()
    if key'="" {
        do ##class(Rugby.Service.Store).Key(key)
        if $data(^RugbyWorld(game,"retry","weeklyTraining",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","weeklyTraining",club,key))
    }
    set old=##class(Rugby.Service.Store).Get("TrainingPlan",club)
    do ##class(Rugby.Service.Store).CheckVersion(old,b)
    set weekly=..Validate(b.%Get("weekly")),plan={"id":(club),"clubId":(club),"mode":"weekly","weekly":(weekly),"groups":[],"rawDailyCost":0,"dailyCost":0,"modelVersion":(##class(Rugby.Service.Development).#VERSION),"weeklyVersion":(..#VERSION)}
    do ##class(Rugby.Service.Store).Put("TrainingPlan",plan)
    set result=..View(club)
    if key'="" set ^RugbyWorld(game,"retry","weeklyTraining",club,key)=result.%ToJSON()
    quit result
}
ClassMethod View(club As %String) As %DynamicObject
{
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan",club),c=##class(Rugby.Service.Store).Get("Club",club)
    set plan.themes=..Themes(),plan.nextDay=c.day+1,plan.nextWeekday=..Weekday(c.day+1),plan.nextDate=$zdate($zdateh(c.date,3)+1,3)
    do plan.%Set("weeklyConfigured",plan.%Get("mode")="weekly","boolean")
    if plan.weeklyConfigured { set plan.nextGroups=..Groups(club,plan,c.day+1) } else { set plan.weekly=..Defaults(),plan.nextGroups=plan.groups }
    quit plan
}
}
