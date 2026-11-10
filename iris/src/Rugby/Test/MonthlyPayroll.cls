Class Rugby.Test.MonthlyPayroll Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club"),middle=0
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),players=##class(Rugby.Service.Store).All("Player","clubId",c.id),band=##class(Rugby.Service.Payroll).Band(c),minimum=99999999,maximum=0
        if band.tier="honor-middle" { set middle=middle+1 do ..Assert((band.monthlyMin=80000)&&(band.monthlyMax=200000),"Middle Honor reference is 800 to 2000 euros per month") }
        if band.tier="honor-high" do ..Assert((band.monthlyMin>80000)&&(band.monthlyMax>200000),"Top Honor has a higher salary band")
        if (band.tier="honor-low")||(band.tier="elite") do ..Assert((band.monthlyMin<80000)&&(band.monthlyMax<200000),"Lower Honor and Elite use lower bands")
        for j=0:1:players.%Size()-1 {
            set p=players.%Get(j),b=##class(Rugby.Service.Payroll).Band(c,p.category),amount=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage)
            do ..Assert((amount>=b.monthlyMin)&&(amount<=b.monthlyMax),"Actual salary stays in the club/category monthly band: "_c.id_" "_p.id)
            if p.category="senior" { set minimum=$select(amount<minimum:amount,1:minimum),maximum=$select(amount>maximum:amount,1:maximum) }
        }
        do ..Assert(maximum>minimum,"Player salaries vary within every roster")
        set s=##class(Rugby.Service.Payroll).Summary(c.id)
        do ..Assert((s.budget=s.budgetReference)&&(s.annualMargin>=s.annualSafetyReserve),"Payroll uses the annual club budget and preserves its safety reserve")
    }
    do ..Assert(middle=4,"Four middle-table Honor clubs use the central band")
    set p=##class(Rugby.Service.Store).Get("Player","c7-p1"),profile=##class(Rugby.Service.Development).FreeProfile(p)
    do ..Assert(profile.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage),"Player profiles expose the same monthly equivalent as the interface")
    set players=##class(Rugby.Service.Transfers).Market(),p=players.%Get(0),n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"monthly-offer-open"),version=n.version
    set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(version),"monthlyWage":200000},"monthly-offer"),again=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(version),"monthlyWage":200000},"monthly-offer")
    do ..Assert((n.status="agreed")&&(n.agreedWeeklyWage=46154)&&(n.%ToJSON()=again.%ToJSON()),"A 2000 euro monthly offer converts to cents accurately and is idempotent")
    for amount=80000:5000:200000 { set week=+$justify(amount*12/52,0,0) do ..Assert($zabs(##class(Rugby.Service.Payroll).Monthly(week)-amount)<=3,"Monthly/weekly conversion differs by at most three cents") }
}
}
