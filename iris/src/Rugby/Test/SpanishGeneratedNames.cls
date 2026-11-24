Class Rugby.Test.SpanishGeneratedNames Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Fingerprint(d As %DynamicObject) As %String
{
    set copy=##class(%DynamicObject).%FromJSON(d.%ToJSON())
    for field="name","version","generatedSpanishNameVersion" { do copy.%Remove(field) }
    quit copy.%ToJSON()
}
ClassMethod Run()
{
    set names={},surnames={},firsts={}
    for seed=1:1:1000 {
        set name=##class(Rugby.Service.PlayerNames).Spanish(seed)
        do ..Assert(($length(name," ")=3)&&($piece(name," ",2)'=$piece(name," ",3)),"Spanish identities have two independently selected surnames")
        do ..Assert(name=##class(Rugby.Service.PlayerNames).Spanish(seed),"Spanish names are deterministic")
        do names.%Set(name,1),surnames.%Set($piece(name," ",2),1),firsts.%Set($piece(name," ",1),1)
    }
    do ..Assert((names.%Size()>990)&&(surnames.%Size()>300)&&(firsts.%Size()>150),"Sequential seeds distribute Spanish given names and surnames independently")
    set clubs=##class(Rugby.Service.Store).All("Club"),checked=0
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),families={}
        if ##class(Rugby.Service.Leagues).Country(c)'="ES" continue
        for j=1:1:20 { set name=##class(Rugby.Service.PlayerNames).Spanish(##class(Rugby.Service.Rivals).Hash(c.id_"-academy-"_j)) do families.%Set($piece(name," ",2),1) }
        do ..Assert(families.%Size()>=14,"Each Spanish academy receives varied surnames")
        set checked=checked+1
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),before={},ids=[],first=""
    for i=0:1:roster.%Size()-1 {
        set p=roster.%Get(i)
        if p.category'="academy" continue
        set p.name="Álvaro García López"
        if first="" set first=p.id
        do ##class(Rugby.Service.Store).Put("Player",p),before.%Set(p.id,..Fingerprint(p)),ids.%Push(p.id)
    }
    set custom=##class(Rugby.Service.Store).Get("Player",ids.%Get(1)),custom.name="Nombre personalizado"
    do ##class(Rugby.Service.Store).Put("Player",custom),before.%Set(custom.id,..Fingerprint(custom))
    set protected=ids.%Get(2),^RugbyAdmin("overrides","Player",protected)={"name":"Álvaro García López"}.%ToJSON()
    set real=##class(Rugby.Service.Store).Get("Player",##class(Rugby.Service.Store).Get("Lineup",c.id_"-default").slots.%Get(0).playerId),realBefore=real.%ToJSON(),foreignLineup=##class(Rugby.Service.Store).Get("Lineup","fr-clermont-default"),spanish=##class(Rugby.Service.Store).Get("Player",foreignLineup.slots.%Get(0).playerId),spanishBefore=spanish.%ToJSON()
    set staff=##class(Rugby.Service.Staff).View(c.id),coach=staff.coaches.%Get(0),coach.name="Diego Serrano García"
    do ##class(Rugby.Service.Store).Put("Coach",coach)
    set coachBefore=..Fingerprint(coach),o=##class(Rugby.Service.Finance).Office(c.id),budget=o.budgetReference
    for i=0:1:o.candidates.%Size()-1 { set p=o.candidates.%Get(i),p.name="Laura Soler" }
    set o.director=o.candidates.%Get(1),directorId=o.director.id,directorQuality=o.director.quality,directorWage=o.director.weeklyWage
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o),##class(Rugby.Service.Store).Put("StaffContract",{"id":"names-contract","clubId":(c.id),"coachId":(coach.id),"employeeName":(coach.name)})
    set p=##class(Rugby.Service.Store).Get("Player",first)
    do ##class(Rugby.Service.Store).Put("Negotiation",{"id":"names-negotiation","playerId":(first),"playerVersion":(p.version),"status":"open"})
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"spanishGeneratedNamesVersion")
    set report=##class(Rugby.Service.SpanishGeneratedNames).Apply(),names={},families={}
    for i=0:1:ids.%Size()-1 {
        set p=##class(Rugby.Service.Store).Get("Player",ids.%Get(i))
        do ..Assert(..Fingerprint(p)=before.%Get(p.id),"Name repair preserves youth attributes, morale, energy, wages and contracts")
        do names.%Set(p.name,1),families.%Set($piece(p.name," ",2),1)
    }
    do ..Assert((names.%Size()=ids.%Size())&&(families.%Size()>=18)&&(report.players>=18),"Existing academies lose their repeated generated surnames")
    do ..Assert(##class(Rugby.Service.Store).Get("Player",custom.id).name=custom.name,"Custom names are preserved")
    do ..Assert(##class(Rugby.Service.Store).Get("Player",protected).name="Álvaro García López","Administrator name overrides are preserved")
    do ..Assert((##class(Rugby.Service.Store).Get("Player",real.id).%ToJSON()=realBefore)&&(##class(Rugby.Service.Store).Get("Player",spanish.id).%ToJSON()=spanishBefore),"Real identities and French players are untouched")
    set updated=##class(Rugby.Service.Store).Get("Coach",coach.id)
    do ..Assert((updated.name'=coach.name)&&(..Fingerprint(updated)=coachBefore),"Spanish staff gain varied names without changing ability or pay")
    do ..Assert(##class(Rugby.Service.Store).Get("StaffContract","names-contract").employeeName=updated.name,"Staff contract names stay consistent")
    set o=##class(Rugby.Service.Finance).Office(c.id),candidates={}
    for i=0:1:o.candidates.%Size()-1 { set p=o.candidates.%Get(i) do candidates.%Set(p.name,1) if p.id=directorId do ..Assert(p.name=o.director.name,"The hired director matches the same candidate identity") }
    do ..Assert((candidates.%Size()=3)&&(o.budgetReference=budget)&&(o.director.quality=directorQuality)&&(o.director.weeklyWage=directorWage),"Financiers are distinct and preserve financial conditions")
    do ..Assert(##class(Rugby.Service.Store).Get("Negotiation","names-negotiation").playerVersion=##class(Rugby.Service.Store).Get("Player",first).version,"Cosmetic updates do not invalidate active negotiations")
    set free=##class(Rugby.Service.Store).All("Coach","clubId","")
    for i=0:1:free.%Size()-1 {
        set candidate=free.%Get(i)
        if candidate.%Get("marketCountry")'="ES" continue
        set firstName=$piece(candidate.name," ",1)
        do ..Assert('$data(roleNames(candidate.role,firstName)),"Spanish candidates keep distinct given names within each coaching role")
        set roleNames(candidate.role,firstName)=1
    }
    set p=##class(Rugby.Service.Store).Get("Player",first),stable=p.%ToJSON(),again=##class(Rugby.Service.SpanishGeneratedNames).Apply()
    do ..Assert((again.players=0)&&(again.coaches=0)&&(again.financiers=0)&&(##class(Rugby.Service.Store).Get("Player",first).%ToJSON()=stable),"Migration runs only once and keeps names stable")
    write "SPANISH_NAMES ",names.%Size()," academy names; ",checked," clubs checked",!
}
}
