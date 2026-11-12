Class Rugby.Test.InitialContracts Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set game=##class(Rugby.Service.Store).Game(),players=##class(Rugby.Service.Store).All("Player"),before={}
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        do p.%Remove("initialContractVersion"),p.%Remove("initialContractPreviousEndDate"),p.%Remove("initialContractExtraYears"),##class(Rugby.Service.Store).Put("Player",p)
    }
    set legacy=##class(Rugby.Service.Store).Get("Player","c1-academy-1")
    do legacy.%Remove("signedDay"),##class(Rugby.Service.Store).Put("Player",legacy)
    do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":"initial-protected-renewal","playerId":"c1-p1","clubId":"c1","kind":"renewal"})
    set p=##class(Rugby.Service.Store).Get("Player","c1-p2"),p.retirementAnnounced=1
    do ##class(Rugby.Service.Store).Put("Player",p)
    set p=##class(Rugby.Service.Store).Get("Player","c1-p3"),p.clubId="",p.contractStatus="expired"
    do ##class(Rugby.Service.Store).Put("Player",p)
    set p=##class(Rugby.Service.Store).Get("Player","c1-p4"),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"initial-pending","renewal")
    set players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) do before.%Set(p.id,p) }
    kill ^RugbyWorld(game,"initialContractsVersion")
    set result=##class(Rugby.Seed.Contracts).Initialize(),bands={}
    do ..Assert(result.changes.%Size()>500,"Migration covers initial senior and youth players across both leagues")
    for i=0:1:result.changes.%Size()-1 {
        set change=result.changes.%Get(i),old=before.%Get(change.playerId),p=##class(Rugby.Service.Store).Get("Player",change.playerId),extra=change.extraYears
        do bands.%Set(extra,1)
        do ..Assert((extra>=0)&&(extra<=3)&&(extra=(##class(Rugby.Service.Rivals).Hash("initial-contract-"_p.id,##class(Rugby.Service.Rivals).Seed())#4)),"Contract extensions are deterministic and range from zero to three years")
        if extra {
            do ..Assert(p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(##class(Rugby.Service.Competition).Year(old.contractEndDate)+extra),"Extensions add seasons to each current expiration, rather than replacing it with the current season")
        } else { do ..Assert(p.contractEndDate=old.contractEndDate,"Zero-year extensions keep the current expiration") }
        for field="version","contractEndDate","contractYears","initialContractVersion","initialContractPreviousEndDate","initialContractExtraYears" { do old.%Remove(field),p.%Remove(field) }
        do ..Assert(old.%ToJSON()=p.%ToJSON(),"Initial contract updates preserve wages, club, category, skills, morale, energy and injuries")
    }
    do ..Assert(##class(Rugby.Service.Store).Get("Player","c1-academy-1").%Get("initialContractVersion")'="","Legacy initial academy players without a signing date are included")
    do ..Assert(bands.%IsDefined(0)&&bands.%IsDefined(1)&&bands.%IsDefined(2)&&bands.%IsDefined(3),"Initial squads use all four expiration cohorts")
    for pid="c1-p1","c1-p2","c1-p3","c1-p4" { do ..Assert(##class(Rugby.Service.Store).Get("Player",pid).%ToJSON()=before.%Get(pid).%ToJSON(),"Signed renewals, retirees, free agents and pending negotiations are preserved") }
    set all=##class(Rugby.Service.Store).All("Player").%ToJSON(),again=##class(Rugby.Seed.Contracts).Initialize()
    do ..Assert((again.changes.%Size()=0)&&(all=##class(Rugby.Service.Store).All("Player").%ToJSON()),"Restarting cannot add another extension or modify player versions")
}
}
