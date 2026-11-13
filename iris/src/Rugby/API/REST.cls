Class Rugby.API.REST Extends %CSP.REST
{
Parameter CHARSET = "utf-8";
Parameter UseSession = 0;
XData UrlMap
{
<Routes>
<Route Url="/:resource" Method="GET" Call="Get1"/>
<Route Url="/:resource/:id" Method="GET" Call="Get2"/>
<Route Url="/:resource/:id/:child" Method="GET" Call="Get3"/>
<Route Url="/:resource" Method="POST" Call="Post1"/>
<Route Url="/:resource/:id" Method="POST" Call="Post2"/>
<Route Url="/:resource/:id" Method="PUT" Call="Put2"/>
<Route Url="/:resource/:id" Method="DELETE" Call="Delete2"/>
<Route Url="/:resource/:id/:child" Method="POST" Call="Post3"/>
<Route Url="/:resource/:id/:child" Method="PUT" Call="Put3"/>
<Route Url="/clubs/:id/academy/:pid/promote" Method="POST" Call="Promote"/>
</Routes>
}
ClassMethod Get1(resource As %String) As %Status { quit ..Handle("GET",resource) }
ClassMethod Get2(resource As %String, id As %String) As %Status { quit ..Handle("GET",resource,id) }
ClassMethod Get3(resource As %String, id As %String, child As %String) As %Status { quit ..Handle("GET",resource,id,child) }
ClassMethod Post1(resource As %String) As %Status { quit ..Handle("POST",resource) }
ClassMethod Post2(resource As %String, id As %String) As %Status { quit ..Handle("POST",resource,id) }
ClassMethod Put2(resource As %String, id As %String) As %Status { quit ..Handle("PUT",resource,id) }
ClassMethod Delete2(resource As %String, id As %String) As %Status { quit ..Handle("DELETE",resource,id) }
ClassMethod Post3(resource As %String, id As %String, child As %String) As %Status { quit ..Handle("POST",resource,id,child) }
ClassMethod Put3(resource As %String, id As %String, child As %String) As %Status { quit ..Handle("PUT",resource,id,child) }
ClassMethod Promote(id As %String, pid As %String) As %Status { quit ..Handle("POST","clubs",id,"promote",pid) }
ClassMethod Handle(method As %String, resource As %String, id As %String = "", child As %String = "", pid As %String = "") As %Status
{
    set %response.ContentType="application/json",%response.CharSet="utf-8",request=##class(Rugby.Interop.Message.Request).%New()
    set request.CorrelationId=$system.Util.CreateGUID(),request.Method=method,request.Resource=resource,request.EntityId=id,request.Child=child,request.PlayerId=pid
    set request.GameId=%request.GetCgiEnv("HTTP_X_GAME_ID"),request.IdempotencyKey=%request.GetCgiEnv("HTTP_IDEMPOTENCY_KEY")
    do %response.SetHeader("X-Request-Id",request.CorrelationId),%response.SetHeader("Cache-Control","no-store")
    set %RugbyInputBody={},%RugbyQuery={}
    for name="offset","limit","date","variant","role","afterSequence","correlationId","before","lineupId" { if $data(%request.Data(name,1)) do %RugbyQuery.%Set(name,%request.Data(name,1)) }
    set request.QueryJSON=%RugbyQuery.%ToJSON()
    set bodyLimit=$select(resource="admin":800000,1:65536)
    if method'="GET" {
        if %request.Content.Size>bodyLimit { set request.InputErrorStatus=413,request.InputErrorCode="BODY_TOO_LARGE",request.InputErrorMessage="Solicitud demasiado grande." }
        else {
            if %request.Content.Size {
                try {
                    set payload=$zcvt(%request.Content.Read(bodyLimit),"I","UTF8"),%RugbyInputBody=##class(%DynamicObject).%FromJSON(payload)
                    if '%RugbyInputBody.%IsA("%Library.DynamicObject") throw ##class(%Exception.General).%New("JSON")
                } catch parse { set %RugbyInputBody={},request.InputErrorStatus=400,request.InputErrorCode="INVALID_JSON",request.InputErrorMessage="El cuerpo debe ser un objeto JSON válido." }
            }
        }
    }
    set request.BodyJSON=##class(Rugby.Interop.Audit).Sanitize(%RugbyInputBody).%ToJSON()
    try {
        set sc=##class(Ens.Director).CreateBusinessService("HTTP.In",.service)
        if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        set sc=service.ProcessInput(request,.response)
        if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
        set %response.Status=response.HTTPStatus_" "_$select(response.HTTPStatus<400:"OK",1:"Error")
        do %response.SetHeader("X-Interop-Session-Id",response.SessionId)
        write response.BodyJSON
    } catch ex {
        set %response.Status="503 Service Unavailable"
        set ^RugbyAPIError(request.CorrelationId)=ex.DisplayString()
        write {"code":"INTEROP_UNAVAILABLE","message":"El motor de operaciones no está disponible. Reintenta en unos instantes.","requestId":(request.CorrelationId)}.%ToJSON()
    }
    kill %RugbyInputBody,%RugbyQuery,%RugbyAuditCorrelation,%RugbyAuditSession,%RugbyAuditUser
    quit $$$OK
}
}
