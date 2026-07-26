---
name: kevin-hermes-process-pack-setup
description: Process skills for Kevin via agent-tools hermes target → ~/.hermes/skills (not factory)
type: pattern
applicability: project
related:
  - ~/Source/OMG/agent-tools/setup.sh
  - hermes/README.md
  - r-20260724-2
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin process pack via hermes publish agent

## Why

Kevin must not use agent-tools publish agent **`factory`** (Factory coding agent → `~/.factory`).
Hermes host skills install under **`~/.hermes/skills`** with the same symlink + `.agent-tools` marker model as Claude/Grok.

## How to apply

1. `cd agent-tools && ./setup.sh` when `~/.hermes` exists → installs managed skills; writes `.agent-tools-revision`.
2. Profile **kevin** `external_dirs` → that path (`apply-kevin-profile.sh`).
3. Update ritual: pull agent-tools + `./setup.sh`. No silent pull on Hermes start/cron.
4. `software-factory/scripts/export-process-pack.sh` is **secondary** only (prefers `--agents hermes`).

## Gotchas

- Prune only removes **managed** entries; Hermes hub trees (apple, media, …) stay alongside.
- `agent:include factory` markup still means Factory coding agent quirks — not Hermes/Kevin. Hermes publish does not receive those blocks.
