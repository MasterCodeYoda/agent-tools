# Run-ledger gap seeds (evolve input)

**Load when:** `/skills:evolve` is run with process/yield focus, user pastes run evidence, or
soft-checks pointed at evolve after thrash/rework.

Seeds are **gap candidates**, not auto-proposals. Every seed still needs detection against the
corpus (evidence that the skill text is wrong/missing) before a proposal is written.

## Where seeds come from

| Source | Path / signal |
|--------|----------------|
| Events spine | `.agent-tools/runs/events.ndjson` |
| Closed runs | `.agent-tools/runs/ledger.yml` |
| Yield glance | `.agent-tools/runs/yield.md` |
| Process memory | `.agent-tools/memory/entries/*` with `type: process` and `related:` run_ids |
| Soft-checks | thrash_bound, review theater, missing compound (session-state) |

## Seed shape (include in gap report)

```yaml
seed_id: seed-001
run_ids: [r-20260718-1]
unit: SPEC-851
symptoms:
  - thrash_bound after micro-eligible issue forced needs_refine
evidence:
  - .agent-tools/runs/events.ndjson lines for run_id
  - session-state reentry_counts
hypothesized_gap: |
  continue unit SM does not classify micro when label=bug
candidate_skills:
  - src/workflow/continue/references/unit-state-machine.md
  - src/workflow/references/tracks.md
severity_guess: P1 | P2 | P3
```

## Detection rules for seeds

1. **Cluster** — prefer ≥2 runs or one thrash_bound with clear oscillation before elevating to P2.
2. **Locate skill text** — greppable mismatch between seed symptom and current procedure.
3. **Intentional omission** — if tracks.md already covers the case, seed may be **agent compliance**
   not a corpus gap (report as observation, not proposal).
4. **One seed → one gap id** in the Evolution Gap Report when confirmed.
5. **Proposals** still follow evolve constraints (one file, evidence-linked, size guard).

## Invocation hints

```text
/skills:evolve --dry-run
  # with chat context: "seeds from runs ledger last 14d" or paste seed YAML

/skills:evolve
  # after compound process entry with related: [r-…]
```

When seeds target workflow/swarm, inventory **must** include `src/workflow/**` and
`src/swarm/**` SKILL.md trees (not only `src/skills/`).
