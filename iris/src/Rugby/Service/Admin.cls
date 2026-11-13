Class Rugby.Service.Admin Extends %RegisteredObject
{
ClassMethod Resolve(method As %String, entity As %String, id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    set %RugbyGame="template",%RugbyManagedClub="c1",kind=$select(entity="clubs":"Club",entity="players":"Player",1:"")
    if kind="" do ##class(Rugby.Service.Store).Fail(404,"ROUTE_NOT_FOUND","Ruta de administración no disponible.")
    if method="GET" {
        if id'="" quit ##class(Rugby.Service.Store).Get(kind,id)
        quit {"items":(##class(Rugby.Service.Store).All(kind))}
    }
    if (method="PUT")&&(id'="") quit ..Save(kind,id,b,key)
    if (method="POST")&&(kind="Player")&&(id="") quit ..Save(kind,"",b,key)
    do ##class(Rugby.Service.Store).Fail(404,"ROUTE_NOT_FOUND","Ruta de administración no disponible.")
}
ClassMethod Copy(target As %DynamicObject, field As %String, source As %DynamicObject, sourceField As %String = "")
{
    if sourceField="" set sourceField=field
    set value=source.%Get(sourceField),type=source.%GetTypeOf(sourceField)
    if $isobject(value) { do target.%Set(field,value) }
    else { do target.%Set(field,value,type) }
}
ClassMethod Text(d As %DynamicObject, field As %String, max As %Integer, required As %Boolean = 1)
{
    if d.%GetTypeOf(field)'="string" do ##class(Rugby.Service.Store).Fail(422,"ADMIN_TEXT","Revisa el campo "_field_".")
    set value=$zstrip(d.%Get(field),"<>W")
    if (required&&(value=""))||($length(value)>max) do ##class(Rugby.Service.Store).Fail(422,"ADMIN_TEXT","Revisa el campo "_field_".")
    do d.%Set(field,value)
}
ClassMethod Number(d As %DynamicObject, field As %String, low As %Numeric, high As %Numeric)
{
    if d.%GetTypeOf(field)'="number" do ##class(Rugby.Service.Store).Fail(422,"ADMIN_NUMBER","Revisa el campo "_field_".")
    if (d.%Get(field)<low)||(d.%Get(field)>high) do ##class(Rugby.Service.Store).Fail(422,"ADMIN_NUMBER","Revisa el campo "_field_".")
}
ClassMethod Crest(value As %String)
{
    if value="" quit
    if ($extract(value,1,9)="/crests/")&&($translate($piece(value,"/",3),"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.","")="") quit
    set prefix=$piece(value,",",1),encoded=$piece(value,",",2,*)
    if '$listfind($listbuild("data:image/png;base64","data:image/jpeg;base64","data:image/webp;base64"),prefix) do ##class(Rugby.Service.Store).Fail(422,"CREST_IMAGE","Utiliza una imagen PNG, JPEG o WebP.")
    if ($length(value)>100000)||(encoded="") do ##class(Rugby.Service.Store).Fail(422,"CREST_IMAGE","El escudo es demasiado grande.")
    set valid=0
    try {
        set bytes=$system.Encryption.Base64Decode(encoded)
        if $translate($system.Encryption.Base64Encode(bytes),$char(10,13),"")'=encoded throw ##class(%Exception.General).%New("Image")
        if prefix="data:image/png;base64" set valid=$extract(bytes,1,8)=$char(137,80,78,71,13,10,26,10)
        if prefix="data:image/jpeg;base64" set valid=$extract(bytes,1,3)=$char(255,216,255)
        if prefix="data:image/webp;base64" set valid=($extract(bytes,1,4)="RIFF")&&($extract(bytes,9,12)="WEBP")
    } catch ex { set valid=0 }
    if 'valid do ##class(Rugby.Service.Store).Fail(422,"CREST_IMAGE","El archivo no contiene una imagen válida.")
}
ClassMethod Validate(kind As %String, d As %DynamicObject)
{
    do ..Text(d,"name",160)
    if kind="Club" {
        do ..Text(d,"shortName",60),..Text(d,"officialName",160),..Text(d,"city",100),..Text(d,"color",7)
        if (d.color'?1"#"6AN)||($translate($zcvt(d.color,"L"),"#abcdef0123456789","")'="") do ##class(Rugby.Service.Store).Fail(422,"ADMIN_COLOR","El color debe utilizar el formato #RRGGBB.")
        if d.%GetTypeOf("stadium")'="object" do ##class(Rugby.Service.Store).Fail(422,"ADMIN_STADIUM","Indica el nombre y aforo del campo.")
        do ..Text(d.stadium,"name",160),..Number(d.stadium,"capacity",0,200000)
        do ..Crest(d.%Get("crestUrl"))
    } else {
        set club=##class(Rugby.Service.Store).Get("Club",$select(d.%Get("clubId")="":"c1",1:d.clubId))
        do ..Number(d,"age",15,60),..Number(d,"position",1,15),..Number(d,"energy",0,100),..Number(d,"morale",0,100),..Number(d,"monthlyWage",0,10000000)
        if ('##class(Rugby.Service.Store).Integer(d.age,15,60))||('##class(Rugby.Service.Store).Integer(d.position,1,15)) do ##class(Rugby.Service.Store).Fail(422,"ADMIN_PLAYER","La edad y la posición deben ser números enteros.")
        if '$listfind($listbuild("senior","academy"),d.%Get("category")) do ##class(Rugby.Service.Store).Fail(422,"ADMIN_CATEGORY","Elige primer equipo o cantera.")
        if d.%GetTypeOf("secondary")'="array" do ##class(Rugby.Service.Store).Fail(422,"ADMIN_POSITION","Revisa las posiciones secundarias.")
        for i=0:1:d.secondary.%Size()-1 { if '##class(Rugby.Service.Store).Integer(d.secondary.%Get(i),1,15) do ##class(Rugby.Service.Store).Fail(422,"ADMIN_POSITION","Revisa las posiciones secundarias.") }
        if d.%GetTypeOf("attributes")'="object" do ##class(Rugby.Service.Store).Fail(422,"ADMIN_ATTRIBUTES","Revisa las características del jugador.")
        set catalog=##class(Rugby.Service.Development).Catalog()
        for i=0:1:16 { do ..Number(d.attributes,catalog.%Get(i).id,1,100) }
        set d.birthDay=club.day-(d.age*365),d.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(d.monthlyWage)
        set d.talentScaleVersion=##class(Rugby.Service.TalentScale).#VERSION,d.talentScaleFactor=##class(Rugby.Service.TalentScale).#FACTOR
        set d.average=##class(Rugby.Service.Development).Average(d),d.form=d.average
    }
}
ClassMethod Save(kind As %String, id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set receipt=$get(^RugbyAdmin("retry",$get(%RugbyUser),key)),fingerprint=##class(Rugby.Service.Auth).Encode($system.Encryption.SHAHash(256,kind_"|"_id_"|"_b.%ToJSON()))
    if receipt'="" {
        set saved=##class(%DynamicObject).%FromJSON(receipt)
        if saved.fingerprint'=fingerprint do ##class(Rugby.Service.Store).Fail(409,"IDEMPOTENCY_CONFLICT","La clave de guardado pertenece a otra operación.")
        quit saved.result
    }
    if b.%GetTypeOf("data")'="object" do ##class(Rugby.Service.Store).Fail(422,"ADMIN_DATA","Se requiere un objeto de datos.")
    set d=##class(%DynamicObject).%FromJSON(b.data.%ToJSON()),fresh=id=""
    if fresh {
        set id="custom-"_$system.Util.CreateGUID(),d.id=id,d.available=1,d.recoveryDay=0,d.developmentYear=-1,d.developmentGains={},d.realIdentity=0,d.signedDay=-67
    } else {
        set original=##class(Rugby.Service.Store).Get(kind,id)
        do ##class(Rugby.Service.Store).CheckVersion(original,b)
        if d.%Get("id")'=id do ##class(Rugby.Service.Store).Fail(422,"ADMIN_ID","El identificador no se puede modificar.")
        // World identity and division are structural; competitions keep their ten participants.
        for field="day","date","startDay","season","seasonYear","competitionId","competition" {
            if original.%IsDefined(field) do ..Copy(d,field,original)
        }
    }
    if fresh&&(d.%Get("clubId")="") do ##class(Rugby.Service.Store).Fail(422,"ADMIN_CLUB","Asigna el nuevo jugador a un club.")
    do ..Validate(kind,d)
    set patch=##class(%DynamicObject).%FromJSON($get(^RugbyAdmin("overrides",kind,id),"{}")),it=d.%GetIterator()
    while it.%GetNext(.field,.value) {
        if $listfind($listbuild("id","version"),field) continue
        set changed=fresh
        if 'fresh {
            if original.%IsDefined(field) { set one={},two={} do ..Copy(one,"v",d,field),..Copy(two,"v",original,field) set changed=one.%ToJSON()'=two.%ToJSON() }
            else { set changed=1 }
        }
        if changed do ..Copy(patch,field,d)
    }
    do ##class(Rugby.Service.Store).Put(kind,d)
    set ^RugbyAdmin("overrides",kind,id)=patch.%ToJSON()
    if fresh set ^RugbyAdmin("created",kind,id)=1
    set ^RugbyAdmin("retry",$get(%RugbyUser),key)={"fingerprint":(fingerprint),"result":(d)}.%ToJSON()
    quit d
}
ClassMethod Apply()
{
    for kind="Club","Player" {
        set id=""
        for {
            set id=$order(^RugbyAdmin("overrides",kind,id))
            quit:id=""
            set d=##class(Rugby.Service.Store).Get(kind,id,0)
            if '$isobject(d) {
                if '$get(^RugbyAdmin("created",kind,id)) continue
                set d={"id":(id)}
            }
            set patch=##class(%DynamicObject).%FromJSON(^RugbyAdmin("overrides",kind,id)),it=patch.%GetIterator()
            while it.%GetNext(.field,.value) { do ..Copy(d,field,patch) }
            do ##class(Rugby.Service.Store).Put(kind,d)
        }
    }
    // Transfer or recategorise initial players without leaving invalid starting or reserve slots.
    set lineups=##class(Rugby.Service.Store).All("Lineup")
    for i=0:1:lineups.%Size()-1 {
        set l=lineups.%Get(i),slots=[],bench=[],changed=0
        for j=0:1:l.slots.%Size()-1 { set s=l.slots.%Get(j),p=##class(Rugby.Service.Store).Get("Player",s.playerId,0) if $isobject(p)&&(p.clubId=l.clubId)&&(p.category="senior") { do slots.%Push(s) } else { set s.playerId="" do slots.%Push(s) set changed=1 } }
        for j=0:1:l.bench.%Size()-1 { set pid=l.bench.%Get(j),p=##class(Rugby.Service.Store).Get("Player",pid) if (p.clubId=l.clubId)&&(p.category="senior") { do bench.%Push(pid) } else { set changed=1 } }
        if changed {
            set l.slots=slots,l.bench=bench,called={}
            for j=0:1:slots.%Size()-1 { if slots.%Get(j).playerId'="" do called.%Set(slots.%Get(j).playerId,1) }
            for j=0:1:bench.%Size()-1 { do called.%Set(bench.%Get(j),1) }
            if 'called.%IsDefined(l.captainId) { set l.captainId="" for j=0:1:slots.%Size()-1 { if slots.%Get(j).playerId'="" { set l.captainId=slots.%Get(j).playerId quit } } }
            do ##class(Rugby.Service.Store).Put("Lineup",l)
        }
    }
}
}
