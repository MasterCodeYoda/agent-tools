# Kevin — orientation

**Product agent:** Kevin · **Hermes profile:** `kevin` · **Process SoT:** this monorepo (`src/` → `dist/hermes`)

## Modes (read first)

| Mode | What | Entry |
|------|------|--------|
| **Workstation Kevin** | Coding agent on your machine; **one git repo** as session home; host Hermes + Kevin-managed skills | **`kevin` CLI** (foundational — see ADR-004); dogfood path of record for capability |
| **Isolated Kevin** | Container image `kevin-hermes`; clean-room baseline; sandbox/remote | Image + `hermes/dev.sh` for packaging; full provision DX later |

These modes are **permanent options**, not a migration ladder. See [ADR-003](./decisions/003-workstation-vs-isolated-kevin.md).

## Start here

| What | Where |
|------|--------|
| **Modes + decisions** | [decisions/](./decisions/) — especially 003, 004 |
| **Workstation distribution** | [ADR-004](./decisions/004-workstation-cli-and-skills-distribution.md) · [skills dist runbook](./runbooks/kevin-skills-dist.md) · CLI (AGNT-12) |
| **Isolated / packaging** | [runbooks/kevin-hermes-docker.md](./runbooks/kevin-hermes-docker.md) · [`hermes/dev.sh`](../../hermes/dev.sh) |
| **Linear** | Team **Agent Tools** (`AGNT`) — [LINEAR.md](./LINEAR.md) |
| **software-factory repo** | Retired — [MIGRATION.md](./MIGRATION.md) |

## Layout

```text
docs/kevin/     narrative + ADRs + runbooks
hermes/
  dev.sh        build kevin-hermes:local from this checkout (packaging)
  docker/       image + compose
  profile/      kevin profile distribution
  scripts/      host helpers (secondary)
```

## Language

Do **not** use “plant” or “Track A/B” in product docs. Prefer workstation / isolated, project repo, Kevin skills root.
