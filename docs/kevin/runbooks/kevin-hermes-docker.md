# Runbook: kevin-hermes Docker primary (path of record)

**Status:** Active — AGNT-11  
**Image:** `ghcr.io/mastercodeyoda/kevin-hermes` (CI) · `kevin-hermes:local` (dev)  
**Profile:** `kevin` only  
**Process skills:** baked **`dist/hermes`** at image build (never raw `src/`)  
**Versioning:** [ADR-002](../decisions/002-kevin-hermes-image-versioning.md) — `:main` + `:sha-…`; no GH Releases for now  

## Intent

Kevin’s **primary instance** is a Docker container. Two different workflows:

| Workflow | Tool | Image source |
|----------|------|----------------|
| **Develop packaging** (this repo) | [`hermes/dev.sh`](../../../hermes/dev.sh) | Always build from local agent-tools checkout |
| **Run published Kevin** (any machine) | Client install / PATH CLI | GHCR `:main` — **not shipped yet** |

Laptop Hermes + `setup.sh` remains for Claude/Grok/etc. and optional host dogfood.

## Dev bring-up (`dev.sh`)

From an **agent-tools** checkout (Docker Desktop, Linux, WSL, Git Bash):

| Step | Action | Pass |
|------|--------|------|
| 1 | Docker engine running | `docker info` |
| 2 | Clone **agent-tools** | `./hermes/dev.sh help` works |
| 3 | Build + start with product repo mount | container `kevin-hermes` up |
| 4 | Logs show gateway | `./hermes/dev.sh logs` |
| 5 | Secrets in data volume as needed | model / Slack when required |
| 6 | Smoke: write under mount → host `git status` | bind works |

```bash
cd /path/to/agent-tools

# Always builds kevin-hermes:local from this tree, then up
./hermes/dev.sh -p /path/to/product-repo

# Tight loop: reuse last local image
./hermes/dev.sh up --no-build -p /path/to/product-repo

./hermes/dev.sh logs
./hermes/dev.sh status
./hermes/dev.sh down
```

If cwd is already a product git repo, omit `-p` and the script mounts the current directory.

## Published image (CI)

Green `main` publishes multi-arch:

```text
ghcr.io/mastercodeyoda/kevin-hermes:main
ghcr.io/mastercodeyoda/kevin-hermes:sha-<short>
```

Client install (install CLI on PATH, pull + run without cloning agent-tools) is **deferred** — separate from `dev.sh`.

## Hard vs soft

| Class | Examples |
|-------|----------|
| **Hard** | Docker engine; local build succeeds; `KEVIN_PROJECT_ROOT` set; container stays up; baked skills present |
| **Soft** | Model API keys; Slack tokens; channel binding placeholder |

## Slack

Packaging: [packs/](../packs/). Tokens only in volume-backed profile `.env`. Live smoke residual OK without tokens. Gateway runs **in the container**.

## Failure matrix

| Symptom | Likely cause | Recovery |
|---------|--------------|----------|
| Crash loop | entrypoint/profile install fail | `./hermes/dev.sh logs`; check data volume perms (`HERMES_UID`/`GID`) |
| Skills empty | bad image build | `./hermes/dev.sh build` and check publish stage |
| Writes not on host | wrong project path | fix `-p` / `KEVIN_PROJECT_ROOT`; restart |
| Stale packaging | used `--no-build` too long | drop `--no-build` so image rebuilds from checkout |

## Out of scope here

- Client PATH `kevin` install / GHCR-only bring-up (future)  
- git-cliff / semver GitHub Releases (ADR-002 later)  
- DinD terminal backend  

## Related

- [hermes/dev.sh](../../../hermes/dev.sh)  
- [hermes/docker/README.md](../../../hermes/docker/README.md)  
- [ADR-001](../decisions/001-hermes-provisional-factory-host.md)  
- [ADR-002](../decisions/002-kevin-hermes-image-versioning.md)  
