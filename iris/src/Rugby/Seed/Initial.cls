Class Rugby.Seed.Initial Extends %RegisteredObject
{
ClassMethod Run()
{
    lock +^RugbySeed:10
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Inicialización en curso")
    lock +^RugbyWrite:10
    if '$test {
        lock -^RugbySeed
        do ##class(Rugby.Service.Store).Fail(409,"BUSY","Hay una operación de gestión en curso.")
    }
    try {
        if '$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",4)) {
            tstart
            set stream=##class(%Stream.FileCharacter).%New()
            set stream.TranslateTable="UTF8"
            set sc=stream.LinkToFile("/opt/rugby/data/clubs.json")
            if $SYSTEM.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
            set catalog=##class(%DynamicObject).%FromJSON(stream)
            set first=$listbuild("Álvaro","Diego","Javier","Pablo","Sergio","Hugo","Mario","Daniel","Adrián","Iván","Marcos","Lucas","Rodrigo","Nicolás","Jaime","Miguel","Andrés","Gonzalo","Raúl","Manuel","Óscar","Bruno","Martín","Joel","Samuel","Álex","Rubén","Gabriel","Víctor")
            set last=$listbuild("García","Fernández","Martínez","López","Sánchez","Romero","Alonso","Ruiz","Navarro","Ortega","Molina","Serrano","Castro","Delgado","Vega","Iglesias","Moreno","Gil","Ramos","Santos","Torres","Vidal","Herrera","Pascual","Soler","Blanco","Prieto","Cruz","Medina")
            for c=1:1:catalog.clubs.%Size() {
                set entry=catalog.clubs.%Get(c-1),id=entry.id,club=##class(Rugby.Service.Store).Get("Club",id,0)
                if '$isobject(club) set club={"id":(id),"initialBalance":25000000,"balance":25000000,"day":-67,"startDay":-67,"date":"2026-09-01"}
                set club.name=entry.name,club.officialName=entry.officialName,club.shortName=entry.shortName,club.city=entry.city,club.color=entry.color,club.competitionId=entry.competitionId,club.competition=entry.competition,club.officialTeamId=entry.officialTeamId,club.season=catalog.season,club.generatedRoster=1
                set club.sourceUrl="https://resultadosrugby.isquad.es/competicion.php?id_superficie=1&seleccion=0&id_competicion="_entry.competitionId_"&id_temp=2627&id_ambito=1&id_territorial=9999",club.sourceVerifiedOn=catalog.verifiedOn
                do ##class(Rugby.Service.Store).Put("Club",club)
                set slots=[],bench=[],tactic={"style":"balanced","tempo":"normal","defense":"normal"}
                for n=1:1:29 {
                    set pos=n
                    if n>15 set pos=+$piece("1,2,3,4,6,9,10,15,11,12,5,8,13,14",",",n-15)
                    set pid=id_"-p"_n,category=$select(n>23:"academy",1:"senior")
                    set attrs={},attrNames="speed,strength,stamina,agility,passing,handling,tackling,kicking,scrum,lineout,discipline,decisions,leadership"
                    for k=1:1:13 {
                        set base=44+(((n*17)+(c*11)+(k*7))#29)
                        if (pos<=8)&&((k=2)||(k=9)||(k=10)) set base=base+9
                        if (pos>=9)&&((k=1)||(k=5)||(k=8)) set base=base+9
                        do attrs.%Set($piece(attrNames,",",k),base)
                    }
                    set secondary=[]
                    if pos>3 do secondary.%Push($select(pos<=8:8,pos<=10:10,1:15))
                    set p={"id":(pid),"clubId":(id),"nationalityCode":"ES","nationality":"España","name":($list(first,((n+c-2)#29)+1)_" "_$list(last,((n+(c*5)-2)#29)+1)),"age":($select(n>23:17+(n#3),1:21+(n#12))),"category":(category),"position":(pos),"secondary":(secondary),"potential":(80+(n#17)),"morale":100,"form":70,"energy":100,"available":true,"recoveryDay":0,"weeklyWage":(45000+(n*1200)),"attributes":(attrs)}
                    if category="academy" set p.name=##class(Rugby.Service.PlayerNames).Spanish(##class(Rugby.Service.Rivals).Hash(pid,17341))
                    if '$isobject(##class(Rugby.Service.Store).Get("Player",pid,0)) do ##class(Rugby.Service.Store).Put("Player",p)
                    if n<=15 do slots.%Push({"position":(n),"playerId":(pid)})
                    if (n>15)&&(n<=23) do bench.%Push(pid)
                }
                set lid=id_"-default",l={"id":(lid),"clubId":(id),"name":"XV principal","slots":(slots),"bench":(bench),"captainId":(id_"-p9"),"tactic":(tactic)}
                if '$isobject(##class(Rugby.Service.Store).Get("Lineup",lid,0)) do ##class(Rugby.Service.Store).Put("Lineup",l)
                set existing=##class(Rugby.Service.Store).Get("Lineup",lid)
                for j=0:1:existing.slots.%Size()-1 {
                    set slot=existing.slots.%Get(j),slot.id=lid_"-"_(j+1),slot.clubId=id
                    do ##class(Rugby.Service.Store).Put("LineupSlot",slot)
                }
                set projected=##class(%DynamicObject).%FromJSON(existing.tactic.%ToJSON()),projected.id=lid,projected.clubId=id
                do ##class(Rugby.Service.Store).Put("Tactic",projected)
                set t={"id":(id),"clubId":(id),"focus":"handling","intensity":"normal","players":[]}
                if '$isobject(##class(Rugby.Service.Store).Get("TrainingPlan",id,0)) do ##class(Rugby.Service.Store).Put("TrainingPlan",t)
            }
            for n=1:1:19 {
                set f=##class(Rugby.Service.Store).Get("Fixture","f"_n,0)
                if $isobject(f) continue
                set f={"id":("f"_n),"clubId":"c1","homeId":($select(n#2:"c1",1:"c"_(n+1))),"awayId":($select(n#2:"c"_(n+1),1:"c1")),"day":((n-1)*3),"status":"scheduled","matchId":""}
                do ##class(Rugby.Service.Store).Put("Fixture",f)
            }
            set matches=##class(Rugby.Service.Store).All("Match")
            for i=0:1:matches.%Size()-1 {
                set m=matches.%Get(i),home=##class(Rugby.Service.Store).Get("Club",m.homeId),away=##class(Rugby.Service.Store).Get("Club",m.awayId)
                set m.homeName=home.name,m.awayName=away.name,m.homeColor=home.color,m.awayColor=away.color
                do ##class(Rugby.Service.Store).Put("Match",m)
            }
            set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",1)=1,^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",3)=1,^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",4)=1
            tcommit
        }
        if '$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",2)) {
            tstart
            set players=##class(Rugby.Service.Store).All("Player")
            for i=0:1:players.%Size()-1 {
                set p=players.%Get(i)
                if p.weeklyWage>1000000 { set p.weeklyWage=45000+(+$piece(p.id,"p",2)*1200) do ##class(Rugby.Service.Store).Put("Player",p) }
            }
            set lineups=##class(Rugby.Service.Store).All("Lineup")
            for i=0:1:lineups.%Size()-1 {
                set l=lineups.%Get(i)
                for j=0:1:l.slots.%Size()-1 {
                    set s=l.slots.%Get(j),s.id=l.id_"-"_(j+1),s.clubId=l.clubId
                    do ##class(Rugby.Service.Store).Put("LineupSlot",s)
                }
                set t=##class(%DynamicObject).%FromJSON(l.tactic.%ToJSON()),t.id=l.id,t.clubId=l.clubId
                do ##class(Rugby.Service.Store).Put("Tactic",t)
            }
            set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"seed",2)=1
            tcommit
        }
        do ##class(Rugby.Seed.Development).Run()
        do ##class(Rugby.Seed.Development).Profiles()
        do ##class(Rugby.Seed.Competition).Run()
        do ##class(Rugby.Seed.Academy).Run()
        do ##class(Rugby.Seed.RealPlayers).Apply()
        set quality=##class(Rugby.Seed.Quality).Apply(),venues=##class(Rugby.Seed.Venues).Apply()
        do ##class(Rugby.Service.Kits).Initialize(),##class(Rugby.Service.Morale).Initialize(),##class(Rugby.Service.Seasons).Initialize()
    } catch ex {
        if $tlevel trollback
        lock -^RugbyWrite
        lock -^RugbySeed
        throw ex
    }
    lock -^RugbyWrite
    lock -^RugbySeed
}
}
