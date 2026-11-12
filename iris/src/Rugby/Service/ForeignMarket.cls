Class Rugby.Service.ForeignMarket Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Active() As %Boolean { quit $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"foreignMarketVersion"))=..#VERSION }
ClassMethod Refresh(day As %Integer, includeReleased As %Boolean = 1) As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),old=$get(^RugbyWorld(game,"transferPoolIds"),"[]"),source=##class(%DynamicArray).%FromJSON(old),ids=[],seen={}
    for i=0:1:source.%Size()-1 {
        set id=source.%Get(i),p=##class(Rugby.Service.Store).Get("Player",id,0)
        if $isobject(p)&&##class(Rugby.Service.TransferPool).Eligible(p)&&('seen.%IsDefined(id)) { do ids.%Push(id),seen.%Set(id,1) }
    }
    // Released players can use vacant places; the weekly intake supplies new foreign agents.
    set free=##class(Rugby.Service.Store).All("Player","clubId","")
    for i=0:1:free.%Size()-1 { set p=free.%Get(i) if includeReleased&&(p.%Get("formerClubId")'="")&&##class(Rugby.Service.TransferPool).Eligible(p)&&('seen.%IsDefined(p.id)) set ranked(-##class(Rugby.Service.Development).Average(p),p.id)=p.id }
    set score=""
    for { set score=$order(ranked(score)) quit:score=""  set id="" for { set id=$order(ranked(score,id)) quit:id=""  quit:ids.%Size()>=20  do ids.%Push(id),seen.%Set(id,1) } }
    set ^RugbyWorld(game,"transferPoolIds")=ids.%ToJSON()
    quit {"version":(..#VERSION),"limit":20,"playerIds":(ids),"changed":(old'=ids.%ToJSON())}
}
ClassMethod Position(day As %Integer, serial As %Integer) As %Integer
{
    set players=##class(Rugby.Service.TransferPool).Players(),minimum=100,best=1,priority=2147483647
    for i=0:1:players.%Size()-1 { set p=players.%Get(i),counts(p.position)=$get(counts(p.position))+1 }
    for pos=1:1:15 {
        set count=$get(counts(pos)),hash=##class(Rugby.Service.Rivals).Hash("foreign-position-"_day_"-"_serial_"-"_pos,##class(Rugby.Service.Rivals).Seed())
        if (count<minimum)||((count=minimum)&&(hash<priority)) set minimum=count,best=pos,priority=hash
    }
    quit best
}
ClassMethod Create(day As %Integer) As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),serial=$get(^RugbyWorld(game,"ids","ForeignAgent"))+1,^RugbyWorld(game,"ids","ForeignAgent")=serial,id="foreign-agent-"_day_"-"_serial,h=##class(Rugby.Service.Rivals).Hash(id,##class(Rugby.Service.Rivals).Seed()),country=1+(h#12)
    set code=$piece("FR,IE,GB,AR,UY,ZA,NZ,PT,IT,FJ,AU,GE",",",country),nationality=$piece("Francia,Irlanda,Reino Unido,Argentina,Uruguay,Sudáfrica,Nueva Zelanda,Portugal,Italia,Fiyi,Australia,Georgia",",",country)
    set given=$piece("Louis,Antoine,Hugo,Mathieu,Thomas,Maxime,Lucas,Pierre|Liam,Conor,Sean,Patrick,Cian,Ronan,Jack,Eoin|Oliver,George,Harry,James,William,Henry,Charlie,Edward|Santiago,Juan,Tomás,Ignacio,Facundo,Matías,Gonzalo,Joaquín|Felipe,Agustín,Nicolás,Francisco,Manuel,Santiago,Diego,Juan|Pieter,Johannes,Siya,Cheslin,Franco,Handré,Willie,Eben|Wiremu,Ardie,Caleb,Rieko,Beauden,Sam,Richie,George|João,Pedro,Diogo,Tomás,Francisco,Miguel,Duarte,Afonso|Luca,Marco,Matteo,Alessandro,Tommaso,Paolo,Federico,Andrea|Josua,Semi,Levani,Viliame,Waisea,Simione,Tevita,Mesake|James,Noah,Angus,Harry,Jordan,Tom,Isaac,William|Giorgi,Davit,Levan,Beka,Vasil,Merab,Tornike,Lasha","|",country)
    set surnames=$piece("Martin,Moreau,Bernard,Petit,Dubois,Laurent,Durand,Lefèvre|Murphy,Kelly,Walsh,O'Brien,Ryan,O'Sullivan,Byrne,Doyle|Smith,Jones,Williams,Brown,Taylor,Wilson,Evans,Thomas|Fernández,González,Rodríguez,López,Martínez,Pérez,Romero,García|Silva,Sosa,Pereira,Castro,Cabrera,Vázquez,Núñez,Suárez|Botha,du Toit,van der Merwe,de Klerk,Jacobs,Ndlovu,Mokoena,Smith|Williams,Smith,Barrett,Clarke,Ioane,Savea,McKenzie,Wilson|Silva,Santos,Ferreira,Pereira,Costa,Rodrigues,Martins,Sousa|Rossi,Russo,Ferrari,Esposito,Bianchi,Romano,Colombo,Ricci|Nayacalevu,Tuisova,Radradra,Mata,Nakarawa,Yato,Nadolo,Tuisue|Smith,Jones,Wilson,Brown,White,Martin,Harris,Clark|Beridze,Kapanadze,Gelashvili,Lomidze,Mamukashvili,Abashidze,Tsiklauri,Sharikadze","|",country)
    set first=1+((##class(Rugby.Service.Rivals).Hash("given",h)\97)#8),last=1+((##class(Rugby.Service.Rivals).Hash("surname",h)\7919)#8),name=$piece(given,",",first)_" "_$piece(surnames,",",last),pos=..Position(day,serial),age=18+(##class(Rugby.Service.Rivals).Hash("age",h)#17),quality=55+(##class(Rugby.Service.Rivals).Hash("quality",h)#27),attrs={},catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:catalog.%Size()-1 {
        set key=catalog.%Get(i).id,value=quality-5+(##class(Rugby.Service.Rivals).Hash(key,h)#11)
        if ((pos<=8)&&$listfind($listbuild("strength","scrum","lineout","ruck","maul"),key))||((pos>8)&&$listfind($listbuild("speed","agility","passing","handling","kicking"),key)) set value=value+3
        do attrs.%Set(key,##class(Rugby.Simulation.Engine).Clamp(value,1,100))
    }
    set secondary=[]
    if pos<=3 { do secondary.%Push($select(pos=1:3,1:1)) } else { do secondary.%Push($select(pos=8:6,pos<=8:8,pos=15:14,1:15)) }
    set p={"id":(id),"clubId":"","name":(name),"nationalityCode":(code),"nationality":(nationality),"age":(age),"birthDay":(day-(age*365)-(h#365)),"category":"senior","position":(pos),"secondary":(secondary),"energy":100,"morale":100,"available":true,"recoveryDay":0,"weeklyWage":100,"signingFee":(200000+((quality-50)*25000)),"contractStatus":"free","attributes":(attrs),"marketCreatedDay":(day),"foreignMarketVersion":(..#VERSION),"transferQualityVersion":(##class(Rugby.Service.TransferPool).#VERSION)}
    if ##class(Rugby.Service.TalentScale).Factor()<1 do ##class(Rugby.Service.TalentScale).Player(p)
    set p.weeklyWage=##class(Rugby.Service.Payroll).Reference(p,"c1")
    do ##class(Rugby.Service.Store).Put("Player",p)
    quit p
}
ClassMethod Fill(day As %Integer) As %DynamicArray
{
    set game=##class(Rugby.Service.Store).Game(),added=[]
    for {
        set ids=##class(%DynamicArray).%FromJSON($get(^RugbyWorld(game,"transferPoolIds"),"[]"))
        quit:ids.%Size()>=20
        set p=..Create(day)
        do ids.%Push(p.id),added.%Push({"playerId":(p.id),"name":(p.name),"nationalityCode":(p.nationalityCode),"average":(p.average),"position":(p.position)})
        set ^RugbyWorld(game,"transferPoolIds")=ids.%ToJSON()
    }
    quit added
}
ClassMethod Remove(p As %DynamicObject, day As %Integer)
{
    do p.%Set("transferMarketRemoved",1,"boolean")
    set p.marketRemovedDay=day,p.marketRemovedReason="weeklyLowestAverage"
    do ##class(Rugby.Service.Store).Put("Player",p)
    set negotiations=##class(Rugby.Service.Store).All("Negotiation")
    for i=0:1:negotiations.%Size()-1 {
        set n=negotiations.%Get(i)
        if (n.playerId=p.id)&&(n.%Get("kind","signing")="signing")&&$listfind($listbuild("open","counteroffer","agreed"),n.status) {
            set n.status="expired",n.expiresDay=day-1,n.updatedDay=day,n.playerVersion=p.version,n.marketExitReason="weeklyRotation"
            do ##class(Rugby.Service.Store).Put("Negotiation",n)
        }
    }
}
ClassMethod Initialize(day As %Integer = "") As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"added":[]}
    if ..Active() quit report
    if day="" set day=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()).day
    set ids=##class(Rugby.Service.TransferPool).Select(day),^RugbyWorld(game,"transferPoolIds")=ids.%ToJSON(),^RugbyWorld(game,"foreignMarketVersion")=..#VERSION,^RugbyWorld(game,"foreignMarketLastDay")=day
    set report.added=..Fill(day),report.nextDay=day+7
    quit report
}
ClassMethod Tick(day As %Integer) As %DynamicObject
{
    if '..Active() quit ..Initialize(day)
    set game=##class(Rugby.Service.Store).Game(),last=^RugbyWorld(game,"foreignMarketLastDay"),report={"version":(..#VERSION),"weeks":[]},pool=..Refresh(day)
    for week=last+7:7:day {
        kill ranked
        set players=##class(Rugby.Service.TransferPool).Players(),removed=[],count=+$justify(players.%Size()*.2,0,0)
        for i=0:1:players.%Size()-1 { set p=players.%Get(i),ranked(##class(Rugby.Service.Development).Average(p),p.id)=p }
        set score=""
        for { set score=$order(ranked(score)) quit:score=""  quit:removed.%Size()>=count  set id="" for { set id=$order(ranked(score,id)) quit:id=""  quit:removed.%Size()>=count  set p=ranked(score,id) do ..Remove(p,week),removed.%Push({"playerId":(p.id),"average":(##class(Rugby.Service.Development).Average(p))}) } }
        set pool=..Refresh(week,0),added=..Fill(week),^RugbyWorld(game,"foreignMarketLastDay")=week
        do report.weeks.%Push({"day":(week),"removed":(removed),"added":(added)})
    }
    set report.nextDay=^RugbyWorld(game,"foreignMarketLastDay")+7
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando el mercado de agentes libres.")
    try {
        tstart
        do reports.%Push(..Initialize())
        set id=""
        for { set id=$order(^RugbyGames(id)) quit:id=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(id)),%RugbyGame=id,%RugbyManagedClub=g.clubId do reports.%Push(..Initialize()) }
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
