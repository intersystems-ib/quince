Class Rugby.Test.StorageMaintenance Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set large={"id":"test-storage","items":[]}
    for i=1:1:100 { do large.items.%Push({"name":("Player "_i),"attributes":("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz")}) }
    set raw=large.%ToJSON(),response=##class(Rugby.Interop.Message.Response).%New()
    do response.SetBody(raw)
    do ..Assert((response.Payload()=raw)&&($length(response.BodyJSON)<=2048),"HTTP payload remains complete while persistent audit body is bounded")
    set summary=##class(%DynamicObject).%FromJSON(response.BodyJSON)
    do ..Assert(summary.compacted&&(summary.summary.itemsCount=100)&&(summary.summary.id=large.id),"Compact audit retains identity and item counts")
    set response.BodyJSON=raw,response.DetailsJSON=raw,sc=response.%Save()
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set c=##class(Rugby.Service.Store).Get("Club","c1"),year=##class(Rugby.Service.Seasons).Year(),day=c.day-31,p=##class(Rugby.Service.Store).Get("Player","c1-p1"),attr="strength",v=p.attributes.strength
    set e={"id":"c1-storage-test","clubId":"c1","day":(day),"seasonYear":(year),"attributeScale":(##class(Rugby.Service.TalentScale).Factor()),"playerWeeklyWages":12345,"results":[{"playerId":(p.id),"attributeGain":1,"changes":[{"attribute":(attr),"before":(v-1),"after":(v),"delta":1}]}],"groups":[],"staffSnapshot":[],"weekly":{}}
    do ##class(Rugby.Service.Store).Put("TrainingExecution",e),##class(Rugby.Service.AttributeProgress).View(p,year)
    set before=p.attributeSeasonChanges.%ToJSON(),trim=##class(Rugby.Service.StorageMaintenance).TrimGame("template"),stored=##class(Rugby.Service.Store).Get("TrainingExecution",e.id)
    do ##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert((before=p.attributeSeasonChanges.%ToJSON())&&(stored.playersTrained=1)&&(stored.results.%Size()=0)&&(stored.playerWeeklyWages=12345),"Compacting old daily details preserves attribute progress, counts and payroll history")
    set result=##class(Rugby.Service.StorageMaintenance).Reduce()
    set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("SELECT BodyJSON,DetailsJSON FROM Rugby_Interop_Message.Response WHERE ID=?"),rows=q.%Execute(response.%Id()),ok=rows.%Next()
    do ..Assert(($length(rows.%Get("BodyJSON"))<=2048)&&($length(rows.%Get("DetailsJSON"))<=8192)&&(result.responses>0),"Legacy audit bodies are reduced without deleting message identities")
    do ..Assert(##class(Rugby.Service.StorageMaintenance).#AUDITDAYS=2,"Message audit retention is two days")
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"attributeTotalsReady"),^RugbyWorld(##class(Rugby.Service.Store).Game(),"attributeTotals",p.id)
    set e.id="storage-legacy-progress"
    do ##class(Rugby.Service.AttributeProgress).Record(e),##class(Rugby.Service.AttributeProgress).LegacyView(p,year)
    set before=p.attributeSeasonChanges.%ToJSON()
    do ##class(Rugby.Service.AttributeProgress).Compact(),##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert((before=p.attributeSeasonChanges.%ToJSON())&&('$data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"attributeHistory"))),"Legacy per-day history becomes season totals with identical visible progress")
}
}
