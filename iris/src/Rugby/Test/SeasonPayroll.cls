Class Rugby.Test.SeasonPayroll Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Complete(year As %Integer)
{
    for division=416,417,1401,1402 {
        set id="league-"_division_"-"_year
        for pass=1:1:4 {
            set fixtures=##class(Rugby.Service.Competition).Fixtures(id)
            for i=0:1:fixtures.%Size()-1 {
                set f=fixtures.%Get(i)
                if f.status="finished" continue
                set f.status="finished",f.homeScore=20,f.awayScore=10,f.homeTries=3,f.awayTries=1,f.winnerId=f.homeId
                do ##class(Rugby.Service.Store).Put("Fixture",f)
            }
            do ##class(Rugby.Service.Competition).Progress(id)
        }
    }
    do ##class(Rugby.Test.Cup).Complete(year)
    set access=##class(Rugby.Service.AccessMatch).Ensure(year),access.status="finished",access.homeScore=20,access.awayScore=10,access.winnerId=access.homeId
    do ##class(Rugby.Service.Store).Put("Fixture",access)
}
ClassMethod Run()
{
    set year=##class(Rugby.Service.Seasons).Year(),c=##class(Rugby.Service.Store).Get("Club","c2"),l=##class(Rugby.Service.Store).Get("Lineup","c2-default"),keep={}
    for i=0:1:13 { do keep.%Set(l.slots.%Get(i).playerId,1) }
    set roster=##class(Rugby.Service.Store).All("Player","clubId",c.id)
    for i=0:1:roster.%Size()-1 {
        set p=roster.%Get(i)
        if (p.category="senior")&&('keep.%IsDefined(p.id)) { set p.clubId="",p.contractStatus="freeAgent" do ##class(Rugby.Service.Store).Put("Player",p) }
    }
    set p=##class(Rugby.Service.Store).Get("Player",l.slots.%Get(0).playerId),p.weeklyWage=100000000,p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage)
    do ##class(Rugby.Service.Store).Put("Player",p)
    set payroll=##class(Rugby.Service.Payroll).Used(c.id),cap=##class(Rugby.Service.Payroll).WeeklyCap(c.id),contracts=##class(Rugby.Service.Store).All("PlayerContract").%Size()
    do ..Assert(payroll>cap,"Reproduction has negative salary room")
    set unavailable=##class(Rugby.Service.Seasons).Acquire(c,15,year+1,99)
    do ..Assert(('$isobject(unavailable))&&(##class(Rugby.Service.Payroll).Used(c.id)=payroll)&&(##class(Rugby.Service.Store).All("PlayerContract").%Size()=contracts),"An over-budget automatic signing is skipped without negative wages or side effects")
    set changes=##class(Rugby.Service.Seasons).Replenish(c,year+1),lineup=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),valid=##class(Rugby.Service.Management).Validate(lineup)
    do ..Assert((changes.%Size()=9)&&valid.valid&&(lineup.bench.%Size()=8),"A short AI squad fills the XV and bench from its contracted academy")
    do ..Assert(##class(Rugby.Service.Payroll).Used(c.id)=payroll,"Emergency youth cover adds no payroll cost")
    for i=0:1:changes.%Size()-1 {
        set a=changes.%Get(i),p=##class(Rugby.Service.Store).Get("Player",a.playerId)
        do ..Assert((a.kind="promotion")&&(a.source="seasonCoverage")&&(p.weeklyWage=a.weeklyWage)&&(p.contractEndDate=a.contractEndDate)&&(p.weeklyWage>0),"Promotions retain their existing wages and contract duration")
    }
    set contracts=##class(Rugby.Service.Store).All("PlayerContract").%Size(),again=##class(Rugby.Service.Seasons).Replenish(c,year+1)
    do ..Assert((again.%Size()=0)&&(##class(Rugby.Service.Store).All("PlayerContract").%Size()=contracts),"Retrying completed coverage creates no extra contracts")
    set c=##class(Rugby.Service.Store).Get("Club","c3"),players=##class(Rugby.Service.Store).All("Player","clubId",c.id)
    for i=0:1:players.%Size()-1 { set p=players.%Get(i),p.weeklyWage=100,p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(100) do ##class(Rugby.Service.Store).Put("Player",p) }
    set p=players.%Get(0),p.weeklyWage=100+##class(Rugby.Service.Payroll).WeeklyCap(c.id)-##class(Rugby.Service.Payroll).Used(c.id)-100,p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage)
    do ##class(Rugby.Service.Store).Put("Player",p)
    set tooSmall=##class(Rugby.Service.Seasons).Acquire(c,4,year+1,98)
    do ..Assert('$isobject(tooSmall),"Tiny remaining room does not create an artificially underpaid senior player")
    set p.weeklyWage=100,p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(100)
    do ##class(Rugby.Service.Store).Put("Player",p)
    set signed=##class(Rugby.Service.Seasons).Acquire(c,4,year+1,1)
    do ..Assert($isobject(signed)&&(signed.weeklyWage>0)&&(##class(Rugby.Service.Payroll).Used(c.id)<=##class(Rugby.Service.Payroll).WeeklyCap(c.id)),"Affordable recruitment still respects the actual salary cap")
    set close=##class(Rugby.Service.SeasonCalendar).CloseDay(year),clubs=##class(Rugby.Service.Store).All("Club"),players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.clubId'="" { do ##class(Rugby.Service.Seasons).Contract(p,year+3),##class(Rugby.Service.Store).Put("Player",p) } }
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),c.day=close,c.date=##class(Rugby.Service.Injuries).Date(close)
        do ##class(Rugby.Service.Store).Put("Club",c)
        set state=##class(%DynamicObject).%FromJSON(^RugbyWorld(##class(Rugby.Service.Store).Game(),"monthlyPayroll",c.id)),state.lastDay=close,^RugbyWorld(##class(Rugby.Service.Store).Game(),"monthlyPayroll",c.id)=state.%ToJSON()
    }
    do ..Complete(year)
    set result=##class(Rugby.Service.Seasons).Tick(close)
    do ..Assert(result.closed&&(result.nextSeasonYear=(year+1)),"Season closure succeeds with an AI club above its salary cap")
    set c=##class(Rugby.Service.Store).Get("Club","c2"),valid=##class(Rugby.Service.Management).Validate(##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"))
    do ..Assert(valid.valid,"The over-budget club remains playable after the rollover")
}
}
