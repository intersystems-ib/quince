Class Rugby.Test.Rivals Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run()
{
    set own=##class(Rugby.Service.Store).Get("Club","c1"),day=own.day+1,originalPlayers=##class(Rugby.Service.Store).All("Player","clubId","c1").%ToJSON(),originalPlan=##class(Rugby.Service.Store).Get("TrainingPlan","c1").%ToJSON(),originalStaff=##class(Rugby.Service.Staff).View("c1").%ToJSON(),fingerprint=""
    for pass=1:1:2 {
        tstart
        set tired=##class(Rugby.Service.Store).Get("Player","c2-p1"),tired.energy=15
        do ##class(Rugby.Service.Store).Put("Player",tired)
        set injured=##class(Rugby.Service.Store).Get("Player","c2-p2"),injured.available=0,injured.recoveryDay=day+2
        do ##class(Rugby.Service.Store).Put("Player",injured)
        set graduating=##class(Rugby.Service.Store).Get("Player","c2-academy-2"),graduating.age=23,graduating.birthDay=day-(23*365)-10,catalog=##class(Rugby.Service.Development).Catalog()
        for k=0:1:16 { do graduating.attributes.%Set(catalog.%Get(k).id,20) }
        do ##class(Rugby.Service.Store).Put("Player",graduating)
        set result=##class(Rugby.Service.Rivals).Day(day),again=##class(Rugby.Service.Rivals).Day(day),hired=0,signed=0,youthTraining=0,recovered=0,ids={}
        do ..Assert(result.clubs.%Size()=19,"Exactly nineteen clubs are managed automatically")
        do ..Assert(result.%ToJSON()=again.%ToJSON(),"Replaying the day does not repeat training, salaries or recruitment")
        do ..Assert(##class(Rugby.Service.Store).Get("Player",graduating.id).clubId="","Older academy players leave and are replaced without deleting their history")
        for i=0:1:result.clubs.%Size()-1 {
            set r=result.clubs.%Get(i),c=##class(Rugby.Service.Store).Get("Club",r.clubId),players=##class(Rugby.Service.Store).All("Player","clubId",r.clubId),academy=0,coverage={}
            do ..Assert((r.clubId'="c1")&&(c.day=day),"All rival clocks follow the management day")
            for j=0:1:players.%Size()-1 { set p=players.%Get(j) if p.category="academy" { set academy=academy+1 do coverage.%Set(p.position,1) } }
            do ..Assert((academy>=20)&&(coverage.%Size()=15),"Academies retain at least twenty players and every position")
            if r.staff.%Get("hired",0) { set hired=hired+1 do ..Assert((r.staff.quality>r.staff.beforeQuality)&&(r.staff.quality<=(r.staff.beforeQuality+8)),"Coaching improves gradually") }
            if r.recruitment.%Get("signed",0) {
                set signed=signed+1
                do ..Assert('ids.%IsDefined(r.recruitment.playerId),"A free agent cannot be signed twice")
                do ids.%Set(r.recruitment.playerId,1)
                do ..Assert(##class(Rugby.Service.Store).Get("Player",r.recruitment.playerId).clubId=r.clubId,"Signed players join the actual rival roster")
            }
            set l=##class(Rugby.Service.Store).Get("Lineup",r.clubId_"-default"),valid=##class(Rugby.Service.Management).Validate(l)
            do ..Assert(valid.valid,"AI chooses a legal lineup by position")
            for j=0:1:r.results.%Size()-1 {
                set e=r.results.%Get(j),p=##class(Rugby.Service.Store).Get("Player",e.playerId)
                if (p.category="academy")&&(e.attributeGain>0)&&(e.energyDelta<0) set youthTraining=youthTraining+1
                if e.playerId="c2-p1" { set recovered=e.focus="recovery" do ..Assert((e.energyDelta=18)&&(e.attributeGain=0),"Exhausted players rest instead of training") }
            }
        }
        do ..Assert((hired>0)&&(signed>0)&&(youthTraining>0)&&recovered,"AI recruits players and staff and develops tired academies")
        do ..Assert(##class(Rugby.Service.Store).All("Player","clubId","c1").%ToJSON()=originalPlayers,"AI does not touch managed players")
        do ..Assert((##class(Rugby.Service.Store).Get("TrainingPlan","c1").%ToJSON()=originalPlan)&&(##class(Rugby.Service.Staff).View("c1").%ToJSON()=originalStaff),"AI does not change managed training or coaches")
        if pass=1 { set fingerprint=result.%ToJSON() } else { do ..Assert(fingerprint=result.%ToJSON(),"Same state and seed produce exactly the same decisions and development") }
        trollback 1
    }
    set youth=##class(Rugby.Service.Store).Get("Player","c2-academy-1"),average=##class(Rugby.Service.Development).Average(youth),lowest=100
    for n=1:1:21 {
        set result=##class(Rugby.Service.Rivals).Day(own.day+n),p=##class(Rugby.Service.Store).Get("Player",youth.id)
        if p.energy<lowest set lowest=p.energy
    }
    do ..Assert((##class(Rugby.Service.Development).Average(p)>average)&&(lowest<100),"Academy skills improve over weeks while energy fluctuates")
    do ..Assert(##class(Rugby.Service.Store).Get("Club","c1").day=own.day,"AI processing never advances the human club by itself")
    set fixtures=##class(Rugby.Service.Store).All("Fixture"),f=""
    for i=0:1:fixtures.%Size()-1 { set candidate=fixtures.%Get(i) if (candidate.%Get("stage")="regular")&&(candidate.homeId'="c1")&&(candidate.awayId'="c1")&&(candidate.status="scheduled") { set f=candidate quit } }
    set l=##class(Rugby.Service.Store).Get("Lineup",f.homeId_"-default"),pid=l.slots.%Get(0).playerId,p=##class(Rugby.Service.Store).Get("Player",pid),energy=p.energy,c=##class(Rugby.Service.Store).Get("Club",f.homeId),balance=c.balance
    do ##class(Rugby.Service.Competition).Simulate(f)
    set p=##class(Rugby.Service.Store).Get("Player",pid),c=##class(Rugby.Service.Store).Get("Club",f.homeId),energyAfter=p.energy
    do ..Assert((energyAfter<energy)&&((c.balance-balance)=f.economy.homeShare),"AI league matches consume energy and pay the home club")
    do ##class(Rugby.Service.Competition).Simulate(f)
    do ..Assert((##class(Rugby.Service.Store).Get("Player",pid).energy=energyAfter)&&(##class(Rugby.Service.Store).Get("Club",f.homeId).balance=c.balance),"A simulated fixture cannot consume energy or pay twice")
}
}
