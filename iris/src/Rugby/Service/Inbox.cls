Class Rugby.Service.Inbox Extends %RegisteredObject
{
ClassMethod Add(items As %DynamicArray, club As %String, id As %String, type As %String, date As %String, title As %String, path As %String, player As %String = "", name As %String = "")
{
    set read=+$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"inboxRead",club,id))
    do items.%Push({"id":(id),"type":(type),"date":(date),"title":(title),"path":(path),"playerId":(player),"personName":(name),"read":(read>0)})
}
ClassMethod View(club As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    set c=##class(Rugby.Service.Store).Get("Club",club),items=[],lineup=##class(Rugby.Service.Store).Get("Lineup",club_"-default",0),seen={}
    if $isobject(lineup) {
        for i=0:1:lineup.slots.%Size()-1 {
            set pid=lineup.slots.%Get(i).playerId
            if (pid="")||seen.%IsDefined(pid) continue
            do seen.%Set(pid,1)
            set p=##class(Rugby.Service.Store).Get("Player",pid,0)
            if '$isobject(p) continue
            if (p.clubId'=club)||('$isobject(p.%Get("injury"))) continue
            set injury=p.injury,id="injury-"_p.id_"-"_injury.%Get("id",injury.%Get("startedOn",c.date))
            do ..Add(items,club,id,"injury",injury.%Get("startedOn",c.date),"Lesionado en el XV titular","/alineacion",p.id,p.name)
        }
    }
    set end=##class(Rugby.Service.Seasons).EndDate(##class(Rugby.Service.Seasons).Year(club)),notice=$piece(end,"-",1)_"-05-30"
    if ($zdateh(c.date,3)>=$zdateh(notice,3))&&($zdateh(c.date,3)<=$zdateh(end,3)) {
        set players=##class(Rugby.Service.Store).All("Player","clubId",club)
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i),expires=p.%Get("contractEndDate")
            if expires="" continue
            if ($zdateh(expires,3)>$zdateh(end,3))||(p.%Get("contractStatus")="retired") continue
            set id="contract-"_p.id_"-"_expires
            do ..Add(items,club,id,"contract",notice,"Contrato próximo a finalizar","/jugadores/"_p.id,p.id,p.name)
            set item=items.%Get(items.%Size()-1),item.contractEndDate=expires,item.category=p.category,item.retiring=p.%Get("retirementAnnounced",0)
        }
    }
    set contracts=##class(Rugby.Service.Store).All("PlayerContract","clubId",club)
    for i=0:1:contracts.%Size()-1 {
        set sale=contracts.%Get(i)
        if (sale.%Get("kind")'="sale")||(sale.%Get("day",c.day)>c.day) continue
        set name=sale.%Get("playerName"),p=##class(Rugby.Service.Store).Get("Player",sale.playerId,0)
        if (name="")&&$isobject(p) set name=p.name
        do ..Add(items,club,"sale-"_sale.id,"sale",##class(Rugby.Service.Injuries).Date(sale.day),"Venta de jugador completada","/jugadores/"_sale.playerId,sale.playerId,name)
        set item=items.%Get(items.%Size()-1),item.fee=sale.%Get("fee",0),buyer=##class(Rugby.Service.Store).Get("Club",sale.%Get("buyerClubId"),0),item.buyerName=$select($isobject(buyer):buyer.%Get("shortName",buyer.name),1:"")
    }
    set roles=##class(Rugby.Service.Staff).Roles(),staff=##class(Rugby.Service.Store).Get("TechnicalStaff",club,0),filled={}
    if $isobject(staff) {
        for i=0:1:staff.coachIds.%Size()-1 {
            set coach=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(i),0)
            if $isobject(coach) { if (coach.clubId=club)&&(coach.%Get("status")'="dismissed") do filled.%Set(coach.role,1) }
        }
    }
    for i=0:1:roles.%Size()-1 {
        set role=roles.%Get(i)
        if filled.%IsDefined(role.id) continue
        do ..Add(items,club,"staff-"_role.id,"staff",c.date,"Puesto sin cubrir","/staff")
        set item=items.%Get(items.%Size()-1),item.role=role.name
    }
    set office=##class(Rugby.Service.Store).Get("FinancialOffice",club,0),director=""
    if $isobject(office) set director=office.%Get("director")
    if '$isobject(director) { set director={} }
    if director.%Get("id")="" {
        do ..Add(items,club,"staff-finance","staff",c.date,"Puesto sin cubrir","/finanzas?tab=director")
        set item=items.%Get(items.%Size()-1),item.role="Financiero"
    }
    set unread=0
    for i=0:1:items.%Size()-1 { if 'items.%Get(i).read set unread=unread+1 }
    quit {"items":(items),"total":(items.%Size()),"unread":(unread),"date":(c.date)}
}
ClassMethod Mark(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club),##class(Rugby.Service.Store).Key(key)
    if (b.%GetTypeOf("ids")'="array")||(b.%GetTypeOf("read")'="boolean") do ##class(Rugby.Service.Store).Fail(422,"INBOX_INPUT","Indica los avisos y si están leídos.")
    if b.ids.%Size()>500 do ##class(Rugby.Service.Store).Fail(422,"INBOX_INPUT","Selecciona como máximo 500 avisos.")
    set view=..View(club),allowed={},game=##class(Rugby.Service.Store).Game()
    for i=0:1:view.items.%Size()-1 { do allowed.%Set(view.items.%Get(i).id,1) }
    for i=0:1:b.ids.%Size()-1 {
        set id=b.ids.%Get(i)
        if b.ids.%GetTypeOf(i)'="string" do ##class(Rugby.Service.Store).Fail(422,"INBOX_INPUT","Indica los avisos y si están leídos.")
        if allowed.%IsDefined(id) {
            if b.read { set ^RugbyWorld(game,"inboxRead",club,id)=1 }
            else { kill ^RugbyWorld(game,"inboxRead",club,id) }
        }
    }
    // Only acknowledgements are stored; resolved operational alerts need no history.
    set id=""
    for { set id=$order(^RugbyWorld(game,"inboxRead",club,id)) quit:id=""  if 'allowed.%IsDefined(id) kill ^RugbyWorld(game,"inboxRead",club,id) }
    quit ..View(club)
}
}
