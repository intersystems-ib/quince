Class Rugby.Test.ForeignMarket Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set game=##class(Rugby.Service.Store).Game(),start=^RugbyWorld(game,"foreignMarketLastDay"),players=##class(Rugby.Service.TransferPool).Players(),original={},ordered=""
    do ..Assert(players.%Size()=20,"Weekly market starts with twenty shared agents")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) do original.%Set(p.id,p) set ranking(##class(Rugby.Service.Development).Average(p),p.id)=p }
    set expected={},score="",lowest=""
    for { set score=$order(ranking(score)) quit:score=""  quit:expected.%Size()>=4  set id="" for { set id=$order(ranking(score,id)) quit:id=""  quit:expected.%Size()>=4  do expected.%Set(id,1) if lowest="" set lowest=id } }
    set p=##class(Rugby.Service.Store).Get("Player",lowest),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"weekly-lowest-negotiation"),before=##class(Rugby.Service.Store).All("Player").%ToJSON(),early=##class(Rugby.Service.ForeignMarket).Tick(start+6)
    do ..Assert((early.weeks.%Size()=0)&&(##class(Rugby.Service.Store).All("Player").%ToJSON()=before),"No churn or creation happens before seven game days")
    tstart
    set first=##class(Rugby.Service.ForeignMarket).Tick(start+7),firstJSON=first.%ToJSON(),snapshot=##class(Rugby.Service.Store).All("Player").%ToJSON()
    trollback 1
    set result=##class(Rugby.Service.ForeignMarket).Tick(start+7),week=result.weeks.%Get(0),positions={},seen={}
    do ..Assert((result.%ToJSON()=firstJSON)&&(##class(Rugby.Service.Store).All("Player").%ToJSON()=snapshot),"Weekly generation and removal are deterministic after rollback and replay")
    do ..Assert((week.removed.%Size()=4)&&(week.added.%Size()=4),"A full list replaces exactly its lowest twenty percent with four foreign agents")
    for i=0:1:week.removed.%Size()-1 {
        set id=week.removed.%Get(i).playerId,p=##class(Rugby.Service.Store).Get("Player",id)
        do ..Assert(expected.%IsDefined(id)&&p.transferMarketRemoved&&('##class(Rugby.Service.TransferPool).Contains(id)),"Only the four lowest averages leave, and refresh cannot bring them back")
        do ..Assert((p.attributes.%ToJSON()=original.%Get(id).attributes.%ToJSON())&&(p.clubId=""),"Market exits retain historical player records and skills")
    }
    for i=0:1:week.added.%Size()-1 {
        set p=##class(Rugby.Service.Store).Get("Player",week.added.%Get(i).playerId)
        do ..Assert((p.nationalityCode'="ES")&&(p.nationalityCode'="")&&(p.clubId="")&&(p.category="senior")&&(p.monthlyWage>0)&&(p.age>=18)&&(p.age<=34),"New agents are foreign, free, correctly aged and have monthly salary expectations")
        do ..Assert((p.talentScaleVersion=##class(Rugby.Service.TalentScale).#VERSION)&&(p.average<70),"New attributes use the same reduced talent scale as the leagues")
    }
    set listed=##class(Rugby.Service.TransferPool).Players()
    for i=0:1:listed.%Size()-1 { set p=listed.%Get(i) do ..Assert('seen.%IsDefined(p.id),"Shared market contains no duplicate identities") do seen.%Set(p.id,1),positions.%Set(p.position,1) }
    do ..Assert((listed.%Size()=20)&&(positions.%Size()=15),"Foreign intake restores twenty candidates and covers all rugby positions")
    set expired=##class(Rugby.Service.Transfers).Get(n.id),error=""
    try { set ignored=##class(Rugby.Service.Transfers).Free(lowest) } catch ex { set error=ex.Location }
    do ..Assert((expired.status="expired")&&(expired.marketExitReason="weeklyRotation")&&(error="MARKET_UNLISTED"),"An agent leaving the market expires active negotiations and cannot be signed through a stale link")
    set before=##class(Rugby.Service.Store).All("Player").%ToJSON(),again=##class(Rugby.Service.ForeignMarket).Tick(start+7),view=##class(Rugby.Service.Transfers).Market()
    do ..Assert((again.weeks.%Size()=0)&&(##class(Rugby.Service.Store).All("Player").%ToJSON()=before),"Same-day retries and market reads never produce additional players")
    set p=##class(Rugby.Service.Store).Get("Player",week.added.%Get(0).playerId),p.clubId="c2",p.contractStatus="employed",signed=p.id
    do ##class(Rugby.Service.Store).Put("Player",p)
    set signedJSON=p.%ToJSON(),pool=##class(Rugby.Service.TransferPool).Refresh(start+8)
    do ..Assert(##class(Rugby.Service.TransferPool).Players().%Size()=19,"Signed agents leave immediately, without daily regeneration")
    set next=##class(Rugby.Service.ForeignMarket).Tick(start+14),week=next.weeks.%Get(0)
    do ..Assert((week.removed.%Size()=4)&&(week.added.%Size()=5)&&(##class(Rugby.Service.TransferPool).Players().%Size()=20),"The next weekly intake replaces the rounded twenty percent and fills vacancies left by signings")
    do ..Assert(##class(Rugby.Service.Store).Get("Player",signed).%ToJSON()=signedJSON,"Weekly churn never modifies players already signed by a club")
}
}
