# kevin-hermes Docker pack

Primary Kevin instance: image **`kevin-hermes`**, process skills from **`dist/hermes`** (baked at build).

## Quick start (local build)

```bash
cd /path/to/agent-tools
docker build -f hermes/docker/Dockerfile -t kevin-hermes:local .

export KEVIN_PROJECT_ROOT=/path/to/your/product-repo
export KEVIN_HERMES_DATA=$HOME/.kevin/hermes-data
export KEVIN_HERMES_IMAGE=kevin-hermes:local
mkdir -p "$KEVIN_HERMES_DATA"

docker compose -f hermes/docker/compose.yaml up -d
docker logs -f kevin-hermes
```

## GHCR (after main CI)

```bash
export KEVIN_HERMES_IMAGE=ghcr.io/mastercodeyoda/kevin-hermes:main
docker compose -f hermes/docker/compose.yaml pull
docker compose -f hermes/docker/compose.yaml up -d
```

## Volumes

| Host | Container | Role |
|------|-----------|------|
| `KEVIN_HERMES_DATA` | `/opt/data` | Secrets, sessions, installed profile |
| `KEVIN_PROJECT_ROOT` | `/workspace` | Product git tree (operator reviews here) |

Skills are **in the image** at `/opt/kevin/skills` (not a host bind). Update skills by pulling a new image and recreating the container.

## Secrets

Fill live values under the data volume after first start (e.g. profile `.env` for API keys / Slack). Names only in `hermes/profile/.env.template`. Never commit tokens.

## Related

- Runbook: [docs/kevin/runbooks/kevin-hermes-docker.md](../../docs/kevin/runbooks/kevin-hermes-docker.md)
- Versioning: [docs/kevin/decisions/002-kevin-hermes-image-versioning.md](../../docs/kevin/decisions/002-kevin-hermes-image-versioning.md)
