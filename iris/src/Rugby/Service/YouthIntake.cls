Class Rugby.Service.YouthIntake Extends %RegisteredObject
{
ClassMethod Build(c As %DynamicObject, year As %Integer, day As %Integer, quality As %Numeric, slot As %Integer, count As %Integer, position As %Integer) As %DynamicObject
{
    set seed=##class(Rugby.Service.Rivals).Seed(),id=c.id_"-intake-"_year_"-"_slot,h=##class(Rugby.Service.Rivals).Hash(id,seed),serial=100000+(year*10)+slot
    set p=##class(Rugby.Seed.Academy).Create(c,position,serial),p.id=id,p.name=##class(Rugby.Service.PlayerNames).Spanish(h),p.age=16+(h#3),p.birthDay=day-(p.age*365)-((h\3)#300),p.signedDay=day,p.payrollStartDay=day+1
    if ##class(Rugby.Service.TalentScale).Factor()<1 do ##class(Rugby.Service.TalentScale).Player(p)
    set quality=##class(Rugby.Simulation.Engine).Clamp(quality,0,100),scale=##class(Rugby.Service.TalentScale).Factor(),base=##class(Rugby.Service.Development).Average(p)
    set variation=((slot-((count+1)/2))*2.4)+((h#101)/50)-1,target=##class(Rugby.Simulation.Engine).Clamp(base+(((quality-50)*.18+variation)*scale),12,75*scale),offset=target-base,catalog=##class(Rugby.Service.Development).Catalog()
    for i=0:1:16 { set attr=catalog.%Get(i).id do p.attributes.%Set(attr,+$justify(##class(Rugby.Simulation.Engine).Clamp(p.attributes.%Get(attr)+offset,1,100),0,6)) }
    if ##class(Rugby.Service.Payroll).Active() set p.weeklyWage=##class(Rugby.Service.Payroll).Reference(p,c.id,"academy"),p.seniorWeeklyWage=##class(Rugby.Service.Payroll).Reference(p,c.id)
    if ##class(Rugby.Service.MonthlyPayroll).Active() set p.monthlyWage=##class(Rugby.Service.Payroll).Monthly(p.weeklyWage)
    set p.contractYears=3,p.youthIntakeYear=year,p.youthIntakeCoachQuality=quality,p.youthIntakeAverage=##class(Rugby.Service.Development).Average(p),p.average=p.youthIntakeAverage,p.form=p.average
    do ##class(Rugby.Service.Seasons).Contract(p,year+2)
    quit p
}
ClassMethod Arrive(c As %DynamicObject, year As %Integer, day As %Integer) As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),previous=$get(^RugbyWorld(game,"youthIntakes",year,c.id))
    if previous'="" quit ##class(%DynamicObject).%FromJSON(previous)
    set seed=##class(Rugby.Service.Rivals).Seed(),count=5+(##class(Rugby.Service.Rivals).Hash(c.id_"-intake-"_year,seed)#2),qualities=##class(Rugby.Service.Staff).Qualities(c.id),quality=qualities.academy,coverage={},players=##class(Rugby.Service.Store).All("Player","clubId",c.id),arrivals=[]
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.category="academy" do coverage.%Set(p.position,coverage.%Get(p.position,0)+1) }
    for slot=1:1:count {
        set best=999999,position=1
        for pos=1:1:15 { set score=(coverage.%Get(pos,0)*1000)+(##class(Rugby.Service.Rivals).Hash(c.id_"-"_year_"-"_slot_"-"_pos,seed)#1000) if score<best set best=score,position=pos }
        set p=..Build(c,year,day,quality,slot,count,position)
        if $isobject(##class(Rugby.Service.Store).Get("Player",p.id,0)) do ##class(Rugby.Service.Store).Fail(409,"YOUTH_INTAKE_EXISTS","Ya existe una incorporación de esta promoción de cantera.")
        do ##class(Rugby.Service.Store).Put("Player",p),coverage.%Set(position,coverage.%Get(position,0)+1)
        do ##class(Rugby.Service.Store).Put("PlayerContract",{"id":(p.id_"-arrival"),"clubId":(c.id),"playerId":(p.id),"kind":"academyIntake","day":(day),"date":(##class(Rugby.Service.Injuries).Date(day)),"seasonYear":(year),"coachQuality":(quality),"contractYears":(p.contractYears),"contractEndDate":(p.contractEndDate),"monthlyWage":(##class(Rugby.Service.MonthlyPayroll).Value(p)),"weeklyWage":(p.weeklyWage),"fee":0})
        do arrivals.%Push({"playerId":(p.id),"name":(p.name),"age":(p.age),"position":(p.position),"average":(p.average)})
    }
    set result={"clubId":(c.id),"seasonYear":(year),"day":(day),"date":(##class(Rugby.Service.Injuries).Date(day)),"coachQuality":(quality),"count":(count),"players":(arrivals)},^RugbyWorld(game,"youthIntakes",year,c.id)=result.%ToJSON()
    quit result
}
}
