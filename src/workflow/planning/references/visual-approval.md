# Visual Plan Approval (presentation layer)

Optional **human-review surface** for `/workflow:plan` approval. Turns the draft
implementation plan into an interactive visual plan (diagrams, file maps, schema/API
blocks, UI wireframes when relevant) so the user can approve direction more easily.

## Source of truth (hard rule)

| Artifact | Role |
|----------|------|
| **`planning/<project>/implementation-plan.md`** | **Executable source of truth** after approval — execute, continue, swarm |
| **`planning/<project>/session-state.md`** | Resume / phase passport |
| **Visual plan** (hosted URL or local MDX folder) | **Approval presentation only** — never execute input |

The visual plan **must not** replace, delay, or weaken the markdown implementation plan.
If the visual surface fails or is skipped, the plan approval gate still runs on the draft
markdown plan.

## When to run

### Convention keys (additive — missing section ≠ never)

`planning/conventions.md` is a **sparse overlay**, not a full replacement of workflow
defaults. Resolve policy in this order:

1. **Explicit** `## Visual plan approval` (or equivalent keys) in `planning/conventions.md`
   when present — use those values.
2. Else **built-in default** (below) — even when conventions.md exists for other topics
   (merge policy, tracks, PM mode, gates). A file that never mentions visual plan does
   **not** disable it.
3. User says “never use a visual plan” / “skip visual” this turn → treat as `never` for
   this invocation only.

```markdown
## Visual plan approval
- **Policy:** never | on-substantial | always
- **Mode:** local-files | hosted | self-hosted
- **Local dir:** `.agent-native/plans/<slug>/`   # optional override
```

| Policy | Behavior |
|--------|----------|
| `never` | Do not attempt a visual surface |
| `on-substantial` | Run only when **substantial** heuristics match |
| `always` | Attempt whenever `/workflow:plan` reaches the approval gate |

**Built-in default** (section absent, with or without a conventions file): policy
`on-substantial`; mode preference `local-files`, then `hosted` if only hosted tooling is
available.

### Substantial heuristics (`on-substantial`)

Treat the plan as substantial if **any** of:

- Multi-file or multi-layer change (≥3 meaningful files, or ≥2 architectural layers)
- UI / product surface work (screens, flows, states, navigation)
- Schema, migration, API/contract, auth, permissions, or ownership boundaries
- Architecture / data-flow shift or hard-to-reverse public shape decisions
- Ambiguous options that need a visual comparison or open-question form

**Skip** (record reason) when the plan is:

- Typo / one-line / single well-specified function
- Pure docs, skill text, or rename-only with no behavior change
- Already easier to approve as short markdown than as a visual surface

User override: if the user explicitly asks for a visual plan this turn, treat as `always`
for this invocation.

## Capability check (before any generation)

Non-blocking. In order:

1. **Hosted Plan MCP** — tools visible under `plan` or legacy `agent-native-plans`
   (`create-visual-plan`, `create-ui-plan`, `get-plan-blocks`, …). Discover via host
   tool search if lazy-loaded.
2. **Local-files CLI** — `npx @agent-native/core@latest` available (network/npx ok).
3. **Neither** → `visual_plan: skipped — plan tooling unavailable` and proceed to the
   normal Plan Approval Prompt. Do **not** invent an inline faux-visual markdown wall
   as a substitute for the Plan surface.

If conventions force `mode: local-files`, prefer (2) and do not write to the hosted Plan DB.
If conventions force `mode: hosted` and MCP is missing, skip with reconnect hint — do not
fall back to a fake inline plan.

## How to build (when policy + substantial + capability pass)

### Inputs

Use the **in-memory draft** of `implementation-plan.md` (not yet saved) plus requirements
context. Pass that text as the plan source (`planText` / local authoring input). Preserve
task breakdown, DoD, risks, and file touch list so the visual surface reflects the same
executable plan.

### Mode selection for content shape

| Work shape | Prefer |
|------------|--------|
| Architecture / backend / data / refactor / API | Document-first (`create-visual-plan`) |
| Product UI states / screens | UI-first (`create-ui-plan`) + canvas wireframes |
| Multi-step interactive flow | Prototype-first (`create-prototype-plan`) when tooling supports it |

Ground blocks in **real** paths, symbols, schema, and endpoints from research — never invent
contracts. Label inferred UI/layout as inferred.

### Hosted mode

1. Call `get-plan-blocks` (authoritative tags — do not memorize JSX).
2. Create with the mode-matched tool; pass draft plan text as source.
3. Report the **absolute URL** returned by the create tool (not a guessed localhost link).
4. On user **Revise** feedback that targets the visual plan, update via
   `update-visual-plan` / `get-plan-feedback` **and** update the draft markdown plan so
   they stay aligned.

### Local-files mode

1. Choose dir: conventions override, else `.agent-native/plans/<project-slug>/`
   (repo-local; do not put under `planning/` as the executable artifact).
2. Author MDX (`kind: "plan"`, `localOnly: true`) from the draft plan; fetch block catalog
   via `npx @agent-native/core@latest plan blocks --out plan-blocks.md` when MCP unavailable.
3. Validate: `npx @agent-native/core@latest plan local check --dir <plan-dir>`
4. Preview: `npx @agent-native/core@latest plan local serve --dir <plan-dir> --kind plan --open`
5. Hand the bridge URL from stdout or `<plan-dir>/.plan-url` (do not commit `.plan-url`).
6. On Revise: edit MDX + draft markdown; re-check/serve.

Full local-files contract details: Agent-Native Plans docs / installed visual-plan skill
references when present. Do not call hosted create/update tools in local-files mode.

### Privacy & security

- Default to the narrowest visibility for hosted plans (org/login, not public).
- Never copy secrets, tokens, or `.env` values into plan blocks — redact.
- Local-files mode keeps plan content off the hosted Plan database; the preview UI may
  still load from the hosted origin against a localhost bridge.

## Integration with Plan Approval Gate

**Order:**

1. Draft `implementation-plan.md` content (in memory) — complete and ready.
2. Leverage check.
3. **Visual approval surface** (this doc) — success or skip with reason.
4. Present Plan Approval Prompt (templates) including visual link **or** skip line.
5. Stop for user choice: Approve & Save | Approve & Execute | Revise.

Rules:

- Visual generation failure → skip line + continue to approval; **never** block the gate.
- Visual plan is **not** a fourth approval option and does **not** replace the three options.
- Approving the plan always means approving the **markdown implementation plan** that will be
  saved; the visual surface is an aid for that decision.
- On **Revise**: update draft markdown first (executable intent), then refresh the visual
  surface when one exists; re-present the approval prompt.
- On **Approve & Save / Approve & Execute**: write `implementation-plan.md` and
  `session-state.md` as today; record visual metadata in session-state (below). Execute
  reads **only** the markdown plan.

## Session-state recording

After approval, include when a visual surface was produced or explicitly skipped:

```yaml
visual_plan: "<url-or-local-dir> | mode=local-files|hosted | status=published"
# or
visual_plan: "skipped — <reason>"
```

Optional body line under Status / Next Steps is fine; frontmatter preferred for greppability.

## What this is not

- Not a substitute for `/workflow:plan` task breakdown or DoD.
- Not execute or swarm input.
- Not a review gate and not review evidence.
- Not required for "plan approved" orientation — disk `implementation-plan.md` + session
  state remain the passport.
- Not visual-recap (post-diff); this is pre-code approval only.
