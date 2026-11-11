Class Rugby.Service.Calendar Extends %RegisteredObject
{
ClassMethod Date(club As %String, date As %String) As %Integer
{
    do ##class(Rugby.Service.Store).Managed(club)
    set c=##class(Rugby.Service.Store).Get("Club",club),valid=0
    try { if date?4N1"-"2N1"-"2N set day=$zdateh(date,3),valid=$zdate(day,3)=date } catch ignored { }
    if 'valid do ##class(Rugby.Service.Store).Fail(422,"DATE","Selecciona una fecha válida.")
    if (day<$zdateh(c.date,3))||(day>($zdateh(c.date,3)+365)) do ##class(Rugby.Service.Store).Fail(422,"FRIENDLY_DATE","El amistoso debe estar entre hoy y los próximos doce meses.")
    quit day-$zdateh("2026-11-07",3)
}
ClassMethod Busy(club As %String, date As %String) As %Boolean
{
    set all=##class(Rugby.Service.Store).All("Fixture"),busy=##class(Rugby.Service.Cup).Reserved(##class(Rugby.Service.Competition).Year(date),date)
    set c=##class(Rugby.Service.Store).Get("Club",club),league=##class(Rugby.Service.Store).Get("Competition","league-"_c.competitionId_"-"_##class(Rugby.Service.Competition).Year(date),0)
    if $isobject(league) {
        if date=league.finalDate set busy=1
        for i=0:1:league.semifinalDates.%Size()-1 { if date=league.semifinalDates.%Get(i) set busy=1 }
    }
    for i=0:1:all.%Size()-1 {
        set f=all.%Get(i)
        if f.%Get("archived",0) continue
        if (f.%Get("date")=date)&&((f.homeId=club)||(f.awayId=club)) set busy=1
    }
    quit busy
}
ClassMethod Options(club As %String, date As %String) As %DynamicObject
{
    set day=..Date(club,date),c=##class(Rugby.Service.Store).Get("Club",club)
    if ..Busy(club,date) do ##class(Rugby.Service.Store).Fail(409,"CALENDAR_BUSY","Ese día está ocupado o reservado para la competición.")
    set offer=$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"friendlyOffers",club,date)),valid=0
    if offer'="" {
        set ids=##class(%DynamicArray).%FromJSON(offer),valid=1
        for i=0:1:ids.%Size()-1 { if ..Busy(ids.%Get(i),date) set valid=0 }
    }
    if 'valid {
        set clubs=##class(Rugby.Service.Store).All("Club"),dh=[],elite=[],pool=[],ids=[]
        for i=0:1:clubs.%Size()-1 {
            set p=clubs.%Get(i)
            if (p.id=club)||(..Busy(p.id,date)) continue
            do pool.%Push(p.id)
            if p.competitionId=416 { do dh.%Push(p.id) } else { do elite.%Push(p.id) }
        }
        if pool.%Size()<3 do ##class(Rugby.Service.Store).Fail(409,"NO_OPPONENTS","No hay tres rivales disponibles para ese día. Elige otra fecha.")
        if dh.%Size() do ids.%Push(dh.%Get($random(dh.%Size())))
        if elite.%Size() do ids.%Push(elite.%Get($random(elite.%Size())))
        for {
            quit:ids.%Size()=3
            set candidate=pool.%Get($random(pool.%Size())),found=0
            for i=0:1:ids.%Size()-1 { if ids.%Get(i)=candidate set found=1 }
            if 'found do ids.%Push(candidate)
        }
        set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"friendlyOffers",club,date)=ids.%ToJSON()
    }
    set items=[]
    for i=0:1:ids.%Size()-1 { do items.%Push(##class(Rugby.Service.Store).Get("Club",ids.%Get(i))) }
    quit {"date":(date),"items":(items),"version":(c.version)}
}
ClassMethod Create(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club),##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","friendly",key)) quit ##class(Rugby.Service.Store).Get("Fixture",^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","friendly",key))
    set c=##class(Rugby.Service.Store).Get("Club",club)
    do ##class(Rugby.Service.Store).CheckVersion(c,b)
    if ##class(Rugby.Service.Store).Active(club) do ##class(Rugby.Service.Store).Fail(409,"MATCH_ACTIVE","Termina el partido en curso antes de concertar otro.")
    set date=b.%Get("date"),day=..Date(club,date),offer=..Options(club,date),found=0
    for i=0:1:offer.items.%Size()-1 { if offer.items.%Get(i).id=b.%Get("opponentId") set found=1 }
    if 'found do ##class(Rugby.Service.Store).Fail(422,"FRIENDLY_OPPONENT","Elige uno de los tres rivales ofrecidos.")
    if '$listfind($listbuild("home","away"),b.%Get("venue")) do ##class(Rugby.Service.Store).Fail(422,"FRIENDLY_VENUE","Elige casa o fuera.")
    set id="friendly-"_$increment(^RugbyWorld(##class(Rugby.Service.Store).Game(),"ids","Friendly")),home=$select(b.venue="home":club,1:b.opponentId),away=$select(b.venue="home":b.opponentId,1:club)
    set f={"id":(id),"clubId":(club),"homeId":(home),"awayId":(away),"date":(date),"day":(day),"stage":"friendly","round":0,"status":"scheduled","matchId":"","seed":(1+$random(2147483645))}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"retry","friendly",key)=id
    quit f
}
}
