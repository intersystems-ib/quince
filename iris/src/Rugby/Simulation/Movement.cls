Class Rugby.Simulation.Movement Extends %RegisteredObject
{
Parameter VERSION = "1.0.0";
ClassMethod Update(m As %DynamicObject, actor As %String = "")
{
    set switched=(m.period>=2)||(m.status="halftime"),carrier="",phase=m.phase
    if (phase="open")||(phase="ruck") {
        set candidate=$select(actor'="":actor,1:m.%Get("ballCarrierId")),players=m.%Get(m.possession_"Players")
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if (p.status="field")&&(p.playerId=candidate) set carrier=p.playerId
        }
        if carrier="" {
            for i=0:1:players.%Size()-1 { set p=players.%Get(i) if (p.status="field")&&(p.position=9) set carrier=p.playerId }
        }
    }
    set m.ballCarrierId=carrier,m.movementVersion=..#VERSION
    for side="home","away" {
        set players=m.%Get(side_"Players"),attacking=side=m.possession,left=(side="home")'=switched,direction=$select(left:1,1:-1)
        for i=0:1:players.%Size()-1 {
            set p=players.%Get(i)
            if p.status'="field" continue
            set pos=p.position,depth=+$piece("3,2,3,7,7,11,11,12,15,22,29,25,28,29,37",",",pos)
            set lane=+$piece("-14,0,14,-7,7,21,-21,0,-4,-11,-29,-18,-23,29,9",",",pos)
            set wave=(((m.clock\20)+(pos*3))#7)-3,ballY=##class(Rugby.Simulation.Engine).Clamp(m.y,5,65)
            set center=(ballY*.45)+(35*.55),spread=1
            if (phase="scrum")&&(pos<=8) { set lane=+$piece("-5,0,5,-2.5,2.5,8,-8,0",",",pos),spread=.9 }
            if (phase="lineout")&&(pos<=8) {
                set center=$select(m.y<35:8,1:62),lane=(pos-4.5)*1.8,depth=3+((pos#3)*3)
            }
            set defensiveGap=$select(phase="scrum":2,phase="ruck":3,1:7)
            set anchor=m.x-(direction*$select(attacking:0,1:defensiveGap))
            set x=anchor-(direction*depth*$select(attacking:1,1:.5))+(wave*.35)
            set y=center+(lane*spread*direction)+(wave*.45)
            if p.playerId=carrier set x=m.x,y=m.y
            set p.x=+$justify(##class(Rugby.Simulation.Engine).Clamp(x,2.5,97.5),0,3),p.y=+$justify(##class(Rugby.Simulation.Engine).Clamp(y,3,67),0,3)
        }
    }
}
}
