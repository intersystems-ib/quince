Class Rugby.Test.TalentScale Extends %RegisteredObject
{
ClassMethod Run()
{
    set game=##class(Rugby.Service.Store).Game(),players=##class(Rugby.Service.Store).All("Player"),before={},factor=##class(Rugby.Service.TalentScale).#FACTOR
    // Reconstruct a pre-migration world inside the suite's rollback transaction.
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) do p.%Remove("talentScaleVersion") set it=p.attributes.%GetIterator() while it.%GetNext(.key,.value) { do p.attributes.%Set(key,value/factor) } do ##class(Rugby.Service.Store).Put("Player",p),before.%Set(p.id,##class(%DynamicObject).%FromJSON(p.%ToJSON())) }
    set referenceClub=##class(Rugby.Service.Store).Get("Club","c1"),expectedTarget=referenceClub.qualitySeniorTarget,referenceClub.qualitySeniorTarget=referenceClub.qualitySeniorTarget/factor,referenceClub.qualityAcademyTarget=referenceClub.qualityAcademyTarget/factor
    do referenceClub.%Remove("talentScaleVersion"),##class(Rugby.Service.Store).Put("Club",referenceClub)
    set original=before.%Get("c1-p1"),snap={"id":"scale-live-c1-p1","playerId":"c1-p1","clubId":"c1","matchId":"scale-live","attributes":(##class(%DynamicObject).%FromJSON(original.attributes.%ToJSON())),"energy":55,"form":(original.form)},m={"id":"scale-live","homeId":"c1","awayId":"c2","status":"paused","clock":123,"homeScore":7,"awayScore":3,"homePlayers":[],"awayPlayers":[]}
    do snap.attributes.%Set("tackling",snap.attributes.tackling-2),m.homePlayers.%Push(snap),##class(Rugby.Service.Store).Put("Match",m)
    set oldTackling=snap.attributes.tackling
    kill ^RugbyWorld(game,"talentScaleVersion")
    set movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),contracts=##class(Rugby.Service.Store).All("PlayerContract").%ToJSON(),report=##class(Rugby.Service.TalentScale).Apply(),after=##class(Rugby.Service.Store).All("Player"),catalog=##class(Rugby.Service.Development).Catalog()
    do ##class(Rugby.Test.Suite).Assert(report.players=players.%Size(),"Every player is scaled, including academy and foreign free agents")
    for i=0:1:after.%Size()-1 {
        set p=after.%Get(i),old=before.%Get(p.id)
        for j=0:1:16 { set key=catalog.%Get(j).id do ##class(Rugby.Test.Suite).Assert($zabs(p.attributes.%Get(key)-(old.attributes.%Get(key)*factor))<.000002,"All seventeen attributes use the same proportion") }
        for key="weeklyWage","monthlyWage","clubId","age","energy","morale","available","recoveryDay" { do ##class(Rugby.Test.Suite).Assert(p.%Get(key)=old.%Get(key),"Non-ability fields are preserved: "_key) }
    }
    do ##class(Rugby.Test.Suite).Assert($zabs(##class(Rugby.Service.Store).Get("Club","c1").qualitySeniorTarget-expectedTarget)<.000002,"Club salary and academy references follow the same scale")
    set live=##class(Rugby.Service.Store).Get("Match","scale-live")
    do ##class(Rugby.Test.Suite).Assert(($zabs(live.homePlayers.%Get(0).attributes.tackling-(oldTackling*factor))<.000002)&&(live.clock=123)&&(live.homeScore=7)&&(live.homePlayers.%Get(0).energy=55),"Live snapshots scale their original abilities without rewriting match state")
    set snapshot=after.%ToJSON(),again=##class(Rugby.Service.TalentScale).Apply()
    do ##class(Rugby.Test.Suite).Assert((again.players=0)&&(snapshot=##class(Rugby.Service.Store).All("Player").%ToJSON())&&(movements=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON())&&(contracts=##class(Rugby.Service.Store).All("PlayerContract").%ToJSON()),"Reopening does not scale twice or change money/contracts")
    set c=##class(Rugby.Service.Store).Get("Club","c1"),p=##class(Rugby.Seed.Academy).Create(c,3,99999),raw=##class(Rugby.Service.Development).Average(p)
    do ##class(Rugby.Service.Store).Put("Player",p)
    do ##class(Rugby.Test.Suite).Assert($zabs(p.average-(raw*factor))<.000002,"Future academy players use the same scale")
    set p.attributes.strength=p.attributes.strength+.5,trained=p.attributes.strength
    do ##class(Rugby.Service.Store).Put("Player",p)
    do ##class(Rugby.Test.Suite).Assert(p.attributes.strength=trained,"Training updates are never scaled again")
}
}
