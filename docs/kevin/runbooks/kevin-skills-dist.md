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

## Install into Kevin skills root (interim — until `kevin` CLI)

Default root: **`~/.kevin/skills`** (override with `KEVIN_SKILLS_ROOT`).

```bash
# From published release
./tools/install-kevin-skills.sh --from-url

# From a local pack
./tools/install-kevin-skills.sh --from-file dist/kevin-skills/kevin-skills.tar.gz

# Custom root
KEVIN_SKILLS_ROOT=/tmp/kevin-skills-test ./tools/install-kevin-skills.sh --from-file dist/kevin-skills/kevin-skills.tar.gz
```

Install is a **copy**, not a symlink into a clone. Verify: `cat $KEVIN_SKILLS_ROOT/.agent-tools-revision`.

Profile `kevin` must set `external_dirs` to this root (AGNT-12 CLI; until then operators may point profile at `~/.kevin/skills` manually after install).

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
