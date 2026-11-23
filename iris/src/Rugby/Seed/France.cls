Class Rugby.Seed.France Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod File(name As %String) As %DynamicObject
{
    set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8",sc=stream.LinkToFile("/opt/rugby/data/"_name_".json")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    quit ##class(%DynamicObject).%FromJSON(stream)
}
ClassMethod Wage(position As %Integer) As %Integer
{
    quit +$piece("245000,247000,260000,290000,302000,242000,242000,296000,261000,343000,223000,271000,271000,223000,251000",",",position)*100
}
ClassMethod Attributes(target As %Numeric, position As %Integer, seed As %Integer, reference As %DynamicObject) As %DynamicObject
{
    set attrs={},catalog=##class(Rugby.Service.Development).Catalog(),minutes=reference.%Get("minutes",0)
    for k=0:1:16 {
        set key=catalog.%Get(k).id,value=target-8+(##class(Rugby.Service.Rivals).Hash(key,seed)#17)
        if (position<=8)&&$listfind($listbuild("strength","scrum","ruck","maul","lineout","tackling"),key) set value=value+6
        if (position>8)&&$listfind($listbuild("speed","agility","passing","handling","kicking","attacking"),key) set value=value+6
        if (minutes>=80)&&(key="tackling") set value=value+##class(Rugby.Simulation.Engine).Clamp(reference.%Get("tackles",0)*80/minutes/4,0,6)
        if (minutes>=80)&&((key="speed")||(key="attacking")) set value=value+##class(Rugby.Simulation.Engine).Clamp(reference.%Get("breaks",0)*80/minutes,0,4)
        if (minutes>=80)&&reference.%Get("pointsValidated",1)&&(key="decisions") set value=value+##class(Rugby.Simulation.Engine).Clamp(reference.%Get("points",0)*80/minutes/8,0,4)
        do attrs.%Set(key,##class(Rugby.Simulation.Engine).Clamp(value,1,99))
    }
    quit attrs
}
ClassMethod Position(row As %DynamicObject, serial As %Integer) As %Integer
{
    if row.%Get("position",0)>0 quit row.position
    set role=row.%Get("sourceRole")
    if role["1" quit $select(serial#3=0:2,serial#3=1:1,1:3)
    if role["2" quit 4+(serial#2)
    if role["3" quit 6+(serial#3)
    if role["ouverture" quit 10
    if role["mêlée" quit 9
    if role["Centre" quit 12+(serial#2)
    if role["Ailier" quit $select(serial#2:11,1:14)
    quit 15
}
ClassMethod Calibrated(target As %Numeric, position As %Integer, seed As %Integer, row As %DynamicObject) As %DynamicObject
{
    quit ..Attributes(target+row.%Get("ratingOffset",0)+((seed#3)-1),position,seed,row)
}
ClassMethod Player(c As %DynamicObject, row As %DynamicObject, serial As %Integer, identityVersion As %String, evidenceVersion As %String) As %DynamicObject
{
    set id=c.id,target=c.qualitySeniorTarget,top=c.competitionId=1401,year=##class(Rugby.Service.Seasons).Year(c.id),pid=id_"-lnr-"_row.lnrId,h=##class(Rugby.Service.Rivals).Hash(pid),pos=..Position(row,serial),age=20+(h#15),attrs=..Calibrated(target,pos,h,row),annual=..Wage(pos)*$select(top:1,1:.36)*(.6+((h#81)/100)),monthly=+$justify(annual/1200,0,0)*100
    set p={"id":(pid),"clubId":(id),"name":(row.name),"realIdentity":1,"identitySource":"LNR","identityNameVersion":(identityVersion),"identitySourceId":(row.lnrId),"identitySourceUrl":(row.sourceUrl),"identitySeason":("2026/2027"),"nationalityCode":(row.%Get("nationalityCode")),"nationality":(row.%Get("nationality","No verificada")),"age":(age),"ageSource":"simulation","birthDay":(c.day-(age*365)),"category":"senior","position":(pos),"positionSource":(row.%Get("positionEvidence","LNR-role-estimate")),"secondary":(row.%Get("secondary",[])),"frontRowQualifications":[],"attributes":(attrs),"attributesSource":"LNR-reference-simulation","lnrReference":(row),"morale":100,"energy":100,"available":true,"recoveryDay":0,"weeklyWage":(##class(Rugby.Service.MonthlyPayroll).Weekly(monthly)),"monthlyWage":(monthly),"payrollStartDay":(c.day),"developmentYear":-1,"developmentGains":{},"developmentCeiling":99,"talentScaleVersion":(##class(Rugby.Service.TalentScale).#VERSION),"talentScaleFactor":1,"marketDivisionId":(c.competitionId)}
    if p.nationality="France" set p.nationalityCode="FR",p.nationality="Francia"
    if pos<=3 do p.frontRowQualifications.%Push(pos)
    for front=1:1:3 { if (front'=pos)&&(row.%Get("positionCounts",{}).%Get(front,0)>0) do p.frontRowQualifications.%Push(front) }
    do ##class(Rugby.Service.Seasons).Contract(p,year+(h#4))
    set p.lnrBaseTarget=target,p.lnrCalibrationVersion=evidenceVersion
    quit p
}
ClassMethod Run() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),result={"clubs":0,"players":0}
    if $get(^RugbyWorld(game,"franceVersion"))=..#VERSION quit result
    tstart
    set catalog=..File("french-leagues"),settings=..File("french-club-settings"),own=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub(),0)
    if '$isobject(own) set own=##class(Rugby.Service.Store).Get("Club","c1")
    set roles=##class(Rugby.Service.Staff).Roles(),year=##class(Rugby.Service.Seasons).Year(own.id)
    for i=0:1:catalog.clubs.%Size()-1 {
        set entry=catalog.clubs.%Get(i),id=entry.id,meta=settings.%Get(id)
        if $isobject(##class(Rugby.Service.Store).Get("Club",id,0)) continue
        set top=entry.competitionId=1401,target=$select(top:83-(entry.rank*.45),1:72-(entry.rank*.3)),c={"id":(id),"name":(entry.name),"officialName":(entry.name),"shortName":(meta.%Get("shortName",entry.shortName)),"city":(meta.city),"color":(meta.color),"competitionId":(entry.competitionId),"competition":(entry.competition),"countryCode":"FR","officialTeamId":0,"day":(own.day),"startDay":(own.day),"date":(own.date),"seasonYear":(year),"season":(year_"/"_(year+1)),"seasonStartDate":(year_"-09-01"),"balance":(meta.budget/12),"initialBalance":(meta.budget/12),"budgetReference":(meta.budget),"frenchBudgetBasis":(meta.budgetBasis),"regulatorySalaryCap":(meta.salaryCap),"salaryCapBasis":(meta.salaryCapBasis),"qualityReferenceRank":(entry.rank),"qualitySeniorTarget":(target),"qualityAcademyTarget":(target-22),"qualityAcademyOffset":0,"qualityVersion":"france-1","sourceUrl":(entry.sourceUrl),"sourceVerifiedOn":(catalog.verifiedOn),"crestUrl":(entry.crestUrl),"stadium":(meta.stadium),"generatedRoster":0,"rosterSource":"LNR","rosterIdentityCount":(entry.players.%Size()),"talentScaleVersion":(##class(Rugby.Service.TalentScale).#VERSION),"aiLastDay":(own.day),"aiAdoptedDay":(own.day),"aiSeason":"","aiSignings":0,"aiPromotions":0}
        set c.kits={"primary":{"color":(meta.color),"accentColor":"#151515","pattern":"trim"},"secondary":{"color":"#f7f3e8","accentColor":(meta.color),"pattern":"trim"}}
        do ##class(Rugby.Service.Store).Put("Club",c)
        set roster=[],selected={}
        for n=0:1:entry.players.%Size()-1 {
            set row=entry.players.%Get(n)
            if ('row.%Get("matchEligible",1))&&('row.%Get("squadListed",0)) continue
            set p=..Player(c,row,n,catalog.%Get("identityVersion"),catalog.%Get("evidenceVersion"))
            do roster.%Push(p)
        }
        // Keep the professional squad within its simulated/regulatory operating limit.
        set annual=0,limit=$select(top:c.regulatorySalaryCap*.88,1:meta.budget*.43)
        for n=0:1:roster.%Size()-1 { set p=roster.%Get(n),annual=annual+(p.monthlyWage*12) }
        if annual>limit { for n=0:1:roster.%Size()-1 { set p=roster.%Get(n),p.monthlyWage=(p.monthlyWage*limit/annual/100)\1*100,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage) } }
        set slots=[],bench=[]
        for pos=1:1:15 { set pid=##class(Rugby.Service.Rivals).Pick(roster,selected,pos,1) if pid'="" { do slots.%Push({"position":(pos),"playerId":(pid)}),selected.%Set(pid,1) } }
        if slots.%Size()'=15 do ##class(Rugby.Service.Store).Fail(422,"LNR_POSITIONS","La plantilla LNR no cubre las quince posiciones: "_id)
        for pos=1,2,3,4,6,9,10,15 { for n=0:1:roster.%Size()-1 { set p=roster.%Get(n) if (p.position=pos)&&('selected.%IsDefined(p.id)) { do bench.%Push(p.id),selected.%Set(p.id,1) quit } } }
        for n=0:1:roster.%Size()-1 { set p=roster.%Get(n) do ##class(Rugby.Service.Store).Put("Player",p) set result.players=result.players+1 }
        set c.rosterIdentityCount=roster.%Size()
        do ##class(Rugby.Service.Store).Put("Club",c)
        set tactic={"style":"balanced","tempo":"normal","defense":"normal"},lineup={"id":(id_"-default"),"clubId":(id),"name":"XV principal","slots":(slots),"bench":(bench),"captainId":(slots.%Get(8).playerId),"tactic":(tactic)}
        do ##class(Rugby.Service.Store).Put("Lineup",lineup)
        for j=0:1:slots.%Size()-1 { set slot=slots.%Get(j),slot.id=lineup.id_"-"_(j+1),slot.clubId=id do ##class(Rugby.Service.Store).Put("LineupSlot",slot) }
        set tactic.id=lineup.id,tactic.clubId=id
        do ##class(Rugby.Service.Store).Put("Tactic",tactic),##class(Rugby.Service.Store).Put("TrainingPlan",{"id":(id),"clubId":(id),"groups":[],"dailyCost":0,"modelVersion":"2.0.0"})
        set coachIds=[]
        for j=0:1:roles.%Size()-1 { set role=roles.%Get(j),cid=id_"-coach-"_role.id,quality=$select(top:80,1:68),coach={"id":(cid),"clubId":(id),"name":(##class(Rugby.Service.PlayerNames).French(##class(Rugby.Service.Rivals).Hash(cid))),"role":(role.id),"quality":(quality),"weeklyWage":(##class(Rugby.Service.MonthlyPayroll).Weekly(##class(Rugby.Service.MonthlyPayroll).BaseStaff(role.id,quality,id))),"monthlyWage":(##class(Rugby.Service.MonthlyPayroll).BaseStaff(role.id,quality,id)),"effectiveness":(##class(Rugby.Service.Staff).Multiplier(quality)),"status":"employed"} do ##class(Rugby.Service.Store).Put("Coach",coach),coachIds.%Push(cid) }
        do ##class(Rugby.Service.Store).Put("TechnicalStaff",{"id":(id),"clubId":(id),"coachIds":(coachIds)})
        for j=1:1:20 { set p=##class(Rugby.Seed.Academy).Create(c,1+((j-1)#15),j),p.name=##class(Rugby.Service.PlayerNames).French(##class(Rugby.Service.Rivals).Hash(p.id)),p.nationalityCode="FR",p.nationality="Francia",p.attributes=..Attributes(target-24,p.position,j,{}),p.talentScaleVersion=##class(Rugby.Service.TalentScale).#VERSION,p.monthlyWage=$select(top:120000,1:70000),p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),p.birthDay=own.day-(p.age*365),p.payrollStartDay=own.day do ##class(Rugby.Service.Seasons).Contract(p,year+2),##class(Rugby.Service.Store).Put("Player",p) }
        set result.clubs=result.clubs+1
        set varied=##class(Rugby.Service.FrenchAcademyTerms).Club(c)
        do ##class(Rugby.Service.Rivals).Lineup(c)
    }
    set ^RugbyWorld(game,"franceVersion")=..#VERSION
    tcommit
    quit result
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),games=["template"],reports=[],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do games.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Importación de ligas en curso.")
    try { for g=0:1:games.%Size()-1 { set %RugbyGame=games.%Get(g),%RugbyManagedClub="c1" if %RugbyGame'="template" { set game=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)),%RugbyManagedClub=game.clubId } do reports.%Push(..Run()) do ##class(Rugby.Service.Competition).Ensure(##class(Rugby.Service.Seasons).Year()) } }
    catch ex { if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
