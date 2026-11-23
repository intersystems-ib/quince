Class Rugby.Service.TicketPricing Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Rank(c As %DynamicObject, date As %String) As %Integer
{
    set rank=c.%Get("qualityReferenceRank",5),year=##class(Rugby.Service.Competition).Year(date),comp=##class(Rugby.Service.Store).Get("Competition","league-"_c.competitionId_"-"_year,0)
    if $isobject(comp) {
        set table=##class(Rugby.Service.Competition).Table(comp)
        for i=0:1:table.%Size()-1 { set row=table.%Get(i) if (row.clubId=c.id)&&(row.played>=3) { set rank=row.rank quit } }
    }
    quit ##class(Rugby.Simulation.Engine).Clamp(rank,1,##class(Rugby.Service.Leagues).Config(c.competitionId).teams)
}
ClassMethod Recommend(f As %DynamicObject) As %DynamicObject
{
    set home=##class(Rugby.Service.Store).Get("Club",f.homeId),away=##class(Rugby.Service.Store).Get("Club",f.awayId),date=f.%Get("date",home.date),stage=f.%Get("stage","friendly"),hr=..Rank(home,date),ar=..Rank(away,date),base=$select(home.competitionId=1401:3000,home.competitionId=1402:1800,home.competitionId=416:1200,1:900),factor=1,reasons=[]
    if stage="friendly" { set factor=.65 do reasons.%Push("Partido amistoso") }
    elseif stage="access" { set factor=2.3 do reasons.%Push("Access Match") }
    elseif stage="final" { set factor=2.5 do reasons.%Push("Final") }
    elseif stage="semifinal" { set factor=1.85 do reasons.%Push("Semifinal") }
    elseif stage="quarterfinal" { set factor=1.5 do reasons.%Push("Cuartos de final") }
    elseif stage="cup-group" { set factor=1.15 do reasons.%Push("Fase de grupos de Copa") }
    else { do reasons.%Push("Liga regular") }
    if (home.competitionId=416)&&(away.competitionId=417) { set factor=factor*.85 do reasons.%Push("Rival de División Élite") }
    if (home.competitionId=417)&&(away.competitionId=416) { set factor=factor*1.2 do reasons.%Push("Visita de un club de División de Honor") }
    if ar<=3 { set factor=factor*1.2 do reasons.%Push("Rival entre los tres primeros") }
    elseif ar>=8 { set factor=factor*.85 do reasons.%Push("Rival de la zona baja") }
    if (hr<=4)&&(ar<=4)&&(stage'="friendly") { set factor=factor*1.15 do reasons.%Push("Duelo entre aspirantes") }
    if (home.city'="")&&($zconvert(home.city,"L")=$zconvert(away.city,"L")) { set factor=factor*1.25 do reasons.%Push("Derbi local") }
    if (stage="regular")&&(f.%Get("round",0)>=15)&&($zabs(hr-ar)<=2)&&(((hr<=4)&&(ar<=4))||((hr>=8)&&(ar>=8))) { set factor=factor*1.15 do reasons.%Push("Jornada decisiva ante un rival directo") }
    set price=##class(Rugby.Simulation.Engine).Clamp(+$justify(base*factor/100,0,0)*100,500,4000),interest=$select(factor>=1.7:"Muy alto",factor>=1.15:"Alto",factor<.9:"Moderado",1:"Normal")
    quit {"price":(price),"basePrice":(base),"interest":(interest),"reasons":(reasons),"homeRank":(hr),"awayRank":(ar),"factor":(factor),"modelVersion":(..#VERSION)}
}
}
