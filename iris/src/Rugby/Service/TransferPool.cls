Class Rugby.Service.TransferPool Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
Parameter LIMIT = 20;
ClassMethod Eligible(p As %DynamicObject) As %Boolean
{
    quit (p.clubId="")&&p.available&&('p.%Get("transferMarketRemoved",0))&&('p.%Get("retirementAnnounced",0))&&(p.%Get("contractStatus")'="retired")
}
ClassMethod Pending(day As %Integer) As %DynamicObject
{
    set negotiations=##class(Rugby.Service.Store).All("Negotiation"),ids={}
    for i=0:1:negotiations.%Size()-1 { set n=negotiations.%Get(i) if (n.%Get("kind","signing")="signing")&&$listfind($listbuild("open","counteroffer","agreed"),n.status)&&(n.expiresDay>=day) do ids.%Set(n.playerId,1) }
    quit ids
}
ClassMethod Select(day As %Integer) As %DynamicArray
{
    set free=##class(Rugby.Service.Store).All("Player","clubId",""),pending=..Pending(day),selected={},positions={},ids=[],ordered=""
    for i=0:1:free.%Size()-1 {
        set p=free.%Get(i)
        if '..Eligible(p) continue
        set age=(day-p.birthDay)\365
        if age>36 continue
        set quality=##class(Rugby.Service.Development).Average(p),score=quality-$select(age>30:(age-30)*.3,1:0),rank(-score,p.id)=p
        if pending.%IsDefined(p.id) set pinned(p.id)=p
    }
    set id=""
    for { set id=$order(pinned(id)) quit:id=""  quit:ids.%Size()>=..#LIMIT  set p=pinned(id) do ids.%Push(id),selected.%Set(id,1),positions.%Set(p.position,1) }
    // Give every rugby position a candidate before filling the remaining places by quality.
    set score=""
    for { set score=$order(rank(score)) quit:score=""  set id="" for { set id=$order(rank(score,id)) quit:id=""  quit:ids.%Size()>=..#LIMIT  set p=rank(score,id) if ('positions.%IsDefined(p.position))&&('selected.%IsDefined(id)) { do ids.%Push(id),selected.%Set(id,1),positions.%Set(p.position,1) } } }
    set score=""
    for { set score=$order(rank(score)) quit:score=""  set id="" for { set id=$order(rank(score,id)) quit:id=""  quit:ids.%Size()>=..#LIMIT  if 'selected.%IsDefined(id) { do ids.%Push(id),selected.%Set(id,1) } } }
    quit ids
}
ClassMethod Refresh(day As %Integer) As %DynamicObject
{
    if ##class(Rugby.Service.ForeignMarket).Active() quit ##class(Rugby.Service.ForeignMarket).Refresh(day)
    set ids=..Select(day),game=##class(Rugby.Service.Store).Game(),old=$get(^RugbyWorld(game,"transferPoolIds"),"[]"),json=ids.%ToJSON()
    set ^RugbyWorld(game,"transferPoolIds")=json
    quit {"version":(..#VERSION),"limit":(..#LIMIT),"playerIds":(ids),"changed":(old'=json)}
}
ClassMethod Players() As %DynamicArray
{
    set json=$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"transferPoolIds")),items=[]
    if json="" { set c=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),ids=..Select(c.day) }
    else { set ids=##class(%DynamicArray).%FromJSON(json) }
    for i=0:1:ids.%Size()-1 { set p=##class(Rugby.Service.Store).Get("Player",ids.%Get(i),0) if $isobject(p)&&..Eligible(p) do items.%Push(p) }
    quit items
}
ClassMethod Contains(id As %String) As %Boolean
{
    set players=..Players(),found=0
    for i=0:1:players.%Size()-1 { if players.%Get(i).id=id set found=1 }
    quit found
}
ClassMethod Rankings() As %DynamicObject
{
    set ranks={},year=##class(Rugby.Service.Seasons).Year()
    for division=416,417 {
        set comp=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-"_year),table=##class(Rugby.Service.Competition).Table(comp)
        for i=0:1:table.%Size()-1 { set row=table.%Get(i) do ranks.%Set(row.clubId,row.rank+$select(division=416:0,1:10)) }
    }
    quit ranks
}
ClassMethod HumanPreferred(proposal As %DynamicObject, day As %Integer, ranks As %DynamicObject) As %Boolean
{
    set own=##class(Rugby.Service.Store).ManagedClub(),negotiations=##class(Rugby.Service.Store).All("Negotiation","clubId",own),p=##class(Rugby.Service.Store).Get("Player",proposal.playerId),preferred=0
    for i=0:1:negotiations.%Size()-1 {
        set n=negotiations.%Get(i)
        if (n.playerId'=p.id)||(n.status'="agreed")||(n.%Get("kind","signing")'="signing")||(n.expiresDay<day)||(n.playerVersion'=p.version) continue
        set club=##class(Rugby.Service.Store).Get("Club",own)
        set cover=##class(Rugby.Service.Rivals).InjuryNeed(club,day),medical=(cover.position>0)&&((cover.position<=8)=(p.position<=8)),affordable=##class(Rugby.Service.Payroll).CanPay(own,p.id,n.agreedWeeklyWage)
        if medical set affordable=affordable||##class(Rugby.Service.Payroll).CanPayMedical(own,p.id,n.agreedWeeklyWage)
        if (club.balance<n.signingFee)||('affordable) continue
        set salary=n.%Get("agreedMonthlyWage",##class(Rugby.Service.Payroll).Monthly(n.agreedWeeklyWage))
        if (salary>proposal.monthlyWage)||((salary=proposal.monthlyWage)&&(ranks.%Get(own,100)<=ranks.%Get(proposal.clubId,100))) set preferred=1
    }
    quit preferred
}
ClassMethod Compete(clubs As %DynamicArray, day As %Integer) As %DynamicObject
{
    set ranks=..Rankings(),results={},done={},blocked={},decisions=[],rounds=0,pool=..Refresh(day)
    for round=1:1:..#LIMIT {
        kill ordered
        set count=0,progress=0,rounds=round
        for i=0:1:clubs.%Size()-1 {
            set review=clubs.%Get(i),cid=review.clubId
            if done.%IsDefined(cid) continue
            set c=##class(Rugby.Service.Store).Get("Club",cid),choice=##class(Rugby.Service.Rivals).Recruit(c,day,review.%Get("medicalOnly",0),1,blocked)
            if '$isobject(choice.%Get("proposal")) {
                do results.%Set(cid,choice),done.%Set(cid,1)
                if choice.%Get("promotedId")'="" do ##class(Rugby.Service.Store).Put("Club",c)
                continue
            }
            set bid=choice.proposal,count=count+1,bid.teamPreference=ranks.%Get(cid,100),ordered(-bid.monthlyWage,bid.teamPreference,cid)=bid
        }
        quit:count=0
        set salary=""
        for {
            set salary=$order(ordered(salary)) quit:salary=""
            set rank=""
            for {
                set rank=$order(ordered(salary,rank)) quit:rank=""
                set cid=""
                for {
                    set cid=$order(ordered(salary,rank,cid)) quit:cid=""
                    set bid=ordered(salary,rank,cid),p=##class(Rugby.Service.Store).Get("Player",bid.playerId),outcome="outbid"
                    if p.clubId="" {
                        if ..HumanPreferred(bid,day,ranks) { do blocked.%Set(p.id,1) set outcome="preferredHumanOffer",progress=1 }
                        elseif 'blocked.%IsDefined(p.id) {
                            set c=##class(Rugby.Service.Store).Get("Club",cid),result=##class(Rugby.Service.Rivals).AcceptRecruitment(c,bid,day)
                            if result.signed { do results.%Set(cid,result),done.%Set(cid,1) set outcome="signed",progress=1 }
                        }
                    }
                    do decisions.%Push({"clubId":(cid),"playerId":(bid.playerId),"monthlyWage":(bid.monthlyWage),"teamPreference":(rank),"outcome":(outcome),"round":(round)})
                }
            }
        }
        quit:'progress
    }
    quit {"criterion":"highestMonthlySalaryThenLeaguePosition","decisions":(decisions),"rounds":(rounds),"results":(results)}
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),c=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),report={"gameId":(game),"version":(..#VERSION),"improvements":[]}
    if $get(^RugbyWorld(game,"transferPoolVersion"))'=..#VERSION {
        set free=##class(Rugby.Service.Store).All("Player","clubId",""),pending=..Pending(c.day),catalog=##class(Rugby.Service.Development).Catalog()
        for i=0:1:free.%Size()-1 {
            set p=free.%Get(i)
            if (p.%Get("transferQualityVersion")=..#VERSION)||('..Eligible(p))||pending.%IsDefined(p.id)||p.%Get("realIdentity",0)||(p.%Get("formerClubId")'="")||p.%IsDefined("signedDay") continue
            if ($extract(p.id,1,11)'="free-agent-")&&($extract(p.id,1,14)'="market-player-") continue
            set before=##class(Rugby.Service.Development).Average(p),h=##class(Rugby.Service.Rivals).Hash(p.id,##class(Rugby.Service.Rivals).Seed()),tier=h#10,target=$select(tier<2:74+(h#7),tier<6:63+(h#8),1:53+(h#10)),changed=0
            for k=0:1:catalog.%Size()-1 {
                set attr=catalog.%Get(k).id,old=p.attributes.%Get(attr),value=target-4+(##class(Rugby.Service.Rivals).Hash(attr,h)#9)
                if ((p.position<=8)&&$listfind($listbuild("strength","scrum","lineout","ruck","maul"),attr))||((p.position>8)&&$listfind($listbuild("speed","agility","passing","handling","kicking"),attr)) set value=value+3
                if value>old { do p.attributes.%Set(attr,##class(Rugby.Simulation.Engine).Clamp(value,1,100)) set changed=1 }
            }
            if changed {
                set p.transferQualityVersion=..#VERSION
                do ##class(Rugby.Service.Store).Put("Player",p),report.improvements.%Push({"playerId":(p.id),"before":(before),"after":(##class(Rugby.Service.Development).Average(p))})
            }
        }
        set ^RugbyWorld(game,"transferPoolVersion")=..#VERSION
    }
    set report.pool=..Refresh(c.day)
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando el mercado compartido.")
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
