---
name: swarm
description: Backlog-scale orchestration on top of /workflow — drives PM items through refine → plan → implement → review → local-merge via role-specialized sub-agents in per-item worktrees. Phase 1 ships /swarm:init (charter authoring + project bootstrapping); the orchestrator loop is Phase 2.
user-invocable: true
argument-hint: "[no args for state summary | <goal> e.g. a milestone, issue list, or backlog file]"
---

# Swarm

`/swarm` is the parent skill for the **swarm** family — multi-role, multi-item
orchestration of backlog-scale work built **on top of** `/workflow`. A host-session
*orchestrator* drives backlog items through the `/workflow` lifecycle (refine → plan →
implement → review → local-merge) by dispatching role-specialized sub-agents in parallel
waves, with each item isolated in its own git worktree.

> **Implementation status.** This repo is shipping `/swarm` in phases. **Phase 1 (current)**
> delivers `/swarm:init` and the foundation it bootstraps (the project charter, the
> `.agent-tools/` umbrella, and swarm config). **The orchestrator loop (`/swarm <goal>`) and
> `/swarm:continue` are Phase 2 and not yet implemented.** See `## Phase status` below.

## Commands in This Family

| Command | Purpose | Status |
|---------|---------|--------|
| `/swarm` (no args) | Summarize repo swarm state (initialized? backlog detectable?) and suggest a next step | **Available** |
| `/swarm:init` | Initialize or re-initialize: author the project charter, link agent-memory files, write swarm config under `.agent-tools/` | **Available** |
| `/swarm <goal>` | Start the orchestrator on a goal (milestone, issue list, or backlog file) | **Phase 2** |
| `/swarm:continue` | Resume the most recent paused run, reconciling state against ground truth | **Phase 2** |

## What `/swarm` Does (and how it relates to `/workflow`)

- **Builds on `/workflow`, not around it.** Workers run ordinary `/workflow` commands
  (`/workflow:plan --worktree`, `/workflow:execute`, `/workflow:review`) inside per-item
  worktrees. `/workflow` behavior is unchanged.
- **Charter is shared ground truth.** `/swarm:init` authors a structured project charter at
  `.agent-tools/charter/` and links it from `AGENTS.md`, so it loads for any agent reading
  project memory — including single-agent `/workflow` runs that never invoke `/swarm`.
- **Safety is non-negotiable.** No agent ever pushes to remote. The orchestrator (Phase 2)
  merges locally to `main` with full test gates between merges; pushing to `origin` is
  always a user-initiated action.

## Behavior

Parse `$ARGUMENTS`:

```text
$ARGUMENTS
```

### No arguments → State summary

Inspect the project from disk only (no run/session machinery — that is Phase 2) and report:

1. **Charter present?** Check for `.agent-tools/charter/charter.md`.
2. **Swarm config present?** Check for `.agent-tools/swarm/config.yml`.
3. **Agent-memory linked?** Check that `AGENTS.md` exists and contains the
   `<!-- agent-tools:charter-link begin -->` marker block.
4. **Backlog detectable?** Note whether a PM tool (Linear/Jira MCP) is available or a
   local `./planning/` backlog exists — informational only.

Then summarize and suggest a next step:

- **Not initialized** (no charter): summarize what's missing, then offer to run
  `/swarm:init`. Ask before delegating; do not auto-run it.
- **Initialized + idle**: report that the charter and swarm config are present, and note
  that the orchestrator (`/swarm <goal>`) and `/swarm:continue` are Phase 2 and not yet
  available in this build. Point the user at `/workflow` for single-agent work today.

### `<goal>` provided → Orchestrator (Phase 2, not yet implemented)

1. **Precondition check.** If `.agent-tools/charter/charter.md` is absent, respond:
   "No charter found. Run `/swarm:init` first."
2. **Otherwise**, respond exactly:

   > Orchestrator not yet implemented; use /workflow directly for single-agent work.

   Do not attempt to dispatch sub-agents, create worktrees, or simulate orchestration.

## Phase status

- **Phase 1 (this build):** `/swarm` state summary + `/swarm:init`. The orchestrator and
  `/swarm:continue` intentionally return the not-implemented message above.
- **Phase 2:** the `/swarm <goal>` orchestration loop, `/swarm:continue` with
  reconciliation, the six canonical role templates under `.agent-tools/swarm/roles/`,
  session logs, and the `active-run` pointer.
- **Phase 3:** cross-CLI worker dispatch via shell-out.

The authoritative design lives at `planning/swarm/design.md` in this repo.

## References

### Attribution

The swarm orchestration concept is adapted from **swarm-forge** by Robert C. "Uncle Bob"
Martin — <https://github.com/unclebob/swarm-forge>.

**Adapted from swarm-forge:**
- the constitution/charter primitive (layered project context with precedence);
- role-specialized agents;
- per-item worktree isolation.

**Re-shaped for this design:**
- **No process orchestration.** swarm-forge uses tmux + macOS Terminal + watchdog scripts;
  `/swarm` uses the host agent's native sub-agent dispatch with no multi-terminal control.
- **Roles aligned to the `/workflow` lifecycle** — planner / implementer / reviewer, plus
  one-shot conflict-resolver / integration-fixer; refinement runs host-side rather than as a
  sub-agent role.
- **Host-mediated structured returns** instead of swarm-forge's inter-agent file-queue
  messaging — sub-agents return a strict status schema to the orchestrator; there is no
  inter-sub-agent messaging.
