Class Rugby.Test.WeeklyTraining Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set club=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",club),c.date="2026-09-07",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set old=##class(Rugby.Service.Store).Get("TrainingPlan",club),original=old.%ToJSON(),view=##class(Rugby.Service.WeeklyTraining).View(club)
    do ..Assert((original=##class(Rugby.Service.Store).Get("TrainingPlan",club).%ToJSON())&&(view.weekly.senior.%Size()=7),"Reading offers a full week without replacing a legacy plan")
    set weekly=##class(Rugby.Service.WeeklyTraining).Defaults()
    for day=0:1:6 { set weekly.senior.%Get(day).theme="physical",weekly.academy.%Get(day).theme="attack" }
    set saved=##class(Rugby.Service.Development).Save(club,{"version":(old.version),"mode":"weekly","weekly":(weekly)}),context=##class(Rugby.Service.WeeklyTraining).Context(club,saved),fw=##class(Rugby.Service.Store).Get("Player",club_"-p1"),back=##class(Rugby.Service.Store).Get("Player",club_"-p10")
    set fw.available=1,fw.energy=100,back.available=1,back.energy=100,fw.age=22,fw.birthDay=c.day-(22*365)
    do fw.%Remove("injury"),back.%Remove("injury")
    set g=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context),gb=##class(Rugby.Service.WeeklyTraining).Group(back,c.day,context),repeat=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day+7,context)
    do ..Assert((g.focus="strength")&&(gb.focus="speed")&&(g.focus=repeat.focus)&&(g.weekday=1),"Monday physical work differs by line and repeats next week")
    set fw.category="academy",ga=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context)
    do ..Assert(ga.focus="maul","Academy follows its own weekly theme")
    set fw.category="senior",fw.energy=40,g=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context)
    do ..Assert(g.focus="recovery","Staff protect low energy")
    set fw.energy=70,g=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context)
    do ..Assert(g.intensity="low","Staff reduce intensity before exhaustion")
    set fw.energy=100,fw.birthDay=c.day-(34*365),g=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context)
    do ..Assert(g.intensity="low","Senior players get an age-appropriate load")
    set fw.birthDay=c.day-(22*365),fw.available=0,g=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context)
    do ..Assert(g.focus="recovery","Unavailable players rest")
    set fw.available=1
    do context.matchDays.%Set(c.day,1)
    set g=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context),fw.category="academy",ga=##class(Rugby.Service.WeeklyTraining).Group(fw,c.day,context)
    do ..Assert((g.focus="recovery")&&(ga.focus="maul"),"Only seniors rest for first-team fixtures")
    set fw.category="senior",fw.id="weekly-new-player"
    do ##class(Rugby.Service.Store).Put("Player",fw)
    set groups=##class(Rugby.Service.WeeklyTraining).Groups(club,saved,c.day),found=0,total=0
    for i=0:1:groups.%Size()-1 { set g=groups.%Get(i) for j=0:1:g.playerIds.%Size()-1 { set total=total+1 if g.playerIds.%Get(j)=fw.id set found=found+1 } }
    do ..Assert((found=1)&&(total=##class(Rugby.Service.Store).All("Player","clubId",club).%Size()),"New arrivals and every squad member receive exactly one session")
    set before=fw.attributes.strength,balance=c.balance,execution=##class(Rugby.Service.Development).Process(club,c.day),fw=##class(Rugby.Service.Store).Get("Player",fw.id),snapshot=fw.%ToJSON(),count=##class(Rugby.Service.Store).All("TrainingExecution").%Size(),retry=##class(Rugby.Service.Development).Process(club,c.day)
    do ..Assert((fw.attributes.strength>before)&&(execution.mode="weekly")&&(execution.groups.%Size()>0),"Daily execution uses resolved weekly drills")
    do ..Assert((snapshot=##class(Rugby.Service.Store).Get("Player",fw.id).%ToJSON())&&(retry.%ToJSON()=execution.%ToJSON())&&(count=##class(Rugby.Service.Store).All("TrainingExecution").%Size())&&(balance=##class(Rugby.Service.Store).Get("Club",club).balance),"Retry never repeats training or charges daily fees")
    set p=##class(Rugby.Service.Store).Get("Player",club_"-p1"),p.available=1,p.energy=100,p.age=22,p.birthDay=c.day-(22*365),q=##class(Rugby.Service.Staff).Qualities(club),rest=##class(%DynamicObject).%FromJSON(saved.%ToJSON())
    for i=0:1:6 { set rest.weekly.senior.%Get(i).theme="rest" }
    set actual=##class(Rugby.Service.Development).Profile(##class(%DynamicObject).%FromJSON(p.%ToJSON()),c,saved,q),resting=##class(Rugby.Service.Development).Profile(##class(%DynamicObject).%FromJSON(p.%ToJSON()),c,rest,q)
    do ..Assert((actual.potential>resting.potential)&&($zabs(resting.potential-p.average)<.00001),"Season potential respects the recurring week and rest")
    for invalid="missing","duplicate","theme","shape" {
        set bad=##class(Rugby.Service.WeeklyTraining).Defaults(),failed=0
        if invalid="missing" do bad.senior.%Pop()
        if invalid="duplicate" set bad.senior.%Get(1).day=1
        if invalid="theme" set bad.senior.%Get(1).theme="football"
        if invalid="shape" do bad.senior.%Set(1,[])
        try { set ignore=##class(Rugby.Service.WeeklyTraining).Validate(bad) } catch ex { set failed=ex.Code=422 }
        do ..Assert(failed,"Malformed weekly plan rejected: "_invalid)
    }
}
}
