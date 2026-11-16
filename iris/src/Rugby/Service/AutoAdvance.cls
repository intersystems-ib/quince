Class Rugby.Service.AutoAdvance Extends %RegisteredObject
{
ClassMethod State(club As %String, knownRevision As %String = "") As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    set c=##class(Rugby.Service.Store).Get("Club",club),fixtures=##class(Rugby.Service.Competition).ClubFixtures(club),pending=[],meetings=##class(Rugby.Service.OpponentPreparation).List(club),events=##class(Rugby.Service.SeasonCalendar).Events(club),revision=##class(Rugby.Service.MatchStatistics).Revision()
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if f.status'="finished" do pending.%Push(##class(Rugby.Service.MatchStatistics).Compact(f,0)) }
    set result={"club":(c),"schedule":{"fixtures":(pending),"meetings":(meetings.items),"seasonEvents":(events.items)},"resultsRevision":(revision)}
    if knownRevision'=revision set result.results=##class(Rugby.Service.MatchStatistics).Recent()
    quit result
}
ClassMethod Step(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club),##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"retry","autoAdvance",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","autoAdvance",club,key))
    set advanced=##class(Rugby.Service.Management).Advance(club,b,key),result=..State(club,b.%Get("resultsRevision"))
    set ^RugbyWorld(game,"retry","autoAdvance",club,key)=result.%ToJSON()
    quit result
}
}
