# Continue soft-checks

Apply on **every** `/workflow:continue` orientation (before portfolio mode resolve), and after
a completed slice when picking up again.

Soft-checks are **events** for the unit machine / portfolio router: they can force work on a
prior slice before claiming new work.

## Review theater

If the most recently completed code-bearing slice has a `review:` line missing `method=` or
findings counts (theater evidence), **surface it** and either re-run `/workflow:review` +
remediate or rewrite **valid** evidence (`gates.md` schema) **before** portfolio claim of new
work. Treat as `needs_review` on that prior unit if still claimable.

## Compound skip

If the most recently completed integrated slice has neither a compound capture note nor a
`compound: none — <reason>` line, surface it and either compound or record the skip before new
work. Treat as `needs_compound` on that unit.

## Active swarm

If `active-run` is present, portfolio-router rows 2–4 take precedence over soft-check-driven
new claims on swarm-owned items.
