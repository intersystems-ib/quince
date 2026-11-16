Class Rugby.Analytics.PlayerMatch Extends %Persistent [ Final ]
{
Parameter STORAGEDEFAULT = "columnar";
Parameter USEEXTENTSET = 1;
Property RecordKey As %String(MAXLEN = 250, STORAGEDEFAULT = "row") [ Required ];
Index RecordKeyIndex On RecordKey [ Unique ];
Property GameId As %String(MAXLEN = 120);
Property CompetitionId As %String(MAXLEN = 120);
Property PlayerId As %String(MAXLEN = 120);
Property ClubId As %String(MAXLEN = 120);
Property PlayerName As %String(MAXLEN = 250);
Property GameDay As %Integer;
Property IncompleteRecord As %Boolean;
Index ScopeIndex On (GameId, CompetitionId, PlayerId, GameDay);
Index BitmapExtent [ Extent, Type = bitmap ];
Property Points As %Integer;
Property Tries As %Integer;
Property Metres As %Double;
Property Carries As %Integer;
Property Passes As %Integer;
Property Actions As %Integer;
Property Tackles As %Integer;
Property Turnovers As %Integer;
Property Conversions As %Integer;
Property ConversionAttempts As %Integer;
Property PenaltyGoals As %Integer;
Property PenaltyAttempts As %Integer;
Property Drops As %Integer;
Property DropAttempts As %Integer;
Property Kicks As %Integer;
Property Scrums As %Integer;
Property Lineouts As %Integer;
Property KnockOns As %Integer;
Property Infringements As %Integer;
Property YellowCards As %Integer;
Property RedCards As %Integer;
Property PlayedSeconds As %Integer;
}
