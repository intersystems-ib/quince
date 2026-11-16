Class Rugby.Interop.Message.Response Extends Ens.Response
{
Property CorrelationId As %String(MAXLEN = 100);
Property SessionId As %String(MAXLEN = 100);
Property HTTPStatus As %Integer [ InitialExpression = 200 ];
Property BodyJSON As %String(MAXLEN = 3640000) [ InitialExpression = "{}" ];
Property TransportJSON As %String(MAXLEN = 3640000) [ Transient ];
Property UserId As %String(MAXLEN = 100);
Property GameId As %String(MAXLEN = 100);
Property ErrorCode As %String(MAXLEN = 100);
Property DurationMs As %Numeric;
Property DetailsJSON As %String(MAXLEN = 3640000) [ InitialExpression = "{}" ];
Method SetBody(json As %String)
{
    if $length(json)>2048 set %RugbyWireId=..CorrelationId,%RugbyWireJSON=json
    set ..TransportJSON=json,..BodyJSON=##class(Rugby.Interop.Audit).Summary(json)
}
Method Payload() As %String
{
    if $data(%RugbyWireJSON)&&($get(%RugbyWireId)=..CorrelationId) quit %RugbyWireJSON
    quit $select(..TransportJSON'="":..TransportJSON,1:..BodyJSON)
}
}
