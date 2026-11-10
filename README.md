# Quince · Rugby Club Manager

MVP de mánager de rugby union en español: **IRIS + ObjectScript** y **React + TypeScript**. Veinte equipos oficiales de División de Honor y División de Honor Élite 2026/27; eliges división y club al crear cada partida. Las convocatorias del primer equipo usan 460 identidades reales extraídas de las actas de la primera jornada. Canteras, agentes libres y condiciones deportivas son simulados. Inspirado en la estructura del proyecto `bronze-wars`, sin modificarlo.

## Arranque

Requisitos: Docker Desktop con contenedores Linux, Compose v2, acceso a las imágenes oficiales de InterSystems y recursos suficientes para IRIS Community. Para desarrollo de frontend: Node 22.12+ y npm. Community está sujeto a su licencia de desarrollo/evaluación y límites del fabricante; no se incluye una licencia comercial ni se requieren componentes AI Hub.

```powershell
cd C:\Code\rugby
Copy-Item .env.example .env
docker pull containers.intersystems.com/intersystems/iris-community:latest-preview
docker compose up -d --build
docker compose logs -f iris
```

Abre **[http://localhost:5175](http://localhost:5175)**. La API de diagnóstico está en [http://localhost:8085/api/v1/health](http://localhost:8085/api/v1/health). Espera a que devuelva `status: ok` y un `workerHeartbeat` reciente. El inicio compila las clases, crea los datos si faltan y lanza un trabajador independiente del navegador. `workerError` permite diagnosticar errores del trabajador; los detalles HTTP se guardan en `^RugbyAPIError(requestId)`.

También puedes ejecutar `./scripts/start.ps1`. Si ya existe `.env`, conserva tus ajustes. `IRIS_IMAGE` usa la imagen solicitada `containers.intersystems.com/intersystems/iris-community:latest-preview`; `WEBGATEWAY_IMAGE` permite usar una imagen de pasarela ya instalada, como `bronze-wars-webgateway:latest`, o la oficial del ejemplo. La etiqueta preview es mutable: para despliegues reproducibles fija el digest descargado en `.env`. Si tu registro exige autenticación, realiza `docker login containers.intersystems.com` con tu cuenta antes de descargar. No guardes credenciales en el repositorio.

El puerto del frontend se configura con `APP_PORT`. IRIS no expone sus puertos de base de datos o administración. Todos los puertos publicados se enlazan exclusivamente a localhost.

## Recorrido jugable

1. En **Plantilla**, filtra jugadores, abre una ficha o compara dos jugadores.
2. En **Cantera**, promociona una promesa; conserva su identificador y su ficha.
3. En **Alineación y táctica**, elige quince titulares, hasta ocho suplentes, capitán y táctica. Guarda y valida. Los tres puestos de primera línea exigen especialistas y cobertura en el banquillo completo.
4. En **Entrenamiento**, selecciona jugadores, crea grupos con especialidad e intensidad y guarda la planificación. En **Cuerpo técnico**, contrata los ocho tipos de especialistas. **Avanzar día** aplica sesiones, recuperación y progresión decimal limitada por edad sin costes diarios de entrenamiento; al cerrar cada mes se pagan las nóminas de jugadores, técnicos y financiero, con prorrateo por días. No se permite avanzar con un partido en curso.
5. Desde el panel o **Calendario**, prepara un encuentro cuya fecha haya llegado. Entra e inicia el partido; el servidor valida la alineación de nuevo y fija las instantáneas.
6. En directo, cambia entre x1/x5/x20/x60, solicita una sustitución y envía táctica. Consulta los estados de comando y el campo SVG. Puedes cerrar la página y volver: el trabajador sigue simulando.
7. Al finalizar consulta el resumen, las estadísticas, el historial y **Finanzas**. Los ingresos se liquidan una sola vez. Avanza tres días para el siguiente amistoso.

## Persistencia y reinicio

`iris-data` es un volumen durable administrado por Docker: contiene bases, clases, journal y partida. `docker compose down` conserva los datos. `docker compose restart iris` recupera los encuentros desde su último estado confirmado, conserva el crédito ya acumulado y no simula el tiempo durante el que estuvo apagado. No hay un proceso por encuentro ni peticiones abiertas durante el partido.

La inicialización es idempotente. Para una **partida nueva destructiva**, ejecuta por separado:

```powershell
./scripts/reset.ps1 -ConfirmDeleteAllRugbyData
docker compose up -d
```

Esto elimina el volumen de datos de este proyecto. No forma parte del arranque normal. Antes de cambiar de versión de IRIS, guarda una copia del volumen y verifica la compatibilidad de actualización del fabricante. No intentes reutilizar una base de una versión más nueva en una más antigua.

## Desarrollo

```powershell
docker compose up -d iris webgateway
cd rugby-frontend
npm ci
npm run dev
```

Frontend de desarrollo: [http://localhost:5176](http://localhost:5176), con proxy a `http://localhost:8085`. `VITE_API_TARGET` puede cambiar el destino del proxy. Las variables de la raíz se usan por Compose; para Vite establece la variable en el shell si necesitas cambiarla.

Al modificar ObjectScript, reconstruye y recrea IRIS con `docker compose up -d --build iris`. Al arrancar se vuelven a cargar las fuentes; el volumen conserva los datos. No se usa otro backend ni un modo simulado en React.

## Pruebas

```powershell
./scripts/test.ps1
```

Ejecuta la suite en IRIS y compila TypeScript/Vite. Los casos de datos se revierten al terminar; el de exclusión mutua usa dos procesos reales y limpia su señal de prueba. Las secuencias internas de identificadores pueden avanzar al probar; no se exige que sean consecutivas. La suite comprueba alineaciones, disponibilidad, club, promoción, entrenamiento y economía idempotentes, comandos, primera línea, no reentrada, ocho cambios, revalidación en cola, puntuación, límites de energía y geometría, fin de partido, liquidación única, reproducción exacta a cuatro velocidades, recuperación de checkpoint, bloqueo entre procesos y tendencias con doce simulaciones reproducibles.

El recorrido HTTP y de navegador se describe en [VERIFICACION.md](docs/VERIFICACION.md). Las pruebas end-to-end necesitan los tres contenedores arrancados:

```powershell
cd rugby-frontend
npx playwright install chromium
npm run test:e2e
```

El caso completo consume un amistoso y avanza el día de gestión en la partida de prueba. Úsalo en una instancia de demostración; no ejecutarlo sobre una partida que quieras conservar intacta.

## Acceso y partidas

Al abrir la aplicación, crea una cuenta o inicia sesión. Desde Mis partidas puedes iniciar una temporada eligiendo división y club, o cargar una partida en curso. Las nuevas partidas empiezan el 1 de septiembre de 2026. El calendario mensual permite concertar amistosos. Ver [acceso, persistencia y calendario](docs/ACCESO-PARTIDAS.md).

## Documentación

- [Gestión determinista de rivales, entrenamientos y mercado](docs/RIVALES.md).

- [Producción de interoperabilidad, componentes y auditoría nativa](docs/INTEROPERABILIDAD.md).

- [Arquitectura, concurrencia y límites](docs/ARQUITECTURA.md).
- [Reglas, fórmulas y fuentes de World Rugby](docs/REGLAS.md).
- [Tarjetas amarillas, rojas y exclusiones durante los partidos](docs/DISCIPLINA.md).
- [Catálogo oficial de clubes y procedencia](docs/CLUBES.md).
- [460 jugadores reales de Honor y Élite, extraídos de las actas](docs/PLANTILLAS-REALES.md).
- [Escudos originales y procedencia de las imágenes](docs/ESCUDOS.md).
- [Entrenamiento por grupos, progresión anual y cuerpo técnico](docs/ENTRENAMIENTO.md).
- [Cantera, entrenador, promoción negociada y rescisión de contratos](docs/CANTERA.md).
- [Primera y segunda equipación con selección automática por contraste](docs/EQUIPACIONES.md).
- [Fichajes de agentes libres y negociación salarial](docs/FICHAJES.md).
- [Contrato OpenAPI 3.1](docs/openapi.json). Regenerar con `python scripts/generate_openapi.py`.
- [Comprobaciones realizadas y pendientes](docs/VERIFICACION.md).

El acceso usa cuentas y JWT en cookie HttpOnly; las partidas están separadas por usuario. El servicio actual se publica solo en localhost. El motor simplifica el reglamento; incluye mercado de agentes libres con negociación salarial. No incluye multijugador, lesiones o sanciones complejas, ni animación física individual.

Prueba HTTP completa, con reinicio real de IRIS: `python scripts/integration.py --restart-backend`. Consume un amistoso y puede avanzar días o promocionar un juvenil en la partida de demostración. Ejecutarla en una instancia de prueba.


La pestaña **Competición** sustituye al calendario de amistosos e incluye liga regular de 18 jornadas y fase final en ambas divisiones. Ver [formato, sorteo y continuidad de la partida](docs/COMPETICION.md).

Detalles del [motor de partidos por participantes y moral](docs/MOTOR-PARTIDOS.md).

Reglas de [moral de todos los clubes](docs/MORAL.md).

[Temporadas, contratos, retiradas y entrenamiento por plantilla](docs/TEMPORADAS-CONTRATOS.md).

La previa permite comparar el XV, delanteros y tres cuartos. El rival adapta su táctica a ambos equipos y al desarrollo del partido: [criterios y auditoría](docs/TACTICAS.md).

Las medias iniciales se calibran por la clasificación de cada club, con mayor nivel en Honor: [referencia, rangos y migración](docs/CALIDAD-EQUIPOS.md).

Gestión financiera: contratación del financiero, campañas automáticas de septiembre, acuerdos plurianuales, abonados y recaudación por asistentes. [Reglas y auditoría](docs/FINANZAS.md).

[Salarios proporcionales por club](docs/SALARIOS-PRESUPUESTO.md): plantilla y cantera, límites para nuevas contrataciones y margen anual mínimo del 15 % sobre el presupuesto del club. Los jugadores se muestran y negocian con importes mensuales.

Plantilla reúne primer equipo y cantera en dos pestañas. Los nuevos jugadores españoles de cantera y mercado se generan con nombre y dos apellidos; los extranjeros conservan su formato.

[Equipaciones de los veinte clubes](docs/EQUIPACIONES.md), con colores y franjas en campo, marcador y directorio, segunda camiseta automática y balón del icono.

Financiación: referencias de 250.000–800.000 €, un patrocinador principal, cinco secundarios y concesión plurianual del bar. El bar se gestiona en Finanzas.

Los scripts de integración guardan sus archivos en la carpeta temporal del sistema (`rugby-test-results`) o en `RUGBY_TEST_ARTIFACTS`. Las capturas, cachés y resultados no forman parte del código fuente; los recursos de la aplicación permanecen en `rugby-frontend/public`.

Las alineaciones permiten combinar puestos con pérdida de moral. El módulo de [lesiones](docs/LESIONES.md) incluye veinte variantes, bajas en partidos y entrenamiento, recuperación por fecha e historial.

En [Mis partidas](docs/PARTIDAS.md) puedes eliminar tus propias partidas con confirmación previa.

Los partidos se pausan por lesión de tu equipo y al descanso; se reanudan seleccionando una velocidad. El último de la regular de Honor y el campeón de los playoffs de Élite intercambian divisiones al cerrar la temporada. Las referencias iniciales de calidad combinan historia y actualidad; véase [Calidad de equipos](docs/CALIDAD-EQUIPOS.md). Los campos y aforos publicados aparecen en clubes y partidos, y las previsiones nuevas respetan el aforo.
