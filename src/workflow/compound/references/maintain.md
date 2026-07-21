# Memory maintain (relocated)

**Primary entry:** `/workflow:maintain` (memory job).

When `/workflow:compound --maintain` (or maintain flags) is invoked, treat as a **compat
shim**: run `/workflow:maintain` with the same flags (see `@workflow:maintain` SKILL.md).
Do **not** re-implement the audit here.

**Full memory procedure:** load and follow

`src/workflow/maintain/references/memory.md`

(from this skill tree: `../../maintain/references/memory.md`).

Cadence / due offers: `../../maintain/references/cadence.md`.
Capture mode (default compound) remains knowledge capture only — soft-prompt due maintain
points at `/workflow:maintain`, it does not inline the audit.
