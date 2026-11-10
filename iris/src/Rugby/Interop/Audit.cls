Class Rugby.Interop.Audit Extends %RegisteredObject
{
ClassMethod Sanitize(d As %DynamicAbstractObject) As %DynamicAbstractObject
{
    set out=$classmethod($classname(d),"%FromJSON",d.%ToJSON()),it=out.%GetIterator()
    while it.%GetNext(.key,.value) {
        set name=$zcvt(key,"L")
        if $find(name,"password")||$find(name,"token")||$find(name,"secret")||$listfind($listbuild("authorization","cookie","salt","hash","jwt"),name) { do out.%Set(key,"[REDACTED]") continue }
        if $isobject(value) do out.%Set(key,..Sanitize(value))
    }
    quit out
}
}
