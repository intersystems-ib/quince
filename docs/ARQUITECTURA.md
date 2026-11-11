# Arquitectura

React y TypeScript consumen la API por el mismo origen. Nginx y Web Gateway conectan con IRIS:

`Rugby.API.REST → HTTP.In → API.Process → Business Operation → servicios → modelos persistentes`.

Cada entidad guarda un documento JSON versionado, separado por partida. JWT identifica al usuario y `X-Game-Id` selecciona su partida. El servidor valida propiedad y permisos.

Las escrituras usan bloqueo, transacción y claves de reintento. El trabajador de partidos confirma estados, eventos y comandos sin depender del navegador. La semilla permite reproducir simulaciones; la velocidad no cambia los sorteos deportivos.

Código: `../iris/src`, `../rugby-frontend/src` y `../webgateway`. Es una aplicación local; no incluye multijugador ni simulación física completa.
