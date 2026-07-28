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

## Why host schedule (not in the container)

Backup is **host ops**, not a Hermes ritual. Do **not** bake `crond` into `jarvis-hermes` or register this as Hermes cron.

| Concern | Host schedule | In-container cron |
|---------|---------------|-------------------|
| Write PAT (`JARVIS_BACKUP_GITHUB_TOKEN`) | Stays on host; never in agent tool plane | PAT next to model/gateway surface |
| DR when gateway is down | Still runs (docker CLI + volume mount) | Dies with the chat container |
| Git worktree | `~/.jarvis/backup-repo` on host | Would mix clone history into volume or need extra mounts |
| Docker API | Host already has docker + volume ownership | Needs socket mount or privileged access |

**Morning brief** is different — that **is** Hermes/gateway cron inside the durable instance (product behavior). See [jarvis-hermes-docker.md](./jarvis-hermes-docker.md).

### Preferred scheduler: **systemd system timer**

Path of record on durable / headless hosts (Portainer, skynet, Ubuntu 24.04 minimal with **no** `crontab`):

| Scope | When | Reboot without login |
|-------|------|----------------------|
| **`systemd` system timer** (`/etc/systemd/system/`) | **Default / production** | **Yes** — fires as the configured docker user |
| systemd user timer (`~/.config/systemd/user/`) | Workstations only (`--user`) | **No**, unless linger — and linger also needs root, so prefer system units |
| cron | Only if `systemctl` unavailable | Yes if system cron / user crontab on always-up session |

Default fire time: **03:15 local** (`OnCalendar=*-*-* 03:15:00`).

**Do not** install a user timer on a headless host and call linger a follow-up. That still needs root once and is a worse shape than system units. Install system units in that one privileged step:

```bash
sudo ./hermes/scripts/jarvis-install-backup-cron.sh --system
```

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

## Full setup (installs host schedule)

```bash
cd /path/to/agent-tools
./hermes/scripts/jarvis-setup.sh
```

This **always** (unless emergency `--skip-cron`):

1. Bring-up container + volume  
2. Secrets wizard with **required** backup repo + GitHub token  
3. `jarvis-backup-state.sh --init` + first backup  
4. `jarvis-install-backup-cron.sh` — nightly host schedule (auto: **systemd timer**, else cron)

### Install / verify schedule only

```bash
# Path of record — system timer (needs root once; runs backup as SUDO_USER)
sudo ./hermes/scripts/jarvis-install-backup-cron.sh --system

# Same intent without flags (defaults to system scope; re-execs under sudo if passwordless)
./hermes/scripts/jarvis-install-backup-cron.sh

# Workstation opt-in only (refuses if Linger≠yes)
./hermes/scripts/jarvis-install-backup-cron.sh --user

# Cron only (legacy / no systemd)
./hermes/scripts/jarvis-install-backup-cron.sh --backend cron --system   # or --user

# Status + smoke (system scope; start needs root for system units)
./hermes/scripts/jarvis-install-backup-cron.sh --status
sudo systemctl start jarvis-backup-state.service
journalctl -u jarvis-backup-state.service -n 40 --no-pager
systemctl list-timers --all | grep jarvis
./hermes/scripts/jarvis-setup.sh --check
```

If smoke fails with `Could not resolve host: github.com`, that is usually **transient DNS** (network-online does not guarantee name resolution). Re-run the start once DNS works (`getent hosts github.com`). The backup script retries push; the unit has an `ExecStartPre` DNS wait. Nightly timer still fires without login once installed.


Optional schedule knobs:

| Flag / env | Meaning |
|------------|---------|
| `--system` / `--user` | Scope (default **system**) |
| `--on-calendar '*-*-* 03:15:00'` | systemd `OnCalendar` |
| `--schedule '15 3 * * *'` | cron line; also derived into OnCalendar when simple daily |
| `JARVIS_BACKUP_SCHEDULE_BACKEND` | `auto` \| `systemd` \| `cron` |
| `JARVIS_BACKUP_SCHEDULE_SCOPE` | `system` \| `user` |
| `JARVIS_BACKUP_RUN_AS` | docker-capable user when installing as root without `SUDO_USER` |
| `JARVIS_BACKUP_ON_CALENDAR` / `JARVIS_BACKUP_CRON_SCHEDULE` | defaults for install |

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

- Run `jarvis-setup.sh` (or install schedule) on the **Docker host** that owns the volume.  
- Schedule user needs `docker` + `git` + network to GitHub.  
- Named volume default: `jarvis-hermes-data`.  
- Host worktree default: `~/.jarvis/backup-repo` (not inside the chat container).  
- **skynet / Ubuntu 24.04:** often **no** `crontab` binary — use systemd timer (default). Do not assume `apt install cron` is required.  
- Compose on some hosts is standalone `docker-compose`, not the `docker compose` plugin — unrelated to backup, but same durable host.  

### skynet-shaped durable install (path of record)

skynet is **headless** — no one logs in after reboot. Use a **system** timer, not a user timer + linger.

```bash
ssh skynet-server
cd ~/Source/OMG/agent-tools   # main (or scp’d scripts until landed)
sudo ./hermes/scripts/jarvis-install-backup-cron.sh --system
# installs /etc/systemd/system/jarvis-backup-state.{service,timer}
# runs as the sudo-invoking user (moverlund); removes any prior user-scope units
sudo systemctl start jarvis-backup-state.service
journalctl -u jarvis-backup-state.service -n 40 --no-pager
./hermes/scripts/jarvis-install-backup-cron.sh --status
```

Units: `/etc/systemd/system/jarvis-backup-state.{service,timer}` · `User=` / `Group=` = docker-capable operator.

**Anti-pattern (do not repeat):** installing a user timer because passwordless sudo was unavailable, then treating `enable-linger` as a follow-up. That still needs root and does not fire without login until linger is set — system units are the same privilege cost with correct semantics.

### Export stage ownership

`jarvis-backup-state.sh` runs the export container as the host uid (`-u $(id -u):$(id -g)`) so temp stage cleanup does not fail under `set -e` (older root-owned stage trees caused a false FAILED unit after a successful push).
