# Plan — context gathering & requirements load

**Load when:** `/work:plan` after mode detection, before drafting the implementation plan.

## 1. Auto-detect project context

```bash
ls ./planning/ 2>/dev/null
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

Also note PM indicators (AGENTS.md, MCP tools) per `planning/pm-integration.md`.

## 2. On-demand codebase research + design confirm

**Load** @work (`references/context-engineering.md`) › On-demand codebase research,
Technical design discussion, and Plan segmentation.

This is **not** the research *track*. Prefer research and technical design already produced in
**`/work:refine`**. Plan **re-verifies** and fills gaps; it does not invent a second product
truth.

1. **Load existing** `codebase-research.md` and `design-discussion.md` when present.  
2. **Freshness:** discard/re-run if branch moved or research is wrong — prefer
   **questions-first + ticket-hidden facts**.  
3. **If research missing** on non-trivial work: run full/light research; write
   `./planning/<project>/codebase-research.md`.  
4. **If design missing** on feature/hard work: produce `design-discussion.md` **before**
   structure/tactical plan — or **stop and offer re-enter refine** when ACs must change.  
5. **If design invalidates frozen ACs:** do **not** quietly rewrite ACs — stop and offer
   `/work:refine`.  
6. **Human leverage:** present short research + design confirm with the segmented plan draft.
   Wrong research/design → throw out and re-steer.

Also: parse ACs, stakeholders, constraints, dependencies; confirm requirements converged with
research. External docs only when needed — not a substitute for codebase research.

## 3. Prefactoring assessment

Ask: *given the current code shape, is the change hard?* If a behavior-preserving structural
refactor would make the upcoming change small and safe, that is **prefactoring** (Kent Beck,
*Tidy First*) — capture as **enabling work** first.

Guardrails:

- **Behavior-preserving** — no functional change; tests stay green  
- **Separately committed** — never share a commit with behavioral changes  
- **Justified by this change** — no speculative cleanup  
- **Off-ramp** — skip if the change is already easy  

## 4. Load requirements

### File mode

Read `requirements.md`: problem, stories, must-haves, success criteria, issue IDs, dependency
metadata (`blocks` / `blocked_by` / `parallelizable_with` from refine Phase 3.5).

### PM mode

Fetch via Issue Retrieval Strategy (`planning/pm-integration.md`): title, description, ACs,
native block relations + `parallelizable_with`. Do not warn about missing `requirements.md`.

### Review with user

1. Requirements complete for planning?  
2. Clarifications needed?  
3. Run `/work:refine` first?  

Echo `blocks` / `blocked_by` / `parallelizable_with` (or absence) for confirm — written to plan
frontmatter for parallel mode waves.

Proceed once requirements are confirmed.
