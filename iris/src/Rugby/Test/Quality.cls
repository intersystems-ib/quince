Class Rugby.Test.Quality Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set ref=##class(Rugby.Seed.Quality).Catalog(),catalog=##class(Rugby.Service.Development).Catalog(),last={}
    for i=0:1:ref.clubs.%Size()-1 {
        set row=ref.clubs.%Get(i),players=##class(Rugby.Service.Store).All("Player","clubId",row.clubId),seniors=0,academy=0,ns=0,na=0,lo=100,hi=0
        for j=0:1:players.%Size()-1 {
            set p=players.%Get(j),avg=##class(Rugby.Service.Development).Average(p)
            if p.category="senior" { set seniors=seniors+avg,ns=ns+1,lo=$select(avg<lo:avg,1:lo),hi=$select(avg>hi:avg,1:hi) }
            else { set academy=academy+avg,na=na+1 }
        }
        do ..Assert(($zabs((seniors/ns)-row.seniorTarget)<.0001)&&($zabs((academy/na)-row.academyTarget)<.0001),"Both seeded category means match target for "_row.clubId)
        do ..Assert((hi-lo)>1,"Individual player variation retained")
        if last.%IsDefined(row.divisionId) do ..Assert((seniors/ns)<last.%Get(row.divisionId),"Rank order strictly decreases within division")
        do last.%Set(row.divisionId,seniors/ns)
    }
    for i=0:1:ref.clubs.%Size()-1 {
        set row=ref.clubs.%Get(i)
        do ..Assert($zabs(row.seniorTarget-((row.currentTarget*row.currentWeight)+(row.historicalTarget*row.historicalWeight)))<.000002,"Historical and current reference use their explicit weights")
    }
    set row=ref.clubs.%Get(0),copy=##class(Rugby.Service.Store).Get("Player",row.clubId_"-p1"),expected=copy.attributes.tackling+.123456
    do ##class(Rugby.Seed.Quality).Adjust(copy,5,"older-calibration",row.clubId)
    set copy.attributes.tackling=copy.attributes.tackling+.123456
    do ##class(Rugby.Seed.Quality).Adjust(copy,row.seniorOffset,ref.version,row.clubId)
    do ..Assert($zabs(copy.attributes.tackling-expected)<.000002,"A new calibration replaces the old offset and retains accumulated training")
    do ..Assert(last.%Get(416)>64,"Weakest Honor squad exceeds strongest Elite squad")
    set p=##class(Rugby.Service.Store).Get("Player","c3-p1"),version=p.qualityVersion,delta=p.qualityOffset,old=p.%ToJSON()
    set again=##class(Rugby.Seed.Quality).Apply()
    do ..Assert((again.players=0)&&(##class(Rugby.Service.Store).Get("Player",p.id).%ToJSON()=old),"Calibration is idempotent")
    for k=0:1:16 { set key=catalog.%Get(k).id do p.attributes.%Set(key,p.attributes.%Get(key)-p.qualityChanges.%Get(key)) }
    set trained=p.attributes.tackling+.123456,p.attributes.tackling=trained,p.clubId="c11",energy=p.energy,morale=p.morale,wage=p.weeklyWage
    do p.%Remove("qualityVersion"),##class(Rugby.Service.Store).Put("Player",p)
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"qualityVersion")
    set report=##class(Rugby.Seed.Quality).Apply(),p=##class(Rugby.Service.Store).Get("Player",p.id)
    do ..Assert((report.players=1)&&($zabs(p.attributes.tackling-(trained+delta))<.000001),"Existing training gains retained and transferred player uses original club calibration")
    do ..Assert((p.clubId="c11")&&(p.energy=energy)&&(p.morale=morale)&&(p.weeklyWage=wage),"Calibration leaves ownership, energy, morale and wage intact")
    set club=##class(Rugby.Service.Store).Get("Club","c3"),young=##class(Rugby.Seed.Academy).Create(club,1,4321),snapshot=young.%ToJSON()
    do ##class(Rugby.Seed.Quality).Adjust(young,club.qualityAcademyOffset,club.qualityVersion,club.id)
    do ..Assert((young.qualityVersion=version)&&(young.%ToJSON()=snapshot),"Future academy intake calibrated once")
}
}
