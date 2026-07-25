# Parallel mode (under `/work:continue`)

Multi-item, **function-scoped**, worktree-isolated orchestration. **Not** a top-level slash
family. Decisions: `docs/decisions/001-swarm-collapse-into-workflow.md`,
`docs/decisions/003-parallel-functions-not-roles.md`.

## Doctrine

- **One agent kind.** Dispatches use the same substrate (harness + model + effort/thinking).
- **Scoped functions, not personas.** Packets are procedures with contracts — not character sheets.
- **One charter.** Shared values/standards/process under `.agent-tools/charter/`.
- **Phase packets** map to `/work:*` (plan, implement, review).
- **Ad-hoc functions** (resolve-conflict, fix-integration) prove value beyond “run a work step
  in a fresh context.”

## Load map

| When | Load |
|------|------|
| Entering parallel with a goal | `orchestrator.md` then `references/*` / `functions/*` as needed |
| Active run / pause recovery | `resume.md` then re-enter `orchestrator.md` at merge sweep |
| Setup / re-setup | `/work:setup` (charter + `.agent-tools/parallel/` config & functions) |
| Classification / dispatch / schemas | `references/` |
| Worker prompts | `functions/` (canonical); project copies under `.agent-tools/parallel/functions/` |

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
- `.agent-tools/parallel/` has `config.yml` and/or `functions/` from `/work:setup`

If not ready but a wave is eligible → one ask: run `/work:setup` then handoff, **or**
proceed sequential on the first claimable peer.

## On-disk layout

```text
.agent-tools/parallel/
  config.yml              # committed preferences (function_chain, models, …)
  functions/              # project function packets (editable)
    worker-contract.md
    plan.md
    implement.md
    review.md
    resolve-conflict.md
    fix-integration.md
  active-run              # runtime pointer (gitignored)
  sessions/<run-id>/      # state.yml + dispatch logs (gitignored)
```

**Migrate:** if `.agent-tools/parallel/functions/` exists and `functions/` does not, rename
`roles` → `functions` (`git mv` when tracked). If both exist, stop and ask. No dual trees;
no alias forever.

Former top-level path `.agent-tools/swarm/` → rename to `parallel/` first (see setup).

## Safety (non-negotiable)

- No agent pushes to remote
- Local merges only into `main`, full tests between merges
- Worktrees only via `@git` worktree-create / worktree-delete — never raw `git worktree` or
  Agent-tool `isolation: "worktree"`
