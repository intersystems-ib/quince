Class Rugby.Test.TransferAuction Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    for scenario="salary","position","human" {
        tstart
        set pool=##class(Rugby.Service.TransferPool).Players(),candidate="",catalog=##class(Rugby.Service.Development).Catalog()
        for i=0:1:pool.%Size()-1 { set p=pool.%Get(i) if p.position=13 set candidate=p }
        do ..Assert($isobject(candidate),"A centre is available for the controlled competition")
        set all=##class(Rugby.Service.Store).All("Player","clubId","")
        for i=0:1:all.%Size()-1 { set p=all.%Get(i) if p.id'=candidate.id { set p.available=0 do ##class(Rugby.Service.Store).Put("Player",p) } }
        for k=0:1:16 { do candidate.attributes.%Set(catalog.%Get(k).id,$select(scenario="salary":78,1:65)) }
        do ##class(Rugby.Service.Store).Put("Player",candidate)
        for cid="c1","c2","c3" {
            set c=##class(Rugby.Service.Store).Get("Club",cid),c.aiSignings=2,c.aiInjurySignings=0,c.aiPromotions=2,players=##class(Rugby.Service.Store).All("Player","clubId",cid)
            for i=0:1:players.%Size()-1 {
                set p=players.%Get(i)
                if p.category'="senior" continue
                set p.weeklyWage=10000
                if (cid'="c1")&&(p.position=13) set p.available=0,p.recoveryDay=c.day+28
                do ##class(Rugby.Service.Store).Put("Player",p)
            }
            do ##class(Rugby.Service.Store).Put("Club",c)
        }
        set fixtures=##class(Rugby.Service.Competition).Fixtures("league-416-2026")
        for i=0:1:fixtures.%Size()-1 {
            set f=fixtures.%Get(i)
            if ((f.homeId="c2")&&(f.awayId="c3"))||((f.homeId="c3")&&(f.awayId="c2")) {
                set f.status="finished",f.homeScore=$select(f.homeId="c3":80,1:0),f.awayScore=$select(f.awayId="c3":80,1:0),f.homeTries=$select(f.homeId="c3":12,1:0),f.awayTries=$select(f.awayId="c3":12,1:0)
                do ##class(Rugby.Service.Store).Put("Fixture",f)
                quit
            }
        }
        set c=##class(Rugby.Service.Store).Get("Club","c1"),pool=##class(Rugby.Service.TransferPool).Refresh(c.day),salary2=##class(Rugby.Service.Payroll).Reference(candidate,"c2"),salary3=##class(Rugby.Service.Payroll).Reference(candidate,"c3")
        if scenario="human" {
            set n=##class(Rugby.Service.Transfers).Open(candidate.id,{"version":(candidate.version)},"best-human-offer"),n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"monthlyWage":200000},"best-human-salary")
            do ..Assert(n.status="agreed","Human salary offer is accepted before competition")
        }
        set result=##class(Rugby.Service.TransferPool).Compete([{"clubId":"c2","medicalOnly":1},{"clubId":"c3","medicalOnly":1}],c.day),p=##class(Rugby.Service.Store).Get("Player",candidate.id)
        if scenario="salary" { do ..Assert((salary2>salary3)&&(p.clubId="c2"),"Higher salary wins even when the other team is better placed") }
        if scenario="position" { do ..Assert((salary2=salary3)&&(p.clubId="c3"),"Equal salaries favour the higher league position") }
        if scenario="human" { do ..Assert(p.clubId="","The best agreed human offer is respected without automatically signing") }
        trollback 1
    }
}
}
