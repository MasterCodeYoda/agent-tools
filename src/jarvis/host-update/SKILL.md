---
name: host-update
description: >-
  Host image update via jarvis-host: read status, !update to force an immediate
  check, notify when available, write apply request on user yes. Never run docker
  on the host from the container.
---

# Host update (approve-only)

## Paths (in container)

```text
$HERMES_HOME/profiles/jarvis/state/ops/update-status.json
$HERMES_HOME/profiles/jarvis/state/ops/update-check-request.json   # !update nudge
$HERMES_HOME/profiles/jarvis/state/ops/update-request.json         # apply nudge
$HERMES_HOME/profiles/jarvis/state/ops/update-result.json
```

Default `HERMES_HOME` = `/opt/data`.

## Commands / when to use

| User says | You do |
|-----------|--------|
| **`!update`** (or “check for updates now”) | Write **check-request** (below); then read status after a short wait / next poll (~1 min) and report |
| “Any updates?” / proactive | Read `update-status.json` only |
| **yes** / **apply update** after you offered an apply | Write **update-request** (apply) |

Periodic host check runs about **every 20 minutes**. `!update` does **not** pull/recreate itself — it asks the host to **check now**; apply still needs a separate yes.

## `!update` — force check now

Write/overwrite `update-check-request.json`:

```json
{
  "schema": "jarvis-host.update-check-request/v1",
  "action": "check",
  "requested_at": "<UTC ISO8601 Z>",
  "requested_by": "slack:<user or channel id if known>"
}
```

Tell the user: host will run the check within about a minute, then you’ll report whether an image update is available.  
Do **not** claim you already pulled or recreated the container.

After ~1 minute (or when status `checked_at` is newer than the request), re-read `update-status.json` and report.

## Read status

1. Read `update-status.json` if present.  
2. If missing: say host check has not run yet — suggest **`!update`** or wait for the 20m timer.  
3. If `available` is false: report up to date (`checked_at`, image refs if present).  
4. If `available` is true: summarize current vs target and ask whether to **apply**.

## Approve apply → write request

Only when the user clearly approves **applying** (not merely checking):

Write/overwrite `update-request.json`:

```json
{
  "schema": "jarvis-host.update-request/v1",
  "action": "update-image",
  "target": "main",
  "requested_at": "<UTC ISO8601 Z>",
  "requested_by": "slack:<user or channel id if known>"
}
```

Tell them the host will apply within about a minute (poll timer), then report `update-result.json`.

## After apply

Read `update-result.json`. Report `ok` / message / image ids. If missing after ~2 minutes, say result not yet written (host poll lag).

## Hard rules

- **Do not** claim you ran `docker pull` yourself.  
- **Do not** invent Docker socket access.  
- **Do not** write an **apply** request without user approval.  
- **`!update` = check only**, not apply.  
- **Do not** put secrets in ops JSON.  
