Class Rugby.Test.Inbox Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Find(view As %DynamicObject, id As %String) As %DynamicObject
{
    for i=0:1:view.items.%Size()-1 { set item=view.items.%Get(i) if item.id=id return item }
    quit ""
}
ClassMethod Run()
{
    set %RugbyManagedClub="c1",c=##class(Rugby.Service.Store).Get("Club","c1"),c.date="2027-05-29",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date),c.seasonYear=2026
    do ##class(Rugby.Service.Store).Put("Club",c)
    set lineup=##class(Rugby.Service.Store).Get("Lineup","c1-default"),pid=lineup.slots.%Get(0).playerId,p=##class(Rugby.Service.Store).Get("Player",pid),p.injury={"id":"inbox-test-injury","startedOn":"2027-05-29"},p.available=0,p.contractEndDate="2027-06-30"
    do ##class(Rugby.Service.Store).Put("Player",p)
    set players=##class(Rugby.Service.Store).All("Player","clubId","c1"),aid=""
    for i=0:1:players.%Size()-1 { set youth=players.%Get(i) if youth.category="academy" { set aid=youth.id quit } }
    do ..Assert(aid'="","Test includes an academy player")
    set youth.contractEndDate="2027-06-30"
    do ##class(Rugby.Service.Store).Put("Player",youth)
    set staff=##class(Rugby.Service.Store).Get("TechnicalStaff","c1"),staff.coachIds=[],office=##class(Rugby.Service.Finance).Office("c1"),office.director={}
    do ##class(Rugby.Service.Store).Put("TechnicalStaff",staff),##class(Rugby.Service.Store).Put("FinancialOffice",office)
    set injuryId="injury-"_pid_"-inbox-test-injury",contractId="contract-"_pid_"-2027-06-30",youthId="contract-"_aid_"-2027-06-30",view=##class(Rugby.Service.Inbox).View("c1")
    do ..Assert($isobject(..Find(view,injuryId))&&('$isobject(..Find(view,contractId))),"Starting XV injury is visible; contracts do not warn before the final month")
    set missing=0
    for i=0:1:view.items.%Size()-1 { if view.items.%Get(i).type="staff" set missing=missing+1 }
    do ..Assert(missing=9,"Eight coaching roles and financial director are checked")
    set c.date="2027-05-30",c.day=##class(Rugby.Service.SeasonCalendar).Day(c.date)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set view=##class(Rugby.Service.Inbox).View("c1")
    do ..Assert($isobject(..Find(view,contractId))&&$isobject(..Find(view,youthId)),"Senior and academy contracts warn one calendar month before season close")
    set marked=##class(Rugby.Service.Inbox).Mark("c1",{"ids":[(injuryId)],"read":true},"inbox-mark"),again=##class(Rugby.Service.Inbox).Mark("c1",{"ids":[(injuryId)],"read":true},"inbox-mark")
    do ..Assert(..Find(marked,injuryId).read&&(marked.unread=view.unread-1)&&(again.unread=marked.unread),"Read status persists and acknowledgements are idempotent")
    set marked=##class(Rugby.Service.Inbox).Mark("c1",{"ids":[(injuryId)],"read":false},"inbox-unread")
    do ..Assert('..Find(marked,injuryId).read,"Notifications can be marked unread")
    set slot=lineup.slots.%Get(0),slot.playerId=""
    do ##class(Rugby.Service.Store).Put("Lineup",lineup)
    set p.contractEndDate="2028-06-30",youth.contractEndDate="2028-06-30"
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Store).Put("Player",youth)
    set view=##class(Rugby.Service.Inbox).View("c1")
    do ..Assert(('$isobject(..Find(view,injuryId)))&&('$isobject(..Find(view,contractId)))&&('$isobject(..Find(view,youthId))),"Substitution and renewals resolve operational alerts")
    set candidate=##class(Rugby.Service.Payroll).Market("head").%Get(0),hired=##class(Rugby.Service.Staff).Assign("c1",candidate.id,"inbox-test-hire"),view=##class(Rugby.Service.Inbox).View("c1")
    do ..Assert('$isobject(..Find(view,"staff-head")),"Hiring a missing coach resolves the vacancy")
    do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":"inbox-sale","kind":"sale","clubId":"c1","buyerClubId":"c2","playerId":(pid),"playerName":(p.name),"fee":123400,"day":(c.day)})
    do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":"inbox-foreign-sale","kind":"sale","clubId":"c2","buyerClubId":"c3","playerId":"c2-p1","playerName":"Other sale","fee":1000,"day":(c.day)})
    set view=##class(Rugby.Service.Inbox).View("c1"),sale=..Find(view,"sale-inbox-sale")
    do ..Assert($isobject(sale)&&(sale.fee=123400)&&('$isobject(..Find(view,"sale-inbox-foreign-sale"))),"Completed sales show fee and are scoped to the seller club")
    set denied=0
    try { set ignored=##class(Rugby.Service.Inbox).View("c2") } catch ex { set denied=+ex.Code=403 }
    do ..Assert(denied,"Other clubs' inboxes are private")
    set rejected=0
    try { set ignored=##class(Rugby.Service.Inbox).Mark("c1",{"ids":[12],"read":true},"inbox-invalid") } catch ex { set rejected=+ex.Code=422 }
    do ..Assert(rejected,"Invalid identifiers are rejected")
}
}
