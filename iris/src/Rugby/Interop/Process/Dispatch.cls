Class Rugby.Interop.Process.Dispatch Extends Ens.BusinessProcess
{
// Synchronous in-process dispatch preserves the CSP context and keeps credentials in memory only.
Parameter INVOCATION = "InProc";
Method OnRequest(pRequest As Rugby.Interop.Message.Request, Output pResponse As Rugby.Interop.Message.Response) As %Status
{
    set start=$zh,%RugbyAuditCorrelation=pRequest.CorrelationId,%RugbyAuditSession=..%SessionId,%RugbyAuditUser="",%RugbyQuery=##class(%DynamicObject).%FromJSON(pRequest.QueryJSON)
    set target=$select(pRequest.Channel="simulation":"Simulation.Operation",pRequest.Channel="system":"System.Operation",(pRequest.Method="POST")&&(pRequest.Resource="clubs")&&(pRequest.Child="advance-day"):"Rivals.Process",((pRequest.Resource="transfer-market")||(pRequest.Resource="negotiations")||((pRequest.Resource="players")&&((pRequest.Child="negotiate")||(pRequest.Child="renew")))||((pRequest.Resource="clubs")&&(pRequest.Child="promote"))):"Transfers.Operation",pRequest.Resource="admin":"Admin.Operation",pRequest.Resource="auth":"Access.Operation",pRequest.Resource="games":"Games.Operation",(pRequest.Resource="clubs")&&$listfind($listbuild("finances","financial-director","financial-movements","salary-budget"),pRequest.Child):"Finance.Operation",pRequest.Resource="matches":"Matches.Operation",pRequest.Resource="competitions":"Competition.Operation",pRequest.Resource="health":"System.Operation",1:"Club.Operation")
    set sc=..SendRequestSync(target,pRequest,.pResponse,120,"Ejecutar "_pRequest.Resource_"/"_pRequest.Child)
    if $system.Status.IsError(sc) quit sc
    set pResponse.SessionId=..%SessionId,pResponse.DurationMs=($zh-start)*1000
    if pResponse.HTTPStatus>=500 { $$$LOGERROR(pResponse.CorrelationId_" "_pResponse.ErrorCode) }
    elseif pResponse.HTTPStatus>=400 { $$$LOGWARNING(pResponse.CorrelationId_" "_pResponse.ErrorCode) }
    quit $$$OK
}
}
