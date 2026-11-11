Class Rugby.Test.AttributeProgress Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),c=##class(Rugby.Service.Store).Get("Club","c1"),year=##class(Rugby.Service.Seasons).Year(),raw=p.attributes.%ToJSON(),scale=p.%Get("talentScaleFactor",1)
    set e={"id":"progress-test","clubId":"c1","day":(c.day),"seasonYear":(year),"attributeScale":(scale),"results":[{"playerId":(p.id),"changes":[{"attribute":"passing","before":10,"after":12,"delta":2,"reason":"training"},{"attribute":"strength","before":60,"after":59,"delta":-1,"reason":"age"}]}]}
    do ##class(Rugby.Service.Store).Put("TrainingExecution",e),##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert((p.attributeSeasonChanges.passing=2)&&(p.attributeSeasonChanges.strength=-1)&&(p.attributeSeasonChanges.agility=0),"Progress includes actual gains, age losses and unchanged attributes")
    do ##class(Rugby.Service.Store).Put("TrainingExecution",e),##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert((p.attributeSeasonChanges.passing=2)&&(p.attributes.%ToJSON()=raw),"Repeated execution writes do not duplicate gains or modify attributes")
    set p.clubId=""
    do ##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert(p.attributeSeasonChanges.passing=2,"Progress follows a released or transferred player")
    do ##class(Rugby.Service.AttributeProgress).View(p,year+1)
    do ..Assert((p.attributeSeasonChanges.passing=0)&&(p.attributeSeasonChanges.strength=0),"New season starts with zero accumulated progress")
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"attributeHistoryVersion")
    set report=##class(Rugby.Service.AttributeProgress).Initialize()
    do ##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert((p.attributeSeasonChanges.passing=2)&&(report.sessions>0),"Existing history is recovered from stored training sessions")
    set p.id="progress-legacy",p.talentScaleFactor=.75,p.attributes.passing=8
    set old={"id":"progress-old-1","day":(c.day-2),"seasonYear":(year),"results":[{"playerId":(p.id),"changes":[{"attribute":"passing","before":8,"after":9,"delta":1}]}]}
    do ##class(Rugby.Service.AttributeProgress).Record(old)
    set old.id="progress-old-2",old.day=c.day-1,old.results.%Get(0).changes=[{"attribute":"passing","before":9,"after":10,"delta":1}]
    do ##class(Rugby.Service.AttributeProgress).Record(old)
    set e.id="progress-new",e.day=c.day,e.attributeScale=.75,e.results=[{"playerId":(p.id),"changes":[{"attribute":"passing","before":7.5,"after":8,"delta":0.5}]}]
    do ##class(Rugby.Service.AttributeProgress).Record(e),##class(Rugby.Service.AttributeProgress).View(p,year)
    do ..Assert(p.attributeSeasonChanges.passing=2,"Legacy progress is normalized across the uniform talent scale change")
}
}
