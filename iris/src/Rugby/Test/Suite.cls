Class Rugby.Test.Suite Extends %RegisteredObject
{
ClassMethod Assert(condition As %Boolean, message As %String)
{
    if 'condition throw ##class(%Exception.General).%New("ASSERT: "_message)
}
ClassMethod Run(only As %String = "")
{
    lock +^RugbyWrite:15
    if '$test { write "TESTS FAILED: busy",! quit }
    set failures=0
    for name="Catalog","Lineups","Management","Development","AttributeProgress","Academy","Competition","Cup","Movement","Commands","BatchSubstitutions","Engine","Speed","Recovery","Strength","Concurrency","Trends","Clock","Sessions","CalendarRules","Interop","Rivals","Transfers","RealPlayers","Discipline","Bonus","Kits","Promotion","Performance","News","MatchStatistics","Morale","Seasons","InitialContracts","Tactics","Quality","Finance","Payroll","PlayerNames","StaffNames","StaffMarket","FinanceRevision","Injuries","GameDeletion","Availability","MonthlyPayroll","EmployeePayroll","TrainingCosts","MatchPauses","Venues","InjuryFrequency","TransferPool","TransferAuction","ContractTerms","StaffPay","FinancialPlanning","TalentScale","FriendlyRequests","WeeklyTraining" {
        if (only'="")&&(name'=only) continue
        try {
            if name'="Concurrency" tstart
            do $classmethod($classname(),name)
            if $tlevel trollback
            write "PASS ",name,!
        } catch ex {
            if $tlevel trollback
            set failures=failures+1
            write "FAIL ",name,": ",ex.DisplayString(),!
        }
    }
    lock -^RugbyWrite
    write $select(failures:"TESTS FAILED: "_failures,1:"ALL TESTS PASSED"),!
}
ClassMethod InitialContracts() { do ##class(Rugby.Test.InitialContracts).Run() }
ClassMethod BatchSubstitutions() { do ##class(Rugby.Test.BatchSubstitutions).Run() }
ClassMethod News() { do ##class(Rugby.Test.News).Run() }
ClassMethod MatchStatistics() { do ##class(Rugby.Test.MatchStatistics).Run() }
ClassMethod EmployeePayroll() { do ##class(Rugby.Test.EmployeePayroll).Run() }
ClassMethod TrainingCosts() { do ##class(Rugby.Test.TrainingCosts).Run() }
ClassMethod MatchPauses() { do ##class(Rugby.Test.MatchPauses).Run() }
ClassMethod Venues() { do ##class(Rugby.Test.Venues).Run() }
ClassMethod InjuryFrequency() { do ##class(Rugby.Test.InjuryFrequency).Run() }
ClassMethod TransferPool() { do ##class(Rugby.Test.TransferPool).Run() }
ClassMethod TransferAuction() { do ##class(Rugby.Test.TransferAuction).Run() }
ClassMethod WeeklyTraining() { do ##class(Rugby.Test.WeeklyTraining).Run() }
ClassMethod TalentScale() { do ##class(Rugby.Test.TalentScale).Run() }
ClassMethod FriendlyRequests() { do ##class(Rugby.Test.FriendlyRequests).Run() }
ClassMethod ContractTerms() { do ##class(Rugby.Test.ContractTerms).Run() }
ClassMethod StaffPay() { do ##class(Rugby.Test.StaffPay).Run() }
ClassMethod FinancialPlanning() { do ##class(Rugby.Test.FinancialPlanning).Run() }
ClassMethod Healthy()
{
    // Independent match test cases start with a healthy roster.
    for cid="c1","c2" { set roster=##class(Rugby.Service.Store).All("Player","clubId",cid) for i=0:1:roster.%Size()-1 { set p=roster.%Get(i) if $isobject(p.%Get("injury")) { set p.available=1,p.recoveryDay=0 do p.%Remove("injury"),##class(Rugby.Service.Store).Put("Player",p) } } }
}
ClassMethod Build(seed As %Integer = 17341) As %DynamicObject
{
    // Runs within a rollback-only test transaction; no user fixtures are consumed.
    set all=##class(Rugby.Service.Store).All("Match")
    for i=0:1:all.%Size()-1 { set q=all.%Get(i),q.status="finished" do ##class(Rugby.Service.Store).Put("Match",q) }
    set club=##class(Rugby.Service.Store).Get("Club","c1")
    do ..Healthy()
    set f={"id":("test-fixture-"_$increment(^RugbyTestId)),"clubId":"c1","homeId":"c1","awayId":"c2","day":(club.day),"status":"scheduled","matchId":""}
    do ##class(Rugby.Service.Store).Put("Fixture",f)
    set m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id),"seed":(seed)},f.id)
    quit ##class(Rugby.Service.Matches).Start(m.id)
}
ClassMethod AttributeProgress() { do ##class(Rugby.Test.AttributeProgress).Run() }
ClassMethod Development()
{
    do ##class(Rugby.Test.Development).Run()
}
ClassMethod Cup() { do ##class(Rugby.Test.Cup).Run() }
ClassMethod Competition()
{
    do ##class(Rugby.Test.Competition).Run()
}
ClassMethod Movement()
{
    do ##class(Rugby.Test.Movement).Run()
}
ClassMethod Academy()
{
    do ##class(Rugby.Test.Academy).Run()
}
ClassMethod Lineups()
{
    set l=##class(Rugby.Service.Store).Get("Lineup","c1-default"),v=##class(Rugby.Service.Management).Validate(l)
    do ..Assert(v.valid,"Seed lineup valid")
    set l.slots.%Get(1).playerId=l.slots.%Get(0).playerId,v=##class(Rugby.Service.Management).Validate(l)
    do ..Assert('v.valid,"Duplicate rejected")
    set l=##class(Rugby.Service.Store).Get("Lineup","c1-default"),l.slots.%Get(3).playerId="c2-p4",v=##class(Rugby.Service.Management).Validate(l)
    do ..Assert('v.valid,"Wrong club rejected")
    set p=##class(Rugby.Service.Store).Get("Player","c1-p1"),p.available=0
    do ##class(Rugby.Service.Store).Put("Player",p)
    set l=##class(Rugby.Service.Store).Get("Lineup","c1-default"),v=##class(Rugby.Service.Management).Validate(l)
    do ..Assert('v.valid,"Unavailable rejected")
}
ClassMethod Management()
{
    set beforeAll=##class(Rugby.Service.Store).All("Player","clubId","c1").%Size()
    set p=##class(Rugby.Service.Management).Promote("c1","c1-p24"),p=##class(Rugby.Service.Management).Promote("c1","c1-p24")
    do ..Assert(p.category="senior","Promotion persists")
    set all=##class(Rugby.Service.Store).All("Player","clubId","c1")
    do ..Assert(all.%Size()=beforeAll,"Promotion does not duplicate")
    set c=##class(Rugby.Service.Store).Get("Club","c1"),before=c.day
    set c=##class(Rugby.Service.Management).Advance("c1",{"version":(c.version)},"test-day"),again=##class(Rugby.Service.Management).Advance("c1",{},"test-day")
    do ..Assert(c.day=again.day,"Retry does not advance twice")
    do ..Assert(c.day=(before+1),"Day increment")
    set movements=##class(Rugby.Service.Store).All("FinancialMovement","clubId","c1"),sum=c.initialBalance
    for i=0:1:movements.%Size()-1 { set sum=sum+movements.%Get(i).amount }
    do ..Assert(sum=c.balance,"Ledger agrees with balance")
    set ex=##class(Rugby.Service.Store).Get("TrainingExecution","c1-day"_c.day)
    do ..Assert(ex.results.%Size()=beforeAll,"Training results persisted")
}
ClassMethod Commands()
{
    set m=..Build(),replacement1="",replacement2="",incomingIndex=0
    for i=15:1:m.homePlayers.%Size()-1 {
        set p=m.homePlayers.%Get(i)
        if p.naturalPosition=1 set replacement1=p.playerId,incomingIndex=i
        if p.naturalPosition=2 set replacement2=p.playerId
    }
    set cmd={"type":"substitution","outId":"c1-p1","inId":(replacement1)}
    do ..Assert(##class(Rugby.Service.Matches).CheckCommand(m,{"type":"speed","speed":60},"home")="","Valid speed accepted")
    do ..Assert(##class(Rugby.Service.Matches).CheckCommand(m,{"type":"speed","speed":2},"home")'="","Invalid speed rejected")
    set c=##class(Rugby.Service.Matches).Command(m.id,cmd,"test-sub"),again=##class(Rugby.Service.Matches).Command(m.id,cmd,"test-sub")
    do ..Assert(c.id=again.id,"Idempotent command")
    set bad=##class(Rugby.Service.Matches).CheckCommand(m,{"type":"substitution","outId":"c1-p1","inId":"c1-p21"},"home")
    do ..Assert(bad="","A substitute may cover another position with a morale cost")
    set m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ##class(Rugby.Service.Matches).Commands(m)
    do ..Assert(m.homePlayers.%Get(0).status="replaced","Outgoing removed")
    do ..Assert(m.homePlayers.%Get(incomingIndex).status="field","Incoming field")
    set bad=##class(Rugby.Service.Matches).CheckCommand(m,{"type":"substitution","outId":(replacement1),"inId":"c1-p1"},"home")
    do ..Assert(bad'="","Reentry prohibited")
    set m.homeSubs=8,bad=##class(Rugby.Service.Matches).CheckCommand(m,{"type":"substitution","outId":"c1-p2","inId":(replacement2)},"home")
    do ..Assert(bad'="","Eight substitution limit")
    set m.homeSubs=1
    // Two individually valid commands can conflict at application time.
    do ##class(Rugby.Service.Store).Put("Match",m)
    set c=##class(Rugby.Service.Matches).Command(m.id,{"type":"substitution","outId":"c1-p2","inId":(replacement2)},"test-a")
    set c2=##class(Rugby.Service.Matches).Command(m.id,{"type":"substitution","outId":"c1-p2","inId":(replacement2)},"test-b")
    set m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ##class(Rugby.Service.Matches).Commands(m)
    set c2=##class(Rugby.Service.Store).Get("MatchCommand",c2.id)
    do ..Assert(c2.status="rejected","Revalidate queued commands")
    set sequence=m.sequence
    for i=1:1:10 { do ##class(Rugby.Simulation.Engine).Step(m) }
    set events=##class(Rugby.Service.Store).All("MatchEvent","matchId",m.id)
    for i=0:1:events.%Size()-1 { set e=events.%Get(i) if e.sequence>sequence do ..Assert(e.playerId'="c1-p1","Replaced player never participates again") }
}
ClassMethod Finish(m As %DynamicObject) As %DynamicObject
{
    set last=0
    for n=1:1:250 {
        quit:m.status="finished"
        if m.speed=0 set m.speed=20
        do ##class(Rugby.Simulation.Engine).Step(m)
        do ..Assert(m.clock>=last,"Monotonic clock")
        set last=m.clock
        do ..Assert((m.x>=0)&&(m.x<=100)&&(m.y>=0)&&(m.y<=70),"Field bounds")
        for side="home","away" { set a=m.%Get(side_"Players"),on=0 for j=0:1:a.%Size()-1 { set p=a.%Get(j) do ..Assert((p.energy>=0)&&(p.energy<=100),"Energy bounds") if $listfind($listbuild("field","sinBin","sentOff"),p.status)||((p.status="injured")&&('p.%Get("substituted",0))) set on=on+1 } do ..Assert(on=15,"Fifteen positions accounted for, including injuries and disciplinary absences") }
        do ##class(Rugby.Service.Store).Put("Match",m)
    }
    do ..Assert(m.status="finished","Terminates within 250 steps")
    do ..Assert((m.clock=4800)&&(m.period=2),"Two forty minute periods")
    quit m
}
ClassMethod Engine()
{
    set m=..Build(),p=m.homePlayers.%Get(0),before=p.energy
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert(p.energy<before,"Energy decreases")
    set m=..Finish(m),events=##class(Rugby.Service.Store).All("MatchEvent","matchId",m.id),home=0,away=0,seen={}
    for i=0:1:events.%Size()-1 {
        set e=events.%Get(i)
        do ..Assert('seen.%IsDefined(e.sequence),"Unique sequence")
        do seen.%Set(e.sequence,1)
        if e.side="home" set home=home+e.points
        if e.side="away" set away=away+e.points
        if e.type="try" do ..Assert(e.points=5,"Try five")
        if e.type="conversion" do ..Assert((e.points=0)||(e.points=2),"Conversion two")
        if (e.type="penaltyGoal")||(e.type="drop") do ..Assert((e.points=0)||(e.points=3),"Kick three")
    }
    do ..Assert((home=m.homeScore)&&(away=m.awayScore),"Score reconciles with events")
    set c=##class(Rugby.Service.Store).Get("Club","c1"),balance=c.balance
    do ##class(Rugby.Service.Matches).Settle(m)
    set c=##class(Rugby.Service.Store).Get("Club","c1")
    do ..Assert(c.balance=balance,"Settlement once")
}
ClassMethod Speed()
{
    set expected=""
    for speed=1,5,20,60 {
        // Nested transaction restores initial players and IDs for each replay.
        tstart
        set m=..Build(593),m.speed=speed
        do ##class(Rugby.Service.Store).Put("Match",m)
        for n=1:1:250 {
            quit:m.status="finished"
            if m.speed=0 { set m.speed=speed do ##class(Rugby.Service.Store).Put("Match",m) }
            do ..Assert(##class(Rugby.Job.Worker).Cycle(m.id,20/speed),"Worker obtained lock")
            set m=##class(Rugby.Service.Store).Get("Match",m.id)
        }
        do ..Assert(m.status="finished","All speeds terminate")
        set fingerprint=m.homeScore_":"_m.awayScore_":"_m.rng_":"_m.sequence
        if expected="" set expected=fingerprint
        do ..Assert(fingerprint=expected,"Speed independent exact RNG, score and events")
        trollback 1
    }
    set m=..Build(593),m.speed=20,m.credit=10
    do ##class(Rugby.Service.Store).Put("Match",m)
    set c=##class(Rugby.Service.Matches).Command(m.id,{"type":"speed","speed":5},"test-speed-credit")
    do ..Assert(##class(Rugby.Job.Worker).Cycle(m.id,.25),"Worker applies speed")
    set m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.credit=15)&&(m.speed=5)&&(m.clock=0),"Accumulate old speed before change without losing credit")
    do ..Assert(##class(Rugby.Job.Worker).Cycle(m.id,1),"Worker consumes remaining credit")
    set m=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((m.clock=20)&&(m.credit=0),"New speed used by following cycle")
}
ClassMethod Recovery()
{
    set m=..Build(852)
    for i=1:1:15 { do ##class(Rugby.Simulation.Engine).Step(m) }
    do ##class(Rugby.Service.Store).Put("Match",m)
    set saved=m.%ToJSON()
    tstart
    set a=..Finish(m),expected=a.homeScore_":"_a.awayScore_":"_a.rng
    trollback 1
    set b=##class(%DynamicObject).%FromJSON(saved),b=..Finish(b)
    do ..Assert((b.homeScore_":"_b.awayScore_":"_b.rng)=expected,"Resume from checkpoint identical")
    set before=b.sequence
    do ##class(Rugby.Simulation.Engine).Step(b)
    do ..Assert(b.sequence=before,"Finished match cannot advance")
}
ClassMethod Strength()
{
    set m=..Build(),p=m.homePlayers.%Get(0),high=##class(Rugby.Simulation.Engine).Rating(p,"handling")
    set p.energy=10,low=##class(Rugby.Simulation.Engine).Rating(p,"handling")
    do ..Assert(high>low,"Fatigue reduces performance")
    set beforeMorale=p.morale,p.energy=100,p.position=15,wrong=##class(Rugby.Simulation.Engine).Rating(p,"handling")
    do ..Assert(high=wrong,"Changing position alone does not scale player attributes")
    do ##class(Rugby.Simulation.Performance).AlignmentMorale(m.homePlayers)
    do ..Assert(p.morale<beforeMorale,"Playing out of position lowers morale")
    do ..Assert(##class(Rugby.Simulation.Engine).Clamp(3)=.92,"Probability upper bound")
    do ..Assert(##class(Rugby.Simulation.Engine).Clamp(-3)=.08,"Probability lower bound")
}
ClassMethod Probe(token As %String)
{
    lock +^RugbyMatch(token):0
    set ^RugbyProbe(token)=$test
    lock -^RugbyMatch(token)
}
ClassMethod Concurrency()
{
    set token="test-lock-"_$job
    kill ^RugbyProbe(token)
    lock +^RugbyMatch(token):0
    do ..Assert($test,"Test owns match lock")
    job ##class(Rugby.Test.Suite).Probe(token)
    for i=1:1:80 { quit:$data(^RugbyProbe(token))  hang .025 }
    do ..Assert($get(^RugbyProbe(token),-1)=0,"Second process cannot own match lock")
    lock -^RugbyMatch(token)
    kill ^RugbyProbe(token)
    job ##class(Rugby.Test.Suite).Probe(token)
    for i=1:1:80 { quit:$data(^RugbyProbe(token))  hang .025 }
    do ..Assert($get(^RugbyProbe(token),-1)=1,"Lock recovers after release")
    kill ^RugbyProbe(token)
}
ClassMethod Trends()
{
    set strong=0,weak=0
    for strength=20,95 {
        for seed=11,37,101,593,852,17341 {
            tstart
            set m=..Build(seed)
            for side="home","away" {
                set a=m.%Get(side_"Players"),level=$select(side="home":strength,1:115-strength)
                for i=0:1:a.%Size()-1 {
                    set p=a.%Get(i),iterator=p.attributes.%GetIterator()
                    while iterator.%GetNext(.key,.value) { do p.attributes.%Set(key,level) }
                }
            }
            set m=..Finish(m),diff=m.homeScore-m.awayScore
            if strength=95 { set strong=strong+diff } else { set weak=weak+diff }
            trollback 1
        }
    }
    do ..Assert(strong>weak,"Superior attributes improve aggregate score differential over fixed seeds")
}
ClassMethod Catalog()
{
    set clubs=##class(Rugby.Service.Store).All("Club"),count416=0,count417=0
    do ..Assert(clubs.%Size()=20,"Twenty official clubs")
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i) if c.competitionId=416 set count416=count416+1
        if c.competitionId=417 set count417=count417+1 }
    do ..Assert((count416=10)&&(count417=10),"Ten clubs in each division")
    set barca=##class(Rugby.Service.Store).Get("Club","c18")
    do ..Assert(barca.name="Barça Rugbi","UTF-8 club names remain intact")
    do ..Assert(barca.competition="División de Honor Élite","UTF-8 competition name remains intact")
}
ClassMethod Clock()
{
    set before=##class(Rugby.Job.Worker).Now()
    hang .05
    set elapsed=##class(Rugby.Job.Worker).Now()-before
    do ..Assert((elapsed>=.03)&&(elapsed<5),"Wall clock is in real seconds, not scaled or process CPU time")
}
ClassMethod Sessions()
{
    do ##class(Rugby.Test.Sessions).Run()
}
ClassMethod CalendarRules()
{
    do ##class(Rugby.Test.CalendarRules).Run()
}
ClassMethod Interop()
{
    do ##class(Rugby.Test.Interop).Run()
}
ClassMethod Rivals()
{
    do ##class(Rugby.Test.Rivals).Run()
}
ClassMethod Transfers()
{
    do ##class(Rugby.Test.Transfers).Run()
}
ClassMethod RealPlayers()
{
    do ##class(Rugby.Test.RealPlayers).Run()
}
ClassMethod Discipline()
{
    do ##class(Rugby.Test.Discipline).Run()
}
ClassMethod Bonus()
{
    do ##class(Rugby.Test.Bonus).Run()
}
ClassMethod Kits()
{
    do ##class(Rugby.Test.Kits).Run()
}
ClassMethod Tactics()
{
    do ##class(Rugby.Test.Tactics).Run()
}
ClassMethod Seasons()
{
    do ##class(Rugby.Test.Seasons).Run()
}
ClassMethod Morale()
{
    do ##class(Rugby.Test.Morale).Run()
}
ClassMethod Performance()
{
    do ##class(Rugby.Test.Performance).Run()
}
ClassMethod Promotion()
{
    do ##class(Rugby.Test.Promotion).Run()
}
ClassMethod Quality() { do ##class(Rugby.Test.Quality).Run() }
ClassMethod Finance() { do ##class(Rugby.Test.Finance).Run() }
ClassMethod Payroll() { do ##class(Rugby.Test.Payroll).Run() }
ClassMethod PlayerNames() { do ##class(Rugby.Test.PlayerNames).Run() }
ClassMethod StaffMarket() { do ##class(Rugby.Test.StaffMarket).Run() }
ClassMethod StaffNames() { do ##class(Rugby.Test.StaffNames).Run() }
ClassMethod FinanceRevision() { do ##class(Rugby.Test.FinanceRevision).Run() }
ClassMethod Injuries() { do ##class(Rugby.Test.Injuries).Run() }
ClassMethod GameDeletion() { do ##class(Rugby.Test.GameDeletion).Run() }
ClassMethod Availability() { do ##class(Rugby.Test.Availability).Run() }
ClassMethod MonthlyPayroll() { do ##class(Rugby.Test.MonthlyPayroll).Run() }
}
