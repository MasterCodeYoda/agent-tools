# Runbook: kevin-hermes Docker primary (path of record)

**Status:** Active — AGNT-11  
**Image:** `ghcr.io/mastercodeyoda/kevin-hermes` (or local build)  
**Profile:** `kevin` only  
**Process skills:** baked **`dist/hermes`** at image build (never raw `src/`)  
**Versioning:** [ADR-002](../decisions/002-kevin-hermes-image-versioning.md) — `:main` + `:sha-…`; no GH Releases for now  

## Intent

Kevin’s **primary instance** is this container. Laptop Hermes + `setup.sh` remains for Claude/Grok/etc. and optional host dogfood — **not** the long-lived factory host path of record.

## Ordered bring-up (script)

Prefer **`hermes/kevin.sh`** (Docker Desktop, Linux, WSL, Git Bash):

| Step | Action | Pass |
|------|--------|------|
| 1 | Docker engine running | `docker info` |
| 2 | Clone **agent-tools** | `./hermes/kevin.sh` works |
| 3 | Start with product repo | container `kevin-hermes` up |
| 4 | Logs show gateway | `./hermes/kevin.sh logs` |
| 5 | Secrets in data volume as needed | model / Slack when required |
| 6 | Smoke: write under mount → host `git status` | bind works |

```bash
cd /path/to/agent-tools

# Local build + start (mount product repo)
./hermes/kevin.sh --build -p /path/to/product-repo

# Or pull GHCR :main + start
./hermes/kevin.sh pull -p /path/to/product-repo

./hermes/kevin.sh logs
./hermes/kevin.sh status
./hermes/kevin.sh down
```

If cwd is already a product git repo, omit `-p` and the script mounts the current directory.

## Update

```bash
./hermes/kevin.sh pull -p /path/to/product-repo
# or rebuild local:
./hermes/kevin.sh --build -p /path/to/product-repo
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
