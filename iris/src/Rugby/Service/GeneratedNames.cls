Class Rugby.Service.GeneratedNames Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Pick(id As %String, used As %DynamicObject, families As %DynamicObject = "", country As %String = "FR", professional As %Boolean = 0) As %String
{
    set attempt=0
    for {
        set seed=##class(Rugby.Service.Rivals).Hash($select(country="FR":"french-generated-",1:"spanish-generated-")_id_"-"_attempt),name=$select(country="FR":##class(Rugby.Service.PlayerNames).French(seed),1:##class(Rugby.Service.PlayerNames).Spanish(seed,professional)),family=$select(country="FR":$piece(name," ",2,*),1:$piece(name," ",2))
        set available='used.%IsDefined(name)
        if $isobject(families)&&(attempt<512)&&families.%IsDefined(family) set available=0
        quit:available
        set attempt=attempt+1
        if attempt>4096 do ##class(Rugby.Service.Store).Fail(500,"NAME_POOL","No se pudo generar una identidad distinta.")
    }
    do used.%Set(name,1)
    if $isobject(families) do families.%Set(family,1)
    quit name
}
ClassMethod Legacy(name As %String, country As %String) As %Boolean
{
    quit $select(country="FR":##class(Rugby.Service.PlayerNames).LegacyFrench(name),1:##class(Rugby.Service.PlayerNames).LegacySpanish(name))
}
ClassMethod Apply(country As %String = "FR") As %DynamicObject
{
    set marker=$select(country="FR":"frenchGeneratedNamesVersion",1:"spanishGeneratedNamesVersion"),nameVersion=$select(country="FR":"generatedFrenchNameVersion",1:"generatedSpanishNameVersion")
    set game=##class(Rugby.Service.Store).Game(),report={"gameId":(game),"players":0,"coaches":0,"financiers":0}
    if $get(^RugbyWorld(game,marker))=..#VERSION quit report
    set players=##class(Rugby.Service.Store).All("Player"),coaches=##class(Rugby.Service.Store).All("Coach"),offices=##class(Rugby.Service.Store).All("FinancialOffice"),clubs=##class(Rugby.Service.Store).All("Club"),eligible={},used={},changedPlayers={},changedStaff={}
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i) if ##class(Rugby.Service.Leagues).Country(c)=country do eligible.%Set(c.id,1) }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i),cid=p.clubId
        do used.%Set(p.name,1)
        if '$data(families("@"_cid)) set families("@"_cid)={}
        do families("@"_cid).%Set($select(country="FR":$piece(p.name," ",2,*),1:$piece(p.name," ",2)),1)
    }
    for i=0:1:coaches.%Size()-1 { do used.%Set(coaches.%Get(i).name,1) }
    for i=0:1:offices.%Size()-1 {
        set o=offices.%Get(i)
        for j=0:1:o.candidates.%Size()-1 { do used.%Set(o.candidates.%Get(j).name,1) }
        if o.director.%Get("id")'="" do used.%Set(o.director.name,1)
    }
    for i=0:1:players.%Size()-1 {
        set p=players.%Get(i)
        if (p.category'="academy")||(p.%Get("nationalityCode")'=country)||p.%Get("realIdentity",0)||(p.%Get("identitySource")'="")||('..Legacy(p.name,country)) continue
        set patch=##class(%DynamicObject).%FromJSON($get(^RugbyAdmin("overrides","Player",p.id),"{}"))
        if patch.%IsDefined("name") continue
        set before=p.version,p.name=..Pick(p.id,used,families("@"_p.clubId),country)
        do p.%Set(nameVersion,..#VERSION)
        do ##class(Rugby.Service.Store).Put("Player",p),changedPlayers.%Set(p.id,{"name":(p.name),"before":(before),"after":(p.version)})
        set report.players=report.players+1
    }
    for i=0:1:coaches.%Size()-1 {
        set p=coaches.%Get(i)
        if p.%Get("realIdentity",0)||(p.%Get("identitySource")'="") continue
        if ((p.%Get("marketCountry","ES")'=country)&&('eligible.%IsDefined(p.clubId)))||('..Legacy(p.name,country)) continue
        set p.name=$select(p.clubId="":##class(Rugby.Seed.StaffNames).Generate(p.id,1,country),1:..Pick(p.id,used,"",country,1))
        do p.%Set(nameVersion,..#VERSION)
        do used.%Set(p.name,1),##class(Rugby.Service.Store).Put("Coach",p),changedStaff.%Set(p.id,p.name)
        set ^RugbyWorld(game,"staffNameOwner",p.name)=p.id,report.coaches=report.coaches+1
    }
    for i=0:1:offices.%Size()-1 {
        set o=offices.%Get(i),changed=0
        if 'eligible.%IsDefined(o.clubId) continue
        for j=0:1:o.candidates.%Size()-1 {
            set p=o.candidates.%Get(j)
            if '..Legacy(p.name,country) continue
            set p.name=..Pick(p.id,used,"",country,1),changed=1,report.financiers=report.financiers+1
            do p.%Set(nameVersion,..#VERSION)
            do changedStaff.%Set(p.id,p.name)
        }
        set p=o.director
        if p.%Get("id")'="" {
            if changedStaff.%IsDefined(p.id) { set p.name=changedStaff.%Get(p.id),changed=1 do p.%Set(nameVersion,..#VERSION) }
            elseif ..Legacy(p.name,country) {
                set p.name=..Pick(p.id,used,"",country,1),changed=1,report.financiers=report.financiers+1
                do p.%Set(nameVersion,..#VERSION)
                do changedStaff.%Set(p.id,p.name)
            }
        }
        if changed do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    }
    if changedStaff.%Size()>0 {
        set contracts=##class(Rugby.Service.Store).All("StaffContract")
        for i=0:1:contracts.%Size()-1 {
            set a=contracts.%Get(i),id=a.%Get("coachId",a.%Get("directorId"))
            if changedStaff.%IsDefined(id) { set a.employeeName=changedStaff.%Get(id) do ##class(Rugby.Service.Store).Put("StaffContract",a) }
        }
    }
    if changedPlayers.%Size()>0 {
        set negotiations=##class(Rugby.Service.Store).All("Negotiation")
        for i=0:1:negotiations.%Size()-1 {
            set n=negotiations.%Get(i)
            if changedPlayers.%IsDefined(n.playerId) {
                set v=changedPlayers.%Get(n.playerId)
                if n.%Get("playerVersion",-1)=v.before { set n.playerVersion=v.after do ##class(Rugby.Service.Store).Put("Negotiation",n) }
            }
        }
        set matches=##class(Rugby.Service.Store).All("Match")
        for i=0:1:matches.%Size()-1 {
            set m=matches.%Get(i),changed=0
            if m.status="finished" continue
            for side="home","away" {
                set rows=m.%Get(side_"Players",[])
                for j=0:1:rows.%Size()-1 {
                    set p=rows.%Get(j)
                    if changedPlayers.%IsDefined(p.playerId) { set p.name=changedPlayers.%Get(p.playerId).name do ##class(Rugby.Service.Store).Put("MatchPlayer",p) set changed=1 }
                }
            }
            if changed do ##class(Rugby.Service.Store).Put("Match",m)
        }
    }
    set ^RugbyWorld(game,marker)=..#VERSION
    quit report
}
ClassMethod InitializeAll(country As %String = "FR") As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[],ids=["template"],gid=""
    for { set gid=$order(^RugbyGames(gid)) quit:gid=""  do ids.%Push(gid) }
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Actualizando nombres generados.")
    try {
        tstart
        for i=0:1:ids.%Size()-1 { set %RugbyGame=ids.%Get(i),%RugbyManagedClub="c1" do reports.%Push(..Apply(country)) }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
