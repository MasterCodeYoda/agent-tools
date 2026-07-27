# kevin-hermes Docker pack

Image **`kevin-hermes`**, process skills from hermes **render dialect** (`dist/hermes`) stamped **product=kevin** at build (ADR-005).

## Dev (this monorepo)

Always build from the agent-tools checkout:

```bash
cd /path/to/agent-tools
./hermes/dev.sh -p /path/to/product-repo   # build + up
./hermes/dev.sh up --no-build              # reuse last local image
./hermes/dev.sh logs
./hermes/dev.sh status
./hermes/dev.sh down
```

Script: [`../dev.sh`](../dev.sh)

## CI / distribution

On green `main`, GitHub Actions builds multi-arch images and pushes:

- `ghcr.io/mastercodeyoda/kevin-hermes:main`
- `ghcr.io/mastercodeyoda/kevin-hermes:sha-<short>`

Client install (PATH `kevin`, pull + run without a full agent-tools checkout) is **not** implemented yet.

## Volumes

| Host | Container | Role |
|------|-----------|------|
| `KEVIN_HERMES_DATA` | `/opt/data` | Secrets, sessions, installed profile |
| `KEVIN_PROJECT_ROOT` | `/workspace` | Product git tree (operator reviews here) |

Skills are **in the image** at `/opt/kevin/skills` (not a host bind).

## Secrets

Fill live values under the data volume after first start (e.g. profile `.env`). Names only in `hermes/profile/.env.template`. Never commit tokens.

## Related

- Runbook: [docs/kevin/runbooks/kevin-hermes-docker.md](../../docs/kevin/runbooks/kevin-hermes-docker.md)
- Versioning: [docs/kevin/decisions/002-kevin-hermes-image-versioning.md](../../docs/kevin/decisions/002-kevin-hermes-image-versioning.md)
