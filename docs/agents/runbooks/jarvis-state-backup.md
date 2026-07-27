# Runbook: Jarvis adaptive-state backup (private git)

**Status:** Active — **required** for full-fidelity setup (`jarvis-setup.sh`)  
**Not optional** on durable/production hosts. Local packaging smoke may skip.  
**Doctrine:** [multi-agent-config-lanes.md](./multi-agent-config-lanes.md)  
**Scripts:** `hermes/scripts/jarvis-backup-state.sh` · `jarvis-restore-state.sh` · `jarvis-install-backup-cron.sh` · `jarvis-setup.sh`

---

## Why

Jarvis’s single remote volume holds **adaptive text** (digests, tracking notes, CoS continuity) that is **not** in agent-tools and is **not** secrets. Losing the volume loses that continuity.

Nightly **allowlisted** commit+push to a **private** git repo gives:

1. Disaster recovery of adaptive state (not policy, not secrets)  
2. Human-readable history  
3. **Input to agent-tools skill evolution** — digests and tracking notes become process/skill signals without treating the backup repo as skill SoT  

Policy remains `hermes/jarvis-profile/` in agent-tools. Skills remain `src/` → publish.

---

## Allowlist / denylist

| Include | Exclude (hard) |
|---------|----------------|
| `profiles/jarvis/state/**` text files (`.md`, `.txt`, `.json`, `.yml`, `.yaml`, `.csv`) | `.env`, `auth.json` |
| `BACKUP_MANIFEST.md` | `sessions/**` |
| | `*.db*` / SQLite |
| | logs, caches, locks, pid |
| | Live `config.yaml` / SOUL as SoT (policy stays agent-tools) |

---

## Secrets (capability spine)

Collected by `jarvis-secrets-wizard.sh --require-backup` during **`jarvis-setup.sh`**:

| Name | Purpose |
|------|---------|
| `JARVIS_BACKUP_REPO` | Private repo URL (`https://github.com/org/jarvis-state.git`) |
| `JARVIS_BACKUP_GITHUB_TOKEN` | **Fine-grained PAT** — `contents: write` to **that repo only** |
| `JARVIS_BACKUP_BRANCH` | Default `main` |

Create the empty private repo on GitHub first. Prefer fine-grained over classic PAT.  
Token is stored on the Jarvis volume `.env` (secrets lane) and read by the **host** backup script via a one-shot volume mount — not logged, not committed.

**Do not** grant this PAT read on OMG org repos. CoS repo familiarity uses a **separate**
`JARVIS_GITHUB_READ_TOKEN` (see [jarvis-capabilities.md](./jarvis-capabilities.md)).

---

## Full setup (installs cron)

```bash
cd /path/to/agent-tools
./hermes/scripts/jarvis-setup.sh
```

This **always** (unless emergency `--skip-cron`):

1. Bring-up container + volume  
2. Secrets wizard with **required** backup repo + GitHub token  
3. `jarvis-backup-state.sh --init` + first backup  
4. `jarvis-install-backup-cron.sh` — nightly host cron (default `15 3 * * *`)

Verify:

```bash
./hermes/scripts/jarvis-setup.sh --check
crontab -l | grep jarvis-backup
./hermes/scripts/jarvis-backup-state.sh --dry-run
```

---

## Manual ops

```bash
# On demand
./hermes/scripts/jarvis-backup-state.sh

# Restore adaptive state into volume (after clone/pull of backup repo)
./hermes/scripts/jarvis-restore-state.sh --dry-run
./hermes/scripts/jarvis-restore-state.sh
docker restart jarvis-hermes
```

---

## Agent-tools / skill evolution

| Layer | Role |
|-------|------|
| **Backup repo `state/`** | Observation stream: digests, what CoS is tracking — **inputs** to evolve/import judgment |
| **agent-tools `src/`** | Skill SoT after human/process promotion |
| **Do not** | Auto-merge backup prose into skills without evolve/import review |

Document in evolve seeds when digests reveal recurring process gaps.

---

## Portainer / remote host notes

- Run `jarvis-setup.sh` (or install cron) on the **Docker host** that owns the volume.  
- Cron user needs `docker` + `git` + network to GitHub.  
- Named volume default: `jarvis-hermes-data`.  
- Host worktree default: `~/.jarvis/backup-repo` (not inside the chat container).  
