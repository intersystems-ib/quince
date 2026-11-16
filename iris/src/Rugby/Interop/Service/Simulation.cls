Class Rugby.Interop.Service.Simulation Extends Ens.BusinessService
{
Parameter ADAPTER = "Ens.InboundAdapter";
Property LastTicks As %DynamicObject;
Property Accrued As %DynamicObject;
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
    set ^RugbyWorkerHeartbeat=##class(Rugby.Job.Worker).Now()
    do ##class(Rugby.Service.StorageMaintenance).Tick()
    if '$isobject(..LastTicks) set ..LastTicks={}
    if '$isobject(..Accrued) set ..Accrued={}
    set gid=""
    for {
        set gid=$order(^RugbyGames(gid))
        quit:gid=""
        set game=##class(%DynamicObject).%FromJSON(^RugbyGames(gid))
        if 'game.%Get("active",0) continue
        set %RugbyGame=gid,%RugbyManagedClub=game.clubId,matches=##class(Rugby.Service.Store).All("Match")
        for i=0:1:matches.%Size()-1 {
            set m=matches.%Get(i)
            if (m.status="scheduled")||(m.status="finished") continue
            set key=gid_"|"_m.id,now=##class(Rugby.Job.Worker).Now(),elapsed=$select(..LastTicks.%IsDefined(key):now-..LastTicks.%Get(key),1:0)
            do ..LastTicks.%Set(key,now)
            set elapsed=..Accrued.%Get(key,0)+##class(Rugby.Simulation.Engine).Clamp(elapsed,0,2),pending=0,commands=##class(Rugby.Service.Store).All("MatchCommand","status","pending")
            for j=0:1:commands.%Size()-1 { if commands.%Get(j).matchId=m.id set pending=1 }
            if (m.speed=0)&&('pending) { do ..Accrued.%Set(key,0) continue }
            if ('pending)&&(elapsed<2)&&((m.%Get("credit",0)+(elapsed*m.speed))<20) { do ..Accrued.%Set(key,elapsed) continue }
            set charged=##class(Rugby.Simulation.Engine).Clamp(elapsed,0,2)
            do ..Accrued.%Set(key,elapsed-charged)
            set request=##class(Rugby.Interop.Message.Request).%New(),request.CorrelationId=$system.Util.CreateGUID(),request.Channel="simulation",request.Method="SYSTEM",request.Resource="simulation",request.GameId=gid,request.EntityId=m.id,request.BodyJSON={"elapsed":(charged)}.%ToJSON()
            set sc=..SendRequestSync("Simulation.Process",request,.response,120,"Simular "_gid_"/"_m.id)
            if $system.Status.IsError(sc) quit
        }
    }
    quit $$$OK
}
}
