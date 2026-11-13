Class Rugby.Service.FriendlyRequests Extends %RegisteredObject
{
ClassMethod FreeWeekend(club As %String, date As %String) As %Boolean
{
    if ##class(Rugby.Service.SeasonCalendar).Reserved(date) quit 0
    set day=$zdateh(date,3),weekday=(day+4)#7
    if (weekday'=0)&&(weekday'=6) quit 0
    quit ('##class(Rugby.Service.Calendar).Busy(club,date))&&('##class(Rugby.Service.Calendar).Busy(club,$zdate(day-1,3)))&&('##class(Rugby.Service.Calendar).Busy(club,$zdate(day+1,3)))
}
ClassMethod Tick() As %DynamicObject
{
    set club=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",club),month=$extract(c.date,1,7),id=club_"-invite-"_month,all=##class(Rugby.Service.Store).All("FriendlyInvitation","clubId",club),report={"created":false,"expired":[]}
    for i=0:1:all.%Size()-1 { set v=all.%Get(i) if (v.status="pending")&&($zdateh(v.expiresOn,3)<$zdateh(c.date,3)) { set v.status="expired" do ##class(Rugby.Service.Store).Put("FriendlyInvitation",v),report.expired.%Push(v.id) } }
    if $isobject(##class(Rugby.Service.Store).Get("FriendlyInvitation",id,0)) quit report
    // One incoming invitation per managed club and calendar month, never on an occupied weekend.
    set clubs=##class(Rugby.Service.Store).All("Club"),seed=##class(Rugby.Service.Rivals).Hash(id,##class(Rugby.Service.Rivals).Seed()),first=$zdateh(c.date,3),best=-1,chosen=""
    for n=7:1:27 {
        set date=$zdate(first+n,3)
        if $extract(date,1,7)'=month continue
        if '..FreeWeekend(club,date) continue
        for j=0:1:clubs.%Size()-1 {
            set rival=clubs.%Get(j)
            if (rival.id=club)||('..FreeWeekend(rival.id,date)) continue
            set score=##class(Rugby.Service.Rivals).Hash(rival.id_"-"_date,seed)
            if score>best set best=score,chosen=rival.id,chosenDate=date
        }
    }
    if chosen="" quit report
    set expires=$zdate(first+6,3),venue=$select(seed#2:"home",1:"away"),v={"id":(id),"clubId":(club),"opponentId":(chosen),"date":(chosenDate),"venue":(venue),"status":"pending","createdOn":(c.date),"expiresOn":(expires),"fixtureId":"","seed":(seed)}
    do ##class(Rugby.Service.Store).Put("FriendlyInvitation",v)
    set report.created=1,report.invitation=v
    quit report
}
ClassMethod List(club As %String) As %DynamicArray
{
    do ##class(Rugby.Service.Store).Managed(club)
    set all=##class(Rugby.Service.Store).All("FriendlyInvitation","clubId",club),items=[],c=##class(Rugby.Service.Store).Get("Club",club)
    for i=0:1:all.%Size()-1 { set v=all.%Get(i) if (v.status="pending")&&($zdateh(v.expiresOn,3)>=$zdateh(c.date,3)) do items.%Push(v) }
    quit items
}
ClassMethod Respond(club As %String, id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club),##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"retry","friendlyResponse",id,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","friendlyResponse",id,key))
    set v=##class(Rugby.Service.Store).Get("FriendlyInvitation",id),c=##class(Rugby.Service.Store).Get("Club",club)
    if v.clubId'=club do ##class(Rugby.Service.Store).Fail(404,"NOT_FOUND","Invitación no encontrada.")
    do ##class(Rugby.Service.Store).CheckVersion(v,b)
    if (v.status'="pending")||($zdateh(v.expiresOn,3)<$zdateh(c.date,3))||($zdateh(v.date,3)<=$zdateh(c.date,3)) do ##class(Rugby.Service.Store).Fail(409,"INVITATION_EXPIRED","La invitación ya no está disponible.")
    if '$listfind($listbuild("accept","reject"),b.%Get("decision")) do ##class(Rugby.Service.Store).Fail(422,"INVITATION_DECISION","Acepta o rechaza la invitación.")
    if b.decision="accept" {
        if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el partido en curso antes de aceptar.")
        if ('..FreeWeekend(club,v.date))||('..FreeWeekend(v.opponentId,v.date)) do ##class(Rugby.Service.Store).Fail(409,"CALENDAR_BUSY","Uno de los equipos ya tiene ocupado ese fin de semana.")
        set home=$select(v.venue="home":club,1:v.opponentId),away=$select(v.venue="home":v.opponentId,1:club),f={"id":("friendly-"_id),"clubId":(club),"homeId":(home),"awayId":(away),"date":(v.date),"day":($zdateh(v.date,3)-$zdateh("2026-11-07",3)),"stage":"friendly","round":0,"status":"scheduled","matchId":"","seed":(v.seed),"invitationId":(id)}
        do ##class(Rugby.Service.Store).Put("Fixture",f)
        set v.status="accepted",v.fixtureId=f.id
    } else { set v.status="rejected" }
    set v.respondedOn=c.date
    do ##class(Rugby.Service.Store).Put("FriendlyInvitation",v)
    set ^RugbyWorld(game,"retry","friendlyResponse",id,key)=v.%ToJSON()
    quit v
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],gid=""
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando invitaciones.")
    try {
        tstart
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Tick()) }
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
