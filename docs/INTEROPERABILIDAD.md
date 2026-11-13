# Interoperabilidad

Las operaciones de la API recorren `Rugby.API.REST → HTTP.In → API.Process → Business Operation`. `API.Process` selecciona la operación de negocio correspondiente. El avance diario pasa por `Rivals.Process` y `Rivals.Operation`.

Las operaciones confirman cada acción en una transacción. El avance diario incluye gestión propia, rivales, entrenamientos, finanzas y solicitudes de amistosos. La simulación usa un servicio de producción y registra sus transiciones.

La auditoría se consulta en el visor nativo de mensajes de IRIS. Cada respuesta incluye `X-Request-Id` y `X-Interop-Session-Id`; los mensajes conservan resultados y detalles, con credenciales ocultas.

El arranque inicializa los datos y registra sus operaciones en la auditoría. Las invitaciones de amistosos utilizan el mismo circuito, con comprobaciones de propiedad y claves de reintento.
