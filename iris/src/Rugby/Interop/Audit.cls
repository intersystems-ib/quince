Class Rugby.Interop.Audit Extends %RegisteredObject
{
ClassMethod Sanitize(d As %DynamicAbstractObject) As %DynamicAbstractObject
{
    set out=$classmethod($classname(d),"%FromJSON",d.%ToJSON()),it=out.%GetIterator()
    while it.%GetNext(.key,.value) {
        set name=$zcvt(key,"L")
        if name="cresturl" { do out.%Set(key,"[IMAGE]") continue }
        if $find(name,"password")||$find(name,"token")||$find(name,"secret")||$listfind($listbuild("authorization","cookie","salt","hash","jwt"),name) { do out.%Set(key,"[REDACTED]") continue }
        if $isobject(value) do out.%Set(key,..Sanitize(value))
    }
    quit out
}
ClassMethod Summary(json As %String, limit As %Integer = 2048) As %String
{
    if $length(json)<=limit quit json
    set result={"compacted":true,"characters":($length(json)),"summary":{}}
    try {
        set d=##class(%DynamicObject).%FromJSON(json)
        for field="id","gameId","clubId","matchId","fixtureId","playerId","version","day","date","status","code","message","requestId","homeId","awayId","homeScore","awayScore","clock","sequence","seasonYear","nextSeasonYear","closed","deleted","trainingExecutionId","rivalsExecutionId","contractId","resultsRevision" {
            if d.%IsDefined(field) { set value=d.%Get(field) if '$isobject(value) do result.summary.%Set(field,$extract(value,1,128)) }
        }
        for field="items","results","players","events","clubs","financialMovements" { set value=d.%Get(field) if $isobject(value) do result.summary.%Set(field_"Count",value.%Size()) }
        set club=d.%Get("club")
        if $isobject(club) set result.summary.club={"id":(club.%Get("id")),"day":(club.%Get("day")),"version":(club.%Get("version"))}
    } catch ignored { }
    if $length(result.%ToJSON())>limit set result.summary={}
    quit result.%ToJSON()
}
}
