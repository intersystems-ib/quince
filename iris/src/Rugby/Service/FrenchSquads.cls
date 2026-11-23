Class Rugby.Service.FrenchSquads Extends %RegisteredObject
{
Parameter VERSION = "2.1.0";
ClassMethod Salary(c As %DynamicObject, row As %DynamicObject, entry As %DynamicObject) As %Integer
{
    set total=0,raw=0,top=entry.competitionId=1401
    for j=0:1:entry.players.%Size()-1 {
        set r=entry.players.%Get(j)
        if ('r.%Get("matchEligible",1))&&('r.%Get("squadListed",0)) continue
        set h=##class(Rugby.Service.Rivals).Hash(c.id_"-lnr-"_r.lnrId),annual=##class(Rugby.Seed.France).Wage(r.position)*$select(top:1,1:.36)*(.6+((h#81)/100)),monthly=+$justify(annual/1200,0,0)*100,total=total+(monthly*12)
        if r.lnrId=row.lnrId set raw=monthly
    }
    set limit=$select(top:c.regulatorySalaryCap*.88,1:c.budgetReference*.43)
    quit $select(total>limit:(raw*limit/total/100)\1*100,1:raw)
}
ClassMethod Calibrate(p As %DynamicObject, row As %DynamicObject, origin As %DynamicObject, evidence As %String)
{
    if p.%Get("lnrCalibrationVersion")=evidence quit
    set h=##class(Rugby.Service.Rivals).Hash(p.id),base=p.%Get("lnrBaseTarget",origin.qualitySeniorTarget),oldRef=p.%Get("lnrReference",{}),oldPos=p.position,pos=$select(row.%Get("positionEvidence")="LNR-starter-vote":row.position,1:p.position)
    if p.%Get("lnrCalibrationVersion")="" { set before=##class(Rugby.Seed.France).Attributes(base+((h#7)-3),oldPos,h,oldRef) }
    else { set before=##class(Rugby.Seed.France).Calibrated(base,oldPos,h,oldRef) }
    set after=##class(Rugby.Seed.France).Calibrated(base,pos,h,row),it=after.%GetIterator()
    while it.%GetNext(.key,.value) { do p.attributes.%Set(key,##class(Rugby.Simulation.Engine).Clamp(p.attributes.%Get(key)+value-before.%Get(key),1,100)) }
    set p.position=pos,p.positionSource=row.positionEvidence,p.secondary=row.%Get("secondary",[]),p.lnrReference=row,p.lnrBaseTarget=base,p.lnrCalibrationVersion=evidence,p.frontRowQualifications=[]
    for front=1:1:3 { if (front=pos)||(row.positionCounts.%Get(front,0)>0) do p.frontRowQualifications.%Push(front) }
}
ClassMethod Rebalance(c As %DynamicObject)
{
    set s=##class(Rugby.Service.Store).Get("FinancialSeason",c.id_"-finance-"_##class(Rugby.Service.Seasons).Year(c.id),0),o=##class(Rugby.Service.Store).Get("FinancialOffice",c.id,0)
    if ('$isobject(s))||('$isobject(o)) quit
    if '$isobject(s.%Get("community")) quit
    set p=s.community
    do p.%Remove("frenchBalanceVersion")
    set forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),wages=##class(Rugby.Service.FrenchFinanceBalance).Wages(c,##class(Rugby.Service.MonthlyPayroll).Totals(c.id)),budget=##class(Rugby.Service.Finance).Budget(c),margin=##class(Rugby.Service.FrenchFinanceBalance).TargetMargin(c,s,o)
    if c.%Get("startDay",c.day)>##class(Rugby.Service.SeasonCalendar).Day(s.year_"-09-01") set budget=budget*wages.activeMonths/12
    set count=forecast.community.balanceInstalments,excess=forecast.projectedCosts-(budget*(1-margin))
    // Restore the original payroll capacity using only unpaid structural costs.
    if (excess>0)&&(count>0) {
        set old=p.annualCosts,p.annualCosts=##class(Rugby.Simulation.Engine).Clamp(old-(excess*10/count),0,old),ratio=$select(old>0:p.annualCosts/old,1:1)
        for key="annualCoachingCosts","annualFederationTravelCosts","annualFacilitiesCosts" { do p.%Set(key,+$justify(p.%Get(key,0)*ratio,0,0)) }
        set c.communityCostReference=p.annualCosts,c.communityBudgetReference=p.referenceBudget
        do ##class(Rugby.Service.Store).Put("Club",c)
    }
    set s.community=p
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
    set changed=##class(Rugby.Service.FrenchFinanceBalance).Adopt(c,s,o)
}
ClassMethod Apply() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"restored":0,"created":0,"calibrated":0,"clubs":[]},catalog=##class(Rugby.Seed.France).File("french-leagues"),version=..#VERSION_"-"_catalog.evidenceVersion
    if $get(^RugbyWorld(game,"frenchSquadVersion"))=version quit report
    set identities={},players=##class(Rugby.Service.Store).All("Player"),busy={},matches=##class(Rugby.Service.Store).All("Match")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.%Get("identitySource")="LNR" do identities.%Set(p.identitySourceId,p.id) }
    for i=0:1:matches.%Size()-1 { set m=matches.%Get(i) if m.status'="finished" { do busy.%Set(m.homeId,1),busy.%Set(m.awayId,1) } }
    for i=0:1:catalog.clubs.%Size()-1 {
        set entry=catalog.clubs.%Get(i),c=##class(Rugby.Service.Store).Get("Club",entry.id,0),restored=0,created=0
        if '$isobject(c) continue
        set current=##class(Rugby.Service.Store).All("Player","clubId",c.id),pool=0
        for j=0:1:current.%Size()-1 { set member=current.%Get(j) if member.category="senior" set pool=pool+member.monthlyWage }
        for j=0:1:entry.players.%Size()-1 {
            set row=entry.players.%Get(j)
            if ('row.%Get("matchEligible",0))&&('row.%Get("squadListed",0)) continue
            set pid=identities.%Get(row.lnrId),p="",changed=0
            if pid'="" set p=##class(Rugby.Service.Store).Get("Player",pid)
            if '$isobject(p) {
                set p=##class(Rugby.Seed.France).Player(c,row,j,catalog.identityVersion,catalog.evidenceVersion),p.monthlyWage=0,p.weeklyWage=0,created=created+1,changed=1
                do identities.%Set(row.lnrId,p.id)
            }
            elseif p.%Get("rosterArchived",0)&&(p.%Get("archivedReason")="outsideFrenchMatchSquad")&&(p.clubId="")&&(p.%Get("contractStatus")="archived")&&(p.archivedClubId=c.id) {
                set p.clubId=c.id,p.contractStatus="employed",p.monthlyWage=..Salary(c,row,entry),p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),p.payrollStartDay=c.day,p.salaryEffectiveDay=c.day,p.salaryBeforeAdjustment=0,p.rosterArchived=0,p.transferMarketRemoved=0,p.transferListed=0
                set h=##class(Rugby.Service.Rivals).Hash(p.id),startYear=##class(Rugby.Service.Competition).Year(##class(Rugby.Service.Injuries).Date(c.%Get("startDay",c.day))),endYear=startYear+(h#4),currentYear=##class(Rugby.Service.Seasons).Year(c.id)
                if endYear<currentYear set endYear=currentYear+(h#3)
                do ##class(Rugby.Service.Seasons).Contract(p,endYear)
                for key="archivedClubId","archivedOn","archivedReason" { do p.%Remove(key) }
                set restored=restored+1,changed=1
            }
            if p.%Get("lnrCalibrationVersion")'=catalog.evidenceVersion {
                do ..Calibrate(p,row,c,catalog.evidenceVersion)
                set changed=1,report.calibrated=report.calibrated+1
            }
            if changed do ##class(Rugby.Service.Store).Put("Player",p)
        }
        if created>0 do ##class(Rugby.Service.SpanishMatchEvidence).SpreadPayroll(c.id,pool,"LNR")
        set c=##class(Rugby.Service.Store).Get("Club",c.id),roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),count=0
        for j=0:1:roster.%Size()-1 { if roster.%Get(j).category="senior" set count=count+1 }
        set c.rosterIdentityCount=count,c.frenchSquadVersion=version
        do ##class(Rugby.Service.Store).Put("Club",c)
        if (restored+created)>0 do ..Rebalance(c)
        if (c.id'=##class(Rugby.Service.Store).ManagedClub())&&('busy.%IsDefined(c.id)) do ##class(Rugby.Service.Rivals).Lineup(c)
        set report.restored=report.restored+restored,report.created=report.created+created
        do report.clubs.%Push({"clubId":(c.id),"restored":(restored),"created":(created),"seniorPlayers":(count)})
    }
    set ^RugbyWorld(game,"frenchSquadVersion")=version
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando convocatorias francesas.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 {
            set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1"
            if %RugbyGame'="template" set %RugbyManagedClub=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)).clubId
            do reports.%Push(..Apply())
        }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
