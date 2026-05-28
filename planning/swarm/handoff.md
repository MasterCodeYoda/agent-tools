# Implementation Handoff — `/swarm` Skill Family

> **Use this as the opening message of a fresh session.** It's self-contained — the new
> session has no prior context. Read everything end-to-end before acting.

---

## What you're implementing

A new top-level skill family `/swarm` for the agent-tools repo (this repo). It delivers
backlog-scale orchestration on top of `/workflow`: a host-session orchestrator drives
backlog items through `refine → plan → execute → review → local-merge` by dispatching
role-specialized sub-agents in parallel waves, with each item isolated in its own git
worktree.

The full design has been brainstormed, refined through extensive collaboration, and
committed at:

**`./planning/swarm/design.md`** — read it end-to-end before doing anything else.

## Required reading (in order)

1. **`./planning/swarm/design.md`** — the approved design (~1380 lines, 11 sections + glossary). This is the source of truth; **everything you implement must conform to it.**
2. **`./README.md`** — to understand the agent-tools publishing model (`src/` → `dist/<agent>/` via `tools/publish-skills.sh`, family overviews + flattened sub-skills, embedded `<!-- agent:include -->` markup).
3. **`./src/workflow/SKILL.md`** — to understand `/workflow`, which workers wrap. Specifically the parallel-execution-with-worktrees section and the session-state schema.
4. **`./src/git/worktree-create/SKILL.md` and `./src/git/worktree-delete/SKILL.md`** — these are the agent-aware worktree primitives that `/swarm` defers to (strict deferral; do NOT reinvent).

## Before producing any plan

Once you've read those files, summarize back to the user — in 5–7 bullets — what `/swarm`
does, how it relates to `/workflow`, and what the 5 role types are (3 sub-agent + 2 ad-hoc).
This is a comprehension check; if your summary is wrong, the user will correct course
before plan production.

## Scope decision

The design has **three phases**. Confirm scope with the user before planning:

| Phase | Scope | Default if user is unclear |
|---|---|---|
| **Phase 1** | Foundation: `/swarm` skill skeleton, `/swarm:init` (charter authoring + AGENTS.md linking + conditional CLAUDE.md/GEMINI.md symlinks), `.agent-tools/` umbrella + gitignore, `/qa:setup` `.sentinel/` migration logic, `/workflow:refine` + `/workflow:plan` enhancements to capture dependency metadata. | ✅ Default scope. |
| **Phase 2** | Orchestrator MVP: `/swarm <goal>` full orchestrator loop, `/swarm:continue` with reconciliation, all six role templates, session log infrastructure, `active-run` pointer, in-process refinement, merge sweep with ad-hoc fix-it dispatch, native sub-agent dispatch. | Defer until Phase 1 ships and is dogfooded. |
| **Phase 3** | Cross-CLI worker dispatch via shell-out, per-role CLI selection in `config.yml`, CLI addenda map. | Defer indefinitely; ship only when there's concrete reason to dispatch workers via non-Claude CLIs. |

**Default: scope to Phase 1 unless the user explicitly chooses otherwise.**

## Planning approach

Once scope is confirmed:

1. **Run `/workflow:plan`** against the scoped portion of `design.md` to produce `./planning/swarm/implementation-plan.md`. The design doc serves as the requirements input.
2. **Get explicit user approval** on the plan before any code changes. Per `/workflow:plan` discipline, plans require explicit approval before saving or executing.
3. **Consider `--worktree`** for execution isolation. This is a meaningful refactor across multiple skills; worktree isolation keeps your work from disturbing the user's other branches.

## Execution approach

When plan is approved:

1. Use `/workflow:execute` (likely with the worktree from `/workflow:plan --worktree`).
2. Follow the plan task-by-task. Commit per story/slice per existing workflow discipline.
3. **Run `setup.sh` after any `src/` changes** to update `dist/` trees and verify publishing.
4. **Verify publisher output** with `tools/publish-skills.sh --dry-run --agents claude grok factory` — confirm `swarm`, `swarm-init`, `swarm-continue` appear in `dist/claude/skills/` and `dist/factory/skills/`, and `swarm` alone in `dist/grok/skills/` (per existing Grok-doesn't-flatten policy).
5. Update README.md per design Section 9.5 documentation requirements.

## Hard constraints (non-negotiable)

- **Follow the design exactly.** If something is ambiguous, ASK the user before deviating. The design reflects many specific decisions made deliberately through iterative refinement; don't second-guess without surfacing first.
- **No new files in `src/swarm/` that aren't in the design.** No "while we're at it" scope expansion.
- **`/workflow` behavior is unchanged** except for the two enhancements in the design (Section 9.5): `/workflow:refine` and `/workflow:plan` capture `blocks` / `blocked_by` / `parallelizable_with` dependency metadata. Don't touch the rest of `/workflow`.
- **`/workflow:init` does NOT exist.** Charter authoring is owned by `/swarm:init` only. The user previously explored a `/workflow:init` path and explicitly rejected it.
- **`./planning/` stays at root in target projects.** Do NOT move it under `.agent-tools/`. This is an intentional carve-out for daily-use friction reasons (design Section 9.2).
- **`AGENTS.md` is the canonical agent-memory file.** Do NOT create separate content in `CLAUDE.md` or `GEMINI.md`. They are SYMLINKS to `AGENTS.md` for picky-named agents only (design Section 4.4).
- **No new agent-tools skills push to remote.** Workers never push; orchestrator never pushes. `git push origin main` is user-initiated only. Permanent constraint.
- **`./planning/swarm/design.md` is the source of truth.** When in doubt, read the design before improvising.

## Acceptance checks (per phase)

### Phase 1 acceptance
1. `setup.sh` runs clean.
2. `tools/publish-skills.sh --dry-run --agents claude grok factory` shows `swarm/` and `swarm-init/` (`swarm-continue/` won't exist yet since it's Phase 2).
3. `/swarm` invoked with no args returns a state summary (initialized vs not).
4. `/swarm <goal>` invocation returns "Orchestrator not yet implemented; use /workflow directly for single-agent work" (since Phase 2 isn't done).
5. `/swarm:init` in a test project (fresh, no charter): produces `.agent-tools/charter/{charter,project,engineering,workflow}.md` + `.agent-tools/swarm/{config.yml, roles/, .gitignore}` + `AGENTS.md` charter-link block + `CLAUDE.md` symlink if `.claude/` present.
6. `/swarm:init` in same project (re-init mode): detects existing charter, surfaces drift, walks user through `keep/replace/edit`, never destructive.
7. `/qa:setup` in a project with existing `.sentinel/`: detects, offers migration to `.agent-tools/sentinel/` via `git mv`, preserves git history, updates path references.
8. `/workflow:refine` produces refined items with `blocks` / `blocked_by` / `parallelizable_with` metadata.
9. `/workflow:plan` surfaces dependency declarations and writes them to `implementation-plan.md` frontmatter.

### Phase 2 acceptance (when applicable)
10. `/swarm <goal>` with a real (small) backlog: orchestrator classifies items, dispatches parallel sub-agents, processes wave returns, surfaces IN_FLIGHT_DECISIONs / TERMINAL_PAUSEs correctly.
11. `/swarm:continue` resumes from TERMINAL_PAUSE; reconciles `state.yml` against disk + PM ground truth; surfaces drift to user.
12. Merge sweep: clean case merges + cleanup; conflict triggers one-shot conflict-resolver dispatch; test-red triggers one-shot integration-fixer dispatch; second failure → TERMINAL_PAUSE.
13. Session logs at `.agent-tools/swarm/sessions/<run-id>/` with per-dispatch files and `orchestrator.md` log.
14. `active-run` pointer behavior matches design Section 8.4 (created on dispatch, cleared on GOAL_COMPLETE, preserved on TERMINAL_PAUSE).

### Phase 3 acceptance (when applicable)
15. Non-interactive CLI invocation confirmed for each target (Claude verified; Droid + Grok verified during P3).
16. Worker dispatch via shell-out to non-host CLI returns parseable structured YAML.
17. `config.yml` `clis` per-role selection works (e.g., `implementer: grok` actually dispatches via Grok).
18. CLI addenda map (`src/swarm/references/cli-addenda.md`) is populated only where needed; canonical role templates remain CLI-agnostic.

## Attribution

`src/swarm/SKILL.md`'s References section MUST credit Robert C. "Uncle Bob" Martin and link to https://github.com/unclebob/swarm-forge per design Section 11. The attribution should briefly note what was adapted (constitution/charter, role specialization, per-item worktree isolation) and what was re-shaped (no tmux; roles aligned to `/workflow` lifecycle stages; host-mediated returns instead of inter-agent file queue).

## Open questions you may surface during planning

The design is approved and complete, but these may come up as you decompose into tasks:

- **For Phase 3 only**: confirm exact CLI invocation flags for Droid and Grok (non-interactive mode + working-directory handling). These should be verified empirically during P3, not assumed.
- **Test command discovery**: the design specifies a 4-step cascade (Section 8.6). If a target project doesn't match any cascade step cleanly, surface to user and persist the answer into `config.yml`.
- **Schema migration paths**: the design declares `schema_version: 1` but doesn't specify migration mechanics for v2+. Defer migration logic until v2 is needed; just verify the version field is checked on load.

## Process discipline

- Use `TaskCreate`/`TaskUpdate` (or equivalent) to track work. Mark tasks complete as soon as done; don't batch.
- Use `/workflow:plan` and `/workflow:execute` as the primary planning + execution skills.
- Use `/git:commit-pr` (or `/git:commit-push`, or `/git:commit`) for commits per existing conventions.
- Reference back to `./planning/swarm/design.md` constantly; treat it as the spec, not as suggestion.

## Begin

1. Read `./planning/swarm/design.md` end-to-end.
2. Read the supporting files listed above.
3. Summarize what `/swarm` does in 5–7 bullets and present to user for comprehension check.
4. Ask user which phase(s) to scope (default Phase 1).
5. Run `/workflow:plan` to produce `./planning/swarm/implementation-plan.md`.
6. Get user approval.
7. Execute.
