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

Example manifest skeleton (edit before use):

```json
{
  "display_information": {
    "name": "Jarvis",
    "description": "Personal chief of staff — Hermes profile jarvis; transport only"
  },
  "features": {
    "bot_user": {
      "display_name": "Jarvis",
      "always_online": true
    },
    "app_home": {
      "messages_tab_enabled": true,
      "messages_tab_read_only_enabled": false
    }
  },
  "settings": {
    "socket_mode_enabled": true
  }
}
```

Generate a full manifest with Hermes when available, e.g.:

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

---

## Out of scope

- Second messenger (Telegram, etc.) day-1  
- Using Slack as digest email replacement  
- Kevin factory channel skill bindings / process pack on this app  
