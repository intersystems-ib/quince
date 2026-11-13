Class Rugby.Test.OpponentPreparation Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run()
{
    set club=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",club),fixtures=##class(Rugby.Service.Competition).ClubFixtures(club),f=""
    for i=0:1:fixtures.%Size()-1 { set row=fixtures.%Get(i) if (row.stage="regular")&&(row.status="scheduled") { set f=row quit } }
    do ..Assert($isobject(f),"An official fixture exists")
    set c.day=f.day-3,c.date=$zdate(c.day+$zdateh("2026-11-07",3),3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set meetings=##class(Rugby.Service.OpponentPreparation).List(club),found=0
    for i=0:1:meetings.items.%Size()-1 { set meeting=meetings.items.%Get(i) if meeting.fixtureId=f.id { set found=(meeting.day=f.day-2)&&('meeting.available) } }
    do ..Assert(found,"Calendar meeting is scheduled exactly two days before the match")
    set caught=0
    try { set result=##class(Rugby.Service.OpponentPreparation).Report(f.id) } catch ex { set caught=ex.Location="PREPARATION_FUTURE" }
    do ..Assert(caught,"Report cannot be read before the meeting")
    set c.day=f.day-2,c.date=$zdate(c.day+$zdateh("2026-11-07",3),3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set players=##class(Rugby.Service.Store).All("Player").%ToJSON(),lineups=##class(Rugby.Service.Store).All("Lineup").%ToJSON(),ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON(),report=##class(Rugby.Service.OpponentPreparation).Report(f.id),again=##class(Rugby.Service.OpponentPreparation).Report(f.id)
    do ..Assert((report.%ToJSON()=again.%ToJSON())&&(report.aspects.%Size()=5),"Report is deterministic and compares five rugby aspects")
    do ..Assert((report.groups.own.forwards.count=8)&&(report.groups.own.backs.count=7),"Analysis follows occupied forward and back slots")
    do ..Assert((players=##class(Rugby.Service.Store).All("Player").%ToJSON())&&(lineups=##class(Rugby.Service.Store).All("Lineup").%ToJSON()),"Opening the meeting never changes players or lineups")
    do ..Assert(report.recommendation.tactic.%ToJSON()'=report.alternative.tactic.%ToJSON(),"There is a distinct tactical alternative")
    set l=##class(Rugby.Service.Store).Get("Lineup",report.lineupId),slots=l.slots.%ToJSON(),bench=l.bench.%ToJSON(),input={"lineupId":(report.lineupId),"lineupVersion":(report.lineupVersion),"reportToken":(report.reportToken),"choice":"main"},applied=##class(Rugby.Service.OpponentPreparation).Apply(f.id,input,"prep-apply"),retry=##class(Rugby.Service.OpponentPreparation).Apply(f.id,input,"prep-apply"),saved=##class(Rugby.Service.Store).Get("Lineup",l.id)
    do ..Assert((saved.tactic.%ToJSON()=report.recommendation.tactic.%ToJSON())&&(saved.slots.%ToJSON()=slots)&&(saved.bench.%ToJSON()=bench),"Applying only changes the selected lineup tactic")
    do ..Assert((applied.lineupVersion=retry.lineupVersion)&&('applied.lastApplied.outdated),"Applying is retry safe and does not invalidate its own analysis")
    do ..Assert((players=##class(Rugby.Service.Store).All("Player").%ToJSON())&&(ledger=##class(Rugby.Service.Store).All("FinancialMovement").%ToJSON()),"No meeting bonuses, fatigue, expenses or income are generated")
    set p=##class(Rugby.Service.Store).Get("Player",l.slots.%Get(0).playerId),p.energy=20
    do ##class(Rugby.Service.Store).Put("Player",p)
    set fresh=##class(Rugby.Service.OpponentPreparation).Report(f.id),caught=0
    do ..Assert(fresh.lastApplied.outdated&&(fresh.aspects.%Get(0).own<report.aspects.%Get(0).own),"Energy changes recalculate the report and mark an old assessment")
    try { set ignored=##class(Rugby.Service.OpponentPreparation).Apply(f.id,input,"prep-stale") } catch ex { set caught=ex.Location="PREPARATION_CHANGED" }
    do ..Assert(caught,"Stale recommendations cannot overwrite a newer lineup")
    set q=##class(Rugby.Service.Staff).Qualities(club),low=##class(Rugby.Service.OpponentPreparation).Probable(report.opponentId,f.id,q)
    for role="head","forwards","backs","defense","attack","skills","fitness" { do q.%Set(role,100) }
    set high=##class(Rugby.Service.OpponentPreparation).Probable(report.opponentId,f.id,q)
    do ..Assert(low.%ToJSON()'=high.%ToJSON(),"Staff quality changes estimation accuracy")
    set injured=##class(Rugby.Service.Store).Get("Player",high.%Get(0).playerId),injured.available=0
    do ##class(Rugby.Service.Store).Put("Player",injured)
    set probable=##class(Rugby.Service.OpponentPreparation).Probable(report.opponentId,f.id,q),found=0
    for i=0:1:probable.%Size()-1 { if probable.%Get(i).playerId=injured.id set found=1 }
    do ..Assert('found,"Probable rival lineup excludes unavailable players")
    set p.energy=100
    do ##class(Rugby.Service.Store).Put("Player",p)
    set custom=##class(Rugby.Service.Store).Get("Lineup",l.id),custom.id="preparation-custom",custom.name="XV alternativo"
    do ##class(Rugby.Service.Store).Put("Lineup",custom)
    set report=##class(Rugby.Service.OpponentPreparation).Report(f.id,custom.id),chosen={"style":"kicking","tempo":"slow","defense":"low"},result=##class(Rugby.Service.OpponentPreparation).Apply(f.id,{"lineupId":(custom.id),"lineupVersion":(report.lineupVersion),"reportToken":(report.reportToken),"choice":"custom","tactic":(chosen)},"prep-custom")
    set c=##class(Rugby.Service.Store).Get("Club",club),c.day=f.day,c.date=f.date
    do ##class(Rugby.Service.Store).Put("Club",c)
    set match=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id)},"prep-match")
    do ..Assert(match.lineupId=custom.id,"Match creation defaults to the lineup prepared in the meeting")
    set report=##class(Rugby.Service.OpponentPreparation).Report(f.id),caught=0
    do ..Assert(report.lineupLocked&&(report.currentTactic.%ToJSON()=chosen.%ToJSON()),"Scheduled match preview keeps the chosen plan")
    set match.status="first"
    do ##class(Rugby.Service.Store).Put("Match",match)
    try { set ignored=##class(Rugby.Service.OpponentPreparation).Report(f.id) } catch ex { set caught=ex.Location="PREPARATION_CLOSED" }
    do ..Assert(caught,"Meeting closes when the match starts")
    set friendly=##class(%DynamicObject).%FromJSON(f.%ToJSON()),friendly.stage="friendly",friendly.id="prep-friendly",friendly.matchId=""
    do ##class(Rugby.Service.Store).Put("Fixture",friendly)
    do ..Assert('##class(Rugby.Service.OpponentPreparation).Official(friendly),"Friendlies do not generate official preparation meetings")
    set friendly.stage="quarterfinal"
    do ..Assert(##class(Rugby.Service.OpponentPreparation).Official(friendly),"Cup knockout ties support preparation")
}
}
