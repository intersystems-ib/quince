Class Rugby.Service.Router Extends %RegisteredObject
{
ClassMethod Paginate(a As %DynamicArray) As %DynamicObject
{
    set offset=%RugbyQuery.%Get("offset",0),limit=%RugbyQuery.%Get("limit",100)
    if ('##class(Rugby.Service.Store).Integer(offset,0,100000))||('##class(Rugby.Service.Store).Integer(limit,1,500)) do ##class(Rugby.Service.Store).Fail(400,"PAGINATION","offset >= 0; limit entre 1 y 500.")
    set items=[]
    for i=offset:1:offset+limit-1 { quit:i>=a.%Size()  do items.%Push(a.%Get(i)) }
    quit {"items":(items),"total":(a.%Size()),"offset":(offset),"limit":(limit)}
}
ClassMethod Resolve(method As %String, resource As %String, id As %String, child As %String, pid As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    if (resource="health")&&(method="GET") quit {"status":"ok","workerHeartbeat":($get(^RugbyWorkerHeartbeat))}
    if resource="auth" quit ##class(Rugby.Service.Auth).Resolve(method,id,b)
    if (resource="game-catalog")&&(method="GET") quit {"items":(##class(Rugby.Service.Store).All("Club"))}
    if resource="games" {
        if (method="DELETE")&&(child="") quit ##class(Rugby.Service.Games).Delete(id,b,key)
        if (method="GET")&&(id="") quit ##class(Rugby.Service.Games).List()
        if (method="POST")&&(id="") quit ##class(Rugby.Service.Games).Create(b,key)
        if (method="POST")&&(child="load") quit ##class(Rugby.Service.Games).Load(id)
        if (method="POST")&&(child="unload") quit ##class(Rugby.Service.Games).Unload(id)
    }
    if (resource="transfer-market")&&(method="GET") quit ..Paginate(##class(Rugby.Service.Transfers).Market())
    if resource="negotiations" {
        if (method="GET")&&(id="") quit ..Paginate(##class(Rugby.Service.Transfers).List())
        if (method="GET")&&(child="") quit ##class(Rugby.Service.Transfers).Get(id)
        if method="POST" {
            if child="offer" quit ##class(Rugby.Service.Transfers).Offer(id,b,key)
            if child="sign" quit ##class(Rugby.Service.Transfers).Sign(id,b,key)
            if child="withdraw" quit ##class(Rugby.Service.Transfers).Withdraw(id,b,key)
        }
    }
    if (resource="players")&&(method="POST")&&(child="renew") quit ##class(Rugby.Service.Transfers).Open(id,b,key,"renewal")
    if (resource="players")&&(method="POST")&&(child="negotiate") quit ##class(Rugby.Service.Transfers).Open(id,b,key)
    if method="GET" {
        if resource="competitions" {
            if id="" quit ..Paginate(##class(Rugby.Service.Store).All("Competition"))
            if child="" quit ##class(Rugby.Service.Competition).View(id)
        }
        if resource="training-types" quit {"items":(##class(Rugby.Service.Development).Catalog()),"modelVersion":(##class(Rugby.Service.Development).#VERSION)}
        if resource="injury-types" quit {"items":(##class(Rugby.Service.Injuries).Catalog()),"modelVersion":(##class(Rugby.Service.Injuries).#VERSION)}
        if resource="staff-market" quit ..Paginate(##class(Rugby.Service.Payroll).Market(%RugbyQuery.%Get("role","")))
        if resource="clubs" {
            if id="" quit ..Paginate(##class(Rugby.Service.Store).All("Club"))
            set c=##class(Rugby.Service.Store).Get("Club",id)
            if child="" quit c
            if (child="players")||(child="academy") {
                set a=##class(Rugby.Service.Store).All("Player","clubId",id),items=[]
                set plan=##class(Rugby.Service.Store).Get("TrainingPlan",id),qualities=##class(Rugby.Service.Staff).Qualities(id)
                for i=0:1:a.%Size()-1 { set p=a.%Get(i) if (child="players")||(p.category="academy") do items.%Push(##class(Rugby.Service.Development).Profile(p,c,plan,qualities)) }
                quit ..Paginate(items)
            }
            if child="lineups" {
                set lineups=##class(Rugby.Service.Store).All("Lineup","clubId",id)
                for i=0:1:lineups.%Size()-1 { do ##class(Rugby.Service.Management).NormalizeBench(lineups.%Get(i)) }
                quit ..Paginate(lineups)
            }
            if child="training-plan" quit ##class(Rugby.Service.WeeklyTraining).View(id)
            if child="training-suggestion" quit ##class(Rugby.Service.Development).Suggest(id,%RugbyQuery.%Get("variant",0))
            if child="staff" quit ##class(Rugby.Service.Staff).View(id)
            if child="training-executions" {
                set a=##class(Rugby.Service.Store).All("TrainingExecution","clubId",id),sorted=[]
                kill executions
                for i=0:1:a.%Size()-1 { set e=a.%Get(i),executions(e.day)=e }
                set day=""
                for { set day=$order(executions(day),-1) quit:day=""  do sorted.%Push(executions(day)) }
                quit ..Paginate(sorted)
            }
            if child="finances" {
                quit ##class(Rugby.Service.Finance).View(id)
            }
            if child="financial-movements" quit ..Paginate(##class(Rugby.Service.Store).All("FinancialMovement","clubId",id))
            if child="fixtures" {
                quit ..Paginate(##class(Rugby.Service.Competition).ClubFixtures(id))
            }
            if child="friendly-invitations" quit ..Paginate(##class(Rugby.Service.FriendlyRequests).List(id))
            if child="friendly-options" quit ##class(Rugby.Service.Calendar).Options(id,%RugbyQuery.%Get("date"))
        }
        if (resource="players")&&(child="") {
            set p=##class(Rugby.Service.Store).Get("Player",id)
            if p.clubId="" quit ##class(Rugby.Service.Development).FreeProfile(p)
            set c=##class(Rugby.Service.Store).Get("Club",p.clubId)
            quit ##class(Rugby.Service.Development).Profile(p,c,##class(Rugby.Service.Store).Get("TrainingPlan",p.clubId),##class(Rugby.Service.Staff).Qualities(p.clubId))
        }
        if resource="matches" {
            set m=##class(Rugby.Service.Store).Get("Match",id)
            if child="" { set m.classification=##class(Rugby.Service.Competition).MatchClassification(m) quit m }
            if child="ticketing" { set c=##class(Rugby.Service.Store).Get("Club",m.homeId),view={"forecast":(##class(Rugby.Service.Finance).Forecast(m))} do view.%Set("editable",(m.homeId=##class(Rugby.Service.Store).ManagedClub())&&(m.status="scheduled")&&(m.date=c.date),"boolean") quit view }
            if child="comparison" quit ##class(Rugby.Simulation.Tactics).Comparison(m)
            if child="stats" quit {"home":(m.homeStats),"away":(m.awayStats)}
            if child="commands" quit ..Paginate(##class(Rugby.Service.Store).All("MatchCommand","matchId",id))
            if child="events" {
                set after=%RugbyQuery.%Get("afterSequence",0),limit=%RugbyQuery.%Get("limit",100)
                if ('##class(Rugby.Service.Store).Integer(after,0,1000000))||('##class(Rugby.Service.Store).Integer(limit,1,500)) do ##class(Rugby.Service.Store).Fail(400,"PAGINATION","afterSequence >= 0; limit entre 1 y 500.")
                set events=[]
                for seq=after+1:1:m.sequence {
                    quit:events.%Size()>=limit
                    set eid=id_"-"_$translate($justify(seq,6)," ","0")
                    do events.%Push(##class(Rugby.Service.Store).Get("MatchEvent",eid))
                }
                set page={"items":(events),"lastSequence":(m.sequence)}
                do page.%Set("hasMore",after+events.%Size()<m.sequence,"boolean")
                quit page
            }
        }
    }
    if (resource="clubs")&&(method'="GET") {
        do ##class(Rugby.Service.Store).Managed(id)
        if (child="advance-day")&&(method="POST") quit ##class(Rugby.Service.Management).Advance(id,b,key)
        if (child="friendly-invitations")&&(method="POST") quit ##class(Rugby.Service.FriendlyRequests).Respond(id,b.%Get("invitationId"),b,key)
        if (child="friendlies")&&(method="POST") quit ##class(Rugby.Service.Calendar).Create(id,b,key)
        if (child="training-plan")&&(method="PUT") quit ##class(Rugby.Service.Management).Training(id,b,key)
        if (child="financial-director")&&(method="POST") quit ##class(Rugby.Service.Finance).Hire(id,b,key)
        if (child="staff")&&(method="POST") quit ##class(Rugby.Service.Staff).Hire(id,b,key)
        if (child="lineups")&&(method="POST") quit ##class(Rugby.Service.Management).SaveLineup("",b)
        if (child="promote")&&(method="POST") quit ##class(Rugby.Service.Transfers).Promotion(id,pid,b,key)
    }
    if resource="lineups" {
        if (method="PUT")&&(child="") quit ##class(Rugby.Service.Management).SaveLineup(id,b)
        if (method="POST")&&(child="validate") quit ##class(Rugby.Service.Management).Validate(##class(Rugby.Service.Store).Get("Lineup",id))
    }
    if (resource="players")&&(method="POST")&&(child="release") quit ##class(Rugby.Service.Management).Release(id,b,key)
    if (resource="matches")&&(method="PUT")&&(child="ticketing") quit ##class(Rugby.Service.Finance).Ticketing(id,b,key)
    if (resource="matches")&&(method="POST") {
        if id="" quit ##class(Rugby.Service.Matches).Create(b,key)
        if child="start" { do ##class(Rugby.Service.Store).Key(key) quit ##class(Rugby.Service.Matches).Start(id) }
        if child="commands" quit ##class(Rugby.Service.Matches).Command(id,b,key)
    }
    do ##class(Rugby.Service.Store).Fail(404,"ROUTE_NOT_FOUND","Ruta no disponible.")
}
}

