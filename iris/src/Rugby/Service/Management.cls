Class Rugby.Service.Management Extends %RegisteredObject
{
ClassMethod NormalizeBench(l As %DynamicObject) As %DynamicArray
{
    set bench=l.%Get("bench"),kept=[],removed=[],captainRemoved=0
    if '$isobject(bench) quit removed
    if 'bench.%IsA("%Library.DynamicArray") quit removed
    for i=0:1:bench.%Size()-1 {
        set id=bench.%Get(i),p=##class(Rugby.Service.Store).Get("Player",id,0)
        if $isobject(p)&&(p.clubId=l.clubId)&&(p.category="senior")&&('p.available) {
            do removed.%Push(id)
            if id=l.%Get("captainId") set captainRemoved=1
        } else { do kept.%Push(id) }
    }
    if removed.%Size()=0 quit removed
    set l.bench=kept
    if captainRemoved {
        set l.captainId="",slots=l.%Get("slots")
        if $isobject(slots)&&slots.%IsA("%Library.DynamicArray") {
            for i=0:1:slots.%Size()-1 {
                set s=slots.%Get(i)
                if '$isobject(s) continue
                set p=##class(Rugby.Service.Store).Get("Player",s.%Get("playerId"),0)
                if $isobject(p)&&(p.clubId=l.clubId)&&p.available { set l.captainId=p.id quit }
            }
        }
        if (l.captainId="")&&(kept.%Size()>0) set l.captainId=kept.%Get(0)
    }
    quit removed
}
ClassMethod RefreshAvailability(club As %String)
{
    set lineups=##class(Rugby.Service.Store).All("Lineup","clubId",club)
    for i=0:1:lineups.%Size()-1 {
        set l=lineups.%Get(i),removed=..NormalizeBench(l)
        if removed.%Size()>0 do ##class(Rugby.Service.Store).Put("Lineup",l)
    }
}
ClassMethod Validate(l As %DynamicObject) As %DynamicObject
{
    set errors=[],seen={},slots=l.%Get("slots"),bench=l.%Get("bench"),front={}
    if ($length(l.%Get("name"))<1)||($length(l.%Get("name"))>80) do errors.%Push("El nombre debe tener entre 1 y 80 caracteres.")
    if '$isobject(slots) do errors.%Push("Debes elegir quince titulares.") quit {"valid":false,"errors":(errors)}
    if 'slots.%IsA("%Library.DynamicArray") do errors.%Push("Los titulares deben ser una lista.") quit {"valid":false,"errors":(errors)}
    if slots.%Size()'=15 do errors.%Push("Debes elegir quince titulares.")
    if '$isobject(bench) { do errors.%Push("El banquillo debe ser una lista.") set bench=[] }
    if 'bench.%IsA("%Library.DynamicArray") { do errors.%Push("El banquillo debe ser una lista.") set bench=[] }
    do ..NormalizeBench(l)
    if $isobject(l.%Get("bench")),l.bench.%IsA("%Library.DynamicArray") set bench=l.bench
    if bench.%Size()>8 do errors.%Push("El banquillo admite hasta ocho jugadores.")
    for i=0:1:slots.%Size()+bench.%Size()-1 {
        set starter=i<slots.%Size()
        if starter {
            set slot=slots.%Get(i)
            if '$isobject(slot) { do errors.%Push("Cada titular necesita posición y jugador.") continue }
            set pid=slot.%Get("playerId"),pos=slot.%Get("position")
            if pos'=(i+1) do errors.%Push("Los titulares deben cubrir, en orden, las posiciones 1 a 15.")
        } else { set pid=bench.%Get(i-slots.%Size()),pos=0 }
        if seen.%IsDefined(pid) do errors.%Push("Jugador duplicado: "_pid)
        do seen.%Set(pid,1)
        set p=##class(Rugby.Service.Store).Get("Player",pid,0)
        if '$isobject(p) { do errors.%Push("Jugador inexistente: "_pid) continue }
        if (p.clubId'=l.clubId)||(p.category'="senior") do errors.%Push(p.name_" no pertenece al primer equipo.")
        if 'p.available do errors.%Push(p.name_" no está disponible.")
        if p.position<=3 do front.%Set(p.position,1)
    }
    if 'seen.%IsDefined(l.%Get("captainId")) do errors.%Push("El capitán debe estar convocado.")
    do ..Tactic(l.%Get("tactic"))
    set result={"errors":(errors)}
    do result.%Set("valid",errors.%Size()=0,"boolean")
    quit result
}
ClassMethod Tactic(t As %DynamicObject)
{
    if '$isobject(t) do ##class(Rugby.Service.Store).Fail(422,"TACTIC","Falta la táctica.")
    if '$listfind($listbuild("hands","balanced","kicking"),t.%Get("style")) do ##class(Rugby.Service.Store).Fail(422,"TACTIC","Estilo no válido.")
    if '$listfind($listbuild("slow","normal","fast"),t.%Get("tempo")) do ##class(Rugby.Service.Store).Fail(422,"TACTIC","Ritmo no válido.")
    if '$listfind($listbuild("low","normal","high"),t.%Get("defense")) do ##class(Rugby.Service.Store).Fail(422,"TACTIC","Defensa no válida.")
}
ClassMethod SaveLineup(id As %String, b As %DynamicObject) As %DynamicObject
{
    if id="" { set id=(##class(Rugby.Service.Store).ManagedClub()_"-")_$increment(^RugbyWorld(##class(Rugby.Service.Store).Game(),"ids","Lineup")),b.id=id,b.clubId=##class(Rugby.Service.Store).ManagedClub() } else {
        set old=##class(Rugby.Service.Store).Get("Lineup",id)
        do ##class(Rugby.Service.Store).Managed(old.clubId)
        do ##class(Rugby.Service.Store).CheckVersion(old,b)
        set b.id=id,b.clubId=old.clubId
    }
    do ##class(Rugby.Service.Store).Managed(b.clubId)
    set valid=..Validate(b)
    if 'valid.valid do ##class(Rugby.Service.Store).Fail(422,"INVALID_LINEUP",valid.errors.%ToJSON())
    do ##class(Rugby.Service.Store).Put("Lineup",b)
    for i=0:1:b.slots.%Size()-1 { set slot=b.slots.%Get(i),slot.id=id_"-"_(i+1),slot.clubId=b.clubId do ##class(Rugby.Service.Store).Put("LineupSlot",slot) }
    set t=##class(%DynamicObject).%FromJSON(b.tactic.%ToJSON()),t.id=id,t.clubId=b.clubId
    do ##class(Rugby.Service.Store).Put("Tactic",t)
    quit b
}
ClassMethod Promote(club As %String, pid As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el encuentro antes de promocionar jugadores.")
    set p=##class(Rugby.Service.Store).Get("Player",pid)
    if p.clubId'=club do ##class(Rugby.Service.Store).Fail(403,"PLAYER_CLUB","El jugador pertenece a otro club.")
    if p.category="academy" {
        do ##class(Rugby.Service.Payroll).Check(club,p.id,p.%Get("seniorWeeklyWage",45000))
        set p.category="senior",p.weeklyWage=p.%Get("seniorWeeklyWage",45000)
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    quit p
}
ClassMethod Training(club As %String, b As %DynamicObject) As %DynamicObject
{
    quit ##class(Rugby.Service.Development).Save(club,b)
}
ClassMethod Release(pid As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","release",pid,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","release",pid,key))
    set p=##class(Rugby.Service.Store).Get("Player",pid),club=p.clubId
    if club="" do ##class(Rugby.Service.Store).Fail(409,"NO_CONTRACT","El jugador ya no tiene contrato con el club.")
    do ##class(Rugby.Service.Store).Managed(club)
    if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el partido en curso antes de rescindir un contrato.")
    do ##class(Rugby.Service.Store).CheckVersion(p,b)
    set lineups=##class(Rugby.Service.Store).All("Lineup","clubId",club)
    for i=0:1:lineups.%Size()-1 {
        set l=lineups.%Get(i),changed=0,bench=[]
        for j=0:1:l.slots.%Size()-1 {
            set slot=l.slots.%Get(j)
            if slot.playerId=pid {
                set slot.playerId="",changed=1,slot.id=l.id_"-"_(j+1),slot.clubId=club
                do ##class(Rugby.Service.Store).Put("LineupSlot",slot)
            }
        }
        for j=0:1:l.bench.%Size()-1 { set id=l.bench.%Get(j) if id=pid { set changed=1 } else { do bench.%Push(id) } }
        if l.captainId=pid set l.captainId="",changed=1
        if changed { set l.bench=bench do ##class(Rugby.Service.Store).Put("Lineup",l) }
    }
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan",club),groups=[],changed=0
    for i=0:1:plan.groups.%Size()-1 {
        set g=plan.groups.%Get(i),ids=[]
        for j=0:1:g.playerIds.%Size()-1 { set id=g.playerIds.%Get(j) if id=pid { set changed=1 } else { do ids.%Push(id) } }
        if ids.%Size() do groups.%Push({"id":(g.id),"name":(g.name),"focus":(g.focus),"intensity":(g.intensity),"playerIds":(ids)})
    }
    if changed set saved=##class(Rugby.Service.Development).Save(club,{"version":(plan.version),"groups":(groups)})
    set c=##class(Rugby.Service.Store).Get("Club",club)
    set contract={"id":(pid_"-release-"_key),"clubId":(club),"playerId":(pid),"playerName":(p.name),"category":(p.category),"kind":"release","day":(c.day),"weeklyWage":(p.weeklyWage),"fee":0,"idempotencyKey":(key)}
    do ##class(Rugby.Service.Store).Put("PlayerContract",contract)
    set p.formerClubId=club,p.releasedDay=c.day,p.previousWeeklyWage=p.weeklyWage,p.clubId="",p.weeklyWage=0,p.contractStatus="released"
    do ##class(Rugby.Service.Store).Put("Player",p)
    set pool=##class(Rugby.Service.TransferPool).Refresh(c.day)
    set result={"playerId":(pid),"name":(p.name),"formerClubId":(club),"status":"released","day":(c.day),"fee":0},^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","release",pid,key)=result.%ToJSON()
    quit result
}
ClassMethod Money(club As %DynamicObject, amount As %Integer, type As %String, concept As %String, key As %String)
{
    set id=club.id_"-"_key
    if $isobject(##class(Rugby.Service.Store).Get("FinancialMovement",id,0)) quit
    set m={"id":(id),"clubId":(club.id),"day":(club.day),"date":(club.date),"amount":(amount),"type":(type),"concept":(concept),"source":(key),"idempotencyKey":(key)}
    set club.balance=club.balance+amount
    do ##class(Rugby.Service.Store).Put("FinancialMovement",m)
    do ##class(Rugby.Service.Store).Put("Club",club)
}
ClassMethod Advance(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    do ##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","day",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","day",club,key))
    if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","No puedes avanzar días con un partido en curso.")
    set c=##class(Rugby.Service.Store).Get("Club",club)
    do ##class(Rugby.Service.Store).CheckVersion(c,b)
    set fixtures=##class(Rugby.Service.Store).All("Fixture")
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i)
        if f.%Get("archived",0) continue
        if (f.day<=c.day)&&(f.status'="finished")&&((f.homeId=club)||(f.awayId=club)) do ##class(Rugby.Service.Store).Fail(409,"MATCH_PENDING","Debes disputar el partido pendiente del "_f.%Get("date",c.date)_" antes de avanzar. Consulta el calendario.")
    }
    do ##class(Rugby.Service.Rivals).Initialize()
    set payroll=##class(Rugby.Service.MonthlyPayroll).Tick(club,c.day),c=##class(Rugby.Service.Store).Get("Club",club)
    set c.day=c.day+1,c.date=$zdate($zdateh("2026-11-07",3)+c.day,3)
    set execution=##class(Rugby.Service.Development).Process(club,c.day)
    do ##class(Rugby.Service.Store).Put("Club",c)

    set announcements=##class(Rugby.Service.Seasons).Announce(c.day),rivals=##class(Rugby.Service.Rivals).Day(c.day)
    do ##class(Rugby.Service.Competition).Sync(c.day)
    set rivals.monthlyPayroll=payroll,rivals.financeExecution=##class(Rugby.Service.Finance).TickAll(c.day)
    set rivals.retirementAnnouncements=announcements,rivals.seasonTransition=##class(Rugby.Service.Seasons).Tick(c.day)
    do ##class(Rugby.Service.Store).Put("RivalExecution",rivals)
    set c=##class(Rugby.Service.Store).Get("Club",club)
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","day",club,key)=c.%ToJSON()
    quit c
}
}
