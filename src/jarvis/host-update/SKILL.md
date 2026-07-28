---
name: host-update
description: >-
  Read jarvis-host update status from volume ops files; notify the user when an
  image update is available; on explicit approval (yes / apply update) write an
  update-request for the host kit to enact. Never run docker on the host.
---

# Host update (approve-only)

## Paths (in container)

```text
$HERMES_HOME/profiles/jarvis/state/ops/update-status.json
$HERMES_HOME/profiles/jarvis/state/ops/update-request.json
$HERMES_HOME/profiles/jarvis/state/ops/update-result.json
```

Default `HERMES_HOME` = `/opt/data`.

## When to use

- User asks if Jarvis is up to date / any host updates  
- Proactive: if `update-status.json` has `"available": true`, tell the user in Slack  
- User replies **yes**, **apply update**, or **update now** after you offered an update  

## Read status

1. Read `update-status.json` if present.  
2. If missing: say host check has not run yet (timer hourly; operator can run `jarvis-host update --check`).  
3. If `available` is false: report up to date (include `checked_at`, image refs if present).  
4. If `available` is true: summarize current vs target image and ask whether to apply.

## Approve → write request

Only when the user clearly approves applying the host image update:

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

Then tell the user the host will pick this up within a few minutes (`jarvis-update-poll` timer) and you will report `update-result.json` when present.

## After apply

Read `update-result.json`. Report `ok` / message / image ids. If absent after a reasonable wait, say result not yet written (host poll lag or failure — operator can check `journalctl -u jarvis-update-poll.service`).

## Hard rules

- **Do not** claim you ran `docker pull` yourself.  
- **Do not** invent Docker socket access.  
- **Do not** write a request without user approval.  
- **Do not** put secrets in ops JSON.  
