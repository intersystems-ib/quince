Class Rugby.Seed.Competition Extends %RegisteredObject
{
ClassMethod Run()
{
    if $get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",8)) quit
    tstart
    set club=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),fixtures=##class(Rugby.Service.Store).All("Fixture")
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i)
        if f.%Get("competitionKey")="" { do f.%Set("archived",1,"boolean") do ##class(Rugby.Service.Store).Put("Fixture",f) }
    }
    do ##class(Rugby.Service.Competition).Sync(club.day)
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",8)=1
    tcommit
}
}
