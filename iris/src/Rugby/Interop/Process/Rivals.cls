Class Rugby.Interop.Process.Rivals Extends Ens.BusinessProcess
{
Parameter INVOCATION = "InProc";
Method OnRequest(pRequest As Rugby.Interop.Message.Request, Output pResponse As Rugby.Interop.Message.Response) As %Status
{
    if (pRequest.Channel'="http")||(pRequest.Resource'="clubs")||(pRequest.Child'="advance-day") quit $system.Status.Error(5001,"Petición de avance diario no válida")
    set sc=..SendRequestSync("Rivals.Operation",pRequest,.pResponse,120,"Entrenamientos y mercado de los 19 clubes rivales")
    if '$system.Status.IsError(sc) set pResponse.SessionId=..%SessionId
    quit sc
}
}
