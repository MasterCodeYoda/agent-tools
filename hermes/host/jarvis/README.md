# jarvis-host

Durable **host ops kit** for Jarvis CoS. Does **not** require cloning agent-tools on the server.

| Path | Role |
|------|------|
| `/opt/jarvis-host` | Installed kit (this tree) |
| `/var/lib/jarvis-host` | Non-secret host prefs |
| Docker volume `jarvis-hermes-data` | Secrets + adaptive state + ops JSON |

## Install (greenfield)

```bash
# After CI publishes rolling release tag `jarvis-host`:
curl -fsSL https://github.com/MasterCodeYoda/agent-tools/releases/download/jarvis-host/install.sh | sudo bash
sudo jarvis-host setup --from-secrets-dir /path/to/secrets   # .env + auth.json
```

From monorepo (developers):

```bash
sudo hermes/host/jarvis/install.sh
```

## Commands

```bash
jarvis-host status
jarvis-host setup [--from-secrets-dir DIR] [--image IMAGE]
jarvis-host backup [--init|--dry-run]
sudo jarvis-host schedule install|status|remove
jarvis-host update --check
jarvis-host update --yes          # operator force enact
# approve via Slack → update-request.json → update --poll (timer)
```

## Existing hosts

```bash
sudo ./migrate-from-legacy.sh   # one-shot; throw away after use
```

## Product runtime

Image: `ghcr.io/mastercodeyoda/jarvis-hermes:main` (pull + recreate; volume kept).
