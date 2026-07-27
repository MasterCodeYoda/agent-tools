# Function: resolve-conflict

**Kind:** ad-hoc (not a `/work` phase — proves functions are more than “run a work step”)

## When

Dispatched by the orchestrator when a merge of a feature branch into `main` is **in
conflict**. Workspace is `main` with the merge in progress (or as the dispatch specifies).

## Procedure

1. Inspect conflict markers and both sides' intent (branch tip vs main).
2. Resolve conflicts preserving both items' acceptance criteria where possible.
3. Complete the merge (or leave instructions if truly blocked).
4. Run the project test command if the dispatch requires it before returning.

## Scope

- One merge conflict episode only. Do not start unrelated refactors.
- Do not push. Local resolution only.
- On second failure of this function for the same item, orchestrator TERMINAL_PAUSE.

## Valid statuses

`DONE` · `FAILED` · `NEEDS_CONTEXT` · `BLOCKED`
