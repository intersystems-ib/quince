Class Rugby.Test.Finance Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Quality(quality As %Integer) As %Numeric
{
    tstart
    set c=##class(Rugby.Service.Store).Get("Club","c1"),c.date="2026-09-21",s=##class(Rugby.Service.Finance).Season(c),o=##class(Rugby.Service.Finance).Office(c.id),o.director={"id":"quality-test","quality":(quality)}
    do ##class(Rugby.Service.Finance).Deals(c,s,o)
    set total=s.campaignIncome,agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id)
    for i=0:1:agreements.%Size()-1 { set total=total+agreements.%Get(i).annualAmount }
    for i=0:1:s.grants.%Size()-1 { set total=total+s.grants.%Get(i).amount }
    trollback 1
    quit total
}
ClassMethod Run()
{
    set c=##class(Rugby.Service.Store).Get("Club","c1"),balance=c.balance,report=##class(Rugby.Service.Finance).Initialize(),o=##class(Rugby.Service.Finance).Office(c.id)
    do ..Assert((report.offices=0)&&(##class(Rugby.Service.Store).Get("Club",c.id).balance=balance),"Finance adoption never grants retroactive cash")
    set low=..Quality(35),high=..Quality(90)
    do ..Assert(high>low,"Better director improves total financing and the annual margin")
    set o.director=o.candidates.%Get(2)
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    for date="2026-09-06","2026-09-07","2026-09-14","2026-09-21" {
        set c.date=date,c.day=$zdateh(date,3)-$zdateh("2026-11-07",3)
        do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Finance).Tick(c.id)
        set c=##class(Rugby.Service.Store).Get("Club",c.id),s=##class(Rugby.Service.Finance).Season(c)
        if date="2026-09-06" do ..Assert(s.offers.%Size()=0,"No agreements before September milestone")
        if date="2026-09-07" do ..Assert((s.offers.%Size()=12)&&(##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id).%Size()=6),"Six sponsor slots each consider two seeded offers")
        if date="2026-09-14" do ..Assert((s.grants.%Size()=2)&&(s.grants.%Get(0).status="paid"),"Generic local public grants are awarded and paid")
        if date="2026-09-21" do ..Assert(s.campaignComplete&&(s.members>0)&&(s.campaignIncome=(s.members*s.seasonTicketPrice)),"Subscriber campaign produces exact count-based revenue")
    }
    set before=c.balance,count=##class(Rugby.Service.Store).All("FinancialMovement").%Size()
    do ##class(Rugby.Service.Finance).Tick(c.id)
    do ..Assert((##class(Rugby.Service.Store).Get("Club",c.id).balance=before)&&(##class(Rugby.Service.Store).All("FinancialMovement").%Size()=count),"Daily replay cannot duplicate income or payroll")
    set agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id),a=agreements.%Get(0),a.endYear=2028,a.years=3
    do ##class(Rugby.Service.Store).Put("FinancialAgreement",a)
    set c.date="2027-09-07",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",c),##class(Rugby.Service.Finance).Tick(c.id)
    set carried=##class(Rugby.Service.Store).Get("FinancialAgreement",a.id)
    do ..Assert((carried.annualAmount=a.annualAmount)&&(carried.endYear=2028),"Multi-year sponsor carries into next season without renegotiation")
    set f={"id":"finance-receipts","homeId":"c1","awayId":"c2","date":"2027-09-27","stage":"regular"},cheap=##class(Rugby.Service.Finance).Forecast(f,800),dear=##class(Rugby.Service.Finance).Forecast(f,3000),again=##class(Rugby.Service.Finance).Forecast(f,800)
    do ..Assert((cheap.attendance>dear.attendance)&&(cheap.%ToJSON()=again.%ToJSON()),"Attendance responds to ticket price and fixed seed")
    set f.stage="friendly",r=##class(Rugby.Service.Finance).Forecast(f,1250),home=##class(Rugby.Service.Store).Get("Club","c1"),away=##class(Rugby.Service.Store).Get("Club","c2"),hb=home.balance,ab=away.balance,result=##class(Rugby.Service.Finance).Settle(f,r)
    set home=##class(Rugby.Service.Store).Get("Club","c1"),away=##class(Rugby.Service.Store).Get("Club","c2")
    do ..Assert(((home.balance-hb)=result.homeShare)&&((away.balance-ab)=result.awayShare)&&($zabs(result.homeShare-result.awayShare)<=1)&&((result.homeShare+result.awayShare)=r.netRevenue),"Friendly tickets and bar net split equally with exact cent conservation")
    set result=##class(Rugby.Service.Finance).Settle(f,r)
    do ..Assert((##class(Rugby.Service.Store).Get("Club","c1").balance=home.balance)&&(##class(Rugby.Service.Store).Get("Club","c2").balance=away.balance),"Match revenue cannot be credited twice")
    set before=##class(Rugby.Service.Finance).View("c1").%ToJSON(),after=##class(Rugby.Service.Finance).View("c1").%ToJSON()
    do ..Assert(before=after,"Finance view is read-only")
}
}
