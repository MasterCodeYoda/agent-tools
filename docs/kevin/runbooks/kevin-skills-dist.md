# Runbook: Kevin skills dist artifact

**Status:** Active — AGNT-13  
**Decisions:** [ADR-004](../decisions/004-workstation-cli-and-skills-distribution.md)  
**Package SoT:** monorepo `src/` → `tools/publish-skills.sh --agents hermes` → pack

## Intent

Workstation Kevin installs process skills from a **published tarball**, not by cloning this monorepo and not via multi-agent `./setup.sh` → `~/.hermes/skills`.

Isolated Kevin continues to bake the same `dist/hermes` family into the image (`/opt/kevin/skills`).

## Stable download URL

```text
https://github.com/MasterCodeYoda/agent-tools/releases/download/kevin-skills/kevin-skills.tar.gz
```

Also published:

| Asset | Role |
|-------|------|
| `kevin-skills.tar.gz` | Package root `kevin-skills/` |
| `kevin-skills.sha256` | Integrity |
| `manifest.json` | `git_sha`, `created_at`, `skill_count` |

Channel: **rolling** GitHub Release tag `kevin-skills` (updated on each `main` pack). Public repo → anonymous download.

## Package layout

```text
kevin-skills/
  skills/                   # dist/hermes/skills contents
  .agent-tools-revision     # agent-tools-rev, installed-at, publish-agent=hermes
  manifest.json
```

## Local pack (maintainers)

```bash
# From agent-tools checkout
./tools/pack-kevin-skills.sh
# → dist/kevin-skills/kevin-skills.tar.gz
```

`--no-publish` reuses an existing `dist/hermes/skills` tree.

## Install into Kevin skills root

Default root: **`~/.kevin/skills`** (override with `KEVIN_SKILLS_ROOT`).

**Preferred (product CLI):**

```bash
kevin setup
# or: kevin setup --from-file dist/kevin-skills/kevin-skills.tar.gz
```

**Direct installer (maintainer / library used by CLI):**

```bash
./tools/install-kevin-skills.sh --from-url
./tools/install-kevin-skills.sh --from-file dist/kevin-skills/kevin-skills.tar.gz
KEVIN_SKILLS_ROOT=/tmp/kevin-skills-test ./tools/install-kevin-skills.sh --from-file dist/kevin-skills/kevin-skills.tar.gz
```

Install is a **copy**, not a symlink into a clone. Verify: `cat $KEVIN_SKILLS_ROOT/.agent-tools-revision`.

Profile `kevin` must set `external_dirs` to this root (`kevin setup` does this).

## CI

Workflow: [`.github/workflows/kevin-skills-dist.yml`](../../../.github/workflows/kevin-skills-dist.yml)

- Trigger: push to `main`, `workflow_dispatch`
- Job: publish hermes → pack → upsert release `kevin-skills`

## What not to use for Kevin product path

| Path | Role |
|------|------|
| `./setup.sh` → `~/.hermes/skills` | Multi-agent / maintainer dogfood only — **not** Kevin consumer path |
| Clone agent-tools + symlink dist | Rejected (ADR-004) |
| Docker-only skills | Isolated mode only |

## Related

- [ADR-004](../decisions/004-workstation-cli-and-skills-distribution.md)  
- AGNT-12 workstation CLI (consumes this artifact)  
- [kevin-hermes Docker](./kevin-hermes-docker.md) (Isolated bake of same dist family)  
