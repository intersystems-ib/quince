Class Rugby.Interop.Message.Request Extends Ens.Request
{
Property CorrelationId As %String(MAXLEN = 100);
Property Channel As %String [ InitialExpression = "http" ];
Property Method As %String;
Property Resource As %String;
Property EntityId As %String(MAXLEN = 250);
Property Child As %String;
Property PlayerId As %String(MAXLEN = 250);
Property GameId As %String(MAXLEN = 100);
Property IdempotencyKey As %String(MAXLEN = 100);
Property QueryJSON As %String(MAXLEN = 65536) [ InitialExpression = "{}" ];
Property BodyJSON As %String(MAXLEN = 65536) [ InitialExpression = "{}" ];
Property InputErrorStatus As %Integer;
Property InputErrorCode As %String;
Property InputErrorMessage As %String(MAXLEN = 1000);
}
