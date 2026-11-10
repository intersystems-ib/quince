Class Rugby.Interop.Runtime Extends %RegisteredObject
{
ClassMethod Send(service As %String, request As Rugby.Interop.Message.Request, Output response As Rugby.Interop.Message.Response) As %Status
{
    set sc=##class(Ens.Director).CreateBusinessService(service,.bs)
    if $system.Status.IsError(sc) quit sc
    quit bs.ProcessInput(request,.response)
}
ClassMethod Start()
{
    set sc=##class(Ens.Director).GetProductionStatus(.name,.state)
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    if state'=1 set sc=##class(Ens.Director).StartProduction("Rugby.Interop.Production")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set request=##class(Rugby.Interop.Message.Request).%New(),request.CorrelationId=$system.Util.CreateGUID(),request.Method="SYSTEM",request.Resource="bootstrap"
    set sc=..Send("System.In",request,.response)
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    if response.HTTPStatus>=400 throw ##class(%Exception.General).%New(response.BodyJSON)
    kill %RugbyAuditCorrelation,%RugbyAuditSession,%RugbyAuditUser,%RugbyQuery
}
}
