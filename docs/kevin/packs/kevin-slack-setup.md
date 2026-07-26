# Kevin Slack bot setup (AGNT-8)

**Profile:** always `hermes -p kevin` — never personal default, never legacy `factory` for Kevin work.  
**Process pack:** agent-tools `./setup.sh` → `~/.hermes/skills` (publish agent **`hermes`**).  
**Manifest:** `packs/kevin-slack-manifest.json` (Agent view, Socket Mode, display name **Kevin**).  
**Path of record (full ops):** [`docs/runbooks/kevin-slack-live.md`](../docs/runbooks/kevin-slack-live.md)

Historical factory packaging (`factory-slack-setup.md`, `factory-slack.env.example`, `slack-factory-manifest.json`) remains for H3 dogfood archive only — **not** the Kevin path of record.

## One-time Slack app

1. Generate/update manifest (checked in for this dogfood; regenerate when Hermes slash registry drifts):
   ```bash
   hermes -p kevin slack manifest --agent-view \
     --name Kevin \
     --description "Kevin software factory agent — transport only; project disk SoT" \
     --write packs/kevin-slack-manifest.json
   ```
2. [api.slack.com/apps](https://api.slack.com/apps) → **Create New App** → **From an app manifest** → paste JSON from `packs/kevin-slack-manifest.json`.
3. **Install to workspace**; enable **Socket Mode**; create App-Level Token with `connections:write`.
4. Copy **Bot User OAuth Token** (`xoxb-`) and App Token (`xapp-`) into  
   `~/.hermes/profiles/kevin/.env` (see `kevin-slack.env.example`). Never commit values.
5. Set **allowlists** before first gateway start (hard gate):
   ```bash
   SLACK_ALLOWED_USERS=U…
   SLACK_ALLOWED_CHANNELS=C…
   ```
   Do **not** set `SLACK_ALLOW_ALL_USERS=true` for kevin.
6. Invite bot to the ops channel: `/invite @Kevin`
7. Put real channel ID into kevin `config.yaml` → `slack.channel_skill_bindings` (replace `REPLACE_WITH_KEVIN_OPS_CHANNEL_ID`), then re-apply profile:
   ```bash
   ./scripts/apply-kevin-profile.sh --force -y
   # or: hermes profile update kevin --force-config
   ```
   Profile update preserves `.env` / auth / sessions.

## Start gateway

```bash
# Preferred dogfood: foreground (launch from software-factory project root)
cd /path/to/software-factory
hermes -p kevin gateway run

# Or user service
hermes -p kevin gateway install
hermes -p kevin gateway start
hermes -p kevin gateway status
```

## Repo visibility (same disk as git)

| Mode | How Hermes sees product repo | Kevin note |
|------|------------------------------|------------|
| **local** (default) | Launch gateway from software-factory tree (or document absolute project root); tools run as your OS user | Fast laptop dogfood; same files you `git status` |
| **docker** | Container + mount product root (and `.agent-tools`) | Prefer for unattended gateway; set `terminal.backend: docker` and mounts |
| **ssh** | Remote worker cwd | Team host without laptop secrets |

**Rule:** planning/runs must update on the **same tree** you review in git. If docker/ssh, mount or sync that tree — do not let Slack agent write a disposable container FS.

## Live checklist (pointer)

Full AC-mapped checklist, residual template, failure matrix, and escalate/judgment paths live in:

→ **[`docs/runbooks/kevin-slack-live.md`](../docs/runbooks/kevin-slack-live.md)**

Quick smoke rows (when tokens available):

| Check | How |
|-------|-----|
| @mention only in allowlisted channel | Non-allowlisted → ignore; allowlisted @mention → reply |
| Skill binding loads process skills | Ops channel has `workflow` / `workflow-continue` binding |
| Approvals work | Dangerous terminal → Slack buttons or `!approve` / `!deny` |
| Project disk updates | After write action, `git status` under software-factory |
| No personal / factory profile bleed | Gateway process is `kevin` only |

## Safety defaults (kevin profile)

- `memory_enabled: false`, skill `write_approval: true`
- `approvals.mode: manual` + deny globs (force-push, curl\|sh, root rm)
- Slack toolsets: `file`, `terminal`, `skills` only
- Channel binding skills: `workflow`, `workflow-continue` (not full pack auto-load)
- Provider auth / portable secrets packaging: [AGNT-9](https://linear.app/overlund-media/issue/AGNT-9) / [hermes-kevin.md](../docs/runbooks/hermes-kevin.md) secrets section
