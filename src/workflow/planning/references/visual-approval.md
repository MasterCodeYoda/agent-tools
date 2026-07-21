# Visual Plan Approval (static HTML)

Optional **human-review surface** for `/workflow:plan` approval. Turns the draft
implementation plan into a **self-contained static HTML brief** (architecture diagrams,
file maps, slice graphs, decisions, risks, open questions) so the user can approve
direction more easily.

First-party only: no third-party Plan apps, MCP connectors, `npx` CLIs, or hosted bridges.
The agent authors HTML from the template and opens the local file.

## Source of truth (hard rule)

| Artifact | Role |
|----------|------|
| **`planning/<project>/implementation-plan.md`** | **Executable source of truth** after approval — execute, continue, swarm |
| **`planning/<project>/session-state.md`** | Resume / phase passport |
| **`planning/<project>/visual-plan.html`** | **Approval presentation only** — never execute input |

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
- **Output path:** planning/<project>/visual-plan.html   # optional override
```

| Policy | Behavior |
|--------|----------|
| `never` | Do not attempt a visual surface |
| `on-substantial` | Run only when **substantial** heuristics match |
| `always` | Attempt whenever `/workflow:plan` reaches the approval gate |

**Built-in default** (section absent, with or without a conventions file): policy
`on-substantial`; output path `planning/<project>/visual-plan.html` (relative to the
resolved planning root — prefer `.agent-tools/planning/` when that is the active root).

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

## Capability check

Always available when the agent can write a local file and the user can open it in a
browser. There is **no** third-party tooling probe.

Skip only when:

- Policy is `never` or the plan is not substantial under `on-substantial`
- Write fails (permissions, disk) → `visual_plan: skipped — could not write HTML`
- User is in an environment where a browser file cannot be opened **and** they decline
  the path-only handoff → `visual_plan: skipped — no browser handoff`

Do **not** skip because some external CLI or MCP is missing.

## How to build (when policy + substantial pass)

### Inputs

Use the **in-memory draft** of `implementation-plan.md` (not yet saved as the approved
executable plan) plus requirements context. Preserve task breakdown, DoD, risks, and file
touch list so the visual surface reflects the same executable plan.

**Write permission exception:** you **may** create the project planning directory and write
**only** `visual-plan.html` before the approval gate. Do **not** write
`implementation-plan.md` or `session-state.md` until the user chooses Approve.

### Output path

1. Conventions `Output path` when set.
2. Else `<planning-root>/<project>/visual-plan.html` (same directory the implementation
   plan will use).

Create parent directories as needed. Prefer a repo-relative path in chat; record an
absolute path in session-state when useful for reopening.

### Authoring steps

1. **Load** @workflow (`planning/templates/visual-plan.html`) as the shell (CSS, layout,
   Mermaid bootstrap, section scaffold).
2. Fill every section that has real content from the draft plan. Omit empty sections
   entirely (do not leave “TBD” chrome).
3. Ground paths, symbols, schema, and endpoints in research — never invent contracts.
   Label inferred UI/layout as *inferred*.
4. Write the complete self-contained HTML file to the output path.
5. Open for review:
   - macOS: `open <path>`
   - Linux: `xdg-open <path>` when available
   - Always print the absolute path in chat so the user can open it manually.
6. Keep the path for the Plan Approval Prompt and for session-state after approve.

### Content shape by work type

| Work shape | Emphasize in the HTML |
|------------|------------------------|
| Architecture / backend / data / refactor / API | Architecture + data-flow Mermaid, file map, decisions, risks |
| Product UI / screens | UI notes or simple wireframe sketches (HTML/CSS), before/after, open questions |
| Mixed | Architecture + file map + a short UI section only if product-facing |

### Section contract (use these ids / headings)

Keep the template’s structure so the brief is scannable:

| Section | Purpose |
|---------|---------|
| **Overview** | 2–4 sentence outcome + approach |
| **Architecture** | One primary Mermaid (or HTML) diagram of the change |
| **Slices / deliverables** | Ordered units with task counts; optional dependency Mermaid |
| **Files** | Touch list / tree with add · modify · remove notes |
| **Decisions** | Hard-to-reverse bets + rationale |
| **Risks** | Concrete risks and mitigations |
| **Open questions** | Unresolved items with recommended defaults when possible |
| **Footer banner** | Always: presentation only; executable SoT is `implementation-plan.md` |

### Mermaid

Use `<pre class="mermaid">…</pre>` blocks inside the template. The template loads Mermaid
from a CDN for rendering. If the environment is offline, diagrams still show as readable
source text — never fail the surface solely because Mermaid cannot fetch.

### Privacy & security

- Never put secrets, tokens, or `.env` values in the HTML.
- Default is local-file only; do not upload the brief to external services.
- Treat the HTML as disposable presentation: safe to regenerate on every revise.

## Integration with Plan Approval Gate

**Order:**

1. Draft `implementation-plan.md` content (in memory) — complete and ready.
2. Leverage check.
3. **Visual approval surface** (this doc) — write/open HTML or skip with reason.
4. Present Plan Approval Prompt (templates) including visual path **or** skip line.
5. Stop for user choice: Approve & Save | Approve & Execute | Revise.

Rules:

- Visual generation failure → skip line + continue to approval; **never** block the gate.
- Visual plan is **not** a fourth approval option and does **not** replace the three options.
- Approving the plan always means approving the **markdown implementation plan** that will be
  saved; the visual surface is an aid for that decision.
- On **Revise**: update draft markdown first (executable intent), then rewrite
  `visual-plan.html` so it matches; re-open if useful; re-present the approval prompt.
- On **Approve & Save / Approve & Execute**: write `implementation-plan.md` and
  `session-state.md` as today; leave or refresh `visual-plan.html` next to them; record
  visual metadata in session-state (below). Execute reads **only** the markdown plan.

## Session-state recording

After approval, include when a visual surface was produced or explicitly skipped:

```yaml
visual_plan: "<absolute-or-repo-relative-path-to-visual-plan.html> | mode=static-html | status=published"
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
- Not a third-party hosted Plan product, MCP connector, or collaborative design canvas.
- Not visual-recap (post-diff); this is pre-code approval only.
