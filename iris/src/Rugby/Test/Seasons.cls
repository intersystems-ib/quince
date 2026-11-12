Class Rugby.Test.Seasons Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Complete(year As %Integer)
{
    for division=416,417 {
        set id="league-"_division_"-"_year
        for pass=1:1:3 {
            set fixtures=##class(Rugby.Service.Competition).Fixtures(id)
            for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if f.status'="finished" { set f.status="finished",f.homeScore=20,f.awayScore=10,f.homeTries=4,f.awayTries=1,f.winnerId=f.homeId
                if (division=417)&&(f.stage="final") set f.homeScore=10,f.awayScore=20,f.winnerId=f.awayId
                do ##class(Rugby.Service.Store).Put("Fixture",f) } }
            do ##class(Rugby.Service.Competition).Progress(id)
        }
    }
    do ##class(Rugby.Test.Cup).Complete(year)
}
ClassMethod Run()
{
    set year=##class(Rugby.Service.Seasons).Year(),final=##class(Rugby.Service.Seasons).FinalDay(year),close=final+7,notice=##class(Rugby.Service.Seasons).NoticeDay(year),p=##class(Rugby.Service.Store).Get("Player","c1-p1")
    do ..Assert((p.contractEndDate>=##class(Rugby.Service.Seasons).EndDate(year))&&(p.contractEndDate<=##class(Rugby.Service.Seasons).EndDate(year+3)),"Initial contracts are distributed across the first four season closures")
    // Explicitly expiring fixtures exercise renewals and releases independently of the initial draw.
    for pid="c1-p1","c1-p2","c2-p1" { set p=##class(Rugby.Service.Store).Get("Player",pid),p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year) do ##class(Rugby.Service.Store).Put("Player",p) }
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1")
    set raw=p.attributes.%ToJSON(),energy=p.energy,n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"renew-open","renewal")
    do ..Assert((n.kind="renewal")&&(n.signingFee=0),"Renewal opens a salary negotiation without a signing fee")
    set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"renew-offer"),version=n.version,n=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(version)},"renew-sign"),again=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(version)},"renew-sign"),p=##class(Rugby.Service.Store).Get("Player","c1-p1")
    do ..Assert((p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+n.agreedContractYears))&&(p.attributes.%ToJSON()=raw)&&(p.energy=energy)&&(again.id=n.id),"Renewal extends the negotiated duration, preserving skills and energy and retrying once")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p24"),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"renew-youth","renewal")
    do ..Assert(n.askingWeeklyWage=p.weeklyWage,"Academy renewal uses academy salary, not senior promotion salary")
    set conflict=0
    try { set ignored=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"renew-mixed","promotion") } catch ex { set conflict=ex.Location="NEGOTIATION_OPEN" }
    do ..Assert(conflict,"A pending academy renewal cannot silently become a promotion")
    set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(n.version),"weeklyWage":(n.askingWeeklyWage)},"renew-youth-offer"),n=##class(Rugby.Service.Transfers).Sign(n.id,{"version":(n.version)},"renew-youth-sign"),p=##class(Rugby.Service.Store).Get("Player","c1-p24")
    do ..Assert(p.category="academy","Renewing a youth player never promotes him")
    for pid="c1-p4","c1-p5","c2-p4" { set p=##class(Rugby.Service.Store).Get("Player",pid),p.birthDay=final-(40*365),p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+2) do ##class(Rugby.Service.Store).Put("Player",p) }
    set pending=##class(Rugby.Service.Store).Get("Player","c1-p5"),pending=##class(Rugby.Service.Transfers).Open(pending.id,{"version":(pending.version)},"retire-pending","renewal"),pending=##class(Rugby.Service.Transfers).Offer(pending.id,{"version":(pending.version),"weeklyWage":(pending.askingWeeklyWage)},"retire-pending-offer")
    set early=##class(Rugby.Service.Seasons).Announce(notice-1)
    do ..Assert(early.%Size()=0,"No retirement announcements before the three-month boundary")
    set announcements=##class(Rugby.Service.Seasons).Announce(notice),again=##class(Rugby.Service.Seasons).Announce(notice),p=##class(Rugby.Service.Store).Get("Player","c1-p4"),blocked=0
    do ..Assert(p.retirementAnnounced&&(again.%Size()=0),"Retirements are announced once, deterministically")
    try { set ignored=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"retiring-renew","renewal") } catch ex { set blocked=ex.Location="PLAYER_RETIRING" }
    do ..Assert(blocked,"A player who announced retirement cannot renew")
    set blocked=0
    try { set ignored=##class(Rugby.Service.Transfers).Sign(pending.id,{"version":(pending.version)},"retiring-sign") } catch ex { set blocked=ex.Location="PLAYER_RETIRING" }
    do ..Assert(blocked,"An announcement also blocks a previously agreed renewal")
    do ..Assert((##class(Rugby.Service.Seasons).RetirementChance(32)=0)&&(##class(Rugby.Service.Seasons).RetirementChance(33)>0),"Retirement eligibility starts at thirty-three")
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),c.day=close,c.date=$zdate(close+$zdateh("2026-11-07",3),3)
        do ##class(Rugby.Service.Store).Put("Club",c)
        if c.id'="c1" set renewals=##class(Rugby.Service.Seasons).RenewRival(c,final-1)
    }
    set rival=##class(Rugby.Service.Store).Get("Player","c2-p1")
    do ..Assert(rival.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+rival.contractYears),"Rivals renew their players for the preferred duration before the season closes")
    set before=##class(Rugby.Service.Seasons).Tick(close)
    do ..Assert('before.closed,"An unfinished championship prevents closure")
    do ..Complete(year)
    set early=##class(Rugby.Service.Seasons).Tick(close-1)
    do ..Assert('early.closed,"Season does not close before the full seven days")
    set oldHonor=##class(Rugby.Service.Store).Get("Competition","league-416-"_year),oldElite=##class(Rugby.Service.Store).Get("Competition","league-417-"_year),table=##class(Rugby.Service.Competition).Table(oldHonor),down=table.%Get(9).clubId,up=oldElite.championId
    do ..Assert(up'=oldElite.regularOrder.%Get(0),"Promotion test uses a playoff champion different from the regular winner")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p2"),raw=p.attributes.%ToJSON(),energy=p.energy,beforeFixtures=##class(Rugby.Service.Competition).Fixtures("league-416-"_year).%ToJSON(),result=##class(Rugby.Service.Seasons).Tick(close)
    do ..Assert(result.closed&&(result.nextSeasonStartDate=((year+1)_"-09-01")),"Both divisions close and the next season starts September first")
    do ..Assert((result.divisionExchange.relegatedClubId=down)&&(result.divisionExchange.promotedClubId=up),"Last Honor regular club and Elite playoff champion are exchanged")
    do ..Assert((##class(Rugby.Service.Store).Get("Club",down).competitionId=417)&&(##class(Rugby.Service.Store).Get("Club",up).competitionId=416),"Club division and its lookup are updated before the next draw")
    for division=416,417 { set teams=##class(Rugby.Service.Store).All("Club","competitionId",division) do ..Assert(teams.%Size()=10,"Both divisions retain ten clubs") }
    set newHonor=##class(Rugby.Service.Store).Get("Competition","league-416-"_(year+1)),newElite=##class(Rugby.Service.Store).Get("Competition","league-417-"_(year+1)),seen={}
    for i=0:1:9 { do seen.%Set(newHonor.teamIds.%Get(i),416),seen.%Set(newElite.teamIds.%Get(i),417) }
    do ..Assert((seen.%Get(up)=416)&&(seen.%Get(down)=417),"New calendars include the promoted and relegated clubs in their new league")
    set cupNext=##class(Rugby.Service.Store).Get("Competition","cup-"_(year+1))
    do ..Assert(cupNext.groupDates.%Size()=3,"Next season reserves all Cup dates before generating leagues")
    for division=416,417 { set generated=##class(Rugby.Service.Competition).Fixtures("league-"_division_"-"_(year+1)) for i=0:1:generated.%Size()-1 { do ..Assert('##class(Rugby.Service.Cup).Reserved(year+1,generated.%Get(i).date),"Season closure creates league schedules without Cup collisions") } }
    set p=##class(Rugby.Service.Store).Get("Player","c1-p2"),retired=##class(Rugby.Service.Store).Get("Player","c1-p4"),kept=##class(Rugby.Service.Store).Get("Player","c1-p1")
    do ..Assert((p.clubId="")&&(p.contractStatus="expired")&&(p.attributes.%ToJSON()=raw)&&(p.energy=energy),"Unrenewed player becomes a free agent with unchanged sporting data")
    do ..Assert((retired.contractStatus="retired")&&('retired.available)&&(kept.clubId="c1"),"Retirees leave permanently while renewed players stay")
    set market=##class(Rugby.Service.Transfers).Market()
    for i=0:1:market.%Size()-1 { do ..Assert(market.%Get(i).id'=retired.id,"Retired players cannot appear as free agents") }
    do ..Assert(##class(Rugby.Service.Competition).Fixtures("league-416-"_year).%ToJSON()=beforeFixtures,"Closing preserves historical results and draws")
    for division=416,417 { set comp=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-"_(year+1)),fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id) do ..Assert((comp.seasonStartDate=((year+1)_"-09-01"))&&(fixtures.%Size()=90),"Next division receives exactly ninety regular fixtures") }
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i) if c.id'="c1" { set valid=##class(Rugby.Service.Management).Validate(##class(Rugby.Service.Store).Get("Lineup",c.id_"-default")) do ..Assert(valid.valid,"Rivals replenish retirements and keep a valid first team") } }
    set again=##class(Rugby.Service.Seasons).Tick(close)
    do ..Assert('again.closed,"The next season is not closed again on retry")
    // Complete a second cycle: lifecycle logic must not be limited to the seed year.
    set nextFinal=##class(Rugby.Service.Seasons).FinalDay(year+1),nextClose=nextFinal+7,announcements=##class(Rugby.Service.Seasons).Announce(##class(Rugby.Service.Seasons).NoticeDay(year+1)),clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i),c.day=nextClose,c.date=$zdate(nextClose+$zdateh("2026-11-07",3),3) do ##class(Rugby.Service.Store).Put("Club",c) if c.id'="c1" set renewed=##class(Rugby.Service.Seasons).RenewRival(c,nextFinal-1) }
    do ..Complete(year+1)
    set transition=##class(Rugby.Service.Seasons).Tick(nextClose)
    do ..Assert(transition.closed&&(transition.nextSeasonYear=(year+2)),"A second season closes and generates a third without resetting the world")
}
}
