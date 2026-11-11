Class Rugby.Service.News Extends %RegisteredObject
{
ClassMethod Item(id As %String, type As %String, day As %Integer, club As %String, name As %String, player As %String = "") As %DynamicObject
{
    set c=##class(Rugby.Service.Store).Get("Club",club,0)
    if '$isobject(c) quit ""
    quit {"id":(id),"type":(type),"day":(day),"date":(##class(Rugby.Service.Injuries).Date(day)),"clubId":(club),"clubName":(c.name),"personName":(name),"playerId":(player),"title":"","text":""}
}
ClassMethod Role(role As %String) As %String
{
    if role="finance" quit "Financiero"
    set roles=##class(Rugby.Service.Staff).Roles()
    for i=0:1:roles.%Size()-1 { set r=roles.%Get(i) if r.id=role return r.name }
    quit "Cuerpo técnico"
}
ClassMethod Recent() As %DynamicObject
{
    set c=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),last=c.day,first=last-6,items=[],seen={},finance={}
    set players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),injuries=##class(%DynamicArray).%FromJSON(p.%Get("injuryHistory",[]).%ToJSON())
        if $isobject(p.%Get("injury")) do injuries.%Push(p.injury)
        for j=0:1:injuries.%Size()-1 {
            set injury=injuries.%Get(j)
            if 'injury.%IsDefined("startedDay") continue
            set day=injury.startedDay,id="injury-"_injury.id
            if (day<first)||(day>last)||seen.%IsDefined(id) continue
            set cid=injury.%Get("clubId",p.clubId)
            if cid="" continue
            set n=..Item(id,"injury",day,cid,p.name,p.id)
            if '$isobject(n) continue
            set n.title="Lesión de "_p.name,n.text=injury.name_" (grado "_injury.grade_"). Baja de "_injury.weeks_" "_$select(injury.weeks=1:"semana",1:"semanas")_".",n.category=injury.%Get("category",p.category)
            do seen.%Set(id,1)
            set ordered(-day,id)=n
        }
    }
    set contracts=##class(Rugby.Service.Store).All("PlayerContract")
    for i=0:1:contracts.%Size()-1 {
        set contract=contracts.%Get(i),day=contract.%Get("day")
        if (contract.%Get("kind")'="signing")||(day<first)||(day>last) continue
        set p=##class(Rugby.Service.Store).Get("Player",contract.playerId,0)
        if '$isobject(p) continue
        set n=..Item("player-"_contract.id,"playerSigning",day,contract.clubId,p.name,p.id)
        if '$isobject(n) continue
        set n.title=p.name_" ficha por "_n.clubName,n.text="Nueva incorporación a la plantilla."
        set ordered(-day,n.id)=n
    }
    set contracts=##class(Rugby.Service.Store).All("StaffContract")
    for i=0:1:contracts.%Size()-1 {
        set contract=contracts.%Get(i),day=contract.%Get("day"),role=contract.%Get("role")
        if (contract.%Get("kind","hire")'="hire")||(day<first)||(day>last) continue
        set name=contract.%Get("employeeName")
        if name="" { set coach=##class(Rugby.Service.Store).Get("Coach",contract.%Get("coachId"),0) if $isobject(coach) set name=coach.name }
        if name="" continue
        set n=..Item("staff-"_contract.id,"staffSigning",day,contract.clubId,name)
        if '$isobject(n) continue
        set n.title=name_" se incorpora a "_n.clubName,n.text=..Role(role)_".",n.role=role
        if role="finance" do finance.%Set(contract.clubId_"|"_day_"|"_contract.%Get("directorId"),1)
        set ordered(-day,n.id)=n
    }
    // Existing saves retain the most recent financial hire in the office record.
    set offices=##class(Rugby.Service.Store).All("FinancialOffice")
    for i=0:1:offices.%Size()-1 {
        set o=offices.%Get(i),date=o.%Get("hiredOn"),director=o.%Get("director")
        if (date="")||('$isobject(director)) continue
        set day=$zdateh(date,3)-$zdateh("2026-11-07",3)
        if (day<first)||(day>last)||finance.%IsDefined(o.clubId_"|"_day_"|"_director.%Get("id")) continue
        set n=..Item("finance-"_o.clubId_"-"_date_"-"_director.id,"staffSigning",day,o.clubId,director.name)
        if '$isobject(n) continue
        set n.title=director.name_" se incorpora a "_n.clubName,n.text="Financiero.",n.role="finance"
        set ordered(-day,n.id)=n
    }
    set day=""
    for { set day=$order(ordered(day)) quit:day=""  set id="" for { set id=$order(ordered(day,id)) quit:id=""  do items.%Push(ordered(day,id)) } }
    set result=##class(Rugby.Service.Router).Paginate(items),result.fromDate=##class(Rugby.Service.Injuries).Date(first),result.toDate=c.date
    quit result
}
}
