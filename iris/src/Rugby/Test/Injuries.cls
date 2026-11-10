Class Rugby.Test.Injuries Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set catalog=##class(Rugby.Service.Injuries).Catalog(),types={}
    do ..Assert(catalog.%Size()=20,"Twenty injury and severity variants")
    for i=0:1:catalog.%Size()-1 { set t=catalog.%Get(i) do types.%Set(t.id,t) do ..Assert((t.minWeeks>=1)&&(t.maxWeeks>=t.minWeeks)&&(t.grade>=1)&&(t.grade<=3),"Valid grades and week ranges") }
    set l=##class(Rugby.Service.Store).Get("Lineup","c1-default"),first=l.slots.%Get(0).playerId,l.slots.%Get(0).playerId=l.slots.%Get(1).playerId,l.slots.%Get(1).playerId=first,back=l.slots.%Get(8).playerId,l.slots.%Get(8).playerId=l.slots.%Get(9).playerId,l.slots.%Get(9).playerId=back
    set v=##class(Rugby.Service.Management).Validate(l)
    do ..Assert(v.valid,"Hooker and prop, scrum half and fly half may exchange slots")
    set saved=##class(Rugby.Service.Management).SaveLineup(l.id,l)
    do ..Assert(saved.slots.%Get(0).playerId=l.slots.%Get(0).playerId,"Flexible lineup persists")
    set p=##class(Rugby.Service.Store).Get("Player",saved.slots.%Get(0).playerId),p.position=2,p.secondary=[]
    do ##class(Rugby.Service.Store).Put("Player",p)
    set m=##class(Rugby.Test.Suite).Build(335),s=m.homePlayers.%Get(0),raw=s.attributes.%ToJSON()
    do ..Assert((s.position=1)&&(s.naturalPosition=2)&&(s.positionMoralePenalty=8),"Hooker playing prop loses morale only")
    set morale=s.morale
    do ##class(Rugby.Simulation.Performance).ApplyMorale(s)
    do ..Assert((s.morale=morale)&&(raw=s.attributes.%ToJSON()),"No repeated morale penalty or attribute change")
    set before=##class(Rugby.Simulation.Performance).Unit(m.homePlayers).%Size(),hit=##class(Rugby.Service.Injuries).Hit(m,"home",s),p=##class(Rugby.Service.Store).Get("Player",s.playerId),day=##class(Rugby.Service.Store).Get("Club","c1").day,injury=p.injury,t=types.%Get(injury.typeId)
    do ..Assert(hit&&('p.available)&&(s.status="injured")&&(injury.recoveryDay=day+(injury.weeks*7)),"Match injury removes the player and persists a week-based return date immediately")
    do ..Assert((injury.weeks>=t.minWeeks)&&(injury.weeks<=t.maxWeeks)&&(p.attributes.%ToJSON()=raw),"Seeded duration respects its injury range without reducing attributes")
    do ..Assert(##class(Rugby.Simulation.Performance).Unit(m.homePlayers).%Size()=(before-1),"Injured player cannot act or contribute to the unit")
    set v=##class(Rugby.Service.Management).Validate(saved)
    do ..Assert('v.valid,"Injured player cannot be selected")
    set incoming=m.homePlayers.%Get(15),cmd={"type":"substitution","outId":(s.playerId),"inId":(incoming.playerId)},why=##class(Rugby.Service.Matches).CheckCommand(m,cmd,"home")
    do ..Assert(why="","An injured player can be replaced by a different forward role")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set command=##class(Rugby.Service.Matches).Command(m.id,cmd,"injury-change"),m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ##class(Rugby.Service.Matches).Commands(m)
    set out=m.homePlayers.%Get(0),in=m.homePlayers.%Get(15),again=##class(Rugby.Service.Matches).CheckCommand(m,cmd,"home")
    do ..Assert((out.status="injured")&&out.substituted&&(in.status="field")&&(m.homeSubs=1)&&(again'=""),"Replacement fills the slot exactly once and keeps the injury visible")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set ok=##class(Rugby.Job.Worker).Cycle(m.id,1),checkpoint=##class(Rugby.Service.Store).Get("MatchPlayer",out.id)
    do ..Assert((checkpoint.status="injured")&&checkpoint.substituted&&$isobject(checkpoint.injury),"Worker checkpoint preserves injury and substitution")
    set qualities={"head":100,"fitness":100,"academy":100},group={"id":"strength","focus":"strength","intensity":"normal"},attrs=p.attributes.%ToJSON(),result=##class(Rugby.Service.Development).Apply(p,group,day+1,qualities)
    do ..Assert((result.attributeGain=0)&&('p.available)&&(p.attributes.%ToJSON()=attrs),"No training gains during injury")
    set recovered=##class(Rugby.Service.Injuries).Recover(p,injury.recoveryDay-1)
    do ..Assert(('recovered)&&('p.available),"No early return")
    set recovered=##class(Rugby.Service.Injuries).Recover(p,injury.recoveryDay),again=##class(Rugby.Service.Injuries).Recover(p,injury.recoveryDay)
    do ..Assert(recovered&&('again)&&p.available&&('p.%IsDefined("injury"))&&(p.injuryHistory.%Size()=1),"Exact recovery date archives the injury once")
    set p.retired=1,p.contractStatus="retired",p.available=0,recovered=##class(Rugby.Service.Injuries).Recover(p,injury.recoveryDay+50)
    do ..Assert(('recovered)&&('p.available),"Recovery cannot reactivate retired players")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p24"),p.age=20,p.energy=30,found=0
    for n=1:1:3000 {
        set a=##class(%DynamicObject).%FromJSON(p.%ToJSON()),b=##class(%DynamicObject).%FromJSON(p.%ToJSON()),first=##class(Rugby.Service.Injuries).Training(a,day+n,3,25)
        if first.%IsDefined("id") { set second=##class(Rugby.Service.Injuries).Training(b,day+n,3,25) do ..Assert((first.%ToJSON()=second.%ToJSON())&&('a.available),"Academy training injury is deterministic and blocks availability") set found=1 quit }
    }
    do ..Assert(found,"Training can actually produce injuries")
    set c=##class(Rugby.Service.Store).Get("Club","c2"),f={"id":"injuries-aggregate","homeId":"c2","awayId":"c3","date":(c.date),"day":(c.day),"stage":"friendly","status":"finished","homeScore":10,"awayScore":5,"winnerId":"c2"},found=0
    for seed=593:1:792 { set rng={"rng":(seed)},factor=##class(Rugby.Simulation.Discipline).Aggregate(f,rng) if f.matchInjuries.%Size()>0 { set found=1 quit } }
    do ..Assert(found,"A rare rival match injury can still occur")
    set copy=##class(%DynamicObject).%FromJSON(f.%ToJSON()),rng2={"rng":(seed)},second=##class(Rugby.Simulation.Discipline).Aggregate(copy,rng2)
    do ..Assert((f.%ToJSON()=copy.%ToJSON())&&(f.matchInjuries.%Size()>0),"Rival match injuries and replacements are deterministic")
    do ##class(Rugby.Service.Rivals).SettleFixture(f)
    for i=0:1:f.matchInjuries.%Size()-1 { set r=f.matchInjuries.%Get(i),p=##class(Rugby.Service.Store).Get("Player",r.playerId) do ..Assert(('p.available)&&(p.injury.id=r.injury.id),"Automated teams persist injuries too") }
    set p=##class(Rugby.Service.Store).Get("Player","c2-p1"),p.available=0,p.recoveryDay=c.day+14
    do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Rivals).Lineup(c)
    set v=##class(Rugby.Service.Management).Validate(##class(Rugby.Service.Store).Get("Lineup","c2-default"))
    do ..Assert(v.valid,"Rival lineup adapts to unavailable forwards")
}
}
