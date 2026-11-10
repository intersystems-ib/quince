Class Rugby.Test.PlayerNames Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set seen={},count=0
    for n=1:1:100 { set name=##class(Rugby.Service.PlayerNames).Spanish(n) do ..Assert(($length(name," ")=3)&&(name=##class(Rugby.Service.PlayerNames).Spanish(n)),"Spanish given name and two surnames repeat for the same seed") if 'seen.%IsDefined(name) { set count=count+1 do seen.%Set(name,1) } }
    do ..Assert(count>90,"Seeds offer diverse complete identities")
    set c=##class(Rugby.Service.Store).Get("Club","c1"),a=##class(Rugby.Seed.Academy).Create(c,1,9999),b=##class(Rugby.Seed.Academy).Create(c,1,9999)
    do ..Assert(($length(a.name," ")=3)&&(a.%ToJSON()=b.%ToJSON()),"New youth intake has two surnames and stays deterministic")
    set before=##class(Rugby.Service.Store).All("Player").%ToJSON(),year=2041
    do ##class(Rugby.Service.Rivals).Market(year),##class(Rugby.Service.Transfers).SeedMarket(year)
    for n=1:1:20 {
        set agent=##class(Rugby.Service.Store).Get("Player","free-agent-"_year_"-"_n)
        if agent.nationalityCode="ES" { do ..Assert($length(agent.name," ")=3,"Spanish free agents have two surnames") }
        else {
            set expected=$select(agent.nationalityCode="FR":"Louis Moreau",agent.nationalityCode="PT":"João Duarte",agent.nationalityCode="IE":"Liam Murphy",agent.nationalityCode="GB":"Jack Taylor",agent.nationalityCode="AR":"Santiago Rivas",agent.nationalityCode="UY":"Facundo Silva",agent.nationalityCode="ZA":"Pieter Smit",1:"Wiremu Rangi")
            do ..Assert(agent.name=expected,"Foreign naming is unchanged")
        }
    }
    do ##class(Rugby.Service.Rivals).Market(year),##class(Rugby.Service.Transfers).SeedMarket(year)
    set old=##class(%DynamicArray).%FromJSON(before)
    for n=0:1:old.%Size()-1 { set p=old.%Get(n) do ..Assert(##class(Rugby.Service.Store).Get("Player",p.id).%ToJSON()=p.%ToJSON(),"Existing player identity and sporting data are untouched") }
}
}
