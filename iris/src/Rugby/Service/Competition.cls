Class Rugby.Service.Competition Extends %RegisteredObject
{
Parameter VERSION = "1.1.0";
Parameter POINTSRULE = "fer-win-three-tries-v1";
ClassMethod Points(score As %Integer, against As %Integer, tries As %Integer, conceded As %Integer) As %DynamicObject
{
    set base=$select(score>against:4,score=against:2,1:0),offensive=(score>against)&&((tries-conceded)>=3),defensive=(score<against)&&((against-score)<=7)
    quit {"basePoints":(base),"bonusOffensive":(offensive),"bonusDefensive":(defensive),"total":(base+offensive+defensive)}
}
ClassMethod Classification(f As %DynamicObject) As %DynamicObject
{
    set result={"eligible":false,"rule":(..#POINTSRULE)}
    if (f.status'="finished")||('$listfind($listbuild("regular","cup-group"),f.%Get("stage")))||(f.%Get("competitionKey")="") quit result
    do result.%Set("eligible",1,"boolean")
    for side="home","away" {
        set other=$select(side="home":"away",1:"home")
        do result.%Set(side,..Points(f.%Get(side_"Score"),f.%Get(other_"Score"),f.%Get(side_"Tries",0),f.%Get(other_"Tries",0)))
    }
    quit result
}
ClassMethod MatchClassification(m As %DynamicObject) As %DynamicObject
{
    set f={"status":(m.status),"stage":(m.%Get("stage")),"competitionKey":(m.%Get("competitionKey")),"homeScore":(m.homeScore),"awayScore":(m.awayScore),"homeTries":(m.homeStats.%Get("tries",0)),"awayTries":(m.awayStats.%Get("tries",0))}
    quit ..Classification(f)
}
ClassMethod Year(date As %String) As %Integer
{
    quit +$piece(date,"-",1)-$select(+$piece(date,"-",2)<7:1,1:0)
}
ClassMethod Nearest(date As %String, weekday As %Integer) As %Integer
{
    set h=$zdateh(date,3),offset=weekday-((h+4)#7)
    if offset>3 set offset=offset-7
    if offset<(-3) set offset=offset+7
    quit h+offset
}
ClassMethod Draw(division As %Integer, year As %Integer, seed As %Integer) As %DynamicObject
{
    set id="league-"_division_"-"_year,old=##class(Rugby.Service.Store).Get("Competition",id,0)
    if $isobject(old) quit old
    do ##class(Rugby.Service.Cup).Ensure(year)
    set clubs=##class(Rugby.Service.Store).All("Club","competitionId",division),teams=[],rng={"rng":(seed)}
    if clubs.%Size()'=10 do ##class(Rugby.Service.Store).Fail(422,"LEAGUE_TEAMS","La liga necesita exactamente diez equipos.")
    for i=0:1:9 { do teams.%Push(clubs.%Get(i).id) }
    for i=9:-1:1 {
        set j=(##class(Rugby.Simulation.Engine).Random(rng)*(i+1))\1,temp=teams.%Get(i)
        do teams.%Set(i,teams.%Get(j)),teams.%Set(j,temp)
    }
    set first=..Nearest(year_"-09-27",6),last=..Nearest((year+1)_"-06-07",0),weeks=(last-1-first)\7
    set days=##class(Rugby.Service.Cup).LeagueWeekends(year,first,last-21)
    if days.%Size()<18 do ##class(Rugby.Service.Store).Fail(409,"LEAGUE_CALENDAR","No quedan dieciocho fines de semana libres para la Liga.")
    set semis=[],base=$zdateh("2026-11-07",3)
    for i=1:1:2 { do semis.%Push($zdate(last-8+((##class(Rugby.Simulation.Engine).Random(rng)*2)\1),3)) }
    set comp={"id":(id),"divisionId":(division),"name":($select(division=416:"División de Honor",1:"División de Honor Élite")),"season":(year_"/"_(year+1)),"year":(year),"drawSeed":(seed),"teamIds":(teams),"seasonStartDate":(year_"-09-01"),"startDate":($zdate(first,3)),"endDate":($zdate(last,3)),"semifinalDates":(semis),"finalDate":($zdate(last,3)),"phase":"regular","regularOrder":[],"championId":"","runnerUpId":"","maxVenueStreak":2,"modelVersion":(..#VERSION),"calendarVersion":(##class(Rugby.Service.Cup).#CALENDARVERSION)}
    do ##class(Rugby.Service.Store).Put("Competition",comp)
    set circle=##class(%DynamicArray).%FromJSON(teams.%ToJSON()),patterns=[]
    // Circle draw: each pair occurs once. Orientations limit all venue streaks to two.
    for r=0:1:8 {
        set row=[]
        for i=0:1:4 {
            set a=circle.%Get(i),b=circle.%Get(9-i),flip=$select(i=0:r#2,1:i#2)
            do row.%Push({"home":($select(flip:b,1:a)),"away":($select(flip:a,1:b))})
        }
        do patterns.%Push(row)
        set next=[]
        do next.%Push(circle.%Get(0)),next.%Push(circle.%Get(9))
        for i=1:1:8 { do next.%Push(circle.%Get(i)) }
        set circle=next
    }
    // Rotate return rounds by one; mirroring in the same order would create a third venue repetition.
    for r=0:1:17 {
        set returnLeg=r>=9,index=$select(returnLeg:(r-8)#9,1:r),row=patterns.%Get(index),week=+ $justify((days.%Size()-1)*r/17,0,0)
        for i=0:1:4 {
            set pair=row.%Get(i),home=$select(returnLeg:pair.away,1:pair.home),away=$select(returnLeg:pair.home,1:pair.away)
            set date=$zdate(days.%Get(week)+((##class(Rugby.Simulation.Engine).Random(rng)*2)\1),3)
            set f={"id":(id_"-r"_(r+1)_"-"_(i+1)),"clubId":($select((home=##class(Rugby.Service.Store).ManagedClub())||(away=##class(Rugby.Service.Store).ManagedClub()):##class(Rugby.Service.Store).ManagedClub(),1:home)),"competitionKey":(id),"divisionId":(division),"season":(comp.season),"stage":"regular","round":(r+1),"homeId":(home),"awayId":(away),"date":(date),"day":($zdateh(date,3)-base),"status":"scheduled","matchId":"","seed":(1+((seed+(r*997)+(i*43))#2147483646))}
            do ##class(Rugby.Service.Store).Put("Fixture",f)
        }
    }
    quit comp
}
ClassMethod Ensure(year As %Integer)
{
    do ##class(Rugby.Service.Cup).Ensure(year)
    for division=416,417 {
        set stored=$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"rivalsSeed")),seed=$select(stored:1+(##class(Rugby.Service.Rivals).Hash(division_"-"_year,stored)#2147483646),1:1+$random(2147483646)),comp=..Draw(division,year,seed)
    }
}
ClassMethod Fixtures(id As %String) As %DynamicArray
{
    set all=##class(Rugby.Service.Store).All("Fixture","competitionKey",id),result=[]
    kill sorted
    for i=0:1:all.%Size()-1 { set f=all.%Get(i),f.classification=..Classification(f),sorted(f.day,f.id)=f }
    set day=""
    for { set day=$order(sorted(day)) quit:day=""  set fid="" for { set fid=$order(sorted(day,fid)) quit:fid=""  do result.%Push(sorted(day,fid)) } }
    quit result
}
ClassMethod Table(comp As %DynamicObject) As %DynamicArray
{
    set rows={},fixtures=..Fixtures(comp.id),result=[]
    for i=0:1:comp.teamIds.%Size()-1 {
        set cid=comp.teamIds.%Get(i),club=##class(Rugby.Service.Store).Get("Club",cid)
        do rows.%Set(cid,{"clubId":(cid),"name":(club.name),"shortName":(club.shortName),"played":0,"wins":0,"draws":0,"losses":0,"pointsFor":0,"pointsAgainst":0,"difference":0,"triesFor":0,"triesAgainst":0,"bonusOffensive":0,"bonusDefensive":0,"points":0,"drawOrder":(i)})
    }
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i)
        if ('$listfind($listbuild("regular","cup-group"),f.stage))||(f.status'="finished") continue
        if (comp.%Get("groupId")'="")&&(f.%Get("groupId")'=comp.groupId) continue
        for side="home","away" {
            set other=$select(side="home":"away",1:"home"),row=rows.%Get(f.%Get(side_"Id")),score=f.%Get(side_"Score"),against=f.%Get(other_"Score"),tries=f.%Get(side_"Tries",0),conceded=f.%Get(other_"Tries",0)
            set row.played=row.played+1,row.pointsFor=row.pointsFor+score,row.pointsAgainst=row.pointsAgainst+against,row.triesFor=row.triesFor+tries,row.triesAgainst=row.triesAgainst+conceded
            if score>against { set row.wins=row.wins+1 }
            elseif score=against { set row.draws=row.draws+1 }
            else  { set row.losses=row.losses+1 }
            set award=..Points(score,against,tries,conceded),row.bonusOffensive=row.bonusOffensive+award.bonusOffensive,row.bonusDefensive=row.bonusDefensive+award.bonusDefensive,row.points=row.points+award.total
            set row.difference=row.pointsFor-row.pointsAgainst
        }
    }
    kill order
    for i=0:1:comp.teamIds.%Size()-1 {
        set row=rows.%Get(comp.teamIds.%Get(i)),order(-row.points,-row.difference,-row.wins,-row.triesFor,row.drawOrder)=row
    }
    set a=""
    for { set a=$order(order(a)) quit:a=""  set b="" for { set b=$order(order(a,b)) quit:b=""  set c="" for { set c=$order(order(a,b,c)) quit:c=""  set d="" for { set d=$order(order(a,b,c,d)) quit:d=""  set e="" for { set e=$order(order(a,b,c,d,e)) quit:e=""  set row=order(a,b,c,d,e),row.rank=result.%Size()+1 do result.%Push(row) } } } } }
    quit result
}
ClassMethod Playoff(comp As %DynamicObject, stage As %String, slot As %Integer, home As %String, away As %String, homeRank As %Integer, awayRank As %Integer) As %DynamicObject
{
    set id=comp.id_"-"_stage_"-"_slot,old=##class(Rugby.Service.Store).Get("Fixture",id,0)
    if $isobject(old) quit old
    set date=$select(stage="final":comp.finalDate,1:comp.semifinalDates.%Get(slot-1))
    set f={"id":(id),"clubId":($select((home=##class(Rugby.Service.Store).ManagedClub())||(away=##class(Rugby.Service.Store).ManagedClub()):##class(Rugby.Service.Store).ManagedClub(),1:home)),"competitionKey":(comp.id),"divisionId":(comp.divisionId),"season":(comp.season),"stage":(stage),"round":($select(stage="final":20,1:19)),"slot":(slot),"homeId":(home),"awayId":(away),"homeRank":(homeRank),"awayRank":(awayRank),"date":(date),"day":($zdateh(date,3)-$zdateh("2026-11-07",3)),"status":"scheduled","matchId":"","seed":(1+((comp.drawSeed+(slot*997)+$select(stage="final":731,1:193))#2147483646))}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    quit f
}
ClassMethod Progress(id As %String)
{
    set comp=##class(Rugby.Service.Store).Get("Competition",id)
    if comp.%Get("type")="cup" { do ##class(Rugby.Service.Cup).Progress(id) quit }
    if comp.phase="finished" quit
    if comp.phase="regular" {
        set fixtures=..Fixtures(id),finished=0
        for i=0:1:fixtures.%Size()-1 { set f=fixtures.%Get(i) if (f.stage="regular")&&(f.status="finished") set finished=finished+1 }
        if finished'=90 quit
        set table=..Table(comp),order=[]
        for i=0:1:9 { do order.%Push(table.%Get(i).clubId) }
        set comp.regularOrder=order,comp.phase="playoffs"
        set first=..Playoff(comp,"semifinal",1,order.%Get(0),order.%Get(3),1,4),second=..Playoff(comp,"semifinal",2,order.%Get(1),order.%Get(2),2,3)
        do ##class(Rugby.Service.Store).Put("Competition",comp)
    }
    set first=##class(Rugby.Service.Store).Get("Fixture",id_"-semifinal-1"),second=##class(Rugby.Service.Store).Get("Fixture",id_"-semifinal-2")
    if (first.status'="finished")||(second.status'="finished") quit
    set a=first.winnerId,b=second.winnerId,ar=0,br=0
    for i=0:1:9 { if comp.regularOrder.%Get(i)=a set ar=i+1
        if comp.regularOrder.%Get(i)=b set br=i+1 }
    set final=..Playoff(comp,"final",1,$select(ar<br:a,1:b),$select(ar<br:b,1:a),$select(ar<br:ar,1:br),$select(ar<br:br,1:ar))
    if final.status="finished" {
        set comp.phase="finished",comp.championId=final.winnerId,comp.runnerUpId=$select(final.winnerId=final.homeId:final.awayId,1:final.homeId)
        do ##class(Rugby.Service.Store).Put("Competition",comp)
    }
}
ClassMethod Strength(club As %String) As %Numeric
{
    set l=##class(Rugby.Service.Store).Get("Lineup",club_"-default"),sum=0
    for i=0:1:14 { set p=##class(Rugby.Service.Store).Get("Player",l.slots.%Get(i).playerId),sum=sum+(##class(Rugby.Service.Development).Average(p)*(.65+(.35*p.energy/100))*(.9+(.1*p.morale/100))) }
    quit sum/15
}
ClassMethod Simulate(f As %DynamicObject)
{
    if (f.status'="scheduled")||(f.matchId'="") quit
    // Recheck medical availability for the fixture date, including catch-up simulation.
    for cid=f.homeId,f.awayId {
        set c=##class(Rugby.Service.Store).Get("Club",cid),roster=##class(Rugby.Service.Store).All("Player","clubId",cid)
        for i=0:1:roster.%Size()-1 { set p=roster.%Get(i) if ##class(Rugby.Service.Injuries).Recover(p,f.day) do ##class(Rugby.Service.Store).Put("Player",p) }
        do ##class(Rugby.Service.Rivals).Lineup(c)
    }
    set homePlayers=##class(Rugby.Simulation.Tactics).LineupPlayers(f.homeId),awayPlayers=##class(Rugby.Simulation.Tactics).LineupPlayers(f.awayId),homePlan=##class(Rugby.Simulation.Tactics).Decide(homePlayers,awayPlayers),awayPlan=##class(Rugby.Simulation.Tactics).Decide(awayPlayers,homePlayers)
    set f.homeTactic=homePlan.tactic,f.awayTactic=awayPlan.tactic,f.tacticalAssessments={"home":(homePlan),"away":(awayPlan)}
    set rng={"rng":(f.seed)},factors=##class(Rugby.Simulation.Discipline).Aggregate(f,rng),home=..Strength(f.homeId)*factors.home,away=..Strength(f.awayId)*factors.away
    set home=home+##class(Rugby.Simulation.Tactics).Modifier(homePlan,awayPlan),away=away+##class(Rugby.Simulation.Tactics).Modifier(awayPlan,homePlan)
    for side="home","away" {
        set advantage=$select(side="home":home-away+3,1:away-home-3),tries=0,conversions=0,kicks=0,plan=$select(side="home":homePlan,1:awayPlan),priority=plan.tactic.%Get("penaltyPriority","auto"),attempts=$select(priority="posts":4,(priority="touch")||(priority="quick"):1,1:3),tryBonus=$select(priority="touch":.035,priority="quick":.025,priority="posts":-.015,1:0)
        for n=1:1:6 {
            if ##class(Rugby.Simulation.Engine).Random(rng)<##class(Rugby.Simulation.Engine).Clamp(.32+(advantage/100)+tryBonus,.1,.75) {
                set tries=tries+1
                if ##class(Rugby.Simulation.Engine).Random(rng)<.68 set conversions=conversions+1
            }
        }
        for n=1:1:attempts { if ##class(Rugby.Simulation.Engine).Random(rng)<##class(Rugby.Simulation.Engine).Clamp(.20+(plan.ownProfile.kicking/220),.15,.85) set kicks=kicks+1 }
        do f.%Set(side_"PenaltyAttempts",attempts)
        do f.%Set(side_"Score",(tries*5)+(conversions*2)+(kicks*3)),f.%Set(side_"Tries",tries)
        do f.%Set(side_"Conversions",conversions),f.%Set(side_"PenaltyGoals",kicks)
    }
    set f.winnerId=$select(f.homeScore>f.awayScore:f.homeId,f.awayScore>f.homeScore:f.awayId,1:"")
    if $listfind($listbuild("quarterfinal","semifinal","final"),f.stage)&&(f.winnerId="") {
        set f.homeShootout=3,f.awayShootout=3
        if ##class(Rugby.Simulation.Engine).Random(rng)<.5 { set f.homeShootout=4,f.winnerId=f.homeId }
        else  { set f.awayShootout=4,f.winnerId=f.awayId }
    }
    set f.status="finished",f.simulationVersion=..#VERSION
    do ##class(Rugby.Service.MatchStatistics).Aggregate(f)
    set f.classification=..Classification(f)
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    do ##class(Rugby.Service.Rivals).SettleFixture(f)
}
ClassMethod Sync(day As %Integer)
{
    set date=$zdate($zdateh("2026-11-07",3)+day,3)
    do ..Ensure(##class(Rugby.Service.Seasons).Year())
    set all=##class(Rugby.Service.Store).All("Competition")
    for i=0:1:all.%Size()-1 {
        set comp=all.%Get(i)
        if comp.phase="finished" continue
        // Regular results, then semis, then final. Never simulate the managed club.
        for pass=1:1:4 {
            set fixtures=..Fixtures(comp.id)
            for j=0:1:fixtures.%Size()-1 {
                set f=fixtures.%Get(j)
                if (f.day<=day)&&(f.status="scheduled")&&(f.homeId'=##class(Rugby.Service.Store).ManagedClub())&&(f.awayId'=##class(Rugby.Service.Store).ManagedClub()) do ..Simulate(f)
            }
            do ..Progress(comp.id)
        }
    }
}
ClassMethod View(id As %String) As %DynamicObject
{
    if ##class(Rugby.Service.Store).Get("Competition",id).%Get("type")="cup" quit ##class(Rugby.Service.Cup).View(id)
    set comp=##class(Rugby.Service.Store).Get("Competition",id),fixtures=..Fixtures(id),regular=[],semis=[],final="",finished=0
    for i=0:1:fixtures.%Size()-1 {
        set f=fixtures.%Get(i)
        if f.stage="regular" { do regular.%Push(f) if f.status="finished" set finished=finished+1 }
        if f.stage="semifinal" do semis.%Push(f)
        if f.stage="final" set final=f
    }
    set retirees=[],players=##class(Rugby.Service.Store).All("Player")
    for i=0:1:players.%Size()-1 { set p=players.%Get(i) if p.%Get("retirementSeasonYear",-1)=comp.year { set cid=p.%Get("retirementClubId") if (cid'="")&&(##class(Rugby.Service.Store).Get("Club",cid).competitionId=comp.divisionId) do retirees.%Push({"playerId":(p.id),"name":(p.name),"clubId":(cid),"retirementDate":(p.retirementDate)}) } }
    set comp.retiringPlayers=retirees
    set comp.standings=..Table(comp),comp.regularFixtures=regular,comp.semifinals=semis,comp.final=final,comp.regularFinished=finished
    quit comp
}
ClassMethod ClubFixtures(club As %String) As %DynamicArray
{
    set c=##class(Rugby.Service.Store).Get("Club",club),current="league-"_c.competitionId_"-"_##class(Rugby.Service.Seasons).Year(club),all=##class(Rugby.Service.Store).All("Fixture"),result=[]
    kill sorted
    for i=0:1:all.%Size()-1 {
        set f=all.%Get(i)
        if (f.homeId'=club)&&(f.awayId'=club) continue
        if f.%Get("archived",0) continue
        if (f.%Get("competitionKey")'="")&&(f.%Get("competitionKey")'=current)&&(f.%Get("competitionKey")'=("cup-"_##class(Rugby.Service.Seasons).Year(club)))&&(f.status'="live") continue
        set preparation=##class(Rugby.Service.Store).Get("OpponentPreparation",f.id,0)
        if $isobject(preparation) set f.preparationLineupId=preparation.lineupId
        set f.classification=..Classification(f),sorted(f.day,f.id)=f
    }
    set day=""
    for { set day=$order(sorted(day)) quit:day=""  set fid="" for { set fid=$order(sorted(day,fid)) quit:fid=""  do result.%Push(sorted(day,fid)) } }
    quit result
}
}
