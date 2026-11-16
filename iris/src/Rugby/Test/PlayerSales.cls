Class Rugby.Test.PlayerSales Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set %RugbyGame="template",%RugbyManagedClub="c1",c=##class(Rugby.Service.Store).Get("Club","c1"),start=c.day
    set own=##class(Rugby.Service.Store).Get("Player","c1-p1"),original=own.%ToJSON(),body={"version":(own.version),"listed":true,"transferFee":100000}
    set listed=##class(Rugby.Service.PlayerSales).Save(own.id,body,"own-sale"),again=##class(Rugby.Service.PlayerSales).Save(own.id,body,"own-sale"),own=##class(Rugby.Service.Store).Get("Player",own.id)
    do ..Assert((listed.%ToJSON()=again.%ToJSON())&&own.transferListed&&(own.clubId="c1"),"Listing is idempotent and preserves ownership")
    set p=##class(Rugby.Service.Store).Get("Player","c2-p1"),error=""
    try { set ignored=##class(Rugby.Service.PlayerSales).Save(p.id,{"version":(p.version),"listed":true,"transferFee":0},"foreign-sale") } catch ex { set error=ex.Location }
    do ..Assert(error'="","A manager cannot list another club's player")
    set players=##class(Rugby.Service.Store).All("Player","clubId","c2")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i),p.transferListed=1,p.transferFee=100000 do ##class(Rugby.Service.Store).Put("Player",p) }
    set engine=##class(Rugby.Service.TransferPool).Players(0),market=##class(Rugby.Service.Transfers).Market()
    do ..Assert((engine.%Size()=20)&&(market.%Size()>20),"Club listings do not consume the twenty generated-agent places")
    set week=##class(Rugby.Service.ForeignMarket).Tick(start+7),p=##class(Rugby.Service.Store).Get("Player","c2-p1")
    do ..Assert(p.transferListed&&('p.%Get("transferMarketRemoved",0))&&(##class(Rugby.Service.TransferPool).Players(0).%Size()=20),"Weekly rotation never removes club listings")
    set n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"buy-listed"),raw=##class(Rugby.Service.Store).Get("Negotiation",n.id),raw.reservationWage=100,raw.askingWeeklyWage=100
    do ##class(Rugby.Service.Store).Put("Negotiation",raw)
    set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"weeklyWage":100,"contractYears":2},"listed-offer"),buyer=##class(Rugby.Service.Store).Get("Club","c1"),seller=##class(Rugby.Service.Store).Get("Club","c2"),balance=buyer.balance,sellerBalance=seller.balance
    set signed=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"listed-sign"),again=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"listed-sign"),p=##class(Rugby.Service.Store).Get("Player",p.id)
    do ..Assert((signed.%ToJSON()=again.%ToJSON())&&(p.clubId="c1")&&('p.transferListed),"A listed player moves exactly once after accepting the contract")
    do ..Assert((##class(Rugby.Service.Store).Get("Club","c1").balance=balance-100000)&&(##class(Rugby.Service.Store).Get("Club","c2").balance=sellerBalance+100000),"The transfer conserves cash across buyer and seller")
    set l=##class(Rugby.Service.Store).Get("Lineup","c2-default"),selected=0
    for i=0:1:l.slots.%Size()-1 { if l.slots.%Get(i).playerId=p.id set selected=1 }
    for i=0:1:l.bench.%Size()-1 { if l.bench.%Get(i)=p.id set selected=1 }
    do ..Assert('selected,"The sold player is removed from the seller's lineup")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),buyer=##class(Rugby.Service.Store).Get("Club","c2"),balance=buyer.balance,previousSignings=buyer.aiSignings,sellerBalance=##class(Rugby.Service.Store).Get("Club","c1").balance
    set proposal={"playerId":(p.id),"playerVersion":(p.version),"weeklyWage":100,"monthlyWage":433,"medical":false,"medicalNeed":{"position":0}}
    set ai=##class(Rugby.Service.Rivals).AcceptRecruitment(buyer,proposal,start)
    do ..Assert(ai.signed&&(##class(Rugby.Service.Store).Get("Player",p.id).clubId="c2"),"An automatic club can buy a human-listed player")
    do ..Assert((##class(Rugby.Service.Store).Get("Club","c2").balance=balance-100000)&&(##class(Rugby.Service.Store).Get("Club","c1").balance=sellerBalance+100000),"Automatic purchases credit the human seller exactly once")
    do ..Assert(##class(Rugby.Service.Store).Get("Club","c2").aiSignings=previousSignings+1,"Automatic transfers persist the recruitment quota")
    set p=##class(Rugby.Service.Store).Get("Player","c2-p2"),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"withdrawn-sale"),%RugbyManagedClub="c2"
    set ignored=##class(Rugby.Service.PlayerSales).Save(p.id,{"version":(p.version),"listed":false},"withdraw-list"),%RugbyManagedClub="c1",visible=##class(Rugby.Service.Transfers).Get(n.id)
    do ..Assert(visible.status="unavailable","Withdrawing a sale invalidates pending buyer negotiations")
    set error=""
    try { set ignored=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":100},"stale-sale") } catch ex { set error=ex.Location }
    do ..Assert(error'="","A stale offer cannot sign a withdrawn player")
}
}
