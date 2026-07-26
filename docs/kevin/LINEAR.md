# Linear disposition (Kevin team / agent-tools monorepo)

## Current state

| Item | Value |
|------|--------|
| Team | **Kevin** |
| Issue prefix | **`KEVN`** |
| Project | Kevin v1 — Hermes factory foundation |
| Open work | **KEVN-11** (monorepo + kevin-hermes) |

Repo SoT is now **agent-tools**. Linear remains the PM queue for Kevin epics.

## Option: rename team to “Agent Tools” + `AGNT-`

### What Linear allows

- **Display name** can be changed in Team settings → General (e.g. Kevin → Agent Tools).
- **Team identifier** (the issue key prefix `KEVN`) is set on the team; Linear documents “team identifier” under General. Changing it is **not** always available or safe for existing issues — treat **`KEVN` as sticky** for historical issues unless Linear UI explicitly allows a non-breaking rename.
- Moving an issue to another team **generates a new identifier** (e.g. `AGNT-1`); old URLs redirect. History is preserved, but every link/script that assumes `KEVN-##` must update.

### Recommendation

| Choice | When |
|--------|------|
| **A. Rename display name only** (recommended default) | Keep `KEVN` keys. Set team name to **Agent Tools** (or “Agent Tools / Kevin”). Zero link breakage. Product name “Kevin” stays the agent; team name matches monorepo. |
| **B. New team `AGNT`** | Only if you want a clean prefix for *new* work. Leave KEVN as archived v1 history, or bulk-move issues (they get new IDs). Higher ceremony. |
| **C. Bulk-move everything to AGNT** | Only if prefix branding matters more than stable IDs. Plan a link fix pass (docs, commits, comments). |

**Do not** invent dual queues (Kevin + Agent Tools both active for the same work).

### Suggested near-term action

1. In Linear UI: Team Kevin → Settings → General → rename to **Agent Tools** (keep identifier `KEVN` if the UI separates name vs identifier).  
2. Rename project to something like **Agent Tools — Kevin / Hermes** if desired.  
3. Keep **KEVN-11** through monorepo ship; do not create parallel AGNT issues for the same work.  
4. Revisit **B** only if you outgrow the KEVN brand for process IP work.

### What automation will not do

MCP cannot reliably rename team identifiers or bulk-rekey issues. Display rename is a one-click UI step for you. This file is the decision record until you choose A/B/C.
