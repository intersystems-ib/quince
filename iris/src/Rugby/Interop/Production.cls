Class Rugby.Interop.Production Extends Ens.Production
{
XData ProductionDefinition
{
<Production Name="Rugby.Interop.Production" LogGeneralTraceEvents="true">
  <Description>Operaciones de Quince con trazabilidad de peticiones, procesos y cambios de datos.</Description>
  <Item Name="HTTP.In" ClassName="Rugby.Interop.Service.HTTP" PoolSize="0" Enabled="true"/>
  <Item Name="System.In" ClassName="Rugby.Interop.Service.HTTP" PoolSize="0" Enabled="true"/>
  <Item Name="Simulation.In" ClassName="Rugby.Interop.Service.Simulation" PoolSize="1" Enabled="true"><Setting Target="Adapter" Name="CallInterval">0.25</Setting></Item>
  <Item Name="API.Process" ClassName="Rugby.Interop.Process.Dispatch" PoolSize="0" Enabled="true"/>
  <Item Name="Simulation.Process" ClassName="Rugby.Interop.Process.Dispatch" PoolSize="0" Enabled="true"/>
  <Item Name="Rivals.Process" ClassName="Rugby.Interop.Process.Rivals" PoolSize="0" Enabled="true"/>
  <Item Name="Rivals.Operation" ClassName="Rugby.Interop.Operation.Rivals" PoolSize="0" Enabled="true"/>
  <Item Name="Transfers.Operation" ClassName="Rugby.Interop.Operation.Transfers" PoolSize="0" Enabled="true"/>
  <Item Name="Access.Operation" ClassName="Rugby.Interop.Operation.Access" PoolSize="0" Enabled="true"/>
  <Item Name="Games.Operation" ClassName="Rugby.Interop.Operation.Games" PoolSize="0" Enabled="true"/>
  <Item Name="Finance.Operation" ClassName="Rugby.Interop.Operation.Finance" PoolSize="0" Enabled="true"/>
  <Item Name="Club.Operation" ClassName="Rugby.Interop.Operation.Club" PoolSize="0" Enabled="true"/>
  <Item Name="Matches.Operation" ClassName="Rugby.Interop.Operation.Matches" PoolSize="0" Enabled="true"/>
  <Item Name="Competition.Operation" ClassName="Rugby.Interop.Operation.Competition" PoolSize="0" Enabled="true"/>
  <Item Name="Simulation.Operation" ClassName="Rugby.Interop.Operation.Simulation" PoolSize="0" Enabled="true"/>
  <Item Name="System.Operation" ClassName="Rugby.Interop.Operation.System" PoolSize="0" Enabled="true"/>
</Production>
}
}
