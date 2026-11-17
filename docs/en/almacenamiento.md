# Storage

[Español](../almacenamiento.md) · [English](almacenamiento.md) · [Français](../fr/almacenamiento.md) · [Index](README.md)

- Interoperability messages and logs are retained for two days, respecting active sessions.
- Full responses travel only to the client; audit stores summaries and identifiers.
- Training keeps minimal receipts for idempotency and payroll. It does not store daily per-player details or copies of the plan and staff.
- Player profiles use attribute totals accumulated by season.
- Games, contracts, results, player statistics and financial transactions are retained.

To reduce an existing installation, stop the interoperability production and run in `RUGBY`:

```objectscript
set report=##class(Rugby.Service.StorageMaintenance).Reduce()
do ##class(Rugby.Service.StorageMaintenance).Daily()
```

This operation creates no backups. Afterwards, reclaim physical space with `SYS.Database.FileCompact` and `SYS.Database.ReturnUnusedSpace` in `%SYS`, using the appropriate database directory.
