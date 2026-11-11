# Quince · Rugby Club Manager

Mánager de rugby en español con React, TypeScript e InterSystems IRIS. Incluye veinte clubes de Honor y Élite, 460 identidades reales y partidas privadas con JWT. Atributos, contratos y economía son simulados.

## Arranque

Requiere Docker Desktop con contenedores Linux y Compose v2. Desde la raíz del proyecto:

```powershell
Copy-Item .env.example .env
docker compose up -d --build
```

Aplicación: [localhost:5175](http://localhost:5175). [Estado de la API](http://localhost:8085/api/v1/health). También puedes usar `./scripts/start.ps1`. La imagen IRIS se configura en `.env` y usa `latest-preview` por defecto.

Para publicar en AWS, configura `APP_PORT` en `.env` (por ejemplo, `80`) y permite ese puerto en el grupo de seguridad de la instancia. Compose escucha en todas las interfaces: accede mediante el dominio o la IP pública. La aplicación incluye el acceso a la API en `/api/v1`; no hace falta abrir `API_PORT` (por defecto `8085`) en el grupo de seguridad. `VITE_API_TARGET` sólo se usa en desarrollo.

## Jugar

Crea una cuenta y una partida, elige división y club. La temporada empieza el 1 de septiembre. Gestiona plantilla y cantera, alineación, entrenamientos, empleados y fichajes. Avanza días y disputa los encuentros pendientes. Calendario permite concertar amistosos y responder a invitaciones de rivales.

El directo admite pausa, velocidades, sustituciones y cambios tácticos; se detiene al descanso y ante lesiones propias. Competición reúne regular y playoffs. Las nóminas se pagan al final de mes y el financiero negocia los ingresos de septiembre.

## Desarrollo y pruebas

```powershell
docker compose up -d iris webgateway
cd rugby-frontend
npm ci
npm run dev
```

Desarrollo: [localhost:5176](http://localhost:5176). `VITE_API_TARGET` cambia la API de destino.

```powershell
./scripts/test.ps1
```

Las integraciones que avanzan partidas deben ejecutarse en una instancia desechable. Véase [Verificación](docs/VERIFICACION.md).

## Datos y documentación

El volumen `iris-data` conserva las partidas al detener o recrear contenedores. `./scripts/reset.ps1 -ConfirmDeleteAllRugbyData` elimina todos los datos del proyecto.

- [Arquitectura](docs/ARQUITECTURA.md) y [auditoría](docs/INTEROPERABILIDAD.md).
- [Acceso y partidas](docs/ACCESO-PARTIDAS.md).
- [Reglas](docs/REGLAS.md), [competición](docs/COMPETICION.md) y [temporadas](docs/TEMPORADAS-CONTRATOS.md).
- [Jugadores](docs/PLANTILLAS-REALES.md), [calidad](docs/CALIDAD-EQUIPOS.md) y [cantera](docs/CANTERA.md).
- [Entrenamiento](docs/ENTRENAMIENTO.md), [lesiones](docs/LESIONES.md) y [moral](docs/MORAL.md).
- [Fichajes](docs/FICHAJES.md), [finanzas](docs/FINANZAS.md) y [salarios](docs/SALARIOS-PRESUPUESTO.md).
- [API](docs/openapi.json): regenerar con `python scripts/generate_openapi.py`.
