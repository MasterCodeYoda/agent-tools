# Run history

Committed, compacted summaries of `/swarm` test runs worth remembering.

`runs/` is gitignored — generated repos are throwaway (28 MB each, mostly `.venv`, plus a
nested `.git`). Worse, the evidence is *doubly transient*: the session logs under
`.agent-tools/parallel/sessions/` are gitignored inside the throwaway repo too (a `/workflow:setup`
rule), and the richest record — the orchestrator's Claude Code transcript — lives outside the
repo entirely under `~/.claude/projects/…` on a retention clock. Delete the run dir and all of
it is gone.

So when a run produced an evolution seed or surfaced something worth keeping, its **summary**
is committed here instead — small, self-contained, and durable. This is the lasting record of
what the run found and what `/skills:evolve` subsequently accepted or rejected.

## Layout

```
history/<run-id>/
  analysis.md        the analyze verdict — invariants, checklist, clusters, evolution seeds (primary)
  observations.json  deterministic ingest output (incl. transcript-recovered dispatch counts)
  orchestrator.md    the run narrative — otherwise transient (gitignored in the run repo)
```

`analysis.md` cites its evidence (dispatch logs, reviewer returns, `state.yml` fields), so the
summary stays traceable without the multi-megabyte run dir or the `~/.claude` transcript.

## Convention

- **Opt-in.** Most runs are noise; archive a summary only when it produced an evolution seed
  or recorded a finding worth revisiting. `/swarm:test` Phase 6 offers this after
  writing `<run-dir>/analysis.md`.
- **Outside `runs/`.** Summaries live here, not under the ignored `runs/` tree — git cannot
  re-include a file inside an ignored directory, so a `!runs/*/analysis.md` negation would not
  work. A sibling tracked dir is the clean mechanism.
- **Compact, not complete.** Commit the distilled summary, never the throwaway repo, `.venv`,
  or full transcripts.
