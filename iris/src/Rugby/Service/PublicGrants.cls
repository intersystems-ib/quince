Class Rugby.Service.PublicGrants Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Split(club As %String, year As %Integer, total As %Integer) As %Integer
{
    if total<2 quit total
    set share=5500+(##class(Rugby.Service.Finance).Hash(club_"-public-funding-share-"_year)#2501),first=(total*share)\10000
    quit $select(first<1:1,first>=total:total-1,1:first)
}
ClassMethod Repair(c As %DynamicObject, s As %DynamicObject) As %DynamicObject
{
    set result={"clubId":(c.id),"seasonId":(s.id),"adjusted":false},first="",second=""
    if (s.%Get("grantDistributionVersion")=..#VERSION)||(s.%Get("fundingReductionVersion")=##class(Rugby.Service.FundingReduction).#VERSION) quit result
    for i=0:1:s.grants.%Size()-1 {
        set g=s.grants.%Get(i)
        if g.id=(s.id_"-grant-1") set first=g
        if g.id=(s.id_"-grant-2") set second=g
    }
    if '$isobject(first)||('$isobject(second)) quit result
    set total=first.amount+second.amount,new=..Split(c.id,s.year,total)
    if (first.status="paid")||(second.status="paid") {
        if (first.status'="paid")||(second.status'="paid") quit result
        set a=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-"_first.id,0),b=##class(Rugby.Service.Store).Get("FinancialMovement",c.id_"-"_second.id,0)
        if '$isobject(a)||('$isobject(b)) quit result
        if (a.amount'=first.amount)||(b.amount'=second.amount) quit result
        // Correct the allocation between institutions; total income and cash never change.
        set a.previousGrantAmount=a.amount,b.previousGrantAmount=b.amount,a.amount=new,b.amount=total-new,a.grantDistributionVersion=..#VERSION,b.grantDistributionVersion=..#VERSION
        do ##class(Rugby.Service.Store).Put("FinancialMovement",a),##class(Rugby.Service.Store).Put("FinancialMovement",b)
    }
    set result.previousAmounts=[(first.amount),(second.amount)],first.previousAmount=first.amount,second.previousAmount=second.amount,first.amount=new,second.amount=total-new,s.grantDistributionVersion=..#VERSION,result.amounts=[(first.amount),(second.amount)],result.total=total,result.adjusted=1
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
    quit result
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Revisando subvenciones.")
    try {
        tstart
        set games=["template"],gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do games.%Push(gid) }
        for g=0:1:games.%Size()-1 {
            set %RugbyGame=games.%Get(g),%RugbyManagedClub="c1",seasons=##class(Rugby.Service.Store).All("FinancialSeason")
            if %RugbyGame'="template" set %RugbyManagedClub=##class(%DynamicObject).%FromJSON(^RugbyGames(%RugbyGame)).clubId
            for i=0:1:seasons.%Size()-1 { set s=seasons.%Get(i),c=##class(Rugby.Service.Store).Get("Club",s.clubId),repair=..Repair(c,s) if repair.adjusted do reports.%Push(repair) }
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
