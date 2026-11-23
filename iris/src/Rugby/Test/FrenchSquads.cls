Class Rugby.Test.FrenchSquads Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run() As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="fr-clermont",report={"clubs":0,"seniorPlayers":0,"restoration":false},catalog=##class(Rugby.Seed.France).File("french-leagues")
    tstart
    try {
        for i=0:1:catalog.clubs.%Size()-1 {
            set entry=catalog.clubs.%Get(i),c=##class(Rugby.Service.Store).Get("Club",entry.id),roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),l=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),senior=0,academy=0,ids={}
            for j=0:1:roster.%Size()-1 {
                set p=roster.%Get(j)
                if p.category="academy" { set academy=academy+1 continue }
                set senior=senior+1
                do ..Assert((p.lnrReference.matchEligible||p.lnrReference.%Get("squadListed",0)),"Every imported player has a match sheet or official squad entry")
                do ..Assert('ids.%IsDefined(p.identitySourceId),"No duplicate LNR identities")
                do ids.%Set(p.identitySourceId,1)
                do ..Assert(p.nationalityCode'="","Imported nationalities have canonical codes")
            }
            do ..Assert(senior=entry.players.%Size(),"All verified match and official squad players are retained")
            do ..Assert(senior>(l.slots.%Size()+l.bench.%Size()),"Squad depth is independent of one match lineup")
            do ..Assert(academy=20,"French academy preserved")
            do ..Assert(##class(Rugby.Service.Management).Validate(l).valid,"Evidence-weighted initial XV and bench are valid")
            set report.clubs=report.clubs+1,report.seniorPlayers=report.seniorPlayers+senior
        }
        set c=##class(Rugby.Service.Store).Get("Club","fr-clermont"),l=##class(Rugby.Service.Store).Get("Lineup",c.id_"-default"),lineup=l.%ToJSON(),roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),p=roster.%Get(0),found=0
        for j=0:1:roster.%Size()-1 { set candidate=roster.%Get(j) if candidate.category="senior" { set p=candidate,found=1 quit } }
        do ..Assert(found,"Reference senior exists")
        set original=##class(%DynamicObject).%FromJSON(p.%ToJSON()),p.archivedClubId=c.id,p.archivedReason="outsideFrenchMatchSquad",p.clubId="",p.contractStatus="archived",p.contractEndDate=c.date,p.weeklyWage=0,p.monthlyWage=0,p.rosterArchived=1,p.transferMarketRemoved=1
        do ##class(Rugby.Service.Store).Put("Player",p)
        set spanish=##class(Rugby.Service.Store).All("Player","clubId","c4").%ToJSON(),cash=c.balance,movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()
        kill ^RugbyWorld("template","frenchSquadVersion")
        set result=##class(Rugby.Service.FrenchSquads).Apply(),restored=##class(Rugby.Service.Store).Get("Player",p.id)
        do ..Assert((result.restored=1)&&(result.created=0),"Only the erroneously archived identity is restored")
        do ..Assert((restored.clubId=c.id)&&(restored.monthlyWage>0)&&('restored.rosterArchived),"Restored senior returns to club payroll")
        do ..Assert(restored.attributes.%ToJSON()=original.attributes.%ToJSON(),"Restoration preserves developed attributes")
        do ..Assert(##class(Rugby.Service.Store).Get("Lineup",l.id).%ToJSON()=lineup,"Managed club lineup remains unchanged")
        do ..Assert(##class(Rugby.Service.Store).Get("Club",c.id).balance=cash,"Restoration does not change cash")
        do ..Assert(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%ToJSON()=movements,"No retrospective payments")
        do ..Assert(##class(Rugby.Service.Store).All("Player","clubId","c4").%ToJSON()=spanish,"Spanish rosters are unchanged")
        set again=##class(Rugby.Service.FrenchSquads).Apply()
        do ..Assert((again.restored=0)&&(again.calibrated=0),"Evidence adoption is idempotent")
        set a=##class(%DynamicObject).%FromJSON(original.%ToJSON()),b=##class(%DynamicObject).%FromJSON(original.%ToJSON()),a.lnrReference.referenceGames=10,b.lnrReference.referenceGames=10,a.lnrReference.minutes=80,b.lnrReference.minutes=640
        do a.lnrReference.positionCounts.%Set(a.position,1),b.lnrReference.positionCounts.%Set(b.position,8)
        do ..Assert(##class(Rugby.Service.Rivals).Rating(b,b.position)=##class(Rugby.Service.Rivals).Rating(a,a.position),"Match references do not override the calibrated average during selection")
        set row=##class(%DynamicObject).%FromJSON(original.lnrReference.%ToJSON()),row.ratingOffset=row.ratingOffset+1,b=##class(%DynamicObject).%FromJSON(original.%ToJSON()),before=b.attributes.passing,b.attributes.passing=before+1.25
        do ##class(Rugby.Service.FrenchSquads).Calibrate(b,row,c,"test-evidence")
        do ..Assert(b.attributes.passing=(before+2.25),"Recalibration preserves training gains")
        set report.restoration=1
        trollback
    } catch ex {
        if $tlevel trollback
        set %RugbyManagedClub="c1"
        throw ex
    }
    set %RugbyManagedClub="c1"
    quit report
}
}
