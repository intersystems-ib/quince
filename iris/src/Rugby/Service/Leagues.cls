Class Rugby.Service.Leagues Extends %RegisteredObject
{
ClassMethod Ids() As %DynamicArray { quit [416,417,1401,1402] }
ClassMethod French(division As %Integer) As %Boolean { quit (division=1401)||(division=1402) }
ClassMethod Config(division As %Integer) As %DynamicObject
{
    set french=..French(division),size=$select(division=1401:14,division=1402:16,1:10),name=$select(division=416:"División de Honor",division=417:"División de Honor Élite",division=1401:"Top 14",division=1402:"Pro D2",1:"")
    if name="" do ##class(Rugby.Service.Store).Fail(422,"DIVISION","Competición desconocida.")
    quit {"id":(division),"name":(name),"countryCode":($select(french:"FR",1:"ES")),"teams":(size),"rounds":((size-1)*2),"regularMatches":(size*(size-1)),"playoffTeams":($select(french:6,1:4)),"directSemifinals":($select(french:2,1:0)),"defensiveBonusMargin":($select(french:5,1:7))}
}
ClassMethod Country(c As %DynamicObject) As %String { quit $select(..French(c.competitionId):"FR",1:"ES") }
ClassMethod ClubIds() As %DynamicArray
{
    set clubs=##class(Rugby.Service.Store).All("Club"),result=[],seen={}
    for i=0:1:clubs.%Size()-1 { set id=clubs.%Get(i).competitionId if 'seen.%IsDefined(id) { do seen.%Set(id,1),result.%Push(id) } }
    quit result
}
}
