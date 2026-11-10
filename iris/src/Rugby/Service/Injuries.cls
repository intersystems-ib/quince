Class Rugby.Service.Injuries Extends %RegisteredObject
{
Parameter VERSION = "1.1.0";
Parameter MATCHRATE = 0.000045;
ClassMethod Catalog() As %DynamicArray
{
    // Gameplay durations, not clinical recovery advice. Weights favour minor injuries.
    quit [
        {"id":"bruise-1","name":"Contusión","grade":1,"severity":"leve","minWeeks":1,"maxWeeks":1,"weight":22},
        {"id":"bruise-2","name":"Contusión","grade":2,"severity":"moderada","minWeeks":1,"maxWeeks":2,"weight":10},
        {"id":"overload","name":"Sobrecarga muscular","grade":1,"severity":"leve","minWeeks":1,"maxWeeks":2,"weight":16},
        {"id":"contracture","name":"Contractura muscular","grade":1,"severity":"leve","minWeeks":1,"maxWeeks":2,"weight":14},
        {"id":"ankle-1","name":"Esguince de tobillo","grade":1,"severity":"leve","minWeeks":1,"maxWeeks":2,"weight":13},
        {"id":"ankle-2","name":"Esguince de tobillo","grade":2,"severity":"moderada","minWeeks":3,"maxWeeks":5,"weight":7},
        {"id":"ankle-3","name":"Esguince de tobillo","grade":3,"severity":"grave","minWeeks":8,"maxWeeks":12,"weight":2},
        {"id":"muscle-1","name":"Lesión de fibras musculares","grade":1,"severity":"leve","minWeeks":1,"maxWeeks":2,"weight":12},
        {"id":"muscle-2","name":"Lesión de fibras musculares","grade":2,"severity":"moderada","minWeeks":3,"maxWeeks":6,"weight":7},
        {"id":"muscle-3","name":"Rotura muscular","grade":3,"severity":"grave","minWeeks":10,"maxWeeks":16,"weight":1},
        {"id":"adductor","name":"Lesión de aductores","grade":2,"severity":"moderada","minWeeks":2,"maxWeeks":4,"weight":5},
        {"id":"hamstring","name":"Lesión de isquiotibiales","grade":2,"severity":"moderada","minWeeks":3,"maxWeeks":6,"weight":5},
        {"id":"shoulder-sprain","name":"Esguince de hombro","grade":2,"severity":"moderada","minWeeks":2,"maxWeeks":4,"weight":5},
        {"id":"shoulder-dislocation","name":"Luxación de hombro","grade":3,"severity":"grave","minWeeks":6,"maxWeeks":10,"weight":2},
        {"id":"concussion","name":"Conmoción cerebral","grade":2,"severity":"moderada","minWeeks":2,"maxWeeks":4,"weight":4},
        {"id":"meniscus","name":"Lesión de menisco","grade":3,"severity":"grave","minWeeks":6,"maxWeeks":10,"weight":2},
        {"id":"clavicle","name":"Fractura de clavícula","grade":3,"severity":"grave","minWeeks":8,"maxWeeks":12,"weight":1},
        {"id":"ankle-fracture","name":"Fractura de tobillo","grade":3,"severity":"grave","minWeeks":12,"maxWeeks":18,"weight":1},
        {"id":"acl","name":"Rotura de ligamento cruzado","grade":3,"severity":"grave","minWeeks":28,"maxWeeks":40,"weight":1},
        {"id":"achilles","name":"Rotura del tendón de Aquiles","grade":3,"severity":"grave","minWeeks":24,"maxWeeks":36,"weight":1}
    ]
}
ClassMethod Date(day As %Integer) As %String { quit $zdate($zdateh("2026-11-07",3)+day,3) }
ClassMethod Active(p As %DynamicObject, day As %Integer) As %Boolean
{
    quit (p.%Get("recoveryDay",0)>day)&&('p.%Get("available",1))
}
ClassMethod View(p As %DynamicObject, day As %Integer)
{
    set injury=p.%Get("injury")
    if '$isobject(injury) quit
    set remaining=$select(injury.recoveryDay>day:injury.recoveryDay-day,1:0)
    set injury.remainingDays=remaining,injury.remainingWeeks=(remaining+6)\7
}
ClassMethod Recover(p As %DynamicObject, day As %Integer) As %Boolean
{
    if p.%Get("retired",0)||(p.%Get("contractStatus")="retired") quit 0
    if p.%Get("available",1)||(p.%Get("recoveryDay",0)>day) quit 0
    set p.available=1,injury=p.%Get("injury")
    if $isobject(injury) {
        set injury.status="recovered",injury.recoveredOn=..Date(day),injury.remainingDays=0,injury.remainingWeeks=0
        if 'p.%IsDefined("injuryHistory") set p.injuryHistory=[]
        do p.injuryHistory.%Push(injury),p.%Remove("injury")
    }
    quit 1
}
ClassMethod Create(p As %DynamicObject, day As %Integer, source As %String, context As %String, rng As %DynamicObject) As %DynamicObject
{
    set catalog=..Catalog(),total=0
    for i=0:1:catalog.%Size()-1 { set total=total+catalog.%Get(i).weight }
    set pick=##class(Rugby.Simulation.Engine).Random(rng)*total,chosen=catalog.%Get(0)
    for i=0:1:catalog.%Size()-1 { set chosen=catalog.%Get(i),pick=pick-chosen.weight quit:pick<0 }
    set weeks=chosen.minWeeks+((##class(Rugby.Simulation.Engine).Random(rng)*(chosen.maxWeeks-chosen.minWeeks+1))\1)
    set injury={"id":(p.id_"-"_context),"typeId":(chosen.id),"name":(chosen.name),"grade":(chosen.grade),"severity":(chosen.severity),"weeks":(weeks),"startedDay":(day),"startedOn":(..Date(day)),"recoveryDay":(day+(weeks*7)),"expectedReturn":(..Date(day+(weeks*7))),"remainingDays":(weeks*7),"remainingWeeks":(weeks),"source":(source),"contextId":(context),"status":"active","modelVersion":(..#VERSION)}
    set p.injury=injury,p.available=0,p.recoveryDay=injury.recoveryDay
    quit injury
}
ClassMethod Risk(energy As %Numeric, age As %Integer) As %Numeric
{
    quit 1+((100-energy)/70)+$select(age>30:(age-30)*.04,1:0)
}
ClassMethod Training(p As %DynamicObject, day As %Integer, intensity As %Integer, quality As %Numeric) As %DynamicObject
{
    if 'p.available quit {}
    set seed=1+(##class(Rugby.Service.Rivals).Hash("injury-training-"_p.id_"-"_day,##class(Rugby.Service.Rivals).Seed())#2147483646),rng={"rng":(seed)},chance=.00035*..Risk(p.energy,p.age)*intensity*(1.2-(quality/250))
    // Mix nearby date/player hashes before drawing a rare event.
    for n=1:1:3 { set discard=##class(Rugby.Simulation.Engine).Random(rng) }
    if ##class(Rugby.Simulation.Engine).Random(rng)>=chance quit {}
    quit ..Create(p,day,"training","training-"_day,rng)
}
ClassMethod Hit(m As %DynamicObject, side As %String, s As %DynamicObject) As %Boolean
{
    if s.status'="field" quit 0
    set p=##class(Rugby.Service.Store).Get("Player",s.playerId),club=##class(Rugby.Service.Store).Get("Club",p.clubId),day=$select(m.%Get("date")'="":$zdateh(m.date,3)-$zdateh("2026-11-07",3),1:club.day)
    if ..Active(p,day) quit 0
    set injury=..Create(p,day,"match",$select(m.%Get("aggregate",0):m.fixtureId,1:m.id),m),s.status="injured",s.injury=injury,s.injuredClock=m.clock,s.energy=##class(Rugby.Simulation.Engine).Clamp(s.energy-8,0,100),p.energy=s.energy
    if 'm.%Get("aggregate",0) { do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Management).RefreshAvailability(p.clubId) }
    set text=p.name_" abandona el campo: "_injury.name_" (grado "_injury.grade_"). Baja de "_injury.weeks_" semanas."
    if m.%Get("aggregate",0) {
        do m.injuryEvents.%Push({"type":"injury","side":(side),"playerId":(p.id),"clock":(m.clock),"text":(text),"injury":(injury)})
    } else {
        do ##class(Rugby.Simulation.Engine).Event(m,"injury",side,text,0,m.x,m.y,p.id)
        if m.%Get(side_"Id")=##class(Rugby.Service.Store).ManagedClub() do ##class(Rugby.Service.Matches).Pause(m,"injury",text_" Partido en pausa: revisa la sustitución y selecciona una velocidad para continuar.",p.id)
        // Preserve conversions and set pieces; all are already substitution windows.
        if '$listfind($listbuild("restart","scrum","lineout","penalty","conversion"),m.phase) set m.phase="stoppage"
    }
    quit 1
}
ClassMethod MatchChance(energy As %Numeric, age As %Integer, elapsed As %Integer) As %Numeric
{
    quit ..#MATCHRATE*(elapsed/20)*..Risk(energy,age)
}
ClassMethod MatchTick(m As %DynamicObject, elapsed As %Integer)
{
    for side="home","away" {
        quit:m.%Get("speed",1)=0
        set players=m.%Get(side_"Players")
        for i=0:1:players.%Size()-1 {
            quit:m.%Get("speed",1)=0
            set s=players.%Get(i)
            if s.status'="field" continue
            set chance=..MatchChance(s.energy,s.%Get("age",26),elapsed)
            if ##class(Rugby.Simulation.Engine).Random(m)<chance set applied=..Hit(m,side,s)
        }
    }
}
ClassMethod Replace(m As %DynamicObject, side As %String)
{
    set players=m.%Get(side_"Players")
    for i=0:1:players.%Size()-1 {
        set out=players.%Get(i)
        if (out.status'="injured")||out.%Get("substituted",0)||(m.%Get(side_"Subs",0)>=8) continue
        set best="",score=-1
        for j=0:1:players.%Size()-1 {
            set candidate=players.%Get(j)
            if candidate.status'="bench" continue
            if (candidate.naturalPosition<=8)'=(out.position<=8) continue
            set value=candidate.energy+$select(candidate.naturalPosition=out.position:100,1:0)
            if value>score set score=value,best=candidate
        }
        if '$isobject(best) continue
        set out.substituted=1,best.status="field",best.position=out.position
        do ##class(Rugby.Simulation.Performance).ApplyMorale(best)
        do m.%Set(side_"Subs",m.%Get(side_"Subs",0)+1)
    }
}
}
