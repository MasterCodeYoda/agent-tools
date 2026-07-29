# Runbook: jarvis-host (durable host ops kit)

**Status:** Active (path of record for operators)  
**Kit prefix:** `/opt/jarvis-host`  
**Runtime image:** `ghcr.io/mastercodeyoda/jarvis-hermes`  
**Release tag:** `jarvis-host` (rolling GitHub Release)

Monorepo scripts under `hermes/scripts/jarvis-*.sh` remain for **developers**. Operators should use this kit.

---

## Install (greenfield)

```bash
curl -fsSL https://github.com/MasterCodeYoda/agent-tools/releases/download/jarvis-host/install.sh | sudo bash
# secrets dir contains .env + auth.json (never commit)
sudo jarvis-host setup --from-secrets-dir /secure/jarvis-secrets
```

If GHCR package is private:

```bash
echo "$GHCR_TOKEN" | docker login ghcr.io -u USER --password-stdin
```

---

## Existing durable host (one-shot)

```bash
# After kit install (or from unpacked release)
sudo /opt/jarvis-host/migrate-from-legacy.sh
# Never re-runs secrets wizard; never deletes volume data
```

Throwaway after all hosts migrated.

---

## Day-2 ops

```bash
jarvis-host status
jarvis-host backup --init    # once
jarvis-host backup
jarvis-host update --check
# Operator force apply:
jarvis-host update --yes
# CoS path (normal):
#   !update in Slack → host checks within ~1m → Jarvis reports
#   if available → you yes → host applies within ~1m
sudo jarvis-host schedule status
```

### Systemd timers (system scope)

| Unit | Role |
|------|------|
| `jarvis-backup-state.timer` | Nightly adaptive-state git backup |
| `jarvis-update-check.timer` | Every **20m**: image check → `state/ops/update-status.json` |
| `jarvis-update-poll.timer` | Every **1m**: honor `!update` check-request + apply `update-request` |

---

## Update protocol (product UX)

```text
!update (or 20m timer) → host check → status.json
Jarvis tells you if available
you: yes → request.json
host poll (~1m) → pull + recreate → result.json
Jarvis reports result
```

On volume (`profiles/jarvis/state/ops/`):

| File | Writer |
|------|--------|
| `update-status.json` | Host check |
| `update-check-request.json` | Jarvis on **`!update`** (check now) |
| `update-request.json` | Jarvis on user **apply** approve |
| `update-result.json` | Host after enact |

No Docker socket in the chat container.

After kit upgrade on a host already migrated: `sudo jarvis-host schedule install` to refresh timer intervals.

---

## Related

- [jarvis-state-backup.md](./jarvis-state-backup.md) — backup allowlist doctrine  
- [jarvis-hermes-docker.md](./jarvis-hermes-docker.md) — runtime topology  
- [multi-agent-config-lanes.md](./multi-agent-config-lanes.md) — lanes  
