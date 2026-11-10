Class Rugby.Test.RealPlayers Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set catalog=##class(Rugby.Seed.RealPlayers).Catalog(),names={},honor=0,elite=0,total=0
    do ..Assert((catalog.teams.%Size()=20)&&(catalog.sources.%Size()=10),"Twenty clubs are backed by ten supplied sheets")
    for i=0:1:catalog.teams.%Size()-1 {
        set t=catalog.teams.%Get(i),c=##class(Rugby.Service.Store).Get("Club",t.clubId)
        do ..Assert(t.players.%Size()=23,"Every club has fifteen starters and eight named reserves")
        do ..Assert(('c.generatedRoster)&&(c.rosterIdentityCount=23),"Club metadata distinguishes real identities from simulated attributes")
        for j=0:1:t.players.%Size()-1 {
            set row=t.players.%Get(j),p=##class(Rugby.Service.Store).Get("Player",row.id),total=total+1
            if t.competitionId=416 { set honor=honor+1 } else { set elite=elite+1 }
            do ..Assert((p.name=row.name)&&p.realIdentity,"Extracted identity is actually used by the application")
            do ..Assert('names.%IsDefined(p.name),"No duplicated player identities")
            do names.%Set(p.name,1)
            do ..Assert((p.identitySourceId=t.sourceId)&&(p.identitySourcePage=1)&&(p.nationalityCode=""),"Provenance is retained without inventing nationality")
            do ..Assert((p.position>=1)&&(p.position<=15)&&('p.%IsDefined("number")),"Rugby positions are used without permanent shirt numbers")
        }
        set valid=##class(Rugby.Service.Management).Validate(##class(Rugby.Service.Store).Get("Lineup",t.clubId_"-default"))
        do ..Assert(valid.valid,"Imported positions leave every default lineup playable")
    }
    do ..Assert((total=460)&&(honor=230)&&(elite=230),"Two hundred thirty real players in each division")
    do ..Assert(##class(Rugby.Service.Store).Get("Player","c3-p16").name="Bernardo Sebastian Vazquez di Pietro","Wrapped name includes its second given name")
    do ..Assert(##class(Rugby.Service.Store).Get("Player","c14-p17").name="Antonio Michel Tangre Aguilar-Tablada","Wrapped Elite name remains complete")
    do ..Assert(##class(Rugby.Service.Store).Get("Player","c1-p15").name="Guzman Vinuesa Garcia","Table headings never become part of a player name")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.name="Nombre ficticio anterior",p.clubId="c2",p.energy=37.5,p.weeklyWage=123400
    set before=p.attributes.%ToJSON(),average=p.average,birth=p.birthDay
    do ##class(Rugby.Service.Store).Put("Player",p)
    set c=##class(Rugby.Service.Store).Get("Club","c1"),balance=c.balance,day=c.day,plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1").%ToJSON(),lineup=##class(Rugby.Service.Store).Get("Lineup","c1-default").%ToJSON()
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"realRosterVersion")
    set report=##class(Rugby.Seed.RealPlayers).Apply(),p=##class(Rugby.Service.Store).Get("Player",p.id)
    do ..Assert((report.imported=460)&&(p.clubId="c2")&&(p.energy=37.5)&&(p.weeklyWage=123400),"Migration preserves transfers, energy and wages")
    do ..Assert((p.attributes.%ToJSON()=before)&&(p.average=average)&&(p.birthDay=birth),"Training progression and simulated age survive identity migration")
    set c=##class(Rugby.Service.Store).Get("Club","c1")
    do ..Assert((c.balance=balance)&&(c.day=day)&&(##class(Rugby.Service.Store).Get("TrainingPlan","c1").%ToJSON()=plan)&&(##class(Rugby.Service.Store).Get("Lineup","c1-default").%ToJSON()=lineup),"No date, balance, training or managed lineup reset")
    set version=p.version,report=##class(Rugby.Seed.RealPlayers).Apply()
    do ..Assert((report.imported=0)&&(##class(Rugby.Service.Store).Get("Player",p.id).version=version),"Repeated initialization never overwrites progress")
}
}
