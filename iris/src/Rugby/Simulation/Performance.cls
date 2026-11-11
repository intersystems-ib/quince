Class Rugby.Simulation.Performance Extends %RegisteredObject
{
ClassMethod MoralePenalty(p As %DynamicObject) As %Integer
{
    if p.position=p.naturalPosition quit 0
    set secondary=0
    for i=0:1:p.secondary.%Size()-1 { if p.secondary.%Get(i)=p.position set secondary=1 }
    if secondary quit 3
    quit $select((p.position<=8)=(p.naturalPosition<=8):8,1:15)
}
ClassMethod ApplyMorale(p As %DynamicObject)
{
    set previous=p.%Get("positionMoraleApplied",p.%Get("positionMoralePenalty",0)),base=##class(Rugby.Simulation.Engine).Clamp(p.morale+previous,0,100),penalty=$select(p.status="field":..MoralePenalty(p),1:0)
    set p.morale=##class(Rugby.Simulation.Engine).Clamp(base-penalty,0,100),p.positionMoralePenalty=penalty,p.positionMoraleApplied=base-p.morale
}
ClassMethod AlignmentMorale(players As %DynamicArray)
{
    for i=0:1:players.%Size()-1 { do ..ApplyMorale(players.%Get(i)) }
}
ClassMethod Skill(p As %DynamicObject, profile As %String) As %Numeric
{
    set names="",weights=""
    if profile="scrum" { set names="scrum,strength,stamina",weights=".60,.30,.10" }
    elseif profile="lineout" { set names="lineout,handling,strength",weights=".65,.20,.15" }
    elseif profile="contact" { set names="ruck,strength,maul",weights=".50,.30,.20" }
    elseif profile="attack" { set names="handling,passing,attacking,agility,decisions",weights=".30,.25,.20,.15,.10" }
    elseif profile="carry" { set names="speed,agility,strength,handling,decisions",weights=".25,.25,.20,.20,.10" }
    elseif profile="defense" { set names="tackling,defensiveReading,strength,agility",weights=".55,.25,.10,.10" }
    else { quit ##class(Rugby.Simulation.Engine).Rating(p,profile) }
    set value=0
    for i=1:1:$length(names,",") { set value=value+(##class(Rugby.Simulation.Engine).Rating(p,$piece(names,",",i))*+$piece(weights,",",i)) }
    quit value
}
ClassMethod Unit(players As %DynamicArray, group As %String = "all", anchor As %DynamicObject = "", limit As %Integer = 15, excluded As %String = "") As %DynamicArray
{
    // Membership follows the occupied slot, never the player's natural role.
    set unit=[],rank=0
    kill ordered
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.status'="field")||(p.playerId=excluded) continue
        if (group="forwards")&&(p.position>8) continue
        if (group="backs")&&(p.position<=8) continue
        set distance=0
        if $isobject(anchor) set distance=((p.%Get("x",50)-anchor.%Get("x",50))**2)+((p.%Get("y",35)-anchor.%Get("y",35))**2)
        set ordered(distance,p.position,i)=p
    }
    set distance=""
    for { set distance=$order(ordered(distance)) quit:distance=""  set pos="" for { set pos=$order(ordered(distance,pos)) quit:pos=""  set i="" for { set i=$order(ordered(distance,pos,i)) quit:i=""  if unit.%Size()<limit do unit.%Push(ordered(distance,pos,i)) } } }
    quit unit
}
ClassMethod Score(unit As %DynamicArray, profile As %String, expected As %Integer = 1) As %Numeric
{
    set sum=0
    for i=0:1:unit.%Size()-1 { set sum=sum+..Skill(unit.%Get(i),profile) }
    // Empty slots count as zero, so exclusions do not improve an average.
    quit sum/expected
}
ClassMethod Ids(unit As %DynamicArray) As %DynamicArray
{
    set ids=[]
    for i=0:1:unit.%Size()-1 { do ids.%Push(unit.%Get(i).playerId) }
    quit ids
}
ClassMethod Kicker(players As %DynamicArray) As %DynamicObject
{
    set best="",value=-1
    // Pick an actual specialist rather than averaging every player's boot.
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if p.status'="field" continue
        set score=..Skill(p,"kicking")
        if score>value { set value=score,best=p }
    }
    quit best
}
ClassMethod Contest(players As %DynamicArray, defenders As %DynamicArray, phase As %String, actor As %DynamicObject) As %DynamicObject
{
    if (phase="conversion")||(phase="penalty") {
        quit {"profile":"kicking","actorId":(actor.playerId),"attackers":[(actor.playerId)],"defenders":[],"attack":(..Skill(actor,"kicking")),"defense":0,"expectedDefenders":0}
    }
    if (phase="scrum")||(phase="lineout") {
        set attack=..Unit(players,"forwards"),defense=..Unit(defenders,"forwards"),profile=phase,expected=8
        set a=..Score(attack,profile,expected),d=..Score(defense,profile,expected)
    } elseif phase="ruck" {
        set attack=..Unit(players,"forwards",actor,3),defense=..Unit(defenders,"forwards",actor,3),profile="contact",expected=3
        set a=(..Score(attack,profile,expected)*.7)+(..Skill(actor,"carry")*.3),d=..Score(defense,profile,expected)
    } else {
        set attack=..Unit(players,"all",actor,2,actor.playerId),defense=..Unit(defenders,"all",actor,3),profile="open",expected=3
        set a=(..Skill(actor,"carry")*.6)+(..Score(attack,"attack",2)*.4),d=..Score(defense,"defense",expected)
        do attack.%Push(actor)
    }
    quit {"profile":(profile),"actorId":(actor.playerId),"attackers":(..Ids(attack)),"defenders":(..Ids(defense)),"attack":(a),"defense":(d),"expectedDefenders":(expected)}
}
}
