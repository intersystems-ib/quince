Class Rugby.Service.Cup Extends %RegisteredObject
{
Parameter CALENDARVERSION = "cup-first-v2";
ClassMethod Weekend(date As %String) As %String
{
    set h=$zdateh(date,3),sat=##class(Rugby.Service.Competition).Nearest(date,6),sun=##class(Rugby.Service.Competition).Nearest(date,0)
    quit $zdate($select($select(sun>h:sun-h,1:h-sun)<=$select(sat>h:sat-h,1:h-sat):sun,1:sat),3)
}
ClassMethod Dates(year As %Integer) As %DynamicObject
{
    quit {"groups":[(..Weekend(year_"-11-22")),(..Weekend(year_"-11-29")),(..Weekend(year_"-12-06"))],"quarterfinal":(..Weekend((year+1)_"-01-10")),"semifinal":(..Weekend((year+1)_"-02-07")),"final":(..Weekend((year+1)_"-05-02"))}
}
ClassMethod Reserved(year As %Integer, date As %String) As %Boolean
{
    set dates=..Dates(year),cup=##class(Rugby.Service.Store).Get("Competition","cup-"_year,0)
    if $isobject(cup) set dates={"groups":(cup.groupDates),"quarterfinal":(cup.quarterfinalDate),"semifinal":(cup.semifinalDates.%Get(0)),"final":(cup.finalDate)}
    set h=$zdateh(date,3),week=h-((h+5)#7),reserved=0
    for i=0:1:2 { set d=$zdateh(dates.groups.%Get(i),3) if (d-((d+5)#7))=week set reserved=1 }
    for stage="quarterfinal","semifinal","final" { set d=$zdateh(dates.%Get(stage),3) if (d-((d+5)#7))=week set reserved=1 }
    if 'reserved {
        set fixtures=##class(Rugby.Service.Store).All("Fixture","competitionKey","cup-"_year)
        for i=0:1:fixtures.%Size()-1 { set d=$zdateh(fixtures.%Get(i).date,3) if (d-((d+5)#7))=week set reserved=1 }
    }
    quit reserved
}
ClassMethod Exemptions(year As %Integer) As %DynamicArray
{
    if year=2026 quit ["c7","c2"]
    set cup=##class(Rugby.Service.Store).Get("Competition","cup-"_(year-1),0),league=##class(Rugby.Service.Store).Get("Competition","league-416-"_(year-1),0),winner="c7",champion="c2",runner=""
    if $isobject(cup) { set winner=cup.%Get("championId","c7"),runner=cup.%Get("runnerUpId") if winner="" set winner="c7" }
    if $isobject(league) { set champion=league.%Get("championId","c2") if champion="" set champion="c2" }
    if winner=champion set champion=runner
    if (champion="")||(champion=winner) { set clubs=##class(Rugby.Service.Store).All("Club","competitionId",416) for i=0:1:clubs.%Size()-1 { if clubs.%Get(i).id'=winner { set champion=clubs.%Get(i).id quit } } }
    quit [(winner),(champion)]
}
ClassMethod Ensure(year As %Integer)
{
    set id="cup-"_year
    if $isobject(##class(Rugby.Service.Store).Get("Competition",id,0)) quit
    set dates=..Dates(year),exempt=..Exemptions(year),clubs=##class(Rugby.Service.Store).All("Club"),teams=[],pool=[],seed=1+(##class(Rugby.Service.Rivals).Hash(id,##class(Rugby.Service.Rivals).Seed())#2147483646),rng={"rng":(seed)}
    for i=0:1:clubs.%Size()-1 { set cid=clubs.%Get(i).id do teams.%Push(cid) if (cid'=exempt.%Get(0))&&(cid'=exempt.%Get(1)) do pool.%Push(cid) }
    if teams.%Size()'=20 do ##class(Rugby.Service.Store).Fail(422,"CUP_TEAMS","La Copa necesita los veinte clubes de Honor y Élite.")
    if year=2026 { set pool=["c19","c3","c16","c13","c6","c20","c1","c14","c9","c18","c5","c17","c11","c10","c12","c8","c4","c15"] }
    else {
        for i=17:-1:1 { set j=(##class(Rugby.Simulation.Engine).Random(rng)*(i+1))\1,temp=pool.%Get(i) do pool.%Set(i,pool.%Get(j)),pool.%Set(j,temp) }
    }
    set groups=[],comp={"id":(id),"type":"cup","divisionId":0,"name":"Copa del Rey","season":(year_"/"_(year+1)),"year":(year),"drawSeed":(seed),"teamIds":(teams),"exemptTeamIds":(exempt),"groups":(groups),"groupDates":(dates.groups),"quarterfinalDate":(dates.quarterfinal),"semifinalDates":[(dates.semifinal),(dates.semifinal)],"finalDate":(dates.final),"seasonStartDate":(year_"-09-01"),"startDate":(dates.groups.%Get(0)),"endDate":(dates.final),"phase":"groups","championId":"","runnerUpId":"","qualifiedTeamIds":[],"regularOrder":[]}
    for i=0:1:5 {
        set group={"id":($char(65+i)),"teamIds":[(pool.%Get(i*3)),(pool.%Get((i*3)+1)),(pool.%Get((i*3)+2))]}
        do groups.%Push(group)
        for r=0:1:2 {
            set reverse=(year=2026)&&((i=0)||(i=2)),a=$select(reverse:$select(r=0:0,r=1:2,1:1),1:r),b=$select(reverse:$select(r=0:1,r=1:0,1:2),1:(r+1)#3),home=group.teamIds.%Get(a),away=group.teamIds.%Get(b),f=..Fixture(comp,"cup-group",(i*3)+r+1,home,away,dates.groups.%Get(r))
            set f.groupId=group.id,f.round=r+1
            do ##class(Rugby.Service.Store).Put("Fixture",f)
        }
    }
    do ##class(Rugby.Service.Store).Put("Competition",comp)
}
ClassMethod Fixture(comp As %DynamicObject, stage As %String, slot As %Integer, home As %String, away As %String, date As %String) As %DynamicObject
{
    set id=comp.id_"-"_stage_"-"_slot,old=##class(Rugby.Service.Store).Get("Fixture",id,0)
    if $isobject(old) quit old
    set own=##class(Rugby.Service.Store).ManagedClub(),f={"id":(id),"clubId":($select((home=own)||(away=own):own,1:home)),"competitionKey":(comp.id),"competitionType":"cup","divisionId":0,"season":(comp.season),"stage":(stage),"slot":(slot),"round":($select(stage="cup-group":1,stage="quarterfinal":4,stage="semifinal":5,1:6)),"homeId":(home),"awayId":(away),"date":(date),"day":($zdateh(date,3)-$zdateh("2026-11-07",3)),"status":"scheduled","matchId":"","seed":(1+(##class(Rugby.Service.Rivals).Hash(id,comp.drawSeed)#2147483646))}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    quit f
}
ClassMethod Progress(id As %String)
{
    set comp=##class(Rugby.Service.Store).Get("Competition",id)
    if comp.phase="finished" quit
    if comp.phase="groups" {
        set fixtures=##class(Rugby.Service.Competition).Fixtures(id),done=0,qualified=##class(%DynamicArray).%FromJSON(comp.exemptTeamIds.%ToJSON())
        for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if (f.stage="cup-group")&&(f.status="finished") set done=done+1 }
        if done'=18 quit
        for i=0:1:5 { set group=comp.groups.%Get(i),table=..Table(comp,group) do qualified.%Push(table.%Get(0).clubId) }
        set comp.qualifiedTeamIds=qualified,comp.phase="quarterfinal",draw=##class(%DynamicArray).%FromJSON(qualified.%ToJSON()),rng={"rng":(comp.drawSeed)}
        for i=7:-1:1 { set j=(##class(Rugby.Simulation.Engine).Random(rng)*(i+1))\1,temp=draw.%Get(i) do draw.%Set(i,draw.%Get(j)),draw.%Set(j,temp) }
        for i=0:1:3 { set f=..Fixture(comp,"quarterfinal",i+1,draw.%Get(i*2),draw.%Get((i*2)+1),comp.quarterfinalDate) }
        do ##class(Rugby.Service.Store).Put("Competition",comp)
    }
    for stage="quarterfinal","semifinal","final" {
        if comp.phase'=stage continue
        set size=$select(stage="quarterfinal":4,stage="semifinal":2,1:1),winners=[],complete=1
        for i=1:1:size { set f=##class(Rugby.Service.Store).Get("Fixture",id_"-"_stage_"-"_i,0) if '$isobject(f) { set complete=0 continue } if (f.status'="finished")||(f.%Get("winnerId")="") { set complete=0 continue } do winners.%Push(f.winnerId) }
        if 'complete quit
        if stage="final" {
            set comp.phase="finished",comp.championId=f.winnerId,comp.runnerUpId=$select(f.winnerId=f.homeId:f.awayId,1:f.homeId)
        } else {
            set next=$select(stage="quarterfinal":"semifinal",1:"final"),date=$select(next="final":comp.finalDate,1:comp.semifinalDates.%Get(0))
            for i=0:1:(size\2)-1 { set home=winners.%Get(i*2),away=winners.%Get((i*2)+1),rng={"rng":(1+(##class(Rugby.Service.Rivals).Hash(id_"-"_next_"-"_i,comp.drawSeed)#2147483646))} if ##class(Rugby.Simulation.Engine).Random(rng)<.5 { set temp=home,home=away,away=temp } set f=..Fixture(comp,next,i+1,home,away,date) }
            set comp.phase=next
        }
        do ##class(Rugby.Service.Store).Put("Competition",comp)
    }
}
ClassMethod Table(comp As %DynamicObject, group As %DynamicObject) As %DynamicArray
{
    quit ##class(Rugby.Service.Competition).Table({"id":(comp.id),"teamIds":(group.teamIds),"groupId":(group.id)})
}
ClassMethod View(id As %String) As %DynamicObject
{
    set comp=##class(Rugby.Service.Store).Get("Competition",id),comp.fixtures=##class(Rugby.Service.Competition).Fixtures(id),comp.standings=[],comp.regularFixtures=[],comp.quarterfinals=[],comp.semifinals=[],comp.final="",comp.regularFinished=0
    for i=0:1:comp.groups.%Size()-1 { set group=comp.groups.%Get(i),group.standings=..Table(comp,group) }
    for i=0:1:comp.fixtures.%Size()-1 {
        set f=comp.fixtures.%Get(i)
        if f.stage="cup-group" { do comp.regularFixtures.%Push(f) if f.status="finished" set comp.regularFinished=comp.regularFinished+1 }
        if f.stage="quarterfinal" do comp.quarterfinals.%Push(f)
        if f.stage="semifinal" do comp.semifinals.%Push(f)
        if f.stage="final" set comp.final=f
    }
    set clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i) do comp.standings.%Push({"clubId":(c.id),"name":(c.name)}) }
    quit comp
}
ClassMethod LeagueWeekends(year As %Integer, first As %Integer, last As %Integer) As %DynamicArray
{
    set days=[],all=##class(Rugby.Service.Store).All("Fixture"),base=$zdateh("2026-11-07",3)
    for h=first:1:last {
        if ((h+4)#7)'=6 continue
        if ..Reserved(year,$zdate(h,3)) continue
        set busy=0
        for i=0:1:all.%Size()-1 { set f=all.%Get(i) if (f.%Get("stage")="friendly")&&('f.%Get("archived",0))&&((f.day+base=h)||(f.day+base=(h+1))) set busy=1 }
        if 'busy do days.%Push(h)
    }
    quit days
}
ClassMethod Recalendar(cup As %DynamicObject, force As %Boolean = 0)
{
    set club=##class(Rugby.Service.Store).Get("Club",##class(Rugby.Service.Store).ManagedClub()),base=$zdateh("2026-11-07",3),today=$zdateh(club.date,3)
    for division=416,417 {
        set league=##class(Rugby.Service.Store).Get("Competition","league-"_division_"-"_cup.year,0)
        if '$isobject(league) continue
        kill movable,roundIndex
        set fixtures=##class(Rugby.Service.Competition).Fixtures(league.id),collision=0,rounds=[],remaining=0
        for i=0:1:fixtures.%Size()-1 {
            set f=fixtures.%Get(i)
            if (f.stage'="regular")||(f.status'="scheduled")||(f.matchId'="") continue
            if (f.day<club.day)&&('..Reserved(cup.year,f.date)) continue
            set movable(f.id)=1,roundIndex(f.round)=1
            if ..Reserved(cup.year,f.date) set collision=1
        }
        if ('force)&&('collision)&&(league.%Get("calendarVersion")=..#CALENDARVERSION) continue
        for r=1:1:18 { if $data(roundIndex(r)) { set roundIndex(r)=remaining,remaining=remaining+1 } }
        set first=##class(Rugby.Service.Competition).Nearest(cup.year_"-09-27",6),last=$zdateh(league.finalDate,3)-21
        if first<=today set first=today+1
        set days=..LeagueWeekends(cup.year,first,last)
        if days.%Size()<remaining do ##class(Rugby.Service.Store).Fail(409,"CUP_CALENDAR","No quedan suficientes fines de semana libres para integrar la Copa.")
        for i=0:1:fixtures.%Size()-1 {
            set f=fixtures.%Get(i)
            if '$data(movable(f.id)) continue
            set index=$select(remaining=1:0,1:+$justify((days.%Size()-1)*roundIndex(f.round)/(remaining-1),0,0)),h=days.%Get(index)+(f.seed#2),date=$zdate(h,3)
            if f.date'=date {
                set f=##class(Rugby.Service.Store).Get("Fixture",f.id),f.rescheduledFromDate=f.%Get("rescheduledFromDate",f.date),f.date=date,f.day=h-base
                do ##class(Rugby.Service.Store).Put("Fixture",f)
            }
        }
        if league.%Get("calendarVersion")'=..#CALENDARVERSION { set league.calendarVersion=..#CALENDARVERSION do ##class(Rugby.Service.Store).Put("Competition",league) }
    }
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando la Copa del Rey.")
    try {
        tstart
        do ..Ensure(##class(Rugby.Service.Seasons).Year()),..Recalendar(##class(Rugby.Service.Store).Get("Competition","cup-"_##class(Rugby.Service.Seasons).Year()))
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do ..Ensure(##class(Rugby.Service.Seasons).Year()),..Recalendar(##class(Rugby.Service.Store).Get("Competition","cup-"_##class(Rugby.Service.Seasons).Year())),reports.%Push({"gameId":(gid),"competitionId":("cup-"_##class(Rugby.Service.Seasons).Year())}) }
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
