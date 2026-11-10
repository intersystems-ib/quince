Class Rugby.Test.Kits Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set clubs=##class(Rugby.Service.Store).All("Club"),pairs=0
    for i=0:1:clubs.%Size()-1 {
        set home=clubs.%Get(i)
        for choice="primary","secondary" {
            set configured=home.kits.%Get(choice),kit=##class(Rugby.Service.Kits).Kit(home,choice)
            do ..Assert((kit.accentColor=configured.accentColor)&&(kit.pattern=configured.pattern)&&(kit.description=configured.description),"Chosen kit carries user palette and design")
            do ..Assert(##class(Rugby.Service.Kits).Valid(kit.accentColor),"Accent colors are valid")
            if configured.%IsDefined("thirdColor") do ..Assert(kit.thirdColor=configured.thirdColor,"Tricolor designs preserve all three colors")
        }
        do ..Assert('##class(Rugby.Service.Kits).Clash(home.kits.primary.color,home.kits.secondary.color),"Each club has two distinct kits")
        for j=0:1:clubs.%Size()-1 {
            if i=j continue
            set chosen=##class(Rugby.Service.Kits).Resolve(home,clubs.%Get(j)),pairs=pairs+1
            do ..Assert('##class(Rugby.Service.Kits).Clash(chosen.home.color,chosen.away.color),"Every possible pairing has distinguishable shirts")
            for side="home","away" {
                set kit=chosen.%Get(side),light=##class(Rugby.Service.Kits).Luminance(kit.color),contrast=$select(kit.numberColor="#000000":(light+.05)/.05,1:1.05/(light+.05))
                do ..Assert(contrast>=4.5,"Numbers contrast with the chosen shirt")
            }
        }
    }
    do ..Assert(pairs=380,"All ordered pairings across both divisions are covered")
    set a=##class(Rugby.Service.Store).Get("Club","c1"),b=##class(Rugby.Service.Store).Get("Club","c2"),chosen=##class(Rugby.Service.Kits).Resolve(a,b)
    do ..Assert((chosen.home.id="primary")&&(chosen.away.id="secondary")&&chosen.clashResolved,"Similar blues switch the visitor to the second kit")
    set chosen=##class(Rugby.Service.Kits).Resolve(a,##class(Rugby.Service.Store).Get("Club","c9"))
    do ..Assert((chosen.home.id="primary")&&(chosen.away.id="primary")&&('chosen.clashResolved),"Clearly distinct primary kits are retained")
    set m=##class(Rugby.Test.Suite).Build(),homeColor=m.homeColor,awayColor=m.awayColor,m.status="halftime",m.clock=2400
    do ##class(Rugby.Simulation.Engine).Step(m)
    do ..Assert((m.homeColor=homeColor)&&(m.awayColor=awayColor),"Changing ends does not change the selected kits")
    do ##class(Rugby.Service.Store).Put("Match",m)
    set players=m.homePlayers.%ToJSON(),clock=m.clock,score=m.homeScore,version=m.version
    kill ^RugbyWorld(##class(Rugby.Service.Store).Game(),"kitVersion")
    set report=##class(Rugby.Service.Kits).Initialize(),saved=##class(Rugby.Service.Store).Get("Match",m.id)
    do ..Assert((report.clubs=20)&&(report.matches>0)&&(saved.homePlayers.%ToJSON()=players)&&(saved.clock=clock)&&(saved.homeScore=score),"Existing matches gain kit metadata without altering sports state")
    set version=saved.version,again=##class(Rugby.Service.Kits).Initialize()
    do ..Assert((again.matches=0)&&(##class(Rugby.Service.Store).Get("Match",m.id).version=version),"Kit initialization is idempotent")
}
}
