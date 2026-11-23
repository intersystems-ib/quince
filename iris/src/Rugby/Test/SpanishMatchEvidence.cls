Class Rugby.Test.SpanishMatchEvidence Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",catalog=##class(Rugby.Seed.France).File("spanish-match-evidence"),report={"players":0,"clubs":0,"idempotent":false},totals={},counts={}
    tstart
    try {
        for i=0:1:catalog.players.%Size()-1 {
            set row=catalog.players.%Get(i),p=##class(Rugby.Service.Store).Get("Player",row.playerId)
            do ..Assert((p.identitySource="FER")&&(p.name=row.name),"Initial identities are preserved")
            do ..Assert((p.ferReference.selections>0)&&(p.ferReference.starts<=p.ferReference.selections),"Participation is supported by real match sheets")
            do ..Assert((p.ferReference.minutes>=0)&&(p.ferReference.minutes<=(80*p.ferReference.minutesMatches)),"Only reconstructed regulation minutes are counted")
            do ..Assert(p.ferCalibrationVersion=catalog.version,"Latest evidence is applied")
            set delta=0,it=p.ferCalibrationChanges.%GetIterator()
            while it.%GetNext(.key,.value) { set delta=delta+value }
            do totals.%Set(row.clubId,totals.%Get(row.clubId,0)+delta),counts.%Set(row.clubId,counts.%Get(row.clubId,0)+1)
            set report.players=report.players+1
        }
        set it=totals.%GetIterator()
        while it.%GetNext(.club,.delta) {
            set c=##class(Rugby.Service.Store).Get("Club",club),roster=##class(Rugby.Service.Store).All("Player","clubId",club),salary=0
            for j=0:1:roster.%Size()-1 { set member=roster.%Get(j) if member.category="senior" set salary=salary+member.monthlyWage }
            do ..Assert(salary=c.ferRosterMonthlyBudget,"Expanded squad preserves its monthly payroll total")
            set mean=delta/(counts.%Get(club)*17),l=##class(Rugby.Service.Store).Get("Lineup",club_"-default")
            do ..Assert((mean>(-.00001))&&(mean<.00001),"Each club retains its average level")
            do ..Assert(##class(Rugby.Service.Management).Validate(l).valid,"Evidence-weighted lineup respects availability and front row rules")
            set report.clubs=report.clubs+1
        }
        set result=##class(Rugby.Service.SpanishMatchEvidence).Apply()
        do ..Assert(result.players=0,"Repeated application does not compound ratings")
        set row=catalog.players.%Get(0),p=##class(Rugby.Service.Store).Get("Player",row.playerId),wage=p.monthlyWage,contract=p.contractEndDate,energy=p.energy,morale=p.morale,p.attributes.passing=p.attributes.passing+1.25,expected=p.attributes.passing
        do p.%Remove("ferCalibrationVersion"),##class(Rugby.Service.Store).Put("Player",p)
        set french=##class(Rugby.Service.Store).All("Player","clubId","fr-clermont").%ToJSON(),youth="",roster=##class(Rugby.Service.Store).All("Player","clubId",p.clubId)
        for i=0:1:roster.%Size()-1 { set candidate=roster.%Get(i) if candidate.category="academy" { set youth=candidate quit } }
        set youthJSON=youth.%ToJSON()
        kill ^RugbyWorld("template","spanishMatchEvidenceVersion")
        set applied=##class(Rugby.Service.SpanishMatchEvidence).Apply(),after=##class(Rugby.Service.Store).Get("Player",p.id)
        do ..Assert(applied.players=1,"Only stale evidence is refreshed")
        do ..Assert(after.attributes.passing=expected,"Training gains survive recalibration")
        do ..Assert((after.monthlyWage=wage)&&(after.contractEndDate=contract)&&(after.energy=energy)&&(after.morale=morale),"Wages, contracts, fitness and morale are unchanged")
        do ..Assert(##class(Rugby.Service.Store).Get("Player",youth.id).%ToJSON()=youthJSON,"Academy is unchanged")
        do ..Assert(##class(Rugby.Service.Store).All("Player","clubId","fr-clermont").%ToJSON()=french,"French ratings remain unchanged")
        set a=##class(%DynamicObject).%FromJSON(after.%ToJSON()),b=##class(%DynamicObject).%FromJSON(after.%ToJSON()),a.ferReference.referenceGames=6,b.ferReference.referenceGames=6,a.ferReference.participationScore=.2,b.ferReference.participationScore=.9
        do a.ferReference.positionCounts.%Set(a.position,1),b.ferReference.positionCounts.%Set(b.position,6)
        do ..Assert(##class(Rugby.Service.Rivals).Rating(b,b.position)=##class(Rugby.Service.Rivals).Rating(a,a.position),"Match references do not override the calibrated average during selection")
        set b.position=12,b.ferReference.positionCounts={"12":3,"13":2},b.id="test-fer-versatile",used={}
        do ..Assert(##class(Rugby.Service.Rivals).Pick([(b)],used,13,1)=b.id,"Observed secondary starting roles are eligible for AI selection")
        set report.idempotent=1
        trollback
    } catch ex {
        if $tlevel trollback
        throw ex
    }
    quit report
}
}
