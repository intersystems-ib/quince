Class Rugby.Service.Development Extends %RegisteredObject
{
Parameter VERSION = "3.0.0";
ClassMethod Catalog() As %DynamicArray
{
    quit [
        {"id":"speed","name":"Velocidad","coachRole":"fitness","supportRole":"backs"},
        {"id":"strength","name":"Fuerza","coachRole":"fitness","supportRole":"forwards"},
        {"id":"stamina","name":"Resistencia","coachRole":"fitness","supportRole":"head"},
        {"id":"agility","name":"Agilidad","coachRole":"fitness","supportRole":"skills"},
        {"id":"passing","name":"Pase","coachRole":"skills","supportRole":"backs"},
        {"id":"handling","name":"Manejo y recepción","coachRole":"skills","supportRole":"attack"},
        {"id":"tackling","name":"Placaje","coachRole":"defense","supportRole":"forwards"},
        {"id":"kicking","name":"Juego al pie","coachRole":"backs","supportRole":"skills"},
        {"id":"scrum","name":"Melé","coachRole":"forwards","supportRole":"fitness"},
        {"id":"lineout","name":"Touche","coachRole":"forwards","supportRole":"skills"},
        {"id":"ruck","name":"Rucks","coachRole":"forwards","supportRole":"defense"},
        {"id":"maul","name":"Mauls","coachRole":"forwards","supportRole":"fitness"},
        {"id":"discipline","name":"Disciplina","coachRole":"defense","supportRole":"head"},
        {"id":"decisions","name":"Toma de decisiones","coachRole":"head","supportRole":"attack"},
        {"id":"leadership","name":"Liderazgo","coachRole":"head","supportRole":"skills"},
        {"id":"attacking","name":"Estructura de ataque","coachRole":"attack","supportRole":"backs"},
        {"id":"defensiveReading","name":"Lectura defensiva","coachRole":"defense","supportRole":"head"},
        {"id":"recovery","name":"Descanso y recuperación","coachRole":"fitness","supportRole":"head"}
    ]
}
ClassMethod Average(p As %DynamicObject) As %Numeric
{
    set catalog=..Catalog(),sum=0,count=0
    for i=0:1:catalog.%Size()-2 {
        set attr=catalog.%Get(i).id
        if p.attributes.%IsDefined(attr) set sum=sum+p.attributes.%Get(attr),count=count+1
    }
    quit $select(count:+$justify(sum/count,0,6),1:1)
}
ClassMethod SeasonEnd(date As %String) As %String
{
    // The management calendar runs from July 1 to June 30.
    set year=+$piece(date,"-",1)
    if +$piece(date,"-",2)>6 set year=year+1
    quit year_"-06-30"
}
ClassMethod Profile(p As %DynamicObject, club As %DynamicObject, plan As %DynamicObject, qualities As %DynamicObject) As %DynamicObject
{
    set position=##class(Rugby.Service.Positions).Describe(p.position)
    set p.positionRole=position.id,p.positionName=position.name,p.positionGroup=position.group
    set p.monthlyWage=##class(Rugby.Service.MonthlyPayroll).Value(p)
    if p.%IsDefined("seniorWeeklyWage") set p.seniorMonthlyWage=##class(Rugby.Service.Payroll).Monthly(p.seniorWeeklyWage)
    do ##class(Rugby.Service.Injuries).View(p,club.day)
    set p.average=..Average(p),future=##class(%DynamicObject).%FromJSON(p.%ToJSON()),group=""
    for i=0:1:plan.groups.%Size()-1 {
        set g=plan.groups.%Get(i)
        for j=0:1:g.playerIds.%Size()-1 { if g.playerIds.%Get(j)=p.id set group=g }
    }
    set endDate=..SeasonEnd(club.date)
    if club.%IsDefined("competitionId") {
        set league=##class(Rugby.Service.Store).Get("Competition","league-"_club.competitionId_"-"_##class(Rugby.Service.Seasons).Year(club.id),0)
        if $isobject(league) set endDate=league.endDate
    }
    set days=##class(Rugby.Simulation.Engine).Clamp($zdateh(endDate,3)-$zdateh(club.date,3),0,366)
    // Forecast only: reuse the real development rules on a detached copy, without saving or charging.
    for n=1:1:days { set result=..Apply(future,group,club.day+n,qualities,0) }
    set p.potential=..Average(future),p.potentialDate=endDate
    set p.potentialTrend=$select(p.potential<p.average:"decline",p.potential>p.average:"growth",1:"stable")
    do p.%Remove("developmentCeiling")
    quit p
}
ClassMethod FreeProfile(p As %DynamicObject) As %DynamicObject
{
    set p.monthlyWage=##class(Rugby.Service.MonthlyPayroll).Value(p)
    if p.%IsDefined("askingWeeklyWage") set p.askingMonthlyWage=##class(Rugby.Service.Payroll).Monthly(p.askingWeeklyWage)
    set position=##class(Rugby.Service.Positions).Describe(p.position)
    set p.positionRole=position.id,p.positionName=position.name,p.positionGroup=position.group,p.average=..Average(p),p.potential=p.average,p.potentialDate="",p.potentialTrend="stable"
    do p.%Remove("developmentCeiling")
    quit p
}
ClassMethod Type(focus As %String) As %DynamicObject
{
    set catalog=..Catalog()
    for i=0:1:catalog.%Size()-1 { set item=catalog.%Get(i) if item.id=focus return item }
    do ##class(Rugby.Service.Store).Fail(422,"TRAINING_TYPE","Tipo de entrenamiento desconocido.")
}
ClassMethod Intensity(value As %String) As %Integer
{
    if '$listfind($listbuild("low","normal","high"),value) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_INTENSITY","Intensidad no válida.")
    quit $select(value="low":1,value="high":3,1:2)
}
ClassMethod AnnualChange(age As %Integer, quality As %Numeric) As %Numeric
{
    set q=##class(Rugby.Simulation.Engine).Clamp(quality,0,100)/100
    quit $select(age<=24:6+(2*q),age<=28:2+(3*q),age<=32:2*q,age<=35:-4+(2*q),1:-7+(2*q))
}
ClassMethod CoachQuality(focus As %String, qualities As %DynamicObject, category As %String = "senior") As %Numeric
{
    if category="academy" quit qualities.%Get("academy",25)
    set t=..Type(focus)
    quit (.15*qualities.head)+(.65*qualities.%Get(t.coachRole))+(.2*qualities.%Get(t.supportRole))
}
ClassMethod Coaching(focus As %String, qualities As %DynamicObject) As %Numeric
{
    quit ##class(Rugby.Service.Staff).Multiplier(..CoachQuality(focus,qualities))
}
ClassMethod DeclineWeight(attribute As %String) As %Numeric
{
    quit $select($listfind($listbuild("speed","strength","stamina","agility"),attribute):2,$listfind($listbuild("decisions","leadership","discipline"),attribute):.6,1:1)
}
ClassMethod Decline(p As %DynamicObject, total As %Numeric, changes As %DynamicArray) As %Numeric
{
    set catalog=..Catalog(),remaining=total,sign=-1,before=##class(%DynamicObject).%FromJSON(p.attributes.%ToJSON())
    // Apply age decline across characteristics without dropping any below 1.
    for pass=1:1:17 {
        quit:remaining<.00002
        set weights=0
        for i=0:1:16 {
            set attr=catalog.%Get(i).id,value=p.attributes.%Get(attr)
            if value>1 set weights=weights+..DeclineWeight(attr)
        }
        quit:weights=0
        set budget=remaining,applied=0
        for i=0:1:16 {
            set attr=catalog.%Get(i).id,value=p.attributes.%Get(attr),room=value-1
            if room>0 {
                set delta=##class(Rugby.Simulation.Engine).Clamp(budget*..DeclineWeight(attr)/weights,0,room)
                set after=+$justify(##class(Rugby.Simulation.Engine).Clamp(value+(sign*delta),1,100),0,6),actual=(after-value)*sign
                // Keep rounding within the total budget.
                if (applied+actual)<=remaining { do p.attributes.%Set(attr,after) set applied=applied+actual }
            }
        }
        quit:applied=0
        set remaining=remaining-applied
    }
    for i=0:1:16 {
        set attr=catalog.%Get(i).id,old=before.%Get(attr),value=p.attributes.%Get(attr)
        if value'=old do changes.%Push({"attribute":(attr),"before":(old),"after":(value),"delta":(value-old),"reason":"age"})
    }
    quit (total-remaining)*sign
}
ClassMethod Save(club As %String, b As %DynamicObject) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    quit ..SavePlan(club,b)
}
ClassMethod SavePlan(club As %String, b As %DynamicObject) As %DynamicObject
{
    set old=##class(Rugby.Service.Store).Get("TrainingPlan",club)
    do ##class(Rugby.Service.Store).CheckVersion(old,b)
    if '$isobject(b.%Get("groups")) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_GROUPS","Selecciona jugadores y crea sus grupos de entrenamiento.")
    if 'b.groups.%IsA("%Library.DynamicArray") do ##class(Rugby.Service.Store).Fail(422,"TRAINING_GROUPS","Los grupos deben ser una lista.")
    if b.groups.%Size()>50 do ##class(Rugby.Service.Store).Fail(422,"TRAINING_GROUPS","Demasiados grupos de entrenamiento.")
    set seen={},groupIds={},cost=0,groups=[]
    for i=0:1:b.groups.%Size()-1 {
        set g=b.groups.%Get(i)
        if '$isobject(g) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_GROUP","Grupo no válido.")
        do ##class(Rugby.Service.Store).Key(g.%Get("id"))
        if groupIds.%IsDefined(g.id) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_GROUP","Identificador de grupo duplicado.")
        do groupIds.%Set(g.id,1)
        if ($length(g.%Get("name"))<1)||($length(g.%Get("name"))>60) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_GROUP","El grupo necesita un nombre de 1 a 60 caracteres.")
        set t=..Type(g.%Get("focus")),intensity=..Intensity(g.%Get("intensity"))
        if '$isobject(g.%Get("playerIds")) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_PLAYERS","Selecciona los jugadores del grupo.")
        if 'g.playerIds.%IsA("%Library.DynamicArray") do ##class(Rugby.Service.Store).Fail(422,"TRAINING_PLAYERS","Los jugadores deben ser una lista de identificadores.")
        if (g.playerIds.%Size()<1)||(g.playerIds.%Size()>100) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_PLAYERS","Cada grupo debe contener entre 1 y 100 jugadores.")
        for j=0:1:g.playerIds.%Size()-1 {
            set pid=g.playerIds.%Get(j),p=##class(Rugby.Service.Store).Get("Player",pid)
            if p.clubId'=club do ##class(Rugby.Service.Store).Fail(422,"PLAYER_CLUB","No puedes entrenar jugadores de otro club.")
            if seen.%IsDefined(pid) do ##class(Rugby.Service.Store).Fail(422,"TRAINING_DUPLICATE",p.name_" ya tiene un entrenamiento asignado. Solo se permite uno por día.")
            do seen.%Set(pid,1)
        }
        do groups.%Push({"id":(g.id),"name":(g.name),"focus":(g.focus),"intensity":(g.intensity),"playerIds":(g.playerIds)})
    }
    set rawCost=0,cost=0
    set plan={"rawDailyCost":(rawCost),"id":(club),"clubId":(club),"groups":(groups),"dailyCost":(cost),"modelVersion":(..#VERSION)}
    do ##class(Rugby.Service.Store).Put("TrainingPlan",plan)
    quit plan
}
ClassMethod SuggestedFocus(p As %DynamicObject, variant As %Integer) As %String
{
    if ('p.available)||(p.energy<60) quit "recovery"
    // Weighted rotation favours the physical and technical demands of each position.
    if p.position<=3 { set choices="strength,scrum,strength,ruck,strength,maul,strength,handling" }
    elseif p.position<=5 { set choices="strength,lineout,strength,maul,ruck,strength,tackling,stamina" }
    elseif p.position<=8 { set choices="strength,ruck,tackling,strength,stamina,maul,strength,lineout" }
    elseif p.position<=10 { set choices="agility,passing,speed,decisions,agility,kicking,speed,handling" }
    elseif (p.position=12)||(p.position=13) { set choices="speed,agility,passing,speed,tackling,agility,attacking,handling" }
    else { set choices="speed,agility,speed,kicking,agility,handling,speed,attacking" }
    quit $piece(choices,",",(variant#8)+1)
}
ClassMethod Suggest(club As %String, variant As %Integer = 0) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    if '##class(Rugby.Service.Store).Integer(variant,0,1000000) do ##class(Rugby.Service.Store).Fail(400,"TRAINING_VARIANT","La propuesta debe ser un número entre 0 y 1000000.")
    set variant=+variant
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),groups=[],buckets={},recovering=0,cost=0
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),focus=..SuggestedFocus(p,variant+i)
        set intensity=$select(focus="recovery":"low",p.energy<75:"low",1:"normal"),key=focus_"-"_intensity
        if 'buckets.%IsDefined(key) {
            set t=..Type(focus),g={"id":("auto-"_key),"name":(t.name),"focus":(focus),"intensity":(intensity),"playerIds":[]}
            do buckets.%Set(key,g),groups.%Push(g)
        }
        do buckets.%Get(key).playerIds.%Push(p.id)
        if focus="recovery" { set recovering=recovering+1 }
    }
    quit {"groups":(groups),"variant":(variant),"playerCount":(players.%Size()),"recoveryCount":(recovering),"dailyCost":(cost)}
}
ClassMethod Apply(p As %DynamicObject, group, day As %Integer, qualities As %DynamicObject, deriveSummary As %Boolean = 1) As %DynamicObject
{
    set recovered=##class(Rugby.Service.Injuries).Recover(p,day)
    set p.age=(day-p.birthDay)\365,oldEnergy=p.energy,changes=[],gain=0,focus="recovery",gid="",intensity=1
    if $isobject(group) set focus=group.focus,gid=group.id,intensity=..Intensity(group.intensity)
    set date=$zdate($zdateh("2026-11-07",3)+day,3),season=..SeasonEnd(date),seasonStart=(+$piece(season,"-",1)-1)_"-07-01"
    set seasonDays=$zdateh(season,3)-$zdateh(seasonStart,3)+1,trainingDays=seasonDays*5/7
    if (p.%Get("developmentModel")'=..#VERSION)||(p.%Get("developmentSeason")'=season) set p.developmentModel=..#VERSION,p.developmentSeason=season,p.developmentProgress=0
    set target=..AnnualChange(p.age,..CoachQuality(focus,qualities,p.category)),averageBefore=0
    if deriveSummary set averageBefore=..Average(p)
    if target<0 {
        set delta=..Decline(p,(-target)*17/seasonDays,changes)
    }
    set canTrain=(focus'="recovery")&&p.available&&(p.energy>=25)
    if canTrain {
        if target>0 {
            set effort=$select(intensity=1:.85,intensity=3:1.1,1:1),remaining=##class(Rugby.Simulation.Engine).Clamp(target-p.developmentProgress,0,target)
            set budget=##class(Rugby.Simulation.Engine).Clamp(target*17/trainingDays*effort,0,remaining*17)
            set before=p.attributes.%Get(focus),delta=##class(Rugby.Simulation.Engine).Clamp(budget,0,100-before)
            set delta=((delta*1000000)\1)/1000000
            set after=+$justify(before+delta,0,6),gain=after-before
            do p.attributes.%Set(focus,after)
            if gain do changes.%Push({"attribute":(focus),"before":(before),"after":(after),"delta":(gain),"reason":"training"})
            set p.developmentProgress=p.developmentProgress+(gain/17)
        }
        set p.energy=##class(Rugby.Simulation.Engine).Clamp(p.energy+12-(intensity*7),0,100)
    } else { set p.energy=##class(Rugby.Simulation.Engine).Clamp(p.energy+18,0,100) }
    set averageAfter=0
    if deriveSummary set averageAfter=..Average(p),p.average=averageAfter,p.form=p.average
    quit {"playerId":(p.id),"groupId":(gid),"focus":(focus),"age":(p.age),"energyDelta":(p.energy-oldEnergy),"attributeGain":(gain),"averageBefore":(averageBefore),"averageAfter":(averageAfter),"averageDelta":(averageAfter-averageBefore),"annualTarget":(target),"recovered":(recovered),"changes":(changes)}
}
ClassMethod Process(club As %String, day As %Integer) As %DynamicObject
{
    set eid=club_"-day"_day,previous=##class(Rugby.Service.Store).Get("TrainingExecution",eid,0)
    if $isobject(previous) quit previous
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan",club),staff=##class(Rugby.Service.Staff).View(club),qualities=##class(Rugby.Service.Staff).Qualities(club),groups={}
    for i=0:1:plan.groups.%Size()-1 {
        set g=plan.groups.%Get(i)
        for j=0:1:g.playerIds.%Size()-1 { do groups.%Set(g.playerIds.%Get(j),g) }
    }
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),results=[],wages=0
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),wages=wages+p.weeklyWage
        set group=groups.%Get(p.id),eligible=p.available&&(p.energy>=25),daily=..Apply(p,group,day,qualities),daily.morale=##class(Rugby.Service.Morale).Daily(p,day)
        if eligible&&$isobject(group)&&(group.focus'="recovery") set daily.injury=##class(Rugby.Service.Injuries).Training(p,day,..Intensity(group.intensity),qualities.%Get($select(p.category="academy":"academy",1:"fitness"),25))
        do results.%Push(daily)
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    do ##class(Rugby.Service.Management).RefreshAvailability(club)
    set execution={"id":(eid),"clubId":(club),"day":(day),"modelVersion":(..#VERSION),"groups":(plan.groups),"staffSnapshot":(staff.coaches),"results":(results),"trainingCost":0,"playerWeeklyWages":(wages),"staffWeeklyWages":(staff.weeklyWage)}
    do ##class(Rugby.Service.Store).Put("TrainingExecution",execution)
    quit execution
}
}
