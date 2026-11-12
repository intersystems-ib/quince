Class Rugby.Test.News Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set c=##class(Rugby.Service.Store).Get("Club","c1"),c.day=0,c.date="2026-11-07"
    do ##class(Rugby.Service.Store).Put("Club",c)
    set p=##class(Rugby.Service.Store).Get("Player","c2-p1"),injury={"id":"news-test-injury","clubId":"c2","startedDay":0,"name":"Esguince","grade":2,"weeks":3},p.injury=injury,p.injuryHistory=[(injury)],p.clubId="c3"
    do ##class(Rugby.Service.Store).Put("Player",p)
    for kind="signing","renewal","promotion","salaryAdjustment" { do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":("news-test-"_kind),"kind":(kind),"clubId":"c3","playerId":"c3-p1","day":-6}) }
    for day=-7,1 { do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":("news-test-outside-"_day),"kind":"signing","clubId":"c3","playerId":"c3-p2","day":(day)}) }
    set candidate=##class(Rugby.Service.Payroll).Market("head").%Get(0),hired=##class(Rugby.Service.Staff).Assign("c4",candidate.id,"news-test-coach")
    // The AI's club uses its own simulation day for the staff contract.
    set contract=##class(Rugby.Service.Store).Get("StaffContract","c4-news-test-coach"),contract.day=-2
    do ##class(Rugby.Service.Store).Put("StaffContract",contract)
    for n=1:1:2 {
        set o=##class(Rugby.Service.Finance).Office("c1")
        for i=0:1:o.candidates.%Size()-1 { set candidate=o.candidates.%Get(i) quit:candidate.id'=o.director.%Get("id") }
        set body={"version":(o.version),"candidateId":(candidate.id)},hired=##class(Rugby.Service.Finance).Hire("c1",body,"news-test-finance-"_n),retry=##class(Rugby.Service.Finance).Hire("c1",body,"news-test-finance-"_n)
    }
    set serial=2
    for day=0,-6,-7,1 {
        set retiree=##class(Rugby.Service.Store).Get("Player","c2-p"_serial),retiree.retirementAnnounced=1,retiree.retirementAnnouncedDate=##class(Rugby.Service.Injuries).Date(day),retiree.retirementDate="2027-06-12",retiree.retirementClubId="c2",retiree.clubId=""
        do ##class(Rugby.Service.Store).Put("Player",retiree)
        set serial=serial+1
    }
    set %RugbyQuery={"limit":500},news=##class(Rugby.Service.News).Recent(),found={},finances=0,previous=1
    for i=0:1:news.items.%Size()-1 {
        set item=news.items.%Get(i)
        do ..Assert((item.day>=-6)&&(item.day<=0)&&(item.day<=previous),"Only the last seven game days appear, most recent first")
        set previous=item.day
        do found.%Set(item.id,item)
        if (item.type="staffSigning")&&(item.role="finance")&&(item.clubId="c1") set finances=finances+1
    }
    do ..Assert(found.%IsDefined("injury-news-test-injury")&&(found.%Get("injury-news-test-injury").clubId="c2"),"Injuries retain the club of occurrence after a transfer")
    do ..Assert(found.%IsDefined("player-news-test-signing")&&('found.%IsDefined("player-news-test-renewal"))&&('found.%IsDefined("player-news-test-promotion"))&&('found.%IsDefined("player-news-test-salaryAdjustment")),"Only actual player signings are news")
    do ..Assert(found.%IsDefined("staff-c4-news-test-coach")&&(finances=2),"Other clubs' coaches and all financial hires appear without duplication")
    do ..Assert(found.%IsDefined("retirement-c2-p2-2026-11-07")&&found.%IsDefined("retirement-c2-p3-2026-11-01"),"Retirement announcements appear on their announcement day and the inclusive seven-day boundary")
    do ..Assert(('found.%IsDefined("retirement-c2-p4-2026-10-31"))&&('found.%IsDefined("retirement-c2-p5-2026-11-08")),"Older and future retirement announcements are excluded")
    set retirement=found.%Get("retirement-c2-p2-2026-11-07")
    do ..Assert((retirement.type="retirement")&&(retirement.clubId="c2")&&(retirement.playerId="c2-p2")&&(retirement.text["12/06/2027"),"Retirement news preserves the club of announcement after departure and links the player with the planned retirement date")
    set before=news.%ToJSON()
    do p.%Remove("injury"),##class(Rugby.Service.Store).Put("Player",p)
    set again=##class(Rugby.Service.News).Recent()
    do ..Assert(again.%ToJSON()=before,"Recovery does not erase or duplicate injury news")
    set %RugbyQuery={"limit":1,"offset":1},page=##class(Rugby.Service.News).Recent()
    do ..Assert((page.total=news.total)&&(page.items.%Size()=1)&&(page.fromDate="2026-11-01")&&(page.toDate="2026-11-07"),"Pagination retains the exact date window and total")
}
}
