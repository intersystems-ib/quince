Class Rugby.Test.StaffNames Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set club="c1",staff=##class(Rugby.Service.Staff).View(club),human=""
    for i=0:1:staff.coaches.%Size()-1 { set p=staff.coaches.%Get(i) if p.role="academy" set human=p }
    set human.name="Óscar Serrano"
    do human.%Remove("generatedNameVersion"),##class(Rugby.Service.Store).Put("Coach",human)
    set humanBefore=human.%ToJSON(),snapshots=[],clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if c.id=club continue
        set p=##class(Rugby.Service.Store).Get("Coach",c.id_"-coach-academy"),p.name="Óscar Serrano",p.clubId="",p.status="available"
        do p.%Remove("generatedNameVersion"),##class(Rugby.Service.Store).Put("Coach",p),snapshots.%Push(p)
    }
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"staffNamesVersion")
    set report=##class(Rugby.Seed.StaffNames).Initialize(),names={}
    do ..Assert(report.changes.%Size()>=19,"Former academy coaches with duplicate placeholder identities are repaired")
    for i=0:1:snapshots.%Size()-1 {
        set old=snapshots.%Get(i),p=##class(Rugby.Service.Store).Get("Coach",old.id)
        do ..Assert((p.name'="Óscar Serrano")&&('names.%IsDefined(p.name)),"Each released academy coach has a distinct identity")
        do names.%Set(p.name,1)
        do ..Assert((p.quality=old.quality)&&(p.weeklyWage=old.weeklyWage)&&(p.role=old.role)&&(p.clubId=old.clubId)&&(p.status=old.status)&&(p.effectiveness=old.effectiveness),"Identity repair preserves skills, wages, role and availability")
    }
    do ..Assert(##class(Rugby.Service.Store).Get("Coach",human.id).%ToJSON()=humanBefore,"The user's current academy coach is untouched")
    set all=##class(Rugby.Service.Store).All("Coach").%ToJSON(),again=##class(Rugby.Seed.StaffNames).Initialize()
    do ..Assert((again.changes.%Size()=0)&&(##class(Rugby.Service.Store).All("Coach").%ToJSON()=all),"Repair is idempotent")
    set oldQuery=$get(%RugbyQuery),%RugbyQuery={"role":"academy","offset":0,"limit":5},page=##class(Rugby.Service.Router).Resolve("GET","staff-market","","","",{},""),%RugbyQuery=oldQuery,previous=101
    do ..Assert((page.items.%Size()=3)&&(page.total=3),"Speciality is filtered before pagination and offers three candidates")
    for i=0:1:page.items.%Size()-1 { set p=page.items.%Get(i) do ..Assert((p.role="academy")&&(p.quality<=previous),"Market is ordered by quality within the requested speciality") set previous=p.quality }
    set name=##class(Rugby.Seed.StaffNames).Generate("ai-coach-name-test"),repeat=##class(Rugby.Seed.StaffNames).Generate("ai-coach-name-test")
    do ..Assert(name=repeat,"New automatic coach names are deterministic")
}
}
