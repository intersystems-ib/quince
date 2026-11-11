Class Rugby.Model.PlayerMatchStats Extends %Persistent
{
Property Key As %String(MAXLEN = 250) [ Required ];
Index StableKey On Key [ IdKey ];
Property Club As %String;
Index ClubIndex On Club;
Property Match As %String;
Index MatchIndex On Match;
Property Sequence As %Integer;
Property Version As %Integer [ InitialExpression = 0 ];
Property Payload As %String(MAXLEN = 3640000) [ Required ];

}
