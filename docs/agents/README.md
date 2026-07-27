# Agents — product orientation (Kevin + Jarvis)

Hermes-hosted **product agents** packaged from this monorepo. Process skills SoT remains `src/` → publish; this tree is product narrative, ADRs, runbooks, and evidence.

| Agent | Role | Hermes profile | Topology |
|-------|------|----------------|----------|
| **Kevin** | Software factory coding agent | `kevin` | Workstation **and** Isolated (`kevin-hermes`) — dual OK |
| **Jarvis** | Personal chief of staff | `jarvis` | **Single remote** only (`jarvis-hermes` + one data volume) |

**Shared doctrine (config lanes, secrets vs policy, pack isolation):**  
[runbooks/multi-agent-config-lanes.md](./runbooks/multi-agent-config-lanes.md)

> **Layout note (2026-07-27):** This directory was formerly `docs/kevin/`. Renamed to `docs/agents/` when Jarvis landed as a second product identity. Historical “Kevin” filenames under runbooks/decisions remain valid product names.

## Kevin — start here

| What | Where |
|------|--------|
| **Modes + decisions** | [decisions/](./decisions/) — especially 003, 004, 005 |
| **Workstation CLI** | [runbooks/kevin-workstation-cli.md](./runbooks/kevin-workstation-cli.md) · [skills dist](./runbooks/kevin-skills-dist.md) |
| **Isolated / packaging** | [runbooks/kevin-hermes-docker.md](./runbooks/kevin-hermes-docker.md) · [`hermes/dev.sh`](../../hermes/dev.sh) |
| **Linear** | Team **Agent Tools** (`AGNT`) — [LINEAR.md](./LINEAR.md) |
| **software-factory migration** | [MIGRATION.md](./MIGRATION.md) |

### Kevin modes

| Mode | What | Entry |
|------|------|--------|
| **Workstation Kevin** | Coding agent on your machine; host Hermes + Kevin skills | **`kevin` CLI** (ADR-004); dogfood path of record |
| **Isolated Kevin** | Container `kevin-hermes`; sandbox/remote | Image + `hermes/dev.sh` for packaging |

Permanent options, not a migration ladder — [ADR-003](./decisions/003-workstation-vs-isolated-kevin.md).

## Jarvis — start here

| What | Where |
|------|--------|
| **Docker / single remote** | [runbooks/jarvis-hermes-docker.md](./runbooks/jarvis-hermes-docker.md) |
| **Capabilities / secrets** | [runbooks/jarvis-capabilities.md](./runbooks/jarvis-capabilities.md) |
| **Slack CoS chat** | [runbooks/jarvis-slack.md](./runbooks/jarvis-slack.md) |
| **Profile dist** | [`hermes/jarvis-profile/`](../../hermes/jarvis-profile/) |
| **Full setup** | [`hermes/scripts/jarvis-setup.sh`](../../hermes/scripts/jarvis-setup.sh) — interactive on host, or `--from-env-file` |
| **Lab → durable promote** | [`hermes/scripts/jarvis-promote.sh`](../../hermes/scripts/jarvis-promote.sh) — copy `.env`, inject, backup cron |
| **Local smoke** | [`hermes/scripts/jarvis-local-smoke.sh`](../../hermes/scripts/jarvis-local-smoke.sh) |
| **State backup** | [runbooks/jarvis-state-backup.md](./runbooks/jarvis-state-backup.md) |

## Layout

```text
docs/agents/     multi-agent product docs (this tree)
  decisions/     ADRs (Kevin-origin; ADR-005 covers product × dialect for both)
  runbooks/      Kevin + Jarvis + shared lanes
  packs/         manifests / env examples
  memory/        durable project memory entries
  research/      host/product research
hermes/
  profile/           kevin distribution
  jarvis-profile/    jarvis distribution
  docker/            both images
  scripts/           apply / bring-up / digest helpers
```

## Language

- Prefer **workstation / isolated** for Kevin; **single remote** for Jarvis.
- Do **not** use “plant” or “Track A/B” in product docs.
- Config changes: name the **lane** (policy / secrets / adaptive state) — see multi-agent-config-lanes.
