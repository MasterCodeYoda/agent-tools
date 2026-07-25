# Function: fix-integration

**Kind:** ad-hoc (not a `/work` phase — proves functions are more than “run a work step”)

## When

Dispatched by the orchestrator when a feature branch **merged cleanly** into `main` but the
post-merge test suite failed. Workspace is `main` post-merge.

## Procedure

1. Reproduce the failure with the project test command from the dispatch.
2. Fix the minimal cause (often integration between newly merged code and main).
3. Re-run tests until green or return FAILED/BLOCKED with evidence.

## Scope

- Integration breakage from the merge under repair — not a general cleanup pass.
- Do not push. Local fix only.
- On second failure of this function for the same item, orchestrator TERMINAL_PAUSE.

## Valid statuses

`DONE` · `FAILED` · `NEEDS_CONTEXT` · `BLOCKED`
