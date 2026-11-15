Class Rugby.Test.DayOptimization Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set c=##class(Rugby.Service.Store).Get("Club","c2"),day=##class(Rugby.Service.SeasonCalendar).Day("2026-09-07"),c.day=day,c.date="2026-09-07"
    do ##class(Rugby.Service.Store).Put("Club",c)
    set plan=##class(Rugby.Service.Rivals).Plan(c,day),p=##class(Rugby.Service.Store).Get("Player","c2-p1"),p.energy=100,p.available=1
    do ##class(Rugby.Service.Store).Put("Player",p)
    set again=##class(Rugby.Service.Rivals).Plan(c,day+1)
    do ..Assert(again.version=plan.version,"Daily energy changes reuse the weekly rival plan")
    set context=##class(Rugby.Service.WeeklyTraining).Context(c.id,plan),g=##class(Rugby.Service.WeeklyTraining).Group(p,day,context)
    do ..Assert(g.focus=plan.aiSessions.%Get(p.id).%Get(0),"The daily session uses the saved individual weekly focus")
    set p.energy=30,g=##class(Rugby.Service.WeeklyTraining).Group(p,day,context)
    do ..Assert(g.focus="recovery","Daily fatigue still overrides the saved plan")
    set p.energy=100,p.available=0,g=##class(Rugby.Service.WeeklyTraining).Group(p,day,context)
    do ..Assert(g.focus="recovery","Daily unavailability still overrides the saved plan")
    set p.available=1
    do context.matchDays.%Set(day,1)
    set g=##class(Rugby.Service.WeeklyTraining).Group(p,day,context)
    do ..Assert(g.focus="recovery","A newly scheduled match overrides the saved plan")
    set next=##class(Rugby.Service.Rivals).Plan(c,day+7)
    do ..Assert((next.version>plan.version)&&(next.aiWeekStart=day+7),"The next week renews the plan")
    set p.category="academy"
    do ##class(Rugby.Service.Store).Put("Player",p)
    set changed=##class(Rugby.Service.Rivals).Plan(c,day+7)
    do ..Assert((changed.version>next.version)&&('changed.aiSessions.%IsDefined(p.id)),"Roster changes invalidate the plan and academy stays automatic")
    set p.category="senior"
    do ##class(Rugby.Service.Store).Put("Player",p)
    do ##class(Rugby.Service.Rivals).Lineup(c,day)
    set l=##class(Rugby.Service.Store).Get("Lineup","c2-default"),version=l.version,selection=##class(Rugby.Service.Rivals).EnsureLineup(c,day+1)
    do ..Assert(('selection.updated)&&(##class(Rugby.Service.Store).Get("Lineup",l.id).version=version),"Quiet days preserve the rival lineup without writing it")
    set p=##class(Rugby.Service.Store).Get("Player",l.slots.%Get(0).playerId),p.available=0,p.recoveryDay=day+14
    do ##class(Rugby.Service.Store).Put("Player",p)
    set selection=##class(Rugby.Service.Rivals).EnsureLineup(c,day+1),new=##class(Rugby.Service.Store).Get("Lineup",l.id),valid=##class(Rugby.Service.Management).Validate(new)
    do ..Assert(selection.updated&&valid.valid&&(new.slots.%Get(0).playerId'=p.id),"An unavailable starter triggers an immediate legal replacement")
    set p.available=1,p.recoveryDay=0
    do ##class(Rugby.Service.Store).Put("Player",p)
    set selection=##class(Rugby.Service.Rivals).EnsureLineup(c,day+1)
    do ..Assert(selection.updated,"Recovery triggers lineup review")
    set before=##class(Rugby.Service.Store).Get("Player",p.id).%ToJSON(),p.potential=100,summary=##class(Rugby.Service.Development).Summary(p,c)
    do ..Assert(('summary.%IsDefined("potential"))&&summary.%IsDefined("average"),"Roster summaries contain the current average without projecting the season")
    set profile=##class(Rugby.Service.Development).Profile(p,c,plan,##class(Rugby.Service.Staff).Qualities(c.id))
    do ..Assert(profile.%IsDefined("potential")&&(profile.potentialDate'=""),"Individual details retain the complete season forecast")
    do ..Assert(before=##class(Rugby.Service.Store).Get("Player",p.id).%ToJSON(),"Reading summaries and forecasts never changes the player")
}
}
