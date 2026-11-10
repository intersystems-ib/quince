Class Rugby.Seed.Quality Extends %RegisteredObject
{
ClassMethod Catalog() As %DynamicObject
{
    set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8",sc=stream.LinkToFile("/opt/rugby/data/team-quality.json")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    quit ##class(%DynamicObject).%FromJSON(stream)
}
ClassMethod Adjust(p As %DynamicObject, offset As %Numeric, version As %String, origin As %String)
{
    if p.%Get("qualityVersion")=version quit
    set catalog=##class(Rugby.Service.Development).Catalog(),changes={}
    for k=0:1:16 {
        set key=catalog.%Get(k).id,old=p.attributes.%Get(key),prior=$select(p.%Get("qualityVersion")'="":p.%Get("qualityChanges",{}).%Get(key,0),1:0),base=old-prior,value=+$justify(##class(Rugby.Simulation.Engine).Clamp(base+offset,1,100),0,6)
        do p.attributes.%Set(key,value),changes.%Set(key,value-base)
    }
    set p.qualityVersion=version,p.qualityOriginClubId=origin,p.qualityOffset=offset,p.qualityChanges=changes
}
ClassMethod Apply() As %DynamicObject
{
    set catalog=..Catalog(),game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"version":(catalog.version),"players":0,"clubs":[]}
    if $get(^RugbyWorld(game,"qualityVersion"))=catalog.version quit report
    set reference={}
    for i=0:1:catalog.clubs.%Size()-1 {
        set row=catalog.clubs.%Get(i),c=##class(Rugby.Service.Store).Get("Club",row.clubId)
        do reference.%Set(c.id,row)
        set c.qualityVersion=catalog.version,c.qualityReferenceRank=row.rank,c.qualityReferenceDate=catalog.consultedOn,c.qualitySeniorTarget=row.seniorTarget,c.qualityAcademyTarget=row.academyTarget,c.qualityAcademyOffset=row.academyOffset,c.qualityHistoricalWeight=row.%Get("historicalWeight",0),c.qualityHistoricalRank=row.%Get("historicalRank",0),c.qualityHistoricalSeason="2025/2026",c.qualityBlendedRank=row.%Get("blendedRank",row.rank)
        do ##class(Rugby.Service.Store).Put("Club",c),report.clubs.%Push(row)
    }
    set players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),origin=$piece(p.id,"-",1),tail=$piece(p.id,"-",2),n=+$extract(tail,2,*)
        // Only original seeded players are recalibrated; signings keep their own ability.
        if 'reference.%IsDefined(origin) continue
        if (tail'="academy")&&(($extract(tail,1)'="p")||(n<1)||(n>29)) continue
        if p.%Get("qualityVersion")=catalog.version continue
        set row=reference.%Get(origin),offset=$select((tail="academy")||(n>23):row.academyOffset,1:row.seniorOffset)
        do ..Adjust(p,offset,catalog.version,origin),##class(Rugby.Service.Store).Put("Player",p)
        set report.players=report.players+1
    }
    set ^RugbyWorld(game,"qualityVersion")=catalog.version
    quit report
}
ClassMethod InitializeAll() As %DynamicArray
{
    set previousGame=##class(Rugby.Service.Store).Game(),previousClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Ajuste de calidad en curso.")
    try {
        tstart
        do reports.%Push(..Apply())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Apply()) }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=previousGame,%RugbyManagedClub=previousClub
    lock -^RugbyWrite
    quit reports
}
}
