# Family contracts (session-state, branch, layout)

**Load when:** plan, execute, continue, setup, or any phase that writes session-state,
creates branches, or needs the planning-directory layout. **Not** required for bare
`/workflow` status (status loads `status.md` only).

**SoT:** this reference + write-time shells under `execution/templates/session-state.md` and
@workflow (`planning/templates.md`). Do not re-embed full YAML in the parent skill.

## Planning directory structure

```
<planning-root>/          # .agent-tools/planning/ preferred; else ./planning/
├── roadmap.md            # optional (roadmap skill)
├── conventions.md        # optional (setup)
├── <project-name>/
│   ├── brainstorm.md           # optional (concept seed — not technical design)
│   ├── requirements.md         # file mode only
│   ├── codebase-research.md    # on-demand code snapshot (almost all work)
│   ├── design-discussion.md    # technical design (refine-primary; feature/hard)
│   ├── implementation-plan.md  # structure + tactical segments (executable SoT)
│   ├── session-state.md
│   ├── visual-plan.html        # optional; approval presentation only
│   └── technical-decisions.md  # optional
└── archive/
```

```
.agent-tools/runs/        # line instrumentation (not under planning-root)
├── events.ndjson
├── ledger.yml
└── yield.md              # optional regenerated glance
```

Initiative/workstream dialects are honored when conventions say so.

## Session state (per-item)

Write-time shell: **load** `execution/templates/session-state.md` (or plan-time shell in
`planning/templates.md`). Typical frontmatter fields:

| Field | Notes |
|-------|--------|
| `project`, `requirements_source`, `work_item`, `pm_tool` | Identity |
| `session_count`, `status`, `progress` | Continuity |
| `track`, `run_id`, `source_channel` | Continue / ledger |
| `branch`, `worktree` | Workspace |
| `visual_plan` | Approval presentation only |
| `reentry_counts`, `thrash_bound_hits` | Thrash bound per `run_id` |
| `current_layer` | **Optional** — only when clean-architecture / layered decomposition applies |

Body sections: Current Focus · Last Session Summary · Intentional Compaction (when used) ·
Session History (append-only on **per-item** files only).

> **Scope:** per-item `planning/<item>/session-state.md` may carry Session History. The
> **top-level handoff** (`planning/session-state.md`) is a *light pointer*, not a log — see
> `@workflow:setup` §4.

## Branch naming

**Rule:** `<type>/<identifier>` exactly.

| Type | With issue key | Without |
|------|----------------|---------|
| Bug | `fix/INK-123` | `fix/login-validation` |
| Feature | `feat/INK-124` | `feat/user-dashboard` |

With an issue key, use the key as the **entire** identifier — no username prefixes, no
appended descriptions. Without: short lowercase-hyphenated (2–4 words).

**Anti-patterns:** `matt/ink-123-desc`, `feature/INK-123-long-name`, bare `INK-123`.

## Handoff (session boundary)

At session boundaries: update session state → commit → offer compound → handoff summary.
Execute owns the full protocol (`execution/SKILL.md` + templates).

## Task planning norms

All planned tasks are required (no priority tiers). Acceptance criteria are binary. Future
ideas go in **Out of Scope**, not deferred tasks. Generic labels (e.g. “DTO”) are placeholders
— use the target project's terminology; for C#, @code-patterns **Model Terminology**.
