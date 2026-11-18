Class Rugby.Service.OpeningTreasury Extends %RegisteredObject
{
Parameter VERSION = "2.0.0";
ClassMethod Funds(club As %String) As %Integer
{
    set c=##class(Rugby.Service.Store).Get("Club",club),t=##class(Rugby.Service.MonthlyPayroll).Totals(club),monthly=t.players+t.staff+t.director+(##class(Rugby.Service.ClubRevenue).Costs(club)/10)
    // One payroll, registration fees and one month of travel, plus 10% liquidity.
    set need=(monthly+(##class(Rugby.Service.Finance).Budget(c)*.03)+(1650000/12))*1.1
    quit ((need+99999)\100000)*100000
}
ClassMethod Initialize() As %DynamicArray
{
    set clubs=##class(Rugby.Service.Store).All("Club"),result=[]
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        if c.%Get("openingTreasuryVersion")=..#VERSION continue
        set fresh=(c.day=c.%Get("startDay",c.day))&&(##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id).%Size()=0),funds=..Funds(c.id)
        if fresh set c.initialBalance=funds,c.balance=funds
        set c.openingTreasuryVersion=..#VERSION
        do ##class(Rugby.Service.Store).Put("Club",c),result.%Push({"clubId":(c.id),"adjusted":(fresh),"openingFunds":(c.initialBalance)})
    }
    quit result
}
}
