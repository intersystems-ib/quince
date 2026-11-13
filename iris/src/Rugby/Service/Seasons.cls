Class Rugby.Service.Seasons Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Year(club As %String = "") As %Integer
{
    if club="" set club=##class(Rugby.Service.Store).ManagedClub()
    set c=##class(Rugby.Service.Store).Get("Club",club)
    quit c.%Get("seasonYear",##class(Rugby.Service.Competition).Year(c.date))
}
ClassMethod FinalDay(year As %Integer) As %Integer { quit ##class(Rugby.Service.Competition).Nearest((year+1)_"-06-07",0)-$zdateh("2026-11-07",3) }
ClassMethod EndDate(year As %Integer) As %String { quit (year+1)_"-06-30" }
ClassMethod NoticeDay(year As %Integer) As %Integer
{
    set final=$zdate(..FinalDay(year)+$zdateh("2026-11-07",3),3)
    quit $zdateh((year+1)_"-03-"_$piece(final,"-",3),3)-$zdateh("2026-11-07",3)
}
ClassMethod Contract(p As %DynamicObject, year As %Integer)
{
    set p.contractEndDate=..EndDate(year),p.contractStatus="employed"
}
ClassMethod Prepare(p As %DynamicObject)
{
    if (p.clubId'="")&&(p.%Get("contractEndDate")="") do ..Contract(p,..Year(p.clubId))
}
ClassMethod RetirementChance(age As %Integer) As %Integer
{
    quit $select(age<33:0,age=33:10,age=34:20,age=35:35,age=36:50,age=37:70,age=38:85,age=39:95,1:100)
}
ClassMethod Announce(day As %Integer) As %DynamicArray
{
    set year=..Year(),result=[]
    if day<..NoticeDay(year) quit result
    set players=##class(Rugby.Service.Store).All("Player"),final=..FinalDay(year),seed=##class(Rugby.Service.Rivals).Seed()
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.%Get("retirementDecisionYear",-1)=year)||(p.%Get("contractStatus")="retired")||p.%Get("retirementAnnounced",0) continue
        set age=(final-p.birthDay)\365,chance=..RetirementChance(age),p.retirementDecisionYear=year
        if (##class(Rugby.Service.Rivals).Hash(p.id_"-retirement-"_year,seed)#100)<chance {
            do p.%Set("retirementAnnounced",1,"boolean")
            set p.retirementSeasonYear=year,p.retirementAnnouncedDate=$zdate(day+$zdateh("2026-11-07",3),3),p.retirementDate=..EndDate(year),p.retirementClubId=p.clubId
            do result.%Push({"playerId":(p.id),"name":(p.name),"clubId":(p.clubId),"retirementDate":(p.retirementDate)})
        }
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    quit result
}
ClassMethod RenewRival(c As %DynamicObject, day As %Integer) As %DynamicArray
{
    set year=..Year(c.id),changes=[]
    if day<..NoticeDay(year) quit changes
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),seniors=0,seed=##class(Rugby.Service.Rivals).Seed()
    for i=0:1:players.%Size()-1 { if players.%Get(i).category="senior" set seniors=seniors+1 }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if p.%Get("retirementAnnounced",0) continue
        set end=$zdateh(p.contractEndDate,3)-$zdateh("2026-11-07",3)
        if (end<day)||(end>##class(Rugby.Service.SeasonCalendar).CloseDay(year)) continue
        // Spread reviews over three months, keeping decisions reproducible.
        set review=..NoticeDay(year)+(##class(Rugby.Service.Rivals).Hash(p.id_"-renew-"_year,seed)#70)
        if day<review continue
        if p.%Get("renewalReviewYear",-1)=year continue
        set p.renewalReviewYear=year,age=(day-p.birthDay)\365,quality=##class(Rugby.Service.Development).Average(p)
        set keep=$select(p.category="academy":(age<=22)&&(quality>=(40*##class(Rugby.Service.TalentScale).Factor())),p.position<=3:1,seniors<=23:1,1:(age<34)&&(quality>=(50*##class(Rugby.Service.TalentScale).Factor())))
        if keep {
            set wage=(((p.weeklyWage*(102+(quality\20)))+9999)\10000)*100,p.weeklyWage=$select(##class(Rugby.Service.Payroll).CanPay(c.id,p.id,wage):wage,1:p.weeklyWage),wage=p.weeklyWage
            set p.contractYears=##class(Rugby.Service.ContractTerms).Preferred(age,p.id)
            do ..Contract(p,year+p.contractYears)
            set id=c.id_"-renew-"_year_"-"_p.id,contract={"id":(id),"clubId":(c.id),"playerId":(p.id),"kind":"renewal","day":(day),"weeklyWage":(wage),"contractEndDate":(p.contractEndDate),"contractYears":(p.contractYears),"fee":0}
            do ##class(Rugby.Service.Store).Put("PlayerContract",contract),changes.%Push(contract)
        }
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    quit changes
}
ClassMethod Depart(p As %DynamicObject, year As %Integer, retired As %Boolean)
{
    set old=##class(Rugby.Service.Store).ManagedClub(),cid=p.clubId,key="season-"_year_"-"_p.id
    try {
        set %RugbyManagedClub=cid
        set ignored=##class(Rugby.Service.Management).Release(p.id,{"version":(p.version)},key),p=##class(Rugby.Service.Store).Get("Player",p.id),p.contractStatus=$select(retired:"retired",1:"expired"),p.signingFee=0
        if retired { do p.%Set("retired",1,"boolean"),p.%Set("available",0,"boolean") }
        do ##class(Rugby.Service.Store).Put("Player",p)
        set contract=##class(Rugby.Service.Store).Get("PlayerContract",p.id_"-release-"_key),contract.kind=$select(retired:"retirement",1:"expiry")
        do ##class(Rugby.Service.Store).Put("PlayerContract",contract)
    } catch ex { set %RugbyManagedClub=old throw ex }
    set %RugbyManagedClub=old
}
ClassMethod Acquire(c As %DynamicObject, pos As %Integer, year As %Integer, serial As %Integer) As %DynamicObject
{
    set pool=##class(Rugby.Service.TransferPool).Players(),best="",score=-1,roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),seniors=0
    for i=0:1:roster.%Size()-1 { if roster.%Get(i).category="senior" set seniors=seniors+1 }
    set remaining=$select(seniors<23:23-seniors,1:1),room=##class(Rugby.Service.Payroll).WeeklyCap(c.id)-##class(Rugby.Service.Payroll).Used(c.id),offerBudget=(room/remaining)\100*100
    for i=0:1:pool.%Size()-1 {
        set p=pool.%Get(i)
        if ('p.available)||p.%Get("retirementAnnounced",0)||(p.%Get("contractStatus")="retired") continue
        if p.%Get("releasedDay",c.day-1)>=c.day continue
        if (pos>0)&&(p.position'=pos) continue
        set asking=$select(p.%Get("previousWeeklyWage",0)>0:p.previousWeeklyWage,1:p.weeklyWage)
        if ##class(Rugby.Service.Payroll).Active() set asking=##class(Rugby.Service.Payroll).Reference(p,c.id)
        if ##class(Rugby.Service.Payroll).Active()&&(asking>offerBudget) continue
        set value=##class(Rugby.Service.Development).Average(p)
        if value>score set best=p,score=value,bestWage=asking
    }
    if '$isobject(best) {
        set p=##class(Rugby.Seed.Academy).Create(c,$select(pos:pos,1:4),9000+serial),p.id="season-agent-"_year_"-"_c.id_"-"_serial,p.clubId="",p.category="senior",p.age=21,p.birthDay=c.day-(21*365),p.weeklyWage=$select(##class(Rugby.Service.Payroll).Active():$select(offerBudget<##class(Rugby.Service.Payroll).Reference(p,c.id):offerBudget,1:##class(Rugby.Service.Payroll).Reference(p,c.id)),1:45000),p.signingFee=0,best=p,bestWage=p.weeklyWage
    }
    set fee=best.%Get("signingFee",0)
    set best.clubId=c.id,best.category="senior",best.weeklyWage=bestWage,best.signedDay=c.day
    if ##class(Rugby.Service.Payroll).Active() set best.weeklyWage=$select(##class(Rugby.Service.Payroll).CanPay(c.id,best.id,best.weeklyWage):best.weeklyWage,1:##class(Rugby.Service.Payroll).Reference(best,c.id))
    do ##class(Rugby.Service.Payroll).Check(c.id,best.id,best.weeklyWage)
    set best.contractYears=##class(Rugby.Service.ContractTerms).Preferred((c.day-best.birthDay)\365,best.id)
    do ..Contract(best,year+best.contractYears-1),##class(Rugby.Service.Store).Put("Player",best)
    if fee do ##class(Rugby.Service.Management).Money(c,-fee,"transfer","Fichaje de "_best.name,"season-sign-"_year_"-"_serial)
    set contract={"id":("season-sign-"_year_"-"_c.id_"-"_serial),"clubId":(c.id),"playerId":(best.id),"kind":"signing","day":(c.day),"weeklyWage":(best.weeklyWage),"contractEndDate":(best.contractEndDate),"contractYears":(best.contractYears),"fee":(fee)}
    do ##class(Rugby.Service.Store).Put("PlayerContract",contract)
    set pool=##class(Rugby.Service.TransferPool).Refresh(c.day)
    quit contract
}
ClassMethod Replenish(c As %DynamicObject, year As %Integer) As %DynamicArray
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),counts={},total=0,changes=[],serial=0
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if (p.category="senior") { do counts.%Set(p.position,counts.%Get(p.position,0)+1) set total=total+1 } }
    for pos=1:1:15 {
        set needed=$select(pos<=3:2,1:1)-counts.%Get(pos,0)
        for j=1:1:needed { set serial=serial+1,total=total+1 do changes.%Push(..Acquire(c,pos,year,serial)) }
    }
    for j=total:1:22 { set serial=serial+1 do changes.%Push(..Acquire(c,0,year,serial)) }
    do ##class(Rugby.Service.Rivals).Lineup(c)
    quit changes
}
ClassMethod Exchange(year As %Integer, date As %String) As %DynamicObject
{
    set honor=##class(Rugby.Service.Store).Get("Competition","league-416-"_year),elite=##class(Rugby.Service.Store).Get("Competition","league-417-"_year),table=##class(Rugby.Service.Competition).Table(honor),down=table.%Get(table.%Size()-1).clubId,up=elite.championId
    if up="" do ##class(Rugby.Service.Store).Fail(409,"CHAMPION_PENDING","La División Élite debe tener campeón antes del ascenso.")
    set changes=[]
    for cid=down,up {
        set c=##class(Rugby.Service.Store).Get("Club",cid),c.divisionBudgetReference=##class(Rugby.Service.Finance).Budget(c),old=c.competitionId,c.competitionId=$select(cid=up:416,1:417),c.competition=$select(cid=up:"División de Honor",1:"División de Honor Élite"),c.divisionChangedDate=date,c.divisionChangedSeason=year+1,c.previousCompetitionId=old
        do ##class(Rugby.Service.Store).Put("Club",c),changes.%Push({"clubId":(cid),"fromDivisionId":(old),"toDivisionId":(c.competitionId),"reason":($select(cid=up:"champion",1:"lastRegularPlace"))})
        if (cid=##class(Rugby.Service.Store).ManagedClub())&&$data(^RugbyGames(##class(Rugby.Service.Store).Game())) {
            set g=##class(%DynamicObject).%FromJSON(^RugbyGames(##class(Rugby.Service.Store).Game())),g.divisionId=c.competitionId,g.division=c.competition
            set ^RugbyGames(g.id)=g.%ToJSON()
        }
    }
    set honor.relegatedClubId=down,elite.promotedClubId=up
    do ##class(Rugby.Service.Store).Put("Competition",honor),##class(Rugby.Service.Store).Put("Competition",elite)
    quit {"promotedClubId":(up),"relegatedClubId":(down),"changes":(changes)}
}
ClassMethod Tick(day As %Integer) As %DynamicObject
{
    set year=..Year(),game=##class(Rugby.Service.Store).Game(),result={"closed":false,"seasonYear":(year)},last=0,ready=1
    for division=416,417 {
        set comp=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-"_year)
        if comp.phase'="finished" set ready=0
        set fixtures=##class(Rugby.Service.Competition).Fixtures(comp.id)
        for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if f.status'="finished" set ready=0
            if f.day>last set last=f.day }
    }
    set cup=##class(Rugby.Service.Store).Get("Competition","cup-"_year,0)
    if $isobject(cup) { if cup.phase'="finished" set ready=0 }
    if 'ready quit result
    if (day<##class(Rugby.Service.SeasonCalendar).CloseDay(year))||##class(Rugby.Service.Store).Active(##class(Rugby.Service.Store).ManagedClub()) quit result
    if $data(^RugbyWorld(game,"seasonClosures",year)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"seasonClosures",year))
    set clubs=##class(Rugby.Service.Store).All("Club"),players=##class(Rugby.Service.Store).All("Player"),released=[],retired=[],reinforcements=[],date=$zdate(day+$zdateh("2026-11-07",3),3)
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i),paid=##class(Rugby.Service.MonthlyPayroll).Tick(c.id,day) }
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),retiring=p.%Get("retirementAnnounced",0)&&(p.%Get("retirementSeasonYear",-1)<=year)
        if p.clubId="" {
            if retiring { set p.contractStatus="retired",p.weeklyWage=0 do p.%Set("retired",1,"boolean"),p.%Set("available",0,"boolean"),##class(Rugby.Service.Store).Put("Player",p),retired.%Push(p.id) }
            continue
        }
        if retiring||($zdateh(p.contractEndDate,3)<=$zdateh(date,3)) {
            do ..Depart(p,year,retiring)
            if retiring { do retired.%Push(p.id) } else { do released.%Push(p.id) }
        }
    }
    set exchange=..Exchange(year,date),clubs=##class(Rugby.Service.Store).All("Club")
    do ##class(Rugby.Service.Competition).Ensure(year+1)
    for division=416,417 {
        set comp=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-"_year),comp.closedDate=date,comp.nextSeasonYear=year+1
        do ##class(Rugby.Service.Store).Put("Competition",comp)
    }
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),c.seasonYear=year+1,c.season=(year+1)_"/"_(year+2),c.seasonStartDate=(year+1)_"-09-01"
        do ##class(Rugby.Service.Store).Put("Club",c)
        if c.id'=##class(Rugby.Service.Store).ManagedClub() do reinforcements.%Push({"clubId":(c.id),"contracts":(..Replenish(c,year+1))})
    }
    set result={"closed":true,"seasonYear":(year),"closedDate":(date),"nextSeasonYear":(year+1),"nextSeasonStartDate":((year+1)_"-09-01"),"releasedPlayerIds":(released),"retiredPlayerIds":(retired),"reinforcements":(reinforcements),"divisionExchange":(exchange)},^RugbyWorld(game,"seasonClosures",year)=result.%ToJSON()
    quit result
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),result={"gameId":(game),"players":0,"version":(..#VERSION)}
    if $get(^RugbyWorld(game,"seasonsVersion"))=..#VERSION quit result
    set clubs=##class(Rugby.Service.Store).All("Club"),players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),c.seasonYear=##class(Rugby.Service.Competition).Year(c.date),c.seasonStartDate=c.seasonYear_"-09-01"
        do ##class(Rugby.Service.Store).Put("Club",c)
    }
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.clubId'="" { do ..Prepare(p),##class(Rugby.Service.Store).Put("Player",p) set result.players=result.players+1 } }
    set ^RugbyWorld(game,"seasonsVersion")=..#VERSION
    quit result
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando contratos.")
    try {
        tstart
        do reports.%Push(..Initialize())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Initialize()) }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
