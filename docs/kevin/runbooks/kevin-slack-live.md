# Runbook: Kevin Slack live (Socket Mode)

**Status:** Path of record for AGNT-8 / E7 Slack transport  
**Profile name:** `kevin` only — never personal default; never brand Kevin as `factory`  
**Unit:** [AGNT-8](https://linear.app/overlund-media/issue/AGNT-8)  
**Packaging:** [`packs/kevin-slack-setup.md`](../../packs/kevin-slack-setup.md) · [`packs/kevin-slack.env.example`](../../packs/kevin-slack.env.example) · [`packs/kevin-slack-manifest.json`](../../packs/kevin-slack-manifest.json)  
**Related:** bring-up [hermes-kevin.md](./hermes-kevin.md) · wake [kevin-unattended-wake.md](./kevin-unattended-wake.md) · legacy H3 dogfood [hermes-factory.md](./hermes-factory.md) § H3 · historical packs `packs/factory-slack-*`

---

## 1. Intent

Slack is **transport only** for the Kevin software-factory agent:

- **Lean A:** process SoT = agent-tools; project = disk (this repo); host = Hermes (pluggable).
- Same process dialect on Slack as CLI (`workflow`, `workflow-continue`, …). No Slack-only continue language.
- Gateway always: `hermes -p kevin …`.
- Full unattended Slack autonomy, Telegram, and multi-channel productization are **out of scope**.

---

## 2. Prerequisites

| Need | Notes |
|------|--------|
| Hermes on PATH | `hermes version` (dogfood validated on 0.19.x) |
| Kevin profile applied | `./scripts/apply-kevin-profile.sh` ([hermes-kevin.md](./hermes-kevin.md)) |
| Process skills installed | agent-tools `./setup.sh` → `~/.hermes/skills` (publish agent **hermes**) |
| Provider auth | Model keys in `~/.hermes/profiles/kevin/.env` or `auth.json` — **AGNT-9** owns portable secrets packaging SoT; names in `hermes/profile/.env.template` |
| Slack tokens | Names only in repo (`packs/kevin-slack.env.example`); values only in user-owned kevin `.env` |
| Project root | software-factory git tree the operator reviews |

---

## 3. One-time Slack app

1. **Manifest** (Kevin brand, Agent view, Socket Mode):
   ```bash
   cd /path/to/software-factory
   hermes -p kevin slack manifest --agent-view \
     --name Kevin \
     --description "Kevin software factory agent — transport only; project disk SoT" \
     --write packs/kevin-slack-manifest.json
   ```
   Or paste the checked-in `packs/kevin-slack-manifest.json`.

2. [api.slack.com/apps](https://api.slack.com/apps) → **Create New App** → **From an app manifest** → paste JSON → Save.

3. **Install to workspace.** Enable **Socket Mode**. Create an **App-Level Token** with scope `connections:write` → yields `xapp-…`.

4. **Bot User OAuth Token** (`xoxb-…`) after install. Invite the bot: `/invite @Kevin` in the ops channel.

5. Confirm manifest has `settings.socket_mode_enabled: true` and bot display name **Kevin** (not Factory / Hermes default).

---

## 4. Env + hard allowlists

Copy **names** from [`packs/kevin-slack.env.example`](../../packs/kevin-slack.env.example) into:

```text
~/.hermes/profiles/kevin/.env
```

Required before any live gateway use:

```bash
SLACK_BOT_TOKEN=xoxb-…          # real value — user-owned only
SLACK_APP_TOKEN=xapp-…          # real value — user-owned only
SLACK_ALLOWED_USERS=U…          # non-empty member ID(s)
SLACK_ALLOWED_CHANNELS=C…       # non-empty channel ID(s)
```

**Hard policy for Kevin:**

- Allowlists **must** be non-empty before live use.
- **Do not** set `SLACK_ALLOW_ALL_USERS=true`.
- Non-allowlisted users/channels are ignored (Hermes default deny + allowlist).
- Optional: `SLACK_HOME_CHANNEL=C…`.

Hermes profile update / apply **preserves** `.env` (user-owned). Never commit token values.

---

## 5. Profile config (toolsets + channel bindings)

Versioned policy lives in [`hermes/profile/config.yaml`](../../hermes/profile/config.yaml):

- `platform_toolsets.slack`: `file`, `terminal`, `skills` only (narrow blast radius).
- `slack.channel_skill_bindings`: placeholder channel id  
  `REPLACE_WITH_KEVIN_OPS_CHANNEL_ID` → replace with real `C…` at ops time.
- Default bound skills: `workflow`, `workflow-continue` (confirm against `ls ~/.hermes/skills`).

After pulling config changes:

```bash
cd /path/to/software-factory
./scripts/apply-kevin-profile.sh --force -y
# or: hermes profile update kevin --force-config
```

`.env` / auth / sessions are preserved. Optional `channel_prompts` for ops tone can be added later without a new process dialect.

---

## 6. Start gateway

Prefer foreground dogfood from the **software-factory project root** (same disk as git):

```bash
cd /path/to/software-factory
hermes -p kevin gateway run
```

Optional service hardening:

```bash
hermes -p kevin gateway install
hermes -p kevin gateway start
hermes -p kevin gateway status
hermes -p kevin gateway stop
```

Useful checks:

```bash
hermes -p kevin gateway status
hermes gateway list   # confirm kevin process, not personal default / factory
```

---

## 7. @mention discipline

| Traffic | Expected behavior |
|---------|-------------------|
| Non-allowlisted user or channel | Ignored (no reply) |
| Allowlisted channel, no @mention (per Hermes mention rules) | No unsolicited agent turn unless product config says otherwise |
| Allowlisted user @mentions @Kevin in allowlisted channel | Agent session / reply in thread |

Smoke when tokens exist: prove ignore vs reply with a second account or non-allowlisted channel.

---

## 8. Escalate / judgment stops

| Stop type | Slack delivery path |
|-----------|---------------------|
| Dangerous terminal / approval-gated shell | Slack **approval buttons** and/or in-thread `!approve` / `!deny` |
| Process judgment (`await_user`, merge gates, human escalate) | Agent posts escalate / report text in the **channel thread** — same dialect as CLI, transport only |
| Stop type cannot surface on Slack | Document in residual table — **do not** invent a second process language |

Profile already sets `approvals.mode: manual` + deny globs. Slack must surface approve UX; it does not replace process skills.

### Residual template (escalate surface)

| Judgment / stop | Surfaces on Slack? | Residual / operator note |
|-----------------|--------------------|---------------------------|
| Dangerous terminal approve/deny | Yes (buttons / `!approve` `!deny`) when gateway live | |
| `await_user` / process escalate text | Yes if agent posts thread message | |
| Merge / ship gate | Thread report only unless operator defines buttons | |
| Other | | Fill when observed |

---

## 9. Repo visibility

| Mode | How Hermes sees software-factory | Note |
|------|----------------------------------|------|
| **local** (default) | Launch gateway cwd / tool context = product repo; OS user files | Laptop dogfood |
| **docker** | Mount product root (+ `.agent-tools` if needed); `terminal.backend: docker` | Prefer unattended |
| **ssh** | Remote worker cwd on same tree | Team host |

**Rule:** gateway tools must mutate the **same git tree** the operator reviews. Smoke: after an allowlisted action that writes project files, `git status` shows changes under software-factory.

Kevin profile intentionally omits hardcoded `terminal.cwd` — launch from the project root.

---

## 10. Live smoke checklist (AC7)

Map 1:1 to Linear ACs. Tick **Pass** only with real evidence. If tokens unavailable this session, mark **Residual** with reason — **no fake PASS**.

| AC | Check | Pass | Residual (reason / remaining steps) |
|----|-------|:----:|-------------------------------------|
| 1 | Kevin packaging present (`kevin-slack.env.example`, `kevin-slack-manifest.json`, `kevin-slack-setup.md`) + this runbook | ✓ packaging | |
| 2 | Socket Mode gateway under `hermes -p kevin`; tokens names documented for `~/.hermes/profiles/kevin/.env` | ✓ docs | Live gateway start residual (no tokens this session) |
| 3 | Hard allowlists required in docs/env example; ban on `SLACK_ALLOW_ALL_USERS=true` | ✓ docs | Live enforce residual until tokens + allowlists set |
| 4 | @mention discipline: non-allowlisted ignore; allowlisted @mention → reply | | Residual — needs live gateway |
| 5 | Escalate/report: approval buttons or `!approve`/`!deny`; judgment text in thread; residual table if gap | ✓ path documented | Live tick residual |
| 6 | Repo visibility: write lands on same software-factory tree (`git status`) | ✓ rules documented | Live project-write residual |
| 7 | Live smoke executed **or** residual documented below | ✓ residual | See session residual table |

### Operator live ticks (when tokens exist)

| # | Action | Pass? | Notes |
|---|--------|:-----:|-------|
| L1 | Slack app from Kevin manifest; Socket Mode + `connections:write` app token | | |
| L2 | Tokens + allowlists in `~/.hermes/profiles/kevin/.env` only | | |
| L3 | Replace `REPLACE_WITH_KEVIN_OPS_CHANNEL_ID`; re-apply profile | | |
| L4 | `hermes -p kevin gateway run` from project root | | |
| L5 | Non-allowlisted traffic ignored | | |
| L6 | Allowlisted @Kevin → agent reply | | |
| L7 | Dangerous command → approve path works | | |
| L8 | Project write → `git status` dirty under software-factory | | |
| L9 | `hermes gateway list` / process shows **kevin**, not factory/personal | | |

### Session residual (tokens unavailable)

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Session / run** | `2026-07-24-mxn3k-kevn-8-9` (AGNT-8 implementer) |
| **AC7 disposition** | **Residual** — packaging + path-of-record shipped; live gateway smoke deferred |
| **Why** | No `~/.hermes/profiles/kevin/.env` with Slack tokens on implementer host; operator has not provisioned workspace app tokens this session |
| **Remaining operator steps** | (1) Create/update Slack app from `packs/kevin-slack-manifest.json`; (2) fill kevin `.env` from `packs/kevin-slack.env.example` with real `xoxb`/`xapp` + non-empty allowlists; (3) set real `C…` in `channel_skill_bindings` and re-apply profile; (4) `cd` software-factory → `hermes -p kevin gateway run`; (5) tick L1–L9 and ACs 4–7 Pass rows above |
| **Fake PASS?** | No |

---

## 11. Failure matrix

| Symptom | Likely cause | Recovery |
|---------|--------------|----------|
| Silent bot (no replies) | Missing Socket Mode / app token; bot not invited; wrong scopes; allowlist empty/mismatch; not @mentioned | Re-check app Socket Mode + tokens; `/invite @Kevin`; fix `SLACK_ALLOWED_*`; mention bot |
| Wrong profile / factory bleed | `hermes -p factory` or personal default gateway | Stop other gateways; always `hermes -p kevin`; confirm with `hermes gateway list` / profile show |
| Missing allowlist / open bot | Empty allowlists or `SLACK_ALLOW_ALL_USERS=true` | Set non-empty U…/C…; remove allow-all; restart gateway |
| Personal profile bleed | Gateway without `-p kevin` | Kill personal gateway; start under kevin only |
| Project writes invisible | Gateway cwd elsewhere; docker without mount | Launch from software-factory; mount/sync project tree |
| Approvals never appear | Toolset missing terminal; approvals misconfigured | Confirm `platform_toolsets.slack` includes `terminal`; `approvals.mode: manual` |
| Skills missing in channel | Binding placeholder not replaced; skills not installed | Real channel id + re-apply; agent-tools `./setup.sh` |
| Config stale after pull | Installed profile not re-applied | `./scripts/apply-kevin-profile.sh --force -y` |

---

## 12. Out of scope

- Telegram or multi-channel productization  
- Full unattended Slack autonomy without approvals  
- New process dialect / dual continue language for Slack  
- AGNT-9 portable secrets packaging SoT (`hermes/profile/.env.template` wholesale)  
- AGNT-10 controller chrome  
- Deleting historical factory Slack packs  

---

## 13. AGNT-9 boundary

| Surface | Owner |
|---------|--------|
| Slack token **names** + Socket Mode ops | **This runbook** + `packs/kevin-slack.env.example` |
| Provider keys / portable auth packaging | **AGNT-9** + [hermes-kevin.md](./hermes-kevin.md) secrets / `hermes/profile/.env.template` |
| User-owned secrets file | `~/.hermes/profiles/kevin/.env` (both may land keys there; different name sets) |

Do **not** rewrite `hermes/profile/.env.template` wholesale for Slack in AGNT-8.

---

## Quick reference

```bash
# Packaging
packs/kevin-slack-manifest.json
packs/kevin-slack.env.example
packs/kevin-slack-setup.md

# Env landing zone
~/.hermes/profiles/kevin/.env

# Gateway
cd /path/to/software-factory
hermes -p kevin gateway run

# Re-apply after config.yaml pull
./scripts/apply-kevin-profile.sh --force -y
```
