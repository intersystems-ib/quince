Class Rugby.Service.Transfers Extends %RegisteredObject
{
ClassMethod InitializeAll()
{
    set previousGame=##class(Rugby.Service.Store).Game(),previousClub=##class(Rugby.Service.Store).ManagedClub()
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Mercado en preparación.")
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
ClassMethod Initialize()
{
    if '$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"transfersVersion")) {
        set players=##class(Rugby.Service.Store).All("Player")
        for i=0:1:players.%Size()-1 { set p=players.%Get(i) if 'p.%IsDefined("nationalityCode") { set p.nationalityCode="ES",p.nationality="España" do ##class(Rugby.Service.Store).Put("Player",p) } }
        set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"transfersVersion")=1
    }
    set c=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub())
    do ..SeedMarket(##class(Rugby.Service.Competition).Year(c.date))
}
ClassMethod SeedMarket(year As %Integer)
{
    if $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"internationalMarket",year)) quit
    set c=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),catalog=##class(Rugby.Service.Development).Catalog(),seed=##class(Rugby.Service.Rivals).Seed()
    for n=1:1:20 {
        set h=##class(Rugby.Service.Rivals).Hash("free-agent-"_year_"-"_n,seed),pos=1+((n-1)#15),age=18+(h#16),quality=$select((h#10)<2:74+(h#7),(h#10)<6:63+(h#8),1:53+(h#10)),attrs={}
        for k=0:1:16 { set t=catalog.%Get(k).id,v=quality-4+(##class(Rugby.Service.Rivals).Hash(t,h)#9)
            if ((pos<=8)&&$listfind($listbuild("strength","scrum","lineout","ruck","maul"),t))||((pos>8)&&$listfind($listbuild("speed","agility","passing","handling","kicking"),t)) set v=v+3
            do attrs.%Set(t,v)
        }
        set country=$select(n<=10:0,1:1+(h#8)),code=$piece("ES,FR,PT,IE,GB,AR,UY,ZA,NZ",",",country+1),nationality=$piece("España,Francia,Portugal,Irlanda,Reino Unido,Argentina,Uruguay,Sudáfrica,Nueva Zelanda",",",country+1)
        set first=$piece("Álvaro,Louis,João,Liam,Jack,Santiago,Facundo,Pieter,Wiremu",",",country+1),surname=$piece("Sanz,Moreau,Duarte,Murphy,Taylor,Rivas,Silva,Smit,Rangi",",",country+1)
        if country=0 set first=$piece("Jorge,Diego,Mateo,Adrián,Pablo,Hugo,Manuel,Iker,Bruno,Jaime,Marcos,Daniel,Sergio,Ander,Rubén",",",pos),surname=$piece("Ramos,Soler,Molina,Ortega,Rivas,Navarro,Blanco,Sanz,Castro,Vidal,Romero,Prieto,López,Gil,Serrano",",",1+(h#15))
        set secondary=[]
        if pos>3 do secondary.%Push($select(pos<=8:8,1:15))
        set p={"id":("free-agent-"_year_"-"_n),"clubId":"","name":(first_" "_surname),"nationalityCode":(code),"nationality":(nationality),"age":(age),"birthDay":(c.day-(age*365)-(h#300)),"category":"senior","position":(pos),"secondary":(secondary),"energy":100,"morale":100,"available":true,"recoveryDay":0,"weeklyWage":(40000+((quality-40)*1800)),"signingFee":(200000+((quality-40)*40000)),"contractStatus":"free","attributes":(attrs)}
        set p.transferQualityVersion=##class(Rugby.Service.TransferPool).#VERSION
        if code="ES" set p.name=##class(Rugby.Service.PlayerNames).Spanish(h)
        if ##class(Rugby.Service.Payroll).Active() set p.weeklyWage=##class(Rugby.Service.Payroll).Reference(p,"c1")
        if '$isobject(##class(Rugby.Service.Store).Get("Player",p.id,0)) do ##class(Rugby.Service.Store).Put("Player",p)
    }
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"internationalMarket",year)=1
}
ClassMethod Asking(p As %DynamicObject, kind As %String = "signing") As %Integer
{
    set base=p.%Get("previousWeeklyWage",p.weeklyWage)
    if (kind="signing")&&(p.clubId="")&&##class(Rugby.Service.Payroll).Active() set base=##class(Rugby.Service.Payroll).Reference(p,##class(Rugby.Service.Store).ManagedClub())
    if (p.category="academy")&&(kind'="renewal") set base=p.%Get("seniorWeeklyWage",45000)
    set base=##class(Rugby.Simulation.Engine).Clamp(base,100,5000000)
    quit ((base+99)\100)*100
}
ClassMethod Market() As %DynamicArray
{
    set players=##class(Rugby.Service.TransferPool).Players(),items=[],club=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub())
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if p.%Get("retirementAnnounced",0)||(p.%Get("contractStatus")="retired") continue
        set p.age=(club.day-p.birthDay)\365,p.askingWeeklyWage=..Asking(p),p.signingFee=p.%Get("signingFee",0),p.nationalityCode=p.%Get("nationalityCode","ES"),p.nationality=p.%Get("nationality","España")
        do items.%Push(##class(Rugby.Service.Development).FreeProfile(p))
    }
    quit items
}
ClassMethod Public(n As %DynamicObject) As %DynamicObject
{
    set out=##class(%DynamicObject).%FromJSON(n.%ToJSON())
    do out.%Remove("reservationWage")
    set c=##class(Rugby.Service.Store).Get("Club",out.clubId),p=##class(Rugby.Service.Store).Get("Player",out.playerId)
    if out.status'="signed" {
        if (out.%Get("kind","signing")="promotion")&&((p.clubId'=out.clubId)||(p.category'="academy")) { set out.status="unavailable" }
        elseif (out.%Get("kind","signing")="renewal")&&((p.clubId'=out.clubId)||p.%Get("retirementAnnounced",0)) { set out.status="unavailable" }
        elseif (out.%Get("kind","signing")="signing")&&(p.clubId'="") { set out.status="unavailable" }
        elseif p.version'=out.playerVersion { set out.status="changed" }
        elseif (c.day>out.expiresDay)&&$listfind($listbuild("open","counteroffer","agreed"),out.status) { set out.status="expired" }
    }
    set age=(c.day-p.birthDay)\365,out.preferredMinYears=$select(age>=33:1,age<=24:2,1:5),out.preferredMaxYears=$select(age>=33:1,age<=24:3,1:5)
    set out.contractYears=out.%Get("contractYears",1)
    set p.age=(c.day-p.birthDay)\365,p.nationality=p.%Get("nationality","España"),p.nationalityCode=p.%Get("nationalityCode","ES"),out.player=##class(Rugby.Service.Development).FreeProfile(p)
    quit out
}
ClassMethod Get(id As %String) As %DynamicObject
{
    set n=##class(Rugby.Service.Store).Get("Negotiation",id)
    do ##class(Rugby.Service.Store).Managed(n.clubId)
    quit ..Public(n)
}
ClassMethod List() As %DynamicArray
{
    set rows=##class(Rugby.Service.Store).All("Negotiation","clubId",##class(Rugby.Service.Store).ManagedClub()),items=[]
    for i=0:1:rows.%Size()-1 { do items.%Push(..Public(rows.%Get(i))) }
    quit items
}
ClassMethod Free(pid As %String) As %DynamicObject
{
    set p=##class(Rugby.Service.Store).Get("Player",pid)
    if p.%Get("retirementAnnounced",0)||(p.%Get("contractStatus")="retired") do ##class(Rugby.Service.Store).Fail(409,"PLAYER_RETIRING","El jugador se retira y no puede firmar.")
    if p.clubId'="" do ##class(Rugby.Service.Store).Fail(409,"PLAYER_TAKEN","El jugador ya tiene equipo.")
    quit p
}
ClassMethod Candidate(pid As %String, kind As %String) As %DynamicObject
{
    if $listfind($listbuild("promotion","renewal"),kind)=0 quit ..Free(pid)
    set p=##class(Rugby.Service.Store).Get("Player",pid)
    do ##class(Rugby.Service.Store).Managed(p.clubId)
    if p.%Get("retirementAnnounced",0) do ##class(Rugby.Service.Store).Fail(409,"PLAYER_RETIRING","El jugador ha anunciado su retirada y no puede renovar.")
    if (kind="promotion")&&(p.category'="academy") do ##class(Rugby.Service.Store).Fail(409,"NOT_ACADEMY","El jugador ya no pertenece a la cantera.")
    quit p
}
ClassMethod Promotion(club As %String, pid As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    quit ..Open(pid,b,key,"promotion")
}
ClassMethod Open(pid As %String, b As %DynamicObject, key As %String, kind As %String = "signing") As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set club=##class(Rugby.Service.Store).ManagedClub(),game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"retry","negotiate",club,key)) quit ..Get(^RugbyWorld(game,"retry","negotiate",club,key))
    set p=..Candidate(pid,kind),c=##class(Rugby.Service.Store).Get("Club",club)
    do ##class(Rugby.Service.Store).CheckVersion(p,b)
    set current=$get(^RugbyWorld(game,"negotiations",club,pid))
    if current'="" {
        set old=##class(Rugby.Service.Store).Get("Negotiation",current),visible=..Public(old)
        if $listfind($listbuild("open","counteroffer","agreed"),visible.status) {
            if old.%Get("kind","signing")'=kind do ##class(Rugby.Service.Store).Fail(409,"NEGOTIATION_OPEN","Ya hay otra negociación con este jugador. Retírala desde Fichajes antes de cambiar de operación.")
            set ^RugbyWorld(game,"retry","negotiate",club,key)=old.id
            quit visible
        }
        if (old.status="rejected")&&(c.day<(old.updatedDay+7)) do ##class(Rugby.Service.Store).Fail(409,"NEGOTIATION_COOLDOWN","El jugador no quiere retomar la negociación hasta dentro de unos días.")
    }
    if (kind="signing")&&('##class(Rugby.Service.TransferPool).Contains(pid)) do ##class(Rugby.Service.Store).Fail(409,"MARKET_UNLISTED","El jugador no está entre los candidatos disponibles del mercado.")
    set ask=..Asking(p,kind),h=##class(Rugby.Service.Rivals).Hash(pid,##class(Rugby.Service.Rivals).Seed()),floor=((((ask\100)*(85+(h#11)))+99)\100)*100,id=club_"-neg-"_$increment(^RugbyWorld(game,"ids","Negotiation"))
    set n={"id":(id),"clubId":(club),"playerId":(pid),"playerVersion":(p.version),"status":"open","askingWeeklyWage":(ask),"reservationWage":(floor),"counterWeeklyWage":(ask),"agreedWeeklyWage":0,"signingFee":(p.%Get("signingFee",0)),"round":0,"maxRounds":5,"createdDay":(c.day),"updatedDay":(c.day),"expiresDay":(c.day+7),"offers":[]}
    set n.kind=kind
    if (kind="promotion")||(kind="renewal") set n.signingFee=0
    set year=##class(Rugby.Service.Seasons).Year(club)
    if kind="promotion" {
        set term=##class(Rugby.Service.Competition).Year(p.contractEndDate)
        if term>year set year=term
    }
    if kind="renewal" {
        set term=##class(Rugby.Service.Competition).Year(p.contractEndDate)
        if term>year set year=term
        set year=year+1
    }
    set years=##class(Rugby.Service.ContractTerms).Preferred((c.day-p.birthDay)\365,p.id),n.contractStartYear=year,n.contractYears=years,n.counterContractYears=years,n.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+years-1)
    do ##class(Rugby.Service.Store).Put("Negotiation",n)
    set ^RugbyWorld(game,"negotiations",club,pid)=id,^RugbyWorld(game,"retry","negotiate",club,key)=id
    quit ..Public(n)
}
ClassMethod Validate(id As %String, b As %DynamicObject) As %DynamicObject
{
    set n=##class(Rugby.Service.Store).Get("Negotiation",id)
    do ##class(Rugby.Service.Store).Managed(n.clubId),##class(Rugby.Service.Store).CheckVersion(n,b)
    set p=..Candidate(n.playerId,n.%Get("kind","signing")),c=##class(Rugby.Service.Store).Get("Club",n.clubId)
    if p.version'=n.playerVersion do ##class(Rugby.Service.Store).Fail(409,"PLAYER_CHANGED","Las condiciones del jugador han cambiado. Abre una nueva negociación.")
    if c.day>n.expiresDay do ##class(Rugby.Service.Store).Fail(409,"NEGOTIATION_EXPIRED","La negociación ha caducado.")
    quit n
}
ClassMethod Offer(id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game(),club=##class(Rugby.Service.Store).ManagedClub()
    if $data(^RugbyWorld(game,"retry","offer",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","offer",club,key))
    set n=..Validate(id,b),wage=b.%Get("weeklyWage"),monthly=b.%IsDefined("monthlyWage")
    if monthly {
        if b.%IsDefined("weeklyWage") do ##class(Rugby.Service.Store).Fail(422,"WAGE","Indica sólo el salario mensual o semanal, no ambos.")
        set amount=b.monthlyWage
        if (b.%GetTypeOf("monthlyWage")'="number")||('##class(Rugby.Service.Store).Integer(amount,500,21666600))||(amount#100) do ##class(Rugby.Service.Store).Fail(422,"WAGE","Indica un salario mensual entre 5 y 216.666 €, en euros enteros.")
        set wage=+$justify(amount*12/52,0,0)
    }
    if '$listfind($listbuild("open","counteroffer"),n.status) do ##class(Rugby.Service.Store).Fail(409,"NEGOTIATION_STATE","Esta negociación no admite más ofertas.")
    if 'monthly { if (b.%GetTypeOf("weeklyWage")'="number")||('##class(Rugby.Service.Store).Integer(wage,100,5000000))||(wage#100) do ##class(Rugby.Service.Store).Fail(422,"WAGE","Indica un salario semanal entre 1 y 50.000 €, en euros enteros.") }
    set years=b.%Get("contractYears",n.%Get("contractYears",1))
    if b.%IsDefined("contractYears") { if (b.%GetTypeOf("contractYears")'="number")||('##class(Rugby.Service.Store).Integer(years,1,5)) do ##class(Rugby.Service.Store).Fail(422,"CONTRACT_YEARS","La duración del contrato debe ser de 1 a 5 años enteros.") }
    set c=##class(Rugby.Service.Store).Get("Club",club),p=..Candidate(n.playerId,n.%Get("kind","signing")),age=(c.day-p.birthDay)\365,preferred=##class(Rugby.Service.ContractTerms).Preferred(age,p.id),minimum=(((n.reservationWage*##class(Rugby.Service.ContractTerms).Premium(age,years))+99)\100)*100
    if 'n.%IsDefined("contractStartYear") set n.contractStartYear=##class(Rugby.Service.Competition).Year(n.contractEndDate)-(n.%Get("contractYears",1)-1)
    set n.round=n.round+1,n.updatedDay=c.day
    if wage>=minimum { set n.status="agreed",n.agreedWeeklyWage=wage,n.agreedMonthlyWage=$select(monthly:amount,1:##class(Rugby.Service.Payroll).Monthly(wage)),n.counterWeeklyWage=0,n.agreedContractYears=years,n.contractYears=years,n.counterContractYears=0,n.contractEndDate=##class(Rugby.Service.ContractTerms).EndDate(n,years) }
    elseif n.round>=n.maxRounds { set n.status="rejected",n.counterWeeklyWage=0,n.counterContractYears=0 }
    else { set n.status="counteroffer",n.contractYears=preferred,n.counterContractYears=preferred,n.contractEndDate=##class(Rugby.Service.ContractTerms).EndDate(n,preferred),n.counterWeeklyWage=n.askingWeeklyWage-(((((n.askingWeeklyWage-n.reservationWage)\100)*n.round)\5)*100) }
    do n.offers.%Push({"round":(n.round),"day":(c.day),"offeredWeeklyWage":(wage),"offeredContractYears":(years),"status":(n.status),"counterWeeklyWage":(n.counterWeeklyWage),"counterContractYears":(n.%Get("counterContractYears",0)),"agreedContractYears":(n.%Get("agreedContractYears",0))})
    do ##class(Rugby.Service.Store).Put("Negotiation",n)
    set out=..Public(n),^RugbyWorld(game,"retry","offer",club,key)=out.%ToJSON()
    quit out
}
ClassMethod Sign(id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game(),club=##class(Rugby.Service.Store).ManagedClub()
    if $data(^RugbyWorld(game,"retry","sign",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","sign",club,key))
    set n=..Validate(id,b)
    if n.status'="agreed" do ##class(Rugby.Service.Store).Fail(409,"NEGOTIATION_STATE","Primero debes acordar el salario.")
    if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el partido antes de incorporar un jugador.")
    set c=##class(Rugby.Service.Store).Get("Club",club),p=..Candidate(n.playerId,n.%Get("kind","signing"))
    if (n.signingFee>0)&&(c.balance<n.signingFee) do ##class(Rugby.Service.Store).Fail(409,"SIGNING_FUNDS","No hay saldo suficiente para la prima de incorporación.")
    set cover=##class(Rugby.Service.Rivals).InjuryNeed(c,c.day),medical=(n.%Get("kind","signing")="signing")&&(cover.position>0)&&((cover.position<=8)=(p.position<=8)),useMedical=medical&&##class(Rugby.Service.Payroll).CanPayMedical(club,p.id,n.agreedWeeklyWage)
    if 'useMedical do ##class(Rugby.Service.Payroll).Check(club,p.id,n.agreedWeeklyWage)
    if n.%Get("kind")'="renewal" set p.clubId=club,p.category="senior",p.signedDay=c.day
    set p.weeklyWage=n.agreedWeeklyWage,p.monthlyWage=n.%Get("agreedMonthlyWage",##class(Rugby.Service.Payroll).Monthly(n.agreedWeeklyWage)),p.payrollStartDay=c.day,p.contractStatus="employed",p.contractYears=n.%Get("agreedContractYears",1),p.contractEndDate=n.%Get("contractEndDate",##class(Rugby.Service.Seasons).EndDate(##class(Rugby.Service.Seasons).Year(club))),p.age=(c.day-p.birthDay)\365
    if useMedical set p.injuryCoverForPlayerId=cover.playerId
    if n.%Get("kind")="renewal" set p.renewedDay=c.day
    if n.%Get("kind")="promotion" set p.seniorWeeklyWage=n.agreedWeeklyWage,p.promotedDay=c.day
    do ##class(Rugby.Service.Store).Put("Player",p)
    if n.signingFee do ##class(Rugby.Service.Management).Money(c,-n.signingFee,"transfer","Prima de incorporación de "_p.name,"sign-"_n.id)
    set contract={"id":(n.id_"-contract"),"clubId":(club),"playerId":(p.id),"negotiationId":(n.id),"kind":(n.%Get("kind","signing")),"day":(c.day),"weeklyWage":(p.weeklyWage),"monthlyWage":(p.monthlyWage),"payPeriod":"monthly","contractEndDate":(p.contractEndDate),"contractYears":(p.contractYears),"fee":(n.signingFee),"idempotencyKey":(key)}
    if useMedical set contract.reason="injuryCover",contract.replacementForPlayerId=cover.playerId
    do ##class(Rugby.Service.Store).Put("PlayerContract",contract)
    set n.status="signed",n.updatedDay=c.day,n.contractId=contract.id
    do ##class(Rugby.Service.Store).Put("Negotiation",n)
    set pool=##class(Rugby.Service.TransferPool).Refresh(c.day)
    set out=..Public(n),^RugbyWorld(game,"retry","sign",club,key)=out.%ToJSON()
    quit out
}
ClassMethod Withdraw(id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set n=##class(Rugby.Service.Store).Get("Negotiation",id)
    do ##class(Rugby.Service.Store).Managed(n.clubId)
    if n.status="withdrawn" quit ..Public(n)
    do ##class(Rugby.Service.Store).CheckVersion(n,b)
    if n.status="signed" do ##class(Rugby.Service.Store).Fail(409,"NEGOTIATION_STATE","El contrato ya está firmado.")
    set n.status="withdrawn",c=##class(Rugby.Service.Store).Get("Club",n.clubId),n.updatedDay=c.day
    do ##class(Rugby.Service.Store).Put("Negotiation",n)
    quit ..Public(n)
}
}

