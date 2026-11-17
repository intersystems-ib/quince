# Interoperability

[Español](../INTEROPERABILIDAD.md) · [English](INTEROPERABILIDAD.md) · [Français](../fr/INTEROPERABILIDAD.md) · [Index](README.md)

API operations follow `Rugby.API.REST → HTTP.In → API.Process → Business Operation`. `API.Process` chooses the business operation. Daily advancement goes through `Rivals.Process` and `Rivals.Operation`.

Operations commit each action in a transaction. A daily advance includes the managed club, opponents, training, finances and friendly requests. Simulation runs through a production service and records its transitions.

Audit is available in the native IRIS message viewer. Responses include `X-Request-Id` and `X-Interop-Session-Id`; persisted messages retain summaries and identifiers, with credentials hidden. Retention is two days, respecting active sessions.

Startup initialises data and audits its operations. Friendly invitations use the same path, with ownership validation and retry keys. See [Storage](almacenamiento.md).
