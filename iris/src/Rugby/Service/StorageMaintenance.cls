Class Rugby.Service.StorageMaintenance Extends %RegisteredObject
{
Parameter AUDITDAYS = 2;
ClassMethod Training(d As %DynamicObject) As %DynamicObject
{
    if d.%Get("storageVersion")="2" quit d
    set result={"id":(d.id),"clubId":(d.clubId),"day":(d.day),"playersTrained":(d.%Get("playersTrained",d.results.%Size())),"results":[],"trainingCost":0,"playerWeeklyWages":(d.%Get("playerWeeklyWages",0)),"staffWeeklyWages":(d.%Get("staffWeeklyWages",0)),"storageVersion":"2","detailsCompacted":true}
    for field="version","seasonYear","attributeScale","modelVersion","mode" { if d.%IsDefined(field) do result.%Set(field,d.%Get(field)) }
    quit result
}
ClassMethod Rivals(d As %DynamicObject) As %DynamicObject
{
    if d.%Get("storageVersion")="1" quit d
    set clubs=d.%Get("clubs",[])
    for i=0:1:clubs.%Size()-1 { set r=clubs.%Get(i) for field="results","groups","staffSnapshot" { do r.%Remove(field) } }
    set finance=d.%Get("financeExecution",[])
    if $isobject(finance)&&finance.%IsA("%Library.DynamicArray") {
        set compact=[]
        for i=0:1:finance.%Size()-1 { set f=finance.%Get(i) do compact.%Push({"clubId":(f.%Get("clubId")),"seasonId":(f.%Get("seasonId")),"members":(f.%Get("members",0)),"movements":(f.%Get("movements",[]))}) }
        set d.financeExecution=compact
    }
    set played=d.%Get("finishedFixtures",[]),compact=[]
    for i=0:1:played.%Size()-1 { do compact.%Push(##class(Rugby.Service.MatchStatistics).Compact(played.%Get(i),0)) }
    set d.finishedFixtures=compact,d.storageVersion="1"
    quit d
}
ClassMethod TrimGame(game As %String) As %DynamicObject
{
    set previousGame=##class(Rugby.Service.Store).Game(),previousClub=##class(Rugby.Service.Store).ManagedClub(),%RugbyGame=game,result={"gameId":(game),"records":0,"before":0,"after":0}
    try {
        set cid=$select(game="template":"c1",1:##class(%DynamicObject).%FromJSON(^RugbyGames(game)).clubId),%RugbyManagedClub=cid,c=##class(Rugby.Service.Store).Get("Club",cid)
        do ##class(Rugby.Service.AttributeProgress).Compact()
        for kind="TrainingExecution","RivalExecution" {
            set id=""
            for {
                set id=$order(^RugbyWorld(game,"catalog",kind,id))
                quit:id=""
                set o=$classmethod("Rugby.Model."_kind,"%OpenId",game_"|"_id),d=##class(%DynamicObject).%FromJSON(o.Payload)
                if ((kind="TrainingExecution")&&(d.%Get("storageVersion")="2"))||((kind="RivalExecution")&&(d.%Get("storageVersion")="1")) continue
                set before=$length(o.Payload),d=$select(kind="TrainingExecution":..Training(d),1:..Rivals(d)),o.Payload=d.%ToJSON(),sc=o.%Save()
                if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
                set result.records=result.records+1,result.before=result.before+before,result.after=result.after+$length(o.Payload)
            }
        }
        set ^RugbyWorld(game,"storageLastTrimDay")=c.day
    } catch ex {
        set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
        throw ex
    }
    set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
    quit result
}
ClassMethod Reduce() As %DynamicObject
{
    lock +^RugbyStorageMaintenance:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Mantenimiento en curso.")
    lock +^RugbyWrite:30
    if '$test { lock -^RugbyStorageMaintenance do ##class(Rugby.Service.Store).Fail(409,"BUSY","Hay operaciones activas.") }
    set report={"responses":0,"before":0,"after":0,"games":[]}
    try {
        set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("SELECT ID FROM Rugby_Interop_Message.Response WHERE $LENGTH(BodyJSON)>2048 OR $LENGTH(DetailsJSON)>8192")
        if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        set rows=q.%Execute()
        while rows.%Next() {
            set id=rows.%Get("ID"),o=##class(Rugby.Interop.Message.Response).%OpenId(id)
            set report.before=report.before+$length(o.BodyJSON)+$length(o.DetailsJSON),o.BodyJSON=##class(Rugby.Interop.Audit).Summary(o.BodyJSON),o.DetailsJSON=##class(Rugby.Interop.Audit).Summary(o.DetailsJSON,8192),sc=o.%Save()
            if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
            set report.responses=report.responses+1,report.after=report.after+$length(o.BodyJSON)+$length(o.DetailsJSON)
            if (report.responses#10000)=0 write "AUDIT COMPACTED ",report.responses,!
        }
        do report.games.%Push(..TrimGame("template"))
        set game=""
        for { set game=$order(^RugbyGames(game)) quit:game=""  do report.games.%Push(..TrimGame(game)) }
        set ^RugbyStorage("lastReduction")=report.%ToJSON(),^RugbyStorage("lastDailyDay")=+$horolog
    } catch ex {
        lock -^RugbyWrite
        lock -^RugbyStorageMaintenance
        throw ex
    }
    lock -^RugbyWrite
    lock -^RugbyStorageMaintenance
    quit report
}
ClassMethod RequestGame(game As %String, day As %Integer)
{
    if game="template" quit
    if (day-$get(^RugbyWorld(game,"storageLastTrimDay"),day))<7 {
        if '$data(^RugbyWorld(game,"storageLastTrimDay")) set ^RugbyWorld(game,"storageLastTrimDay")=day
        quit
    }
    if $get(^RugbyWorld(game,"storageTrimRequested"),0)>(##class(Rugby.Job.Worker).Now()-120) quit
    set ^RugbyWorld(game,"storageTrimRequested")=##class(Rugby.Job.Worker).Now()
    job ##class(Rugby.Service.StorageMaintenance).TrimOne(game)
}
ClassMethod TrimOne(game As %String)
{
    lock +^RugbyStorageMaintenance:0
    if '$test quit
    lock +^RugbyWrite(game):30
    if '$test { lock -^RugbyStorageMaintenance quit }
    try { if $data(^RugbyGames(game)) set report=..TrimGame(game) }
    catch ex { set ^RugbyStorage("error")=ex.DisplayString() }
    kill ^RugbyWorld(game,"storageTrimRequested")
    lock -^RugbyWrite(game)
    lock -^RugbyStorageMaintenance
}
ClassMethod Tick()
{
    if $get(^RugbyStorage("lastDailyDay"),0)>=+$horolog quit
    if $get(^RugbyStorage("dailyRequested"),0)>(##class(Rugby.Job.Worker).Now()-3600) quit
    set ^RugbyStorage("dailyRequested")=##class(Rugby.Job.Worker).Now()
    job ##class(Rugby.Service.StorageMaintenance).Daily()
}
ClassMethod Daily()
{
    lock +^RugbyStorageMaintenance:0
    if '$test quit
    try {
        set sc=##class(Ens.Util.MessagePurge).Purge(.deleted,..#AUDITDAYS,1,1)
        if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        set sc=##class(Ens.Util.Log).Purge(.logs,..#AUDITDAYS,0)
        if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        set ^RugbyStorage("lastDailyDay")=+$horolog
    } catch ex { set ^RugbyStorage("error")=ex.DisplayString() }
    lock -^RugbyStorageMaintenance
}
}
