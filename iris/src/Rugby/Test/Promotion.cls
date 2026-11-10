Class Rugby.Test.Promotion Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set p=##class(Rugby.Service.Store).Get("Player","c1-p24"),oldWage=p.weeklyWage,attributes=p.attributes.%ToJSON(),energy=p.energy,c=##class(Rugby.Service.Store).Get("Club","c1"),balance=c.balance,plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1").%ToJSON(),count=##class(Rugby.Service.Store).All("Player","clubId","c1").%Size()
    set n=##class(Rugby.Service.Router).Resolve("POST","clubs","c1","promote",p.id,{"version":(p.version)},"test-promotion-open")
    do ..Assert((n.kind="promotion")&&(n.status="open")&&(n.signingFee=0)&&('n.%IsDefined("reservationWage")),"Public promotion starts a private salary negotiation without a fee")
    do ..Assert(##class(Rugby.Service.Store).Get("Player",p.id).category="academy","Starting negotiations does not promote the player")
    set error=""
    try { set ignored=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"test-promo-early") } catch ex { set error=ex.Location }
    do ..Assert(error="NEGOTIATION_STATE","Promotion cannot bypass salary agreement")
    set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":100},"test-promotion-low")
    do ..Assert((n.status="counteroffer")&&(##class(Rugby.Service.Store).Get("Player",p.id).weeklyWage=oldWage),"A low offer receives a counteroffer while the academy wage remains unchanged")
    set wage=n.counterWeeklyWage,n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(wage)},"test-promotion-agree"),body={"version":(n.version)},signed=##class(Rugby.Service.Transfers).Sign(n.id,body,"test-promotion-sign"),again=##class(Rugby.Service.Transfers).Sign(n.id,body,"test-promotion-sign"),p=##class(Rugby.Service.Store).Get("Player",p.id)
    do ..Assert((signed.status="signed")&&(signed.%ToJSON()=again.%ToJSON())&&(p.category="senior")&&(p.weeklyWage=wage),"Confirmed promotion applies the negotiated salary exactly once")
    do ..Assert((p.attributes.%ToJSON()=attributes)&&(p.energy=energy)&&(p.clubId="c1")&&(##class(Rugby.Service.Store).All("Player","clubId","c1").%Size()=count),"Promotion preserves the same player and sporting progress")
    do ..Assert((##class(Rugby.Service.Store).Get("Club","c1").balance=balance)&&(##class(Rugby.Service.Store).Get("TrainingPlan","c1").%ToJSON()=plan),"No fee is charged and training groups remain intact")
    do ..Assert(##class(Rugby.Service.Store).Get("PlayerContract",signed.contractId).kind="promotion","Promotion contract records the agreed salary and purpose")
    set error="",foreign=##class(Rugby.Service.Store).Get("Player","c2-p24")
    try { set ignored=##class(Rugby.Service.Transfers).Promotion("c1",foreign.id,{"version":(foreign.version)},"test-promo-foreign") } catch ex { set error=ex.Location }
    do ..Assert(error="CLUB_FORBIDDEN","Another club's academy cannot be promoted")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p25"),n=##class(Rugby.Service.Transfers).Promotion("c1",p.id,{"version":(p.version)},"test-promo-withdraw"),withdrawn=##class(Rugby.Service.Transfers).Withdraw(n.id,{"version":(n.version)},"test-promo-withdraw-confirm")
    do ..Assert((withdrawn.status="withdrawn")&&(##class(Rugby.Service.Store).Get("Player",p.id).category="academy"),"Withdrawal leaves the player in the academy")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p26"),n=##class(Rugby.Service.Transfers).Promotion("c1",p.id,{"version":(p.version)},"test-promo-stale"),p.energy=90,error=""
    do ##class(Rugby.Service.Store).Put("Player",p)
    try { set ignored=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"test-promo-stale-offer") } catch ex { set error=ex.Location }
    do ..Assert(error="PLAYER_CHANGED","Outdated player conditions require a fresh negotiation")
    set m=##class(Rugby.Test.Suite).Build(),p=##class(Rugby.Service.Store).Get("Player","c1-p27"),n=##class(Rugby.Service.Transfers).Promotion("c1",p.id,{"version":(p.version)},"test-promo-active"),n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"test-promo-active-offer"),error=""
    try { set ignored=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"test-promo-active-sign") } catch ex { set error=ex.Location }
    do ..Assert(error="MATCH_ACTIVE","Salary agreement does not allow promotion during a match")
}
}
