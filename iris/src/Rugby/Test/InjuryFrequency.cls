Class Rugby.Test.InjuryFrequency Extends %RegisteredObject
{
ClassMethod Run()
{
    set m=##class(Rugby.Test.Suite).Build(593),m.aggregate=1,m.fixtureId="frequency-sample",total=0,matches=200
    for n=1:1:matches {
        set m.injuryEvents=[]
        for side="home","away" { set players=m.%Get(side_"Players") for i=0:1:14 { set p=players.%Get(i),p.status="field",p.energy=100,p.age=26 } }
        for step=1:1:240 { set m.clock=step*20 do ##class(Rugby.Service.Injuries).MatchTick(m,20) }
        set total=total+m.injuryEvents.%Size()
    }
    do ##class(Rugby.Test.Suite).Assert((total>=20)&&(total<=120),"Actual match injury draws stay rare across two hundred healthy matches")
    set healthy=##class(Rugby.Service.Injuries).MatchChance(100,26,20),tired=##class(Rugby.Service.Injuries).MatchChance(30,26,20),older=##class(Rugby.Service.Injuries).MatchChance(100,36,20)
    do ##class(Rugby.Test.Suite).Assert((tired>healthy)&&(older>healthy),"Fatigue and age still increase match injury risk")
    do ##class(Rugby.Test.Suite).Assert(##class(Rugby.Service.Injuries).MatchChance(100,26,0)=0,"No playing time has no injury exposure")
    write "INJURY_FREQUENCY ",total," injuries / ",matches," controlled matches; ",total/matches," per match",!
}
}
