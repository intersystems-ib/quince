Class Rugby.Test.YouthIntake Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set own=##class(Rugby.Service.Store).Get("Club","c1"),year=##class(Rugby.Service.Seasons).Year()+1,day=##class(Rugby.Service.SeasonCalendar).CloseDay(year-1),minimum=100,maximum=0
    for slot=1:1:6 {
        set weak=##class(Rugby.Service.YouthIntake).Build(own,year,day,20,slot,6,slot),strong=##class(Rugby.Service.YouthIntake).Build(own,year,day,90,slot,6,slot),again=##class(Rugby.Service.YouthIntake).Build(own,year,day,90,slot,6,slot)
        do ..Assert((strong.average>weak.average+6)&&(strong.%ToJSON()=again.%ToJSON()),"The same seeded recruit improves with academy coach quality and generation is deterministic")
        if strong.average<minimum set minimum=strong.average
        if strong.average>maximum set maximum=strong.average
        do ..Assert((strong.age>=16)&&(strong.age<=18)&&(((day-strong.birthDay)\365)=strong.age),"Annual recruits have consistent ages between sixteen and eighteen")
    }
    do ..Assert((maximum-minimum)>5,"A cohort contains varied averages instead of identical players")
    set clubs=##class(Rugby.Service.Store).All("Club"),seen={},total=0,managed=0
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),before=##class(Rugby.Service.Store).All("Player","clubId",c.id).%Size(),staff=##class(Rugby.Service.Staff).View(c.id).%ToJSON(),quality=##class(Rugby.Service.Staff).Qualities(c.id).academy
        set intake=##class(Rugby.Service.YouthIntake).Arrive(c,year,day),retry=##class(Rugby.Service.YouthIntake).Arrive(c,year,day)
        do ..Assert((intake.count>=5)&&(intake.count<=6)&&(intake.players.%Size()=intake.count)&&(intake.coachQuality=quality),"Every club receives five or six recruits using its actual academy coach")
        do ..Assert((intake.%ToJSON()=retry.%ToJSON())&&(##class(Rugby.Service.Store).All("Player","clubId",c.id).%Size()=(before+intake.count)),"Retrying annual arrivals never duplicates recruits")
        do ..Assert(staff=##class(Rugby.Service.Staff).View(c.id).%ToJSON(),"Annual recruitment does not change staff")
        for j=0:1:intake.players.%Size()-1 {
            set p=##class(Rugby.Service.Store).Get("Player",intake.players.%Get(j).playerId)
            do ..Assert(('seen.%IsDefined(p.id))&&(p.clubId=c.id)&&(p.category="academy"),"New players have unique identities and join the correct academy")
            do seen.%Set(p.id,1)
            do ..Assert(($length(p.name," ")>=3)&&(p.nationalityCode="ES")&&(p.energy=100)&&(p.morale=100),"Recruits have Spanish names with two surnames and start rested and motivated")
            do ..Assert((p.contractEndDate=##class(Rugby.Service.Seasons).EndDate(year+2))&&(p.contractYears=3)&&(p.payrollStartDay=day+1),"Youth contracts cover three seasons and payroll starts after season closure")
            do ..Assert(##class(Rugby.Service.MonthlyPayroll).Value(p)<##class(Rugby.Service.Payroll).Monthly(p.seniorWeeklyWage),"Recruits retain the reduced academy salary band")
        }
        if c.id=own.id set managed=intake.count
        set total=total+intake.count
    }
    do ..Assert((managed>=5)&&(total>=100)&&(total<=120),"Annual arrivals include the managed club and both divisions")
}
}
