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
    // Availability updates should persist bench cleanup, not re-add recovered players.
    set p=##class(Rugby.Service.Store).Get("Player",bench),p.available=1
    do ##class(Rugby.Service.Store).Put("Player",p)
    do saved.bench.%Push(bench)
    set saved=##class(Rugby.Service.Management).SaveLineup(saved.id,saved),p.available=0
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Management).RefreshAvailability("c1")
    set saved=##class(Rugby.Service.Store).Get("Lineup",saved.id),count=saved.bench.%Size(),version=saved.version
    do ##class(Rugby.Service.Management).RefreshAvailability("c1")
    do ..Assert(##class(Rugby.Service.Store).Get("Lineup",saved.id).version=version,"Availability refresh does not rewrite unchanged lineups")
    set p.available=1
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Management).RefreshAvailability("c1")
    do ..Assert(##class(Rugby.Service.Store).Get("Lineup",saved.id).bench.%Size()=count,"Recovery does not automatically select a player")
    // Club boundaries remain strict even when a submitted foreign player is unavailable.
    set foreign=##class(Rugby.Service.Store).Get("Player","c2-p1"),foreign.available=0
    do ##class(Rugby.Service.Store).Put("Player",foreign),saved.bench.%Push(foreign.id)
    set v=##class(Rugby.Service.Management).Validate(saved)
    do ..Assert('v.valid,"Unavailable foreign players are rejected, not silently accepted")
}
}
