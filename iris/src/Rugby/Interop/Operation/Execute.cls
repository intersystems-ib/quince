Class Rugby.Interop.Operation.Execute Extends Ens.BusinessOperation
{
Parameter INVOCATION = "InProc";
Method Execute(pRequest As Rugby.Interop.Message.Request, Output pResponse As Rugby.Interop.Message.Response) As %Status
{
    set pResponse=##class(Rugby.Interop.Message.Response).%New(),pResponse.CorrelationId=pRequest.CorrelationId,held=0
    set %RugbyGame="template",%RugbyManagedClub="c1",%RugbyUser="",%RugbySession=""
    try {
        if (pRequest.Channel="simulation")&&(pRequest.Resource="simulation") {
            set %RugbyAuditUser="system:simulation"
            if '$data(^RugbyGames(pRequest.GameId)) do ##class(Rugby.Service.Store).Fail(404,"GAME_NOT_FOUND","Partida inexistente.")
            set game=##class(%DynamicObject).%FromJSON(^RugbyGames(pRequest.GameId)),%RugbyGame=game.id,%RugbyManagedClub=game.clubId
            set before=##class(Rugby.Service.Store).Get("Match",pRequest.EntityId),input=##class(%DynamicObject).%FromJSON(pRequest.BodyJSON)
            set processed=##class(Rugby.Job.Worker).Cycle(pRequest.EntityId,input.elapsed),after=##class(Rugby.Service.Store).Get("Match",pRequest.EntityId)
            set out={"gameId":(game.id),"matchId":(after.id),"processed":(processed),"clockBefore":(before.clock),"clockAfter":(after.clock),"sequenceBefore":(before.sequence),"sequenceAfter":(after.sequence),"status":(after.status),"homeScore":(after.homeScore),"awayScore":(after.awayScore),"version":(after.version)}
            set events=[]
            for seq=before.sequence+1:1:after.sequence { do events.%Push(##class(Rugby.Service.Store).Get("MatchEvent",after.id_"-"_$translate($justify(seq,6)," ","0"))) }
            set movements=##class(Rugby.Service.Store).All("FinancialMovement","source","match-"_after.id)
            set pResponse.DetailsJSON={"events":(events),"tacticalAssessment":(after.%Get("aiTacticalAssessment")),"matchEconomy":(after.%Get("economy")),"pause":{"speed":(after.speed),"reason":(after.%Get("pauseReason")),"message":(after.%Get("pauseMessage")),"clock":(after.clock)},"settled":(after.settled),"moraleResults":(after.%Get("moraleResults")),"financialMovements":(movements),"classification":(after.%Get("classification"))}.%ToJSON()
        } elseif (pRequest.Channel="system")&&(pRequest.Resource="bootstrap") {
            set %RugbyAuditUser="system:startup"
            do ##class(Rugby.Service.Auth).Init(),##class(Rugby.Service.Games).Initialize(),##class(Rugby.Service.Rivals).InitializeAll(),##class(Rugby.Service.Transfers).InitializeAll()
            set cup=##class(Rugby.Service.Cup).InitializeAll()
            set imported=##class(Rugby.Seed.RealPlayers).InitializeAll(),kits=##class(Rugby.Service.Kits).InitializeAll(),morale=##class(Rugby.Service.Morale).InitializeAll(),seasons=##class(Rugby.Service.Seasons).InitializeAll(),quality=##class(Rugby.Seed.Quality).InitializeAll(),venues=##class(Rugby.Seed.Venues).InitializeAll(),finance=##class(Rugby.Service.Finance).InitializeAll(),payroll=##class(Rugby.Service.Payroll).InitializeAll(),staffNames=##class(Rugby.Seed.StaffNames).InitializeAll(),monthly=##class(Rugby.Service.MonthlyPayroll).InitializeAll(),pool=##class(Rugby.Service.TransferPool).InitializeAll(),staffPay=##class(Rugby.Service.StaffPay).InitializeAll(),planning=##class(Rugby.Service.FinancialPlanning).InitializeAll(),talent=##class(Rugby.Service.TalentScale).InitializeAll(),invitations=##class(Rugby.Service.FriendlyRequests).InitializeAll(),pResponse.DetailsJSON={"realRosterImports":(imported),"kitImports":(kits),"moraleImports":(morale),"seasonImports":(seasons),"qualityCalibration":(quality),"venueImports":(venues),"financeImports":(finance),"payrollAdjustments":(payroll),"staffIdentityRepairs":(staffNames),"monthlyPayrollAdjustments":(monthly),"sharedTransferMarket":(pool),"staffSalaryAdjustments":(staffPay),"financialPlanning":(planning),"talentScale":(talent),"friendlyInvitations":(invitations)}.%ToJSON()
            set out={"initialized":true}
        } else {
            if (pRequest.Resource'="auth")&&(pRequest.Resource'="health") {
                set user=##class(Rugby.Service.Auth).Require(),%RugbyAuditUser=user.id
            }
            if (pRequest.Resource'="auth")&&(pRequest.Resource'="health")&&(pRequest.Resource'="games")&&(pRequest.Resource'="game-catalog") do ##class(Rugby.Service.Games).Select(pRequest.GameId)
            lock +^RugbyWrite:3
            if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Operación en curso. Reintenta.")
            set held=1
            if pRequest.InputErrorStatus do ##class(Rugby.Service.Store).Fail(pRequest.InputErrorStatus,pRequest.InputErrorCode,pRequest.InputErrorMessage)
            if pRequest.Method'="GET" {
                set origin=%request.GetCgiEnv("HTTP_ORIGIN")
                if (origin'="")&&($piece(origin,"/",3)'=%request.GetCgiEnv("HTTP_HOST")) do ##class(Rugby.Service.Store).Fail(403,"ORIGIN","Origen de la solicitud no permitido.")
                if pRequest.Resource'="auth" tstart
            }
            // InProc: raw HTTP credentials are never properties of a persistent message.
            set body=$select($isobject($get(%RugbyInputBody)):%RugbyInputBody,1:##class(%DynamicObject).%FromJSON(pRequest.BodyJSON))
            set out=##class(Rugby.Service.Router).Resolve(pRequest.Method,pRequest.Resource,pRequest.EntityId,pRequest.Child,pRequest.PlayerId,body,pRequest.IdempotencyKey)
            if (pRequest.Method'="GET")&&(pRequest.Resource'="auth") { do ##class(Rugby.Service.Games).Touch() tcommit }
            if (pRequest.Resource="clubs")&&(pRequest.Child="advance-day") {
                set execution=##class(Rugby.Service.Store).Get("TrainingExecution",pRequest.EntityId_"-day"_out.day,0),movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId",pRequest.EntityId),daily=[]
                for i=0:1:movements.%Size()-1 { set movement=movements.%Get(i) if movement.day=out.day do daily.%Push(movement) }
                set rivals=##class(Rugby.Service.Store).Get("RivalExecution","rivals-day-"_out.day,0)
                set pResponse.DetailsJSON={"trainingExecution":(execution),"financialMovements":(daily),"rivalsExecution":(rivals),"financeExecution":(rivals.%Get("financeExecution"))}.%ToJSON()
            }
            if (pRequest.Resource="clubs")&&(pRequest.Child="training-plan")&&(pRequest.Method="PUT") set pResponse.DetailsJSON={"trainingPlan":(out)}.%ToJSON()
            if (pRequest.Resource="clubs")&&(pRequest.Child="financial-director")&&(pRequest.Method="POST") set pResponse.DetailsJSON={"financialManagement":(out)}.%ToJSON()
            if (pRequest.Resource="games")&&(pRequest.Method="DELETE") set pResponse.DetailsJSON={"gameDeletion":(out)}.%ToJSON()
            if (pRequest.Resource="matches")&&(pRequest.Child="start")&&(pRequest.Method="POST") set pResponse.DetailsJSON={"tacticalAssessment":(out.%Get("aiTacticalAssessment"))}.%ToJSON()
            if (pRequest.Resource="negotiations")&&(pRequest.Child="sign")&&(pRequest.Method="POST") {
                set contract=##class(Rugby.Service.Store).Get("PlayerContract",out.contractId),movements=##class(Rugby.Service.Store).All("FinancialMovement","source","sign-"_out.id)
                set pResponse.DetailsJSON={"contract":(contract),"financialMovements":(movements)}.%ToJSON()
            }
            if (pRequest.Method="POST")&&(((pRequest.Resource="matches")&&(pRequest.EntityId=""))||((pRequest.Resource="clubs")&&(pRequest.Child="lineups"))) set pResponse.HTTPStatus=201
            if held { lock -^RugbyWrite set held=0 }
        }
        set pResponse.BodyJSON=out.%ToJSON()
        if (pRequest.Resource="auth")&&out.%IsDefined("user") set %RugbyAuditUser=out.user.id
    } catch ex {
        if $tlevel trollback
        if held lock -^RugbyWrite
        set status=+ex.Code
        if (status<400)||(status>599) set status=500
        set code=$select(status=500:"INTERNAL_ERROR",1:ex.Location),message=$select(status=500:"Error del servidor. Consulta los registros con el identificador de solicitud.",1:ex.Name),details={}
        if code="INVALID_LINEUP" {
            try { set errors=##class(%DynamicArray).%FromJSON(message),details.errors=errors,message="Alineación inválida. " for i=0:1:errors.%Size()-1 { set message=message_errors.%Get(i)_" " } } catch ignored { }
        }
        set ^RugbyAPIError(pRequest.CorrelationId)=ex.DisplayString(),pResponse.HTTPStatus=status,pResponse.ErrorCode=code
        set pResponse.BodyJSON={"code":(code),"message":(message),"details":(details),"requestId":(pRequest.CorrelationId)}.%ToJSON()
    }
    if $get(%RugbyAuditUser)="" set %RugbyAuditUser=$get(%RugbyUser)
    set pResponse.UserId=$get(%RugbyAuditUser),pResponse.GameId=$select(##class(Rugby.Service.Store).Game()="template":"",1:##class(Rugby.Service.Store).Game())
    quit $$$OK
}
XData MessageMap
{
<MapItems><MapItem MessageType="Rugby.Interop.Message.Request"><Method>Execute</Method></MapItem></MapItems>
}
}
