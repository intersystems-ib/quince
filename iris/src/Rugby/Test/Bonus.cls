Class Rugby.Test.Bonus Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set p=##class(Rugby.Service.Competition).Points(21,0,3,0)
    do ..Assert((p.basePoints=4)&&(p.bonusOffensive=1)&&(p.total=5),"Winning by three tries earns the offensive bonus even with fewer than four tries")
    set p=##class(Rugby.Service.Competition).Points(35,28,5,4)
    do ..Assert((p.bonusOffensive=0)&&(p.total=4),"Four or five tries alone do not earn an offensive bonus")
    set p=##class(Rugby.Service.Competition).Points(28,35,4,5)
    do ..Assert((p.bonusDefensive=1)&&(p.bonusOffensive=0)&&(p.total=1),"Exactly seven points of defeat earns one defensive bonus")
    set p=##class(Rugby.Service.Competition).Points(7,15,1,3)
    do ..Assert(p.total=0,"Eight points of defeat earns no defensive bonus")
    set p=##class(Rugby.Service.Competition).Points(13,14,1,2)
    do ..Assert(p.total=1,"A one-point defeat earns the defensive bonus")
    set p=##class(Rugby.Service.Competition).Points(35,35,5,2)
    do ..Assert((p.total=2)&&(p.bonusOffensive=0)&&(p.bonusDefensive=0),"Draws get two points without either winner or loser bonus")
    set p=##class(Rugby.Service.Competition).Points(25,28,5,1)
    do ..Assert((p.bonusOffensive=0)&&(p.total=1),"A losing team cannot earn the FER winner-only offensive bonus")
    for division=416,417 {
        set comp=##class(Rugby.Service.Competition).Draw(division,2038,17341+division),f=##class(Rugby.Service.Competition).Fixtures(comp.id).%Get(0),f.status="finished",f.homeScore=20,f.awayScore=19,f.homeTries=4,f.awayTries=1
        do ##class(Rugby.Service.Store).Put("Fixture",f)
        set table=##class(Rugby.Service.Competition).Table(comp)
        for i=0:1:table.%Size()-1 {
            set row=table.%Get(i)
            if row.clubId=f.homeId do ..Assert((row.points=5)&&(row.bonusOffensive=1)&&(row.bonusDefensive=0),"Both divisions include offensive bonus in total points")
            if row.clubId=f.awayId do ..Assert((row.points=1)&&(row.bonusDefensive=1)&&(row.bonusOffensive=0),"The opponent can simultaneously receive a defensive bonus")
        }
        do ..Assert(##class(Rugby.Service.Competition).Table(comp).%ToJSON()=table.%ToJSON(),"Repeated reads never award the same points twice")
        set result=##class(Rugby.Service.Competition).Classification(f)
        do ..Assert(result.eligible&&(result.home.total=5)&&(result.away.total=1),"Fixture breakdown matches the standings")
        for stage="friendly","semifinal","final" {
            set f.stage=stage,result=##class(Rugby.Service.Competition).Classification(f)
            do ..Assert('result.eligible,"Friendlies and playoffs never award league points")
        }
        set f.stage="regular",f.status="scheduled",result=##class(Rugby.Service.Competition).Classification(f)
        do ..Assert('result.eligible,"Unfinished matches do not award league points")
        set automatic=##class(Rugby.Service.Competition).Fixtures(comp.id).%Get(1)
        do ##class(Rugby.Service.Competition).Simulate(automatic)
        set expected=##class(Rugby.Service.Competition).Classification(automatic),persisted=##class(Rugby.Service.Store).Get("Fixture",automatic.id)
        do ..Assert(persisted.classification.%ToJSON()=expected.%ToJSON(),"Automated fixtures persist the exact same rule and bonus calculation")
    }
    set m=##class(Rugby.Test.Suite).Build(593),f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId),comp=##class(Rugby.Service.Store).Get("Competition","league-416-2026")
    set m.status="finished",m.stage="regular",m.competitionKey=comp.id,m.homeScore=35,m.awayScore=28,m.homeStats.tries=5,m.awayStats.tries=4,f.stage="regular",f.competitionKey=comp.id
    do ##class(Rugby.Service.Store).Put("Fixture",f),##class(Rugby.Service.Matches).Settle(m)
    set f=##class(Rugby.Service.Store).Get("Fixture",m.fixtureId)
    do ..Assert((f.classification.home.total=4)&&(f.classification.away.total=1)&&(m.classification.%ToJSON()=f.classification.%ToJSON()),"Live settlement persists the same classification breakdown used by the table")
}
}
