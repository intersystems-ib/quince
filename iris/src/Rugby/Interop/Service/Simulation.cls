Class Rugby.Interop.Service.Simulation Extends Ens.BusinessService
{
Parameter ADAPTER = "Ens.InboundAdapter";
Property LastTicks As %DynamicObject;
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
    set ^RugbyWorkerHeartbeat=##class(Rugby.Job.Worker).Now()
    if '$isobject(..LastTicks) set ..LastTicks={}
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
            set request=##class(Rugby.Interop.Message.Request).%New(),request.CorrelationId=$system.Util.CreateGUID(),request.Channel="simulation",request.Method="SYSTEM",request.Resource="simulation",request.GameId=gid,request.EntityId=m.id,request.BodyJSON={"elapsed":(##class(Rugby.Simulation.Engine).Clamp(elapsed,0,2))}.%ToJSON()
            set sc=..SendRequestSync("Simulation.Process",request,.response,120,"Simular "_gid_"/"_m.id)
            if $system.Status.IsError(sc) quit
        }
    }
    quit $$$OK
}
}
