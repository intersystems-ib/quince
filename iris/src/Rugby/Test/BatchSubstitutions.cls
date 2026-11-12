Class Rugby.Test.BatchSubstitutions Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(524),players=m.homePlayers
    if players.%Size()<23 {
        set extra=##class(%DynamicObject).%FromJSON(players.%Get(players.%Size()-1).%ToJSON()),extra.playerId="batch-extra",extra.id=m.id_"-batch-extra"
        do players.%Push(extra)
    }
    set changes=[]
    for i=0:1:7 { do changes.%Push({"outId":(players.%Get(i).playerId),"inId":(players.%Get(i+15).playerId)}) }
    set body={"type":"substitution","changes":(changes)},before=players.%ToJSON()
    do ..Assert(..Check(m,body)="","Eight distinct substitution pairs are accepted together")
    set duplicate=##class(%DynamicObject).%FromJSON(body.%ToJSON()),duplicate.changes.%Get(1).inId=duplicate.changes.%Get(0).inId
    do ..Assert(..Check(m,duplicate)'="","A substitute cannot enter twice in one request")
    set duplicate=##class(%DynamicObject).%FromJSON(body.%ToJSON()),duplicate.changes.%Get(1).outId=duplicate.changes.%Get(0).outId
    do ..Assert(..Check(m,duplicate)'="","A field player cannot be replaced twice in one request")
    set m.homeSubs=1
    do ..Assert(..Check(m,body)'="","The batch accounts for substitutions already used")
    set m.homeSubs=0
    for bad=0,"invalid",{},[] { do ..Assert(..Check(m,{"type":"substitution","changes":(bad)})'="","Malformed and empty batches are rejected") }
    do ..Assert(..Check(m,{"type":"substitution","changes":(changes),"outId":"mixed"})'="","Batch and single-player parameters cannot be mixed")
    do ..Assert(players.%ToJSON()=before,"Validation never changes snapshots")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set command=##class(Rugby.Service.Matches).Command(m.id,body,"batch-eight"),retry=##class(Rugby.Service.Matches).Command(m.id,body,"batch-eight"),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((command.id=retry.id)&&(m.homeSubs=0),"Submission is idempotent and leaves players unchanged until application")
    do ##class(Rugby.Service.Matches).Commands(m)
    do ..Assert((m.homeSubs=8)&&(##class(Rugby.Service.Store).Get("MatchCommand",command.id).status="applied"),"The entire batch is applied in one command")
    for i=0:1:7 { do ..Assert((m.homePlayers.%Get(i).status="replaced")&&(m.homePlayers.%Get(i+15).status="field")&&(m.homePlayers.%Get(i+15).position=(i+1)),"Each incoming player occupies the outgoing player's numbered position") }
    do ##class(Rugby.Service.Matches).Commands(m)
    do ..Assert(m.homeSubs=8,"An applied batch cannot be applied twice")
    set m=##class(Rugby.Test.Suite).Build(525),changes=[]
    for i=0:1:1 { do changes.%Push({"outId":(m.homePlayers.%Get(i).playerId),"inId":(m.homePlayers.%Get(i+15).playerId)}) }
    set command=##class(Rugby.Service.Matches).Command(m.id,{"type":"substitution","changes":(changes)},"batch-stale"),m=##class(Rugby.Service.Store).Get("Match",m.id),m.homePlayers.%Get(16).status="injured",before=m.homePlayers.%ToJSON()
    do ##class(Rugby.Service.Matches).Commands(m)
    do ..Assert((m.homeSubs=0)&&(m.homePlayers.%ToJSON()=before)&&(##class(Rugby.Service.Store).Get("MatchCommand",command.id).status="rejected"),"If one queued pair becomes invalid, the full batch is rejected without partial substitutions")
}
ClassMethod Check(m As %DynamicObject, b As %DynamicObject) As %String { quit ##class(Rugby.Service.Matches).CheckCommand(m,b,"home") }
}
