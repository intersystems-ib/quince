Class Rugby.Service.ContractTerms Extends %RegisteredObject
{
ClassMethod Preferred(age As %Integer, id As %String = "") As %Integer
{
    if age>=33 quit 1
    if age<=24 quit 2+(##class(Rugby.Service.Rivals).Hash(id,##class(Rugby.Service.Rivals).Seed())#2)
    quit 5
}
ClassMethod Premium(age As %Integer, years As %Integer) As %Numeric
{
    if age>=33 quit 1+((years-1)*.08)
    if age<=24 quit 1+($select(years<2:2-years,years>3:years-3,1:0)*.06)
    quit 1+((5-years)*.05)
}
ClassMethod EndDate(n As %DynamicObject, years As %Integer) As %String
{
    set base=n.%Get("contractStartYear",##class(Rugby.Service.Competition).Year(n.contractEndDate)-(n.%Get("contractYears",1)-1))
    quit ##class(Rugby.Service.Seasons).EndDate(base+years-1)
}
}
