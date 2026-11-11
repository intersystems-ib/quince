Class Rugby.Service.StaffMarket Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Remove(p As %DynamicObject) As %Boolean
{
    set game=##class(Rugby.Service.Store).Game(),staff=##class(Rugby.Service.Store).All("TechnicalStaff")
    for i=0:1:staff.%Size()-1 { set ids=staff.%Get(i).coachIds for j=0:1:ids.%Size()-1 { if ids.%Get(j)=p.id return 0 } }
    // Contracts keep their names even after the live employee record is removed.
    set contracts=##class(Rugby.Service.Store).All("StaffContract")
    for i=0:1:contracts.%Size()-1 {
        set c=contracts.%Get(i),changed=0
        if (c.%Get("coachId")=p.id)&&(c.%Get("employeeName")="") set c.employeeName=p.name,changed=1
        if (c.%Get("replacedCoachId")=p.id)&&(c.%Get("replacedEmployeeName")="") set c.replacedEmployeeName=p.name,changed=1
        if changed do ##class(Rugby.Service.Store).Put("StaffContract",c)
    }
    set sc=##class(Rugby.Model.Coach).%DeleteId(game_"|"_p.id)
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set indexed=##class(%DynamicObject).%FromJSON($get(^RugbyWorld(game,"indexed","Coach",p.id),"{}")),it=indexed.%GetIterator()
    while it.%GetNext(.field,.value) { kill ^RugbyWorld(game,"lookup","Coach",field,"@"_value,p.id) }
    kill ^RugbyWorld(game,"catalog","Coach",p.id),^RugbyWorld(game,"indexed","Coach",p.id)
    quit 1
}
ClassMethod Ensure(role As %String = "") As %DynamicObject
{
    set report={"created":[],"removed":[]},roles=##class(Rugby.Service.Staff).Roles(),free=##class(Rugby.Service.Store).All("Coach","clubId",""),used={},kept={},contracts=##class(Rugby.Service.Store).All("StaffContract")
    for i=0:1:contracts.%Size()-1 { set c=contracts.%Get(i) if c.%Get("kind","hire")="hire" do used.%Set(c.%Get("coachId"),1) }
    for i=0:1:free.%Size()-1 {
        set p=free.%Get(i)
        if (role'="")&&(p.role'=role) continue
        if used.%IsDefined(p.id)||($piece(p.id,"-",2)="coach")||(p.status="dismissed") {
            if ..Remove(p) do report.removed.%Push({"id":(p.id),"name":(p.name),"role":(p.role)})
            continue
        }
        set band=$select(p.quality<55:1,p.quality<75:2,1:3)
        set ordered(p.role,band,-p.quality,p.id)=p
    }
    for i=0:1:roles.%Size()-1 {
        set r=roles.%Get(i)
        if (role'="")&&(r.id'=role) continue
        for band=1:1:3 {
            set quality=$order(ordered(r.id,band,"")),id=""
            if quality'="" set id=$order(ordered(r.id,band,quality,""))
            if id'="" { do kept.%Set(id,1) continue }
            set game=##class(Rugby.Service.Store).Game(),serial=$get(^RugbyWorld(game,"ids","StaffMarket"))+1,^RugbyWorld(game,"ids","StaffMarket")=serial,id="market-"_r.id_"-new-"_serial,quality=$piece("40,65,90",",",band)+(##class(Rugby.Service.Rivals).Hash(id,17341)#11)-5
            set p={"id":(id),"clubId":"","name":(##class(Rugby.Seed.StaffNames).Generate(id)),"generatedNameVersion":"1.0.0","role":(r.id),"quality":(quality),"weeklyWage":(##class(Rugby.Service.Staff).Salary(r.id,quality)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(quality)),"status":"available"}
            do ##class(Rugby.Service.Store).Put("Coach",p),kept.%Set(id,1),report.created.%Push({"id":(id),"name":(p.name),"role":(r.id)})
        }
    }
    for i=0:1:free.%Size()-1 {
        set p=free.%Get(i)
        if (role'="")&&(p.role'=role) continue
        if kept.%IsDefined(p.id) continue
        if '$isobject(##class(Rugby.Service.Store).Get("Coach",p.id,0)) continue
        if ..Remove(p) do report.removed.%Push({"id":(p.id),"name":(p.name),"role":(p.role)})
    }
    quit report
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game()
    if $get(^RugbyWorld(game,"staffMarketVersion"))=..#VERSION quit {"gameId":(game),"created":[],"removed":[]}
    set report=..Ensure(),report.gameId=game,^RugbyWorld(game,"staffMarketVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando el mercado de entrenadores.")
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
