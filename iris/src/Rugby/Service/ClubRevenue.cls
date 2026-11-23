Class Rugby.Service.ClubRevenue Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Reference(c As %DynamicObject) As %Integer
{
    if $listfind($listbuild("c1","c7"),c.id) quit 60000000
    quit ##class(Rugby.Service.Finance).Budget(c)
}
ClassMethod Plan(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject, coreCosts As %Numeric, coreIncome As %Numeric) As %DynamicObject
{
    if $isobject(s.%Get("community")) {
        if ##class(Rugby.Service.Leagues).French(c.competitionId) quit ##class(Rugby.Service.FrenchFinanceBalance).Plan(c,s,o,s.community,coreCosts,coreIncome)
        quit s.community
    }
    set reference=..Reference(c),h=##class(Rugby.Service.Finance).Hash("community-"_c.id),count=+$justify(reference/100*.0008*(.9+((h#21)/100)),0,0),fee=(130+((h\21)#61))*100
    if c.id="c1" set count=600
    if c.id="c7" set count=300
    set members=count*fee,baseline=coreIncome
    if o.director.%Get("id")="" {
        set office=##class(%DynamicObject).%FromJSON(o.%ToJSON()),office.director={"id":"planning-reference","quality":65},standard=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,office,0),baseline=standard.projectedIncome
        set coreCosts=coreCosts+(##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(65,c.id)*12)
    }
    set other=reference-baseline-members,minimum=reference*.08
    if other<minimum set other=minimum
    set other=(other\100)*100,total=baseline+members+other,initialMargin=.02
    if ##class(Rugby.Service.Leagues).French(c.competitionId) { set desired=##class(Rugby.Service.FrenchFinanceBalance).TargetMargin(c,s,o) if desired>initialMargin set initialMargin=desired }
    set costs=$select((total*(1-initialMargin))>coreCosts:(total*(1-initialMargin))-coreCosts,1:0)
    if c.%Get("communityCostReference",-1)>=0 set costs=c.communityCostReference*reference/c.communityBudgetReference
    set costs=(costs\100)*100,youth=(other*(.6+((h#16)/100))\100)*100,coaching=(costs*.4\100)*100,federation=(costs*.3\100)*100
    set month=+$piece(c.date,"-",2),first=$select(month>=9:month-9,month<=6:month+3,1:0)
    if (+$piece(c.date,"-",3)>21)&&('##class(Rugby.Service.SeasonCalendar).Summer(c.date)) set first=first+1
    set first=$select(first>10:10,1:first),instalments=10-first
    set p={"modelVersion":(..#VERSION),"referenceBudget":(reference),"memberCount":(count),"memberFee":(fee),"annualMembersIncome":(members),"annualOtherIncome":(other),"annualYouthFees":(youth),"annualActivitiesIncome":(other-youth),"annualCosts":(costs),"annualCoachingCosts":(coaching),"annualFederationTravelCosts":(federation),"annualFacilitiesCosts":(costs-coaching-federation),"firstInstalment":(first),"plannedMembersIncome":(members*instalments/10),"plannedOtherIncome":(other*instalments/10),"plannedCosts":(costs*instalments/10),"introducedOn":(c.date)}
    if ##class(Rugby.Service.Leagues).French(c.competitionId) set p=##class(Rugby.Service.FrenchFinanceBalance).Plan(c,s,o,p,coreCosts,baseline)
    quit p
}
ClassMethod Costs(club As %String) As %Numeric
{
    set c=##class(Rugby.Service.Store).Get("Club",club),s=##class(Rugby.Service.Store).Get("FinancialSeason",club_"-finance-"_##class(Rugby.Service.Competition).Year(c.date),0)
    if '$isobject(s) quit 0
    if '$isobject(s.%Get("community")) quit 0
    quit s.community.plannedCosts
}
ClassMethod Prepare(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject)
{
    if $isobject(s.%Get("community")) quit
    set forecast=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),s.community=forecast.community
    if 'c.%IsDefined("communityCostReference") {
        set c.communityCostReference=s.community.annualCosts,c.communityBudgetReference=s.community.referenceBudget
        do ##class(Rugby.Service.Store).Put("Club",c)
    }
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
}
ClassMethod Tick(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject)
{
    do ..Prepare(c,s,o)
    set month=+$piece(c.date,"-",2),index=$select(month>=9:month-9,month<=6:month+3,1:-1),p=s.community
    if (index<0)||(index<p.firstInstalment)||(+$piece(c.date,"-",3)<21) quit
    for type="socialMembers","otherIncome","communityCosts" {
        set annual=p.%Get($select(type="socialMembers":"annualMembersIncome",type="otherIncome":"annualOtherIncome",1:"annualCosts")),amount=((annual*(index+1)/10)\1)-((annual*index/10)\1),concept=$select(type="socialMembers":"Cuotas de socios",type="otherIncome":"Cuotas de categorías inferiores y otras actividades",1:"Escuelas, otras categorías y estructura social")
        if (type="otherIncome")&&(p.%Get("frenchBalanceVersion")'="") set amount=##class(Rugby.Service.FrenchFinanceBalance).Payment(p,index)
        if type="communityCosts" set amount=-amount
        if amount do ##class(Rugby.Service.Management).Money(c,amount,type,concept_" "_s.season,s.id_"-community-"_type_"-"_month)
    }
}
ClassMethod Initialize()
{
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i),o=##class(Rugby.Service.Finance).Office(c.id),s=##class(Rugby.Service.Finance).Season(c)
        do ..Prepare(c,s,o)
    }
    set treasury=##class(Rugby.Service.OpeningTreasury).Initialize()
}
ClassMethod InitializeAll() As %DynamicObject
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),count=0
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando ingresos de socios y categorías inferiores.")
    try {
        tstart
        set %RugbyGame="template",%RugbyManagedClub="c1",restored=##class(Rugby.Service.SalaryRestoration).Initialize()
        do ..Initialize()
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId,restored=##class(Rugby.Service.SalaryRestoration).Initialize(),count=count+1 do ..Initialize() }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit {"modelVersion":(..#VERSION),"games":(count)}
}
}
