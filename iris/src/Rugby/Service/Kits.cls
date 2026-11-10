Class Rugby.Service.Kits Extends %RegisteredObject
{
Parameter VERSION = "2.0.0";
ClassMethod Valid(color As %String) As %Boolean
{
    quit ($length(color)=7)&&($extract(color)="#")&&($translate($zconvert($extract(color,2,7),"U"),"0123456789ABCDEF","")="")
}
ClassMethod Channel(color As %String, index As %Integer) As %Integer
{
    set hex="0123456789ABCDEF",color=$zconvert(color,"U")
    quit (($find(hex,$extract(color,2+(index*2)))-2)*16)+($find(hex,$extract(color,3+(index*2)))-2)
}
ClassMethod Distance(a As %String, b As %String) As %Integer
{
    set sum=0
    for i=0:1:2 { set delta=..Channel(a,i)-..Channel(b,i),sum=sum+(delta*delta) }
    quit sum
}
ClassMethod Clash(a As %String, b As %String) As %Boolean { quit ..Distance(a,b)<14400 }
ClassMethod Linear(value As %Numeric) As %Numeric
{
    set value=value/255
    if value<=.04045 quit value/12.92
    quit ((value+.055)/1.055)**2.4
}
ClassMethod Luminance(color As %String) As %Numeric
{
    quit (..Linear(..Channel(color,0))*.2126)+(..Linear(..Channel(color,1))*.7152)+(..Linear(..Channel(color,2))*.0722)
}
ClassMethod Kit(club As %DynamicObject, choice As %String) As %DynamicObject
{
    set configured=club.%Get("kits"),color=$select(choice="primary":club.color,1:"#f7f3e8")
    if $isobject(configured) { set entry=configured.%Get(choice) if $isobject(entry) set color=entry.color }
    if '..Valid(color) do ##class(Rugby.Service.Store).Fail(422,"KIT_COLOR","Color de equipación inválido.")
    set light=..Luminance(color),white=1.05/(light+.05),black=(light+.05)/.05
    set result={"id":(choice),"name":($select(choice="primary":"Primera equipación",1:"Segunda equipación")),"color":(color),"numberColor":($select(black>=white:"#000000",1:"#ffffff"))}
    if $isobject(configured) {
        set entry=configured.%Get(choice)
        if $isobject(entry) { for key="accentColor","thirdColor","pattern","description" { if entry.%IsDefined(key) do result.%Set(key,entry.%Get(key)) } }
    }
    for key="accentColor","thirdColor" { if result.%IsDefined(key)&&('..Valid(result.%Get(key))) do ##class(Rugby.Service.Store).Fail(422,"KIT_COLOR","Color secundario de equipación inválido.") }
    quit result
}
ClassMethod Resolve(home As %DynamicObject, away As %DynamicObject) As %DynamicObject
{
    set h=..Kit(home,"primary"),a=..Kit(away,"primary"),clash=..Clash(h.color,a.color)
    if clash {
        set a=..Kit(away,"secondary")
        if ..Clash(h.color,a.color) {
            set h=..Kit(home,"secondary"),a=..Kit(away,"primary")
            if ..Clash(h.color,a.color) set a=..Kit(away,"secondary")
        }
        if ..Clash(h.color,a.color) do ##class(Rugby.Service.Store).Fail(422,"KIT_CONTRAST","Las dos equipaciones de ambos clubes no permiten distinguir los equipos.")
    }
    set result={"home":(h),"away":(a)}
    do result.%Set("clashResolved",clash,"boolean")
    quit result
}
ClassMethod Apply(m As %DynamicObject, home As %DynamicObject, away As %DynamicObject)
{
    set chosen=..Resolve(home,away),m.homeKit=chosen.home,m.awayKit=chosen.away,m.homeColor=chosen.home.color,m.awayColor=chosen.away.color,m.kitVersion=..#VERSION
    do m.%Set("kitClashResolved",chosen.clashResolved,"boolean")
}
ClassMethod Initialize() As %DynamicObject
{
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(..#VERSION),"clubs":0,"matches":0}
    if $get(^RugbyWorld(game,"kitVersion"))=..#VERSION quit report
    set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8",sc=stream.LinkToFile("/opt/rugby/data/clubs.json")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set catalog=##class(%DynamicObject).%FromJSON(stream)
    for i=0:1:catalog.clubs.%Size()-1 {
        set entry=catalog.clubs.%Get(i),club=##class(Rugby.Service.Store).Get("Club",entry.id),club.kits=##class(%DynamicObject).%FromJSON(entry.kits.%ToJSON()),club.kitVersion=..#VERSION,club.color=entry.kits.primary.color
        set primary=..Kit(club,"primary"),secondary=..Kit(club,"secondary")
        if ..Clash(primary.color,secondary.color) do ##class(Rugby.Service.Store).Fail(422,"KIT_PALETTE","Las dos camisetas del club deben diferenciarse.")
        do ##class(Rugby.Service.Store).Put("Club",club)
        set report.clubs=report.clubs+1
    }
    set matches=##class(Rugby.Service.Store).All("Match")
    for i=0:1:matches.%Size()-1 {
        set m=matches.%Get(i),home=##class(Rugby.Service.Store).Get("Club",m.homeId),away=##class(Rugby.Service.Store).Get("Club",m.awayId)
        do ..Apply(m,home,away),##class(Rugby.Service.Store).Put("Match",m)
        set report.matches=report.matches+1
    }
    set ^RugbyWorld(game,"kitVersion")=..#VERSION
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando equipaciones.")
    try {
        tstart
        do reports.%Push(..Initialize())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Initialize()) }
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
