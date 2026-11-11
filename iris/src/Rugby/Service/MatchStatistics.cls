Class Rugby.Service.MatchStatistics Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Empty() As %DynamicObject
{
    quit {"actions":0,"metres":0,"carries":0,"tackles":0,"turnovers":0,"passes":0,"kicks":0,"knockOns":0,"tries":0,"conversionAttempts":0,"conversions":0,"penaltyAttempts":0,"penaltyGoals":0,"dropAttempts":0,"drops":0,"points":0,"scrums":0,"lineouts":0}
}
ClassMethod Add(p As %DynamicObject, field As %String, amount As %Numeric = 1)
{
    if '$isobject(p.%Get("stats")) set p.stats={}
    do p.stats.%Set(field,p.stats.%Get(field,0)+amount)
}
ClassMethod Defender(players As %DynamicArray, skill As %String = "defense") As %DynamicObject
{
    set best="",score=-1
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.status="field" { set value=##class(Rugby.Simulation.Performance).Skill(p,skill) if value>score set best=p,score=value } }
    quit best
}
ClassMethod Credit(players As %DynamicArray, field As %String, skill As %String = "defense")
{
    set p=..Defender(players,skill)
    if $isobject(p) do ..Add(p,field)
}
ClassMethod Entry(p As %DynamicObject, f As %DynamicObject, match As %String = "", source As %String = "live") As %DynamicObject
{
    set side=p.side,cid=f.%Get(side_"Id"),other=$select(side="home":"away",1:"home"),opponent=f.%Get(other_"Id"),c=##class(Rugby.Service.Store).Get("Club",cid),r=##class(Rugby.Service.Store).Get("Club",opponent),date=f.%Get("date",##class(Rugby.Service.Injuries).Date(f.day)),year=##class(Rugby.Service.Competition).Year(date)
    set stats=##class(%DynamicObject).%FromJSON(p.%Get("stats",{}).%ToJSON()),stats.yellowCards=p.%Get("yellowCards",0),stats.redCards=p.%Get("redCards",0),stats.infringements=p.%Get("infringements",0)
    set e={"id":(f.id_"-"_p.playerId),"playerId":(p.playerId),"playerName":(p.name),"clubId":(cid),"clubName":(c.name),"opponentId":(opponent),"opponentName":(r.name),"fixtureId":(f.id),"matchId":(match),"date":(date),"day":(f.day),"season":(year_"/"_(year+1)),"stage":(f.%Get("stage","friendly")),"competitionType":(f.%Get("competitionType","league")),"side":(side),"position":(p.position),"playedSeconds":(p.%Get("playedSeconds",0)),"homeScore":(f.%Get("homeScore",0)),"awayScore":(f.%Get("awayScore",0)),"stats":(stats),"source":(source),"modelVersion":(..#VERSION)}
    do e.%Set("complete",p.%Get("statsVersion")=..#VERSION,"boolean")
    quit e
}
ClassMethod Save(f As %DynamicObject, players As %DynamicArray, match As %String = "", source As %String = "live")
{
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),id=f.id_"-"_p.playerId
        if $isobject(##class(Rugby.Service.Store).Get("PlayerMatchStats",id,0)) continue
        do ##class(Rugby.Service.Store).Put("PlayerMatchStats",..Entry(p,f,match,source))
    }
}
ClassMethod Live(m As %DynamicObject, f As %DynamicObject)
{
    for side="home","away" { do ..Save(f,m.%Get(side_"Players"),m.id) }
}
ClassMethod Aggregate(f As %DynamicObject)
{
    if '$isobject(f.%Get("statisticsPlayers")) quit
    set rng={"rng":(1+(##class(Rugby.Service.Rivals).Hash("statistics-"_f.id,f.seed)#2147483646))}
    for side="home","away" {
        set players=f.statisticsPlayers.%Get(side),eligible=[]
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i),p.side=side,p.stats=..Empty(),p.statsVersion=..#VERSION
            if p.playedSeconds>0 {
                do eligible.%Push(p)
                set fraction=p.playedSeconds/4800,a=p.attributes
                set p.stats.carries=(fraction*(2+(a.strength/10)+(##class(Rugby.Simulation.Engine).Random(rng)*8)))\1,p.stats.metres=p.stats.carries*(2+(a.speed/15)),p.stats.tackles=(fraction*(3+(a.tackling/8)+(##class(Rugby.Simulation.Engine).Random(rng)*5)))\1,p.stats.passes=(fraction*(3+(a.passing/8)))\1,p.stats.kicks=(fraction*(a.kicking/20))\1,p.stats.turnovers=(fraction*(a.ruck/30))\1
                set p.stats.actions=p.stats.carries+p.stats.tackles+p.stats.passes+p.stats.kicks+p.stats.turnovers
            }
        }
        if eligible.%Size()>0 {
            set kicker="",best=-1
            for i=0:1:eligible.%Size()-1 { set p=eligible.%Get(i) if p.attributes.kicking>best set kicker=p,best=p.attributes.kicking }
            for n=1:1:f.%Get(side_"Tries",0) { set p=eligible.%Get((##class(Rugby.Simulation.Engine).Random(rng)*eligible.%Size())\1) do ..Add(p,"tries"),..Add(p,"points",5) }
            set kicker.stats.conversionAttempts=f.%Get(side_"Tries",0),kicker.stats.conversions=f.%Get(side_"Conversions",0),kicker.stats.penaltyAttempts=3,kicker.stats.penaltyGoals=f.%Get(side_"PenaltyGoals",0)
            do ..Add(kicker,"points",(kicker.stats.conversions*2)+(kicker.stats.penaltyGoals*3))
        }
        do ..Save(f,players,"","aggregate")
    }
    do f.%Remove("statisticsPlayers")
}
ClassMethod History(pid As %String) As %DynamicObject
{
    set player=##class(Rugby.Service.Store).Get("Player",pid),rows=##class(Rugby.Service.Store).All("PlayerMatchStats","playerId",pid),seen={},items=[],totals={},appearances=0,seconds=0,partial=0
    for i=0:1:rows.%Size()-1 { set r=rows.%Get(i) do seen.%Set(r.fixtureId,1) set ordered(-r.day,r.id)=r }
    // Older matches expose only the counters that were actually recorded.
    set old=##class(Rugby.Service.Store).All("MatchPlayer","playerId",pid)
    for i=0:1:old.%Size()-1 {
        set p=old.%Get(i),m=##class(Rugby.Service.Store).Get("Match",p.matchId,0)
        if '$isobject(m) continue
        if (m.status'="finished")||seen.%IsDefined(m.fixtureId) continue
        set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId,0)
        if '$isobject(f) continue
        set r=..Entry(p,f,m.id,"legacy"),ordered(-r.day,r.id)=r
    }
    set day=""
    for { set day=$order(ordered(day)) quit:day=""  set id="" for { set id=$order(ordered(day,id)) quit:id=""  set r=ordered(day,id) do items.%Push(r) set seconds=seconds+r.playedSeconds,partial=partial+('r.complete) if r.playedSeconds>0 { set appearances=appearances+1 } set it=r.stats.%GetIterator() while it.%GetNext(.field,.value) { do totals.%Set(field,totals.%Get(field,0)+value) } } }
    set result=##class(Rugby.Service.Router).Paginate(items),result.summary={"appearances":(appearances),"playedSeconds":(seconds),"stats":(totals),"partialMatches":(partial)}
    quit result
}
}
