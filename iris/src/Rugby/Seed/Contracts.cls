Class Rugby.Seed.Contracts Extends %RegisteredObject
{
Parameter VERSION = "1.0.1";
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"changes":[]}
    if $get(^RugbyWorld(game,"initialContractsVersion"))=..#VERSION quit report
    set players=##class(Rugby.Service.Store).All("Player"),contracts=##class(Rugby.Service.Store).All("PlayerContract"),negotiations=##class(Rugby.Service.Store).All("Negotiation"),protected={}
    for i=0:1:contracts.%Size()-1 { set contract=contracts.%Get(i) if $listfind($listbuild("renewal","signing","promotion"),contract.%Get("kind")) do protected.%Set(contract.playerId,1) }
    for i=0:1:negotiations.%Size()-1 { set n=negotiations.%Get(i) if $listfind($listbuild("open","counteroffer","agreed"),n.status) do protected.%Set(n.playerId,1) }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.clubId="")||(p.%Get("initialContractVersion")'="")||p.%Get("retirementAnnounced",0)||(p.%Get("contractStatus")="retired")||protected.%IsDefined(p.id) continue
        set original=(p.id?1"c"1.N1"-p"1.N)||((p.id?1"c"1.N1"-academy-"1.N)&&(p.%Get("signedDay",($zdateh("2026-09-01",3)-$zdateh("2026-11-07",3)))<=($zdateh("2026-09-01",3)-$zdateh("2026-11-07",3))))
        if 'original continue
        set c=##class(Rugby.Service.Store).Get("Club",p.clubId),before=p.contractEndDate
        if (before="")||(before<c.date) continue
        set extra=##class(Rugby.Service.Rivals).Hash("initial-contract-"_p.id,##class(Rugby.Service.Rivals).Seed())#4,year=##class(Rugby.Service.Competition).Year(before)
        set p.initialContractVersion=..#VERSION,p.initialContractPreviousEndDate=before,p.initialContractExtraYears=extra
        if extra {
            set p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+extra),p.contractYears=p.%Get("contractYears",year-2026+1)+extra
        }
        do ##class(Rugby.Service.Store).Put("Player",p),report.changes.%Push({"playerId":(p.id),"clubId":(p.clubId),"extraYears":(extra),"previousEndDate":(before),"contractEndDate":(p.contractEndDate)})
    }
    set ^RugbyWorld(game,"initialContractsVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando contratos iniciales.")
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
