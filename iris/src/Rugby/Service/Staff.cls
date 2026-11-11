Class Rugby.Service.Staff Extends %RegisteredObject
{
ClassMethod Roles() As %DynamicArray
{
    quit [
        {"id":"head","name":"Entrenador principal","englishName":"Head Coach","description":"Dirección del equipo, decisiones, liderazgo y filosofía de juego.","baseWeeklyWage":120000},
        {"id":"forwards","name":"Entrenador de delanteros","englishName":"Forwards Coach","description":"Melé, touche, rucks, mauls y trabajo de los ocho delanteros.","baseWeeklyWage":90000},
        {"id":"backs","name":"Entrenador de tres cuartos","englishName":"Backs Coach","description":"Ataque desplegado, combinaciones, juego al pie y coordinación de los backs.","baseWeeklyWage":90000},
        {"id":"defense","name":"Entrenador de defensa","englishName":"Defence Coach","description":"Placaje, lectura defensiva y disciplina en el breakdown.","baseWeeklyWage":85000},
        {"id":"attack","name":"Entrenador de ataque","englishName":"Attack Coach","description":"Estructura ofensiva, rupturas y circulación del balón.","baseWeeklyWage":85000},
        {"id":"skills","name":"Entrenador de destrezas","englishName":"Skills Coach","description":"Pase, manejo, recepción y fundamentos técnicos individuales.","baseWeeklyWage":80000},
        {"id":"fitness","name":"Preparador físico","englishName":"Strength & Conditioning Coach","description":"Fuerza, resistencia, velocidad, agilidad y conservación física.","baseWeeklyWage":95000},
        {"id":"academy","name":"Entrenador de cantera","englishName":"Academy Coach","description":"Desarrollo de los canteranos en todas sus especialidades de entrenamiento.","baseWeeklyWage":75000}
    ]
}
ClassMethod Multiplier(quality As %Numeric) As %Numeric
{
    quit .35+(.65*quality/100)
}
ClassMethod Salary(role As %String, quality As %Numeric) As %Integer
{
    set roles=..Roles(),base=80000
    for i=0:1:roles.%Size()-1 { set r=roles.%Get(i) if r.id=role set base=r.baseWeeklyWage }
    quit +$justify(base*..Multiplier(quality),0,0)
}
ClassMethod View(club As %String) As %DynamicObject
{
    set staff=##class(Rugby.Service.Store).Get("TechnicalStaff",club),coaches=[],total=0,monthly=0
    for i=0:1:staff.coachIds.%Size()-1 {
        set coach=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(i)),total=total+coach.weeklyWage
        set coach.monthlyWage=##class(Rugby.Service.MonthlyPayroll).Value(coach),monthly=monthly+coach.monthlyWage
        do coaches.%Push(coach)
    }
    quit {"id":(staff.id),"clubId":(club),"version":(staff.version),"coaches":(coaches),"weeklyWage":(total),"monthlyWage":(monthly),"payPeriod":"monthly","roles":(..Roles())}
}
ClassMethod Qualities(club As %String) As %DynamicObject
{
    set q={"head":25,"forwards":25,"backs":25,"defense":25,"attack":25,"skills":25,"fitness":25,"academy":25},staff=..View(club)
    for i=0:1:staff.coaches.%Size()-1 { set coach=staff.coaches.%Get(i) do q.%Set(coach.role,coach.quality) }
    quit q
}
ClassMethod Hire(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club)
    do ##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","staff",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","staff",club,key))
    set staff=##class(Rugby.Service.Store).Get("TechnicalStaff",club)
    do ##class(Rugby.Service.Store).CheckVersion(staff,b)
    quit ..Assign(club,b.%Get("coachId"),key)
}
ClassMethod Assign(club As %String, coachId As %String, key As %String) As %DynamicObject
{
    set staff=##class(Rugby.Service.Store).Get("TechnicalStaff",club)
    set candidate=##class(Rugby.Service.Store).Get("Coach",coachId)
    if candidate.clubId'="" do ##class(Rugby.Service.Store).Fail(409,"COACH_UNAVAILABLE","Este entrenador ya tiene contrato. Actualiza los candidatos.")
    set candidate.monthlyWage=##class(Rugby.Service.MonthlyPayroll).StaffMonthly(candidate.role,candidate.quality,club),candidate.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(candidate.monthlyWage)
    set candidate.payrollStartDay=##class(Rugby.Service.Store).Get("Club",club).day,candidate.staffPayVersion=##class(Rugby.Service.StaffPay).#VERSION,candidate.salaryEffectiveDay=candidate.payrollStartDay,candidate.salaryBeforeAdjustment=0
    set ids=[],replaced="",replacedName=""
    for i=0:1:staff.coachIds.%Size()-1 {
        set coach=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(i))
        if coach.role=candidate.role {
            set replaced=coach.id,replacedName=coach.name,coach.clubId="",coach.status="dismissed"
            do ##class(Rugby.Service.Store).Put("Coach",coach)
        } else { do ids.%Push(coach.id) }
    }
    if ##class(Rugby.Service.Payroll).Active() set candidate.weeklyWage=##class(Rugby.Service.Payroll).StaffWage(candidate.role,candidate.quality,club)
    set candidate.clubId=club,candidate.status="employed"
    do ##class(Rugby.Service.Store).Put("Coach",candidate)
    do ids.%Push(candidate.id)
    set staff.coachIds=ids
    do ##class(Rugby.Service.Store).Put("TechnicalStaff",staff)
    set c=##class(Rugby.Service.Store).Get("Club",club)
    set contract={"id":(club_"-"_key),"clubId":(club),"coachId":(candidate.id),"replacedCoachId":(replaced),"role":(candidate.role),"quality":(candidate.quality),"weeklyWage":(candidate.weeklyWage),"monthlyWage":(candidate.monthlyWage),"payPeriod":"monthly","day":(c.day),"idempotencyKey":(key)}
    set contract.kind="hire",contract.employeeName=candidate.name,contract.replacedEmployeeName=replacedName
    do ##class(Rugby.Service.Store).Put("StaffContract",contract)
    if replaced'="" { set former=##class(Rugby.Service.Store).Get("Coach",replaced,0) if $isobject(former) set removed=##class(Rugby.Service.StaffMarket).Remove(former) }
    set replenished=##class(Rugby.Service.StaffMarket).Ensure(candidate.role)
    set result=..View(club),^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","staff",club,key)=result.%ToJSON()
    quit result
}
}
