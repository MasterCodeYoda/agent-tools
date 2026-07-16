# Project Workflow Conventions

## Requirements source

File mode default for agent-tools corpus work unless an issue key is given.

## Integration / merge policy

**Autonomous local merge is authorized** for `/workflow:continue` (and the same standard
for standalone execute→finish) when **all** of the following hold:

1. Review completed with **valid evidence** (method, date, verdict, P1–P3 counts, disposition)
2. Project gates clean (doc_lint, relevant unit tests for the change, any other project checks run this loop)
3. Task requirements / plan DoD for the slice met
4. End-of-loop recap includes Review findings & disposition when code moved

When those preconditions are met: **merge to `main` locally** (prefer fast-forward), delete the
feature branch if fully merged, run compound (or record `compound: none`), and advance roadmap
NEXT — **do not stop to ask for merge confirmation**.

Still **stop and hand back** when: review missing/invalid, gates red, genuine judgment call,
doubt about DoD, or push/PR needed. **Pushing and opening PRs remain user-initiated.**

## Work tracks

Default feature track only (`roadmap? → refine → plan → execute → review → finish → compound`).
