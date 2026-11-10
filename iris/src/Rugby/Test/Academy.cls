Class Rugby.Test.Academy Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String)
{
    do ##class(Rugby.Test.Suite).Assert(ok,message)
}
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set club=clubs.%Get(i),players=##class(Rugby.Service.Store).All("Player","clubId",club.id),count=0,positions={},averages={}
        for j=0:1:players.%Size()-1 {
            set p=players.%Get(j)
            if p.category'="academy" continue
            set count=count+1
            do positions.%Set(p.position,1),averages.%Set(##class(Rugby.Service.Development).Average(p),1)
            do ..Assert((p.weeklyWage>=100)&&(p.weeklyWage<10000),"Academy wages remain modest and reflect club budget")
            do ..Assert(p.seniorWeeklyWage>p.weeklyWage,"Promotion wage is separate and higher")
        }
        do ..Assert((count>=20)&&(positions.%Size()=15),"Expanded academy covers all fifteen positions")
        do ..Assert(averages.%Size()>1,"Academy players have varied attributes")
        set staff=##class(Rugby.Service.Staff).View(club.id)
        do ..Assert((staff.coaches.%Size()=8)&&(staff.roles.%Size()=8),"Eight staff specialties including academy")
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),base=##class(Rugby.Test.Development).Player(18),base.category="academy",low=##class(%DynamicObject).%FromJSON(base.%ToJSON()),high=##class(%DynamicObject).%FromJSON(base.%ToJSON())
    set q1=##class(Rugby.Test.Development).Qualities(35),q2=##class(Rugby.Test.Development).Qualities(35),q1.academy=10,q2.academy=90,g={"id":"academy-test","name":"Fuerza","focus":"strength","intensity":"normal","playerIds":[(base.id)]}
    set a=##class(Rugby.Service.Development).Apply(low,g,1,q1),b=##class(Rugby.Service.Development).Apply(high,g,1,q2)
    do ..Assert(b.attributeGain>a.attributeGain,"Better academy coach increases academy progression")
    do ..Assert((a.changes.%Size()=1)&&(b.changes.%Size()=1)&&(high.attributes.speed=50),"Academy still develops only the selected skill")
    set low=##class(Rugby.Test.Development).Player(18),high=##class(Rugby.Test.Development).Player(18)
    set a=##class(Rugby.Service.Development).Apply(low,g,1,q1),b=##class(Rugby.Service.Development).Apply(high,g,1,q2)
    do ..Assert(a.attributeGain=b.attributeGain,"Academy coach does not replace senior specialists")
    set catalog=##class(Rugby.Service.Development).Catalog()
    for k=0:1:16 {
        set focus=catalog.%Get(k).id,low=##class(Rugby.Test.Development).Player(18),low.category="academy",high=##class(%DynamicObject).%FromJSON(low.%ToJSON()),g={"id":"youth-focus","focus":(focus),"intensity":"normal"}
        set a=##class(Rugby.Service.Development).Apply(low,g,1,q1),b=##class(Rugby.Service.Development).Apply(high,g,1,q2)
        do ..Assert((b.attributeGain>a.attributeGain)&&(b.changes.%Size()=1)&&(b.changes.%Get(0).attribute=focus),"Every chosen academy skill uses the academy coach and changes only that attribute")
    }
    set candidates=##class(Rugby.Service.Store).All("Coach","clubId",""),candidate=""
    for i=0:1:candidates.%Size()-1 { set coach=candidates.%Get(i) if coach.role="academy" { set candidate=coach quit } }
    set staff=##class(Rugby.Service.Staff).View("c1"),hired=##class(Rugby.Service.Staff).Hire("c1",{"coachId":(candidate.id),"version":(staff.version)},"academy-hire-test")
    do ..Assert(hired.coaches.%Size()=8,"Hiring academy coach replaces only that specialty")
    do ..Assert(##class(Rugby.Service.Staff).Qualities("c1").academy=candidate.quality,"Hired academy quality is used by development")
    // Promotion retains the player and converts the youth wage into the stored senior wage once.
    set players=##class(Rugby.Service.Store).All("Player","clubId","c1"),young=""
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.category="academy" { set young=p quit } }
    set before=players.%Size(),salary=young.seniorWeeklyWage,promoted=##class(Rugby.Service.Management).Promote("c1",young.id),again=##class(Rugby.Service.Management).Promote("c1",young.id)
    do ..Assert((promoted.weeklyWage=salary)&&(promoted.version=again.version),"Promotion applies senior salary once")
    do ..Assert(##class(Rugby.Service.Store).All("Player","clubId","c1").%Size()=before,"Promotion does not duplicate a youth player")
    do ..Release()
}
ClassMethod Release()
{
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),caught=0
    try { set r=##class(Rugby.Service.Management).Release(p.id,{"version":(p.version-1)},"stale-release") } catch ex { set caught=ex.Location="VERSION_CONFLICT" }
    do ..Assert(caught,"Releasing with a stale player version is rejected")
    set caught=0,other=##class(Rugby.Service.Store).Get("Player","c2-p1")
    try { set r=##class(Rugby.Service.Management).Release(other.id,{"version":(other.version)},"foreign-release") } catch ex { set caught=ex.Code=403 }
    do ..Assert(caught,"Cannot release another club's player")
    set m=##class(Rugby.Test.Suite).Build(),caught=0
    try { set r=##class(Rugby.Service.Management).Release(p.id,{"version":(p.version)},"active-release") } catch ex { set caught=ex.Location="MATCH_ACTIVE" }
    do ..Assert(caught,"Cannot release during a live match")
    set m.status="finished"
    do ##class(Rugby.Service.Store).Put("Match",m)
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1"),saved=##class(Rugby.Service.Development).Save("c1",{"version":(plan.version),"groups":[{"id":"release-group","name":"Fuerza","focus":"strength","intensity":"normal","playerIds":[(p.id)]}]})
    set lineup=##class(Rugby.Service.Store).Get("Lineup","c1-default"),lineup.captainId=p.id
    do ##class(Rugby.Service.Store).Put("Lineup",lineup)
    set c=##class(Rugby.Service.Store).Get("Club","c1"),balance=c.balance,attributes=p.attributes.%ToJSON(),r=##class(Rugby.Service.Management).Release(p.id,{"version":(p.version)},"senior-release"),retry=##class(Rugby.Service.Management).Release(p.id,{},"senior-release")
    set free=##class(Rugby.Service.Store).Get("Player",p.id),lineup=##class(Rugby.Service.Store).Get("Lineup",lineup.id),plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1")
    do ..Assert((free.clubId="")&&(free.weeklyWage=0)&&(free.attributes.%ToJSON()=attributes),"Released player is free and retains attributes")
    do ..Assert((r.%ToJSON()=retry.%ToJSON())&&(r.fee=0),"Release retry is idempotent and has no fee")
    do ..Assert((lineup.slots.%Get(0).playerId="")&&(lineup.captainId=""),"Release clears the lineup slot and captain")
    do ..Assert((plan.groups.%Size()=0)&&(plan.dailyCost=0),"Release removes training assignment and its cost")
    do ..Assert(##class(Rugby.Service.Store).Get("Club","c1").balance=balance,"Release does not change balance")
    do ..Assert($isobject(##class(Rugby.Service.Store).Get("PlayerContract",p.id_"-release-senior-release",0)),"Release audit is retained")
    set bench=##class(Rugby.Service.Store).Get("Player","c1-p16"),r=##class(Rugby.Service.Management).Release(bench.id,{"version":(bench.version)},"bench-release"),lineup=##class(Rugby.Service.Store).Get("Lineup","c1-default")
    do ..Assert(lineup.bench.%Size()=7,"Released substitute is removed from the bench")
    set players=##class(Rugby.Service.Store).All("Player","clubId","c1"),young="",wages=0
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.category="academy" { set young=p quit } }
    set r=##class(Rugby.Service.Management).Release(young.id,{"version":(young.version)},"academy-release")
    do ..Assert(##class(Rugby.Service.Store).Get("Player",young.id).clubId="","Academy contract can also be released")
    set players=##class(Rugby.Service.Store).All("Player","clubId","c1")
    for i=0:1:players.%Size()-1 { set wages=wages+players.%Get(i).weeklyWage }
    set execution=##class(Rugby.Service.Development).Process("c1",c.day+1)
    do ..Assert(execution.playerWeeklyWages=wages,"Released players are excluded from future payroll")
}
}
