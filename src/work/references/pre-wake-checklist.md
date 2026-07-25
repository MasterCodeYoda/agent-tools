# Pre-wake checklist (automation / scheduled entry)

**Load when:** a scheduled job, gateway mention, or unattended host is about to run
`/work:continue` (or equivalent drive entry). Host-agnostic **shape** — hosts implement
scripts; this file is the portable contract.

**Related:** approval-boundaries · soft-checks · portfolio-router · planning-root · runs-ledger.

---

## Principle

Hydrate **current** process inputs **before** the model invents context. Pre-run collection beats
assumptions. Fail closed when isolation or claimability is unsafe.

## Checklist (ordered)

Run as deterministic script/steps when possible; model only after green.

| # | Check | Fail closed action |
|---|--------|-------------------|
| 1 | **Workspace root** is the intended project (or disposable worktree), not a random cwd | Stop; report mis-bind |
| 2 | **Isolation** — if policy requires worktree/automation sandbox, cwd is that worktree; **never** a dirty primary checkout of active human work | Stop; escalate |
| 3 | **Git hygiene** — unexpected dirty state on the automation worktree is logged; do not clobber human WIP on primary | Stop or quarantine per host policy |
| 4 | **Planning root** resolves (`.agent-tools/planning/` preferred) | Stop + offer setup if uninitialized |
| 5 | **Claimable unit** — named NEXT / in_progress / conventions PM queue only; **zero invent** | hard_stop; deliver status, do not invent work |
| 6 | **Soft-check priors** — theater review / missing compound / thrash on prior slice would block new claim | Surface; remediate prior or stop |
| 7 | **Approval tier** — job class maps to Autonomous / Draft-first / Escalate (`approval-boundaries.md`) | Draft-first or escalate jobs must not auto-ship |
| 8 | **Approvals floor** — host tool approvals fail-closed for unattended (e.g. cron deny YOLO) | Do not start if host is YOLO |
| 9 | **Delivery path** — on escalate/await_user, channel or operator report target known | Prefer silent fail-safe over undelivered escalate |
| 10 | **Pre-collected context** — attach fresh queue/status/ledger snippets the job needs (not stale chat) | Prefer re-fetch over memory |
| 11 | **Effort ceiling** — unattended runs use ≤ medium thinking/effort; Sol-class high/ultra force-down when host can detect — `model-runtime-policy.md` | Stop or force-down; do not start unattended high-effort freelancing |

## After model wake

Same loop as interactive continue:

```text
read policy (approval-boundaries + conventions)
  → soft-checks → portfolio mode → claimable only
  → act within tier → write planning disk → runs append
  → report / escalate without re-driving the same red gate
```

**Do not** re-drive the same `await_user` / E-MERGE gate in a tight cron loop. Deliver once;
wait for human or disk change.

## Script promote

The second time a pre-wake or gate check is hand-rolled, **promote** it to a named script under
the host’s script home (or project `scripts/`). Skills describe *how*; scripts *do*. See
@work maintain process invariants (script promote-on-second-use).

## Host implementation notes (informative)

| Host concern | Example |
|--------------|---------|
| Hermes factory | `hermes -p factory cron` + workdir=worktree; profile terminal.cwd never dirty primary; **effort ≤ medium** hard cap |
| CLI operator | Optional: run checklist manually before long unattended continue |
| Controller product | Parse checklist exits → continue \| escalate \| idle |
| Effort / model policy | Bind host knobs to `model-runtime-policy.md` (do not fork phase tables) |

Process pack does **not** ship host cron YAML as SoT.
