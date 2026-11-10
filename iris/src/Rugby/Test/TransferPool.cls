Class Rugby.Test.TransferPool Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set market=##class(Rugby.Service.Transfers).Market(),positions={},seen={},low=100,high=0,spanish=0,foreign=0
    do ..Assert(market.%Size()=20,"A new game has exactly twenty shared agents")
    for i=0:1:market.%Size()-1 {
        set p=market.%Get(i),v=##class(Rugby.Service.Development).Average(p)
        do positions.%Set(p.position,1),seen.%Set(p.id,1)
        set low=$select(v<low:v,1:low),high=$select(v>high:v,1:high)
        if p.nationalityCode="ES" { set spanish=spanish+1 } else { set foreign=foreign+1 }
    }
    do ..Assert((positions.%Size()=15)&&(high>=74)&&((high-low)>10)&&spanish&&foreign,"Market covers all positions with varied quality and nationalities")
    set original=##class(Rugby.Service.Store).All("Player").%ToJSON(),clubs=##class(Rugby.Service.Store).All("Club"),own=##class(Rugby.Service.Store).ManagedClub()
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),%RugbyManagedClub=c.id,rows=##class(Rugby.Service.Transfers).Market()
        do ..Assert(rows.%Size()<=20,"Every club sees the same capped market")
        for j=0:1:rows.%Size()-1 { do ..Assert(seen.%IsDefined(rows.%Get(j).id),"Both divisions compete for the same player identities") }
    }
    set %RugbyManagedClub=own,report=##class(Rugby.Service.TransferPool).Initialize()
    do ..Assert((report.improvements.%Size()=0)&&(##class(Rugby.Service.Store).All("Player").%ToJSON()=original),"Market adoption never repeatedly improves players")
    set c=##class(Rugby.Service.Store).Get("Club","c2"),normal=##class(Rugby.Service.Payroll).WeeklyCap(c.id),medical=##class(Rugby.Service.Payroll).MedicalWeeklyCap(c.id),totals=##class(Rugby.Service.MonthlyPayroll).Totals(c.id),budget=##class(Rugby.Service.Finance).Budget(c),director=$select(totals.director>0:totals.director,1:##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(35,c.id)),cost=(medical*52)+((totals.staff+director)*12)+(budget*.03)+1650000
    do ..Assert((medical>normal)&&(cost<=(budget*.9)),"Medical cover releases only a bounded reserve and retains ten percent of the budget")
    set contracts=##class(Rugby.Service.Store).All("PlayerContract").%Size(),signed={}
    for cid="c2","c12" {
        set c=##class(Rugby.Service.Store).Get("Club",cid),c.aiSignings=2,c.aiInjurySignings=0,c.aiPromotions=2,players=##class(Rugby.Service.Store).All("Player","clubId",cid),injured=""
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if p.category'="senior" continue
            set p.weeklyWage=10000
            if p.position=13 { set p.available=0,p.recoveryDay=c.day+28,injured=p.id }
            do ##class(Rugby.Service.Store).Put("Player",p)
        }
        do ##class(Rugby.Service.Store).Put("Club",c)
        set balance=c.balance,result=##class(Rugby.Service.Rivals).Recruit(c,c.day,1)
        do ..Assert(result.signed&&(result.reason="injuryCover")&&(result.replacementForPlayerId=injured),"Honor and Elite sign injury cover outside the regular signing quota: "_cid_" "_result.%ToJSON())
        do ..Assert('signed.%IsDefined(result.playerId),"A shared free agent cannot join two clubs")
        do signed.%Set(result.playerId,1)
        set p=##class(Rugby.Service.Store).Get("Player",result.playerId),stored=##class(Rugby.Service.Store).Get("Club",cid),contract=##class(Rugby.Service.Store).Get("PlayerContract",cid_"-sign-"_c.day)
        do ..Assert((p.clubId=cid)&&(p.signedDay=c.day)&&(p.monthlyWage=contract.monthlyWage)&&(contract.reason="injuryCover")&&(stored.balance=(balance-result.fee)),"Medical signing persists ownership, monthly pay and its exact fee")
        do ..Assert((stored.aiSignings=2)&&(stored.aiInjurySignings=1)&&('##class(Rugby.Service.TransferPool).Contains(p.id)),"Medical signings have a separate limit and leave the market")
        set retry=##class(Rugby.Service.Rivals).Recruit(stored,c.day,1)
        do ..Assert('retry.signed,"A second review cannot sign twice for the same day")
        do ##class(Rugby.Service.Rivals).Lineup(stored)
        do ..Assert(##class(Rugby.Service.Management).Validate(##class(Rugby.Service.Store).Get("Lineup",cid_"-default")).valid,"The revised rival lineup remains legal")
    }
    do ..Assert(##class(Rugby.Service.Store).All("PlayerContract").%Size()=(contracts+2),"Each medical purchase creates exactly one contract")
    set rows=##class(Rugby.Service.Transfers).Market()
    do ..Assert(rows.%Size()<=20,"Signing and refreshing never exceed twenty available players")
}
}
