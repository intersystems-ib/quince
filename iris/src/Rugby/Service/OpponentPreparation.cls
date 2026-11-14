Class Rugby.Service.OpponentPreparation Extends %RegisteredObject
{
Parameter VERSION = "1.3.0";
ClassMethod Official(f As %DynamicObject) As %Boolean
{
    quit ('f.%Get("archived",0))&&$listfind($listbuild("regular","cup-group","quarterfinal","semifinal","final"),f.%Get("stage"))&&(f.homeId'="")&&(f.awayId'="")
}
ClassMethod Fixture(id As %String) As %DynamicObject
{
    set f=##class(Rugby.Service.Store).Get("Fixture",id),own=##class(Rugby.Service.Store).ManagedClub()
    if ((f.homeId'=own)&&(f.awayId'=own))||('..Official(f)) do ##class(Rugby.Service.Store).Fail(404,"PREPARATION_NOT_FOUND","No hay preparación disponible para este encuentro.")
    quit f
}
ClassMethod Meeting(f As %DynamicObject, c As %DynamicObject, fixtures = "") As %DynamicObject
{
    set day=f.day-2,opponent=$select(f.homeId=c.id:f.awayId,1:f.homeId),other=##class(Rugby.Service.Store).Get("Club",opponent),record=##class(Rugby.Service.Store).Get("OpponentPreparation",f.id,0),closed=f.status'="scheduled"
    if f.matchId'="" { set match=##class(Rugby.Service.Store).Get("Match",f.matchId,0) if $isobject(match)&&(match.status'="scheduled") set closed=1 }
    if '$isobject(fixtures) set fixtures=##class(Rugby.Service.Competition).ClubFixtures(c.id)
    set start=$zdateh(##class(Rugby.Service.Competition).Year(f.date)_"-09-01",3)-$zdateh("2026-11-07",3),last=start-1,previousFinished=1
    for i=0:1:fixtures.%Size()-1 {
        set previous=fixtures.%Get(i)
        if (previous.id'=f.id)&&(previous.day<f.day)&&(previous.day>last) { set last=previous.day,start=previous.day+1,previousFinished=previous.status="finished" }
    }
    set result={"fixtureId":(f.id),"date":($zdate(day+$zdateh("2026-11-07",3),3)),"day":(day),"matchDate":(f.date),"matchDay":(f.day),"preparationStartDay":(start),"preparationStartDate":(##class(Rugby.Service.Injuries).Date(start)),"opponentId":(opponent),"opponentName":(other.name),"stage":(f.stage),"lineupId":($select($isobject(record):record.%Get("lineupId"),1:""))}
    do result.%Set("closed",closed||(c.day>f.day),"boolean"),result.%Set("available",('closed)&&(c.day>=day)&&(c.day<=f.day),"boolean"),result.%Set("applied",$isobject(record),"boolean")
    do result.%Set("preparing",('closed)&&(c.day<day)&&previousFinished&&(c.day>=start),"boolean")
    quit result
}
ClassMethod List(club As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    set c=##class(Rugby.Service.Store).Get("Club",club),fixtures=##class(Rugby.Service.Competition).ClubFixtures(club),items=[]
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if ..Official(f) do items.%Push(..Meeting(f,c,fixtures)) }
    quit {"items":(items)}
}
ClassMethod Snapshot(p As %DynamicObject, position As %Integer) As %DynamicObject
{
    set s={"playerId":(p.id),"position":(position),"naturalPosition":(p.position),"secondary":(p.secondary),"status":"field","attributes":(##class(%DynamicObject).%FromJSON(p.attributes.%ToJSON())),"energy":(p.energy),"form":(p.form),"morale":(p.morale)}
    do ##class(Rugby.Simulation.Performance).ApplyMorale(s)
    quit s
}
ClassMethod Players(l As %DynamicObject) As %DynamicArray
{
    set players=[]
    for i=0:1:l.slots.%Size()-1 {
        set slot=l.slots.%Get(i),p=##class(Rugby.Service.Store).Get("Player",slot.playerId,0)
        if '$isobject(p) continue
        if (p.clubId'=l.clubId)||(p.category'="senior")||('p.available) continue
        do players.%Push(..Snapshot(p,slot.position))
    }
    quit players
}
ClassMethod Probable(club As %String, fixture As %String, q As %DynamicObject) As %DynamicArray
{
    set roster=##class(Rugby.Service.Store).All("Player","clubId",club),used={},players=[],catalog=##class(Rugby.Service.Development).Catalog()
    for pos=1:1:15 {
        set id=##class(Rugby.Service.Rivals).Pick(roster,used,pos,1)
        if id="" set id=##class(Rugby.Service.Rivals).Pick(roster,used,pos)
        if id="" continue
        set p=##class(Rugby.Service.Store).Get("Player",id),s=..Snapshot(p,pos)
        do used.%Set(id,1)
        for k=0:1:16 {
            set t=catalog.%Get(k),quality=(q.head*.4)+(q.%Get(t.coachRole,35)*.6),radius=(100-quality)/12,noise=((##class(Rugby.Service.Rivals).Hash(fixture_"-"_id_"-"_t.id)#2001)-1000)/1000
            do s.attributes.%Set(t.id,##class(Rugby.Simulation.Engine).Clamp(s.attributes.%Get(t.id)+(noise*radius),1,100))
        }
        set s.energy=##class(Rugby.Simulation.Engine).Clamp(s.energy+(((##class(Rugby.Service.Rivals).Hash(fixture_"-"_id_"-energy")#2001)-1000)/1000*((100-q.head)/12)),0,100),s.form=##class(Rugby.Service.Development).Average(s)
        do players.%Push(s)
    }
    quit players
}
ClassMethod Aspects(a As %DynamicObject, b As %DynamicObject, q As %DynamicObject) As %DynamicArray
{
    set rows=[],definitions=[{"id":"setPieces","name":"Formaciones fijas","group":"forwards","role":"forwards","attributes":["scrum","lineout","strength"]},{"id":"contact","name":"Contacto y conquista","group":"forwards","role":"forwards","attributes":["strength","ruck","maul","stamina"]},{"id":"attack","name":"Ataque abierto","group":"backs","role":"backs","attributes":["passing","handling","speed","agility"]},{"id":"defense","name":"Defensa","group":"all","role":"defense","attributes":["tackling","defensiveReading","discipline"]},{"id":"kicking","name":"Juego al pie","group":"backs","role":"backs","attributes":["kicking","decisions"]}]
    for i=0:1:definitions.%Size()-1 {
        set d=definitions.%Get(i),own=0,opponent=0
        for j=0:1:d.attributes.%Size()-1 { set key=d.attributes.%Get(j),own=own+a.%Get(d.group).%Get(key),opponent=opponent+b.%Get(d.group).%Get(key) }
        set own=own/d.attributes.%Size(),opponent=opponent/d.attributes.%Size(),quality=(q.head*.4)+(q.%Get(d.role)*.6),uncertainty=((100-quality)/12+.999)\1
        do rows.%Push({"id":(d.id),"name":(d.name),"group":(d.group),"own":(own),"opponent":(opponent),"delta":(own-opponent),"uncertainty":(uncertainty)})
    }
    quit rows
}
ClassMethod Risk(t As %DynamicObject) As %String
{
    set text=$select(t.style="hands":"El juego a la mano exige precisión en pase y recepción.",t.style="kicking":"El juego al pie cede posesión y exige perseguir las patadas.",1:"El equilibrio reduce la especialización en nuestras ventajas.")
    if t.tempo="fast" set text=text_" El ritmo alto aumenta el desgaste."
    if t.tempo="slow" set text=text_" El ritmo pausado reduce las oportunidades de acelerar el ataque."
    if t.defense="high" set text=text_" La presión alta exige energía y disciplina."
    set text=text_" "_$select(t.%Get("penaltyPriority","auto")="posts":"Se priorizan los tiros a palos alcanzables.",t.%Get("penaltyPriority","auto")="touch":"Se renuncia a tiros a palos para buscar el ensayo.",t.%Get("penaltyPriority","auto")="quick":"Jugar rápido puede provocar pérdidas de balón.",1:"Los golpes se deciden según marcador, tiempo y alcance del pateador.")
    quit text
}
ClassMethod Report(id As %String, lineupId As %String = "") As %DynamicObject
{
    set f=..Fixture(id),club=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",club),meeting=..Meeting(f,c)
    if meeting.closed do ##class(Rugby.Service.Store).Fail(409,"PREPARATION_CLOSED","La preparación se cierra al comenzar el partido.")
    if 'meeting.available do ##class(Rugby.Service.Store).Fail(409,"PREPARATION_FUTURE",$select(meeting.preparing:"El cuerpo técnico está trabajando en la elaboración del informe. ",1:"La preparación comenzará después del partido anterior. ")_"El análisis estará disponible el "_meeting.date_".")
    set match="",record=##class(Rugby.Service.Store).Get("OpponentPreparation",id,0)
    if f.matchId'="" set match=##class(Rugby.Service.Store).Get("Match",f.matchId)
    if lineupId="" set lineupId=$select($isobject(match):match.lineupId,1:club_"-default")
    set l=##class(Rugby.Service.Store).Get("Lineup",lineupId)
    do ##class(Rugby.Service.Store).Managed(l.clubId)
    if $isobject(match)&&(match.lineupId'=lineupId) do ##class(Rugby.Service.Store).Fail(409,"PREPARATION_LINEUP","Elige la alineación seleccionada para este partido.")
    set validation=##class(Rugby.Service.Management).Validate(l),own=..Players(l),q=##class(Rugby.Service.Staff).Qualities(club),opponent=..Probable(meeting.opponentId,id,q),a=##class(Rugby.Simulation.Tactics).Profile(own),b=##class(Rugby.Simulation.Tactics).Profile(opponent),rows=..Aspects(a,b,q),advantages=[],risks=[]
    kill positive,negative
    for i=0:1:rows.%Size()-1 {
        set row=rows.%Get(i),threshold=$select(row.uncertainty>4:row.uncertainty/2,1:2)
        if row.delta>=threshold set positive(-row.delta,row.id)=row.name_": ventaja prevista de "_$justify(row.delta,0,0)_" puntos."
        if row.delta<(-threshold) set negative(row.delta,row.id)=row.name_": el rival nos supera en unos "_$justify(-row.delta,0,0)_" puntos."
    }
    set n=""
    for { set n=$order(positive(n)) quit:n=""  set key="" for { set key=$order(positive(n,key)) quit:key=""  if advantages.%Size()<2 do advantages.%Push(positive(n,key)) } }
    set n=""
    for { set n=$order(negative(n)) quit:n=""  set key="" for { set key=$order(negative(n,key)) quit:key=""  if risks.%Size()<2 do risks.%Push(negative(n,key)) } }
    set decision=##class(Rugby.Simulation.Tactics).Decide(own,opponent),main=decision.tactic,alternative={"style":($select(main.style'="balanced":"balanced",a.backs.passing>=a.backs.kicking:"hands",1:"kicking")),"tempo":($select(a.energy<50:"slow",1:"normal")),"defense":($select(a.energy<50:"low",1:"normal")),"penaltyPriority":"auto"},quality=(q.head+q.forwards+q.backs+q.defense)/4
    set signatureSlots=[]
    for i=0:1:l.slots.%Size()-1 { set slot=l.slots.%Get(i) do signatureSlots.%Push({"position":(slot.position),"playerId":(slot.playerId)}) }
    set signature={"modelVersion":(..#VERSION),"fixtureId":(id),"day":(f.day),"date":(f.date),"clubDay":(c.day),"lineupId":(l.id),"slots":(signatureSlots),"own":(own),"opponent":(opponent),"qualities":(q)},token=##class(Rugby.Service.Auth).Encode($system.Encryption.SHAHash(256,signature.%ToJSON())),groups={"own":{},"opponent":{}}
    for group="all","forwards","backs" { do groups.own.%Set(group,##class(Rugby.Simulation.Tactics).Summary(own,group)),groups.opponent.%Set(group,##class(Rugby.Simulation.Tactics).Summary(opponent,group)) }
    set result={"fixtureId":(id),"meeting":(meeting),"ownName":(c.name),"clubId":(club),"opponentName":(meeting.opponentName),"opponentId":(meeting.opponentId),"lineupId":(l.id),"lineupName":(l.name),"lineupVersion":(l.version),"reportToken":(token),"currentTactic":(l.tactic),"aspects":(rows),"groups":(groups),"advantages":(advantages),"risks":(risks),"confidence":{"quality":(quality),"label":($select(quality>=75:"Alta",quality>=50:"Media",1:"Orientativa"))},"recommendation":{"tactic":(main),"reason":(decision.reason),"risk":(..Risk(main))},"alternative":{"tactic":(alternative),"reason":($select(alternative.style="balanced":"Un plan equilibrado con un ritmo sostenible.",alternative.style="hands":"Otra vía para aprovechar el pase y la movilidad.",1:"Una alternativa territorial apoyada en el juego al pie.")),"risk":(..Risk(alternative))},"validationErrors":(validation.errors)}
    do result.%Set("lineupLocked",$isobject(match),"boolean")
    do result.%Set("ready",validation.valid&&(opponent.%Size()=15),"boolean")
    if $isobject(record) {
        set result.lastApplied={"date":(record.date),"lineupId":(record.lineupId),"tactic":(record.tactic),"choice":(record.choice)}
        do result.lastApplied.%Set("outdated",record.reportToken'=token,"boolean"),result.lastApplied.%Set("tacticChanged",record.tactic.%ToJSON()'=l.tactic.%ToJSON(),"boolean")
    }
    quit result
}
ClassMethod Apply(id As %String, input As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game(),club=##class(Rugby.Service.Store).ManagedClub()
    if $data(^RugbyWorld(game,"retry","preparation",id,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","preparation",id,key))
    set report=..Report(id,input.%Get("lineupId")),l=##class(Rugby.Service.Store).Get("Lineup",report.lineupId)
    if (input.%Get("reportToken")'=report.reportToken)||(input.%Get("lineupVersion",-1)'=l.version) do ##class(Rugby.Service.Store).Fail(409,"PREPARATION_CHANGED","El equipo ha cambiado. Actualiza el informe antes de aplicar una propuesta.")
    if 'report.ready do ##class(Rugby.Service.Store).Fail(422,"PREPARATION_LINEUP","Revisa la alineación y los jugadores disponibles antes de aplicar el plan.")
    set choice=input.%Get("choice"),tactic=""
    if choice="main" set tactic=report.recommendation.tactic
    if choice="alternative" set tactic=report.alternative.tactic
    if choice="custom" set tactic=input.%Get("tactic")
    if '$isobject(tactic) do ##class(Rugby.Service.Store).Fail(422,"PREPARATION_CHOICE","Elige una propuesta o define una táctica.")
    do ##class(Rugby.Service.Management).Tactic(tactic)
    set l.tactic=tactic,l=##class(Rugby.Service.Management).SaveLineup(l.id,l),c=##class(Rugby.Service.Store).Get("Club",club)
    set record={"id":(id),"clubId":(club),"fixtureId":(id),"date":(c.date),"day":(c.day),"lineupId":(l.id),"choice":(choice),"tactic":(tactic),"reportToken":(report.reportToken),"report":(report)}
    do ##class(Rugby.Service.Store).Put("OpponentPreparation",record)
    set result=..Report(id,l.id),^RugbyWorld(game,"retry","preparation",id,key)=result.%ToJSON()
    quit result
}
}
