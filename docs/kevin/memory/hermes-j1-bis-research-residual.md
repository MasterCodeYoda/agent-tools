---
title: J1-bis automated wake — research residual (not live PASS)
type: lesson
tags: [hermes, cron, gateway, j1-bis, automation, residual]
date: 2026-07-22
source: hermes-j1-bis-automated-wake (r-20260722-j1bis)
---

# J1-bis residual

## Closed as research, not execution

- Hermes cron + gateway substrate is real (docs + CLI).  
- Factory profile ready (memory off, pack, approvals).  
- **Gateway not running** → jobs will not fire.  
- Factory `terminal.cwd` → primary Spectral (often dirty) — **unsafe** for unattended without isolated worktree `workdir`.  
- Does **not** block provisional H5 host adopt.  
- Live J1-bis optional follow-on with isolation + no remote pollution policy.
