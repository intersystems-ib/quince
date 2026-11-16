# Almacenamiento

- Auditoría de mensajes y registros de interoperabilidad: 2 días, respetando las sesiones activas.
- Las respuestas completas sólo viajan al cliente; la auditoría guarda resúmenes e identificadores.
- El entrenamiento conserva recibos mínimos para evitar duplicados y calcular nóminas. No se almacena el detalle diario por jugador ni copias del plan o del cuerpo técnico.
- La ficha del jugador utiliza acumulados por atributo y temporada.
- Se conservan partidas, contratos, resultados, estadísticas de jugadores y movimientos financieros.

Para reducir una instalación existente, detener la producción y ejecutar en `RUGBY`:

```objectscript
set report=##class(Rugby.Service.StorageMaintenance).Reduce()
do ##class(Rugby.Service.StorageMaintenance).Daily()
```

La operación no crea copias. Después puede recuperarse espacio físico mediante `SYS.Database.FileCompact` y `SYS.Database.ReturnUnusedSpace` en `%SYS`, usando el directorio de la base de datos correspondiente.
