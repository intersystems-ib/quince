# Arquitectura

Se reutiliza la separación de `C:\Code\bronze-wars`: `iris/`, `webgateway/` y frontend Vite, con Compose. No se importan sus modelos, credenciales privadas, motor de IA ni dependencia GPU.

```
React + TypeScript + Router + TanStack Query
            │ HTTP /api/v1 (mismo origen)
            ▼
Nginx frontend → Web Gateway → Rugby.API.REST
                                  │
                    HTTP.In → API.Process → Business Operations
                                  │
                    Management / Matches / Store
                                  │
                      Clases persistentes IRIS
                                  ▲
                Simulation.In → Simulation.Process → Simulation.Operation → Simulation.Engine
```

El navegador no simula, calcula resultados ni controla el reloj. El campo SVG representa coordenadas autoritativas. Se sondea estado cada segundo y comandos cada 1,5 segundos. La narración utiliza `afterSequence`, con paginación de 500 eventos y deduplicación por secuencia; en una recarga se reconstruye desde cero sin reiniciar el partido. Errores de conexión conservan el último estado y siguen reintentando.

## Almacenamiento

Dieciocho clases `%Persistent`: Club, Player, Lineup, LineupSlot, Tactic, TrainingPlan, TrainingExecution, FinancialMovement, Fixture, Match, MatchPlayer, MatchEvent, MatchCommand, Coach, TechnicalStaff, StaffContract, Competition y PlayerContract. Cada una tiene clave estable `Key` como IdKey, versión, índices de club y partido y un agregado JSON `Payload`. MatchEvent añade unicidad `(Match, Sequence)`. Los campos de catálogo e índices se escriben junto con el agregado; `^RugbyCatalog` permite recorrer claves sin SQL dinámico. Las referencias se validan en los servicios. Los objetos anidados son agregados JSON versionados, no columnas SQL para cada atributo; es una decisión explícita de este MVP.

Match contiene las instantáneas operativas de sus convocados; MatchPlayer persiste la misma información para consulta individual. Se guardan juntas en la misma transacción. Cambiar un jugador de la plantilla después de iniciar no altera la instantánea. LineupSlot y Tactic son proyecciones persistentes de la alineación; solo las escribe el servicio correspondiente.

## Concurrencia e idempotencia

- Todas las mutaciones HTTP adquieren `^RugbyWrite`, abren transacción y confirman o revierten todos los cambios.
- Worker también adquiere `^RugbyMatch(id)` y comprueba la versión cargada antes de guardar. `^RugbyWorker` excluye procesos trabajadores adicionales.
- Las ediciones de alineación y entrenamiento y el avance de día requieren `version`, devuelven 409 si está obsoleta.
- Inicio retorna el partido existente; creación queda vinculada de forma única al encuentro del calendario. Promoción cambia la categoría de la ficha existente.
- `Idempotency-Key` identifica los comandos y avances; un reintento con la misma clave devuelve el resultado previo. Usar una clave diferente representa otra intención. No reutilizar una clave con otro cuerpo; el MVP devuelve la primera operación sin comparar hashes del cuerpo.
- Ledger: movimiento único por `club + origen`; saldo e historial se guardan juntos. Liquidación se protege por `settled`, clave de movimiento y la transacción de cierre.
- No hay borrados ni reinitialización destructiva al arrancar. El script reset está separado y exige una opción explícita.

## Identidad y acceso

Identidad fija de desarrollo: `c1` (Complutense Cisneros). Se pueden consultar todos los clubes; solo modificar el gestionado. IRIS no publica sus puertos directamente, la API y el frontend se enlazan a `127.0.0.1`. No hay CORS global; Vite usa proxy en desarrollo. La aplicación IRIS permite acceso local sin autenticación de usuario y con rol amplio para simplificar el entorno. Esto no es autenticación de producción: no exponer públicamente; antes de desplegar añadir autenticación, roles mínimos, protección CSRF, límites de uso y TLS.

## Límites y siguientes mejoras

- Un solo usuario local y un club gestionable; diecinueve amistosos, sin ligas completas, mercado, contratos avanzados ni insolvencia.
- El motor agregado simplifica muchos procedimientos; consultar REGLAS.md.
- Semilla fija por defecto 17341; la API permite otra. Se preserva `engineVersion`; cambios incompatibles de motor deben exigir migración explícita o terminar partidas con la versión anterior.
- Edición visual del XV principal. La API admite crear otras alineaciones; las nuevas se seleccionan al preparar un encuentro. No hay editor visual de todos los planes guardados en paralelo.
- Sin retención/archivado automático de eventos; las respuestas están paginadas. La UI muestra los últimos 100 de la narración y hasta 500 comandos.
- Próximos pasos: normalizar atributos para analítica SQL, separar bloqueos por club y partido, autorización real, migraciones de esquema y versiones de motor, ampliar IA y calibrar resultados con datos.


Competición añade `Rugby.Model.Competition`, el sorteo y las transiciones de fase en `Rugby.Service.Competition`. Los resultados de Fixture son la única fuente de la clasificación; las localías de playoffs utilizan el orden regular congelado.


## Cuentas y partidas privadas

El acceso JWT y la selección de partida preceden a todas las operaciones del juego. Las claves físicas e índices de los modelos incluyen la partida, y los catálogos y contadores se separan bajo `^RugbyWorld`. El club gestionado se determina en el servidor. El worker procesa cada partida activa en su contexto. Véase [acceso, partidas y calendario](ACCESO-PARTIDAS.md). La identidad fija c1 descrita en comprobaciones históricas ya no se usa para autorizar peticiones.


## Producción de interoperabilidad

La API HTTP invoca el Business Service de entrada; los procesos y operaciones se ejecutan en `Rugby.Interop.Production`. El antiguo worker independiente queda sustituido por un Business Service con adaptador de sondeo. La auditoría se consulta mediante mensajes, sesiones, traza visual y registro de eventos nativos de IRIS, sin una pantalla o repositorio de auditoría propios. Ver [componentes, seguridad y consulta de trazas](INTEROPERABILIDAD.md).
