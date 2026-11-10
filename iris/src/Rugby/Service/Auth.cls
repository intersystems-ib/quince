Class Rugby.Service.Auth Extends %RegisteredObject
{
ClassMethod Now() As %Integer
{
    set h=$ztimestamp
    quit (($piece(h,",",1)-47117)*86400)+$piece(h,",",2)
}
ClassMethod Init()
{
    if '$data(^RugbyAuth("secret")) set ^RugbyAuth("secret")=$system.Encryption.GenCryptRand(32)
}
ClassMethod Encode(s As %String) As %String
{
    quit $translate($system.Encryption.Base64Encode(s),"+/="_$char(10,13),"-_")
}
ClassMethod Decode(s As %String) As %String
{
    set s=$translate(s,"-_","+/")
    for {
        quit:(($length(s)#4)=0)
        set s=s_"="
    }
    quit $system.Encryption.Base64Decode(s)
}
ClassMethod Equal(a As %String, b As %String) As %Boolean
{
    set bad=$length(a)'=$length(b)
    for i=1:1:$length(a) { set bad=bad+($ascii(a,i)'=$ascii(b,i)) }
    quit bad=0
}
ClassMethod Cookie(value As %String, age As %Integer)
{
    set secure=$select(%request.GetCgiEnv("HTTPS")="on":"; Secure",1:"")
    do %response.SetHeader("Set-Cookie","rugby_session="_value_"; Path=/api/v1; HttpOnly; SameSite=Strict; Max-Age="_age_secure)
}
ClassMethod Token() As %String
{
    set header=%request.GetCgiEnv("HTTP_AUTHORIZATION")
    if $extract(header,1,7)="Bearer " quit $extract(header,8,*)
    set cookies=%request.GetCgiEnv("HTTP_COOKIE"),token=""
    for i=1:1:$length(cookies,";") { set part=$zstrip($piece(cookies,";",i),"<>W") if $piece(part,"=",1)="rugby_session" set token=$piece(part,"=",2,*) }
    quit token
}
ClassMethod Require(token As %String = "") As %DynamicObject
{
    if token="" set token=..Token()
    set valid=0
    try {
        if ($length(token,".")'=3)||($length(token)>4096) throw ##class(%Exception.General).%New("JWT")
        set data=$piece(token,".",1,2),sig=..Encode($system.Encryption.HMACSHA(256,data,^RugbyAuth("secret")))
        if '..Equal(sig,$piece(token,".",3)) throw ##class(%Exception.General).%New("JWT")
        set header=##class(%DynamicObject).%FromJSON(..Decode($piece(token,".",1))),claims=##class(%DynamicObject).%FromJSON(..Decode($piece(token,".",2)))
        if (header.alg'="HS256")||(header.typ'="JWT")||(claims.iss'="quince")||(claims.aud'="rugby-manager")||(claims.exp<=..Now())||(claims.iat>..Now()) throw ##class(%Exception.General).%New("JWT")
        if $get(^RugbyAuth("sessions",claims.jti))'=claims.sub throw ##class(%Exception.General).%New("JWT")
        set user=##class(%DynamicObject).%FromJSON(^RugbyAuth("users",claims.sub)),%RugbyUser=user.id,%RugbySession=claims.jti,valid=1
    } catch ex { set valid=0 }
    if 'valid do ##class(Rugby.Service.Store).Fail(401,"UNAUTHORIZED","Inicia sesión para continuar.")
    quit {"id":(user.id),"username":(user.username)}
}
ClassMethod Resolve(method As %String, action As %String, b As %DynamicObject) As %DynamicObject
{
    if (method="GET")&&(action="me") quit ..Require()
    if method'="POST" do ##class(Rugby.Service.Store).Fail(404,"ROUTE_NOT_FOUND","Ruta no disponible.")
    if action="logout" {
        try { set u=..Require() do ##class(Rugby.Service.Games).PauseUser() kill ^RugbyAuth("sessions",%RugbySession) } catch ignored { }
        do ..Cookie("",0)
        quit {"signedOut":true}
    }
    if (action'="login")&&(action'="register") do ##class(Rugby.Service.Store).Fail(404,"ROUTE_NOT_FOUND","Ruta no disponible.")
    set username=$zcvt($zstrip(b.%Get("username"),"<>W"),"L"),password=b.%Get("password"),now=..Now(),bucket=now\60,ip=%request.GetCgiEnv("REMOTE_ADDR")
    if ($length(username)<3)||($length(username)>40)||($translate(username,"abcdefghijklmnopqrstuvwxyz0123456789-_.","")'="") do ##class(Rugby.Service.Store).Fail(422,"USERNAME","El usuario debe tener de 3 a 40 letras, números, puntos o guiones.")
    if ($length(password)<10)||($length(password)>128) do ##class(Rugby.Service.Store).Fail(422,"PASSWORD","La contraseña debe tener entre 10 y 128 caracteres.")
    if $get(^RugbyAuth("attempts",ip,bucket))>=10 do ##class(Rugby.Service.Store).Fail(429,"LOGIN_LIMIT","Demasiados intentos. Espera un minuto.")
    set attempts=$increment(^RugbyAuth("attempts",ip,bucket))
    if action="register" {
        if $data(^RugbyAuth("names",username)) do ##class(Rugby.Service.Store).Fail(409,"USERNAME_TAKEN","Ese usuario ya está registrado.")
        set uid=$system.Util.CreateGUID(),salt=..Encode($system.Encryption.GenCryptRand(24)),hash=..Encode($system.Encryption.PBKDF2($zcvt(password,"O","UTF8"),600000,salt,32,256)),user={"id":(uid),"username":(username),"salt":(salt),"hash":(hash),"createdAt":(now)}
        set ^RugbyAuth("users",uid)=user.%ToJSON(),^RugbyAuth("names",username)=uid
    } else {
        set uid=$get(^RugbyAuth("names",username)),salt="unknown-user-salt",expected=""
        if uid'="" { set user=##class(%DynamicObject).%FromJSON(^RugbyAuth("users",uid)),salt=user.salt,expected=user.hash }
        set hash=..Encode($system.Encryption.PBKDF2($zcvt(password,"O","UTF8"),600000,salt,32,256))
        if '..Equal(hash,expected) do ##class(Rugby.Service.Store).Fail(401,"LOGIN_FAILED","Usuario o contraseña incorrectos.")
    }
    set sid=..Encode($system.Encryption.GenCryptRand(24)),claims={"sub":(uid),"jti":(sid),"iss":"quince","aud":"rugby-manager","iat":(now),"exp":(now+28800)},header={"alg":"HS256","typ":"JWT"},data=..Encode(header.%ToJSON())_"."_..Encode(claims.%ToJSON()),token=data_"."_..Encode($system.Encryption.HMACSHA(256,data,^RugbyAuth("secret")))
    set ^RugbyAuth("sessions",sid)=uid
    do ..Cookie(token,28800)
    quit {"user":{"id":(uid),"username":(username)},"expiresAt":(now+28800)}
}
}
