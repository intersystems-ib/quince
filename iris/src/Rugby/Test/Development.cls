Class Rugby.Test.Development Extends %RegisteredObject
{
ClassMethod Assert(condition As %Boolean, message As %String)
{
    do ##class(Rugby.Test.Suite).Assert(condition,message)
}
ClassMethod Player(age As %Integer) As %DynamicObject
{
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.age=age,p.birthDay=-(age*365),p.energy=100,p.potential=100,p.developmentCeiling=100,p.available=1,p.developmentYear=-1,p.developmentGains={},p.developmentModel="",p.developmentProgress=0
    set catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:catalog.%Size()-2 { do p.attributes.%Set(catalog.%Get(i).id,50) }
    quit p
}
ClassMethod Qualities(q As %Numeric) As %DynamicObject
{
    quit {"head":(q),"forwards":(q),"backs":(q),"defense":(q),"attack":(q),"skills":(q),"fitness":(q),"academy":(q)}
}
ClassMethod Suggestions()
{
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1"),before=plan.%ToJSON(),players=##class(Rugby.Service.Store).All("Player","clubId","c1")
    set a=##class(Rugby.Service.Development).Suggest("c1",0),b=##class(Rugby.Service.Development).Suggest("c1",1),seen={},changed=0
    for i=0:1:a.groups.%Size()-1 {
        set g=a.groups.%Get(i)
        for j=0:1:g.playerIds.%Size()-1 {
            set pid=g.playerIds.%Get(j),p=##class(Rugby.Service.Store).Get("Player",pid)
            do ..Assert('seen.%IsDefined(pid),"Suggested players occur exactly once")
            do seen.%Set(pid,g.focus)
            if (p.energy<60)||('p.available) do ..Assert(g.focus="recovery","Low energy or unavailable players recover")
            if (g.focus'="recovery")&&(p.energy<75) do ..Assert(g.intensity="low","Moderate energy gets gentle training")
        }
    }
    do ..Assert(seen.%Size()=players.%Size(),"Suggestion covers whole roster including academy")
    for i=0:1:b.groups.%Size()-1 {
        set g=b.groups.%Get(i)
        for j=0:1:g.playerIds.%Size()-1 { if seen.%Get(g.playerIds.%Get(j))'=g.focus set changed=1 }
    }
    // Test positional weighting across the complete rotation independently of roster fatigue.
    set p=..Player(25)
    for pos=1:1:15 {
        set p.position=pos,strength=0,speed=0,agility=0,last=""
        for v=0:1:7 {
            set focus=##class(Rugby.Service.Development).SuggestedFocus(p,v)
            do ..Assert(focus'=last,"Repeated suggestions rotate healthy player training")
            set last=focus
            if focus="strength" set strength=strength+1
            if focus="speed" set speed=speed+1
            if focus="agility" set agility=agility+1
        }
        if pos<=8 do ..Assert(strength>=3,"Forwards favour strength")
        else  do ..Assert((speed+agility)>=4,"Backs favour speed and agility")
    }
    set p.energy=59
    do ..Assert(##class(Rugby.Service.Development).SuggestedFocus(p,0)="recovery","Recovery threshold")
    set p.energy=60
    do ..Assert(##class(Rugby.Service.Development).SuggestedFocus(p,0)'="recovery","Training threshold")
    set p.available=0
    do ..Assert(##class(Rugby.Service.Development).SuggestedFocus(p,1)="recovery","Unavailable always recovers")
    set after=##class(Rugby.Service.Store).Get("TrainingPlan","c1")
    do ..Assert(after.%ToJSON()=before,"Suggestions never save the plan")
    set caught=0
    try { set invalid=##class(Rugby.Service.Development).Suggest("c1",-1) } catch ex { set caught=ex.Location="TRAINING_VARIANT" }
    do ..Assert(caught,"Invalid suggestion variant rejected")
}
ClassMethod Profiles()
{
    for pos=1:1:15 {
        set role=##class(Rugby.Service.Positions).Describe(pos)
        do ..Assert(role.group=$select(pos<=8:"forwards",1:"backs"),"All rugby positions have an explicit unit")
    }
    set reserve=##class(Rugby.Service.Store).Get("Player","c1-p17"),role=##class(Rugby.Service.Positions).Describe(reserve.position)
    do ..Assert((role.id="loosehead-prop")&&(role.group="forwards"),"Reserve prop is forward regardless of player identifier or roster order")
    set wing=##class(Rugby.Service.Positions).Describe(11),flanker=##class(Rugby.Service.Positions).Describe(6)
    do ..Assert((wing.group="backs")&&(flanker.group="forwards"),"Wings and flankers use rugby roles despite similar names")
    set club={"id":"c1","day":0,"date":"2026-11-07"},plan={"groups":[]},p=..Player(25)
    set p.energy=1
    do ..Assert(##class(Rugby.Service.Development).Average(p)=50,"Average excludes energy and form")
    set p.attributes.strength=67
    do ..Assert(##class(Rugby.Service.Development).Average(p)=51,"Average includes all seventeen characteristics")
    set p=..Player(18),g={"id":"test","name":"Fuerza","focus":"strength","intensity":"normal","playerIds":[(p.id)]},plan.groups=[(g)]
    set profile=##class(Rugby.Service.Development).Profile(p,club,plan,..Qualities(90))
    do ..Assert(profile.potential>profile.average,"Young player year-end growth with training")
    do ..Assert(profile.potentialDate="2027-06-30","Potential is season-end")
    do ..Assert(profile.attributes.strength=50,"Forecast does not train current player")
    do ..Assert(profile.energy=100,"Forecast does not spend real energy")
    do ..Assert((profile.potential>51)&&(profile.potential<58),"Season projection reflects meaningful average progression")
    set p=..Player(38),profile=##class(Rugby.Service.Development).Profile(p,club,plan,..Qualities(90))
    do ..Assert((profile.potential<profile.average)&&(profile.potentialTrend="decline"),"Veteran potential indicates lower year-end average")
    set p=..Player(25),club.date="2027-06-30",profile=##class(Rugby.Service.Development).Profile(p,club,plan,..Qualities(90))
    do ..Assert(profile.potential=profile.average,"No future days on final season day")
    set club.date="2027-07-01",profile=##class(Rugby.Service.Development).Profile(..Player(25),club,plan,..Qualities(90))
    do ..Assert(profile.potentialDate="2028-06-30","Forecast rolls over with season")
    set club.date="2027-01-01",profile=##class(Rugby.Service.Development).Profile(..Player(25),club,plan,..Qualities(90))
    do ..Assert(profile.potentialDate="2027-06-30","January stays within the same season")
}
ClassMethod AnnualRates()
{
    set start=$zdateh("2027-07-01",3)-$zdateh("2026-11-07",3),group={"id":"annual","name":"Velocidad","focus":"speed","intensity":"normal","playerIds":["c1-p1"]}
    for age=22,26,30,34,38 {
        set low=..Player(age),high=..Player(age),low.birthDay=start-(age*365),high.birthDay=low.birthDay
        for offset=0:1:365 {
            set catalog=##class(Rugby.Service.Development).Catalog(),group.focus=catalog.%Get(offset#17).id
            set session=$select((offset#7)<5:group,1:"")
            set a=##class(Rugby.Service.Development).Apply(low,session,start+offset,..Qualities(0))
            set b=##class(Rugby.Service.Development).Apply(high,session,start+offset,..Qualities(100))
        }
        set lowDelta=##class(Rugby.Service.Development).Average(low)-50,highDelta=##class(Rugby.Service.Development).Average(high)-50
        set lower=##class(Rugby.Service.Development).AnnualChange(age,0),upper=##class(Rugby.Service.Development).AnnualChange(age,100)
        write "AVERAGE age ",age,": ",$justify(lowDelta,0,3)," to ",$justify(highDelta,0,3),!
        do ..Assert($zabs(lowDelta-lower)<.003,"Low quality annual average matches age band")
        do ..Assert($zabs(highDelta-upper)<.003,"High quality annual average matches age band")
        do ..Assert(highDelta>lowDelta,"Better coaches improve growth or soften decline")
        if age>32 do ..Assert(high.attributes.speed<high.attributes.leadership,"Physical skills decline faster than mental skills")
    }
    // Explicit inclusive boundaries, including the user's 35/36 transition.
    for age=24,28,32,35,36 {
        set low=##class(Rugby.Service.Development).AnnualChange(age,0),high=##class(Rugby.Service.Development).AnnualChange(age,100)
        do ..Assert(low=$select(age=24:6,age=28:2,age=32:0,age=35:-4,1:-7),"Lower age boundary")
        do ..Assert(high=$select(age=24:8,age=28:5,age=32:2,age=35:-2,1:-5),"Upper age boundary")
    }
}
ClassMethod Run()
{
    do ..Profiles()
    do ..Suggestions()
    set catalog=##class(Rugby.Service.Development).Catalog()
    do ..Assert(catalog.%Size()=18,"Seventeen trainable attributes plus recovery")
    set all=##class(Rugby.Service.Store).All("Player")
    for i=0:1:all.%Size()-1 {
        set p=all.%Get(i)
        for j=0:1:catalog.%Size()-2 { set value=p.attributes.%Get(catalog.%Get(j).id) do ..Assert((value>=1)&&(value<=100),"Every player has every trainable attribute in range") }
    }
    do ..AnnualRates()
    set g={"id":"g1","name":"Velocidad","focus":"speed","intensity":"high","playerIds":["c1-p1"]}
    set p=..Player(22),g.intensity="normal"
    set r=##class(Rugby.Service.Development).Apply(p,g,1,..Qualities(100))
    do ..Assert($zabs(r.averageDelta-(8*7/365/5))<.000003,"Daily attribute distribution produces the intended average gain")
    do ..Assert(r.changes.%Size()=1,"A session improves only the selected characteristic")
    do ..Assert(p.attributes.passing=50,"Untrained characteristics do not increase")
    do ..Assert($zabs(r.attributeGain-(8*17*7/365/5))<.000003,"Selected characteristic gains seventeen times the intended mean increment")
    set g.intensity="high"
    set p=..Player(25),p.developmentModel="3.0.0",p.developmentSeason="2027-06-30",p.developmentProgress=4.999999
    set r=##class(Rugby.Service.Development).Apply(p,g,1,..Qualities(100))
    do ..Assert(p.developmentProgress<=5,"Changing plans cannot bypass average season budget")
    set p=..Player(25),p.attributes.speed=100
    set r=##class(Rugby.Service.Development).Apply(p,g,1,..Qualities(100))
    do ..Assert(p.attributes.speed=100,"Attribute upper bound")
    do ..Assert((r.attributeGain=0)&&(r.changes.%Size()=0),"A saturated focus never redirects growth to untrained characteristics")
    set p=..Player(25),p.energy=10
    set r=##class(Rugby.Service.Development).Apply(p,g,1,..Qualities(100))
    do ..Assert((r.attributeGain=0)&&(p.energy>10),"Exhausted players recover instead of getting stuck without progress")
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1"),groups=[(g),{"id":"g2","name":"Pase","focus":"passing","intensity":"normal","playerIds":["c1-p2"]}]
    set saved=##class(Rugby.Service.Development).Save("c1",{"version":(plan.version),"groups":(groups)})
    set club=##class(Rugby.Service.Store).Get("Club","c1"),execution=##class(Rugby.Service.Development).Process("c1",club.day+1)
    set p1=##class(Rugby.Service.Store).Get("Player","c1-p1"),p2=##class(Rugby.Service.Store).Get("Player","c1-p2")
    set fingerprint=p1.%ToJSON(),retry=##class(Rugby.Service.Development).Process("c1",club.day+1),after=##class(Rugby.Service.Store).Get("Player","c1-p1")
    do ..Assert(fingerprint=after.%ToJSON(),"Session retry cannot train twice")
    do ..Assert(execution.id=retry.id,"One execution per club and day")
    do ..Assert((execution.trainingCost=0)&&(saved.dailyCost=0)&&(saved.rawDailyCost=0),"Training has no additional charge regardless of group or intensity")
    set groups.%Get(1).playerIds=["c1-p1"],caught=0
    try { set invalid=##class(Rugby.Service.Development).Save("c1",{"version":(saved.version),"groups":(groups)}) } catch ex { set caught=ex.Location="TRAINING_DUPLICATE" }
    do ..Assert(caught,"Overlapping groups rejected")
    set groups.%Get(1).playerIds=["c2-p1"],caught=0
    try { set invalid=##class(Rugby.Service.Development).Save("c1",{"version":(saved.version),"groups":(groups)}) } catch ex { set caught=ex.Location="PLAYER_CLUB" }
    do ..Assert(caught,"Foreign player rejected")
    set caught=0
    try { set invalid=##class(Rugby.Service.Development).Save("c1",{"version":(saved.version-1),"groups":[]}) } catch ex { set caught=ex.Location="VERSION_CONFLICT" }
    do ..Assert(caught,"Stale plan rejected")
    set staff=##class(Rugby.Service.Staff).View("c1"),candidates=##class(Rugby.Service.Store).All("Coach","clubId",""),candidate=candidates.%Get(0)
    set hired=##class(Rugby.Service.Staff).Hire("c1",{"version":(staff.version),"coachId":(candidate.id)},"test-hire")
    set again=##class(Rugby.Service.Staff).Hire("c1",{"version":(staff.version),"coachId":(candidate.id)},"test-hire")
    do ..Assert(hired.coaches.%Size()=8,"One coach per role after replacement")
    do ..Assert(hired.version=again.version,"Hire retry does not duplicate contract")
    set contracts=##class(Rugby.Service.Store).All("StaffContract","clubId","c1")
    do ..Assert($isobject(##class(Rugby.Service.Store).Get("StaffContract","c1-test-hire",0)),"Contract persists")
    do ..Assert(##class(Rugby.Service.Staff).Salary("head",90)>##class(Rugby.Service.Staff).Salary("head",35),"Better acceleration costs more")
    set caught=0
    try { set invalid=##class(Rugby.Service.Staff).Hire("c1",{"version":(hired.version),"coachId":(candidate.id)},"test-hire-again") } catch ex { set caught=ex.Location="COACH_UNAVAILABLE" }
    do ..Assert(caught,"Coach under contract cannot be hired again")
    // Settlement and proration are covered by the monthly payroll tests.
    do ..Assert(hired.monthlyWage>0,"Staff exposes actual monthly salaries")
}
}
