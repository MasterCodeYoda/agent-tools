# Runbook: kevin-hermes Docker primary (path of record)

**Status:** Active — KEVN-11  
**Image:** `ghcr.io/mastercodeyoda/kevin-hermes` (or local build)  
**Profile:** `kevin` only  
**Process skills:** baked **`dist/hermes`** at image build (never raw `src/`)  
**Versioning:** [ADR-002](../decisions/002-kevin-hermes-image-versioning.md) — `:main` + `:sha-…`; no GH Releases for now  

## Intent

Kevin’s **primary instance** is this container. Laptop Hermes + `setup.sh` remains for Claude/Grok/etc. and optional host dogfood — **not** the long-lived factory host path of record.

## Ordered bring-up

| Step | Action | Pass |
|------|--------|------|
| 1 | Docker Desktop (or Linux engine) running | `docker info` |
| 2 | Clone **agent-tools** (optional if only pulling image) | repo present for local build |
| 3 | Set `KEVIN_PROJECT_ROOT` to product repo absolute path | path exists, is git |
| 4 | Set `KEVIN_HERMES_DATA` (default `~/.kevin/hermes-data`) | dir creatable |
| 5 | `docker compose -f hermes/docker/compose.yaml pull` **or** local `docker build` | image present |
| 6 | `docker compose -f hermes/docker/compose.yaml up -d` | container running |
| 7 | `docker logs kevin-hermes` shows profile/skills OK | no crash loop |
| 8 | Secrets in data volume (API keys / Slack as needed) | model or gateway ready |
| 9 | Smoke: write under `/workspace` → host `git status` dirty | project bind works |

```bash
cd /path/to/agent-tools   # if using compose from repo

export KEVIN_PROJECT_ROOT=/path/to/product-repo
export KEVIN_HERMES_DATA=$HOME/.kevin/hermes-data
# export KEVIN_HERMES_IMAGE=kevin-hermes:local   # after local build

mkdir -p "$KEVIN_HERMES_DATA"
docker compose -f hermes/docker/compose.yaml up -d
```

### Local image build

```bash
cd /path/to/agent-tools
docker build -f hermes/docker/Dockerfile -t kevin-hermes:local .
export KEVIN_HERMES_IMAGE=kevin-hermes:local
```

## Update

```bash
docker compose -f hermes/docker/compose.yaml pull
docker compose -f hermes/docker/compose.yaml up -d
```

New process skills = **new image** (green `main` rebuild). No silent git pull of agent-tools inside the running gateway.

## Hard vs soft

| Class | Examples |
|-------|----------|
| **Hard** | Docker engine; image pull/build; `KEVIN_PROJECT_ROOT` set; container stays up; baked skills present |
| **Soft** | Model API keys; Slack tokens; channel binding placeholder |

## Slack

Packaging: [packs/](../packs/). Tokens only in volume-backed profile `.env`. Live smoke residual OK without tokens. Gateway runs **in this container**.

## Failure matrix

| Symptom | Likely cause | Recovery |
|---------|--------------|----------|
| Crash loop | entrypoint/profile install fail | `docker logs kevin-hermes`; check data volume perms (`HERMES_UID`/`GID`) |
| Skills empty | bad image build | rebuild; confirm publish stage |
| Writes not on host | wrong `KEVIN_PROJECT_ROOT` | fix path; recreate |
| Wrong profile | not using this image / old host gateway | stop host gateway; use compose service only |

## Out of scope here

- git-cliff / semver GitHub Releases (ADR-002 later)  
- DinD terminal backend  
- Deleting software-factory (see [MIGRATION.md](../MIGRATION.md))  

## Related

- [hermes/docker/README.md](../../../hermes/docker/README.md)  
- [ADR-001](../decisions/001-hermes-provisional-factory-host.md)  
- [ADR-002](../decisions/002-kevin-hermes-image-versioning.md)  
