# Quince · Rugby Club Manager

[Español](README.md) · [English](README.en.md) · [Français](README.fr.md)

A rugby management game in Spanish, English and French, built with React, TypeScript and InterSystems IRIS. It includes twenty Honor and Élite clubs, 460 real player identities and private games with JWT authentication. Attributes, contracts and finances are simulated.

## Getting started

Requires Docker Engine or Docker Desktop with Linux containers and Compose v2. From the project root:

```powershell
Copy-Item .env.example .env
docker compose up -d --build
```

On Linux, use `cp .env.example .env` for the first command.

Application: [localhost:5175](http://localhost:5175). [API health](http://localhost:8085/api/v1/health). You can also use `./scripts/start.ps1`. Set the IRIS image in `.env`; the default is `latest-preview`.

For AWS, set `APP_PORT` in `.env` (for example, `80`) and allow that port in the instance security group. Compose listens on all interfaces: use the domain or public IP address. The application proxies API requests through `/api/v1`; `API_PORT` (default `8085`) does not need to be exposed in the security group. `VITE_API_TARGET` is only used for development.

## Playing

Create an account and a game, then choose a division and club. The season starts on 1 September. Manage the first team, academy, line-up, training, staff and transfers. Advance days and play pending fixtures. The calendar lets you arrange friendlies and respond to other clubs' invitations.

Live matches support pause, speed controls, substitutions and tactical changes, with automatic pauses at half-time and for your team's injuries. Competition separates standings, fixtures and player statistics into tabs. Wages are paid at month-end; the finance director negotiates September income.

Your club displays injuries, player and staff signings, and retirement announcements from all clubs over the last seven in-game days. The language selector remembers your choice without reloading the game.

## Development and tests

```powershell
docker compose up -d iris webgateway
cd rugby-frontend
npm ci
npm run dev
```

Development: [localhost:5176](http://localhost:5176). `VITE_API_TARGET` changes the target API.

```powershell
./scripts/test.ps1
```

Integration tests that advance games must run in a disposable instance. See [Verification](docs/en/VERIFICACION.md).

## Data and documentation

The `iris-data` volume keeps games when containers stop or are recreated. `./scripts/reset.ps1 -ConfirmDeleteAllRugbyData` permanently deletes all project data.

- [Architecture](docs/en/ARQUITECTURA.md) and [interoperability audit](docs/en/INTEROPERABILIDAD.md).
- [Access and games](docs/en/ACCESO-PARTIDAS.md) and [initial-data administration](docs/en/ADMINISTRACION.md).
- [Rules](docs/en/REGLAS.md), [competitions](docs/en/COMPETICION.md) and [seasons](docs/en/TEMPORADAS-CONTRATOS.md).
- [Players](docs/en/PLANTILLAS-REALES.md), [quality](docs/en/CALIDAD-EQUIPOS.md) and [academy](docs/en/CANTERA.md).
- [Opposition preparation and automatic advance](docs/en/PREPARACION-RIVAL.md).
- [Training](docs/en/ENTRENAMIENTO.md), [injuries](docs/en/LESIONES.md), [statistics](docs/en/ESTADISTICAS.md) and [morale](docs/en/MORAL.md).
- [Transfers](docs/en/FICHAJES.md), [finances](docs/en/FINANZAS.md) and [wages](docs/en/SALARIOS-PRESUPUESTO.md).
- [Languages](docs/en/IDIOMAS.md) and [storage](docs/en/almacenamiento.md).
- [API specification](docs/openapi.json): regenerate with `python scripts/generate_openapi.py`.

[Full documentation index](docs/en/README.md).
