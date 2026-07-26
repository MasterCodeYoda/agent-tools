# kevin-hermes Docker pack

Primary Kevin instance: image **`kevin-hermes`**, process skills from **`dist/hermes`** (baked at build).

## Quick start (preferred)

From the **agent-tools** repo (or any product repo with `--project`):

```bash
# Build local image and start, mounting a product repo
./hermes/kevin.sh --build -p /path/to/product-repo

# Or from inside a product git checkout (mounts cwd)
./hermes/kevin.sh --build

# Pull GHCR :main and start
./hermes/kevin.sh pull -p /path/to/product-repo

./hermes/kevin.sh logs
./hermes/kevin.sh status
./hermes/kevin.sh down
```

Script path: [`../kevin.sh`](../kevin.sh)

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
