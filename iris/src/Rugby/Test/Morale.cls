Class Rugby.Test.Morale Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set players=##class(Rugby.Service.Store).All("Player"),clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:players.%Size()-1 { do ..Assert(players.%Get(i).morale=100,"All initial seniors, academies and free agents start at one hundred") }
    set p=##class(Rugby.Service.Store).Get("Player","c1-p4"),raw=p.attributes.%ToJSON()
    do p.%Remove("moraleVersion")
    do ##class(Rugby.Service.Morale).Prepare(p,0)
    set r=##class(Rugby.Service.Morale).Daily(p,14)
    do ..Assert(p.morale=100,"Fourteen days of grace")
    set r=##class(Rugby.Service.Morale).Daily(p,15),r=##class(Rugby.Service.Morale).Daily(p,15)
    do ..Assert(p.morale=99,"Daily idle loss is once only")
    set r=##class(Rugby.Service.Morale).Daily(p,18)
    do ..Assert((p.morale=96)&&(p.attributes.%ToJSON()=raw),"Skipped days charge consistently without changing skills")
    set p.lastAppearanceDay=18,r=##class(Rugby.Service.Morale).Daily(p,32)
    do ..Assert(p.morale=96,"Any actual minutes renew the grace period")
    set r=##class(Rugby.Service.Morale).Daily(p,33)
    do ..Assert(p.morale=95,"Idle loss resumes after the renewed grace")
    // The rule affects every roster member, not only the match sheet.
    for cid="c1","c2","c11","c12" {
        set roster=##class(Rugby.Service.Store).All("Player","clubId",cid)
        for i=0:1:roster.%Size()-1 { set p=roster.%Get(i),p.morale=60 do ##class(Rugby.Service.Store).Put("Player",p) }
        set pid=cid_"-p4",report=##class(Rugby.Service.Morale).Result(cid,100,"morale-win-"_cid,"win",[{"playerId":(pid),"playedSeconds":20}]),roster=##class(Rugby.Service.Store).All("Player","clubId",cid)
        for i=0:1:roster.%Size()-1 { do ..Assert(roster.%Get(i).morale=100,"Victory restores the full roster in both divisions") }
        set p=##class(Rugby.Service.Store).Get("Player",pid),bench=##class(Rugby.Service.Store).Get("Player",cid_"-p16")
        do ..Assert((p.lastAppearanceDay=100)&&('bench.%IsDefined("lastAppearanceDay")),"Only a player with minutes gains an appearance")
        set once=p.matchAppearances,again=##class(Rugby.Service.Morale).Result(cid,100,"morale-win-"_cid,"win",[{"playerId":(pid),"playedSeconds":20}]),p=##class(Rugby.Service.Store).Get("Player",pid)
        do ..Assert(p.matchAppearances=once,"Settlement replay does not duplicate appearances")
        set report=##class(Rugby.Service.Morale).Result(cid,101,"morale-loss-"_cid,"loss",[]),report=##class(Rugby.Service.Morale).Result(cid,102,"morale-loss2-"_cid,"loss",[]),roster=##class(Rugby.Service.Store).All("Player","clubId",cid)
        for i=0:1:roster.%Size()-1 { do ..Assert(roster.%Get(i).morale=90,"Two defeats lower the entire team by ten, including academy and reserves") }
    }
    set m=##class(Rugby.Test.Suite).Build(593),pid=m.homePlayers.%Get(0).playerId,benchId=m.homePlayers.%Get(15).playerId,m.homeScore=20,m.awayScore=0,m.homeStats.tries=4
    for i=0:1:m.homePlayers.%Size()-1 { set s=m.homePlayers.%Get(i),s.morale=40 if s.status="field" set s.playedSeconds=20 }
    do ##class(Rugby.Service.Matches).Settle(m)
    set p=##class(Rugby.Service.Store).Get("Player",pid),bench=##class(Rugby.Service.Store).Get("Player",benchId),lost=##class(Rugby.Service.Store).Get("Player","c2-p4")
    do ..Assert((p.morale=100)&&(bench.morale=100)&&(lost.morale=85),"Live settlement uses victory/loss rules for both full squads")
    do ..Assert(p.%IsDefined("lastAppearanceDay")&&('bench.%IsDefined("lastAppearanceDay")),"Unused live bench is not credited with minutes")
    set c=##class(Rugby.Service.Store).Get("Club","c11"),f={"id":"morale-auto","homeId":"c11","awayId":"c12","day":(c.day),"date":(c.date),"winnerId":"c12","disciplineParticipants":[{"side":"home","playerId":"c11-p4","playedSeconds":4800},{"side":"away","playerId":"c12-p4","playedSeconds":4800}]}
    do ##class(Rugby.Service.Rivals).SettleFixture(f)
    set p=##class(Rugby.Service.Store).Get("Player","c11-p24"),q=##class(Rugby.Service.Store).Get("Player","c12-p24")
    do ..Assert((p.morale=85)&&(q.morale=100),"Automated fixture applies identical rules beyond the match squad")
    set before=p.morale
    do ##class(Rugby.Service.Rivals).SettleFixture(f)
    set p=##class(Rugby.Service.Store).Get("Player","c11-p24")
    do ..Assert(p.morale=before,"Automated result is idempotent")
    set report=##class(Rugby.Service.Morale).Initialize(),p=##class(Rugby.Service.Store).Get("Player","c11-p24")
    do ..Assert((report.players=0)&&(p.morale=before),"Bootstrap never resets an already initialized world's morale")
}
}
