Class Rugby.Test.Venues Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        do ..Assert((c.stadium.name'="")&&(c.stadium.capacity>0)&&(c.stadium.sourceUrl'=""),"Every club has a sourced ground and published capacity")
    }
    set c=##class(Rugby.Service.Store).Get("Club","c1"),before=c.%ToJSON(),report=##class(Rugby.Seed.Venues).Apply()
    do ..Assert((report.clubs.%Size()=0)&&(##class(Rugby.Service.Store).Get("Club","c1").%ToJSON()=before),"Venue adoption is idempotent")
    do ..Assert((c.stadium.name="Estadio Nacional Complutense")&&(c.stadium.capacity=12400),"Cisneros uses the provided 12400 capacity")
    set a=##class(Rugby.Service.Store).Get("Club","c2"),b=##class(Rugby.Service.Store).Get("Club","c8")
    do ..Assert((a.stadium.%ToJSON()=b.stadium.%ToJSON())&&(a.stadium.capacity=5000),"Valladolid clubs share Pepe Rojo")
    set f={"id":"venue-away-test","clubId":"c1","homeId":"c7","awayId":"c1","day":(c.day),"date":(c.date),"status":"scheduled","matchId":"","stage":"friendly"}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set f=##class(Rugby.Service.Store).Get("Fixture",f.id)
    do ..Assert((f.venue.name="Las Terrazas")&&(f.venue.capacity=2000),"Away fixture uses the home club ground")
    set m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id)},"venue-away-test")
    do ..Assert(m.venue.%ToJSON()=f.venue.%ToJSON(),"Match keeps the correct home venue snapshot")
    set f={"id":"capacity-test","homeId":"c6","awayId":"c2","stage":"semifinal","date":(c.date)},forecast=##class(Rugby.Service.Finance).Forecast(f,0),home=##class(Rugby.Service.Store).Get("Club",f.homeId)
    do ..Assert((forecast.attendance<=home.stadium.capacity)&&((forecast.seasonTicketHolders+forecast.payingAttendees)=forecast.attendance),"New attendance never exceeds published capacity")
}
}
