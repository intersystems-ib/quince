Class Rugby.Test.CompetitionPayload Extends %RegisteredObject
{
ClassMethod Run()
{
    for division=416,417,1401,1402 { do ..League(division) }
    set filler=$translate($justify("",24000)," ","x"),cupFixtures=##class(Rugby.Service.Competition).Fixtures("cup-2026"),cupFixture=cupFixtures.%Get(0),cupFixture.tacticalAssessments={"padding":(filler)}
    do ##class(Rugby.Service.Store).Put("Fixture",cupFixture)
    set cup=##class(Rugby.Service.Cup).View("cup-2026")
    for i=0:1:cup.fixtures.%Size()-1 { do ##class(Rugby.Test.Suite).Assert('cup.fixtures.%Get(i).%IsDefined("tacticalAssessments"),"Cup fixtures share the compact representation") }
    set fixtures=##class(Rugby.Service.Competition).Fixtures("league-1402-2026"),access=fixtures.%Get(0),top=##class(Rugby.Service.Store).Get("Competition","league-1401-2026")
    set access.id="league-1401-2026-access-1",access.competitionKey=top.id,access.awayId=top.teamIds.%Get(0),access.stage="access"
    do ##class(Rugby.Service.Store).Put("Fixture",access)
    for division=1401,1402 {
        set view=##class(Rugby.Service.Competition).View("league-"_division_"-2026")
        do ##class(Rugby.Test.Suite).Assert((view.accessMatch.id=access.id)&&('view.accessMatch.%IsDefined("tacticalAssessments"))&&view.accessMatch.%IsDefined("venue"),"Both French leagues receive a compact Access Match")
    }
}
ClassMethod League(division As %Integer)
{
    set config=##class(Rugby.Service.Leagues).Config(division),id="league-"_division_"-2026",fixtures=##class(Rugby.Service.Competition).Fixtures(id),filler=$translate($justify("",24000)," ","x"),originalSize=0
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i),f.status="finished",f.homeScore=20,f.awayScore=10,f.homeTries=2,f.awayTries=1,f.classification={"eligible":true},f.preparationLineupId=f.homeId_"-default"
        set f.tacticalAssessments={"padding":(filler)},f.disciplineParticipants=[{"padding":(filler)}]
        do ##class(Rugby.Service.Store).Put("Fixture",f)
        set originalSize=originalSize+$length(f.%ToJSON())
    }
    do ##class(Rugby.Test.Suite).Assert((fixtures.%Size()=config.regularMatches)&&(originalSize>3640000),"Completed league fixture detail exceeds the deployed response string limit")
    for stage="semifinal","final" {
        set f=##class(%DynamicObject).%FromJSON(fixtures.%Get(0).%ToJSON()),f.id="payload-"_division_"-"_stage,f.stage=stage,f.slot=1,f.homeRank=1,f.awayRank=4
        do ##class(Rugby.Service.Store).Put("Fixture",f)
    }
    if ##class(Rugby.Service.Leagues).French(division) {
        set f.id="payload-"_division_"-quarterfinal",f.stage="quarterfinal"
        do ##class(Rugby.Service.Store).Put("Fixture",f)
    }
    set result=##class(Rugby.Service.Competition).View(id),json=result.%ToJSON(),sample=result.regularFixtures.%Get(0)
    do ##class(Rugby.Test.Suite).Assert(($length(json)<500000)&&(result.regularFixtures.%Size()=config.regularMatches)&&(result.regularFinished=config.regularMatches)&&(result.standings.%Size()=config.teams),"Every league season serializes compactly with all fixtures and standings")
    do ##class(Rugby.Test.Suite).Assert(sample.%IsDefined("venue")&&sample.%IsDefined("classification")&&sample.%IsDefined("preparationLineupId"),"Compact fixtures preserve stadium, bonus points and lineup selection")
    do ##class(Rugby.Test.Suite).Assert(('sample.%IsDefined("tacticalAssessments"))&&('sample.%IsDefined("disciplineParticipants")),"Competition response excludes internal simulation detail")
    do ##class(Rugby.Test.Suite).Assert(##class(Rugby.Service.Store).Get("Fixture",sample.id).%IsDefined("tacticalAssessments"),"Compacting a response never erases stored match detail")
    do ##class(Rugby.Test.Suite).Assert((result.semifinals.%Size()=1)&&('$isobject(result.semifinals.%Get(0).%Get("tacticalAssessments")))&&(result.final.homeRank=1),"Playoffs retain seeding and use the same compact format")
    write "LEAGUE_PAYLOAD ",division," ",originalSize," -> ",$length(json)," chars",!
}
}
