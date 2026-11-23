Class Rugby.Service.CompetitionStatistics Extends %RegisteredObject
{
Parameter VERSION = "1";
ClassMethod Catalog() As %DynamicArray
{
    quit [{"id":"points","label":"Puntos","category":"attack","column":"Points"},{"id":"tries","label":"Ensayos","category":"attack","column":"Tries"},{"id":"metres","label":"Metros ganados","category":"attack","column":"Metres"},{"id":"carries","label":"Carreras con balón","category":"attack","column":"Carries"},{"id":"passes","label":"Pases","category":"attack","column":"Passes"},{"id":"actions","label":"Acciones","category":"attack","column":"Actions"},{"id":"tackles","label":"Placajes","category":"defense","column":"Tackles"},{"id":"turnovers","label":"Recuperaciones","category":"defense","column":"Turnovers"},{"id":"conversions","label":"Transformaciones","category":"kicking","column":"Conversions"},{"id":"conversionAttempts","label":"Transformaciones intentadas","category":"kicking","column":"ConversionAttempts"},{"id":"penaltyGoals","label":"Penalties anotados","category":"kicking","column":"PenaltyGoals"},{"id":"penaltyAttempts","label":"Penalties intentados","category":"kicking","column":"PenaltyAttempts"},{"id":"drops","label":"Drops","category":"kicking","column":"Drops"},{"id":"dropAttempts","label":"Drops intentados","category":"kicking","column":"DropAttempts"},{"id":"kicks","label":"Patadas","category":"kicking","column":"Kicks"},{"id":"scrums","label":"Melés disputadas","category":"setPieces","column":"Scrums"},{"id":"lineouts","label":"Touches disputadas","category":"setPieces","column":"Lineouts"},{"id":"knockOns","label":"Más avants","category":"discipline","column":"KnockOns"},{"id":"infringements","label":"Más infracciones","category":"discipline","column":"Infringements"},{"id":"yellowCards","label":"Más amarillas","category":"discipline","column":"YellowCards"},{"id":"redCards","label":"Más rojas","category":"discipline","column":"RedCards"},{"id":"playedSeconds","label":"Minutos jugados","category":"participation","column":"PlayedSeconds"},{"id":"appearances","label":"Partidos jugados","category":"participation","column":"Appearances"}]
}
ClassMethod Project(key As %String, d As %DynamicObject)
{
    set game=$piece(key,"|",1),fixture=##class(Rugby.Service.Store).Get("Fixture",d.fixtureId,0)
    if '$isobject(fixture) quit
    set competition=d.%Get("competitionKey",fixture.%Get("competitionKey")),finished=d.%Get("matchFinished",fixture.status="finished")
    if (competition="")||('finished) quit
    set o=##class(Rugby.Analytics.PlayerMatch).RecordKeyIndexOpen(key)
    if '$isobject(o) set o=##class(Rugby.Analytics.PlayerMatch).%New(),o.RecordKey=key
    set o.GameId=game,o.CompetitionId=competition,o.PlayerId=d.playerId,o.ClubId=d.clubId,o.PlayerName=d.playerName,o.GameDay=d.day,o.IncompleteRecord='d.%Get("complete",0),catalog=..Catalog()
    for i=0:1:catalog.%Size()-1 {
        set item=catalog.%Get(i),field=item.id
        if field="appearances" continue
        set $property(o,item.column)=$select(field="playedSeconds":d.%Get(field,0),1:d.stats.%Get(field,0))
    }
    set sc=o.%Save()
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
}
ClassMethod Initialize()
{
    if $get(^RugbySchema("competitionStatisticsVersion"))=..#VERSION quit
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando estadísticas.")
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub()
    try {
        set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("SELECT ID,Payload FROM Rugby_Model.PlayerMatchStats")
        if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        set rows=q.%Execute()
        while rows.%Next() {
            set key=rows.%Get("ID"),%RugbyGame=$piece(key,"|",1),d=##class(%DynamicObject).%FromJSON(rows.%Get("Payload"))
            do ..Project(key,d)
        }
        set ^RugbySchema("competitionStatisticsVersion")=..#VERSION
    } catch ex {
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
}
ClassMethod RemoveGame(game As %String)
{
    set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("DELETE FROM Rugby_Analytics.PlayerMatch WHERE GameId = ?")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set rows=q.%Execute(game)
    if rows.%SQLCODE<0 do ##class(Rugby.Service.Store).Fail(500,"STATISTICS","No se pudieron eliminar las estadísticas.")
}
ClassMethod Identity(pid As %String, competition As %String) As %DynamicObject
{
    set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("SELECT TOP 1 ClubId,PlayerName FROM Rugby_Analytics.PlayerMatch WHERE GameId = ? AND CompetitionId = ? AND PlayerId = ? AND PlayedSeconds > 0 ORDER BY GameDay DESC,ID DESC")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set rows=q.%Execute(##class(Rugby.Service.Store).Game(),competition,pid),result={"playerId":(pid),"name":(pid),"clubId":"","clubName":""}
    if rows.%Next() {
        set result.name=rows.%Get("PlayerName"),result.clubId=rows.%Get("ClubId"),club=##class(Rugby.Service.Store).Get("Club",result.clubId,0)
        if $isobject(club) set result.clubName=club.%Get("shortName",club.name)
    }
    set current=##class(Rugby.Service.Store).Get("Player",pid,0)
    if $isobject(current) set result.name=current.name
    quit result
}
ClassMethod Top(id As %String) As %DynamicObject
{
    set competition=##class(Rugby.Service.Store).Get("Competition",id),catalog=..Catalog(),sql="SELECT %EXACT(PlayerId) AS PlayerId,COUNT(*) AS Games,SUM(IncompleteRecord) AS Partials",items=[],identities={},partial=0,players=0
    for i=0:1:catalog.%Size()-1 { set metric=catalog.%Get(i) if metric.id'="appearances" set sql=sql_",SUM("_metric.column_") AS S"_i }
    set sql=sql_" FROM Rugby_Analytics.PlayerMatch WHERE GameId = ? AND CompetitionId = ? AND PlayedSeconds > 0 GROUP BY %EXACT(PlayerId)"
    set q=##class(%SQL.Statement).%New(),sc=q.%Prepare(sql)
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set rows=q.%Execute(##class(Rugby.Service.Store).Game(),id)
    if rows.%SQLCODE<0 do ##class(Rugby.Service.Store).Fail(500,"STATISTICS","No se pudieron consultar las estadísticas.")
    while rows.%Next() {
        set pid=rows.%Get("PlayerId"),games=rows.%Get("Games"),players=players+1,partial=partial+rows.%Get("Partials")
        for i=0:1:catalog.%Size()-1 {
            set metric=catalog.%Get(i),value=$select(metric.id="appearances":games,1:rows.%Get("S"_i))
            if metric.id="playedSeconds" set value=value/60
            if value>0 set ranked(i,-value,pid)=games
        }
    }
    for i=0:1:catalog.%Size()-1 {
        set metric=catalog.%Get(i),leaders=[],score=""
        for {
            set score=$order(ranked(i,score)) quit:score=""  quit:leaders.%Size()>=10
            set pid=""
            for {
                set pid=$order(ranked(i,score,pid)) quit:pid=""  quit:leaders.%Size()>=10
                if 'identities.%IsDefined(pid) do identities.%Set(pid,..Identity(pid,id))
                set entry=##class(%DynamicObject).%FromJSON(identities.%Get(pid).%ToJSON()),entry.rank=leaders.%Size()+1,entry.value=-score,entry.appearances=ranked(i,score,pid)
                do leaders.%Push(entry)
            }
        }
        do metric.%Remove("column")
        set metric.leaders=leaders
        do items.%Push(metric)
    }
    quit {"competitionId":(id),"season":(competition.season),"players":(players),"partialRecords":(partial),"metrics":(items)}
}
}
