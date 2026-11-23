Class Rugby.Simulation.AggregateScoring Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Step(m As %DynamicObject, step As %Integer, power As %DynamicObject)
{
    set tryWindow=((step#40)=20),kickWindow=((step#60)=30)
    if 'tryWindow&&'kickWindow quit
    set home=power.home/15,away=power.away/15
    for side="home","away" {
        set other=$select(side="home":"away",1:"home"),plan=m.aiTacticalAssessments.%Get(side),opponent=m.aiTacticalAssessments.%Get(other)
        set advantage=$select(side="home":home-away+3,1:away-home-3)+##class(Rugby.Simulation.Tactics).Modifier(plan,opponent)
        set priority=m.%Get(side_"Tactic").%Get("penaltyPriority","auto"),bonus=$select(priority="touch":.035,priority="quick":.025,priority="posts":-.015,1:0)
        if tryWindow {
            if ##class(Rugby.Simulation.Engine).Random(m)<##class(Rugby.Simulation.Engine).Clamp(.32+(advantage/100)+bonus,.1,.75) {
                do m.%Set(side_"Tries",m.%Get(side_"Tries",0)+1),m.%Set(side_"Score",m.%Get(side_"Score",0)+5)
                if ##class(Rugby.Simulation.Engine).Random(m)<.68 {
                    do m.%Set(side_"Conversions",m.%Get(side_"Conversions",0)+1),m.%Set(side_"Score",m.%Get(side_"Score",0)+2)
                }
            }
        }
        if kickWindow {
            set opportunity=(step-30)\60,attempt=(priority="posts")||((priority="auto")&&(opportunity<3))||(opportunity=0)
            if attempt {
                do m.%Set(side_"PenaltyAttempts",m.%Get(side_"PenaltyAttempts",0)+1)
                set kicker=##class(Rugby.Simulation.Performance).Kicker(m.%Get(side_"Players")),rating=0
                if $isobject(kicker) set rating=##class(Rugby.Simulation.Engine).Rating(kicker,"kicking")
                if ##class(Rugby.Simulation.Engine).Random(m)<##class(Rugby.Simulation.Engine).Clamp(.20+(rating/220),.15,.85) {
                    do m.%Set(side_"PenaltyGoals",m.%Get(side_"PenaltyGoals",0)+1),m.%Set(side_"Score",m.%Get(side_"Score",0)+3)
                }
            }
        }
    }
}
}
