# Execute — error recovery

**Load when:** tests fail, approach diverges, code pushes back, blocked, or context is lost.

## Tests fail

1. Distinguish crash site from root cause — trace back  
2. Trace to actual definitions — don't assume from names  
3. Check the opposite hypothesis before concluding  
4. Fix before next task; if out of scope, document evidence in session state  
5. Do not proceed with failing tests  

## Approach diverges or code pushes back

Plans and requirements are **working hypotheses** (@work
`references/context-engineering.md` › Provisional artifacts).

1. **Stop** non-trivial further edits on the wrong path.  
2. **Record evidence** in session-state / phase-return.  
3. **Emit the right event** for continue re-classification — do not only “push through” the
   approved plan:
   - Wrong problem / ticket framing → `PROBLEM_REFRAMED` → re-refine  
   - Design/structure falsified → `DESIGN_FALSIFIED` → re-plan or re-refine  
   - Human trajectory change → `HUMAN_STEER` → re-classify from evidence  
   - Plan structure only (ACs still hold) → `EXECUTE_GAP` → re-plan  
4. Resume from revised phase artifacts, not a polluted “force the old plan” window.

If continue is not driving this session: document and run `/work:plan` or
`/work:refine` as the event implies, then resume execute.

## Blocked

Document; create resolution task; parallelize if possible; escalate if critical path.

## Lost context

Read session-state (latest **Intentional Compaction** + `resume_loads`), git log,
implementation-plan, and `codebase-research.md`; ask user if needed. Prefer
**context-compact protocol** (write if stale → reclaim + resume) over replaying a failed
thread.
