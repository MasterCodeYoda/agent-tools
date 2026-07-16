# Continue soft-checks

Apply on the next `/workflow:continue` orientation after a completed slice.

## Review theater

If the most recently completed slice that produced code has a `review:` line missing `method=` or findings counts (theater evidence), **surface it** and either re-run `/workflow:review` + remediate or rewrite valid evidence **before** picking up new work.

## Compound skip

If the most recently completed integrated slice has neither a compound capture note nor a `compound: none — <reason>` line, surface it and either compound or record the skip before new work.
