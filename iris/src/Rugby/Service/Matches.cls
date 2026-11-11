Class Rugby.Service.Matches Extends %RegisteredObject
{
ClassMethod Create(b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","match",key)) quit ##class(Rugby.Service.Store).Get("Match",^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","match",key))
    set f=##class(Rugby.Service.Store).Get("Fixture",b.%Get("fixtureId")),club=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub())
    do ##class(Rugby.Service.Store).Managed(f.clubId)
    if f.%Get("archived",0) do ##class(Rugby.Service.Store).Fail(409,"FIXTURE_ARCHIVED","El amistoso está archivado. Consulta la competición.")
    if f.matchId'="" quit ##class(Rugby.Service.Store).Get("Match",f.matchId)
    if f.status'="scheduled" do ##class(Rugby.Service.Store).Fail(409,"FIXTURE_STATE","El encuentro no está pendiente.")
    if f.day>club.day do ##class(Rugby.Service.Store).Fail(409,"FIXTURE_FUTURE","Avanza hasta la fecha del encuentro.")
    if ##class(Rugby.Service.Store).Active(##class(Rugby.Service.Store).ManagedClub()) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Ya hay un partido en curso.")
    set lineup=##class(Rugby.Service.Store).Get("Lineup",b.%Get("lineupId",(##class(Rugby.Service.Store).ManagedClub()_"-default")))
    do ##class(Rugby.Service.Store).Managed(lineup.clubId)
    set validation=##class(Rugby.Service.Management).Validate(lineup)
    if 'validation.valid do ##class(Rugby.Service.Store).Fail(422,"INVALID_LINEUP",validation.errors.%ToJSON())
    set seed=b.%Get("seed",f.%Get("seed",17341))
    if '##class(Rugby.Service.Store).Integer(seed,1,2147483646) do ##class(Rugby.Service.Store).Fail(422,"SEED","La semilla debe estar entre 1 y 2147483646.")
    set id="m"_$increment(^RugbyWorld(##class(Rugby.Service.Store).Game(),"ids","Match")),home=##class(Rugby.Service.Store).Get("Club",f.homeId),away=##class(Rugby.Service.Store).Get("Club",f.awayId)
    set m={"id":(id),"clubId":(##class(Rugby.Service.Store).ManagedClub()),"fixtureId":(f.id),"homeId":(f.homeId),"awayId":(f.awayId),"homeName":(home.name),"awayName":(away.name),"homeColor":(home.color),"awayColor":(away.color),"lineupId":(lineup.id),"status":"scheduled","period":1,"clock":0,"speed":20,"credit":0,"homeScore":0,"awayScore":0,"possession":"home","x":50,"y":35,"phase":"restart","seed":(seed),"rng":(seed),"engineVersion":(##class(Rugby.Simulation.Engine).#VERSION),"sequence":0,"commandSequence":0,"settled":false,"homeSubs":0,"awaySubs":0,"homePlayers":[],"awayPlayers":[],"homeStats":{},"awayStats":{},"homeTactic":{},"awayTactic":{}}
    do ##class(Rugby.Service.Kits).Apply(m,home,away)
    set m.groupId=f.%Get("groupId"),m.competitionType=f.%Get("competitionType"),m.competitionKey=f.%Get("competitionKey"),m.stage=f.%Get("stage","friendly"),m.round=f.%Get("round",0),m.date=f.%Get("date",club.date)
    do ##class(Rugby.Service.Store).Put("Match",m)
    set f.matchId=id
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","match",key)=id
    quit m
}
ClassMethod Start(id As %String) As %DynamicObject
{
    set m=##class(Rugby.Service.Store).Get("Match",id)
    if m.status'="scheduled" quit m
    if ##class(Rugby.Service.Store).Active(##class(Rugby.Service.Store).ManagedClub()) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Ya hay un partido activo.")
    for side="home","away" {
        set cid=m.%Get(side_"Id"),l=##class(Rugby.Service.Store).Get("Lineup",$select(cid=##class(Rugby.Service.Store).ManagedClub():m.lineupId,1:cid_"-default")),v=##class(Rugby.Service.Management).Validate(l)
        if 'v.valid do ##class(Rugby.Service.Store).Fail(422,"INVALID_LINEUP",v.errors.%ToJSON())
        set snapshots=[]
        for i=0:1:l.slots.%Size()+l.bench.%Size()-1 {
            set starter=i<15,pid=$select(starter:l.slots.%Get(i).playerId,1:l.bench.%Get(i-15))
            set p=##class(Rugby.Service.Store).Get("Player",pid)
            set s={"id":(id_"-"_pid),"matchId":(id),"playerId":(pid),"clubId":(cid),"side":(side),"name":(p.name),"attributes":(p.attributes),"naturalPosition":(p.position),"secondary":(p.secondary),"position":($select(starter:i+1,1:p.position)),"status":($select(starter:"field",1:"bench")),"playedSeconds":0,"yellowCards":0,"redCards":0,"sinBinUntil":0,"cards":[],"energy":(p.energy),"form":(p.form),"morale":(p.morale),"stats":{"actions":0,"tries":0,"points":0}}
            set s.age=p.age
            do ##class(Rugby.Simulation.Performance).ApplyMorale(s)
            do snapshots.%Push(s)
            do ##class(Rugby.Service.Store).Put("MatchPlayer",s)
        }
        do m.%Set(side_"Players",snapshots)
        do m.%Set(side_"Tactic",l.tactic)
        do m.%Set(side_"Stats",{"actions":0,"possessionSeconds":0,"metres":0,"tackles":0,"turnovers":0,"scrums":0,"lineouts":0,"penalties":0,"tries":0,"conversions":0,"penaltyGoals":0,"drops":0,"kicks":0,"passes":0,"yellowCards":0,"redCards":0,"infringements":0})
    }
    set m.economySnapshot=##class(Rugby.Service.Finance).Forecast(m)
    set m.status="first",m.disciplineVersion=##class(Rugby.Simulation.Discipline).#VERSION,m.redCardRule="permanent"
    do ##class(Rugby.Simulation.Tactics).Adapt(m,$select(m.homeId=##class(Rugby.Service.Store).ManagedClub():"away",1:"home"),1)
    do ##class(Rugby.Simulation.Engine).Event(m,"kickoff","home","Comienza el encuentro. Balón al centro.",0,50,35,"")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId),f.status="live"
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    quit m
}
ClassMethod Pause(m As %DynamicObject, reason As %String, message As %String, playerId As %String = "")
{
    if m.status="finished" quit
    if (m.%Get("speed",1)=0)&&(m.%Get("pauseReason")'="manual")&&(reason'="manual") set message=m.%Get("pauseMessage")_" "_message
    set m.speed=0,m.credit=0,m.pauseReason=reason,m.pauseMessage=message,m.pausedClock=m.clock,m.pausedPlayerId=playerId
}
ClassMethod CheckCommand(m As %DynamicObject, b As %DynamicObject, side As %String) As %String
{
    if (m.status="finished")||(m.status="scheduled") quit "El partido no está en juego."
    set type=b.%Get("type")
    if type="speed" {
        if '$listfind($listbuild(0,1,5,20,60),b.%Get("speed")) quit "Velocidad permitida: pausa (0), 1, 5, 20 o 60."
        quit ""
    }
    if type="tactic" { do ##class(Rugby.Service.Management).Tactic(b.%Get("tactic")) quit "" }
    if type'="substitution" quit "Tipo de comando desconocido."
    if m.%Get(side_"Subs")>=8 quit "Ya se han utilizado las ocho sustituciones."
    set players=m.%Get(side_"Players"),out="",in=""
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.playerId=b.%Get("outId") set out=p
        if p.playerId=b.%Get("inId") set in=p }
    if ('$isobject(out))||('$isobject(in)) quit "Ambos jugadores deben estar convocados en tu equipo."
    if (out.status'="field")&&(out.status'="injured") quit "El jugador que sale ya no está en el campo."
    if out.%Get("substituted",0) quit "El jugador ya ha sido sustituido."
    if in.status'="bench" quit "Solo puede entrar un suplente que no haya participado."
    if $isobject(in.%Get("injury")) quit "El suplente está lesionado."
    quit ""
}
ClassMethod Command(id As %String, b As %DynamicObject, key As %String, side As %String = "", source As %String = "user", current = "") As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set cid=id_"-"_source_"-"_key,old=##class(Rugby.Service.Store).Get("MatchCommand",cid,0)
    if $isobject(old) quit old
    set m=$select($isobject(current):current,1:##class(Rugby.Service.Store).Get("Match",id))
    if side="" set side=$select(m.homeId=##class(Rugby.Service.Store).ManagedClub():"home",1:"away")
    set reason=..CheckCommand(m,b,side)
    if reason'="" do ##class(Rugby.Service.Store).Fail(422,"INVALID_COMMAND",reason)
    set m.commandSequence=m.commandSequence+1
    set cmd={"id":(cid),"matchId":(id),"clubId":(m.%Get(side_"Id")),"side":(side),"type":(b.type),"parameters":(b),"idempotencyKey":(key),"sequence":(m.commandSequence),"status":"pending","receivedClock":(m.clock),"appliedClock":0,"reason":"","source":(source)}
    do ##class(Rugby.Service.Store).Put("MatchCommand",cmd)
    if '$isobject(current) do ##class(Rugby.Service.Store).Put("Match",m)
    quit cmd
}
ClassMethod Commands(m As %DynamicObject, speedOnly As %Boolean = 0)
{
    // Catalog keys are not receipt order. Sort explicitly by persisted sequence.
    set all=##class(Rugby.Service.Store).All("MatchCommand","matchId",m.id)
    kill ordered
    for i=0:1:all.%Size()-1 { set c=all.%Get(i) if c.status="pending" set ordered(c.sequence)=c }
    set seq=0
    for { set seq=$order(ordered(seq)) quit:seq=""  set c=ordered(seq),b=c.parameters
        if speedOnly&&(c.type'="speed") continue
        if 'speedOnly&&(c.type="speed") continue
        set reason=..CheckCommand(m,b,c.side)
        if reason'="" { set c.status="rejected",c.reason=reason } else {
            if c.type="speed" {
                if b.speed=0 { do ..Pause(m,"manual","Partido en pausa. Selecciona una velocidad para continuar.") }
                else { set m.speed=b.speed,m.pauseReason="",m.pauseMessage="",m.pausedPlayerId="" }
            }
            if c.type="tactic" do m.%Set(c.side_"Tactic",b.tactic)
            if c.type="substitution" {
                set players=m.%Get(c.side_"Players"),pos=0
                for i=0:1:players.%Size()-1 {
                    set p=players.%Get(i)
                    if p.playerId=b.outId {
                        set pos=p.position,p.substituted=1
                        if p.status'="injured" set p.status="replaced"
                        do ##class(Rugby.Simulation.Performance).ApplyMorale(p)
                    }
                }
                for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.playerId=b.inId set p.position=pos,p.status="field" do ##class(Rugby.Simulation.Performance).ApplyMorale(p) }
                do m.%Set(c.side_"Subs",m.%Get(c.side_"Subs")+1)
            }
            set c.status="applied",c.appliedClock=m.clock
            set text=$select(c.type="speed":$select(b.speed=0:"Partido en pausa.",1:"Velocidad x"_b.speed),c.type="tactic":"Cambio táctico confirmado.",1:"Sustitución confirmada.")
            if (c.type="tactic")&&(c.source="ai")&&$isobject(b.%Get("assessment")) set text="El rival ajusta su táctica. "_b.assessment.reason
            do ##class(Rugby.Simulation.Engine).Event(m,"command",c.side,text,0,m.x,m.y,"",b.%Get("assessment"))
        }
        do ##class(Rugby.Service.Store).Put("MatchCommand",c)
    }
}
ClassMethod AI(m As %DynamicObject)
{
    set side=$select(m.homeId=##class(Rugby.Service.Store).ManagedClub():"away",1:"home"),players=m.%Get(side_"Players")
    if m.%Get(side_"Subs")<8 {
        set found=0
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            set injured=(p.status="injured")&&('p.%Get("substituted",0)),tired=(p.status="field")&&(p.energy<=66)&&(m.clock>=3000)
            if ('injured)&&('tired) continue
            for j=0:1:players.%Size()-1 {
                set q=players.%Get(j)
                set compatible=(p.position<=8)=(q.naturalPosition<=8)
                if (q.status="bench")&&compatible {
                    do ..Command(m.id,{"type":"substitution","outId":(p.playerId),"inId":(q.playerId)},"sub-"_m.clock,side,"ai",m)
                    set found=1 quit
                }
            }
            quit:found
        }
    }
    do ##class(Rugby.Simulation.Tactics).Adapt(m,side)
}
ClassMethod Settle(m As %DynamicObject)
{
    if m.settled quit
    set club=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub())
    set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId),m.economy=##class(Rugby.Service.Finance).Settle(f,m.%Get("economySnapshot"))
    set m.moraleResults=[]
    for side="home","away" {
        set players=m.%Get(side_"Players"),ownScore=m.%Get(side_"Score"),otherScore=m.%Get($select(side="home":"away",1:"home")_"Score")
        for i=0:1:players.%Size()-1 {
            set s=players.%Get(i),p=##class(Rugby.Service.Store).Get("Player",s.playerId)
            set p.energy=s.energy
            do ##class(Rugby.Service.Store).Put("Player",p)
        }
        set outcome=$select(m.%Get("winnerId")'="":$select(m.winnerId=m.%Get(side_"Id"):"win",1:"loss"),ownScore>otherScore:"win",ownScore<otherScore:"loss",1:"draw")
        do m.moraleResults.%Push(##class(Rugby.Service.Morale).Result(m.%Get(side_"Id"),club.day,"match-"_m.id,outcome,players))
    }
    set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId),f.economy=m.economy,f.status="finished",f.homeScore=m.homeScore,f.awayScore=m.awayScore
    set f.homeTries=m.homeStats.%Get("tries",0),f.awayTries=m.awayStats.%Get("tries",0)
    for side="home","away" { do f.%Set(side_"YellowCards",m.%Get(side_"Stats").%Get("yellowCards",0)),f.%Set(side_"RedCards",m.%Get(side_"Stats").%Get("redCards",0)) }
    set f.winnerId=m.%Get("winnerId",$select(m.homeScore>m.awayScore:m.homeId,m.awayScore>m.homeScore:m.awayId,1:""))
    if m.%IsDefined("homeShootout") set f.homeShootout=m.homeShootout,f.awayShootout=m.awayShootout
    set f.classification=##class(Rugby.Service.Competition).Classification(f),m.classification=f.classification
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    if f.%Get("competitionKey")'="" do ##class(Rugby.Service.Competition).Sync(club.day)
    set commands=##class(Rugby.Service.Store).All("MatchCommand","matchId",m.id)
    for i=0:1:commands.%Size()-1 { set c=commands.%Get(i) if c.status="pending" { set c.status="rejected",c.reason="El encuentro ha terminado." do ##class(Rugby.Service.Store).Put("MatchCommand",c) } }
    set m.settled=1
}
ClassMethod PlayoffWinner(m As %DynamicObject)
{
    if ('$listfind($listbuild("quarterfinal","semifinal","final"),m.%Get("stage")))||(m.homeScore'=m.awayScore) quit
    set home=0,away=0
    for n=1:1:5 {
        if ##class(Rugby.Simulation.Engine).Random(m)<##class(Rugby.Simulation.Engine).Clamp(.45+(##class(Rugby.Simulation.Engine).Strength(m.homePlayers,"kicking")/200)) set home=home+1
        if ##class(Rugby.Simulation.Engine).Random(m)<##class(Rugby.Simulation.Engine).Clamp(.45+(##class(Rugby.Simulation.Engine).Strength(m.awayPlayers,"kicking")/200)) set away=away+1
    }
    for n=1:1:100 {
        quit:home'=away
        if ##class(Rugby.Simulation.Engine).Random(m)<.5 set home=home+1
        if ##class(Rugby.Simulation.Engine).Random(m)<.5 set away=away+1
    }
    if home=away set home=home+1
    set m.homeShootout=home,m.awayShootout=away,m.winnerId=$select(home>away:m.homeId,1:m.awayId)
    do ##class(Rugby.Simulation.Engine).Event(m,"shootout","","Desempate a palos: "_home_"–"_away_". Se clasifica "_$select(home>away:m.homeName,1:m.awayName)_".",0,m.x,m.y,"")
}
}
