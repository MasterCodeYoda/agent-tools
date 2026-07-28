# Runbook: Jarvis Slack (CoS transport)

**Status:** Active — day-1 interactive UX for Jarvis  
**Profile:** `jarvis` only  
**Topology:** **Same** single remote instance as cron/state ([jarvis-hermes-docker.md](./jarvis-hermes-docker.md))  
**Doctrine:** [multi-agent-config-lanes.md](./multi-agent-config-lanes.md)  
**Secrets:** [jarvis-capabilities.md](./jarvis-capabilities.md)

---

## Intent

Slack is **transport only** for talking to Jarvis:

- Primary CoS conversation surface (DM and/or home channel)
- **Not** the morning digest delivery channel (email owns that)
- **Not** terminal — ops stay on `hermes -p jarvis` / docker exec
- No second Jarvis instance for chat

Pattern class matches Kevin Socket Mode packaging; **brand and allowlists are Jarvis-specific**.

---

## One-time Slack app (CoS)

1. Create a Slack app (manifest or UI) branded **Jarvis** — personal CoS, not factory.
2. Enable **Socket Mode**; create app-level token `xapp-…` with `connections:write`.
3. Bot token `xoxb-…` with messaging scopes sufficient for DM + home channel (mirror Kevin app scopes as a starting point; tighten to least privilege).
4. Install to workspace; note your member user id for allowlist.

Example **valid** manifest (edit before use).  
**Note:** `bot_user` / Messages tab require `oauth_config.scopes.bot` — without bot scopes Slack errors with *“Bot user requires bot scope”*.

```json
{
  "display_information": {
    "name": "Jarvis",
    "description": "Personal chief of staff — Hermes profile jarvis; transport only",
    "background_color": "#1a1a2e"
  },
  "features": {
    "app_home": {
      "home_tab_enabled": false,
      "messages_tab_enabled": true,
      "messages_tab_read_only_enabled": false
    },
    "bot_user": {
      "display_name": "Jarvis",
      "always_online": true
    }
  },
  "oauth_config": {
    "scopes": {
      "bot": [
        "app_mentions:read",
        "channels:history",
        "channels:read",
        "chat:write",
        "groups:history",
        "groups:read",
        "im:history",
        "im:read",
        "im:write",
        "mpim:history",
        "mpim:read",
        "users:read"
      ]
    }
  },
  "settings": {
    "event_subscriptions": {
      "bot_events": [
        "app_home_opened",
        "app_mention",
        "message.channels",
        "message.groups",
        "message.im",
        "message.mpim"
      ]
    },
    "interactivity": {
      "is_enabled": true
    },
    "org_deploy_enabled": false,
    "socket_mode_enabled": true,
    "token_rotation_enabled": false
  }
}
```

Socket Mode: after create, **Settings → Socket Mode → Enable**, then create an **App-Level Token** (`xapp-…`) with scope `connections:write` (not always in the YAML for new apps).

### Gateway commands in Slack (home channel, etc.)

Slack treats messages that start with `/` as **workspace slash commands**. If the
command is not registered on the Jarvis app, Slack swallows it and Hermes never
sees the text.

| What you want | Type this in the DM | Notes |
|---------------|---------------------|--------|
| Set home channel | `!sethome` | **Preferred.** Hermes rewrites `!` → `/` for known gateway commands. |
| Set home (native slash) | `/sethome` | Only if the app has slash command `/sethome` installed. |
| Legacy parent slash | `/hermes sethome` | Only if `/hermes` is registered (full Hermes-generated manifest). |

The jarvis-hermes image patches Hermes’ first-DM home-channel hint to recommend
`!sethome` (upstream says `/hermes sethome`, which fails on event-only apps).

Optional: generate a full slash-command manifest and reinstall so `/sethome` works natively:

```bash
hermes -p jarvis slack manifest --agent-view \
  --name Jarvis \
  --description "Personal chief of staff — single remote instance" \
  --write docs/agents/packs/jarvis-slack-manifest.json
```

(Checked-in generated manifest optional; do not commit tokens.)

---

## Secrets (live volume only)

Put in jarvis profile `.env` on the **production volume**:

```bash
SLACK_BOT_TOKEN=xoxb-…
SLACK_APP_TOKEN=xapp-…
SLACK_ALLOWED_USERS=U0123…          # hard allowlist
# SLACK_HOME_CHANNEL=C0123…         # optional home channel
# SLACK_ALLOWED_CHANNELS=C0123…
```

Names only in `hermes/jarvis-profile/.env.template`. Never commit values.

Update profile channel binding placeholder in live config (or after promote to git) for home channel id:

```yaml
slack:
  channel_skill_bindings:
    - id: "C…"   # real home channel
      skills:
        - jarvis-research-digest   # and other jarvis skills as added
```

---

## Bring-up checklist

| Step | Pass |
|------|------|
| jarvis-hermes up with gateway | Container running; gateway logs healthy |
| Tokens in live `.env` | No secrets in git |
| Allowlist set | Only your user id (and intended peers) |
| DM or home message | Jarvis replies from **this** instance |
| State continuity | Project list / prior context still on same volume |

---

## Smoke (AC18)

1. Ensure container gateway running on production volume.  
2. From Slack, DM Jarvis (or post in home channel).  
3. Expect a CoS-style reply without using terminal chat.  
4. Confirm `JARVIS_HERMES_DATA` is the only instance you use for follow-ups.

`jarvis-local-smoke.sh` (when `SLACK_BOT_TOKEN` is set) probes the bot token via `conversations.list?types=im` (requires **`im:read`**). Socket Mode “connected” alone is not enough.

---

## Failure: DM silent, gateway still “✓ slack connected”

**Symptom:** Jarvis shows online; you DM “hello”; no reply. Gateway logs show Socket Mode connected; often a session seed from opening the DM tab, but **zero** agent messages/tokens.

**Cause (lab confirmed):** Bot User OAuth Token installed with incomplete scopes, e.g. only:

```text
provided: channels:history,chat:write
needed for DMs: im:history (and typically im:read, im:write, users:read, …)
```

Socket Mode uses the **app-level** `xapp-` token to connect; inbound `message.im` delivery requires the **bot** token’s OAuth scopes + Event Subscriptions. A thin token can authenticate the bot while never delivering DMs.

**Fix:**

1. [api.slack.com/apps](https://api.slack.com/apps) → **Jarvis** app.  
2. **OAuth & Permissions → Bot Token Scopes** — match the manifest in this runbook (at minimum for DMs: `im:history`, `im:read`, `im:write`, `chat:write`, `users:read`).  
3. **Event Subscriptions → Subscribe to bot events** — include `message.im` (and `app_home_opened` if used).  
4. **Reinstall to workspace** (required after scope changes).  
5. Copy the **new** `xoxb-…` Bot User OAuth Token into the live profile `.env` (`SLACK_BOT_TOKEN`). App-level `xapp-` usually stays the same.  
6. Restart gateway (`docker restart jarvis-hermes` or bring-up).  
7. DM again; expect a reply. Re-run smoke to confirm `im:history` present.

**Not the cause (when this mode matches):** `SLACK_ALLOWED_USERS` mismatch (would log early reject), or Grok OAuth (CLI `hermes -p jarvis chat -q …` still works).

---

## Failure: bot says type `/hermes sethome`, Slack says not a valid command

**Cause:** Upstream Hermes hardcodes that hint for Slack, assuming a registered
`/hermes` parent slash command. Minimal/event-only apps do not have it.

**Fix (packaging):** jarvis-hermes image rewrites the hint to `!sethome`. Rebuild
the image to pick up the patch. Until then, type `!sethome` yourself (works today).

---

## Out of scope

- Second messenger (Telegram, etc.) day-1  
- Using Slack as digest email replacement  
- Kevin factory channel skill bindings / process pack on this app  
