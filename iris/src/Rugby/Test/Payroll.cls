Class Rugby.Test.Payroll Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club"),catalog=##class(Rugby.Service.Staff).Roles()
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),s=##class(Rugby.Service.Payroll).Summary(c.id),all=##class(Rugby.Service.Store).All("Player","clubId",c.id),lo=9999999,hi=0,senior=0,academy=0
        do ..Assert((s.annualMargin>=(s.budget*.15))&&(s.weeklyAvailable>0),"Annual initial spending fits the club reference budget and leaves a safety margin: "_c.id)
        for j=0:1:all.%Size()-1 {
            set p=all.%Get(j)
            if p.category="senior" { set senior=senior+p.weeklyWage,lo=$select(p.weeklyWage<lo:p.weeklyWage,1:lo),hi=$select(p.weeklyWage>hi:p.weeklyWage,1:hi) } else { set academy=academy+p.weeklyWage }
            do ..Assert((p.weeklyWage>0)&&(p.weeklyWage#100=0),"Salaries are positive whole euros")
        }
        do ..Assert((hi>lo)&&(academy<(senior*.1)),"Salaries retain individual differences and low academy payroll")
        set worst=##class(Rugby.Service.Payroll).AnnualCap(c.id)+s.annualStaff+s.annualDirector+(##class(Rugby.Service.Payroll).TrainingCost(999999,c.id)*365)+s.annualRegistrations+1650000
        do ..Assert(worst<=(s.budget*.85)+1,"Player cap and current employees preserve 15 percent: "_c.id)
    }
    set all=##class(Rugby.Service.Store).All("Player").%ToJSON(),clubsBefore=clubs.%ToJSON(),count=##class(Rugby.Service.Store).All("PlayerContract").%Size(),report=##class(Rugby.Service.Payroll).Initialize()
    do ..Assert((report.players=0)&&(##class(Rugby.Service.Store).All("Player").%ToJSON()=all)&&(##class(Rugby.Service.Store).All("Club").%ToJSON()=clubsBefore)&&(##class(Rugby.Service.Store).All("PlayerContract").%Size()=count),"Payroll calibration is idempotent and never retroactively changes cash")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),room=##class(Rugby.Service.Payroll).WeeklyCap("c1")-##class(Rugby.Service.Payroll).Used("c1",p.id),caught=0
    do ##class(Rugby.Service.Payroll).Check("c1",p.id,room)
    try { do ##class(Rugby.Service.Payroll).Check("c1",p.id,room+100) } catch ex { set caught=ex.Location="PAYROLL_LIMIT" }
    do ..Assert(caught,"New salaries are blocked exactly above the available weekly limit")
    set young=##class(Rugby.Seed.Academy).Create(##class(Rugby.Service.Store).Get("Club","c11"),1,999)
    do ..Assert((young.weeklyWage<young.seniorWeeklyWage)&&(young.weeklyWage<5000),"Future youth players inherit proportional wages")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p2"),quality=p.attributes.%ToJSON(),energy=p.energy,morale=p.morale
    do ##class(Rugby.Service.Payroll).Check("c1",p.id,p.weeklyWage)
    do ..Assert((p.attributes.%ToJSON()=quality)&&(p.energy=energy)&&(p.morale=morale),"Budget checks never affect sporting values")
}
}
