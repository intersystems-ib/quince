Class Rugby.Interop.Message.Response Extends Ens.Response
{
Property CorrelationId As %String(MAXLEN = 100);
Property SessionId As %String(MAXLEN = 100);
Property HTTPStatus As %Integer [ InitialExpression = 200 ];
Property BodyJSON As %String(MAXLEN = 3640000) [ InitialExpression = "{}" ];
Property UserId As %String(MAXLEN = 100);
Property GameId As %String(MAXLEN = 100);
Property ErrorCode As %String(MAXLEN = 100);
Property DurationMs As %Numeric;
Property DetailsJSON As %String(MAXLEN = 3640000) [ InitialExpression = "{}" ];
}
