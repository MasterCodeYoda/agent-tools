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
# Operator force:
jarvis-host update --yes
# CoS path: Jarvis notifies in Slack → reply "yes" → host poll enacts
sudo jarvis-host schedule status
```

### Systemd timers (system scope)

| Unit | Role |
|------|------|
| `jarvis-backup-state.timer` | Nightly adaptive-state git backup |
| `jarvis-update-check.timer` | Hourly image check → `state/ops/update-status.json` |
| `jarvis-update-poll.timer` | Every 5m: valid `update-request.json` → enact |

---

## Update approve protocol

On volume (`profiles/jarvis/state/ops/`):

| File | Writer |
|------|--------|
| `update-status.json` | Host check |
| `update-request.json` | Jarvis on user approve |
| `update-result.json` | Host after enact |

No Docker socket in the chat container.

---

## Related

- [jarvis-state-backup.md](./jarvis-state-backup.md) — backup allowlist doctrine  
- [jarvis-hermes-docker.md](./jarvis-hermes-docker.md) — runtime topology  
- [multi-agent-config-lanes.md](./multi-agent-config-lanes.md) — lanes  
