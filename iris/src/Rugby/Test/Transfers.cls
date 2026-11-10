Class Rugby.Test.Transfers Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set %RugbyGame="template",%RugbyManagedClub="c1"
    do ##class(Rugby.Service.Transfers).Initialize()
    set players=##class(Rugby.Service.Transfers).Market(),p=players.%Get(0),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"test-neg"),c=##class(Rugby.Service.Store).Get("Club","c1"),balance=c.balance
    do ..Assert('n.%IsDefined("reservationWage"),"Private salary threshold never appears in the public negotiation")
    set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"test-agree")
    do ..Assert(n.status="agreed","Requested salary is accepted without automatically signing")
    set q=##class(Rugby.Service.Store).Get("Player",p.id)
    do ..Assert((q.clubId="")&&(##class(Rugby.Service.Store).Get("Club","c1").balance=balance),"Salary agreement leaves the player free and funds untouched")
    set %RugbyManagedClub="c2",error=""
    try { set out=##class(Rugby.Service.Transfers).Get(n.id) } catch ex { set error=ex.Location }
    do ..Assert(error="CLUB_FORBIDDEN","Negotiations are private to the managed club")
    set %RugbyManagedClub="c1",q.clubId="c2"
    do ##class(Rugby.Service.Store).Put("Player",q)
    set out=##class(Rugby.Service.Transfers).Get(n.id),error=""
    try { set out=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"test-race") } catch ex { set error=ex.Location }
    do ..Assert(error="PLAYER_TAKEN","A rival signing prevents double ownership")
    do ..Assert(##class(Rugby.Service.Store).Get("Club","c1").balance=balance,"Unavailable players cause no charges")
    set p=players.%Get(1),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"test-neg-expired"),c.day=n.expiresDay+1
    do ##class(Rugby.Service.Store).Put("Club",c)
    set out=##class(Rugby.Service.Transfers).Get(n.id),error=""
    try { set out=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"test-expired") } catch ex { set error=ex.Location }
    do ..Assert((out.status="expired")&&(error="NEGOTIATION_EXPIRED"),"Expired proposals cannot be accepted")
    set p=players.%Get(2),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"test-neg-funds"),n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"test-agree-funds"),c.balance=0
    do ##class(Rugby.Service.Store).Put("Club",c)
    set error=""
    try { set out=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"test-no-funds") } catch ex { set error=ex.Location }
    do ..Assert(error="SIGNING_FUNDS","Signing bonuses require sufficient funds")
    set c.balance=balance
    do ##class(Rugby.Service.Store).Put("Club",c)
    set m=##class(Rugby.Test.Suite).Build(),error=""
    try { set out=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"test-active-sign") } catch ex { set error=ex.Location }
    do ..Assert(error="MATCH_ACTIVE","A running match blocks additions to the roster")
}
}
