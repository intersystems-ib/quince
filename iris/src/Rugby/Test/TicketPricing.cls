Class Rugby.Test.TicketPricing Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set home=##class(Rugby.Service.Store).Get("Club","c1"),away=##class(Rugby.Service.Store).Get("Club","c2"),home.city="Ciudad local",away.city="Ciudad visitante",home.competitionId=416,away.competitionId=416,home.qualityReferenceRank=5,away.qualityReferenceRank=9
    do ##class(Rugby.Service.Store).Put("Club",home),##class(Rugby.Service.Store).Put("Club",away)
    set f={"id":"ticket-pricing-test","homeId":"c1","awayId":"c2","date":"2096-10-10","stage":"regular","round":4},weak=##class(Rugby.Service.TicketPricing).Recommend(f)
    set away.qualityReferenceRank=2
    do ##class(Rugby.Service.Store).Put("Club",away)
    set strong=##class(Rugby.Service.TicketPricing).Recommend(f)
    do ..Assert(strong.price>weak.price,"A strong visitor attracts a higher ticket price than a weak opponent")
    set f.stage="quarterfinal",quarter=##class(Rugby.Service.TicketPricing).Recommend(f),f.stage="semifinal",semi=##class(Rugby.Service.TicketPricing).Recommend(f),f.stage="final",final=##class(Rugby.Service.TicketPricing).Recommend(f),f.stage="friendly",friendly=##class(Rugby.Service.TicketPricing).Recommend(f)
    do ..Assert((final.price>semi.price)&&(semi.price>quarter.price)&&(quarter.price>strong.price)&&(strong.price>friendly.price),"Finals and knockout fixtures cost more; friendlies cost less")
    set f.stage="regular",away.city=home.city
    do ##class(Rugby.Service.Store).Put("Club",away)
    set derby=##class(Rugby.Service.TicketPricing).Recommend(f)
    do ..Assert(derby.price>strong.price,"A local derby increases the suggested price")
    set home.qualityReferenceRank=2,away.qualityReferenceRank=3,f.round=4
    do ##class(Rugby.Service.Store).Put("Club",home),##class(Rugby.Service.Store).Put("Club",away)
    set normal=##class(Rugby.Service.TicketPricing).Recommend(f),f.round=17,decisive=##class(Rugby.Service.TicketPricing).Recommend(f)
    do ..Assert(decisive.price>normal.price,"Late-season direct rivals increase match interest")
    set home.competitionId=417,away.competitionId=417
    do ##class(Rugby.Service.Store).Put("Club",home),##class(Rugby.Service.Store).Put("Club",away)
    set elite=##class(Rugby.Service.TicketPricing).Recommend(f),again=##class(Rugby.Service.TicketPricing).Recommend(f)
    do ..Assert((elite.price<decisive.price)&&(elite.%ToJSON()=again.%ToJSON())&&(elite.price>=500)&&(elite.price<=4000),"Elite prices are lower, bounded and deterministic")
    set forecast=##class(Rugby.Service.Finance).Forecast(f),manual=##class(Rugby.Service.Finance).Forecast(f,2500)
    do ..Assert((forecast.ticketPrice=elite.price)&&(manual.ticketPrice=2500)&&(manual.pricing.price=elite.price),"Forecast defaults to the recommendation and respects an explicit price")
    set m=##class(Rugby.Test.Suite).Build(4531)
    do ..Assert((m.ticketPrice>0)&&(m.ticketPriceSource="recommended")&&(m.economySnapshot.ticketPrice=m.ticketPrice),"New matches apply and freeze the recommended price at kickoff")
    set m.status="scheduled",m.date=home.date
    do ##class(Rugby.Service.Store).Put("Match",m)
    set saved=##class(Rugby.Service.Finance).Ticketing(m.id,{"version":(m.version),"ticketPrice":1700},"ticket-price-manual"),retry=##class(Rugby.Service.Finance).Ticketing(m.id,{},"ticket-price-manual"),forecast=##class(Rugby.Service.Finance).Forecast(saved)
    do ..Assert((saved.ticketPrice=1700)&&(saved.ticketPriceSource="manual")&&(forecast.ticketPrice=1700)&&(retry.%ToJSON()=saved.%ToJSON()),"Manual ticket prices are retained and retries do not overwrite them")
    set comp={"id":"league-417-2096","teamIds":["c1","c2"]}
    do ##class(Rugby.Service.Store).Put("Competition",comp)
    for i=1:1:3 {
        set played={"id":("ticket-rank-"_i),"competitionKey":(comp.id),"homeId":"c1","awayId":"c2","stage":"regular","status":"finished","day":(i),"homeScore":0,"awayScore":20}
        do ##class(Rugby.Service.Store).Put("Fixture",played)
    }
    do ..Assert(##class(Rugby.Service.TicketPricing).Rank(away,"2096-10-10")=1,"Current league standings replace reference ranks after three played games")

}
}
