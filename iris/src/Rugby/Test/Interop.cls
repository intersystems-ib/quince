Class Rugby.Test.Interop Extends %RegisteredObject
{
ClassMethod Run()
{
    set raw={"username":"manager","password":"must-not-persist","nested":{"accessToken":"secret-token","safe":"visible"},"items":[{"secret":"private-key"}]},clean=##class(Rugby.Interop.Audit).Sanitize(raw)
    do ##class(Rugby.Test.Suite).Assert((clean.password="[REDACTED]")&&(clean.nested.accessToken="[REDACTED]")&&(clean.items.%Get(0).secret="[REDACTED]"),"Sensitive fields are recursively removed from production messages")
    do ##class(Rugby.Test.Suite).Assert((raw.password="must-not-persist")&&(clean.nested.safe="visible"),"Sanitizing the trace preserves original in-memory input and normal fields")
    set request=##class(Rugby.Interop.Message.Request).%New(),request.CorrelationId=$system.Util.CreateGUID(),request.Method="GET",request.Resource="health",request.QueryJSON="{}"
    set sc=##class(Rugby.Interop.Runtime).Send("HTTP.In",request,.response)
    do ##class(Rugby.Test.Suite).Assert('$system.Status.IsError(sc),"Business service invokes the process and operation")
    do ##class(Rugby.Test.Suite).Assert((response.HTTPStatus=200)&&(response.SessionId'=""),"Engine assigns an interoperablity session to the HTTP request")
    set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("SELECT COUNT(*) AS Total FROM Ens.MessageHeader WHERE SessionId = ? AND SourceConfigName = 'HTTP.In' AND TargetConfigName = 'API.Process'"),rows=q.%Execute(response.SessionId),next=rows.%Next()
    do ##class(Rugby.Test.Suite).Assert(rows.%Get("Total")>0,"Native message headers retain the service to process trace")
    set q=##class(%SQL.Statement).%New(),sc=q.%Prepare("SELECT COUNT(*) AS Total FROM Ens.MessageHeader WHERE SessionId = ? AND TargetConfigName = 'System.Operation'"),rows=q.%Execute(response.SessionId),next=rows.%Next()
    do ##class(Rugby.Test.Suite).Assert(rows.%Get("Total")>0,"Native message headers retain the process to operation trace")
    kill %RugbyAuditCorrelation,%RugbyAuditSession,%RugbyAuditUser,%RugbyQuery
}
}
