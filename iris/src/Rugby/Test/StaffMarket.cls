Class Rugby.Test.StaffMarket Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    for i=1:1:40 {
        set quality=20+(i*2),p={"id":("market-test-"_i),"name":("Candidato "_i),"clubId":"","role":"academy","quality":(quality),"weeklyWage":10000,"effectiveness":1,"status":"available"}
        do ##class(Rugby.Service.Store).Put("Coach",p)
    }
    set former={"id":"retired-market-test","clubId":"","name":"Empleado despedido","role":"academy","quality":80,"weeklyWage":10000,"status":"available"}
    do ##class(Rugby.Service.Store).Put("Coach",former),##class(Rugby.Service.Store).Put("StaffContract",{"id":"market-history-test","coachId":(former.id),"clubId":"c2","kind":"hire","role":"academy","day":0})
    set staffBefore=##class(Rugby.Service.Staff).View("c1").%ToJSON(),report=##class(Rugby.Service.StaffMarket).Ensure()
    do ..Assert(('$isobject(##class(Rugby.Service.Store).Get("Coach",former.id,0)))&&(##class(Rugby.Service.Store).Get("StaffContract","market-history-test").employeeName=former.name),"Dismissed employees are removed while historical contracts retain their name")
    do ..Assert(##class(Rugby.Service.Staff).View("c1").%ToJSON()=staffBefore,"Pool cleanup never changes currently employed staff")
    set before=##class(Rugby.Service.Store).All("Coach").%ToJSON(),market=##class(Rugby.Service.Payroll).Market("academy"),seen={},bands={},previous=101
    do ..Assert(market.%Size()=3,"Large candidate pools produce three offers per speciality")
    for i=0:1:market.%Size()-1 {
        set p=market.%Get(i)
        do ..Assert((p.role="academy")&&(p.clubId="")&&('seen.%IsDefined(p.id))&&(p.quality<=previous),"Shortlist contains unique available candidates ordered by quality")
        do seen.%Set(p.id,1),bands.%Set($select(p.quality<55:1,p.quality<75:2,1:3),1)
        set previous=p.quality
    }
    do ..Assert(bands.%IsDefined(1)&&bands.%IsDefined(2)&&bands.%IsDefined(3),"Different quality and salary bands remain available")
    for n=1:1:3 { set again=##class(Rugby.Service.Payroll).Market("academy"),other=##class(Rugby.Service.Payroll).Market("head") do ..Assert(again.%ToJSON()=market.%ToJSON(),"Switching specialities keeps a stable shortlist") }
    do ..Assert(##class(Rugby.Service.Store).All("Coach").%ToJSON()=before,"Viewing candidates never creates, deletes or modifies coaches")
    set %RugbyQuery={"role":"academy","limit":2,"offset":1},page=##class(Rugby.Service.Router).Resolve("GET","staff-market","","","",{},"")
    do ..Assert((page.total=3)&&(page.items.%Size()=2)&&(page.items.%Get(0).id=market.%Get(1).id),"Filtering and shortlisting precede pagination")
    set staff=##class(Rugby.Service.Staff).View("c1"),oldId="",oldName=""
    for i=0:1:staff.coaches.%Size()-1 { set p=staff.coaches.%Get(i) if p.role="academy" set oldId=p.id,oldName=p.name }
    set candidate=market.%Get(0),body={"coachId":(candidate.id),"version":(staff.version)},hired=##class(Rugby.Service.Staff).Hire("c1",body,"market-refill-test"),free=##class(Rugby.Service.Store).All("Coach","clubId",""),available=0
    for i=0:1:free.%Size()-1 { if free.%Get(i).role="academy" set available=available+1 }
    do ..Assert((available=3)&&('$isobject(##class(Rugby.Service.Store).Get("Coach",oldId,0)))&&(##class(Rugby.Service.Store).Get("Coach",candidate.id).clubId="c1"),"Hiring removes the dismissed coach and refills the pool to exactly three")
    do ..Assert(##class(Rugby.Service.Store).Get("StaffContract","c1-market-refill-test").replacedEmployeeName=oldName,"Replacement contracts preserve the dismissed employee name")
    set poolBefore=##class(Rugby.Service.Store).All("Coach").%ToJSON(),retry=##class(Rugby.Service.Staff).Hire("c1",body,"market-refill-test"),again=##class(Rugby.Service.StaffMarket).Ensure()
    do ..Assert((again.created.%Size()=0)&&(again.removed.%Size()=0)&&(##class(Rugby.Service.Store).All("Coach").%ToJSON()=poolBefore),"Retries and repeated maintenance do not generate more candidates")
    set p=##class(Rugby.Service.Store).Get("Coach",candidate.id),removed=##class(Rugby.Service.StaffMarket).Remove(p)
    do ..Assert(('removed)&&$isobject(##class(Rugby.Service.Store).Get("Coach",p.id,0)),"Currently employed staff cannot be removed by pool maintenance")
    set c=##class(Rugby.Service.Store).Get("Club","c2"),c.balance=1000000000,c.divisionBudgetReference=1000000,staff=##class(Rugby.Service.Staff).View(c.id),free=##class(Rugby.Service.Store).All("Coach","clubId","")
    do ##class(Rugby.Service.Store).Put("Club",c)
    for i=0:1:free.%Size()-1 { set p=free.%Get(i),p.quality=100 do ##class(Rugby.Service.Store).Put("Coach",p) }
    for i=0:1:staff.coaches.%Size()-1 { set p=staff.coaches.%Get(i),p.quality=35 do ##class(Rugby.Service.Store).Put("Coach",p) }
    set count=##class(Rugby.Service.Store).All("Coach").%Size()
    for day=c.day+1:1:c.day+3 {
        set result=##class(Rugby.Service.Rivals).Coach(c,day)
        do ..Assert(('result.hired)&&(result.reason="payrollLimit")&&(##class(Rugby.Service.Store).All("Coach").%Size()=count),"Unfunded AI attempts do not create more candidates")
    }
}
}
