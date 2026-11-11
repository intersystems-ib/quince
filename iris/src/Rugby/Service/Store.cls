Class Rugby.Service.Store Extends %RegisteredObject
{
ClassMethod Game() As %String { quit $get(%RugbyGame,"template") }
ClassMethod ManagedClub() As %String { quit $get(%RugbyManagedClub,"c1") }
ClassMethod Get(kind As %String, id As %String, required As %Boolean = 1) As %DynamicObject
{
    set o=$classmethod("Rugby.Model."_kind,"%OpenId",..Game()_"|"_id)
    if '$isobject(o) {
        if required do ..Fail(404,"NOT_FOUND","No se encuentra "_kind_" "_id)
        quit ""
    }
    set d=##class(%DynamicObject).%FromJSON(o.Payload)
    do ..Flags(d),..Venue(kind,d)
    quit d
}
ClassMethod Venue(kind As %String, d As %DynamicObject)
{
    if '$listfind($listbuild("Fixture","Match"),kind) quit
    if $isobject(d.%Get("venue")) { if d.venue.%Get("name")'="" quit }
    set home=..Get("Club",d.%Get("homeId"),0)
    if $isobject(home)&&$isobject(home.%Get("stadium")) set d.venue=home.stadium
}
ClassMethod Put(kind As %String, d As %DynamicObject)
{
    do ..Venue(kind,d)
    set previousSalary=..Get(kind,d.id,0)
    if (kind="Player")&&('$isobject(previousSalary))&&(##class(Rugby.Service.TalentScale).Factor()<1) do ##class(Rugby.Service.TalentScale).Player(d)
    do ##class(Rugby.Service.MonthlyPayroll).Sync(kind,d,previousSalary)
    if kind="Player" do ##class(Rugby.Service.Seasons).Prepare(d)
    if kind="Player" set d.average=##class(Rugby.Service.Development).Average(d),d.form=d.average
    do ..Flags(d)
    set o=$classmethod("Rugby.Model."_kind,"%OpenId",..Game()_"|"_d.id)
    if '$isobject(o) set o=$classmethod("Rugby.Model."_kind,"%New") set o.Key=..Game()_"|"_d.id
    set d.version=o.Version+1,o.Version=d.version
    set o.Club=..Game()_"|"_d.%Get("clubId"),o.Match=..Game()_"|"_d.%Get("matchId"),o.Sequence=d.%Get("sequence",0)
    set o.Payload=d.%ToJSON()
    set sc=o.%Save()
    if $SYSTEM.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"catalog",kind,d.id)=1
    set previous={}
    if o.Version>1 { set previousJSON=$get(^RugbyWorld(..Game(),"indexed",kind,d.id),"{}"),previous=##class(%DynamicObject).%FromJSON(previousJSON) }
    set indexed={}
    for field="clubId","matchId","competitionId","competitionKey","source","playerId" {
        if previous.%IsDefined(field) kill ^RugbyWorld(..Game(),"lookup",kind,field,"@"_previous.%Get(field),d.id)
        if d.%IsDefined(field) { do indexed.%Set(field,d.%Get(field)) set ^RugbyWorld(..Game(),"lookup",kind,field,"@"_d.%Get(field),d.id)=1 }
    }
    set ^RugbyWorld(..Game(),"indexed",kind,d.id)=indexed.%ToJSON()
    if kind="TrainingExecution" do ##class(Rugby.Service.AttributeProgress).Record(d)
    if (kind="Player")&&$isobject(previousSalary) {
        if ('previousSalary.%Get("available",1))&&d.available&&(previousSalary.clubId=d.clubId) do ##class(Rugby.Service.Management).ReturnToBench(d)
    }
}
ClassMethod Flags(d As %DynamicObject)
{
    for field="available","settled","generatedRoster","realIdentity" {
        if d.%IsDefined(field) do d.%Set(field,+d.%Get(field),"boolean")
    }
}
ClassMethod All(kind As %String, field As %String = "", value As %String = "") As %DynamicArray
{
    if $listfind($listbuild("clubId","matchId","competitionId","competitionKey","source","playerId"),field) {
        if '$get(^RugbyWorld(..Game(),"lookupReady",kind,field)) {
            kill ^RugbyWorld(..Game(),"lookup",kind,field)
            set id=""
            for { set id=$order(^RugbyWorld(..Game(),"catalog",kind,id)) quit:id=""  set item=..Get(kind,id) if item.%IsDefined(field) { set ^RugbyWorld(..Game(),"lookup",kind,field,"@"_item.%Get(field),id)=1 set idx=##class(%DynamicObject).%FromJSON($get(^RugbyWorld(..Game(),"indexed",kind,id),"{}")) do idx.%Set(field,item.%Get(field)) set ^RugbyWorld(..Game(),"indexed",kind,id)=idx.%ToJSON() } }
            set ^RugbyWorld(..Game(),"lookupReady",kind,field)=1
        }
        set a=[],id=""
        for { set id=$order(^RugbyWorld(..Game(),"lookup",kind,field,"@"_value,id)) quit:id=""  do a.%Push(..Get(kind,id)) }
        quit a
    }
    set a=[],id=""
    for { set id=$order(^RugbyWorld(##class(Rugby.Service.Store).Game(),"catalog",kind,id)) quit:id=""  set d=..Get(kind,id) if (field="")||(d.%Get(field)=value) do a.%Push(d) }
    quit a
}
ClassMethod Fail(status As %Integer, code As %String, message As %String)
{
    throw ##class(%Exception.General).%New(message,status,code)
}
ClassMethod CheckVersion(d As %DynamicObject, b As %DynamicObject)
{
    if b.%Get("version",-1)'=d.version do ..Fail(409,"VERSION_CONFLICT","Los datos han cambiado. Recarga antes de guardar.")
}
ClassMethod Key(key As %String)
{
    if (key="")||($length(key)>100)||($translate(key,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.","")'="") do ..Fail(400,"IDEMPOTENCY_KEY","Se requiere Idempotency-Key de 1 a 100 caracteres alfanuméricos, guion o punto.")
}
ClassMethod Managed(id As %String)
{
    if id'=..ManagedClub() do ..Fail(403,"CLUB_FORBIDDEN","Solo puedes gestionar el club de esta partida.")
}
ClassMethod Active(club As %String) As %Boolean
{
    set a=..All("Match"),active=0
    for i=0:1:a.%Size()-1 { set m=a.%Get(i) if ((m.homeId=club)||(m.awayId=club))&&(m.status'="scheduled")&&(m.status'="finished") set active=1 }
    quit active
}
ClassMethod Integer(v, low As %Integer, high As %Integer) As %Boolean
{
    quit (v?1.N)&&(v>=low)&&(v<=high)
}
}
