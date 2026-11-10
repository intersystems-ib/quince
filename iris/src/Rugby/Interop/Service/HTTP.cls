Class Rugby.Interop.Service.HTTP Extends Ens.BusinessService
{
Method OnProcessInput(pInput As Rugby.Interop.Message.Request, Output pOutput As Rugby.Interop.Message.Response) As %Status
{
    set pInput.Channel=$select(..%ConfigName="System.In":"system",1:"http")
    quit ..SendRequestSync("API.Process",pInput,.pOutput,120,"HTTP "_pInput.Method_" "_pInput.Resource_"/"_pInput.Child)
}
}
