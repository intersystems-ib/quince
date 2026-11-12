Class Rugby.Seed.Academy Extends %RegisteredObject
{
Parameter TARGET = 20;
ClassMethod Wage(age As %Integer, index As %Integer) As %Integer
{
    set age=##class(Rugby.Simulation.Engine).Clamp(age,16,20)
    quit 2500+((age-16)*500)+((index#4)*500)
}
ClassMethod Create(club As %DynamicObject, position As %Integer, serial As %Integer) As %DynamicObject
{
    set clubIndex=+$extract(club.id,2,*),age=16+((serial+clubIndex)#5),attrs={},catalog=##class(Rugby.Service.Development).Catalog()
    for k=0:1:16 {
        set attr=catalog.%Get(k).id,value=30+(((serial*19)+(clubIndex*7)+(k*11))#32)
        if (position<=8)&&$listfind($listbuild("strength","scrum","lineout","ruck","maul"),attr) set value=value+8
        if (position>8)&&$listfind($listbuild("speed","agility","passing","kicking"),attr) set value=value+8
        do attrs.%Set(attr,value)
    }
    set secondary=[]
    if position>3 do secondary.%Push($select(position<=8:8,1:15))
    set p={"id":(club.id_"-academy-"_serial),"clubId":(club.id),"nationalityCode":"ES","nationality":"España","name":(##class(Rugby.Service.PlayerNames).Spanish(##class(Rugby.Service.Rivals).Hash(club.id_"-academy-"_serial,##class(Rugby.Service.Rivals).Seed()))),"age":(age),"birthDay":(club.day-(age*365)-((serial*47)#300)),"signedDay":(club.day),"category":"academy","position":(position),"secondary":(secondary),"energy":100,"morale":100,"available":true,"recoveryDay":0,"weeklyWage":(..Wage(age,serial)),"seniorWeeklyWage":(44500+((serial#12)*1500)),"attributes":(attrs),"developmentCeiling":(80+(serial#20))}
    if club.%Get("qualityVersion")'="" do ##class(Rugby.Seed.Quality).Adjust(p,club.qualityAcademyOffset,club.qualityVersion,club.id)
    if ##class(Rugby.Service.Payroll).Active() set p.weeklyWage=##class(Rugby.Service.Payroll).Reference(p,club.id,"academy"),p.seniorWeeklyWage=##class(Rugby.Service.Payroll).Reference(p,club.id)
    quit p
}
ClassMethod Run()
{
    if $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",9)) quit
    tstart
    set clubs=##class(Rugby.Service.Store).All("Club")
    for c=0:1:clubs.%Size()-1 {
        set club=clubs.%Get(c),staff=##class(Rugby.Service.Store).Get("TechnicalStaff",club.id),found=0
        for i=0:1:staff.coachIds.%Size()-1 {
            set coach=##class(Rugby.Service.Store).Get("Coach",staff.coachIds.%Get(i))
            if coach.role="academy" set found=1
        }
        if 'found {
            set coach={"id":(club.id_"-coach-academy"),"clubId":(club.id),"name":(##class(Rugby.Seed.StaffNames).Generate(club.id_"-coach-academy")),"generatedNameVersion":"1.0.0","role":"academy","quality":35,"weeklyWage":(##class(Rugby.Service.Staff).Salary("academy",35)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(35)),"status":"employed"}
            do ##class(Rugby.Service.Store).Put("Coach",coach),staff.coachIds.%Push(coach.id)
            do ##class(Rugby.Service.Store).Put("TechnicalStaff",staff)
        }
        set players=##class(Rugby.Service.Store).All("Player","clubId",club.id),count=0,coverage={},serial=0
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if p.category'="academy" continue
            set count=count+1,p.seniorWeeklyWage=p.%Get("seniorWeeklyWage",p.weeklyWage),p.weeklyWage=..Wage(p.age,count)
            do coverage.%Set(p.position,1)
            do ##class(Rugby.Service.Store).Put("Player",p)
        }
        // Fill missing positions first, then add depth until the academy has at least twenty players.
        for pos=1:1:15 {
            if coverage.%IsDefined(pos) continue
            set serial=serial+1,p=..Create(club,pos,serial),count=count+1
            do ##class(Rugby.Service.Store).Put("Player",p)
        }
        for {
            quit:count>=..#TARGET
            set serial=serial+1,p=..Create(club,1+((serial-1)#15),serial),count=count+1
            do ##class(Rugby.Service.Store).Put("Player",p)
        }
    }
    for tier=1:1:3 {
        set id="market-academy-"_tier
        if $isobject(##class(Rugby.Service.Store).Get("Coach",id,0)) continue
        set quality=$select(tier=1:40,tier=2:65,1:90),coach={"id":(id),"clubId":"","name":(##class(Rugby.Seed.StaffNames).Generate(id)),"generatedNameVersion":"1.1.0","role":"academy","quality":(quality),"weeklyWage":(##class(Rugby.Service.Staff).Salary("academy",quality)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(quality)),"status":"available"}
        do ##class(Rugby.Service.Store).Put("Coach",coach)
    }
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",9)=1
    tcommit
}
}
