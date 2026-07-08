# Decision records — keeping a corpus current, not archaeological

How decision records and the docs around them are kept across a project's life. The `/workflow`
skills `@`-reference this file; the per-project bindings (which file plays which role, and the rare
genre override) live in `planning/conventions.md`, authored by `/workflow:setup`.

## The problem this prevents

Decision corpora rot when they track the *history of every change* instead of stating the *current
target*. A superseded decision gets a tombstone, a "folded into ADR-X" row, an "amends" chain, or a
"Reality:/Model update:" correction block — and the dead content keeps sitting in an
authoritative-looking record. Humans and agents then re-import the stale decision, because
detailed-but-stale beats terse-but-current for attention. The same disease hits a backlog: when a
decision changes, issues get find-replaced (a vendor swapped) but never re-sized, so old phasing and
ceremony ride forward in the acceptance criteria.

## Three roles, one source each

Every project keeps three kinds of fact. They may live in three places or collapse into fewer files,
but each fact has exactly one home:

| Role | Answers | Typical home |
|---|---|---|
| **Decision layer** | what we chose, why, and the alternatives rejected | `docs/decisions/` (ADRs), or a `## Decisions` section in a README |
| **Domain layer** | how the system is designed and behaves (forward-authored; seeds the backlog) | a docs site, `docs/`, or a README |
| **Realization layer** | how much is actually built | the PM tracker (Linear/Jira) or a milestone |

A decision record is written only when a choice **warranted weighing options** — most of the domain
layer has no decision record. When a project has only a README, the decision and domain layers
collapse into one file with two sections; the lifecycle below is identical. `/workflow:setup` names
which file plays each role so the skills speak in roles, not filenames.

**"Is it built yet?" is the realization layer's question.** Decision and domain docs carry **no
status field** and may legitimately run ahead of the code during a build window. Don't stamp
"Proposed / Implemented / Superseded" on a decision doc — the tracker holds realization state.

## The default: current-state, rewritten in place

A decision record states the decision **in force now**: the choice, the reasoning, and the
alternatives rejected (with why). It does **not** narrate how the decision changed over time.

- **When a decision changes, rewrite the record in place.** No supersession notice, no tombstone, no
  "superseded by / folded into" status row, no "previously we said X" history block. Git holds the
  past; the document holds the present.
- **Keep the why, drop the changelog.** Always retain rationale and rejected alternatives — they keep
  a settled question settled, so it isn't re-litigated. Never retain the *change history* of the
  decision; that stale-but-authoritative content is exactly what gets re-imported. If the *reason a
  decision changed* is itself a durable, reusable lesson, route it to project shared memory
  (`.agent-tools/memory/entries/`, type `lesson`) via `/workflow:compound` — not into the
  record as a changelog.
- **Reversed → rewrite. Abandoned → delete.** A decision no longer in force gets no file, no section,
  no "historical" notice — the whole file goes for a dead record; the relevant section is rewritten
  for a changed one.
- **Forward docs (READMEs, config files, code comments) carry no tombstones either** — no "replaces
  the retired X." Say what is.

This is the default for new projects and the recommended target for existing ones.

## The rare exception: classic-immutable

A project that records `decision_records: classic-immutable` in `planning/conventions.md` keeps
append-only, superseded-not-rewritten records instead. Choose this **only** when an external audit
trail is a genuine requirement — a regulated or contractual context where the immutable history *is*
a deliverable. This is the unlikely exception, not a co-equal option; the overwhelming default is
current-state. When classic-immutable is in force, the audit rot-checks below do not apply.

## Two checkpoints — the forcing function

The discipline holds through two moments; this is what keeps docs and code from drifting:

1. **At authoring** (`/workflow:brainstorm`, `:refine`): validate the decision against the live corpus
   — does it cohere; does it contradict or duplicate an existing record? If it changes an existing
   decision, plan to **rewrite that record** at close, not to add a competing one. Refine is where
   rationale + rejected-alternatives are captured — capture them here or nowhere.
2. **At close** (`/workflow:execute`, folded into "verify before closing"): reconcile the governing
   decision record + any docs/ACs the change touched against the **code as built** — match → it
   stands; the build taught better → rewrite the doc to the new target; the doc named a real
   constraint the code dropped → fix the code. Record the reconciliation as **evidence** (name the doc
   + the lines changed, or assert "no drift" against the diff); scope it to the change's blast radius,
   **never** a corpus sweep. A bare checkbox is not evidence.

## Required shape of a decision record

So "keep the why" survives a rewrite, every current-state decision record carries, at minimum: the
**decision**, its **rationale**, and the **alternatives considered (and why rejected)**. A record
missing its rationale/alternatives is incomplete — audit flags it. Titles describe the substantive
decision, not its lineage (no "v2", "supersedes X", "option A" in the title).
