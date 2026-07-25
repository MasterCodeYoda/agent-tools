# Critic Pass

A reusable verification primitive that runs **after** a set of independent findings (or
responses) has been collected and **before** they are finalized. It exists because parallel
agents share correlated blind spots: they converge on the obvious and miss what none of them
thought to look for, and a plausible-but-wrong finding survives when nobody is tasked with
attacking it.

Two passes, dispatched as sub-agents (supported natively on all target agents, so no agent
markup is needed). Each pass is **evidence-bound** — it adds signal, never volume. A pass that
finds nothing concrete emits nothing.

## Pass 1 — Blind-Spot Critic

Spawn **one** agent with a fresh context. Give it the full set of collected findings plus the
target under examination (the diff, the codebase domains, or the set of advisor responses).

Ask exactly:
- Which entire **category** of risk or concern appears in *none* of these findings?
- What did all the independent reviewers **collectively** miss?

It may only emit a finding that points to a concrete, locatable gap (a `file:line`, a missing
artifact, an untested path, an unstated assumption). Tag emitted findings `[blind-spot]` and
assign severity by the host skill's scale. The gap *between* perspectives is the signal — what
nobody mentioned is more informative than what everyone repeated.

## Pass 2 — Refutation

For each **blocking** finding only (P1 / critical — not P2/P3, to bound cost), spawn a skeptic
instructed to **refute** it: assume the finding is wrong and hunt for evidence that exonerates
the code (a guard elsewhere, framework behavior, existing test coverage, a shadowed call). The
finding **stands** only if refutation fails on the evidence.

- Refuted with cited evidence → **downgrade or retract**, recording why.
- Not refuted → keep, now hardened against the obvious counter-argument.

This operationalizes the per-agent "check the opposite hypothesis" reasoning standard as a
distinct, accountable pass so a false P1 cannot silently block.

## Discipline

- **Cite or drop.** Every emitted or retained finding cites `file:line` or a concrete absence.
- **Bound the cost.** Refutation runs on blocking findings only; the blind-spot pass is a single
  agent. Skip the whole primitive for trivial / quick-scope work.
- **No new volume.** These passes resolve and harden findings; they do not pad the report.

## Reuse beyond code

Applied to a set of independent *advisor* responses on a decision (rather than code findings),
Pass 1 is the "what did everyone miss?" round of an idea pressure-test — the highest-value
step of a council. Host skills that pressure-test ideas (e.g. requirements refinement) can reuse
Pass 1 directly; Pass 2's refutation maps to stress-testing the surviving recommendation.
