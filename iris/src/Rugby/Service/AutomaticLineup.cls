Class Rugby.Service.AutomaticLineup Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Ability(p As %DynamicObject) As %Numeric
{
    quit (##class(Rugby.Service.Development).Average(p)*10000)+(p.energy/100)+(p.morale/10000)
}
ClassMethod Covers(p As %DynamicObject, roles As %DynamicArray) As %Boolean
{
    set covered=0
    for i=0:1:roles.%Size()-1 {
        set role=roles.%Get(i)
        if p.position=role { set covered=1 quit }
        for j=0:1:p.secondary.%Size()-1 { if p.secondary.%Get(j)=role { set covered=1 quit } }
        if covered quit
    }
    quit covered
}
ClassMethod Score(p As %DynamicObject, position As %Integer, ability As %Numeric = "") As %Numeric
{
    if (p.position<=8)'=(position<=8) quit -1000000
    if ability="" set ability=..Ability(p)
    set fit=$select(p.position=position:1000000000,..Covers(p,[(position)]):100000000,1:0)
    quit fit+ability
}
ClassMethod Assign(scores As %DynamicArray) As %DynamicArray
{
    set n=scores.%Size(),m=scores.%Get(0).%Size(),result=[]
    for j=0:1:m { set v(j)=0,chosen(j)=0,way(j)=0 }
    for i=0:1:n { set u(i)=0 }
    for i=1:1:n {
        set chosen(0)=i,j0=0
        kill minimum,used
        for j=0:1:m { set minimum(j)=1E30,used(j)=0 }
        for {
            set used(j0)=1,i0=chosen(j0),delta=1E30,j1=0
            for j=1:1:m {
                if used(j) continue
                set current=0-scores.%Get(i0-1).%Get(j-1)-u(i0)-v(j)
                if current<minimum(j) set minimum(j)=current,way(j)=j0
                if minimum(j)<delta set delta=minimum(j),j1=j
            }
            for j=0:1:m {
                if used(j) { set u(chosen(j))=u(chosen(j))+delta,v(j)=v(j)-delta }
                else { set minimum(j)=minimum(j)-delta }
            }
            set j0=j1
            quit:chosen(j0)=0
        }
        for { set j1=way(j0),chosen(j0)=chosen(j1),j0=j1 quit:j0=0 }
    }
    for i=0:1:n-1 { do result.%Push(-1) }
    for j=1:1:m { if chosen(j)>0 do result.%Set(chosen(j)-1,j-1) }
    quit result
}
ClassMethod Build(lineup As %DynamicObject, players As %DynamicArray) As %DynamicObject
{
    set available=[],abilities=[],order=""
    kill sorted
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.clubId'=lineup.clubId)||(p.category'="senior")||('p.available)||p.%Get("retired",0) continue
        set sorted(p.id)=p
    }
    for { set order=$order(sorted(order)) quit:order=""  set p=sorted(order) do available.%Push(p),abilities.%Push(..Ability(p)) }
    if available.%Size()<15 do ##class(Rugby.Service.Store).Fail(409,"AI_LINEUP","El rival no dispone de quince jugadores disponibles.")
    set scores=[]
    for pos=1:1:15 {
        set row=[]
        for i=0:1:available.%Size()-1 { do row.%Push(..Score(available.%Get(i),pos,abilities.%Get(i))) }
        do scores.%Push(row)
    }
    set selected=..Assign(scores),slots=[],used={}
    for i=0:1:14 {
        set column=selected.%Get(i)
        if (column<0)||(scores.%Get(i).%Get(column)<0) do ##class(Rugby.Service.Store).Fail(409,"AI_LINEUP","El rival no dispone de suficientes delanteros o tres cuartos.")
        set p=available.%Get(column)
        do slots.%Push({"position":(i+1),"playerId":(p.id)}),used.%Set(p.id,1)
    }
    set remaining=[],powers=[]
    for i=0:1:available.%Size()-1 { set p=available.%Get(i) if 'used.%IsDefined(p.id) { do remaining.%Push(p),powers.%Push(abilities.%Get(i)) } }
    set fullFront=0
    if remaining.%Size()>=3 {
        set scores=[]
        for pos=1:1:3 {
            set row=[]
            for i=0:1:remaining.%Size()-1 { do row.%Push($select(..Covers(remaining.%Get(i),[(pos)]):powers.%Get(i),1:-1000000)) }
            do scores.%Push(row)
        }
        set front=..Assign(scores),fullFront=1
        for i=0:1:2 { if scores.%Get(i).%Get(front.%Get(i))<0 set fullFront=0 }
    }
    set roles=$select(fullFront:[[1],[2],[3],[4,5],[6,7,8],[9],[10],[11,12,13,14,15]],1:[[1],[2],[3],[4,5,6,7,8],[9],[10],[11,12,13,14,15]]),scores=[]
    for r=0:1:roles.%Size()-1 {
        set positions=roles.%Get(r),row=[]
        for i=0:1:remaining.%Size()-1 {
            set p=remaining.%Get(i),same=(p.position<=8)=(positions.%Get(0)<=8),coverage=$select(same&&..Covers(p,positions):$select(r<3:10000000000,1:1000000000),same:10000000,1:0)
            do row.%Push(coverage+powers.%Get(i))
        }
        for i=1:1:roles.%Size() { do row.%Push(0) }
        do scores.%Push(row)
    }
    set reserves=..Assign(scores),bench=[]
    for i=0:1:reserves.%Size()-1 { set column=reserves.%Get(i) if column<remaining.%Size() { set p=remaining.%Get(column) do bench.%Push(p.id),used.%Set(p.id,1) } }
    set result=##class(%DynamicObject).%FromJSON(lineup.%ToJSON()),result.slots=slots,result.bench=bench
    if 'used.%IsDefined(result.captainId) {
        set captain="",best=-1
        for i=0:1:14 { set p=available.%Get(selected.%Get(i)),leadership=p.attributes.%Get("leadership",##class(Rugby.Service.Development).Average(p)) if leadership>best set captain=p.id,best=leadership }
        set result.captainId=captain
    }
    quit result
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"clubs":0}
    if $get(^RugbyWorld(game,"automaticLineupVersion"))=..#VERSION quit report
    set busy={},matches=##class(Rugby.Service.Store).All("Match"),clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:matches.%Size()-1 { set m=matches.%Get(i) if m.status'="finished" { do busy.%Set(m.homeId,1),busy.%Set(m.awayId,1) } }
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if (c.id=##class(Rugby.Service.Store).ManagedClub())||busy.%IsDefined(c.id) continue
        do ##class(Rugby.Service.Rivals).Lineup(c)
        set report.clubs=report.clubs+1
    }
    set ^RugbyWorld(game,"automaticLineupVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando alineaciones automáticas.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 {
            set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1"
            if %RugbyGame'="template" set %RugbyManagedClub=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)).clubId
            do reports.%Push(..Initialize())
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
    quit reports
}
}
