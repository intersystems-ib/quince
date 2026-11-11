Class Rugby.Service.Games Extends %RegisteredObject
{
ClassMethod Initialize()
{
    if '$get(^RugbySchema(10)) {
        // The user requested a complete restart of the former single local game.
        for kind="Club","Player","Lineup","LineupSlot","Tactic","TrainingPlan","TrainingExecution","FinancialMovement","Fixture","Match","MatchPlayer","MatchEvent","MatchCommand","Coach","TechnicalStaff","StaffContract","Competition","PlayerContract","RivalExecution","Negotiation" {
            set sc=$classmethod("Rugby.Model."_kind,"%DeleteExtent")
            if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        }
        kill ^RugbyWorld,^RugbyCatalog,^RugbyRetry,^RugbyIds,^RugbySeed
        set ^RugbySchema(10)=1
    }
    set %RugbyGame="template",%RugbyManagedClub="c1"
    do ##class(Rugby.Seed.Initial).Run()
}
ClassMethod Select(id As %String)
{
    if id="" do ##class(Rugby.Service.Store).Fail(404,"GAME_NOT_FOUND","Selecciona una partida para continuar.")
    if '$data(^RugbyGames(id)) do ##class(Rugby.Service.Store).Fail(404,"GAME_NOT_FOUND","No se encuentra la partida.")
    set game=##class(%DynamicObject).%FromJSON(^RugbyGames(id))
    if game.userId'=$get(%RugbyUser) do ##class(Rugby.Service.Store).Fail(404,"GAME_NOT_FOUND","No se encuentra la partida.")
    set %RugbyGame=id,%RugbyManagedClub=game.clubId
}
ClassMethod List() As %DynamicObject
{
    set items=[],id="",oldGame=$get(%RugbyGame,"template"),oldClub=$get(%RugbyManagedClub,"c1")
    for { set id=$order(^RugbyGames(id)) quit:id=""  set game=##class(%DynamicObject).%FromJSON(^RugbyGames(id)) if game.userId=%RugbyUser {
        set %RugbyGame=id,%RugbyManagedClub=game.clubId,c=##class(Rugby.Service.Store).Get("Club",game.clubId)
        set game.date=c.date,game.balance=c.balance
        do game.%Remove("userId"),items.%Push(game)
    } }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    quit {"items":(items)}
}
ClassMethod Create(b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyGameRetry(%RugbyUser,key)) {
        set id=^RugbyGameRetry(%RugbyUser,key)
        if $data(^RugbyGameDeletions(%RugbyUser,id)) do ##class(Rugby.Service.Store).Fail(410,"GAME_DELETED","La partida de esta solicitud ya fue eliminada. Crea una nueva partida.")
        do ..Select(id)
        quit ##class(%DynamicObject).%FromJSON(^RugbyGames(id))
    }
    set %RugbyGame="template",%RugbyManagedClub="c1",club=##class(Rugby.Service.Store).Get("Club",b.%Get("clubId")),name=$zstrip(b.%Get("name"),"<>W")
    if (club.competitionId'=b.%Get("divisionId"))||('$listfind($listbuild(416,417),b.%Get("divisionId"))) do ##class(Rugby.Service.Store).Fail(422,"DIVISION_CLUB","Elige un club de la división seleccionada.")
    if ($length(name)<1)||($length(name)>60) do ##class(Rugby.Service.Store).Fail(422,"GAME_NAME","Da un nombre a la partida, de hasta 60 caracteres.")
    set id=$system.Util.CreateGUID(),%RugbyGame=id,%RugbyManagedClub=club.id
    do ##class(Rugby.Seed.Initial).Run()
    set game={"id":(id),"userId":(%RugbyUser),"name":(name),"clubId":(club.id),"clubName":(club.name),"divisionId":(club.competitionId),"division":(club.competition),"date":"2026-09-01","createdAt":(##class(Rugby.Service.Auth).Now()),"updatedAt":(##class(Rugby.Service.Auth).Now()),"active":false}
    do ##class(Rugby.Service.Rivals).Initialize(),##class(Rugby.Service.Transfers).Initialize()
    set finance=##class(Rugby.Service.Finance).Initialize(),payroll=##class(Rugby.Service.Payroll).Initialize(),staffNames=##class(Rugby.Seed.StaffNames).Initialize(),monthly=##class(Rugby.Service.MonthlyPayroll).Initialize(),pool=##class(Rugby.Service.TransferPool).Initialize(),staffPay=##class(Rugby.Service.StaffPay).Initialize(),talent=##class(Rugby.Service.TalentScale).Apply()
    set training=##class(Rugby.Service.Store).Get("TrainingPlan",club.id),weekly=##class(Rugby.Service.WeeklyTraining).Save(club.id,{"version":(training.version),"weekly":(##class(Rugby.Service.WeeklyTraining).Defaults())})
    set invitation=##class(Rugby.Service.FriendlyRequests).Tick(),progress=##class(Rugby.Service.AttributeProgress).Initialize()
    set ^RugbyGames(id)=game.%ToJSON(),^RugbyGameRetry(%RugbyUser,key)=id
    quit game
}
ClassMethod Load(id As %String) As %DynamicObject
{
    do ..Select(id)
    set other=""
    for { set other=$order(^RugbyGames(other)) quit:other=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(other)) if g.userId=%RugbyUser { do g.%Set("active",other=id,"boolean") set ^RugbyGames(other)=g.%ToJSON() } }
    quit ##class(%DynamicObject).%FromJSON(^RugbyGames(id))
}
ClassMethod Unload(id As %String) As %DynamicObject
{
    do ..Select(id)
    set g=##class(%DynamicObject).%FromJSON(^RugbyGames(id))
    do g.%Set("active",0,"boolean")
    set ^RugbyGames(id)=g.%ToJSON()
    quit {"saved":true}
}
ClassMethod PauseUser()
{
    set id=""
    for { set id=$order(^RugbyGames(id)) quit:id=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(id)) if g.userId=%RugbyUser { do g.%Set("active",0,"boolean") set ^RugbyGames(id)=g.%ToJSON() } }
}
ClassMethod Delete(id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    // HTTP mutations hold RugbyWrite and an enclosing transaction, shared with the worker.
    do ##class(Rugby.Service.Store).Key(key)
    if $data(^RugbyGameDeletions(%RugbyUser,id)) {
        set %RugbyGame=id
        quit ##class(%DynamicObject).%FromJSON(^RugbyGameDeletions(%RugbyUser,id))
    }
    do ..Select(id)
    if b.%Get("confirm")'=1 do ##class(Rugby.Service.Store).Fail(422,"DELETE_CONFIRMATION","Confirma que deseas eliminar esta partida de forma definitiva.")
    set game=##class(%DynamicObject).%FromJSON(^RugbyGames(id)),counts={},total=0,kind=""
    // Delete only stable keys belonging to this world; never delete an entire model extent.
    for {
        set kind=$order(^RugbyWorld(id,"catalog",kind))
        quit:kind=""
        set entity="",count=0
        for {
            set entity=$order(^RugbyWorld(id,"catalog",kind,entity))
            quit:entity=""
            set sc=$classmethod("Rugby.Model."_kind,"%DeleteId",id_"|"_entity)
            if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
            set count=count+1,total=total+1
        }
        do counts.%Set(kind,count)
    }
    kill ^RugbyWorld(id),^RugbyGames(id)
    // Small owner-scoped receipt makes retries safe without retaining the game data.
    set result={"deleted":true,"gameId":(id),"name":(game.name),"deletedAt":(##class(Rugby.Service.Auth).Now()),"recordsDeleted":(total),"entities":(counts)}
    set ^RugbyGameDeletions(%RugbyUser,id)=result.%ToJSON()
    quit result
}
ClassMethod Touch()
{
    set id=##class(Rugby.Service.Store).Game()
    if '$data(^RugbyGames(id)) quit
    set g=##class(%DynamicObject).%FromJSON(^RugbyGames(id)),c=##class(Rugby.Service.Store).Get("Club",g.clubId),g.date=c.date,g.updatedAt=##class(Rugby.Service.Auth).Now(),^RugbyGames(id)=g.%ToJSON()
}
}
