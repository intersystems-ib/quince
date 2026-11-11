Class Rugby.Service.Rivals Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod InitializeAll()
{
    set previousGame=##class(Rugby.Service.Store).Game(),previousClub=##class(Rugby.Service.Store).ManagedClub()
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Inicialización de rivales en curso.")
    try {
        tstart
        do ..Initialize()
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do ..Initialize() }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
    lock -^RugbyWrite
}
ClassMethod Hash(text As %String, seed As %Integer = 17341) As %Integer
{
    set h=seed
    for i=1:1:$length(text) { set h=((h*31)+$ascii(text,i))#2147483647 }
    quit h
}
ClassMethod Seed() As %Integer
{
    set g=##class(Rugby.Service.Store).Game()
    if '$data(^RugbyWorld(g,"rivalsSeed")) {
        set leagues=##class(Rugby.Service.Store).All("Competition"),seed=17341
        for i=0:1:leagues.%Size()-1 { set league=leagues.%Get(i),seed=..Hash(league.id,1+((seed+league.drawSeed)#2147483646)) }
        set ^RugbyWorld(g,"rivalsSeed")=seed
    }
    quit ^RugbyWorld(g,"rivalsSeed")
}
ClassMethod Initialize()
{
    if $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"rivalsVersion"))=..#VERSION quit
    set own=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),clubs=##class(Rugby.Service.Store).All("Club"),seed=..Seed()
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if c.id=own.id continue
        // Adopt the current date without granting historical development or charging back wages.
        set c.day=own.day,c.date=own.date,c.aiLastDay=own.day,c.aiAdoptedDay=own.day,c.aiSeason="",c.aiSignings=0,c.aiPromotions=0
        do ##class(Rugby.Service.Store).Put("Club",c)
        set plan=..Plan(c,own.day)
    }
    do ..Market(##class(Rugby.Service.Competition).Year(own.date))
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"rivalsVersion")=..#VERSION
}
ClassMethod Market(year As %Integer)
{
    do ##class(Rugby.Service.Transfers).SeedMarket(year)
}

ClassMethod Focus(p As %DynamicObject, day As %Integer, seed As %Integer) As %String
{
    set catalog=##class(Rugby.Service.Development).Catalog(),best=-1,focus="strength",general=(..Hash(p.id_"-"_day,seed)#7)=0
    for i=0:1:16 {
        set attr=catalog.%Get(i).id,weight=1
        if 'general {
            if p.position<=8 { set weight=$select($listfind($listbuild("strength","scrum","lineout","ruck","maul"),attr):1.8,$listfind($listbuild("tackling","stamina","defensiveReading"),attr):1.3,1:.65) }
            else { set weight=$select($listfind($listbuild("speed","agility","passing","handling"),attr):1.8,$listfind($listbuild("kicking","decisions","attacking","tackling"),attr):1.3,1:.65) }
        }
        set score=((100-p.attributes.%Get(attr))*weight)+((..Hash(p.id_"-"_day_"-"_attr,seed)#100)/20)
        if score>best set best=score,focus=attr
    }
    quit focus
}
ClassMethod MatchNear(club As %String, day As %Integer) As %Boolean
{
    set fixtures=##class(Rugby.Service.Competition).ClubFixtures(club),near=0
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if (f.day>=day)&&(f.day<=(day+1))&&(f.status'="finished") set near=1 }
    quit near
}
ClassMethod Plan(c As %DynamicObject, day As %Integer) As %DynamicObject
{
    set old=##class(Rugby.Service.Store).Get("TrainingPlan",c.id),players=##class(Rugby.Service.Store).All("Player","clubId",c.id),groups=[],buckets={},seed=..Seed(),weekday=($zdateh("2026-11-07",3)+day+4)#7,near=..MatchNear(c.id,day)
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),focus="recovery",intensity="low"
        if p.available&&(p.energy>=65)&&(weekday'=0)&&(weekday'=6)&&((p.category="academy")||('near)) {
            set focus=..Focus(p,day,seed),intensity=$select((p.energy>=85)&&((..Hash(p.id_"-"_day,seed)#3)=0):"high",1:"normal")
        }
        set key=focus_"-"_intensity
        if 'buckets.%IsDefined(key) { set t=##class(Rugby.Service.Development).Type(focus),g={"id":("ai-"_key),"name":(t.name),"focus":(focus),"intensity":(intensity),"playerIds":[]} do buckets.%Set(key,g),groups.%Push(g) }
        do buckets.%Get(key).playerIds.%Push(p.id)
    }
    quit ##class(Rugby.Service.Development).SavePlan(c.id,{"version":(old.version),"groups":(groups)})
}
ClassMethod Coach(c As %DynamicObject, day As %Integer) As %DynamicObject
{
    set staff=##class(Rugby.Service.Staff).View(c.id),worst="",score=-1
    for i=0:1:staff.coaches.%Size()-1 {
        set coach=staff.coaches.%Get(i),priority=(100-coach.quality)*$select(coach.role="academy":1.3,coach.role="fitness":1.2,coach.role="head":1.1,1:1)
        if priority>score set worst=coach,score=priority
    }
    if (worst.quality>=75)||(c.balance<(staff.weeklyWage*8)) quit {"hired":false}
    set market=##class(Rugby.Service.Store).All("Coach","clubId",""),candidate="",best=-1
    for i=0:1:market.%Size()-1 {
        set coach=market.%Get(i)
        if (coach.role'=worst.role)||(coach.quality<(worst.quality+2))||(coach.quality>(worst.quality+8)) continue
        set value=(coach.quality-worst.quality)/(1+coach.weeklyWage)
        if value>best set candidate=coach,best=value
    }
    if '$isobject(candidate) {
        set quality=worst.quality+2+(..Hash(c.id_"-"_day,..Seed())#4),id="ai-coach-"_c.id_"-"_day
        set candidate={"id":(id),"clubId":"","name":(##class(Rugby.Seed.StaffNames).Generate(id)),"generatedNameVersion":"1.0.0","role":(worst.role),"quality":(quality),"weeklyWage":(##class(Rugby.Service.Staff).Salary(worst.role,quality)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(quality)),"status":"available"}
        do ##class(Rugby.Service.Store).Put("Coach",candidate)
    }
    if '##class(Rugby.Service.MonthlyPayroll).CanHire(c.id,candidate.role,##class(Rugby.Service.MonthlyPayroll).StaffMonthly(candidate.role,candidate.quality,c.id)) quit {"hired":false,"reason":"payrollLimit"}
    set assigned=##class(Rugby.Service.Staff).Assign(c.id,candidate.id,"ai-staff-"_day)
    quit {"hired":true,"coachId":(candidate.id),"role":(candidate.role),"beforeQuality":(worst.quality),"quality":(candidate.quality),"weeklyWage":(candidate.weeklyWage)}
}
ClassMethod InjuryNeed(c As %DynamicObject, day As %Integer) As %DynamicObject
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),healthy={},covered={},need={"position":0},best=-1
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.category'="senior")||('p.available) continue
        do healthy.%Set(p.position,healthy.%Get(p.position,0)+1)
        if p.%Get("injuryCoverForPlayerId")'="" do covered.%Set(p.injuryCoverForPlayerId,1)
    }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),days=p.%Get("recoveryDay",0)-day,count=healthy.%Get(p.position,0)
        if (p.category'="senior")||p.available||(days<=0)||(count>=2)||covered.%IsDefined(p.id) continue
        if (days<14)&&(count>0) continue
        set priority=$select(count=0:1000,1:100)+days+##class(Rugby.Service.Development).Average(p)
        if priority>best set best=priority,need={"position":(p.position),"playerId":(p.id),"remainingDays":(days),"healthySpecialists":(count)}
    }
    quit need
}
ClassMethod Recruit(c As %DynamicObject, day As %Integer, medicalOnly As %Boolean = 0, proposeOnly As %Boolean = 0, excluded As %DynamicObject = "") As %DynamicObject
{
    if $isobject(##class(Rugby.Service.Store).Get("PlayerContract",c.id_"-sign-"_day,0)) quit {"signed":false,"reason":"dailySigningComplete"}
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),weakest="",weak=101,count=0,need=..InjuryNeed(c,day),medical=need.position>0
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.category="senior" { set count=count+1,v=##class(Rugby.Service.Development).Average(p) if v<weak set weakest=p,weak=v } }
    if ('$isobject(weakest))||(medicalOnly&&('medical)) quit {"signed":false}
    if (count>=$select(medical:30,1:28)) quit {"signed":false,"reason":"rosterLimit"}
    if medical {
        if c.%Get("aiInjurySignings",0)>=6 quit {"signed":false,"reason":"medicalSigningLimit"}
    } else {
        set youth="",best=weak-1
        if c.aiPromotions<2 {
            for i=0:1:players.%Size()-1 { set p=players.%Get(i),v=##class(Rugby.Service.Development).Average(p) if (p.category="academy")&&p.available&&(p.age>=18)&&(p.age<=22)&&(p.position=weakest.position)&&(v>best) set youth=p,best=v }
        }
        if $isobject(youth)&&##class(Rugby.Service.Payroll).CanPay(c.id,youth.id,youth.%Get("seniorWeeklyWage",45000)) {
            set youth.category="senior",youth.weeklyWage=youth.%Get("seniorWeeklyWage",45000),c.aiPromotions=c.aiPromotions+1
            do ##class(Rugby.Service.Store).Put("Player",youth)
            do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":(c.id_"-promote-"_day),"clubId":(c.id),"playerId":(youth.id),"kind":"promotion","day":(day),"weeklyWage":(youth.weeklyWage),"monthlyWage":(youth.monthlyWage),"payPeriod":"monthly","fee":0})
            quit {"signed":false,"promotedId":(youth.id),"position":(youth.position),"monthlyWage":(youth.monthlyWage)}
        }
        if c.aiSignings>=2 quit {"signed":false,"reason":"regularSigningLimit"}
    }
    if c.balance<$select(medical:500000,1:5000000) quit {"signed":false,"reason":"cashReserve"}
    set used=##class(Rugby.Service.Payroll).Used(c.id),wageCap=$select(medical:##class(Rugby.Service.Payroll).MedicalWeeklyCap(c.id),1:##class(Rugby.Service.Payroll).WeeklyCap(c.id))
    set free=##class(Rugby.Service.TransferPool).Players(),candidate="",best=-1,pos=$select(medical:need.position,1:weakest.position),minimum=$select(medical:$select(need.healthySpecialists=0:($select(c.competitionId=416:58,1:50)*##class(Rugby.Service.TalentScale).Factor()),weak>(62*##class(Rugby.Service.TalentScale).Factor()):weak-(12*##class(Rugby.Service.TalentScale).Factor()),1:(50*##class(Rugby.Service.TalentScale).Factor())),1:weak+1)
    for i=0:1:free.%Size()-1 {
        set p=free.%Get(i)
        if $isobject(excluded)&&excluded.%IsDefined(p.id) continue
        set age=(day-p.birthDay)\365,v=##class(Rugby.Service.Development).Average(p),fee=p.%Get("signingFee",0),fit=$select(p.position=pos:1,medical&&((p.position<=8)=(pos<=8)):.85,1:0)
        if (fit=0)||((v*fit)<minimum)||(age>$select(medical:36,1:32))||(fee>(c.balance/8)) continue
        set wage=##class(Rugby.Service.Payroll).Reference(p,c.id),monthly=##class(Rugby.Service.Payroll).Monthly(wage)
        if ((used+wage)>wageCap)||(c.balance<(fee+(monthly*2))) continue
        set value=((v*fit-minimum+10)*100000)/(wage+1)
        if value>best set candidate=p,best=value,bestWage=wage
    }
    if '$isobject(candidate) quit {"signed":false,"reason":"noAffordableCandidate","medicalNeed":(need),"minimum":(minimum),"candidateCount":(free.%Size())}
    set proposal={"clubId":(c.id),"playerId":(candidate.id),"playerVersion":(candidate.version),"weeklyWage":(bestWage),"monthlyWage":(##class(Rugby.Service.Payroll).Monthly(bestWage)),"medical":(medical),"medicalNeed":(need)}
    if proposeOnly quit {"signed":false,"proposal":(proposal)}
    quit ..AcceptRecruitment(c,proposal,day)
}
ClassMethod AcceptRecruitment(c As %DynamicObject, proposal As %DynamicObject, day As %Integer) As %DynamicObject
{
    set candidate=##class(Rugby.Service.Store).Get("Player",proposal.playerId),medical=proposal.medical,need=proposal.medicalNeed,bestWage=proposal.weeklyWage
    if (candidate.clubId'="")||('candidate.available)||(candidate.version'=proposal.playerVersion) quit {"signed":false,"reason":"candidateTaken"}
    if $isobject(##class(Rugby.Service.Store).Get("PlayerContract",c.id_"-sign-"_day,0)) quit {"signed":false,"reason":"dailySigningComplete"}
    if '$select(medical:##class(Rugby.Service.Payroll).CanPayMedical(c.id,candidate.id,bestWage),1:##class(Rugby.Service.Payroll).CanPay(c.id,candidate.id,bestWage)) quit {"signed":false,"reason":"payrollLimit"}
    if c.balance<(candidate.%Get("signingFee",0)+(proposal.monthlyWage*2)) quit {"signed":false,"reason":"cashReserve"}
    set fee=candidate.%Get("signingFee",0),candidate.clubId=c.id,candidate.category="senior",candidate.contractStatus="employed",candidate.weeklyWage=bestWage,candidate.monthlyWage=##class(Rugby.Service.Payroll).Monthly(bestWage),candidate.signedDay=day,candidate.payrollStartDay=day
    if medical { set candidate.injuryCoverForPlayerId=need.playerId,c.aiInjurySignings=c.%Get("aiInjurySignings",0)+1 }
    else { set c.aiSignings=c.aiSignings+1 do candidate.%Remove("injuryCoverForPlayerId") }
    do ##class(Rugby.Service.Seasons).Contract(candidate,##class(Rugby.Service.Seasons).Year(c.id)),##class(Rugby.Service.Store).Put("Player",candidate)
    do ##class(Rugby.Service.Management).Money(c,-fee,"transfer","Fichaje de "_candidate.name,"ai-sign-"_day)
    set reason=$select(medical:"injuryCover",1:"squadImprovement"),contract={"id":(c.id_"-sign-"_day),"clubId":(c.id),"playerId":(candidate.id),"kind":"signing","reason":(reason),"replacementForPlayerId":(need.%Get("playerId")),"day":(day),"weeklyWage":(candidate.weeklyWage),"monthlyWage":(candidate.monthlyWage),"payPeriod":"monthly","contractEndDate":(candidate.contractEndDate),"fee":(fee)}
    do ##class(Rugby.Service.Store).Put("PlayerContract",contract)
    set pool=##class(Rugby.Service.TransferPool).Refresh(day)
    quit {"signed":true,"reason":(reason),"replacementForPlayerId":(need.%Get("playerId")),"playerId":(candidate.id),"position":(candidate.position),"average":(##class(Rugby.Service.Development).Average(candidate)),"fee":(fee),"weeklyWage":(candidate.weeklyWage),"monthlyWage":(candidate.monthlyWage),"contract":(contract)}
}
ClassMethod Academy(c As %DynamicObject, day As %Integer) As %DynamicObject
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),count=0,coverage={},serial=c.%Get("aiAcademySerial",1000),added=0,departed=[],promoted=[],seniors=0
    for i=0:1:players.%Size()-1 { if players.%Get(i).category="senior" set seniors=seniors+1 }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if p.category'="academy" continue
        set age=(day-p.birthDay)\365,p.age=age
        if age>=23 {
            set weakest=101
            for j=0:1:players.%Size()-1 { set other=players.%Get(j) if (other.category="senior")&&(other.position=p.position) { set v=##class(Rugby.Service.Development).Average(other) if v<weakest set weakest=v } }
            if (seniors<28)&&(c.aiPromotions<2)&&(##class(Rugby.Service.Development).Average(p)>weakest)&&##class(Rugby.Service.Payroll).CanPay(c.id,p.id,p.%Get("seniorWeeklyWage",45000)) {
                set p.category="senior",p.weeklyWage=p.%Get("seniorWeeklyWage",45000),c.aiPromotions=c.aiPromotions+1,seniors=seniors+1
                do promoted.%Push(p.id),##class(Rugby.Service.Store).Put("Player",p)
                do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":(c.id_"-graduate-"_p.id_"-"_day),"clubId":(c.id),"playerId":(p.id),"kind":"promotion","day":(day),"weeklyWage":(p.weeklyWage),"fee":0})
            } else {
                set p.formerClubId=c.id,p.previousWeeklyWage=p.weeklyWage,p.clubId="",p.weeklyWage=0,p.contractStatus="released",p.releasedDay=day,p.signingFee=0
                do departed.%Push(p.id),##class(Rugby.Service.Store).Put("Player",p)
                do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":(c.id_"-graduate-"_p.id_"-"_day),"clubId":(c.id),"playerId":(p.id),"kind":"release","reason":"academyGraduation","day":(day),"fee":0})
            }
            continue
        }
        set count=count+1
        do coverage.%Set(p.position,1)
    }
    for pos=1:1:15 {
        if coverage.%IsDefined(pos)&&(count>=20) continue
        set serial=serial+1,p=##class(Rugby.Seed.Academy).Create(c,pos,serial),added=added+1,count=count+1
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    for { quit:count>=20  set serial=serial+1,p=##class(Rugby.Seed.Academy).Create(c,1+(serial#15),serial),count=count+1,added=added+1 do ##class(Rugby.Service.Store).Put("Player",p) }
    set c.aiAcademySerial=serial
    quit {"added":(added),"departed":(departed),"promoted":(promoted)}
}
ClassMethod Surplus(c As %DynamicObject, day As %Integer) As %String
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),count=0,coverage={},selected={},lineup=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),candidate="",worst=999
    for i=0:1:lineup.slots.%Size()-1 { do selected.%Set(lineup.slots.%Get(i).playerId,1) }
    for i=0:1:lineup.bench.%Size()-1 { do selected.%Set(lineup.bench.%Get(i),1) }
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.category="senior" { set count=count+1 do coverage.%Set(p.position,coverage.%Get(p.position,0)+1) } }
    if count<=25 quit ""
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.category'="senior")||selected.%IsDefined(p.id)||(coverage.%Get(p.position)<=$select(p.position<=3:2,1:1)) continue
        if 'p.available continue
        if p.%Get("injuryCoverForPlayerId")'="" { set original=##class(Rugby.Service.Store).Get("Player",p.injuryCoverForPlayerId,0) if $isobject(original)&&(original.clubId=c.id)&&('original.available) continue }
        set value=##class(Rugby.Service.Development).Average(p)-($select(p.age>32:(p.age-32)*2,1:0))
        if value<worst set candidate=p,worst=value
    }
    if '$isobject(candidate) quit ""
    set candidate.formerClubId=c.id,candidate.previousWeeklyWage=candidate.weeklyWage,candidate.clubId="",candidate.weeklyWage=0,candidate.releasedDay=day,candidate.contractStatus="released",candidate.signingFee=0
    do ##class(Rugby.Service.Seasons).Contract(candidate,##class(Rugby.Service.Seasons).Year(c.id))
    do ##class(Rugby.Service.Store).Put("Player",candidate)
    do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":(c.id_"-ai-release-"_day),"clubId":(c.id),"playerId":(candidate.id),"kind":"release","day":(day),"fee":0})
    quit candidate.id
}
ClassMethod Rating(p As %DynamicObject, pos As %Integer) As %Numeric
{
    set fit=$select(p.position=pos:1,(p.position<=8)=(pos<=8):.85,1:.6)
    quit ##class(Rugby.Service.Development).Average(p)*fit*(.6+(.4*p.energy/100))
}
ClassMethod Pick(players As %DynamicArray, used As %DynamicObject, pos As %Integer, specialist As %Boolean = 0) As %String
{
    set id="",best=-1
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.category'="senior")||('p.available)||used.%IsDefined(p.id) continue
        if specialist&&(p.position'=pos) continue
        set value=..Rating(p,pos)
        if value>best set best=value,id=p.id
    }
    quit id
}
ClassMethod Lineup(c As %DynamicObject)
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",c.id),l=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),slots=[],bench=[],used={}
    for pos=1:1:15 {
        set id=..Pick(players,used,pos,1)
        if id="" set id=..Pick(players,used,pos)
        if id="" do ##class(Rugby.Service.Store).Fail(409,"AI_LINEUP","El rival no dispone de jugadores suficientes para el puesto "_pos)
        do used.%Set(id,1),slots.%Push({"position":(pos),"playerId":(id)})
    }
    for pos=1:1:3 { set id=..Pick(players,used,pos,1) if id'="" { do used.%Set(id,1),bench.%Push(id) } }
    set maxBench=$select(bench.%Size()=3:8,1:7)
    for pos=4,8,9,10,15 { quit:bench.%Size()>=maxBench  set id=..Pick(players,used,pos) if id'="" { do used.%Set(id,1),bench.%Push(id) } }
    set l.slots=slots,l.bench=bench,l.captainId=slots.%Get(8).playerId,l.tactic={"style":"balanced","tempo":"normal","defense":"normal"},valid=##class(Rugby.Service.Management).Validate(l)
    if 'valid.valid do ##class(Rugby.Service.Store).Fail(409,"AI_LINEUP",valid.errors.%ToJSON())
    do ##class(Rugby.Service.Store).Put("Lineup",l)
    for i=0:1:14 { set slot=slots.%Get(i),slot.id=l.id_"-"_(i+1),slot.clubId=c.id do ##class(Rugby.Service.Store).Put("LineupSlot",slot) }
}
ClassMethod Day(day As %Integer) As %DynamicObject
{
    do ..Initialize()
    set eid="rivals-day-"_day,old=##class(Rugby.Service.Store).Get("RivalExecution",eid,0)
    if $isobject(old) quit old
    set own=##class(Rugby.Service.Store).ManagedClub(),clubs=##class(Rugby.Service.Store).All("Club"),date=$zdate($zdateh("2026-11-07",3)+day,3),year=##class(Rugby.Service.Seasons).Year(),order={},report=[]
    do ..Market(year),##class(Rugby.Service.Transfers).SeedMarket(year)
    set free=##class(Rugby.Service.Store).All("Player","clubId","")
    for i=0:1:free.%Size()-1 { set p=free.%Get(i) if ##class(Rugby.Service.Injuries).Recover(p,day) do ##class(Rugby.Service.Store).Put("Player",p) }
    set marketPool=##class(Rugby.Service.TransferPool).Refresh(day)
    // Rotate the market priority deterministically so catalog order gives no permanent advantage.
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if c.id=own continue
        set need=..InjuryNeed(c,day),priority=..Hash("market-"_c.id,..Hash(day,..Seed()))
        if need.position>0 set priority=priority-2147483647
        set order(priority,c.id)=c
    }
    set priority=""
    for {
        set priority=$order(order(priority))
        quit:priority=""
        set cid=""
        for {
            set cid=$order(order(priority,cid))
            quit:cid=""
            set c=##class(Rugby.Service.Store).Get("Club",cid)
            if c.%Get("aiLastDay",day-1)>=day continue
            set payroll=##class(Rugby.Service.MonthlyPayroll).Tick(cid,c.day),c=##class(Rugby.Service.Store).Get("Club",cid)
            set c.day=day,c.date=date
            if c.%Get("aiSeason")'=year set c.aiSeason=year,c.aiSignings=0,c.aiPromotions=0,c.aiInjurySignings=0
            do ##class(Rugby.Service.Store).Put("Club",c)
            set renewals=##class(Rugby.Service.Seasons).RenewRival(c,day)
            set review=((day-c.aiAdoptedDay)=1)||(((day-c.aiAdoptedDay+(+$extract(cid,2,*)))#28)=0),staff={},recruit={},released=""
            if review { set released=..Surplus(c,day),staff=..Coach(c,day) }
            set intake=..Academy(c,day)
            do ##class(Rugby.Service.Store).Put("Club",c)
            do report.%Push({"clubId":(cid),"day":(day),"medicalOnly":('review),"monthlyPayroll":(payroll),"staff":(staff),"renewals":(renewals),"releasedPlayerId":(released),"academyIntake":(intake.added),"academyDepartures":(intake.departed),"academyPromotions":(intake.promoted)})
        }
    }
    set auction=##class(Rugby.Service.TransferPool).Compete(report,day)
    for i=0:1:report.%Size()-1 {
        set r=report.%Get(i),c=##class(Rugby.Service.Store).Get("Club",r.clubId),r.recruitment=auction.results.%Get(c.id,{"signed":false}),plan=..Plan(c,day),execution=##class(Rugby.Service.Development).Process(c.id,day),c.aiLastDay=day
        do ##class(Rugby.Service.Store).Put("Club",c),..Lineup(c)
        set r.trainingExecutionId=execution.id,r.trainingCost=execution.trainingCost,r.playersTrained=execution.results.%Size(),r.results=execution.results
    }
    do ##class(Rugby.Service.Competition).Sync(day)
    for i=0:1:report.%Size()-1 {
        set r=report.%Get(i),c=##class(Rugby.Service.Store).Get("Club",r.clubId),movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId",r.clubId),daily=[]
        for j=0:1:movements.%Size()-1 { set m=movements.%Get(j) if m.day=day do daily.%Push(m) }
        set r.moraleResults=##class(Rugby.Service.Morale).Reports(r.clubId,day),r.financialMovements=daily,r.balanceAfter=c.balance,r.lineup=##class(Rugby.Service.Store).Get("Lineup",r.clubId_"-default"),execution=##class(Rugby.Service.Store).Get("TrainingExecution",r.trainingExecutionId),r.groups=execution.groups,r.staffSnapshot=execution.staffSnapshot
    }
    set fixtures=##class(Rugby.Service.Store).All("Fixture"),played=[]
    for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if (f.day=day)&&(f.status="finished")&&('f.%Get("archived",0)) do played.%Push(f) }
    set marketPool=##class(Rugby.Service.TransferPool).Refresh(day)
    set result={"transferCompetition":(auction),"marketPool":(marketPool),"id":(eid),"clubId":(own),"day":(day),"date":(date),"modelVersion":(..#VERSION),"seed":(..Seed()),"clubs":(report),"finishedFixtures":(played)}
    do ##class(Rugby.Service.Store).Put("RivalExecution",result)
    quit result
}
ClassMethod SettleFixture(f As %DynamicObject)
{
    if f.%Get("aiSettled",0) quit
    for side="home","away" {
        set cid=f.%Get(side_"Id")
        if cid=##class(Rugby.Service.Store).ManagedClub() continue
        set c=##class(Rugby.Service.Store).Get("Club",cid),l=##class(Rugby.Service.Store).Get("Lineup",cid_"-default")
        if c.day<f.day set c.day=f.day,c.date=f.date
        for i=0:1:l.slots.%Size()+l.bench.%Size()-1 {
            set starter=i<l.slots.%Size(),pid=$select(starter:l.slots.%Get(i).playerId,1:l.bench.%Get(i-l.slots.%Size())),p=##class(Rugby.Service.Store).Get("Player",pid),cost=$select(starter:21+(..Hash(f.id_"-"_pid,..Seed())#9),1:3)
            if starter&&f.%IsDefined("disciplineParticipants") {
                for j=0:1:f.disciplineParticipants.%Size()-1 { set participation=f.disciplineParticipants.%Get(j) if participation.playerId=pid set cost=cost*(participation.playedSeconds/4800) }
            }
            set p.energy=##class(Rugby.Simulation.Engine).Clamp(p.energy-cost,0,100),injuries=f.%Get("matchInjuries",[])
            for j=0:1:injuries.%Size()-1 { set report=injuries.%Get(j) if report.playerId=pid set p.injury=report.injury,p.available=0,p.recoveryDay=report.injury.recoveryDay }
            do ##class(Rugby.Service.Store).Put("Player",p)
        }
        do ##class(Rugby.Service.Management).RefreshAvailability(cid)
        set participants=[]
        if f.%IsDefined("disciplineParticipants") { for j=0:1:f.disciplineParticipants.%Size()-1 { set s=f.disciplineParticipants.%Get(j) if s.side=side do participants.%Push(s) } }
        set outcome=$select(f.winnerId=cid:"win",f.winnerId="":"draw",1:"loss"),morale=##class(Rugby.Service.Morale).Result(cid,f.day,"fixture-"_f.id,outcome,participants)
        if 'f.%IsDefined("moraleResults") set f.moraleResults=[]
        do f.moraleResults.%Push(morale)

    }
    set f.economy=##class(Rugby.Service.Finance).Settle(f)
    do f.%Set("aiSettled",1,"boolean")
    do ##class(Rugby.Service.Store).Put("Fixture",f)
}
}
