Class Rugby.Service.SpanishMatchEvidence Extends %RegisteredObject
{
Parameter VERSION = "2.0.0";
ClassMethod Player(row As %DynamicObject, c As %DynamicObject) As %DynamicObject
{
    set h=##class(Rugby.Service.Rivals).Hash(row.playerId),pos=row.position,target=c.qualitySeniorTarget,attrs=##class(Rugby.Seed.France).Attributes(target,pos,h,{}),it=attrs.%GetIterator(),sum=0
    while it.%GetNext(.key,.value) { set sum=sum+value }
    set shift=target+((h#7)-3)-(sum/17),it=attrs.%GetIterator()
    while it.%GetNext(.key,.value) { do attrs.%Set(key,##class(Rugby.Simulation.Engine).Clamp(value+shift,1,100)) }
    set age=20+(h#13),p={"id":(row.playerId),"clubId":(c.id),"name":(row.name),"realIdentity":true,"identitySource":"FER","identitySourceId":(row.ferId),"identityClubId":(row.clubId),"identitySourceUrl":(row.sourceUrl),"identitySeason":"2026/2027","nationality":"No verificada","nationalityCode":"","nationalitySource":"unknown","age":(age),"ageSource":"simulation","birthDay":(c.day-(age*365)),"category":"senior","position":(pos),"positionSource":(row.positionEvidence),"secondary":(row.secondary),"frontRowQualifications":(row.frontRowQualifications),"attributes":(attrs),"attributesSource":"FER-reference-simulation","morale":100,"energy":100,"available":true,"recoveryDay":0,"weeklyWage":0,"monthlyWage":0,"payrollStartDay":(c.day),"developmentYear":-1,"developmentGains":{},"developmentCeiling":99,"talentScaleVersion":(##class(Rugby.Service.TalentScale).#VERSION),"talentScaleFactor":(##class(Rugby.Service.TalentScale).#FACTOR),"ferExpandedSeed":true}
    do ##class(Rugby.Service.Seasons).Contract(p,##class(Rugby.Service.Seasons).Year(c.id)+(h#4))
    quit p
}
ClassMethod SpreadPayroll(club As %String, pool As %Numeric, source As %String = "FER")
{
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),flex=[],weight=0,fixed=0,c=##class(Rugby.Service.Store).Get("Club",club)
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if p.category'="senior" continue
        if (p.%Get("identitySource")'=source)||p.%IsDefined("signedDay")||p.%IsDefined("renewedDay") { set fixed=fixed+p.monthlyWage continue }
        set reference=p.%Get($select(source="LNR":"lnrReference",1:"ferReference"),{}),participation=reference.%Get("participationScore",.5)
        if source="LNR" set participation=##class(Rugby.Simulation.Engine).Clamp(reference.%Get("minutes",0)/(80*$select(reference.%Get("referenceGames",0)>0:reference.referenceGames,1:1)),0,1)
        set w=##class(Rugby.Service.Development).Average(p)**2*(.6+(.4*participation))
        if source="LNR" set w=w*##class(Rugby.Seed.France).Wage(p.position)/25000000
        do flex.%Push({"player":(p),"weight":(w)})
        set weight=weight+w
    }
    set prefix=$select(source="LNR":"lnr",1:"fer")
    do c.%Set(prefix_"RosterMonthlyBudget",pool),c.%Set(prefix_"ExpandedPayrollVersion",..#VERSION),##class(Rugby.Service.Store).Put("Club",c)
    set room=pool-fixed,used=0
    if (room<0)||(weight<=0) quit
    for i=0:1:flex.%Size()-1 {
        set item=flex.%Get(i),p=item.player,old=p.monthlyWage,amount=$select(i=(flex.%Size()-1):room-used,1:(room*item.weight/weight)\1),used=used+amount
        if amount'=old set p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(amount)
        set p.monthlyWage=amount,p.salaryBeforeAdjustment=old,p.salaryEffectiveDay=c.day
        do p.%Set(prefix_"ExpandedPayrollVersion",..#VERSION)
        do ##class(Rugby.Service.Store).Put("Player",p)
    }
}
ClassMethod Apply() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"players":0,"clubs":0,"created":0},catalog=##class(Rugby.Seed.France).File("spanish-match-evidence")
    if $get(^RugbyWorld(game,"spanishMatchEvidenceVersion"))=(..#VERSION_"-"_catalog.version) quit report
    set clubs={},pools={},expanded={},busy={},matches=##class(Rugby.Service.Store).All("Match"),versions={}
    for i=0:1:matches.%Size()-1 { set m=matches.%Get(i) if m.status'="finished" { do busy.%Set(m.homeId,1),busy.%Set(m.awayId,1) } }
    for i=0:1:catalog.players.%Size()-1 {
        set row=catalog.players.%Get(i),p=##class(Rugby.Service.Store).Get("Player",row.playerId,0)
        if '$isobject(p) {
            set c=##class(Rugby.Service.Store).Get("Club",row.clubId)
            if 'pools.%IsDefined(c.id) {
                set roster=##class(Rugby.Service.Store).All("Player","clubId",c.id),pool=0
                for j=0:1:roster.%Size()-1 { set member=roster.%Get(j) if member.category="senior" set pool=pool+member.monthlyWage }
                do pools.%Set(c.id,pool)
            }
            set p=..Player(row,c),report.created=report.created+1
            do expanded.%Set(c.id,1)
        }
        if (p.%Get("identitySource")'="FER")||(p.%Get("ferCalibrationVersion")=catalog.version) continue
        set prior=p.%Get("ferCalibrationChanges",{}),changes={},it=row.attributeOffsets.%GetIterator()
        while it.%GetNext(.key,.offset) {
            set base=p.attributes.%Get(key)-prior.%Get(key,0),value=##class(Rugby.Simulation.Engine).Clamp(base+offset,1,100)
            do p.attributes.%Set(key,value),changes.%Set(key,value-base)
        }
        set p.ferReference=row,p.ferCalibrationVersion=catalog.version,p.ferCalibrationChanges=changes,p.attributesSource="FER-reference-simulation"
        if row.positionCounts.%Size()>0 {
            set p.position=row.position,p.positionSource="FER-starter-vote",secondary={},values=[]
            for j=0:1:p.secondary.%Size()-1 { do secondary.%Set(p.secondary.%Get(j),1) }
            for j=0:1:row.secondary.%Size()-1 { do secondary.%Set(row.secondary.%Get(j),1) }
            set it=secondary.%GetIterator()
            while it.%GetNext(.pos,.flag) { if +pos'=p.position do values.%Push(+pos) }
            set p.secondary=values
        }
        do versions.%Set(p.id,p.version),##class(Rugby.Service.Store).Put("Player",p),clubs.%Set(row.clubId,1)
        set report.players=report.players+1
    }
    set it=expanded.%GetIterator()
    while it.%GetNext(.id,.flag) { do ..SpreadPayroll(id,pools.%Get(id)) }
    // Attribute refreshes do not invalidate a pending salary offer.
    set negotiations=##class(Rugby.Service.Store).All("Negotiation")
    for i=0:1:negotiations.%Size()-1 { set n=negotiations.%Get(i) if versions.%IsDefined(n.playerId)&&(n.%Get("playerVersion",-1)=versions.%Get(n.playerId)) { set n.playerVersion=##class(Rugby.Service.Store).Get("Player",n.playerId).version do ##class(Rugby.Service.Store).Put("Negotiation",n) } }
    set it=clubs.%GetIterator(),initial=(game="template")||('$data(^RugbyGames(game)))
    while it.%GetNext(.id,.flag) {
        set c=##class(Rugby.Service.Store).Get("Club",id),roster=##class(Rugby.Service.Store).All("Player","clubId",id),count=0
        for j=0:1:roster.%Size()-1 { if roster.%Get(j).category="senior" set count=count+1 }
        set c.rosterIdentityCount=count,c.rosterSource="FER · Actas de varias jornadas"
        do ##class(Rugby.Service.Store).Put("Club",c)
        if (initial||(id'=##class(Rugby.Service.Store).ManagedClub()))&&('busy.%IsDefined(id)) do ##class(Rugby.Service.Rivals).Lineup(c)
        set report.clubs=report.clubs+1
    }
    set ^RugbyWorld(game,"spanishMatchEvidenceVersion")=..#VERSION_"-"_catalog.version
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando referencias de las actas españolas.")
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
