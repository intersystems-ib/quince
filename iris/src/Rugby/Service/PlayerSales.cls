Class Rugby.Service.PlayerSales Extends %RegisteredObject
{
ClassMethod Generated(p As %DynamicObject) As %Boolean
{
    quit (p.%Get("formerClubId","")="")&&('p.%IsDefined("signedDay"))&&('p.%Get("realIdentity",0))
}
ClassMethod Listed(p As %DynamicObject) As %Boolean
{
    quit (p.clubId'="")&&p.%Get("transferListed",0)&&('p.%Get("retirementAnnounced",0))&&(p.%Get("contractStatus")'="retired")
}
ClassMethod CanBuy(p As %DynamicObject, buyer As %String) As %Boolean
{
    quit (p.clubId'=buyer)&&((p.clubId="")||..Listed(p))&&('p.%Get("retirementAnnounced",0))&&(p.%Get("contractStatus")'="retired")
}
ClassMethod Fee(p As %DynamicObject) As %Integer { quit $select(p.clubId="":0,1:p.%Get("transferFee",0)) }
ClassMethod Cost(p As %DynamicObject) As %Integer { quit $select(p.clubId="":p.%Get("signingFee",0),1:..Fee(p)) }
ClassMethod Suggested(p As %DynamicObject) As %Integer
{
    quit +$justify(##class(Rugby.Service.MonthlyPayroll).Value(p)*3,0,0)
}
ClassMethod Save(pid As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game(),club=##class(Rugby.Service.Store).ManagedClub()
    if $data(^RugbyWorld(game,"retry","sale",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","sale",club,key))
    set p=##class(Rugby.Service.Store).Get("Player",pid)
    do ##class(Rugby.Service.Store).Managed(p.clubId),##class(Rugby.Service.Store).CheckVersion(p,b)
    if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el partido antes de modificar la venta.")
    if b.%GetTypeOf("listed")'="boolean" do ##class(Rugby.Service.Store).Fail(422,"SALE","Indica si el jugador está a la venta.")
    if b.listed&&p.%Get("retirementAnnounced",0) do ##class(Rugby.Service.Store).Fail(409,"PLAYER_RETIRING","El jugador ha anunciado su retirada.")
    set fee=b.%Get("transferFee",..Suggested(p))
    if b.listed { if (b.%GetTypeOf("transferFee")'="number")||('##class(Rugby.Service.Store).Integer(fee,0,100000000))||(fee#100) do ##class(Rugby.Service.Store).Fail(422,"TRANSFER_FEE","Indica un precio entre 0 y 1.000.000 €, en euros enteros.") }
    set c=##class(Rugby.Service.Store).Get("Club",club),p.transferListed=b.listed,p.transferFee=$select(b.listed:fee,1:0),p.transferListedDay=c.day
    do ##class(Rugby.Service.Store).Put("Player",p)
    set result={"playerId":(pid),"listed":(b.listed),"transferFee":(p.transferFee),"version":(p.version)}
    do result.%Set("listed",b.listed,"boolean")
    set ^RugbyWorld(game,"retry","sale",club,key)=result.%ToJSON()
    quit result
}
ClassMethod Complete(p As %DynamicObject, buyer As %String, fee As %Integer, key As %String)
{
    set seller=p.clubId
    if ('..Listed(p))||(seller=buyer)||(..Fee(p)'=fee) do ##class(Rugby.Service.Store).Fail(409,"SALE_CHANGED","El jugador ya no está disponible en estas condiciones.")
    if ##class(Rugby.Service.Store).Active(seller)||##class(Rugby.Service.Store).Active(buyer) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el partido antes de completar el traspaso.")
    set from=##class(Rugby.Service.Store).Get("Club",seller),to=##class(Rugby.Service.Store).Get("Club",buyer)
    if to.balance<fee do ##class(Rugby.Service.Store).Fail(409,"SIGNING_FUNDS","No hay saldo para el traspaso.")
    do ..Detach(p)
    do ##class(Rugby.Service.Management).Money(to,-fee,"transfer","Traspaso de "_p.name,key_"-out")
    do ##class(Rugby.Service.Management).Money(from,fee,"transfer","Venta de "_p.name,key_"-in")
    set contract={"id":(key_"-sale"),"clubId":(seller),"buyerClubId":(buyer),"playerId":(p.id),"playerName":(p.name),"kind":"sale","day":(to.day),"fee":(fee)}
    do ##class(Rugby.Service.Store).Put("PlayerContract",contract)
    set p.formerClubId=seller,p.transferListed=0,p.transferFee=0
}
ClassMethod Detach(p As %DynamicObject)
{
    set club=p.clubId,pid=p.id,lineups=##class(Rugby.Service.Store).All("Lineup","clubId",club)
    for i=0:1:lineups.%Size()-1 {
        set l=lineups.%Get(i),changed=0,bench=[]
        for j=0:1:l.slots.%Size()-1 {
            set slot=l.slots.%Get(j)
            if slot.playerId=pid { set slot.playerId="",changed=1,slot.id=l.id_"-"_(j+1),slot.clubId=club do ##class(Rugby.Service.Store).Put("LineupSlot",slot) }
        }
        for j=0:1:l.bench.%Size()-1 { set id=l.bench.%Get(j) if id=pid { set changed=1 } else { do bench.%Push(id) } }
        if l.captainId=pid set l.captainId="",changed=1
        if changed { set l.bench=bench do ##class(Rugby.Service.Store).Put("Lineup",l) }
    }
    set plan=##class(Rugby.Service.Store).Get("TrainingPlan",club),changed=0
    for i=0:1:plan.groups.%Size()-1 {
        set g=plan.groups.%Get(i),ids=[]
        for j=0:1:g.playerIds.%Size()-1 { set id=g.playerIds.%Get(j) if id=pid { set changed=1 } else { do ids.%Push(id) } }
        set g.playerIds=ids
    }
    if changed do ##class(Rugby.Service.Store).Put("TrainingPlan",plan)
}
}
