# Dated rule / incident-class entry template

Load when capturing a **lesson from a concrete mistake or near-miss** that future sessions must
obey (claim-class errors, policy misses, automation failures). Prefer `type: lesson` or
`type: process` under `.agent-tools/memory/entries/<slug>.md`.

Debugging root-cause narratives still use `templates/solution.md`. Pure patterns without an
incident may use the generic entry shape in compound SKILL (Why + How to apply only).

## Output

```markdown
---
name: <slug>
description: <one-line actionable rule>
type: lesson | process
applicability: project
related: []          # run_ids, PRs, ADRs, skill paths
incident_date: YYYY-MM-DD
job_phases: []       # e.g. continue, review, channel-reply, pre-wake
promoted_at: null
promoted_to: null
source_harness: null
---

# <Title — the rule, not the story>

## Incident

**Date:** YYYY-MM-DD  
**What went wrong:** one paragraph (observable failure; no secrets).  
**Impact:** who/what was wrong (public claim, bad merge, thrash, …).

## Rule

Imperative rule every future session must follow.

## Mandatory verify (claim-class)

If this was a false claim / missing capability / “live” vs “in code” error, list **what to
check live** before asserting again (commands, dashboards, paths). Memory is not the citation.

- [ ] Verify step 1 …
- [ ] Verify step 2 …

If not claim-class, write `n/a — not claim-class`.

## Load when

Which jobs/phases should read this entry (continue orientation, review PR bodies, pre-wake,
support reply, …). Keep short so progressive disclosure stays cheap.

## How to apply

Concrete steps; link SoT files. Prefer “check X then assert” over vibes.

## Prevention

What would have blocked the incident (soft-check, gate, script, approval tier).
```

## Quality

- [ ] `incident_date` set  
- [ ] Rule is reusable (not ticket diary only)  
- [ ] Claim-class has non-empty verify steps  
- [ ] `job_phases` or Load when filled  
- [ ] MEMORY.md one-liner added  
- [ ] No secrets  
