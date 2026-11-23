Class Rugby.Simulation.Substitutions Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Plan(m As %DynamicObject, side As %String, injuriesOnly As %Boolean = 0) As %DynamicArray
{
    set changes=[],limit=8-m.%Get(side_"Subs",0)
    if (limit<=0)||(m.status="finished")||(m.status="scheduled") quit changes
    set players=m.%Get(side_"Players")
    kill ordered
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if p.%Get("substituted",0) continue
        set injured=p.status="injured",tired=(p.status="field")&&((p.energy<=35)||((m.clock>=3000)&&(p.energy<=66)))
        if ('injured)&&(injuriesOnly||('tired)) continue
        set priority=$select(injured:0,1:1),ordered(priority,p.energy,p.playerId)=p
    }
    set targets=[],priority="",bench=[],powers=[]
    for {
        set priority=$order(ordered(priority)) quit:priority=""
        set energy=""
        for {
            set energy=$order(ordered(priority,energy)) quit:energy=""
            set id=""
            for { set id=$order(ordered(priority,energy,id)) quit:id=""  do targets.%Push(ordered(priority,energy,id)) }
        }
    }
    if targets.%Size()=0 quit changes
    for i=0:1:players.%Size()-1 {
        set candidate=players.%Get(i)
        if (candidate.status'="bench")||candidate.%Get("substituted",0)||$isobject(candidate.%Get("injury")) continue
        if candidate.%IsDefined("available") { if 'candidate.available continue }
        if (candidate.%Get("redCards",0)>0)||(candidate.%Get("sinBinUntil",0)>m.clock) continue
        do bench.%Push(candidate),powers.%Push(##class(Rugby.Service.AutomaticLineup).Ability(candidate))
    }
    set scores=[]
    for r=0:1:targets.%Size()-1 {
        set out=targets.%Get(r),injured=out.status="injured",row=[]
        for i=0:1:bench.%Size()-1 {
            set candidate=bench.%Get(i),value=-1000000
            if ((candidate.naturalPosition<=8)=(out.position<=8))&&(injured||(candidate.energy>=(out.energy+10))) {
                set same=candidate.naturalPosition=out.position,secondary=0
                for j=0:1:candidate.secondary.%Size()-1 { if candidate.secondary.%Get(j)=out.position set secondary=1 }
                set urgency=$select(injured:1000000000000000,1:1000000000000+((100-out.energy)*10000000000)),value=urgency+$select(same:1000000000,secondary:100000000,1:0)+powers.%Get(i)
            }
            do row.%Push(value)
        }
        for i=1:1:targets.%Size() { do row.%Push(0) }
        do scores.%Push(row)
    }
    set assignment=##class(Rugby.Service.AutomaticLineup).Assign(scores)
    for r=0:1:targets.%Size()-1 {
        quit:changes.%Size()>=limit
        set column=assignment.%Get(r)
        if (column>=bench.%Size())||(scores.%Get(r).%Get(column)<0) continue
        set out=targets.%Get(r),best=bench.%Get(column)
        do changes.%Push({"outId":(out.playerId),"inId":(best.playerId),"outName":(out.name),"inName":(best.name),"reason":($select(out.status="injured":"injury",1:"fatigue"))})
    }
    quit changes
}
ClassMethod Apply(m As %DynamicObject, side As %String, changes As %DynamicArray)
{
    for i=0:1:changes.%Size()-1 {
        quit:m.%Get(side_"Subs",0)>=8
        do ##class(Rugby.Service.Matches).Substitute(m,side,changes.%Get(i))
    }
}
}
