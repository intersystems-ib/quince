Class Rugby.Test.Availability Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set l=##class(Rugby.Service.Store).Get("Lineup","c1-default"),bench=l.bench.%Get(0),second=l.bench.%Get(1),starter=l.slots.%Get(0).playerId,p=##class(Rugby.Service.Store).Get("Player",bench),p.available=0,p.recoveryDay=1000
    do ##class(Rugby.Service.Store).Put("Player",p)
    set p=##class(Rugby.Service.Store).Get("Player",second),p.available=0,p.unavailableReason="Otra causa futura",p.recoveryDay=1000
    do ##class(Rugby.Service.Store).Put("Player",p)
    set originalSize=l.bench.%Size(),l.captainId=bench,removed=##class(Rugby.Service.Management).NormalizeBench(l),v=##class(Rugby.Service.Management).Validate(l)
    do ..Assert((removed.%Size()=2)&&(l.bench.%Size()=originalSize-2)&&v.valid,"Unavailable substitutes are removed for injuries or other causes without blocking a valid XV")
    do ..Assert((l.captainId'=bench)&&(l.captainId'=second),"Unavailable bench captain is replaced")
    set saved=##class(Rugby.Service.Management).SaveLineup(l.id,l),v=##class(Rugby.Service.Management).Validate(saved)
    do ..Assert(v.valid&&(saved.bench.%Size()=originalSize-2),"The cleaned lineup saves successfully")
    // Old clients may still submit the unavailable bench: save must normalize it too.
    do saved.bench.%Push(bench)
    set saved=##class(Rugby.Service.Management).SaveLineup(saved.id,saved)
    do ..Assert(saved.bench.%Size()=originalSize-2,"A stale bench submission cannot select an unavailable player")
    set p=##class(Rugby.Service.Store).Get("Player",starter),p.available=0,p.recoveryDay=1000
    do ##class(Rugby.Service.Store).Put("Player",p)
    set v=##class(Rugby.Service.Management).Validate(saved)
    do ..Assert(('v.valid)&&(saved.slots.%Get(0).playerId=starter),"An unavailable starter must be explicitly replaced rather than silently leaving a vacant slot")
    set incoming=saved.bench.%Get(0),saved.slots.%Get(0).playerId=incoming
    do saved.bench.%Set(0,starter)
    if saved.captainId=starter set saved.captainId=incoming
    set saved=##class(Rugby.Service.Management).SaveLineup(saved.id,saved),v=##class(Rugby.Service.Management).Validate(saved)
    do ..Assert(v.valid&&(saved.bench.%Size()=originalSize-3),"Replacing an unavailable starter with a substitute does not put the injured player on the bench")
    // Recovery returns a player to the bench only once, when there is room.
    set p=##class(Rugby.Service.Store).Get("Player",bench),p.available=1
    do ##class(Rugby.Service.Store).Put("Player",p)
    set saved=##class(Rugby.Service.Store).Get("Lineup",saved.id)
    set saved=##class(Rugby.Service.Management).SaveLineup(saved.id,saved),p.available=0
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Management).RefreshAvailability("c1")
    set saved=##class(Rugby.Service.Store).Get("Lineup",saved.id),count=saved.bench.%Size(),version=saved.version
    do ##class(Rugby.Service.Management).RefreshAvailability("c1")
    do ..Assert(##class(Rugby.Service.Store).Get("Lineup",saved.id).version=version,"Availability refresh does not rewrite unchanged lineups")
    set recovered=##class(Rugby.Service.Injuries).Recover(p,p.recoveryDay)
    do ..Assert(recovered,"The recovery date makes the player available")
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Management).RefreshAvailability("c1")
    set saved=##class(Rugby.Service.Store).Get("Lineup",saved.id)
    do ..Assert((saved.bench.%Size()=count+1)&&(saved.bench.%Get(count)=bench),"Recovery automatically fills a vacant bench place")
    set version=saved.version
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Management).RefreshAvailability("c1")
    do ..Assert(##class(Rugby.Service.Store).Get("Lineup",saved.id).version=version,"Repeated recovery refresh does not duplicate the player or rewrite the lineup")
    set roster=##class(Rugby.Service.Store).All("Player","clubId","c1"),selected={}
    for i=0:1:saved.slots.%Size()-1 { do selected.%Set(saved.slots.%Get(i).playerId,1) }
    for i=0:1:saved.bench.%Size()-1 { do selected.%Set(saved.bench.%Get(i),1) }
    for i=0:1:roster.%Size()-1 {
        quit:saved.bench.%Size()=8
        set q=roster.%Get(i)
        if (q.category="senior")&&q.available&&('selected.%IsDefined(q.id)) { do saved.bench.%Push(q.id),selected.%Set(q.id,1) }
    }
    while saved.bench.%Size()<8 {
        set q=##class(Rugby.Service.Store).Get("Player",incoming),q.id="recovery-reserve-"_saved.bench.%Size()
        do ##class(Rugby.Service.Store).Put("Player",q),saved.bench.%Push(q.id)
    }
    set saved=##class(Rugby.Service.Management).SaveLineup(saved.id,saved),p=##class(Rugby.Service.Store).Get("Player",second),p.available=1
    do ##class(Rugby.Service.Store).Put("Player",p)
    set saved=##class(Rugby.Service.Store).Get("Lineup",saved.id),found=0
    for i=0:1:saved.bench.%Size()-1 { if saved.bench.%Get(i)=second set found=1 }
    do ..Assert((saved.bench.%Size()=8)&&('found),"With a full bench the recovered player remains available and unselected")
    // A recovered starter stays in his slot and is never duplicated on the bench.
    set vacant=[]
    for i=0:1:6 { do vacant.%Push(saved.bench.%Get(i)) }
    set saved.bench=vacant,saved=##class(Rugby.Service.Management).SaveLineup(saved.id,saved)
    set p=##class(Rugby.Service.Store).Get("Player",incoming),p.available=0
    do ##class(Rugby.Service.Store).Put("Player",p)
    set p.available=1
    do ##class(Rugby.Service.Store).Put("Player",p)
    set saved=##class(Rugby.Service.Store).Get("Lineup",saved.id)
    do ..Assert((saved.slots.%Get(0).playerId=incoming)&&(saved.bench.%Size()=7),"Recovery preserves an existing starting position even with a vacant bench place")
    // Club boundaries remain strict even when a submitted foreign player is unavailable.
    set foreign=##class(Rugby.Service.Store).Get("Player","c2-p1"),foreign.available=0
    do ##class(Rugby.Service.Store).Put("Player",foreign),saved.bench.%Push(foreign.id)
    set v=##class(Rugby.Service.Management).Validate(saved)
    do ..Assert('v.valid,"Unavailable foreign players are rejected, not silently accepted")
}
}
