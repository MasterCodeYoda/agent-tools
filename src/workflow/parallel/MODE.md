# Parallel mode (under `/workflow:continue`)

Multi-item, role-specialized, worktree-isolated orchestration. **Not** a top-level slash
family. Decision: `docs/decisions/001-swarm-collapse-into-workflow.md`.

## Load map

| When | Load |
|------|------|
| Entering parallel with a goal | `orchestrator.md` then `references/*` / `roles/*` as needed |
| Active run / pause recovery | `resume.md` then re-enter `orchestrator.md` at merge sweep |
| Setup / re-setup | `/workflow:setup` (charter + `.agent-tools/parallel/` config & roles) |
| Classification / dispatch / schemas | `references/` |
| Worker prompts | `roles/` (canonical); project copies under `.agent-tools/parallel/roles/` |

## Entry (portfolio router)

Continue selects parallel mode when:

1. **parallel_resume** — `.agent-tools/parallel/active-run` present (`in_progress` or paused)
2. **parallel_handoff** — explicit roadmap `∥` / `{wave}` at head, ≥2 claimable peers, and
   parallel **ready** (charter + `.agent-tools/parallel/` setup)
3. **parallel** — `$ARGUMENTS` name a multi-item goal (comma-separated issue keys, milestone
   string, backlog file path, or ≥2 resolvable peers) — same pre-launch confirmation as
   orchestrator

Single-item args always stay **unit** mode (never force parallel for one id).

## Ready

- `.agent-tools/charter/charter.md` exists, and
- `.agent-tools/parallel/` has `config.yml` and/or `roles/` from `/workflow:setup`

If not ready but a wave is eligible → one ask: run `/workflow:setup` then handoff, **or**
proceed sequential on the first claimable peer.

## On-disk layout

```text
.agent-tools/parallel/
  config.yml          # committed preferences
  roles/              # project role templates (editable)
  active-run          # runtime pointer (gitignored)
  sessions/<run-id>/  # state.yml + dispatch logs (gitignored)
```

Former path `.agent-tools/swarm/` is obsolete. `/workflow:setup` renames it to `parallel/` when
found (no in-flight run assumed).

## Safety (non-negotiable)

- No agent pushes to remote
- Local merges only into `main`, full tests between merges
- Worktrees only via `@git` worktree-create / worktree-delete — never raw `git worktree` or
  Agent-tool `isolation: "worktree"`
