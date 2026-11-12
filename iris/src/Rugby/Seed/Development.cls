Class Rugby.Seed.Development Extends %RegisteredObject
{
ClassMethod Profiles()
{
    if $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",7)) quit
    tstart
    set players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),p.developmentCeiling=p.%Get("potential",100)
        do p.%Remove("potential")
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",7)=1
    tcommit
}
ClassMethod Run()
{
    if $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",6)) quit
    tstart
    set clubs=##class(Rugby.Service.Store).All("Club"),catalog=##class(Rugby.Service.Development).Catalog(),roles=##class(Rugby.Service.Staff).Roles()
    for c=0:1:clubs.%Size()-1 {
        set club=clubs.%Get(c),players=##class(Rugby.Service.Store).All("Player","clubId",club.id),allIds=[]
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            set extra={"ruck":((p.attributes.strength+p.attributes.tackling+p.attributes.decisions)/3),"maul":((p.attributes.strength+p.attributes.scrum+p.attributes.handling)/3),"attacking":((p.attributes.passing+p.attributes.decisions+p.attributes.speed)/3),"defensiveReading":((p.attributes.tackling+p.attributes.decisions+p.attributes.discipline)/3)}
            for j=0:1:catalog.%Size()-2 {
                set attr=catalog.%Get(j).id,value=p.attributes.%Get(attr,extra.%Get(attr,50))
                do p.attributes.%Set(attr,+$justify(##class(Rugby.Simulation.Engine).Clamp(value,1,100),0,6))
            }
            set p.birthDay=club.day-(p.age*365),p.developmentYear=-1,p.developmentGains={}
            do ##class(Rugby.Service.Store).Put("Player",p)
            do allIds.%Push(p.id)
        }
        set coachIds=[]
        for r=0:1:roles.%Size()-1 {
            set role=roles.%Get(r),cid=club.id_"-coach-"_role.id

            set coach={"id":(cid),"clubId":(club.id),"name":(##class(Rugby.Seed.StaffNames).Generate(cid)),"generatedNameVersion":"1.0.0","role":(role.id),"quality":35,"weeklyWage":(##class(Rugby.Service.Staff).Salary(role.id,35)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(35)),"status":"employed"}
            do ##class(Rugby.Service.Store).Put("Coach",coach)
            do coachIds.%Push(cid)
        }
        do ##class(Rugby.Service.Store).Put("TechnicalStaff",{"id":(club.id),"clubId":(club.id),"coachIds":(coachIds)})
        set plan=##class(Rugby.Service.Store).Get("TrainingPlan",club.id),ids=plan.%Get("players",[])
        if ids.%Size()=0 set ids=allIds
        set group={"id":"legacy-group","name":"Plan de la plantilla","focus":(plan.%Get("focus","handling")),"intensity":(plan.%Get("intensity","normal")),"playerIds":(ids)}
        set plan.groups=[(group)],plan.dailyCost=0,plan.rawDailyCost=0,plan.modelVersion="2.0.0"
        do plan.%Remove("focus")
        do plan.%Remove("intensity")
        do plan.%Remove("players")
        do ##class(Rugby.Service.Store).Put("TrainingPlan",plan)
    }
    for r=0:1:roles.%Size()-1 {
        set role=roles.%Get(r)
        for tier=1:1:3 {
            set quality=$select(tier=1:40,tier=2:65,1:90),id="market-"_role.id_"-"_tier
            set coach={"id":(id),"clubId":"","name":(##class(Rugby.Seed.StaffNames).Generate(id)),"generatedNameVersion":"1.1.0","role":(role.id),"quality":(quality),"weeklyWage":(##class(Rugby.Service.Staff).Salary(role.id,quality)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(quality)),"status":"available"}
            do ##class(Rugby.Service.Store).Put("Coach",coach)
        }
    }
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",6)=1
    tcommit
}
}
