Class Rugby.Service.PersonnelMarkets Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Country(club As %String) As %String
{
    quit ##class(Rugby.Service.Leagues).Country(##class(Rugby.Service.Store).Get("Club",club))
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"coaches":0,"offices":0}
    if $get(^RugbyWorld(game,"personnelMarketsVersion"))=..#VERSION quit report
    set coaches=##class(Rugby.Service.Store).All("Coach")
    for i=0:1:coaches.%Size()-1 {
        set p=coaches.%Get(i),country=$select(p.clubId'="":..Country(p.clubId),1:p.%Get("marketCountry","ES"))
        if p.%Get("marketCountry")'=country { set p.marketCountry=country do ##class(Rugby.Service.Store).Put("Coach",p) set report.coaches=report.coaches+1 }
    }
    set offices=##class(Rugby.Service.Store).All("FinancialOffice")
    for i=0:1:offices.%Size()-1 {
        set o=offices.%Get(i),country=..Country(o.clubId),o.marketCountry=country
        for j=0:1:o.candidates.%Size()-1 { set p=o.candidates.%Get(j),p.marketCountry=country }
        if o.director.%Get("id")'="" set o.director.marketCountry=country
        do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
        set report.offices=report.offices+1
    }
    set ^RugbyWorld(game,"personnelMarketsVersion")=..#VERSION
    quit report
}
}
