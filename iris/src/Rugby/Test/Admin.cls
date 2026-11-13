Class Rugby.Test.Admin Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run()
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),oldUser=$get(%RugbyUser)
    try {
        set %RugbyGame="template",%RugbyManagedClub="c1",%RugbyUser="admin-unit"
        set c=##class(Rugby.Service.Store).Get("Club","c1"),c.name="Club administrado",c.stadium={"name":"Campo de prueba","capacity":3456},c.crestUrl="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a0X8AAAAASUVORK5CYII=",body={"version":(c.version),"data":(c)}
        set changed=##class(Rugby.Service.Admin).Save("Club","c1",body,"admin-club"),retry=##class(Rugby.Service.Admin).Save("Club","c1",body,"admin-club")
        do ..Assert((changed.name=c.name)&&(retry.version=changed.version),"Club changes and crest are retry safe")
        set caught=0
        try { set bad=##class(Rugby.Service.Admin).Save("Club","c1",body,"admin-stale") } catch ex { set caught=ex.Location="VERSION_CONFLICT" }
        do ..Assert(caught,"Concurrent edits cannot overwrite a newer record")
        set caught=0
        try { do ##class(Rugby.Service.Admin).Crest("data:image/svg+xml;base64,PHN2Zz4=") } catch ex { set caught=ex.Location="CREST_IMAGE" }
        do ..Assert(caught,"Active image formats are rejected")
        set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.name="Jugador administrado",p.attributes.tackling=82.25,body={"version":(p.version),"data":(p)}
        set changed=##class(Rugby.Service.Admin).Save("Player",p.id,body,"admin-player")
        do ..Assert(changed.attributes.tackling=82.25,"Exact edited attributes retain decimals")
        set attrs=##class(%DynamicObject).%FromJSON(p.attributes.%ToJSON()),newPlayer={"name":"Nuevo jugador","clubId":"c2","age":21,"category":"senior","position":2,"secondary":[1,3],"nationality":"España","nationalityCode":"ES","monthlyWage":100000,"energy":100,"morale":100,"attributes":(attrs)}
        set created=##class(Rugby.Service.Admin).Save("Player","",{"data":(newPlayer)},"admin-new")
        do ..Assert((created.clubId="c2")&&(created.attributes.tackling=82.25)&&(created.monthlyWage=100000),"New player belongs to chosen club and shares exact attribute scale")
        set bad=##class(%DynamicObject).%FromJSON(created.%ToJSON()),bad.attributes.speed=101,caught=0
        try { set result=##class(Rugby.Service.Admin).Save("Player",created.id,{"version":(created.version),"data":(bad)},"admin-invalid") } catch ex { set caught=ex.Location="ADMIN_NUMBER" }
        do ..Assert(caught,"Invalid attributes cannot be saved")
        set game=##class(Rugby.Service.Games).Create({"name":"Admin seed test","divisionId":416,"clubId":"c1"},"admin-test-game"),actual=##class(Rugby.Service.Store).Get("Player",created.id)
        do ..Assert((game.clubName="Club administrado")&&(actual.clubId="c2")&&(actual.attributes.tackling=82.25),"New games receive club edits and custom players after calibration")
        do ..Assert(##class(Rugby.Service.Store).Get("Player","c1-p1").name="Jugador administrado","New games receive initial player overrides")
        set actual=##class(Rugby.Service.Store).Get("Club","c1")
        do ..Assert((actual.stadium.capacity=3456)&&(actual.crestUrl=c.crestUrl),"Venue and crest copied to new game")
        set %RugbyGame="template",edited=##class(Rugby.Service.Store).Get("Club","c1"),edited.name="Otro nombre",ignored=##class(Rugby.Service.Admin).Save("Club","c1",{"version":(edited.version),"data":(edited)},"admin-isolation")
        set %RugbyGame=game.id
        do ..Assert(##class(Rugby.Service.Store).Get("Club","c1").name="Club administrado","Existing games keep their own club data")
    } catch ex {
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub,%RugbyUser=oldUser
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub,%RugbyUser=oldUser
}
}
